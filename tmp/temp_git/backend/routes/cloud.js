const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const CloudAccount = require('../models/CloudAccount');

const DEFAULT_CLOUDS = [
    { provider: 'AWS', status: 'Active', regions: ['us-east-1', 'eu-west-1'] },
    { provider: 'GCP', status: 'Active', regions: ['us-central1'] },
    { provider: 'Azure', status: 'Issues Detected', regions: ['eastus'] },
];

// @route   GET api/cloud/accounts
// @desc    Get cloud accounts for user (seeds defaults if none exist)
// @access  Private
router.get('/accounts', auth, async (req, res) => {
    try {
        let accounts = await CloudAccount.find({ userId: req.user.id });
        if (accounts.length === 0) {
            // Auto-seed defaults for new users
            const seeds = DEFAULT_CLOUDS.map(c => ({ ...c, userId: req.user.id }));
            accounts = await CloudAccount.insertMany(seeds);
        }
        res.json(accounts.map(a => ({
            id: a._id,
            provider: a.provider,
            status: a.status,
            regions: a.regions,
            lastSync: a.lastSync,
        })));
    } catch (err) {
        res.status(500).json({ message: 'Failed to fetch cloud accounts.' });
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
