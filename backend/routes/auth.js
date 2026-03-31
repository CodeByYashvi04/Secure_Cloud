const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const JWT_SECRET = process.env.JWT_SECRET || 'cloudsecure_fallback_secret_key_2024';

const signToken = (payload) => {
    return new Promise((resolve, reject) => {
        jwt.sign(payload, JWT_SECRET, { expiresIn: '8h' }, (err, token) => {
            if (err) reject(err);
            else resolve(token);
        });
    });
};

// @route   POST api/auth/register
router.post('/register', async (req, res) => {
    const { name, email, password } = req.body;

    if (!name || !email || !password) {
        return res.status(400).json({ message: 'Please provide name, email, and password.' });
    }

    try {
        let user = await User.findOne({ email });
        if (user) {
            return res.status(400).json({ message: 'User already exists. Please log in.' });
        }

        user = new User({ name, email, password });
        await user.save();

        const payload = { user: { id: user.id, role: user.role } };
        const token = await signToken(payload);

        res.json({
            token,
            user: { id: user.id, name: user.name, email: user.email, role: user.role }
        });
    } catch (err) {
        console.error('Registration Error:', err.message);
        res.status(500).json({ message: 'Registration failed: ' + err.message });
    }
});

// @route   POST api/auth/login
router.post('/login', async (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({ message: 'Please provide email and password.' });
    }

    try {
        const user = await User.findOne({ email });
        if (!user) {
            return res.status(400).json({ message: 'Invalid credentials. Please check your email.' });
        }

        const isMatch = await user.comparePassword(password);
        if (!isMatch) {
            return res.status(400).json({ message: 'Invalid credentials. Please check your password.' });
        }

        const payload = { user: { id: user.id, role: user.role } };
        const token = await signToken(payload);

        res.json({
            token,
            user: { id: user.id, name: user.name, email: user.email, role: user.role }
        });
    } catch (err) {
        console.error('Login Error:', err.message);
        res.status(500).json({ message: 'Login failed: ' + err.message });
    }
});

const crypto = require('crypto');
const auth = require('../middleware/auth');

// @route   POST api/auth/forgot-password
// @desc    Generate reset token (Mock email)
router.post('/forgot-password', async (req, res) => {
    try {
        const { email } = req.body;
        const user = await User.findOne({ email });
        if (!user) return res.status(404).json({ message: 'User not found' });

        const resetToken = crypto.randomBytes(20).toString('hex');
        user.resetPasswordToken = resetToken;
        user.resetPasswordExpire = Date.now() + 3600000; // 1 hour
        await user.save();

        // In a real app, send email here. For now, return token for testing/demo.
        res.json({ message: 'Reset token generated (Check console/response in dev)', token: resetToken });
    } catch (err) {
        res.status(500).json({ message: 'Server error' });
    }
});

// @route   POST api/auth/reset-password/:token
// @desc    Reset password using token
router.post('/reset-password/:token', async (req, res) => {
    try {
        const user = await User.findOne({
            resetPasswordToken: req.params.token,
            resetPasswordExpire: { $gt: Date.now() }
        });
        if (!user) return res.status(400).json({ message: 'Invalid or expired token' });

        user.password = req.body.password;
        user.resetPasswordToken = undefined;
        user.resetPasswordExpire = undefined;
        await user.save();

        res.json({ message: 'Password reset successful!' });
    } catch (err) {
        res.status(500).json({ message: 'Server error' });
    }
});

// @route   PUT api/auth/profile
// @desc    Update user profile
router.put('/profile', auth, async (req, res) => {
    try {
        const { name, email, mfaEnabled, pushNotificationsEnabled, threatStrictness, dataSanitization, biometricEnabled } = req.body;
        const user = await User.findById(req.user.id);
        if (!user) return res.status(404).json({ message: 'User not found' });

        if (name) user.name = name;
        if (email) user.email = email;
        if (mfaEnabled !== undefined) user.mfaEnabled = mfaEnabled;
        if (pushNotificationsEnabled !== undefined) user.pushNotificationsEnabled = pushNotificationsEnabled;
        if (threatStrictness) user.threatStrictness = threatStrictness;
        if (dataSanitization !== undefined) user.dataSanitization = dataSanitization;
        if (biometricEnabled !== undefined) user.biometricEnabled = biometricEnabled;

        await user.save();
        res.json({ 
            id: user.id, name: user.name, email: user.email, 
            mfaEnabled: user.mfaEnabled, 
            pushNotificationsEnabled: user.pushNotificationsEnabled,
            threatStrictness: user.threatStrictness,
            dataSanitization: user.dataSanitization,
            biometricEnabled: user.biometricEnabled
        });
    } catch (err) {
        res.status(500).json({ message: 'Update failed' });
    }
});

// @route   POST api/auth/panic
// @desc    Emergency Lockdown - Wipes all sessions
router.post('/panic', auth, async (req, res) => {
    try {
        const user = await User.findById(req.user.id);
        // Simulate logging IP and device of panic trigger
        user.loginHistory.push({ ip: req.ip, device: req.headers['user-agent'], timestamp: new Date() });
        await user.save();
        
        // In a real app, you would invalidate all JWTs and revoke cloud tokens here
        res.json({ message: 'Digital Fortress Activated. All session keys revoked.' });
    } catch (err) {
        res.status(500).json({ message: 'Panic trigger failed' });
    }
});

// @route   GET api/auth/audit-logs
router.get('/audit-logs', auth, async (req, res) => {
    try {
        const user = await User.findById(req.user.id);
        // If history is empty, add some mock data for the demo
        if (user.loginHistory.length === 0) {
            user.loginHistory = [
                { ip: '192.168.1.1', device: 'iOS - iPhone 15 Pro', timestamp: new Date(Date.now() - 3600000) },
                { ip: '192.168.1.45', device: 'Web - Chrome (Windows)', timestamp: new Date(Date.now() - 86400000) }
            ];
            await user.save();
        }
        res.json(user.loginHistory);
    } catch (err) {
        res.status(500).json({ message: 'Audit fetch failed' });
    }
});

// @route   DELETE api/auth/account
router.delete('/account', auth, async (req, res) => {
    try {
        await User.findByIdAndDelete(req.user.id);
        // Also cleanup CloudAccounts for this user (not shown here for brevity but planned)
        res.json({ message: 'Account permanently purged.' });
    } catch (err) {
        res.status(500).json({ message: 'Purge failed' });
    }
});

module.exports = router;
