const mongoose = require('mongoose');

const AlertSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    type: {
        type: String,
        enum: ['Low', 'Medium', 'High', 'Critical'],
        required: true
    },
    title: {
        type: String,
        required: true
    },
    description: {
        type: String
    },
    source: {
        type: String,
        required: true
    },
    riskScore: {
        type: Number,
        required: true
    },
    isDismissed: {
        type: Boolean,
        default: false
    },
    timestamp: {
        type: Date,
        default: Date.now
    }
});

AlertSchema.index({ userId: 1, isDismissed: 1, timestamp: -1 });

module.exports = mongoose.model('Alert', AlertSchema);
