# 🏁 Typing Racer Pro - Global Championship

An advanced and fun typing racing game with a global leaderboard, power-ups, achievements, and competitive AI opponents!

## 🎮 Features

### Core Gameplay
- **Real-time typing racing** with visual car progress
- **5 difficulty levels**: Easy, Medium, Hard, Expert, and Nightmare
- **WPM and accuracy tracking** with live updates
- **AI competitors** with different skill levels
- **Dynamic text generation** with varied content for each difficulty

### Advanced Features
- **Power-ups system**:
  - ⚡ Speed Boost (+20% WPM for 10 seconds)
  - 🛡️ Accuracy Shield (No penalties for 5 seconds)
  - ❄️ Time Freeze (Pause opponents for 3 seconds)
- **Achievement system** with unlockable rewards
- **Global leaderboard** with daily, weekly, and all-time rankings
- **Real-time multiplayer** support via Socket.IO
- **Beautiful animations** and visual effects
- **Responsive design** for all devices

### Technical Highlights
- **Real-time WebSocket communication**
- **SQLite database** for persistent leaderboards
- **Advanced score validation** and anti-cheat measures
- **Performance optimized** with efficient algorithms
- **Modern UI/UX** with glassmorphism design
- **Easter eggs** (try the Konami code!)

## 🚀 Quick Start

### Prerequisites
- Node.js (v14 or higher)
- npm or yarn

### Installation

1. **Clone or download** the project files
2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Start the server**:
   ```bash
   npm start
   ```

4. **Open your browser** and go to:
   ```
   http://localhost:3000
   ```

5. **Start racing!** 🏎️

### Development Mode
For development with auto-restart:
```bash
npm run dev
```

## 🎯 How to Play

### Basic Controls
- **Click** the typing input or press **Enter** to start a race
- **Type** the displayed text as accurately and quickly as possible
- **Use power-ups** by clicking them or pressing **1, 2, 3** keys
- **Reset** the race anytime with the Reset button

### Power-ups Strategy
- **Speed Boost**: Best used when you're behind or need to catch up
- **Accuracy Shield**: Use when facing difficult words or punctuation
- **Time Freeze**: Perfect for overtaking opponents in the final stretch

### Difficulty Levels
- **Easy**: Simple sentences and common words
- **Medium**: Longer paragraphs with varied vocabulary
- **Hard**: Complex sentences with technical terms
- **Expert**: Advanced concepts and specialized terminology
- **Nightmare**: Highly technical content with complex punctuation

### Scoring System
Your score is calculated based on:
- **WPM (Words Per Minute)**: Higher is better
- **Accuracy**: Percentage of correctly typed characters
- **Difficulty Multiplier**: Higher difficulties give more points
- **Final Score**: `WPM × (Accuracy/100) × Difficulty Multiplier`

## 🏆 Achievements

Unlock achievements by reaching various milestones:
- **First Steps**: Complete your first race
- **Speed Demon**: Reach 60+ WPM
- **Accuracy Master**: Achieve 95%+ accuracy
- **Lightning Fast**: Reach 100+ WPM
- **Perfectionist**: Complete a race with 100% accuracy

## 📊 Leaderboard

The global leaderboard features:
- **Daily Rankings**: Today's best performers
- **Weekly Rankings**: This week's champions
- **All-Time Rankings**: The greatest typists ever
- **Real-time updates** when new scores are submitted
- **Score validation** to ensure fair competition

## 🛠️ Technical Details

### Frontend Technologies
- **HTML5** with semantic markup
- **CSS3** with modern features (Grid, Flexbox, Animations)
- **Vanilla JavaScript** (ES6+) for game logic
- **Socket.IO Client** for real-time communication
- **Font Awesome** for icons
- **Google Fonts** for typography

### Backend Technologies
- **Node.js** with Express framework
- **Socket.IO** for real-time WebSocket communication
- **SQLite3** for local database storage
- **CORS** for cross-origin requests
- **UUID** for unique score identification

### Database Schema
```sql
-- Scores table
CREATE TABLE scores (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    wpm INTEGER NOT NULL,
    accuracy INTEGER NOT NULL,
    time REAL NOT NULL,
    difficulty TEXT NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Daily stats table
CREATE TABLE daily_stats (
    date DATE PRIMARY KEY,
    total_races INTEGER DEFAULT 0,
    average_wpm REAL DEFAULT 0,
    highest_wpm INTEGER DEFAULT 0,
    total_players INTEGER DEFAULT 0
);
```

## 🎨 Customization

### Adding New Texts
Edit the `textSets` object in `game.js` to add new typing challenges:

```javascript
const textSets = {
    easy: [
        "Your new easy text here...",
        // Add more texts
    ],
    // Add to other difficulties
};
```

### Modifying Power-ups
Adjust power-up effects in the `activatePowerup` method:

```javascript
case 'speedBoost':
    // Modify duration, multiplier, etc.
    break;
```

### Styling Changes
Customize the appearance by editing `styles.css`. The design uses CSS custom properties for easy theming.

## 🐛 Troubleshooting

### Common Issues

1. **Port already in use**:
   ```bash
   # Change port in server.js or kill existing process
   lsof -ti:3000 | xargs kill -9
   ```

2. **Database locked**:
   ```bash
   # Remove database file to reset
   rm leaderboard.db
   ```

3. **Socket connection issues**:
   - Check firewall settings
   - Ensure port 3000 is accessible
   - Try restarting the server

### Performance Tips
- Close unused browser tabs for better performance
- Use Chrome or Firefox for best WebSocket support
- Ensure stable internet connection for leaderboard features

## 📈 Future Enhancements

Potential improvements for future versions:
- **Multiplayer races** with live opponents
- **Custom text uploads** by users
- **Voice narration** for accessibility
- **Mobile app** version
- **Tournament system** with brackets
- **Typing lessons** and tutorials
- **Statistics dashboard** with detailed analytics
- **Themes and customization** options

## 🤝 Contributing

Feel free to contribute to this project by:
- Reporting bugs and issues
- Suggesting new features
- Improving the codebase
- Adding new typing texts
- Enhancing the UI/UX

## 📄 License

This project is licensed under the MIT License - see the package.json file for details.

## 🎉 Credits

Created with ❤️ using modern web technologies. Special thanks to:
- **Socket.IO** for real-time communication
- **Font Awesome** for beautiful icons
- **Google Fonts** for typography
- **The typing community** for inspiration

---

**Ready to race? Start your engines and may the fastest typer win!** 🏁🎮