const axios = require('axios');

async function testChat() {
    try {
        const res = await axios.post('http://localhost:5000/api/ai/chat', 
            { message: 'Hello AI' },
            { headers: { 'x-auth-token': 'YOUR_TOKEN_HERE' } }
        );
        console.log('Response:', res.data);
    } catch (err) {
        console.error('Error:', err.response ? err.response.data : err.message);
    }
}

testChat();
