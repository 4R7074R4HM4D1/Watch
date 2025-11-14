# Flask Server Setup Guide

Python Flask server for receiving sensor data from the iOS Watch app.

## Prerequisites

- Python 3.7 or higher
- pip (Python package manager)

## Installation

1. **Install Python dependencies**:
   ```bash
   pip install -r requirements.txt
   ```
   
   Or install manually:
   ```bash
   pip install Flask flask-cors
   ```

## Running the Server

### Basic Usage

```bash
python3 server-flask.py
```

Or on Windows:
```bash
python server-flask.py
```

The server will start on `http://localhost:5000`

### For Physical Device Testing

The server is configured to accept connections from any IP address (`0.0.0.0`), so you can access it from your Apple Watch using your Mac's IP address:

```
http://YOUR_MAC_IP:5000/upload
```

## Endpoints

### POST /upload
Receives sensor data from the Watch app.

**Headers:**
- `Content-Type: application/json`
- `X-Filename: sensor_data_2024-01-01_12-00-00.json` (optional)

**Body:**
JSON object containing sensor data (see `sample-data.json` for format)

**Response:**
```json
{
  "success": true,
  "message": "File uploaded successfully",
  "filename": "sensor_data_2024-01-01_12-00-00.json",
  "fileSize": 12345,
  "statistics": {
    "accelerometer": 1000,
    "gyroscope": 1000,
    "magnetometer": 500,
    "deviceMotion": 1000,
    "altimeter": 100
  },
  "totalSamples": 3600
}
```

### GET /health
Health check endpoint.

**Response:**
```json
{
  "status": "ok",
  "service": "Sensor Data Upload Server",
  "uploads_dir": "uploads"
}
```

### GET /
API information and usage instructions.

## Testing the Server

### 1. Health Check
```bash
curl http://localhost:5000/health
```

### 2. Test Upload
```bash
curl -X POST http://localhost:5000/upload \
  -H "Content-Type: application/json" \
  -H "X-Filename: test.json" \
  -d @sample-data.json
```

Or using Python:
```python
import requests

with open('sample-data.json', 'r') as f:
    data = json.load(f)

response = requests.post(
    'http://localhost:5000/upload',
    json=data,
    headers={'X-Filename': 'test.json'}
)
print(response.json())
```

## Updating Watch App

Update `DataManager.swift` to use the Flask server:

```swift
private let serverURL = "http://localhost:5000/upload"
```

For physical device testing:
```swift
private let serverURL = "http://192.168.1.100:5000/upload"  // Replace with your Mac's IP
```

## File Storage

All uploaded files are saved in the `uploads/` directory with their original filenames.

## Production Deployment

For production use:

1. **Disable debug mode**:
   ```python
   app.run(host='0.0.0.0', port=5000, debug=False)
   ```

2. **Use a production WSGI server** (e.g., Gunicorn):
   ```bash
   pip install gunicorn
   gunicorn -w 4 -b 0.0.0.0:5000 server-flask:app
   ```

3. **Set up reverse proxy** (nginx, Apache) for HTTPS

4. **Configure firewall** to allow port 5000

5. **Use environment variables** for configuration:
   ```python
   import os
   port = int(os.getenv('PORT', 5000))
   debug = os.getenv('DEBUG', 'False').lower() == 'true'
   ```

## Troubleshooting

### Port Already in Use
If port 5000 is already in use, change it:
```python
app.run(host='0.0.0.0', port=5001, debug=True)
```

### Connection Refused
- Ensure firewall allows connections on the port
- For physical device, ensure Mac and Watch are on same network
- Check that server is running and accessible

### CORS Errors
The server includes `flask-cors` which should handle CORS automatically. If you still see errors, check the CORS configuration.

## Comparison with Node.js Server

| Feature | Flask (Python) | Node.js (Express) |
|---------|---------------|-------------------|
| Language | Python | JavaScript |
| Setup | `pip install Flask flask-cors` | `npm install express` |
| Port | 5000 (default) | 3000 (default) |
| File saving | Same | Same |
| CORS | flask-cors | Manual headers |

Both servers provide the same functionality. Choose based on your preference!

