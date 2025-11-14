# iOS Watch Sensor Collector App

An iOS Watch app that collects sensor data (accelerometer, gyroscope, magnetometer, device motion, and altimeter) at the highest possible frequency and uploads it to a server.

## Features

- **High-frequency sensor data collection**:
  - Accelerometer: 100 Hz
  - Gyroscope: 100 Hz
  - Magnetometer: 50 Hz
  - Device Motion: 100 Hz (includes attitude, rotation rate, gravity, user acceleration, magnetic field)
  - Altimeter: Available when supported

- **Simple UI**: Single button to start/stop recording sessions
- **Automatic upload**: Data is automatically uploaded to your server when a session ends
- **JSON format**: All data is saved and uploaded in JSON format with timestamps

## Setup Instructions

### 1. Create Xcode Project

1. Open Xcode
2. Create a new project:
   - Choose **watchOS** → **App**
   - Product Name: `SensorCollector`
   - Interface: **SwiftUI**
   - Language: **Swift**

### 2. Add Files to Project

Copy all files from the `WatchApp/` directory into your Xcode project:
- `WatchApp.swift` (replace the default)
- `ContentView.swift`
- `SensorManager.swift`
- `DataManager.swift`
- `Info.plist` (merge with existing or add required keys)

### 3. Configure Info.plist

Add the following to your WatchKit Extension's `Info.plist`:
- `NSMotionUsageDescription`: "This app needs access to motion sensors to collect accelerometer, gyroscope, and other sensor data."

### 4. Configure Server URL

Edit `DataManager.swift` and update the `serverURL` constant with your server endpoint:

```swift
private let serverURL = "https://your-server.com/upload"
```

### 5. Server Requirements

Your server should accept POST requests with:
- Content-Type: `application/json`
- Header: `X-Filename` (contains the filename)
- Body: JSON data containing the sensor session data

Example server endpoint (Node.js/Express):

```javascript
app.post('/upload', (req, res) => {
  const filename = req.headers['x-filename'];
  const data = req.body;
  
  // Save data to file or database
  fs.writeFileSync(`uploads/${filename}`, JSON.stringify(data, null, 2));
  
  res.status(200).send('OK');
});
```

## Usage

1. Launch the app on your Apple Watch
2. Tap **"Start Session"** to begin collecting sensor data
3. The app will continuously collect data from all available sensors
4. Tap **"Stop & Upload"** to end the session and upload the data
5. The upload status will be displayed briefly

## Data Format

The collected data is saved as JSON with the following structure:

```json
{
  "accelerometer": [
    {
      "timestamp": 1234567890.123,
      "x": 0.1,
      "y": 0.2,
      "z": 0.3
    }
  ],
  "gyroscope": [...],
  "magnetometer": [...],
  "deviceMotion": [
    {
      "timestamp": 1234567890.123,
      "attitude": {
        "roll": 0.1,
        "pitch": 0.2,
        "yaw": 0.3
      },
      "rotationRate": {...},
      "gravity": {...},
      "userAcceleration": {...},
      "magneticField": {...}
    }
  ],
  "altimeter": [
    {
      "timestamp": 1234567890.123,
      "relativeAltitude": 0.5,
      "pressure": 101325.0
    }
  ],
  "startTime": "2024-01-01T12:00:00Z"
}
```

## Notes

- Sensor update frequencies are set to the maximum supported rates (100 Hz for most sensors)
- Data is collected in memory during the session and written to disk when the session ends
- The app requires watchOS 7.0 or later
- Make sure your Apple Watch has sufficient battery and storage space for long recording sessions

## Troubleshooting

- **No sensor data**: Check that motion permissions are granted in Watch Settings
- **Upload fails**: Verify the server URL is correct and the server is accessible
- **Memory issues**: For very long sessions, consider implementing data streaming or periodic saves

