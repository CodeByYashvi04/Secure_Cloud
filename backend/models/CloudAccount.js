const mongoose = require('mongoose');

const CloudAccountSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    provider: { type: String, enum: ['AWS', 'GCP', 'Azure'], required: true },
    status: { type: String, enum: ['Active', 'Issues Detected', 'Disconnected'], default: 'Active' },
    regions: { type: [String], default: [] },
    lastSync: { type: Date, default: Date.now }
});

module.exports = mongoose.model('CloudAccount', CloudAccountSchema);
