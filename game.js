class TypingRacerPro {
    constructor() {
        this.gameState = 'waiting'; // waiting, racing, finished
        this.currentText = '';
        this.currentIndex = 0;
        this.startTime = null;
        this.endTime = null;
        this.errors = 0;
        this.totalCharacters = 0;
        this.wpm = 0;
        this.accuracy = 100;
        this.difficulty = 'medium';
        
        // Power-ups
        this.powerups = {
            speedBoost: { count: 0, active: false, duration: 10000 },
            accuracyShield: { count: 0, active: false, duration: 5000 },
            timeFreeze: { count: 0, active: false, duration: 3000 }
        };
        
        // AI competitors
        this.aiCompetitors = [
            { name: 'Speed Demon', progress: 0, speed: 0.8 },
            { name: 'Turbo Type', progress: 0, speed: 0.9 }
        ];
        
        // Achievements
        this.achievements = [
            { id: 'first_race', name: 'First Steps', description: 'Complete your first race', unlocked: false },
            { id: 'speed_demon', name: 'Speed Demon', description: 'Reach 60+ WPM', unlocked: false },
            { id: 'accuracy_master', name: 'Accuracy Master', description: 'Achieve 95%+ accuracy', unlocked: false },
            { id: 'lightning_fast', name: 'Lightning Fast', description: 'Reach 100+ WPM', unlocked: false },
            { id: 'perfectionist', name: 'Perfectionist', description: 'Complete a race with 100% accuracy', unlocked: false }
        ];
        
        this.socket = null;
        this.initializeGame();
        this.connectSocket();
    }

    initializeGame() {
        this.bindEvents();
        this.loadLeaderboard();
        this.generateText();
        this.updateDisplay();
        
        // Initialize power-up counts
        this.powerups.speedBoost.count = Math.floor(Math.random() * 3) + 1;
        this.powerups.accuracyShield.count = Math.floor(Math.random() * 2) + 1;
        this.powerups.timeFreeze.count = Math.floor(Math.random() * 2) + 1;
        this.updatePowerupDisplay();
    }

    connectSocket() {
        this.socket = io();
        
        this.socket.on('leaderboard_update', (data) => {
            this.displayLeaderboard(data);
        });
        
        this.socket.on('score_submitted', (response) => {
            if (response.success) {
                this.showAchievement('Score Submitted!', 'Your score has been added to the leaderboard');
                this.loadLeaderboard();
            }
        });
    }

    bindEvents() {
        // Game controls
        document.getElementById('start-race').addEventListener('click', () => this.startRace());
        document.getElementById('reset-race').addEventListener('click', () => this.resetRace());
        document.getElementById('difficulty-select').addEventListener('change', (e) => {
            this.difficulty = e.target.value;
            this.generateText();
        });

        // Typing input
        const typingInput = document.getElementById('typing-input');
        typingInput.addEventListener('input', (e) => this.handleTyping(e));
        typingInput.addEventListener('focus', () => this.startRace());

        // Power-ups
        document.getElementById('speed-boost').addEventListener('click', () => this.activatePowerup('speedBoost'));
        document.getElementById('accuracy-shield').addEventListener('click', () => this.activatePowerup('accuracyShield'));
        document.getElementById('time-freeze').addEventListener('click', () => this.activatePowerup('timeFreeze'));

        // Leaderboard
        document.getElementById('toggle-leaderboard').addEventListener('click', () => this.toggleLeaderboard());
        
        // Leaderboard filters
        document.querySelectorAll('.filter-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
                e.target.classList.add('active');
                this.loadLeaderboard(e.target.dataset.filter);
            });
        });

        // Modal events
        document.getElementById('submit-score').addEventListener('click', () => this.submitScore());
        document.getElementById('play-again').addEventListener('click', () => this.playAgain());
        document.getElementById('close-modal').addEventListener('click', () => this.closeModal());

        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') this.closeModal();
            if (e.key === 'Enter' && this.gameState === 'waiting') this.startRace();
            
            // Power-up shortcuts
            if (e.key === '1' && this.gameState === 'racing') this.activatePowerup('speedBoost');
            if (e.key === '2' && this.gameState === 'racing') this.activatePowerup('accuracyShield');
            if (e.key === '3' && this.gameState === 'racing') this.activatePowerup('timeFreeze');
        });
    }

    generateText() {
        const textSets = {
            easy: [
                "The quick brown fox jumps over the lazy dog. This is a simple sentence for beginners to practice typing.",
                "Cats and dogs are popular pets. They bring joy and companionship to many families around the world.",
                "Learning to type fast takes practice and patience. Start slow and gradually increase your speed."
            ],
            medium: [
                "Technology has revolutionized the way we communicate and work. From smartphones to artificial intelligence, innovation continues to shape our daily lives in remarkable ways.",
                "The art of programming requires logical thinking and creative problem-solving skills. Developers must write clean, efficient code that solves real-world challenges.",
                "Climate change presents one of the greatest challenges of our time. Scientists and policymakers work together to find sustainable solutions for future generations."
            ],
            hard: [
                "Quantum computing represents a paradigm shift in computational capabilities, leveraging quantum mechanical phenomena like superposition and entanglement to process information exponentially faster than classical computers.",
                "Cryptocurrency and blockchain technology have disrupted traditional financial systems, creating decentralized networks that enable peer-to-peer transactions without intermediaries or central authorities.",
                "Machine learning algorithms analyze vast datasets to identify patterns and make predictions, transforming industries from healthcare to autonomous vehicles through sophisticated neural networks."
            ],
            expert: [
                "The implementation of advanced cryptographic protocols ensures data integrity and confidentiality in distributed systems, utilizing mathematical functions that are computationally infeasible to reverse without proper authorization keys.",
                "Bioinformatics combines computational biology with statistical analysis to decode genomic sequences, enabling researchers to understand genetic variations and develop personalized medical treatments for complex diseases.",
                "Quantum entanglement demonstrates non-local correlations between particles, challenging classical physics concepts and providing the foundation for quantum communication protocols and teleportation experiments."
            ],
            nightmare: [
                "Pseudorandom number generators utilizing cryptographically secure algorithms incorporate entropy from hardware-based sources, ensuring unpredictability essential for cybersecurity applications, digital signatures, and blockchain consensus mechanisms.",
                "Neuromorphic computing architectures mimic synaptic plasticity through memristive devices, implementing spiking neural networks that achieve ultra-low power consumption while processing temporal information with biological-inspired learning algorithms.",
                "Topological quantum error correction codes protect quantum information against decoherence by encoding logical qubits across multiple physical qubits, utilizing anyonic braiding operations and surface code implementations for fault-tolerant quantum computation."
            ]
        };

        const texts = textSets[this.difficulty];
        this.currentText = texts[Math.floor(Math.random() * texts.length)];
        this.currentIndex = 0;
        this.errors = 0;
        this.totalCharacters = this.currentText.length;
        
        this.updateTextDisplay();
        this.updateStats();
    }

    updateTextDisplay() {
        const textContent = document.getElementById('text-content');
        let html = '';
        
        for (let i = 0; i < this.currentText.length; i++) {
            const char = this.currentText[i];
            if (i < this.currentIndex) {
                html += `<span class="correct">${char === ' ' ? '&nbsp;' : char}</span>`;
            } else if (i === this.currentIndex) {
                html += `<span class="current">${char === ' ' ? '&nbsp;' : char}</span>`;
            } else {
                html += char === ' ' ? '&nbsp;' : char;
            }
        }
        
        textContent.innerHTML = html;
        
        // Update words remaining
        const wordsRemaining = this.currentText.slice(this.currentIndex).split(' ').length - 1;
        document.getElementById('words-remaining').textContent = Math.max(0, wordsRemaining);
    }

    handleTyping(event) {
        if (this.gameState !== 'racing') return;
        
        const inputValue = event.target.value;
        const currentChar = this.currentText[this.currentIndex];
        const typedChar = inputValue[inputValue.length - 1];
        
        if (typedChar === currentChar) {
            this.currentIndex++;
            event.target.value = '';
            
            // Check for completion
            if (this.currentIndex >= this.currentText.length) {
                this.finishRace();
                return;
            }
        } else if (typedChar && !this.powerups.accuracyShield.active) {
            this.errors++;
            event.target.style.borderColor = '#ff4444';
            setTimeout(() => {
                event.target.style.borderColor = '';
            }, 200);
        }
        
        this.updateTextDisplay();
        this.updateStats();
        this.updateRaceProgress();
    }

    startRace() {
        if (this.gameState === 'racing') return;
        
        this.gameState = 'racing';
        this.startTime = Date.now();
        this.currentIndex = 0;
        this.errors = 0;
        
        // Reset AI competitors
        this.aiCompetitors.forEach(ai => {
            ai.progress = 0;
        });
        
        document.getElementById('typing-input').focus();
        document.getElementById('start-race').disabled = true;
        
        // Start AI competitors
        this.startAIRace();
        
        // Start timer
        this.startTimer();
        
        this.updateDisplay();
    }

    startAIRace() {
        const aiInterval = setInterval(() => {
            if (this.gameState !== 'racing') {
                clearInterval(aiInterval);
                return;
            }
            
            this.aiCompetitors.forEach((ai, index) => {
                if (!this.powerups.timeFreeze.active) {
                    const baseSpeed = ai.speed;
                    const randomFactor = 0.8 + Math.random() * 0.4; // 0.8 to 1.2
                    ai.progress += (baseSpeed * randomFactor) / 100;
                }
                
                // Cap at 100%
                ai.progress = Math.min(ai.progress, 1);
                
                // Update visual position
                const car = document.getElementById(`ai-car-${index + 1}`);
                const maxLeft = car.parentElement.offsetWidth - 100; // Account for finish line
                car.style.left = `${20 + (ai.progress * maxLeft)}px`;
                
                // Add visual effects
                if (ai.progress > 0.8) {
                    car.classList.add('speed-boost-active');
                } else {
                    car.classList.remove('speed-boost-active');
                }
            });
        }, 50);
    }

    startTimer() {
        const timerInterval = setInterval(() => {
            if (this.gameState !== 'racing') {
                clearInterval(timerInterval);
                return;
            }
            
            const elapsed = Math.floor((Date.now() - this.startTime) / 1000);
            document.getElementById('time-elapsed').textContent = elapsed;
        }, 1000);
    }

    updateRaceProgress() {
        const progress = this.currentIndex / this.currentText.length;
        const playerCar = document.getElementById('player-car');
        const maxLeft = playerCar.parentElement.offsetWidth - 100; // Account for finish line
        playerCar.style.left = `${20 + (progress * maxLeft)}px`;
        
        // Add visual effects based on performance
        if (this.wpm > 60) {
            playerCar.classList.add('speed-boost-active');
        } else {
            playerCar.classList.remove('speed-boost-active');
        }
    }

    updateStats() {
        if (!this.startTime) return;
        
        const timeElapsed = (Date.now() - this.startTime) / 1000 / 60; // in minutes
        const charactersTyped = this.currentIndex;
        const wordsTyped = charactersTyped / 5; // Standard: 5 characters = 1 word
        
        // Calculate WPM with power-up bonus
        let baseWPM = timeElapsed > 0 ? Math.round(wordsTyped / timeElapsed) : 0;
        this.wpm = this.powerups.speedBoost.active ? Math.round(baseWPM * 1.2) : baseWPM;
        
        // Calculate accuracy
        this.accuracy = this.currentIndex > 0 ? Math.round(((this.currentIndex - this.errors) / this.currentIndex) * 100) : 100;
        
        // Update display
        document.getElementById('current-wpm').textContent = this.wpm;
        document.getElementById('current-accuracy').textContent = this.accuracy;
        
        // Update rank based on AI performance
        let rank = 1;
        this.aiCompetitors.forEach(ai => {
            if (ai.progress > (this.currentIndex / this.currentText.length)) {
                rank++;
            }
        });
        document.getElementById('current-rank').textContent = this.getOrdinal(rank);
    }

    finishRace() {
        this.gameState = 'finished';
        this.endTime = Date.now();
        
        document.getElementById('start-race').disabled = false;
        
        // Calculate final stats
        const totalTime = (this.endTime - this.startTime) / 1000;
        const finalWPM = Math.round((this.currentText.length / 5) / (totalTime / 60));
        const finalAccuracy = Math.round(((this.currentText.length - this.errors) / this.currentText.length) * 100);
        
        // Determine final position
        let position = 1;
        this.aiCompetitors.forEach(ai => {
            if (ai.progress >= 1) position++;
        });
        
        // Check for achievements
        this.checkAchievements(finalWPM, finalAccuracy);
        
        // Show results modal
        this.showResults(finalWPM, finalAccuracy, totalTime, position);
        
        // Award power-ups based on performance
        this.awardPowerups(finalWPM, finalAccuracy);
    }

    showResults(wpm, accuracy, time, position) {
        document.getElementById('final-wpm').textContent = wpm;
        document.getElementById('final-accuracy').textContent = accuracy;
        document.getElementById('final-time').textContent = time.toFixed(1);
        document.getElementById('final-position').textContent = this.getOrdinal(position);
        
        document.getElementById('results-modal').classList.add('show');
    }

    activatePowerup(type) {
        if (this.gameState !== 'racing' || this.powerups[type].count <= 0 || this.powerups[type].active) return;
        
        this.powerups[type].count--;
        this.powerups[type].active = true;
        
        // Apply power-up effects
        switch (type) {
            case 'speedBoost':
                document.getElementById('player-car').classList.add('speed-boost-active');
                this.showAchievement('Speed Boost!', '+20% WPM for 10 seconds');
                break;
            case 'accuracyShield':
                document.getElementById('player-car').classList.add('accuracy-shield-active');
                this.showAchievement('Accuracy Shield!', 'No typing penalties for 5 seconds');
                break;
            case 'timeFreeze':
                this.aiCompetitors.forEach((_, index) => {
                    document.getElementById(`ai-car-${index + 1}`).classList.add('frozen');
                });
                this.showAchievement('Time Freeze!', 'Opponents frozen for 3 seconds');
                break;
        }
        
        // Set timeout to deactivate
        setTimeout(() => {
            this.powerups[type].active = false;
            
            switch (type) {
                case 'speedBoost':
                    document.getElementById('player-car').classList.remove('speed-boost-active');
                    break;
                case 'accuracyShield':
                    document.getElementById('player-car').classList.remove('accuracy-shield-active');
                    break;
                case 'timeFreeze':
                    this.aiCompetitors.forEach((_, index) => {
                        document.getElementById(`ai-car-${index + 1}`).classList.remove('frozen');
                    });
                    break;
            }
        }, this.powerups[type].duration);
        
        this.updatePowerupDisplay();
    }

    updatePowerupDisplay() {
        Object.keys(this.powerups).forEach(type => {
            const element = document.getElementById(type.replace(/([A-Z])/g, '-$1').toLowerCase());
            if (element) {
                const countElement = element.querySelector('.powerup-count');
                countElement.textContent = this.powerups[type].count;
                
                if (this.powerups[type].count <= 0) {
                    element.style.opacity = '0.5';
                    element.style.pointerEvents = 'none';
                } else {
                    element.style.opacity = '1';
                    element.style.pointerEvents = 'auto';
                }
            }
        });
    }

    awardPowerups(wpm, accuracy) {
        let awarded = 0;
        
        if (wpm >= 50) {
            this.powerups.speedBoost.count++;
            awarded++;
        }
        
        if (accuracy >= 90) {
            this.powerups.accuracyShield.count++;
            awarded++;
        }
        
        if (wpm >= 40 && accuracy >= 85) {
            this.powerups.timeFreeze.count++;
            awarded++;
        }
        
        if (awarded > 0) {
            setTimeout(() => {
                this.showAchievement('Power-ups Earned!', `You earned ${awarded} power-up${awarded > 1 ? 's' : ''}!`);
                this.updatePowerupDisplay();
            }, 2000);
        }
    }

    checkAchievements(wpm, accuracy) {
        const toUnlock = [];
        
        if (!this.achievements[0].unlocked) {
            this.achievements[0].unlocked = true;
            toUnlock.push(this.achievements[0]);
        }
        
        if (wpm >= 60 && !this.achievements[1].unlocked) {
            this.achievements[1].unlocked = true;
            toUnlock.push(this.achievements[1]);
        }
        
        if (accuracy >= 95 && !this.achievements[2].unlocked) {
            this.achievements[2].unlocked = true;
            toUnlock.push(this.achievements[2]);
        }
        
        if (wpm >= 100 && !this.achievements[3].unlocked) {
            this.achievements[3].unlocked = true;
            toUnlock.push(this.achievements[3]);
        }
        
        if (accuracy === 100 && !this.achievements[4].unlocked) {
            this.achievements[4].unlocked = true;
            toUnlock.push(this.achievements[4]);
        }
        
        // Show achievements with delay
        toUnlock.forEach((achievement, index) => {
            setTimeout(() => {
                this.showAchievement(achievement.name, achievement.description);
            }, 1000 + (index * 2000));
        });
    }

    showAchievement(title, description) {
        const toast = document.getElementById('achievement-toast');
        document.getElementById('achievement-title').textContent = title;
        document.getElementById('achievement-description').textContent = description;
        
        toast.classList.add('show');
        
        setTimeout(() => {
            toast.classList.remove('show');
        }, 3000);
    }

    submitScore() {
        const playerName = document.getElementById('player-name').value.trim();
        if (!playerName) {
            alert('Please enter your name!');
            return;
        }
        
        const scoreData = {
            name: playerName,
            wpm: parseInt(document.getElementById('final-wpm').textContent),
            accuracy: parseInt(document.getElementById('final-accuracy').textContent),
            time: parseFloat(document.getElementById('final-time').textContent),
            difficulty: this.difficulty,
            timestamp: new Date().toISOString()
        };
        
        if (this.socket) {
            this.socket.emit('submit_score', scoreData);
        }
        
        document.getElementById('submit-score').disabled = true;
        document.getElementById('submit-score').textContent = 'Submitted!';
    }

    loadLeaderboard(filter = 'daily') {
        if (this.socket) {
            this.socket.emit('get_leaderboard', { filter });
        }
    }

    displayLeaderboard(data) {
        const leaderboardList = document.getElementById('leaderboard-list');
        
        if (!data || data.length === 0) {
            leaderboardList.innerHTML = '<div class="no-data">No scores yet. Be the first!</div>';
            return;
        }
        
        const html = data.map((entry, index) => `
            <div class="leaderboard-entry">
                <span class="entry-rank">#${index + 1}</span>
                <span class="entry-name">${entry.name}</span>
                <div class="entry-stats">
                    <div>${entry.wpm} WPM</div>
                    <div>${entry.accuracy}% ACC</div>
                    <div>${entry.difficulty.toUpperCase()}</div>
                </div>
            </div>
        `).join('');
        
        leaderboardList.innerHTML = html;
    }

    toggleLeaderboard() {
        const panel = document.getElementById('leaderboard-panel');
        panel.classList.toggle('open');
    }

    resetRace() {
        this.gameState = 'waiting';
        this.currentIndex = 0;
        this.errors = 0;
        this.startTime = null;
        this.endTime = null;
        
        document.getElementById('typing-input').value = '';
        document.getElementById('typing-input').style.borderColor = '';
        document.getElementById('start-race').disabled = false;
        document.getElementById('time-elapsed').textContent = '0';
        
        // Reset car positions
        document.getElementById('player-car').style.left = '20px';
        this.aiCompetitors.forEach((ai, index) => {
            ai.progress = 0;
            document.getElementById(`ai-car-${index + 1}`).style.left = '20px';
        });
        
        this.generateText();
        this.updateStats();
        this.updateDisplay();
    }

    playAgain() {
        this.closeModal();
        this.resetRace();
    }

    closeModal() {
        document.getElementById('results-modal').classList.remove('show');
        document.getElementById('submit-score').disabled = false;
        document.getElementById('submit-score').textContent = 'Submit Score';
        document.getElementById('player-name').value = '';
    }

    updateDisplay() {
        // Any additional display updates can go here
    }

    getOrdinal(num) {
        const suffixes = ['th', 'st', 'nd', 'rd'];
        const v = num % 100;
        return num + (suffixes[(v - 20) % 10] || suffixes[v] || suffixes[0]);
    }
}

// Initialize the game when the page loads
document.addEventListener('DOMContentLoaded', () => {
    window.game = new TypingRacerPro();
});

// Add some fun easter eggs
document.addEventListener('keydown', (e) => {
    // Konami code: ↑↑↓↓←→←→BA
    const konamiCode = [38, 38, 40, 40, 37, 39, 37, 39, 66, 65];
    if (!window.konamiSequence) window.konamiSequence = [];
    
    window.konamiSequence.push(e.keyCode);
    if (window.konamiSequence.length > konamiCode.length) {
        window.konamiSequence.shift();
    }
    
    if (window.konamiSequence.length === konamiCode.length && 
        window.konamiSequence.every((key, index) => key === konamiCode[index])) {
        // Easter egg: Give all power-ups
        if (window.game) {
            Object.keys(window.game.powerups).forEach(type => {
                window.game.powerups[type].count += 5;
            });
            window.game.updatePowerupDisplay();
            window.game.showAchievement('Konami Code!', 'All power-ups maxed out!');
        }
        window.konamiSequence = [];
    }
});