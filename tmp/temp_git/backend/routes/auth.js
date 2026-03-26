const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const JWT_SECRET = process.env.JWT_SECRET || 'cloudsecure_fallback_secret_key_2024';

const signToken = (payload) => {
    return new Promise((resolve, reject) => {
        jwt.sign(payload, JWT_SECRET, { expiresIn: '8h' }, (err, token) => {
            if (err) reject(err);
            else resolve(token);
        });
    });
};

// @route   POST api/auth/register
router.post('/register', async (req, res) => {
    const { name, email, password } = req.body;

    if (!name || !email || !password) {
        return res.status(400).json({ message: 'Please provide name, email, and password.' });
    }

    try {
        let user = await User.findOne({ email });
        if (user) {
            return res.status(400).json({ message: 'User already exists. Please log in.' });
        }

        user = new User({ name, email, password });
        await user.save();

        const payload = { user: { id: user.id, role: user.role } };
        const token = await signToken(payload);

        res.json({
            token,
            user: { id: user.id, name: user.name, email: user.email, role: user.role }
        });
    } catch (err) {
        console.error('Registration Error:', err.message);
        res.status(500).json({ message: 'Registration failed: ' + err.message });
    }
});

// @route   POST api/auth/login
router.post('/login', async (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({ message: 'Please provide email and password.' });
    }

    try {
        const user = await User.findOne({ email });
        if (!user) {
            return res.status(400).json({ message: 'Invalid credentials. Please check your email.' });
        }

        const isMatch = await user.comparePassword(password);
        if (!isMatch) {
            return res.status(400).json({ message: 'Invalid credentials. Please check your password.' });
        }

        const payload = { user: { id: user.id, role: user.role } };
        const token = await signToken(payload);

        res.json({
            token,
            user: { id: user.id, name: user.name, email: user.email, role: user.role }
        });
    } catch (err) {
        console.error('Login Error:', err.message);
        res.status(500).json({ message: 'Login failed: ' + err.message });
    }
});

module.exports = router;
