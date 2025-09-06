const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const bodyParser = require('body-parser');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const { v4: uuidv4 } = require('uuid');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(express.static(path.join(__dirname)));

// Database setup
const db = new sqlite3.Database('./leaderboard.db');

// Initialize database tables
db.serialize(() => {
    db.run(`
        CREATE TABLE IF NOT EXISTS scores (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            wpm INTEGER NOT NULL,
            accuracy INTEGER NOT NULL,
            time REAL NOT NULL,
            difficulty TEXT NOT NULL,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    `);
    
    db.run(`
        CREATE TABLE IF NOT EXISTS daily_stats (
            date DATE PRIMARY KEY,
            total_races INTEGER DEFAULT 0,
            average_wpm REAL DEFAULT 0,
            highest_wpm INTEGER DEFAULT 0,
            total_players INTEGER DEFAULT 0
        )
    `);
    
    // Create indexes for better performance
    db.run(`CREATE INDEX IF NOT EXISTS idx_timestamp ON scores(timestamp)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_wpm ON scores(wpm)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_difficulty ON scores(difficulty)`);
});

// Utility functions
function getDateFilter(filter) {
    const now = new Date();
    let dateFilter;
    
    switch (filter) {
        case 'daily':
            dateFilter = new Date(now.getFullYear(), now.getMonth(), now.getDate());
            break;
        case 'weekly':
            const weekStart = new Date(now);
            weekStart.setDate(now.getDate() - now.getDay());
            weekStart.setHours(0, 0, 0, 0);
            dateFilter = weekStart;
            break;
        case 'alltime':
        default:
            dateFilter = new Date('2020-01-01');
            break;
    }
    
    return dateFilter.toISOString();
}

function calculateScore(wpm, accuracy, difficulty) {
    const difficultyMultiplier = {
        'easy': 1.0,
        'medium': 1.2,
        'hard': 1.5,
        'expert': 2.0,
        'nightmare': 3.0
    };
    
    const baseScore = wpm * (accuracy / 100);
    return Math.round(baseScore * (difficultyMultiplier[difficulty] || 1.0));
}

function validateScore(scoreData) {
    const { name, wpm, accuracy, time, difficulty } = scoreData;
    
    // Basic validation
    if (!name || name.length < 1 || name.length > 20) return false;
    if (wpm < 0 || wpm > 300) return false; // Reasonable WPM limits
    if (accuracy < 0 || accuracy > 100) return false;
    if (time < 1 || time > 600) return false; // 1 second to 10 minutes
    if (!['easy', 'medium', 'hard', 'expert', 'nightmare'].includes(difficulty)) return false;
    
    // Advanced validation - check if scores are realistic
    const expectedTime = (wpm > 0) ? (60 / wpm) * 10 : 0; // Rough estimate for 50 characters
    if (time < expectedTime * 0.3) return false; // Too fast
    
    return true;
}

// API Routes
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

app.get('/api/leaderboard/:filter?', (req, res) => {
    const filter = req.params.filter || 'daily';
    const dateFilter = getDateFilter(filter);
    
    const query = `
        SELECT name, wpm, accuracy, time, difficulty, timestamp,
               (wpm * (accuracy / 100.0) * 
                CASE difficulty 
                    WHEN 'easy' THEN 1.0
                    WHEN 'medium' THEN 1.2
                    WHEN 'hard' THEN 1.5
                    WHEN 'expert' THEN 2.0
                    WHEN 'nightmare' THEN 3.0
                    ELSE 1.0
                END) as score
        FROM scores 
        WHERE timestamp >= ?
        ORDER BY score DESC, wpm DESC, accuracy DESC
        LIMIT 50
    `;
    
    db.all(query, [dateFilter], (err, rows) => {
        if (err) {
            console.error('Database error:', err);
            return res.status(500).json({ error: 'Database error' });
        }
        
        res.json(rows);
    });
});

app.get('/api/stats', (req, res) => {
    const queries = {
        totalRaces: 'SELECT COUNT(*) as count FROM scores',
        averageWPM: 'SELECT AVG(wpm) as avg FROM scores',
        highestWPM: 'SELECT MAX(wpm) as max FROM scores',
        totalPlayers: 'SELECT COUNT(DISTINCT name) as count FROM scores',
        todayRaces: `SELECT COUNT(*) as count FROM scores WHERE date(timestamp) = date('now')`,
        difficultyStats: `
            SELECT difficulty, COUNT(*) as count, AVG(wpm) as avg_wpm, MAX(wpm) as max_wpm
            FROM scores 
            GROUP BY difficulty
        `
    };
    
    const stats = {};
    let completed = 0;
    const total = Object.keys(queries).length;
    
    Object.entries(queries).forEach(([key, query]) => {
        db.all(query, [], (err, rows) => {
            if (!err) {
                if (key === 'difficultyStats') {
                    stats[key] = rows;
                } else {
                    stats[key] = rows[0];
                }
            }
            
            completed++;
            if (completed === total) {
                res.json(stats);
            }
        });
    });
});

