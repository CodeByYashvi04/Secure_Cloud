const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Activity = require('../models/Activity');

// @route   GET api/activity/logs
// @desc    Get activity logs for user
// @access  Private
router.get('/logs', auth, async (req, res) => {
    try {
        const logs = await Activity.find({ userId: req.user.id })
            .sort({ timestamp: -1 })
            .limit(50);
        res.json(logs);
    } catch (err) {
        res.status(500).json({ message: 'Failed to fetch activity logs.' });
    }
});

// @route   POST api/activity/log
// @desc    Create a new activity log entry
// @access  Private
router.post('/log', auth, async (req, res) => {
    try {
        const { action, service, ipAddress, riskScore } = req.body;
        const log = new Activity({
            userId: req.user.id,
            action: action || 'User Action',
            service: service || 'App',
            ipAddress: ipAddress || req.ip || '0.0.0.0',
            riskScore: riskScore || 0,
        });
        await log.save();
        res.json(log);
    } catch (err) {
        res.status(500).json({ message: 'Failed to create log.' });
    }
});

module.exports = router;
