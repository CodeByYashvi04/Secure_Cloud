require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');
const Activity = require('./models/Activity');
const Alert = require('./models/Alert');

const seedData = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/cloudsecure');
        
        // Clear existing data
        await User.deleteMany();
        await Activity.deleteMany();
        await Alert.deleteMany();

        // Create Admin User
        const admin = new User({
            name: 'Security Admin',
            email: 'admin@cloudsecure.com',
            password: 'password123',
            role: 'Admin'
        });
        await admin.save();

        // Create Mock Activities
        const activities = [
            {
                userId: admin._id,
                action: 'AWS Console Login',
                service: 'AWS',
                location: 'India',
                ipAddress: '192.168.1.1',
                deviceInfo: 'Laptop (Windows)',
                riskScore: 5
            },
            {
                userId: admin._id,
                action: 'S3 Bucket Accessible',
                service: 'AWS',
                location: 'USA',
                ipAddress: '45.33.22.1',
                deviceInfo: 'Unknown Device',
                riskScore: 45
            }
        ];
        await Activity.insertMany(activities);

        // Create Mock Alerts
        const alerts = [
            {
                userId: admin._id,
                type: 'Critical',
                title: 'Large Data Download',
                description: 'Over 50GB of data downloaded from S3-Production bucket.',
                source: 'AWS S3',
                riskScore: 85
            },
            {
                userId: admin._id,
                type: 'High',
                title: 'Unusual Login Location',
                description: 'Login attempt detected from Russia.',
                source: 'Azure AD',
                riskScore: 75
            }
        ];
        await Alert.insertMany(alerts);

        console.log('Database Seeded Successfully!');
        process.exit();
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
};

seedData();
