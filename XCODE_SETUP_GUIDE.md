# Xcode Project Setup Guide

Complete step-by-step guide to create and configure the Sensor Collector Watch app in Xcode.

## Prerequisites

- macOS with Xcode installed (latest version recommended)
- Apple Developer account (free account works for simulator testing)
- Apple Watch (for physical device testing, optional for simulator)

---

## Step 1: Create New Project

1. **Open Xcode**
   - Launch Xcode from Applications or Spotlight

2. **Create New Project**
   - Click **"Create a new Xcode project"** or go to `File → New → Project...`
   - Or press `⌘ + Shift + N`

3. **Select Template**
   - Choose **watchOS** tab at the top
   - Select **App** template
   - Click **Next**

4. **Configure Project**
   - **Product Name**: `SensorCollector`
   - **Team**: Select your Apple Developer team (or "None" for simulator only)
   - **Organization Identifier**: `com.yourname` (e.g., `com.johndoe`)
   - **Bundle Identifier**: Will auto-generate as `com.yourname.SensorCollector`
   - **Interface**: **SwiftUI** ✓
   - **Language**: **Swift** ✓
   - *(Note: Newer Xcode versions don't show "Include Notification Scene" or "Include Complication" options - these are not needed for this app anyway)*
   - Click **Next**

5. **Choose Location**
   - Select where to save your project
   - **Create Git repository**: Optional (recommended)
   - Click **Create**

---

## Step 2: Project Structure Overview

After creation, you'll see:
```
SensorCollector/
├── SensorCollector Watch App/
│   ├── SensorCollectorApp.swift (default - we'll replace this)
│   └── Assets.xcassets
├── SensorCollector Watch App Extension/
│   └── (empty or minimal files)
└── SensorCollector.xcodeproj
```

---

## Step 3: Add Source Files

### Option A: Drag and Drop (Easiest)

1. **Open Finder** and navigate to the `WatchApp/` folder from this project

2. **In Xcode**, locate the **"SensorCollector Watch App"** group in the Project Navigator (left sidebar)

3. **Drag files** from Finder into the "SensorCollector Watch App" group:
   - `WatchApp.swift` (will replace `SensorCollectorApp.swift`)
   - `ContentView.swift`
   - `SensorManager.swift`
   - `DataManager.swift`

4. **When prompted**, choose:
   - ✅ **"Copy items if needed"** (if files are outside project folder)
   - ✅ **"Create groups"** (not folder references)
   - ✅ **Target**: "SensorCollector Watch App" should be checked
   - Click **Finish**

### Option B: Add Files Manually

1. **Right-click** on "SensorCollector Watch App" group in Project Navigator
2. Select **"Add Files to SensorCollector..."**
3. Navigate to and select all Swift files from `WatchApp/` folder
4. Ensure **"Copy items if needed"** is checked
5. Ensure **"SensorCollector Watch App"** target is checked
6. Click **Add**

---

## Step 4: Replace Default App File

1. **Delete** the default `SensorCollectorApp.swift`:
   - Right-click on `SensorCollectorApp.swift` in Project Navigator
   - Select **"Delete"**
   - Choose **"Move to Trash"**

2. **Verify** `WatchApp.swift` is in the project and has the `@main` attribute

---

## Step 5: Configure Info.plist (Add Motion Permission)

### Method 1: Using Target Info Tab (Easiest - Recommended)

1. **Select Project** in Project Navigator (top blue icon)

2. **Select "SensorCollector Watch App" target** (under TARGETS)

3. **Click the "Info" tab** at the top

4. **Add the permission**:
   - Look for any section that says "Custom" or "Custom Properties" or just a list of properties
   - If you see a **+** button, click it
   - If you don't see a + button, look for an empty row or "Add" option
   - In the key field (or dropdown), start typing: `Privacy - Motion Usage Description`
   - If that doesn't appear, type: `NSMotionUsageDescription` directly
   - Set the **Type** to: `String`
   - Set the **Value** to: `This app needs access to motion sensors to collect accelerometer, gyroscope, and other sensor data.`

   **Alternative**: If the Info tab is empty or confusing, use **Method 2** below (it's more reliable).

### Method 2: Using Info.plist File (Most Reliable - Use This If Method 1 Doesn't Work)

1. **Locate Info.plist**:
   - In Project Navigator, find **"SensorCollector Watch App"** group
   - Look for `Info.plist` (might be named `Info` or in a subfolder)

2. **Open Info.plist**:
   - Right-click on `Info.plist`
   - Select **"Open As" → "Source Code"** (this shows the raw XML)

3. **Add the permission**:
   - Find the `</dict>` closing tag near the end
   - Add these lines **before** the `</dict>` tag:
   ```xml
   <key>NSMotionUsageDescription</key>
   <string>This app needs access to motion sensors to collect accelerometer, gyroscope, and other sensor data.</string>
   ```

4. **Save** the file (`⌘ + S`)

### Method 3: Visual Editor (Alternative)

1. **Open Info.plist** in the visual editor (not source code)

2. **Add new row**:
   - Click the **+** button
   - In the key field, type: `NSMotionUsageDescription` (exactly as shown)
   - Set Type to: `String`
   - Set Value to: `This app needs access to motion sensors to collect accelerometer, gyroscope, and other sensor data.`

**Note**: If you don't see `NSMotionUsageDescription` in the dropdown, you can type it manually. The visual editor might show it as "Privacy - Motion Usage Description" but the actual key is `NSMotionUsageDescription`.

---

## ⚠️ Fix: "Multiple commands produce Info.plist" Error

If you get this build error, it means Xcode is trying to generate Info.plist automatically AND you have a manual Info.plist file. Here's how to fix it:

### Solution 1: Remove Manual Info.plist (Recommended)

1. **Find Info.plist** in Project Navigator
2. **Right-click** on `Info.plist` → **Delete** → **Move to Trash**
3. **Use Method 1 above** (Target Info Tab) to add the permission instead
4. **Clean Build Folder**: `Product → Clean Build Folder` (`⌘ + Shift + K`)
5. **Rebuild**: `⌘ + B`

### Solution 2: Remove from Build Phase (If Solution 1 doesn't work)

1. **Select Project** (blue icon) → **"SensorCollector Watch App" target**
2. **Click "Build Phases" tab**
3. **Expand "Copy Bundle Resources"**
4. **Find `Info.plist`** in the list
5. **Select it** and press **Delete** (or click **-** button)
6. **Clean Build Folder**: `⌘ + Shift + K`
7. **Rebuild**: `⌘ + B`

### Solution 3: Disable Auto-Generation (Alternative)

1. **Select Project** → **"SensorCollector Watch App" target**
2. **Click "Build Settings" tab**
3. **Search for**: `GENERATE_INFOPLIST_FILE`
4. **Set it to**: `NO`
5. **Clean Build Folder**: `⌘ + Shift + K`
6. **Rebuild**: `⌘ + B`

**Recommendation**: Use **Solution 1** - it's the modern approach. Modern Xcode projects don't need a manual Info.plist file; everything is managed through the Target Info tab.

---

## Step 6: Configure Build Settings

1. **Select Project** in Project Navigator (top blue icon)

2. **Select "SensorCollector Watch App" target** (under TARGETS)

3. **General Tab**:
   - **Deployment Info**:
     - **Minimum Deployments**: watchOS 7.0 or later (recommended: 9.0+)
   - **Signing & Capabilities**:
     - Ensure your Team is selected (for device testing)
     - Xcode will handle code signing automatically

4. **Build Settings Tab** (if needed):
   - Search for "Swift Language Version"
   - Ensure it's set to Swift 5 or later

---

## Step 7: Update Server URL

1. **Open** `DataManager.swift` in Xcode

2. **Find** the line:
   ```swift
   private let serverURL = "https://your-server.com/upload"
   ```

3. **Replace** with your actual server URL:
   ```swift
   private let serverURL = "http://localhost:3000/upload"  // For local testing
   // OR
   private let serverURL = "https://your-actual-server.com/upload"  // For production
   ```

---

## Step 8: Build and Run

### For Simulator:

1. **Select Scheme**:
   - At the top toolbar, click the scheme dropdown
   - Select **"SensorCollector Watch App"**
   - Select a simulator (e.g., "Apple Watch Series 9 (45mm)")

2. **Build**:
   - Press `⌘ + B` or click **Product → Build**
   - Wait for build to complete (check for errors)

3. **Run**:
   - Press `⌘ + R` or click the **Play** button
   - Wait for simulator to launch
   - The Watch app should appear in the simulator

### For Physical Device:

1. **Connect Apple Watch**:
   - Pair your Apple Watch with your Mac
   - Ensure it's unlocked and on your wrist

2. **Select Device**:
   - In scheme dropdown, select your physical Apple Watch

3. **Trust Developer** (first time only):
   - On your Watch: Settings → General → Device Management
   - Trust your developer certificate

4. **Build and Run**:
   - Press `⌘ + R`
   - App will install on your Watch

---

## Step 9: Test the App

1. **Launch the app** on Watch or simulator

2. **Grant Permissions**:
   - When prompted, allow motion sensor access
   - This is required for the app to work

3. **Test Recording**:
   - Tap **"Start Session"** button
   - Wait a few seconds (watch the sample count increase)
   - Tap **"Stop & Upload"** button
   - Check upload status message

4. **Verify Data**:
   - If using local server, check `uploads/` folder for JSON files
   - Verify data structure in the JSON file

---

## Step 10: Troubleshooting

### Common Issues:

**Issue: "Cannot find 'SensorManager' in scope"**
- **Solution**: Ensure all Swift files are added to the correct target
  - Select file → File Inspector (right panel) → Target Membership → Check "SensorCollector Watch App"

**Issue: "Motion permission not requested"**
- **Solution**: Verify `NSMotionUsageDescription` is in Info.plist
- Clean build folder: `Product → Clean Build Folder` (`⌘ + Shift + K`)

**Issue: "Upload fails"**
- **Solution**: 
  - Check server URL is correct
  - Ensure server is running
  - For simulator, use `http://localhost:3000/upload`
  - For physical device, use your Mac's IP: `http://192.168.1.X:3000/upload`

**Issue: "Build errors with CoreMotion"**
- **Solution**: Ensure you're targeting watchOS 7.0+ (CoreMotion is available)

**Issue: "App crashes on launch"**
- **Solution**: 
  - Check Console for error messages
  - Verify all files are properly added to target
  - Clean and rebuild project

**Issue: "Multiple commands produce Info.plist"**
- **Solution**: See "Fix: Multiple commands produce Info.plist" section above
  - Remove manual Info.plist file
  - Use Target Info tab instead (Method 1)
  - Clean build folder and rebuild

### Debugging Tips:

1. **View Console Logs**:
   - `View → Debug Area → Activate Console` (`⌘ + Shift + Y`)
   - Look for print statements and errors

2. **Check Device Logs**:
   - `Window → Devices and Simulators`
   - Select your device → View Device Logs

3. **Test Server Connection**:
   - Use the sample server on Windows/Mac
   - Test with `sample-data.json` first

---

## Step 11: Project Structure (Final)

Your project should look like this:

```
SensorCollector/
├── SensorCollector Watch App/
│   ├── WatchApp.swift          ← Main entry point
│   ├── ContentView.swift        ← UI
│   ├── SensorManager.swift      ← Sensor collection
│   ├── DataManager.swift        ← Data upload
│   ├── Info.plist              ← Permissions
│   └── Assets.xcassets         ← Images (if any)
├── SensorCollector Watch App Extension/
│   └── (may be empty)
└── SensorCollector.xcodeproj
```

---

## Next Steps

1. ✅ Test basic functionality in simulator
2. ✅ Test on physical Apple Watch
3. ✅ Set up your production server
4. ✅ Update server URL in `DataManager.swift`
5. ✅ Test end-to-end data collection and upload

---

## Quick Reference Commands

- **Build**: `⌘ + B`
- **Run**: `⌘ + R`
- **Stop**: `⌘ + .`
- **Clean Build**: `⌘ + Shift + K`
- **Show/Hide Navigator**: `⌘ + 0`
- **Show/Hide Debug Area**: `⌘ + Shift + Y`

---

## Additional Resources

- [Apple Watch Development Documentation](https://developer.apple.com/watchos/)
- [CoreMotion Framework Reference](https://developer.apple.com/documentation/coremotion)
- [SwiftUI for watchOS](https://developer.apple.com/documentation/swiftui)

Good luck with your project! 🚀

