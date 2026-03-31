const { GoogleGenerativeAI } = require('@google/generative-ai');
require('dotenv').config();

async function listModels() {
    try {
        const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
        const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
        
        console.log("Checking model availability...");
        // This is a dummy call to see if the model exists
        const result = await model.generateContent("test");
        console.log("Model 'gemini-1.5-flash' is AVAILABLE.");
    } catch (err) {
        console.error("Error with 'gemini-1.5-flash':", err.message);
        
        try {
          const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
          // Try to list models
          console.log("Attempting to list all available models...");
          // Note: listModels is not a direct method on genAI, but on the API client if using lower level.
          // In @google/generative-ai, listModels might not be exposed easily in some versions.
          // Let's try gemini-pro fallback
          const model2 = genAI.getGenerativeModel({ model: "gemini-pro" });
          await model2.generateContent("test");
          console.log("Model 'gemini-pro' is AVAILABLE.");
        } catch (err2) {
          console.error("Error with 'gemini-pro':", err2.message);
        }
    }
}

listModels();
