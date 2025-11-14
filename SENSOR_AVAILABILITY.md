# Sensor Availability Guide

## Understanding Sensor Availability

Not all sensors are available on all devices or in simulators. Here's what to expect:

### Apple Watch Simulator
- **Accelerometer**: Usually available (simulated data)
- **Gyroscope**: Often NOT available
- **Magnetometer**: Often NOT available  
- **Device Motion**: Usually available (provides combined sensor data)
- **Altimeter**: Usually NOT available

### Physical Apple Watch
- **Accelerometer**: ✅ Available on all models
- **Gyroscope**: ✅ Available on Series 2 and later
- **Magnetometer**: ✅ Available on Series 5 and later
- **Device Motion**: ✅ Available on all models (combines multiple sensors)
- **Altimeter**: ✅ Available on Series 3 and later

## Important: Device Motion Includes Gyroscope Data

Even if the **Gyroscope** sensor is not available, **Device Motion** provides rotation rate data which is equivalent to gyroscope readings. Device Motion combines:
- Rotation rate (gyroscope-like)
- User acceleration (accelerometer-like)
- Gravity
- Attitude (orientation)
- Magnetic field (if available)

## What This Means

If you see:
- ✅ **Device Motion** active
- ⚠️ **Gyroscope** not available

**You're still getting rotation/gyroscope data!** Device Motion includes `rotationRate` which provides the same information as the gyroscope sensor.

## Checking Available Sensors

The app will show you which sensors are active when you start a session. Look for the status message that shows:
- "✅ X sensor(s) active: Accelerometer, Device Motion, ..."

## Recommendations

1. **For Testing**: Use a physical Apple Watch (Series 2+) for best results
2. **For Development**: Simulator is fine - Device Motion will still provide useful data
3. **Data Collection**: Device Motion alone provides comprehensive motion data even if individual sensors aren't available

## Data Structure

When Device Motion is available, you'll get:
```json
{
  "deviceMotion": [
    {
      "rotationRate": { "x": ..., "y": ..., "z": ... },  // Gyroscope data
      "userAcceleration": { "x": ..., "y": ..., "z": ... },  // Accelerometer data
      "gravity": { "x": ..., "y": ..., "z": ... },
      "attitude": { "roll": ..., "pitch": ..., "yaw": ... },
      "magneticField": { "x": ..., "y": ..., "z": ... }
    }
  ]
}
```

So even without individual gyroscope/accelerometer sensors, Device Motion provides all the data you need!

