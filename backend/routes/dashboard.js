const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Activity = require('../models/Activity');
const Alert = require('../models/Alert');

// @route   GET api/dashboard/stats
// @desc    Get dashboard overview stats
// @access  Private
// @route   GET api/dashboard/summary
// @desc    Unified dashboard data (Stats + History + Activities) to reduce API roundtrips
// @access  Private
router.get('/summary', auth, async (req, res) => {
    try {
        const [totalAlerts, recentActivities] = await Promise.all([
            Alert.countDocuments({ userId: req.user.id, isDismissed: false }),
            Activity.find({ userId: req.user.id }).sort({ timestamp: -1 }).limit(5)
        ]);

        const riskScore = Math.min(totalAlerts * 15, 100) || 5;

        // Simulated history for now
        const history = [
            { day: 'Mon', risk: 10 },
            { day: 'Tue', risk: 25 },
            { day: 'Wed', risk: 15 },
            { day: 'Thu', risk: 45 },
            { day: 'Fri', risk: 30 },
            { day: 'Sat', risk: 60 },
            { day: 'Sun', risk: 20 },
        ];

        res.json({
            stats: {
                riskScore,
                connectedClouds: 3,
                activeSessions: 1,
                totalAlerts,
                recentActivities
            },
            history
        });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
});

// @route   GET api/dashboard/stats
router.get('/stats', auth, async (req, res) => {
    try {
        const [totalAlerts, recentActivities] = await Promise.all([
            Alert.countDocuments({ userId: req.user.id, isDismissed: false }),
            Activity.find({ userId: req.user.id }).sort({ timestamp: -1 }).limit(5)
        ]);
        
        const calculatedRisk = Math.min(totalAlerts * 15, 100);

        res.json({
            riskScore: calculatedRisk || 5,
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

// @route   GET api/dashboard/history
// @desc    Get risk history for charts
// @access  Private
router.get('/history', auth, async (req, res) => {
    try {
        // Send back some simulated history data for the line chart
        const history = [
            { day: 'Mon', risk: 10 },
            { day: 'Tue', risk: 25 },
            { day: 'Wed', risk: 15 },
            { day: 'Thu', risk: 45 },
            { day: 'Fri', risk: 30 },
            { day: 'Sat', risk: 60 },
            { day: 'Sun', risk: 20 },
        ];
        res.json(history);
    } catch (err) {
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
