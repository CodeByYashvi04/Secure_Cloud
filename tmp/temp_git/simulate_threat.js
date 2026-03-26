const API_URL = 'https://secure-cloud-d93x.onrender.com/api';

// --- ENTER YOUR CREDENTIALS HERE ---
const EMAIL = 'yashvi444@gmail.com'; 
const PASSWORD = 'yashvi444'; 

async function runSimulation() {
    try {
        console.log('Logging in to get auth token...');
        const loginRes = await fetch(`${API_URL}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: EMAIL, password: PASSWORD })
        });

        const loginData = await loginRes.json();
        if (!loginRes.ok) throw new Error(loginData.message || 'Login failed');

        const TOKEN = loginData.token;
        console.log('Login successful. Token acquired.');

        console.log('Simulating high-risk activity...');
        const res = await fetch(`${API_URL}/activity/log`, {
            method: 'POST',
            headers: { 
                'Content-Type': 'application/json',
                'x-auth-token': TOKEN 
            },
            body: JSON.stringify({
                action: 'Multiple Failed Login Attempts',
                service: 'AWS IAM',
                ipAddress: '192.168.1.100',
                riskScore: 85 // Manually send high risk score to ensure alert generation
            })
        });

        const data = await res.json();
        if (!res.ok) throw new Error(data.message || 'Log failed');

        console.log('Activity logged with Risk Score:', data.riskScore);
        console.log('SUCCESS: Check your "Alerts" tab in the Flutter app! 🚨');
    } catch (err) {
        console.error('Error:', err.message);
    }
}

runSimulation();
