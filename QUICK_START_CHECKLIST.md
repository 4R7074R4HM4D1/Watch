# Quick Start Checklist

Use this checklist when setting up the project in Xcode.

## Pre-Setup
- [ ] Xcode installed and updated
- [ ] Apple Developer account (free account works)
- [ ] Server ready (optional, can test later)

## Project Creation
- [ ] Created new watchOS App project
- [ ] Named project: `SensorCollector`
- [ ] Selected SwiftUI interface
- [ ] Selected Swift language
- [ ] Saved project to desired location

## File Setup
- [ ] Added `WatchApp.swift` to project
- [ ] Added `ContentView.swift` to project
- [ ] Added `SensorManager.swift` to project
- [ ] Added `DataManager.swift` to project
- [ ] Deleted default `SensorCollectorApp.swift`
- [ ] Verified all files are in "SensorCollector Watch App" target

## Configuration
- [ ] Added `NSMotionUsageDescription` to Info.plist
- [ ] Updated `serverURL` in `DataManager.swift`
- [ ] Set minimum deployment to watchOS 7.0+
- [ ] Selected development team (for device testing)

## Testing
- [ ] Built project successfully (`⌘ + B`)
- [ ] Ran in simulator (`⌘ + R`)
- [ ] Granted motion permissions when prompted
- [ ] Tested "Start Session" button
- [ ] Verified sample count increases
- [ ] Tested "Stop & Upload" button
- [ ] Verified upload status message appears

## Server Testing (Optional)
- [ ] Started test server (`node server-example.js`)
- [ ] Tested server health endpoint
- [ ] Verified upload endpoint receives data
- [ ] Checked `uploads/` folder for JSON files

## Troubleshooting
If you encounter issues:
- [ ] Checked all files are in correct target
- [ ] Cleaned build folder (`⌘ + Shift + K`)
- [ ] Verified Info.plist has motion permission
- [ ] Checked server URL is correct
- [ ] Reviewed console logs for errors

---

## Common First-Time Issues

**"Cannot find SensorManager"**
→ Check Target Membership for all Swift files

**"Permission not requested"**
→ Verify Info.plist has NSMotionUsageDescription

**"Upload fails"**
→ Check server URL and ensure server is running

**"Build errors"**
→ Clean build folder and rebuild

---

## Next Steps After Setup
1. Test basic functionality
2. Test on physical Apple Watch (if available)
3. Customize server URL for your needs
4. Test long recording sessions
5. Verify data quality in JSON files

