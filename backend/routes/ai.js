const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const Alert = require('../models/Alert');
const CloudAccount = require('../models/CloudAccount');
const Activity = require('../models/Activity');

// Initialize Gemini
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || '');

// @route   POST api/ai/chat
// @desc    Real-time AI Security Assistant with App Context
// @access  Private
router.post('/chat', auth, async (req, res) => {
    try {
        const { message } = req.body;
        if (!message) return res.status(400).json({ message: 'Message is required' });

        if (!process.env.GEMINI_API_KEY) {
            return res.json({ 
                reply: "I'm sorry, my neural link (API Key) is currently disconnected. Please ask the administrator to add GEMINI_API_KEY to the server environments." 
            });
        }

        // 1. Gather User Context for the AI (with resilience)
        let alerts = [], clouds = [], activity = [];
        try {
            [alerts, clouds, activity] = await Promise.all([
                Alert.find({ userId: req.user.id, isDismissed: false }).limit(5),
                CloudAccount.find({ userId: req.user.id }),
                Activity.find({ userId: req.user.id }).sort({ timestamp: -1 }).limit(3)
            ]);
        } catch (e) {
            console.warn('[AI] Context gathering failed, proceeding without DB context.');
        }

        const contextPrompt = `
            You are "CloudSecure AI", a professional security assistant for the CloudSecure app.
            
            USER CONTEXT:
            - Connected Clouds: ${clouds.map(c => c.provider).join(', ') || 'None'}
            - Active Alerts: ${alerts.length} (${alerts.map(a => a.type + ': ' + a.title).join('; ') || 'None'})
            - Recent Activity: ${activity.map(a => a.action).join(', ') || 'None'}

            APP FEATURES:
            - "Dashboard/HQ": Shows real-time risk scores and activity trends.
            - "Vault": Secure file storage with military-grade encryption and anomaly detection.
            - "Alerts": Detailed breakdown of security incidents.
            - "Monitor": Real-time status of multi-cloud (AWS, GCP, Azure) connections.

            INSTRUCTIONS:
            - Be concise, professional, and slightly futuristic.
            - Help the user navigate the app or explain security risks based on their context.
            - If they ask about a specific threat, use the context provided above.
            - Do not answer questions unrelated to security or this app.
        `;

        const modelName = "gemini-pro"; 
        console.log(`[AI] Attempting AI generation with model: ${modelName}`);

        const model = genAI.getGenerativeModel({ model: modelName });
        
        // Generate content with a timeout/safety
        const result = await model.generateContent([contextPrompt, message]);
        const response = await result.response;
        const text = response.text();

        if (!text) {
            throw new Error('Empty response from AI engine');
        }

        res.json({ reply: text });

    } catch (err) {
        console.error('[AI Chat Error]', err);
        
        let errorReply = "I encountered an internal error while processing your request.";
        if (err.message.includes('API_KEY_INVALID')) {
            errorReply = "My security key (API Key) seems to be invalid. Please verify the GEMINI_API_KEY environment variable.";
        } else if (err.message.includes('quota')) {
            errorReply = "I've hit my daily security quota. Please try again in a bit.";
        } else if (err.message.includes('safety')) {
            errorReply = "I cannot fulfill that request as it triggers my internal safety protocols. Let's stick to security and cloud monitoring!";
        } else {
            errorReply = `Secure link interrupted: ${err.message}`;
        }

        res.json({ reply: errorReply });
    }
});

module.exports = router;
