const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Activity = require('../models/Activity');
const Alert = require('../models/Alert');

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

const axios = require('axios');

// @route   POST api/activity/log
// @desc    Create a new activity log entry with AI analysis
// @access  Private
router.post('/log', auth, async (req, res) => {
    try {
        const { action, service, ipAddress } = req.body;
        
        let riskScore = 0;
        
        // Attempt to call AI Service
        try {
            const aiRes = await axios.post('http://localhost:8000/analyze', {
                logs: [{
                    userId: req.user.id,
                    service: service || 'App',
                    action: action || 'User Action',
                    ipAddress: ipAddress || req.ip || '0.0.0.0'
                }]
            });
            if (aiRes.data && aiRes.data.results) {
                riskScore = aiRes.data.results[0].riskScore;
            }
        } catch (aiErr) {
            console.log('AI Service offline, using default scoring.');
            // Basic heuristic fallback
            riskScore = action && action.toLowerCase().includes('failed') ? 50 : 10;
        }

        const log = new Activity({
            userId: req.user.id,
            action: action || 'User Action',
            service: service || 'App',
            ipAddress: ipAddress || req.ip || '0.0.0.0',
            riskScore,
        });
        await log.save();
        console.log(`Log saved with Risk Score: ${riskScore}`);

        // Generate Alert if risk is high (Lowered to 10 for testing)
        if (riskScore >= 10) {
            console.log('Creating security alert...');
            const alertType = riskScore >= 85 ? 'Critical' : (riskScore >= 70 ? 'High' : 'Medium');
            const newAlert = new Alert({
                userId: req.user.id,
                type: alertType,
                title: `${alertType} Risk Detected`,
                description: `Unusual activity: ${action} in ${service} (Score: ${riskScore})`,
                source: service || 'System',
                riskScore: riskScore
            });
            await newAlert.save();
            console.log('Alert saved successfully.');
        }

        res.json(log);
    } catch (err) {
        res.status(500).json({ message: 'Failed to create log.' });
    }
});

module.exports = router;
