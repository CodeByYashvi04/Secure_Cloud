const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const auth = require('../middleware/auth');
const File = require('../models/File');

// Store uploads in memory (no disk needed on Render free tier)
const storage = multer.memoryStorage();
const upload = multer({
    storage,
    limits: { fileSize: 10 * 1024 * 1024 }, // 10MB max
    fileFilter: (req, file, cb) => {
        cb(null, true); // Accept all file types
    }
});

// @route   POST api/vault/upload
// @desc    Upload a file
// @access  Private
router.post('/upload', auth, upload.single('file'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ message: 'No file provided.' });
        }

        const newFile = new File({
            userId: req.user.id,
            filename: `${Date.now()}_${req.file.originalname}`,
            originalName: req.file.originalname,
            size: req.file.size,
            mimetype: req.file.mimetype,
            status: 'Encrypted',
        });

        await newFile.save();

        // Simulate a scan delay then mark as encrypted
        setTimeout(async () => {
            newFile.status = 'Encrypted';
            await newFile.save();
        }, 3000);

        res.json({
            message: 'File uploaded and encrypted successfully.',
            file: {
                id: newFile._id,
                name: newFile.originalName,
                size: newFile.size,
                status: newFile.status,
                uploadedAt: newFile.uploadedAt,
            }
        });
    } catch (err) {
        console.error('Upload error:', err.message);
        res.status(500).json({ message: 'File upload failed: ' + err.message });
    }
});

// @route   GET api/vault/files
// @desc    Get all uploaded files for user
// @access  Private
router.get('/files', auth, async (req, res) => {
    try {
        const files = await File.find({ userId: req.user.id }).sort({ uploadedAt: -1 });
        res.json(files.map(f => ({
            id: f._id,
            name: f.originalName,
            size: f.size,
            status: f.status,
            uploadedAt: f.uploadedAt,
        })));
    } catch (err) {
        res.status(500).json({ message: 'Failed to fetch files.' });
    }
});

// @route   DELETE api/vault/files/:id
// @desc    Delete a file record
// @access  Private
router.delete('/files/:id', auth, async (req, res) => {
    try {
        await File.findOneAndDelete({ _id: req.params.id, userId: req.user.id });
        res.json({ message: 'File deleted.' });
    } catch (err) {
        res.status(500).json({ message: 'Failed to delete file.' });
    }
});

module.exports = router;
