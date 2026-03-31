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
const CloudAccount = require('../models/CloudAccount');

// @route   GET api/dashboard/summary
// @desc    Unified dashboard data (Stats + History + Activities) to reduce API roundtrips
// @access  Private
router.get('/summary', auth, async (req, res) => {
    try {
        const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

        const [totalAlerts, recentActivities, cloudCount, historyData] = await Promise.all([
            Alert.countDocuments({ userId: req.user.id, isDismissed: false }),
            Activity.find({ userId: req.user.id }).sort({ timestamp: -1 }).limit(5),
            CloudAccount.countDocuments({ userId: req.user.id }),
            Alert.aggregate([
                { $match: { userId: new require('mongoose').Types.ObjectId(req.user.id), timestamp: { $gte: sevenDaysAgo } } },
                { $group: { 
                    _id: { $dateToString: { format: "%a", date: "$timestamp" } },
                    risk: { $sum: "$riskScore" } 
                } }
            ])
        ]);

        const riskScore = Math.min(totalAlerts * 15, 100) || 5;

        // Process history map for UI
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        const historyMap = Object.fromEntries(historyData.map(h => [h._id, Math.min(h.risk, 100)]));
        const history = days.map(day => ({ 
            day, 
            risk: historyMap[day] || (Math.floor(Math.random() * 10) + 5) // Baseline if no alerts for that day
        }));

        res.json({
            stats: {
                riskScore,
                connectedClouds: cloudCount || 0,
                activeSessions: recentActivities.length || 0,
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
        const [totalAlerts, recentActivities, cloudCount] = await Promise.all([
            Alert.countDocuments({ userId: req.user.id, isDismissed: false }),
            Activity.find({ userId: req.user.id }).sort({ timestamp: -1 }).limit(5),
            CloudAccount.countDocuments({ userId: req.user.id })
        ]);
        
        const calculatedRisk = Math.min(totalAlerts * 15, 100);

        res.json({
            riskScore: calculatedRisk || 5,
            connectedClouds: cloudCount || 0,
            activeSessions: recentActivities.length || 0,
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
        const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
        const historyData = await Alert.aggregate([
            { $match: { userId: new require('mongoose').Types.ObjectId(req.user.id), timestamp: { $gte: sevenDaysAgo } } },
            { $group: { 
                _id: { $dateToString: { format: "%a", date: "$timestamp" } },
                risk: { $sum: "$riskScore" } 
            } }
        ]);

        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        const historyMap = Object.fromEntries(historyData.map(h => [h._id, Math.min(h.risk, 100)]));
        const history = days.map(day => ({ 
            day, 
            risk: historyMap[day] || (Math.floor(Math.random() * 10) + 5)
        }));

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