// Socket.IO events
io.on('connection', (socket) => {
    console.log('User connected:', socket.id);
    
    // Send initial leaderboard
    socket.emit('leaderboard_update', []);
    
    socket.on('get_leaderboard', (data) => {
        const filter = data.filter || 'daily';
        const dateFilter = getDateFilter(filter);
        
        const query = `
            SELECT name, wpm, accuracy, time, difficulty, timestamp,
                   (wpm * (accuracy / 100.0) * 
                    CASE difficulty 
                        WHEN 'easy' THEN 1.0
                        WHEN 'medium' THEN 1.2
                        WHEN 'hard' THEN 1.5
                        WHEN 'expert' THEN 2.0
                        WHEN 'nightmare' THEN 3.0
                        ELSE 1.0
                    END) as score
            FROM scores 
            WHERE timestamp >= ?
            ORDER BY score DESC, wpm DESC, accuracy DESC
            LIMIT 50
        `;
        
        db.all(query, [dateFilter], (err, rows) => {
            if (!err) {
                socket.emit('leaderboard_update', rows);
            }
        });
    });
    
    socket.on('submit_score', (scoreData) => {
        // Validate the score data
        if (!validateScore(scoreData)) {
            socket.emit('score_submitted', { 
                success: false, 
                error: 'Invalid score data' 
            });
            return;
        }
        
        const id = uuidv4();
        const score = calculateScore(scoreData.wpm, scoreData.accuracy, scoreData.difficulty);
        
        const query = `
            INSERT INTO scores (id, name, wpm, accuracy, time, difficulty, timestamp)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        `;
        
        db.run(query, [
            id,
            scoreData.name.trim(),
            scoreData.wpm,
            scoreData.accuracy,
            scoreData.time,
            scoreData.difficulty,
            scoreData.timestamp || new Date().toISOString()
        ], function(err) {
            if (err) {
                console.error('Database error:', err);
                socket.emit('score_submitted', { 
                    success: false, 
                    error: 'Failed to save score' 
                });
                return;
            }
            
            socket.emit('score_submitted', { 
                success: true, 
                id: id,
                score: score
            });
            
            // Broadcast updated leaderboard to all clients
            const dateFilter = getDateFilter('daily');
            const query = `
                SELECT name, wpm, accuracy, time, difficulty, timestamp,
                       (wpm * (accuracy / 100.0) * 
                        CASE difficulty 
                            WHEN 'easy' THEN 1.0
                            WHEN 'medium' THEN 1.2
                            WHEN 'hard' THEN 1.5
                            WHEN 'expert' THEN 2.0
                            WHEN 'nightmare' THEN 3.0
                            ELSE 1.0
                        END) as score
                FROM scores 
                WHERE timestamp >= ?
                ORDER BY score DESC, wpm DESC, accuracy DESC
                LIMIT 50
            `;
            
            db.all(query, [dateFilter], (err, rows) => {
                if (!err) {
                    io.emit('leaderboard_update', rows);
                }
            });
            
            // Update daily stats
            updateDailyStats();
        });
    });
    
    socket.on('disconnect', () => {
        console.log('User disconnected:', socket.id);
    });
});

function updateDailyStats() {
    const today = new Date().toISOString().split('T')[0];
    
    const statsQuery = `
        SELECT 
            COUNT(*) as total_races,
            AVG(wpm) as average_wpm,
            MAX(wpm) as highest_wpm,
            COUNT(DISTINCT name) as total_players
        FROM scores 
        WHERE date(timestamp) = ?
    `;
    
    db.get(statsQuery, [today], (err, stats) => {
        if (!err && stats) {
            const updateQuery = `
                INSERT OR REPLACE INTO daily_stats 
                (date, total_races, average_wpm, highest_wpm, total_players)
                VALUES (?, ?, ?, ?, ?)
            `;
            
            db.run(updateQuery, [
                today,
                stats.total_races,
                stats.average_wpm || 0,
                stats.highest_wpm || 0,
                stats.total_players
            ]);
        }
    });
}

// Cleanup old scores (keep only last 30 days for performance)
function cleanupOldScores() {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    
    db.run(
        'DELETE FROM scores WHERE timestamp < ?',
        [thirtyDaysAgo.toISOString()],
        function(err) {
            if (!err) {
                console.log(`Cleaned up ${this.changes} old scores`);
            }
        }
    );
}

// Run cleanup daily
setInterval(cleanupOldScores, 24 * 60 * 60 * 1000);

// Error handling
process.on('uncaughtException', (err) => {
    console.error('Uncaught Exception:', err);
});

process.on('unhandledRejection', (err) => {
    console.error('Unhandled Rejection:', err);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM received, shutting down gracefully');
    server.close(() => {
        db.close((err) => {
            if (err) {
                console.error('Error closing database:', err);
            }
            process.exit(0);
        });
    });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`🏁 Typing Racer Pro server running on port ${PORT}`);
    console.log(`🌐 Open http://localhost:${PORT} to play!`);
    
    // Initialize some sample data if database is empty
    db.get('SELECT COUNT(*) as count FROM scores', (err, row) => {
        if (!err && row.count === 0) {
            console.log('📊 Adding sample leaderboard data...');
            
            const sampleScores = [
                { name: 'SpeedDemon', wpm: 95, accuracy: 98, time: 45.2, difficulty: 'hard' },
                { name: 'TypeMaster', wpm: 87, accuracy: 96, time: 52.1, difficulty: 'medium' },
                { name: 'KeyboardNinja', wpm: 102, accuracy: 94, time: 41.8, difficulty: 'expert' },
                { name: 'FastFingers', wpm: 78, accuracy: 99, time: 48.7, difficulty: 'medium' },
                { name: 'RacingPro', wpm: 89, accuracy: 97, time: 46.3, difficulty: 'hard' }
            ];
            
            sampleScores.forEach((score, index) => {
                const timestamp = new Date();
                timestamp.setHours(timestamp.getHours() - index);
                
                db.run(`
                    INSERT INTO scores (id, name, wpm, accuracy, time, difficulty, timestamp)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                `, [
                    uuidv4(),
                    score.name,
                    score.wpm,
                    score.accuracy,
                    score.time,
                    score.difficulty,
                    timestamp.toISOString()
                ]);
            });
        }
    });
});