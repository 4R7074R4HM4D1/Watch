# Testing the Server on Windows

You can test the server component right now on Windows while you prepare to test the Watch app on macOS.

## Quick Start

1. **Install Node.js** (if not already installed):
   - Download from: https://nodejs.org/
   - Install the LTS version

2. **Install dependencies**:
   ```powershell
   npm install express
   ```
   Or rename `server-example-package.json` to `package.json` and run:
   ```powershell
   npm install
   ```

3. **Run the server**:
   ```powershell
   node server-example.js
   ```

4. **Test the server**:
   - Open browser: http://localhost:3000/health
   - Should see: `{"status":"ok"}`

## Testing Upload Endpoint

You can test the upload endpoint with a sample JSON file:

```powershell
# Using PowerShell
$body = Get-Content -Path "sample-data.json" -Raw
Invoke-RestMethod -Uri "http://localhost:3000/upload" -Method Post -Body $body -ContentType "application/json" -Headers @{"X-Filename"="test.json"}
```

Or use curl (if installed):
```bash
curl -X POST http://localhost:3000/upload -H "Content-Type: application/json" -H "X-Filename: test.json" -d @sample-data.json
```

