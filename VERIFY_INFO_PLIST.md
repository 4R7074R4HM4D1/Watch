# How to Verify Info.plist Permission is Set

## Method 1: Check Target Info Tab

1. **Select Project** (blue icon) → **"SensorCollector Watch App" target**
2. **Click "Info" tab**
3. **Look for** `NSMotionUsageDescription` or `Privacy - Motion Usage Description`
4. **Verify** it has the value: `This app needs access to motion sensors to collect accelerometer, gyroscope, and other sensor data.`

If you see it here, it's configured! ✅

## Method 2: Check if Info.plist File Exists

1. In Project Navigator, look in **"SensorCollector Watch App"** folder
2. Look for `Info.plist` or just `Info`
3. If it doesn't exist, that's OK - modern Xcode manages it through the target

## Method 3: View Generated Info.plist

Even if you don't see Info.plist in the project, Xcode generates one. To verify:

1. **Build the project** (`⌘ + B`)
2. **Find the build product**:
   - Right-click on "SensorCollector Watch App" in Project Navigator
   - Select **"Show in Finder"** (or navigate to build folder)
   - Look for `Info.plist` in the build output
3. **Check the generated file** contains `NSMotionUsageDescription`

## Method 4: Check Build Settings

1. **Select Project** → **"SensorCollector Watch App" target**
2. **Build Settings tab**
3. **Search for**: `INFOPLIST_FILE`
4. **Verify** the path is correct (or empty if auto-generated)

## If Permission is Set But Still Not Working:

### 1. Clean and Rebuild
- `Product → Clean Build Folder` (`⌘ + Shift + K`)
- Delete app from Watch/Simulator
- Rebuild and reinstall

### 2. Check You're Testing on Physical Device
- Simulators don't request permissions the same way
- Physical Apple Watch will show permission prompt

### 3. Verify Target is Correct
- Make sure you added permission to **"SensorCollector Watch App"** target
- NOT the extension target

### 4. Check Console Output
- When you tap "Start Session", check Xcode console
- Look for the diagnostic output showing sensor availability
- This will tell you if sensors are actually available

## Quick Test:

1. Add/verify permission in Target Info tab
2. Clean build folder
3. Delete app from device/simulator
4. Rebuild and run
5. Tap "Start Session"
6. Check console for diagnostic output

The console will show:
- `📱 Sensor Availability Check:` - tells you what's available
- `⚠️ Running on Simulator` - if on simulator
- `✅ Accelerometer started` - if sensor started

