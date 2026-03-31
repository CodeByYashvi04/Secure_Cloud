const mongoose = require('mongoose');

const ActivitySchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    action: {
        type: String,
        required: true
    },
    service: {
        type: String,
        required: true
    },
    location: {
        type: String,
        default: 'Unknown'
    },
    ipAddress: {
        type: String
    },
    deviceInfo: {
        type: String
    },
    riskScore: {
        type: Number,
        default: 0
    },
    timestamp: {
        type: Date,
        default: Date.now
    }
});

ActivitySchema.index({ userId: 1, timestamp: -1 });

module.exports = mongoose.model('Activity', ActivitySchema);
