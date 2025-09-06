#!/bin/bash

echo "🏁 Starting Typing Racer Pro..."
echo "================================="

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js first."
    exit 1
fi

# Check if dependencies are installed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Start the server
echo "🚀 Starting server on port 3000..."
echo "🌐 Open http://localhost:3000 in your browser to play!"
echo "⌨️  Press Ctrl+C to stop the server"
echo ""

node server.js