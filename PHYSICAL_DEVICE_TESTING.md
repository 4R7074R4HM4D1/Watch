# Physical Device Testing Guide

## Finding Your Mac's IP Address

When testing on a physical Apple Watch, you need to use your Mac's IP address instead of `localhost`.

### Method 1: System Settings (macOS Ventura+)
1. Open **System Settings**
2. Click **Network**
3. Select your active connection (Wi-Fi or Ethernet)
4. Your IP address is shown (e.g., `192.168.1.100`)

### Method 2: Terminal
```bash
# For Wi-Fi
ipconfig getifaddr en0

# For Ethernet
ipconfig getifaddr en1

# Or get all IPs
ifconfig | grep "inet " | grep -v 127.0.0.1
```

### Method 3: Network Utility
1. Open **Network Utility** (Spotlight: `Network Utility`)
2. Click **Info** tab
3. Select your interface
4. IP address is shown

## Updating Server URL for Physical Device

1. Open `DataManager.swift` in Xcode
2. Find the `serverURL` property
3. Replace with your Mac's IP:
   ```swift
   private let serverURL = "http://192.168.1.100:3000/upload"
   ```
   (Replace `192.168.1.100` with your actual IP)

## Important Notes

### Firewall
- Ensure your Mac's firewall allows incoming connections on port 3000
- Go to **System Settings → Network → Firewall**
- Add Node.js or allow port 3000

### Same Network
- Your Mac and Apple Watch must be on the same Wi-Fi network
- Apple Watch uses the iPhone's network connection

### Testing Steps
1. Start server on Mac: `node server-example.js`
2. Note your Mac's IP address
3. Update `DataManager.swift` with the IP
4. Build and run on physical Watch
5. Test upload functionality

## Alternative: Use ngrok for External Testing

If you want to test from anywhere:

1. **Install ngrok**: `brew install ngrok` or download from ngrok.com
2. **Start your server**: `node server-example.js`
3. **Create tunnel**: `ngrok http 3000`
4. **Use ngrok URL**: Update `serverURL` with the ngrok URL (e.g., `https://abc123.ngrok.io/upload`)

Note: Free ngrok URLs change on restart. For production, use a permanent server.

