#!/usr/bin/env python3
"""
Flask server for receiving sensor data uploads from iOS Watch app
Run with: python3 server-flask.py
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import os
from datetime import datetime

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Create uploads directory if it doesn't exist
UPLOADS_DIR = 'uploads'
if not os.path.exists(UPLOADS_DIR):
    os.makedirs(UPLOADS_DIR)

@app.route('/upload', methods=['POST', 'OPTIONS'])
def upload():
    """Receive and save sensor data from Watch app"""
    try:
        # Handle preflight OPTIONS request
        if request.method == 'OPTIONS':
            return '', 200
        
        # Get filename from header or generate one
        filename = request.headers.get('X-Filename')
        if not filename:
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            filename = f'sensor_data_{timestamp}.json'
        
        # Get JSON data from request body
        data = request.get_json()
        
        if not data:
            return jsonify({
                'success': False,
                'error': 'No data received'
            }), 400
        
        # Save to file
        filepath = os.path.join(UPLOADS_DIR, filename)
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        
        # Calculate statistics
        stats = {
            'accelerometer': len(data.get('accelerometer', [])),
            'gyroscope': len(data.get('gyroscope', [])),
            'magnetometer': len(data.get('magnetometer', [])),
            'deviceMotion': len(data.get('deviceMotion', [])),
            'altimeter': len(data.get('altimeter', []))
        }
        total_samples = sum(stats.values())
        
        # Log information
        file_size = os.path.getsize(filepath)
        print(f'\n✅ Received upload: {filename}')
        print(f'   File size: {file_size:,} bytes')
        print(f'   Total samples: {total_samples:,}')
        print(f'   - Accelerometer: {stats["accelerometer"]:,}')
        print(f'   - Gyroscope: {stats["gyroscope"]:,}')
        print(f'   - Magnetometer: {stats["magnetometer"]:,}')
        print(f'   - Device Motion: {stats["deviceMotion"]:,}')
        print(f'   - Altimeter: {stats["altimeter"]:,}')
        print(f'   Saved to: {filepath}\n')
        
        return jsonify({
            'success': True,
            'message': 'File uploaded successfully',
            'filename': filename,
            'fileSize': file_size,
            'statistics': stats,
            'totalSamples': total_samples
        }), 200
        
    except json.JSONDecodeError as e:
        print(f'❌ JSON decode error: {e}')
        return jsonify({
            'success': False,
            'error': f'Invalid JSON: {str(e)}'
        }), 400
        
    except Exception as e:
        print(f'❌ Upload error: {e}')
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'ok',
        'service': 'Sensor Data Upload Server',
        'uploads_dir': UPLOADS_DIR
    }), 200

@app.route('/', methods=['GET'])
def index():
    """Root endpoint with API information"""
    return jsonify({
        'service': 'Sensor Data Upload Server',
        'version': '1.0.0',
        'endpoints': {
            'POST /upload': 'Upload sensor data from Watch app',
            'GET /health': 'Health check',
            'GET /': 'This information'
        },
        'usage': {
            'upload': 'POST /upload with JSON body and X-Filename header',
            'example': 'curl -X POST http://localhost:5000/upload -H "Content-Type: application/json" -H "X-Filename: test.json" -d @sample-data.json'
        }
    }), 200

if __name__ == '__main__':
    print('=' * 60)
    print('Sensor Data Upload Server (Flask)')
    print('=' * 60)
    print(f'Server running on http://localhost:5000')
    print(f'Upload endpoint: http://localhost:5000/upload')
    print(f'Health check: http://localhost:5000/health')
    print(f'Uploads will be saved to: {os.path.abspath(UPLOADS_DIR)}')
    print('=' * 60)
    print('Press Ctrl+C to stop the server\n')
    
    # Run the server
    app.run(
        host='0.0.0.0',  # Allow connections from any IP (for physical device testing)
        port=3000,
        debug=True  # Set to False in production
    )

