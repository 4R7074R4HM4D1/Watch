// Example Node.js server for testing sensor data uploads
// Run with: node server-example.js

const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = 3000;

// Create uploads directory if it doesn't exist
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir);
}

// Middleware to parse JSON
app.use(express.json({ limit: '50mb' }));

// CORS headers (if needed)
app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type, X-Filename');
    if (req.method === 'OPTIONS') {
        res.sendStatus(200);
    } else {
        next();
    }
});

// Upload endpoint
app.post('/upload', (req, res) => {
    try {
        const filename = req.headers['x-filename'] || `sensor_data_${Date.now()}.json`;
        const data = req.body;
        
        // Save to file
        const filePath = path.join(uploadsDir, filename);
        fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
        
        console.log(`Received upload: ${filename} (${JSON.stringify(data).length} bytes)`);
        console.log(`  - Accelerometer samples: ${data.accelerometer?.length || 0}`);
        console.log(`  - Gyroscope samples: ${data.gyroscope?.length || 0}`);
        console.log(`  - Magnetometer samples: ${data.magnetometer?.length || 0}`);
        console.log(`  - Device Motion samples: ${data.deviceMotion?.length || 0}`);
        console.log(`  - Altimeter samples: ${data.altimeter?.length || 0}`);
        
        res.status(200).json({ 
            success: true, 
            message: 'File uploaded successfully',
            filename: filename 
        });
    } catch (error) {
        console.error('Upload error:', error);
        res.status(500).json({ 
            success: false, 
            error: error.message 
        });
    }
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'ok' });
});

app.listen(PORT, () => {
    console.log(`Sensor data upload server running on http://localhost:${PORT}`);
    console.log(`Upload endpoint: http://localhost:${PORT}/upload`);
    console.log(`Uploads will be saved to: ${uploadsDir}`);
});

