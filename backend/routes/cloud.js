const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const CloudAccount = require('../models/CloudAccount');
const { encrypt } = require('../utils/encryption');

// Cloud SDK Imports
const { STSClient, GetCallerIdentityCommand } = require('@aws-sdk/client-sts');
const { GoogleAuth } = require('google-auth-library');
const { ClientSecretCredential } = require('@azure/identity');

// @route   GET api/cloud/accounts
// @desc    Get cloud accounts for user
// @access  Private
router.get('/accounts', auth, async (req, res) => {
    try {
        const accounts = await CloudAccount.find({ userId: req.user.id });
        res.json(accounts.map(a => ({
            id: a._id,
            provider: a.provider,
            accountId: a.accountId,
            status: a.status,
            regions: a.regions,
            lastSync: a.lastSync,
        })));
    } catch (err) {
        res.status(500).json({ message: 'Failed to fetch cloud accounts.' });
    }
});

// @route   POST api/cloud/accounts
// @desc    Add a new cloud account with real-time SDK validation
// @access  Private
router.post('/accounts', auth, async (req, res) => {
    try {
        const { provider, credentials } = req.body;
        
        if (!provider || !credentials) {
            return res.status(400).json({ message: 'Provider and credentials are required.' });
        }

        let accountId;
        const accountData = {
            userId: req.user.id,
            provider,
            status: 'Active',
            regions: []
        };

        if (provider === 'AWS') {
            const { apiKey, apiSecret } = credentials;
            if (!apiKey || !apiSecret) return res.status(400).json({ message: 'Missing AWS Keys.' });
            
            // Validate AWS Keys via STS
            const sts = new STSClient({
                region: 'us-east-1',
                credentials: { accessKeyId: apiKey, secretAccessKey: apiSecret }
            });
            const response = await sts.send(new GetCallerIdentityCommand({}));
            accountId = response.Account; // 12 digit AWS Account ID

            accountData.accountId = accountId;
            accountData.encryptedApiKey = encrypt(apiKey);
            accountData.encryptedApiSecret = encrypt(apiSecret);
            accountData.regions = ['global'];

        } else if (provider === 'GCP') {
            const { projectId, clientEmail, privateKey } = credentials;
            if (!projectId || !clientEmail || !privateKey) return res.status(400).json({ message: 'Missing GCP Keys.' });
            
            // Format Private Key correctly if passed via JSON
            const formattedKey = privateKey.replace(/\\n/g, '\n');

            // Validate GCP via Auth Token
            const googleAuth = new GoogleAuth({
                credentials: { client_email: clientEmail, private_key: formattedKey },
                scopes: 'https://www.googleapis.com/auth/cloud-platform'
            });
            await googleAuth.getAccessToken(); // Will throw an error if keys are fake

            accountId = projectId;
            accountData.accountId = accountId;
            accountData.projectId = projectId;
            accountData.clientEmail = clientEmail;
            accountData.encryptedPrivateKey = encrypt(formattedKey);
            accountData.regions = ['global'];

        } else if (provider === 'Azure') {
            const { tenantId, clientId, clientSecret } = credentials;
            if (!tenantId || !clientId || !clientSecret) return res.status(400).json({ message: 'Missing Azure Keys.' });

            // Validate Azure Service Principal
            const credential = new ClientSecretCredential(tenantId, clientId, clientSecret);
            await credential.getToken("https://management.azure.com/.default"); // Will throw if fake

            accountId = tenantId;
            accountData.accountId = accountId;
            accountData.tenantId = tenantId;
            accountData.clientId = clientId;
            accountData.encryptedClientSecret = encrypt(clientSecret);
            accountData.regions = ['global'];
        } else {
            return res.status(400).json({ message: 'Unsupported Provider.' });
        }

        // Save successfully verified account to securely to MongoDB
        const newAccount = new CloudAccount(accountData);
        await newAccount.save();

        res.json({
            id: newAccount._id,
            provider: newAccount.provider,
            accountId: newAccount.accountId,
            status: newAccount.status,
            regions: newAccount.regions,
            lastSync: newAccount.lastSync
        });

    } catch (err) {
        console.error('[CloudValidation Error]', err.message);
        return res.status(401).json({ 
            message: 'Failed to authenticate with the cloud provider.',
            details: err.message
        });
    }
});

// @route   PUT api/cloud/accounts/:id/status
// @desc    Update cloud account status
// @access  Private
router.put('/accounts/:id/status', auth, async (req, res) => {
    try {
        const { status } = req.body;
        const account = await CloudAccount.findOneAndUpdate(
            { _id: req.params.id, userId: req.user.id },
            { status, lastSync: new Date() },
            { new: true }
        );
        if (!account) return res.status(404).json({ message: 'Account not found.' });
        res.json(account);
    } catch (err) {
        res.status(500).json({ message: 'Failed to update account.' });
    }
});

module.exports = router;
