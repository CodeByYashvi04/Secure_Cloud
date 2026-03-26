const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Activity = require('../models/Activity');
const Alert = require('../models/Alert');

// @route   GET api/dashboard/stats
// @desc    Get dashboard overview stats
// @access  Private
router.get('/stats', auth, async (req, res) => {
    try {
        const totalAlerts = await Alert.countDocuments({ userId: req.user.id, isDismissed: false });
        const recentActivities = await Activity.find({ userId: req.user.id }).sort({ timestamp: -1 }).limit(5);
        
        // Mocking some stats for now
        res.json({
            riskScore: 12,
            connectedClouds: 3,
            activeSessions: 1,
            totalAlerts,
            recentActivities
        });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   GET api/dashboard/alerts
// @desc    Get all active alerts
// @access  Private
router.get('/alerts', auth, async (req, res) => {
    try {
        const alerts = await Alert.find({ userId: req.user.id, isDismissed: false }).sort({ timestamp: -1 });
        res.json(alerts);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

module.exports = router;
