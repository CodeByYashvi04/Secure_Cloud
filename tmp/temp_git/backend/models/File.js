const mongoose = require('mongoose');

const FileSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    filename: { type: String, required: true },
    originalName: { type: String, required: true },
    size: { type: Number, required: true },
    mimetype: { type: String },
    data: { type: Buffer }, // Store actual file data for download
    status: { type: String, enum: ['Uploading', 'Scanning', 'Encrypted', 'Failed'], default: 'Scanning' },
    uploadedAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('File', FileSchema);
