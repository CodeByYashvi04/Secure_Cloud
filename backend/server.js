require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const connectDB = require('./config/db');

const app = express();
const server = http.createServer(app);

// Setup Socket.IO
const io = new Server(server, {
    cors: {
        origin: '*', // Allow all origins for mobile connection
        methods: ['GET', 'POST']
    }
});

// Make io accessible to our router
app.set('io', io);

io.on('connection', (socket) => {
    console.log(`[Socket] A client connected: ${socket.id}`);
    
    // Optional: Clients can join a room based on their userID
    socket.on('join', (userId) => {
        if (userId) {
            socket.join(userId);
            console.log(`[Socket] Client ${socket.id} joined room: ${userId}`);
        }
    });

    socket.on('disconnect', () => {
        console.log(`[Socket] A client disconnected: ${socket.id}`);
    });
});

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
app.use('/api/ai', require('./routes/ai'));

// Global error handler
app.use((err, req, res, next) => {
    res.send('CloudSecure API is running...');
});

// Placeholder for other routes
app.get('/', (req, res) => {
    res.send('CloudSecure API is running...');
});

const PORT = process.env.PORT || 5000;

server.listen(PORT, '0.0.0.0', () => console.log(`Server running on port ${PORT} (with WebSockets)`));
