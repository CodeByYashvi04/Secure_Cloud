require('dotenv').config();
const express = require('express');
const cors = require('cors');
const connectDB = require('./config/db');

const app = express();

// Connect to Database
connectDB();

// Middleware
app.use(express.json());
app.use(cors());

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/dashboard', require('./routes/dashboard'));
app.use('/api/vault', require('./routes/vault'));
app.use('/api/cloud', require('./routes/cloud'));
app.use('/api/activity', require('./routes/activity'));

// Placeholder for other routes
app.get('/', (req, res) => {
    res.send('CloudSecure API is running...');
});

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
