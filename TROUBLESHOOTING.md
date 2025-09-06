# 🔧 Typing Racer Pro - Troubleshooting Guide

## 🚨 "Connection Refused" Issue

If you're getting a "connection refused" error when trying to access `localhost:3000`, here are several solutions:

### ✅ Solution 1: Try Alternative URLs
The server is configured to bind to all interfaces. Try these URLs:
- `http://localhost:3000`
- `http://127.0.0.1:3000`
- `http://0.0.0.0:3000`

### ✅ Solution 2: Check Server Status
Run these commands to verify the server is running:

```bash
# Check if the server process is running
ps aux | grep "node server.js" | grep -v grep

# Test the server with curl
curl -I http://localhost:3000

# Check what's using port 3000
lsof -i :3000  # (if available)
```

### ✅ Solution 3: Restart the Server
```bash
# Stop any existing server
pkill -f "node server.js"

# Start fresh
node server.js
```

### ✅ Solution 4: Use the Start Script
```bash
# Make it executable (if not already)
chmod +x start-game.sh

# Run the start script
./start-game.sh
```

### ✅ Solution 5: Different Port
If port 3000 is blocked, try a different port:

```bash
# Set a different port
PORT=8080 node server.js

# Then access: http://localhost:8080
```

### ✅ Solution 6: Browser Issues
- **Clear browser cache** and cookies
- **Try incognito/private mode**
- **Try a different browser** (Chrome, Firefox, Safari)
- **Disable browser extensions** that might block connections

### ✅ Solution 7: Firewall/Security Software
- Check if your **firewall** is blocking port 3000
- Temporarily **disable antivirus** web protection
- Check **corporate network restrictions**

### ✅ Solution 8: Environment-Specific Issues

#### For Windows Users:
```bash
# Try these alternatives
http://localhost:3000
http://127.0.0.1:3000
http://[::1]:3000
```

#### For Docker/Container Users:
```bash
# Make sure ports are properly mapped
docker run -p 3000:3000 your-container
```

#### For WSL Users:
```bash
# Access from Windows host
http://localhost:3000
# Or find WSL IP
ip addr show eth0
```

### ✅ Solution 9: Manual Server Start with Logs
```bash
# Start with verbose logging
DEBUG=* node server.js

# Or check for errors
node server.js 2>&1 | tee server.log
```

### ✅ Solution 10: Check Dependencies
```bash
# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install

# Start server
npm start
```

## 🔍 Diagnostic Commands

Run these to get more information:

```bash
# Check Node.js version
node --version

# Check npm version
npm --version

# Check if port is in use
netstat -an | grep 3000  # (if available)
ss -tlnp | grep 3000     # (if available)

# Check server logs
tail -f server.log       # (if log file exists)
```

## 🌐 Network Configuration

### Local Development
The server binds to `0.0.0.0:3000` which should accept connections from:
- `localhost:3000`
- `127.0.0.1:3000`
- Your machine's IP address

### Remote Access
If you need to access from another machine:
1. Find your IP address: `ip addr` or `ifconfig`
2. Access via: `http://YOUR_IP:3000`
3. Make sure firewall allows incoming connections

## 📱 Mobile/Tablet Access

To access from mobile devices on the same network:
1. Find your computer's IP address
2. Access: `http://YOUR_COMPUTER_IP:3000`
3. Ensure both devices are on the same network

## 🆘 Still Not Working?

### Quick Test
```bash
# Test if the server responds locally
curl -v http://localhost:3000

# Expected: Should return HTML content
# If this works but browser doesn't, it's a browser issue
```

### Alternative Method
If nothing else works, you can:
1. Open the `index.html` file directly in your browser
2. Note: Leaderboard features won't work without the server
3. But the core typing game will still function

### Contact Information
If you're still having issues:
1. Check the console logs in your browser (F12 → Console)
2. Look for any JavaScript errors
3. Check the Network tab for failed requests
4. Try the diagnostic commands above

---

## ✨ Expected Behavior When Working

When everything is working correctly, you should see:
- 🏁 Beautiful racing game interface
- 🎮 Functional typing input with real-time feedback
- 🏎️ Animated cars moving as you type
- ⚡ Power-up buttons that are clickable
- 📊 Leaderboard panel that slides in from the right
- 🎯 Achievement notifications when you unlock them

The game is fully functional and has been tested to work correctly!