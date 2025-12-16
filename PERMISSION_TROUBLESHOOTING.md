# Permission Troubleshooting Guide

## Issue: No Sensors Available / Permission Not Requested

### Common Causes:

1. **Running on Simulator**
   - Simulators don't have real sensors
   - Device Motion might work with simulated data
   - **Solution**: Test on a physical Apple Watch

2. **Info.plist Not Configured**
   - The `NSMotionUsageDescription` key must be in Info.plist
   - Must be in the **Watch App** target, not the extension

3. **Info.plist Not in Correct Target**
   - Ensure Info.plist is added to "SensorCollector Watch App" target
   - Check Target Membership in File Inspector

4. **Permission Already Denied**
   - If permission was denied, you need to reset it
   - Go to Watch Settings → Privacy → Motion & Fitness

## Step-by-Step Fix:

### 1. Verify Info.plist Configuration

**Check if Info.plist exists:**
- In Xcode, look for `Info.plist` in "SensorCollector Watch App" folder
- If it doesn't exist, you need to create it

**Verify the key is present:**
- Open Info.plist as Source Code
- Look for:
  ```xml
  <key>NSMotionUsageDescription</key>
  <string>This app needs access to motion sensors...</string>
  ```

### 2. Check Target Membership

1. Select `Info.plist` in Project Navigator
2. Open File Inspector (right panel)
3. Under "Target Membership", ensure "SensorCollector Watch App" is checked

### 3. Clean and Rebuild

1. **Clean Build Folder**: `Product → Clean Build Folder` (`⌘ + Shift + K`)
2. **Delete Derived Data** (optional):
   - `Xcode → Settings → Locations`
   - Click arrow next to Derived Data path
   - Delete the folder for your project
3. **Rebuild**: `⌘ + B`

### 4. Check Simulator vs Physical Device

**On Simulator:**
- Many sensors won't work
- Device Motion might provide simulated data
- Status will show "Simulator detected"

**On Physical Device:**
- All sensors should work (depending on Watch model)
- Permission prompt should appear on first use
- Check Watch Settings if permission was denied

### 5. Reset Permissions (Physical Device)

If permission was denied:

1. On Apple Watch: **Settings → Privacy → Motion & Fitness**
2. Find your app in the list
3. Toggle it OFF, then ON again
4. Or delete and reinstall the app

### 6. Verify Info.plist Location

The Info.plist must be in:
- **SensorCollector Watch App/** folder
- NOT in SensorCollector Watch App Extension/

### 7. Check Console Logs

When you start a session, check Xcode console for:
- `📱 Sensor Availability Check:` - Shows which sensors are available
- `✅ Accelerometer started` - Confirms sensor started
- `⚠️ Accelerometer not available` - Sensor unavailable

## Expected Behavior:

### First Launch (Physical Device):
1. Tap "Start Session"
2. Permission prompt appears: "SensorCollector would like to access Motion & Activity"
3. Tap "Allow"
4. Sensors start collecting data

### Simulator:
1. Tap "Start Session"
2. Status shows "Simulator detected"
3. Device Motion might work with simulated data
4. Other sensors likely won't work

## Quick Diagnostic Checklist:

- [ ] Info.plist exists in Watch App folder
- [ ] `NSMotionUsageDescription` key is in Info.plist
- [ ] Info.plist is added to Watch App target
- [ ] Clean build folder and rebuilt
- [ ] Testing on physical device (not simulator)
- [ ] Permission not denied in Settings
- [ ] Check console logs for sensor availability

## Still Not Working?

1. **Verify Info.plist is being used:**
   - Check Build Settings → Info.plist File path
   - Should point to your Info.plist

2. **Try creating Info.plist manually:**
   - Right-click Watch App folder → New File
   - Property List → Name it `Info.plist`
   - Add `NSMotionUsageDescription` key
   - Ensure target membership is correct

3. **Check Xcode version:**
   - Some older Xcode versions handle Info.plist differently
   - Try updating Xcode

4. **Test with minimal code:**
   - Create a simple test that just checks `isAccelerometerAvailable`
   - If this returns false, it's a permission/configuration issue

