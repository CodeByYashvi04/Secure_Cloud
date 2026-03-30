const mongoose = require('mongoose');

const CloudAccountSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    provider: { type: String, enum: ['AWS', 'GCP', 'Azure'], required: true },
    accountId: { type: String, required: true }, // The discovered AWS account number, GCP project name, or Azure Subscription ID
    status: { type: String, enum: ['Active', 'Issues Detected', 'Disconnected'], default: 'Active' },
    regions: { type: [String], default: [] },
    lastSync: { type: Date, default: Date.now },
    
    // AWS specific fields
    encryptedApiKey: { type: String },
    encryptedApiSecret: { type: String },

    // GCP specific fields
    projectId: { type: String },
    clientEmail: { type: String },
    encryptedPrivateKey: { type: String }, // Large RSA key

    // Azure specific fields
    tenantId: { type: String },
    clientId: { type: String },
    encryptedClientSecret: { type: String }
});

module.exports = mongoose.model('CloudAccount', CloudAccountSchema);
