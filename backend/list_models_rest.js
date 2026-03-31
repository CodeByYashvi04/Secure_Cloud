const axios = require('axios');
require('dotenv').config();

async function listModels() {
    const key = process.env.GEMINI_API_KEY;
    if (!key) {
        console.error("No GEMINI_API_KEY found in .env");
        return;
    }

    try {
        console.log(`Using Key: ${key.substring(0, 8)}...`);
        console.log("Fetching available models from Gemini REST API...");
        const url = `https://generativelanguage.googleapis.com/v1beta/models?key=${key}`;
        const res = await axios.get(url);
        
        console.log("Full API Response Keys:", Object.keys(res.data));

        if (res.data && res.data.models && res.data.models.length > 0) {
            console.log("\n--- AVAILABLE MODELS ---");
            res.data.models.forEach(m => {
                console.log(`- ${m.name} (${m.displayName})`);
            });
            console.log("------------------------\n");
        } else {
            console.log("!!! No models found in this project. Is the API enabled? !!!");
            console.log("Raw Response Data:", JSON.stringify(res.data, null, 2));
        }
    } catch (err) {
        console.error("REST API Error Status:", err.response ? err.response.status : 'No Status');
        console.error("REST API Error Data:", JSON.stringify(err.response ? err.response.data : err.message, null, 2));
    }
}

listModels();
