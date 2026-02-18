// ============================================================
// CONSTANTS
// ============================================================
const CANVAS_WIDTH = 800;
const CANVAS_HEIGHT = 450;
const GROUND_Y = 380;
const GRAVITY = 1800;
const JUMP_VELOCITY = -650;
const MAX_FALL_SPEED = 1200;
const BASE_SCROLL_SPEED = 250;
const MAX_SCROLL_SPEED = 500;
const SPEED_INCREASE_RATE = 2;
const STRAWBERRY_SPAWN_INTERVAL = 1.2;
const SPAWN_INTERVAL_VARIANCE = 0.6;
const GOLDEN_PROBABILITY = 0.10;
const STRAWBERRY_MIN_Y = 220;
const STRAWBERRY_MAX_Y = 330;
const STRAWBERRY_RADIUS = 14;
const CLUSTER_CHANCE = 0.25;
const ROCK_SPAWN_INTERVAL = 3.0;
const ROCK_SPAWN_VARIANCE = 1.5;
const ROCK_WIDTH = 30;
const ROCK_HEIGHT = 25;
const TIGER_X = 120;
const TIGER_WIDTH = 60;
const TIGER_HEIGHT = 50;
const HITBOX_INSET = 8;

// ============================================================
// CANVAS SETUP
// ============================================================
const canvas = document.getElementById('gameCanvas');
const ctx = canvas.getContext('2d');

// ============================================================
// AUDIO (Web Audio API - no external files)
// ============================================================
var audioCtx = null;

function getAudioCtx() {
    if (!audioCtx) {
        audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    }
    return audioCtx;
}

function playJumpSound() {
    try {
        var ctx = getAudioCtx();
        var osc = ctx.createOscillator();
        var gain = ctx.createGain();
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(300, ctx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(600, ctx.currentTime + 0.15);
        gain.gain.setValueAtTime(0.15, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.2);
        osc.start(ctx.currentTime);
        osc.stop(ctx.currentTime + 0.2);
    } catch (e) {}
}

function playScoreSound() {
    try {
        var ctx = getAudioCtx();
        var osc = ctx.createOscillator();
        var gain = ctx.createGain();
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.type = 'sine';
        osc.frequency.setValueAtTime(523, ctx.currentTime);
        osc.frequency.setValueAtTime(659, ctx.currentTime + 0.08);
        gain.gain.setValueAtTime(0.12, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.2);
        osc.start(ctx.currentTime);
        osc.stop(ctx.currentTime + 0.2);
    } catch (e) {}
}

function playGoldenSound() {
    try {
        var ctx = getAudioCtx();
        // Three quick ascending notes
        var notes = [523, 659, 784];
        for (var i = 0; i < notes.length; i++) {
            var osc = ctx.createOscillator();
            var gain = ctx.createGain();
            osc.connect(gain);
            gain.connect(ctx.destination);
            osc.type = 'sine';
            osc.frequency.setValueAtTime(notes[i], ctx.currentTime + i * 0.08);
            gain.gain.setValueAtTime(0, ctx.currentTime + i * 0.08);
            gain.gain.linearRampToValueAtTime(0.15, ctx.currentTime + i * 0.08 + 0.02);
            gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + i * 0.08 + 0.15);
            osc.start(ctx.currentTime + i * 0.08);
            osc.stop(ctx.currentTime + i * 0.08 + 0.15);
        }
    } catch (e) {}
}

function playGameOverSound() {
    try {
        var ctx = getAudioCtx();
        var notes = [400, 300, 200];
        for (var i = 0; i < notes.length; i++) {
            var osc = ctx.createOscillator();
            var gain = ctx.createGain();
            osc.connect(gain);
            gain.connect(ctx.destination);
            osc.type = 'square';
            osc.frequency.setValueAtTime(notes[i], ctx.currentTime + i * 0.15);
            gain.gain.setValueAtTime(0, ctx.currentTime + i * 0.15);
            gain.gain.linearRampToValueAtTime(0.1, ctx.currentTime + i * 0.15 + 0.02);
            gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + i * 0.15 + 0.25);
            osc.start(ctx.currentTime + i * 0.15);
            osc.stop(ctx.currentTime + i * 0.15 + 0.25);
        }
    } catch (e) {}
}

// Background music state
var bgmPlaying = false;
var bgmNodes = [];
var bgmInterval = null;

function startBGM() {
    if (bgmPlaying) return;
    bgmPlaying = true;
    try {
        var ac = getAudioCtx();

        // Jungle-style percussion loop using noise bursts
        var percGain = ac.createGain();
        percGain.gain.value = 0.06;
        percGain.connect(ac.destination);
        bgmNodes.push(percGain);

        // Deep bass drone (tiger growl vibe)
        var bassOsc = ac.createOscillator();
        var bassGain = ac.createGain();
        bassOsc.type = 'sawtooth';
        bassOsc.frequency.value = 55;
        bassGain.gain.value = 0.07;
        var bassFilter = ac.createBiquadFilter();
        bassFilter.type = 'lowpass';
        bassFilter.frequency.value = 120;
        bassOsc.connect(bassFilter);
        bassFilter.connect(bassGain);
        bassGain.connect(ac.destination);
        bassOsc.start();
        bgmNodes.push(bassOsc, bassGain, bassFilter);

        // Melody pattern - pentatonic scale, jungle feel
        // E minor pentatonic: E3, G3, A3, B3, D4, E4
        var melodyNotes = [
            164.81, 196.00, 220.00, 246.94, 293.66, 329.63,
            293.66, 246.94, 220.00, 196.00, 164.81, 196.00,
            220.00, 293.66, 329.63, 293.66
        ];
        var beatDuration = 0.22;
        var loopLength = melodyNotes.length * beatDuration;
        var noteIndex = 0;

        function scheduleMelodyNote() {
            if (!bgmPlaying) return;
            try {
                var ac2 = getAudioCtx();
                var osc = ac2.createOscillator();
                var gain = ac2.createGain();
                var filter = ac2.createBiquadFilter();
                osc.type = 'triangle';
                osc.frequency.value = melodyNotes[noteIndex % melodyNotes.length];
                filter.type = 'lowpass';
                filter.frequency.value = 800;
                osc.connect(filter);
                filter.connect(gain);
                gain.connect(ac2.destination);
                gain.gain.setValueAtTime(0, ac2.currentTime);
                gain.gain.linearRampToValueAtTime(0.08, ac2.currentTime + 0.02);
                gain.gain.exponentialRampToValueAtTime(0.001, ac2.currentTime + beatDuration * 0.9);
                osc.start(ac2.currentTime);
                osc.stop(ac2.currentTime + beatDuration);
                noteIndex++;
            } catch (e) {}
        }

        // Drum pattern using oscillator clicks
        var drumIndex = 0;
        var drumPattern = [1, 0, 1, 0, 1, 0, 1, 1]; // 1 = hit

        function scheduleDrum() {
            if (!bgmPlaying) return;
            try {
                var ac2 = getAudioCtx();
                if (drumPattern[drumIndex % drumPattern.length]) {
                    var osc = ac2.createOscillator();
                    var gain = ac2.createGain();
                    osc.type = 'square';
                    osc.frequency.value = 80;
                    osc.connect(gain);
                    gain.connect(percGain);
                    gain.gain.setValueAtTime(0.3, ac2.currentTime);
                    gain.gain.exponentialRampToValueAtTime(0.001, ac2.currentTime + 0.08);
                    osc.start(ac2.currentTime);
                    osc.stop(ac2.currentTime + 0.08);
                }
                drumIndex++;
            } catch (e) {}
        }

        // Schedule both melody and drums on the same interval
        bgmInterval = setInterval(function() {
            scheduleMelodyNote();
            scheduleDrum();
        }, beatDuration * 1000);

        // Play first notes immediately
        scheduleMelodyNote();
        scheduleDrum();

    } catch (e) {}
}

function stopBGM() {
    bgmPlaying = false;
    if (bgmInterval) {
        clearInterval(bgmInterval);
        bgmInterval = null;
    }
    for (var i = 0; i < bgmNodes.length; i++) {
        try {
            if (bgmNodes[i].stop) bgmNodes[i].stop();
            if (bgmNodes[i].disconnect) bgmNodes[i].disconnect();
        } catch (e) {}
    }
    bgmNodes = [];
}

// ============================================================
// GAME STATE
// ============================================================
let gameState = 'MENU';
let score = 0;
let bestScore = getHighScore();
let scrollSpeed = BASE_SCROLL_SPEED;
let scrollOffset = 0;
let frameCount = 0;
let playTime = 0;
let lastTime = 0;

// ============================================================
// ENTITIES
// ============================================================
let tiger = null;
let strawberries = [];
let rocks = [];
let clouds = [];
let scoreParticles = [];
let strawberrySpawnTimer = 0;
let rockSpawnTimer = 0;

// ============================================================
// HIGH SCORE
// ============================================================
function getHighScore() {
    return parseInt(localStorage.getItem('strawberrytiger_best') || '0', 10);
}

function saveHighScore(s) {
    const best = getHighScore();
    if (s > best) {
        localStorage.setItem('strawberrytiger_best', s);
    }
}

// ============================================================
// INITIALIZATION
// ============================================================
function initTiger() {
    tiger = {
        x: TIGER_X,
        y: GROUND_Y - TIGER_HEIGHT,
        width: TIGER_WIDTH,
        height: TIGER_HEIGHT,
        velocityY: 0,
        isOnGround: true,
        groundY: GROUND_Y - TIGER_HEIGHT
    };
}

function initClouds() {
    clouds = [];
    for (let i = 0; i < 5; i++) {
        clouds.push({
            x: Math.random() * CANVAS_WIDTH,
            y: 30 + Math.random() * 100,
            width: 60 + Math.random() * 80,
            height: 20 + Math.random() * 20,
            speed: 0.2 + Math.random() * 0.3
        });
    }
}

function resetGame() {
    initTiger();
    initClouds();
    strawberries = [];
    rocks = [];
    scoreParticles = [];
    score = 0;
    scrollSpeed = BASE_SCROLL_SPEED;
    scrollOffset = 0;
    playTime = 0;
    strawberrySpawnTimer = 1.0;
    rockSpawnTimer = 2.0;
    bestScore = getHighScore();
}

function startGame() {
    resetGame();
    gameState = 'PLAYING';
    startBGM();
}

// ============================================================
// INPUT HANDLING
// ============================================================
let usingTouch = false;

function handleInput(e) {
    // Prevent double-fire: if touch is used, ignore click events
    if (e.type === 'touchstart') {
        usingTouch = true;
        e.preventDefault();
    }
    if (e.type === 'click' && usingTouch) return;

    if (gameState === 'MENU') {
        startGame();
    } else if (gameState === 'PLAYING') {
        if (tiger.isOnGround) {
            tiger.velocityY = JUMP_VELOCITY;
            tiger.isOnGround = false;
            playJumpSound();
        }
    } else if (gameState === 'GAME_OVER') {
        gameState = 'MENU';
        resetGame();
    }
}

canvas.addEventListener('click', handleInput);
canvas.addEventListener('touchstart', handleInput, { passive: false });

document.addEventListener('keydown', function(e) {
    if (e.code === 'Space' || e.code === 'ArrowUp') {
        e.preventDefault();
        handleInput(e);
    }
});

// ============================================================
// MANUAL ROTATION & RESIZE
// ============================================================
var isRotated = false;
var container = document.getElementById('game-container');
var rotateBtn = document.getElementById('rotate-btn');

function isTouchDevice() {
    return ('ontouchstart' in window) || (navigator.maxTouchPoints > 0);
}

function resizeCanvas() {
    var cw = window.innerWidth;
    var ch = window.innerHeight;

    // Show/hide rotate button: only on touch devices in portrait
    if (isTouchDevice() && ch > cw) {
        rotateBtn.style.display = 'flex';
    } else {
        rotateBtn.style.display = 'none';
        // Auto-reset rotation when going landscape or on PC
        if (isRotated) {
            isRotated = false;
        }
    }

    if (isRotated) {
        // Portrait phone, user wants landscape view
        // Size container to ch x cw (swapped), position fixed at center
        container.style.position = 'fixed';
        container.style.width = ch + 'px';
        container.style.height = cw + 'px';
        container.style.left = ((cw - ch) / 2) + 'px';
        container.style.top = ((ch - cw) / 2) + 'px';
        container.style.transform = 'rotate(90deg)';
        // Canvas scales to fit the swapped dimensions (ch wide, cw tall)
        var scale = Math.min(ch / CANVAS_WIDTH, cw / CANVAS_HEIGHT);
        canvas.style.width = Math.floor(CANVAS_WIDTH * scale) + 'px';
        canvas.style.height = Math.floor(CANVAS_HEIGHT * scale) + 'px';
    } else {
        container.style.position = '';
        container.style.width = '100%';
        container.style.height = '100%';
        container.style.left = '';
        container.style.top = '';
        container.style.transform = 'none';
        var scale = Math.min(cw / CANVAS_WIDTH, ch / CANVAS_HEIGHT);
        canvas.style.width = Math.floor(CANVAS_WIDTH * scale) + 'px';
        canvas.style.height = Math.floor(CANVAS_HEIGHT * scale) + 'px';
    }
}

rotateBtn.addEventListener('click', function(e) {
    e.stopPropagation();
    isRotated = !isRotated;
    resizeCanvas();
});
rotateBtn.addEventListener('touchstart', function(e) {
    e.stopPropagation();
    e.preventDefault();
    isRotated = !isRotated;
    resizeCanvas();
}, { passive: false });

window.addEventListener('resize', resizeCanvas);
window.addEventListener('orientationchange', function() {
    setTimeout(resizeCanvas, 100);
    setTimeout(resizeCanvas, 300);
});
resizeCanvas();

// ============================================================
// UPDATE FUNCTIONS
// ============================================================
function updateTiger(dt) {
    if (!tiger.isOnGround) {
        tiger.velocityY += GRAVITY * dt;
        tiger.velocityY = Math.min(tiger.velocityY, MAX_FALL_SPEED);
        tiger.y += tiger.velocityY * dt;

        if (tiger.y >= tiger.groundY) {
            tiger.y = tiger.groundY;
            tiger.velocityY = 0;
            tiger.isOnGround = true;
        }
    }
}

function spawnStrawberries(dt) {
    strawberrySpawnTimer -= dt;
    if (strawberrySpawnTimer <= 0) {
        strawberrySpawnTimer = STRAWBERRY_SPAWN_INTERVAL
            + (Math.random() - 0.5) * SPAWN_INTERVAL_VARIANCE * 2;

        var count = Math.random() < CLUSTER_CHANCE
            ? Math.floor(Math.random() * 2) + 2
            : 1;

        for (var i = 0; i < count; i++) {
            var isGolden = Math.random() < GOLDEN_PROBABILITY;
            var r = (Math.random() + Math.random()) / 2;
            var yPos = STRAWBERRY_MIN_Y + r * (STRAWBERRY_MAX_Y - STRAWBERRY_MIN_Y);

            strawberries.push({
                x: CANVAS_WIDTH + 20 + i * 45,
                y: yPos,
                radius: STRAWBERRY_RADIUS,
                isGolden: isGolden,
                collected: false
            });
        }
    }
}

function updateStrawberries(dt) {
    for (var i = strawberries.length - 1; i >= 0; i--) {
        strawberries[i].x -= scrollSpeed * dt;
        if (strawberries[i].x < -30) {
            strawberries.splice(i, 1);
        }
    }
}

function spawnRocks(dt) {
    rockSpawnTimer -= dt;
    if (rockSpawnTimer <= 0) {
        rockSpawnTimer = ROCK_SPAWN_INTERVAL
            + (Math.random() - 0.5) * ROCK_SPAWN_VARIANCE * 2;

        rocks.push({
            x: CANVAS_WIDTH + 20,
            y: GROUND_Y - ROCK_HEIGHT,
            width: ROCK_WIDTH,
            height: ROCK_HEIGHT
        });
    }
}

function updateRocks(dt) {
    for (var i = rocks.length - 1; i >= 0; i--) {
        rocks[i].x -= scrollSpeed * dt;
        if (rocks[i].x < -40) {
            rocks.splice(i, 1);
        }
    }
}

function updateClouds(dt) {
    for (var i = 0; i < clouds.length; i++) {
        var c = clouds[i];
        c.x -= c.speed * scrollSpeed * dt;
        if (c.x + c.width < 0) {
            c.x = CANVAS_WIDTH + Math.random() * 100;
            c.y = 30 + Math.random() * 100;
        }
    }
}

function updateScoreParticles(dt) {
    for (var i = scoreParticles.length - 1; i >= 0; i--) {
        var p = scoreParticles[i];
        p.y += p.velocityY * dt;
        p.life -= dt;
        if (p.life <= 0) {
            scoreParticles.splice(i, 1);
        }
    }
}

function aabbCollision(a, b) {
    return (
        a.x < b.x + b.width &&
        a.x + a.width > b.x &&
        a.y < b.y + b.height &&
        a.y + a.height > b.y
    );
}

function checkCollisions() {
    // Tiger hitbox (inset from visual bounds)
    var th = {
        x: tiger.x + HITBOX_INSET,
        y: tiger.y + HITBOX_INSET,
        width: tiger.width - HITBOX_INSET * 2,
        height: tiger.height - HITBOX_INSET * 2
    };

    // Strawberry collisions
    for (var i = 0; i < strawberries.length; i++) {
        var s = strawberries[i];
        if (s.collected) continue;

        var sb = {
            x: s.x - s.radius,
            y: s.y - s.radius,
            width: s.radius * 2,
            height: s.radius * 2
        };

        if (aabbCollision(th, sb)) {
            s.collected = true;
            var points = s.isGolden ? 3 : 1;
            score += points;
            if (s.isGolden) { playGoldenSound(); } else { playScoreSound(); }

            scoreParticles.push({
                x: s.x,
                y: s.y,
                text: '+' + points,
                color: s.isGolden ? '#FFD700' : '#FFFFFF',
                life: 1.0,
                velocityY: -80
            });
        }
    }

    // Remove collected strawberries
    for (var i = strawberries.length - 1; i >= 0; i--) {
        if (strawberries[i].collected) {
            strawberries.splice(i, 1);
        }
    }

    // Rock collisions
    for (var i = 0; i < rocks.length; i++) {
        if (aabbCollision(th, rocks[i])) {
            saveHighScore(score);
            bestScore = getHighScore();
            gameState = 'GAME_OVER';
            stopBGM();
            playGameOverSound();
            return;
        }
    }
}

function updateDifficulty(dt) {
    playTime += dt;
    scrollSpeed = Math.min(
        BASE_SCROLL_SPEED + playTime * SPEED_INCREASE_RATE,
        MAX_SCROLL_SPEED
    );
}

function update(dt) {
    if (gameState !== 'PLAYING') return;

    frameCount++;
    scrollOffset += scrollSpeed * dt;

    updateTiger(dt);
    spawnStrawberries(dt);
    updateStrawberries(dt);
    spawnRocks(dt);
    updateRocks(dt);
    updateClouds(dt);
    updateScoreParticles(dt);
    checkCollisions();
    updateDifficulty(dt);
}

// ============================================================
// RENDER FUNCTIONS
// ============================================================
function drawSky() {
    var gradient = ctx.createLinearGradient(0, 0, 0, GROUND_Y);
    gradient.addColorStop(0, '#87CEEB');
    gradient.addColorStop(1, '#E0F0FF');
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, CANVAS_WIDTH, GROUND_Y);
}

function drawClouds() {
    ctx.fillStyle = 'rgba(255, 255, 255, 0.8)';
    for (var i = 0; i < clouds.length; i++) {
        var c = clouds[i];
        ctx.beginPath();
        ctx.ellipse(c.x + c.width / 2, c.y + c.height / 2, c.width / 2, c.height / 2, 0, 0, Math.PI * 2);
        ctx.fill();
        // secondary puff
        ctx.beginPath();
        ctx.ellipse(c.x + c.width * 0.3, c.y + c.height * 0.6, c.width * 0.3, c.height * 0.4, 0, 0, Math.PI * 2);
        ctx.fill();
        ctx.beginPath();
        ctx.ellipse(c.x + c.width * 0.7, c.y + c.height * 0.6, c.width * 0.35, c.height * 0.35, 0, 0, Math.PI * 2);
        ctx.fill();
    }
}

function drawGround() {
    // Grass strip
    ctx.fillStyle = '#4CAF50';
    ctx.fillRect(0, GROUND_Y, CANVAS_WIDTH, 20);

    // Dirt
    ctx.fillStyle = '#8B4513';
    ctx.fillRect(0, GROUND_Y + 20, CANVAS_WIDTH, 50);

    // Scrolling grass detail
    ctx.strokeStyle = '#388E3C';
    ctx.lineWidth = 1;
    var offset = scrollOffset % 20;
    for (var x = -offset; x < CANVAS_WIDTH + 20; x += 20) {
        ctx.beginPath();
        ctx.moveTo(x, GROUND_Y);
        ctx.lineTo(x + 5, GROUND_Y - 6);
        ctx.stroke();
        ctx.beginPath();
        ctx.moveTo(x + 10, GROUND_Y);
        ctx.lineTo(x + 13, GROUND_Y - 4);
        ctx.stroke();
    }
}

function roundRect(x, y, width, height, radius) {
    ctx.beginPath();
    ctx.moveTo(x + radius, y);
    ctx.lineTo(x + width - radius, y);
    ctx.arcTo(x + width, y, x + width, y + radius, radius);
    ctx.lineTo(x + width, y + height - radius);
    ctx.arcTo(x + width, y + height, x + width - radius, y + height, radius);
    ctx.lineTo(x + radius, y + height);
    ctx.arcTo(x, y + height, x, y + height - radius, radius);
    ctx.lineTo(x, y + radius);
    ctx.arcTo(x, y, x + radius, y, radius);
    ctx.closePath();
}

function drawTiger() {
    var x = tiger.x;
    var y = tiger.y;

    // Tail - straight out behind, slight upward curve, gentle tip wag
    ctx.lineCap = 'round';
    var tipWag = Math.sin(frameCount * 0.12) * 4;
    // Orange tail
    ctx.strokeStyle = '#FF8C00';
    ctx.lineWidth = 5;
    ctx.beginPath();
    ctx.moveTo(x + 8, y + 20);
    ctx.quadraticCurveTo(x - 6, y + 16, x - 14, y + 12 + tipWag);
    ctx.stroke();
    // Black rings on tail
    ctx.strokeStyle = '#1a1a1a';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(x - 1, y + 17.5);
    ctx.lineTo(x - 3, y + 19);
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(x - 7, y + 15);
    ctx.lineTo(x - 9, y + 16.5);
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(x - 12, y + 12.5 + tipWag * 0.7);
    ctx.lineTo(x - 14, y + 14 + tipWag * 0.7);
    ctx.stroke();

    // Body - muscular, broader
    ctx.fillStyle = '#FF8C00';
    roundRect(x + 6, y + 10, 46, 32, 8);
    ctx.fill();

    // White belly
    ctx.fillStyle = '#FFF3E0';
    ctx.beginPath();
    ctx.ellipse(x + 30, y + 36, 18, 6, 0, 0, Math.PI * 2);
    ctx.fill();

    // Body stripes - black, curved (tiger pattern)
    ctx.strokeStyle = '#1a1a1a';
    ctx.lineWidth = 2.5;
    // Stripe 1
    ctx.beginPath();
    ctx.moveTo(x + 16, y + 12);
    ctx.quadraticCurveTo(x + 14, y + 24, x + 17, y + 36);
    ctx.stroke();
    // Stripe 2
    ctx.beginPath();
    ctx.moveTo(x + 24, y + 11);
    ctx.quadraticCurveTo(x + 22, y + 22, x + 25, y + 35);
    ctx.stroke();
    // Stripe 3
    ctx.beginPath();
    ctx.moveTo(x + 32, y + 11);
    ctx.quadraticCurveTo(x + 34, y + 22, x + 31, y + 36);
    ctx.stroke();
    // Stripe 4
    ctx.beginPath();
    ctx.moveTo(x + 40, y + 12);
    ctx.quadraticCurveTo(x + 42, y + 24, x + 39, y + 35);
    ctx.stroke();

    // Ears - short, rounded, tiger-style (drawn before head)
    // Left ear
    ctx.fillStyle = '#FF8C00';
    ctx.beginPath();
    ctx.ellipse(x + 43, y + 3, 5, 6, -0.15, 0, Math.PI * 2);
    ctx.fill();
    // Right ear
    ctx.beginPath();
    ctx.ellipse(x + 57, y + 3, 5, 6, 0.15, 0, Math.PI * 2);
    ctx.fill();
    // Black ear backs (tiger marking)
    ctx.fillStyle = '#1a1a1a';
    ctx.beginPath();
    ctx.ellipse(x + 43, y + 1, 4, 4, -0.15, Math.PI, Math.PI * 2);
    ctx.fill();
    ctx.beginPath();
    ctx.ellipse(x + 57, y + 1, 4, 4, 0.15, Math.PI, Math.PI * 2);
    ctx.fill();
    // White ear spots (tiger feature)
    ctx.fillStyle = '#FFFFFF';
    ctx.beginPath();
    ctx.arc(x + 43, y + 1, 2, 0, Math.PI * 2);
    ctx.fill();
    ctx.beginPath();
    ctx.arc(x + 57, y + 1, 2, 0, Math.PI * 2);
    ctx.fill();

    // Head - slightly wider, more square-ish (tiger jaw)
    ctx.fillStyle = '#FFA500';
    ctx.beginPath();
    ctx.ellipse(x + 50, y + 13, 13, 12, 0, 0, Math.PI * 2);
    ctx.fill();

    // White muzzle area (tiger marking)
    ctx.fillStyle = '#FFF8E1';
    ctx.beginPath();
    ctx.ellipse(x + 50, y + 18, 8, 6, 0, 0, Math.PI * 2);
    ctx.fill();

    // White cheek fur patches
    ctx.fillStyle = '#FFF3E0';
    ctx.beginPath();
    ctx.ellipse(x + 42, y + 15, 4, 3, -0.3, 0, Math.PI * 2);
    ctx.fill();
    ctx.beginPath();
    ctx.ellipse(x + 58, y + 15, 4, 3, 0.3, 0, Math.PI * 2);
    ctx.fill();

    // Face stripes - black markings above eyes
    ctx.strokeStyle = '#1a1a1a';
    ctx.lineWidth = 2;
    // Left face stripes
    ctx.beginPath();
    ctx.moveTo(x + 40, y + 6);
    ctx.quadraticCurveTo(x + 42, y + 9, x + 44, y + 8);
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(x + 38, y + 9);
    ctx.quadraticCurveTo(x + 41, y + 12, x + 43, y + 11);
    ctx.stroke();
    // Right face stripes
    ctx.beginPath();
    ctx.moveTo(x + 60, y + 6);
    ctx.quadraticCurveTo(x + 58, y + 9, x + 56, y + 8);
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(x + 62, y + 9);
    ctx.quadraticCurveTo(x + 59, y + 12, x + 57, y + 11);
    ctx.stroke();

    // Eyes - fierce, slightly narrow
    ctx.fillStyle = '#FFFFFF';
    ctx.beginPath();
    ctx.ellipse(x + 45, y + 11, 3.5, 2.5, -0.1, 0, Math.PI * 2);
    ctx.fill();
    ctx.beginPath();
    ctx.ellipse(x + 55, y + 11, 3.5, 2.5, 0.1, 0, Math.PI * 2);
    ctx.fill();
    // Amber iris
    ctx.fillStyle = '#E6A800';
    ctx.beginPath();
    ctx.arc(x + 46, y + 11, 2, 0, Math.PI * 2);
    ctx.fill();
    ctx.beginPath();
    ctx.arc(x + 56, y + 11, 2, 0, Math.PI * 2);
    ctx.fill();
    // Black pupils
    ctx.fillStyle = '#000000';
    ctx.beginPath();
    ctx.arc(x + 46, y + 11, 1, 0, Math.PI * 2);
    ctx.fill();
    ctx.beginPath();
    ctx.arc(x + 56, y + 11, 1, 0, Math.PI * 2);
    ctx.fill();

    // Nose - wider, more rounded (tiger nose)
    ctx.fillStyle = '#D4576B';
    ctx.beginPath();
    ctx.ellipse(x + 50, y + 16, 3, 2, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = '#1a1a1a';
    ctx.beginPath();
    ctx.ellipse(x + 50, y + 15.5, 2.5, 1.5, 0, 0, Math.PI);
    ctx.fill();

    // Mouth line
    ctx.strokeStyle = '#1a1a1a';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(x + 50, y + 17.5);
    ctx.lineTo(x + 50, y + 19);
    ctx.stroke();
    ctx.beginPath();
    ctx.arc(x + 47, y + 19, 3, 0, Math.PI, false);
    ctx.stroke();
    ctx.beginPath();
    ctx.arc(x + 53, y + 19, 3, 0, Math.PI, false);
    ctx.stroke();

    // Whiskers - thick, white (tiger whiskers)
    ctx.strokeStyle = '#FFFFFF';
    ctx.lineWidth = 1.5;
    ctx.lineCap = 'round';
    // Left whiskers
    ctx.beginPath();
    ctx.moveTo(x + 43, y + 17);
    ctx.lineTo(x + 32, y + 15);
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(x + 43, y + 18);
    ctx.lineTo(x + 31, y + 19);
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(x + 43, y + 19);
    ctx.lineTo(x + 33, y + 23);
    ctx.stroke();
    // Right whiskers
    ctx.beginPath();
    ctx.moveTo(x + 57, y + 17);
    ctx.lineTo(x + 68, y + 15);
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(x + 57, y + 18);
    ctx.lineTo(x + 69, y + 19);
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(x + 57, y + 19);
    ctx.lineTo(x + 67, y + 23);
    ctx.stroke();

    // Legs
    ctx.strokeStyle = '#FF8C00';
    ctx.lineWidth = 4;
    ctx.lineCap = 'round';

    if (tiger.isOnGround && gameState === 'PLAYING') {
        var legPhase = Math.sin(frameCount * 0.3);
        // Front legs
        ctx.beginPath();
        ctx.moveTo(x + 38, y + 40);
        ctx.lineTo(x + 38 + legPhase * 6, y + 50);
        ctx.stroke();
        ctx.beginPath();
        ctx.moveTo(x + 44, y + 40);
        ctx.lineTo(x + 44 - legPhase * 6, y + 50);
        ctx.stroke();
        // Back legs
        ctx.beginPath();
        ctx.moveTo(x + 16, y + 40);
        ctx.lineTo(x + 16 - legPhase * 6, y + 50);
        ctx.stroke();
        ctx.beginPath();
        ctx.moveTo(x + 22, y + 40);
        ctx.lineTo(x + 22 + legPhase * 6, y + 50);
        ctx.stroke();
    } else if (!tiger.isOnGround) {
        // Tucked legs in air
        ctx.beginPath();
        ctx.moveTo(x + 38, y + 40);
        ctx.lineTo(x + 42, y + 46);
        ctx.stroke();
        ctx.beginPath();
        ctx.moveTo(x + 44, y + 40);
        ctx.lineTo(x + 48, y + 46);
        ctx.stroke();
        ctx.beginPath();
        ctx.moveTo(x + 16, y + 40);
        ctx.lineTo(x + 12, y + 46);
        ctx.stroke();
        ctx.beginPath();
        ctx.moveTo(x + 22, y + 40);
        ctx.lineTo(x + 18, y + 46);
        ctx.stroke();
    } else {
        // Standing still (menu)
        ctx.beginPath();
        ctx.moveTo(x + 38, y + 40);
        ctx.lineTo(x + 38, y + 50);
        ctx.stroke();
        ctx.beginPath();
        ctx.moveTo(x + 44, y + 40);
        ctx.lineTo(x + 44, y + 50);
        ctx.stroke();
        ctx.beginPath();
        ctx.moveTo(x + 16, y + 40);
        ctx.lineTo(x + 16, y + 50);
        ctx.stroke();
        ctx.beginPath();
        ctx.moveTo(x + 22, y + 40);
        ctx.lineTo(x + 22, y + 50);
        ctx.stroke();
    }
}

function drawStrawberry(berry) {
    var x = berry.x;
    var y = berry.y;
    var r = berry.radius;

    ctx.save();

    // Glow for golden
    if (berry.isGolden) {
        ctx.shadowColor = '#FFD700';
        ctx.shadowBlur = 15;
    }

    // Berry body
    ctx.fillStyle = berry.isGolden ? '#FFD700' : '#FF2D55';
    ctx.beginPath();
    ctx.moveTo(x, y - r * 0.6);
    ctx.quadraticCurveTo(x + r, y - r * 0.6, x + r * 0.9, y + r * 0.2);
    ctx.quadraticCurveTo(x + r * 0.5, y + r * 1.3, x, y + r * 1.2);
    ctx.quadraticCurveTo(x - r * 0.5, y + r * 1.3, x - r * 0.9, y + r * 0.2);
    ctx.quadraticCurveTo(x - r, y - r * 0.6, x, y - r * 0.6);
    ctx.fill();

    ctx.shadowColor = 'transparent';
    ctx.shadowBlur = 0;

    // Seeds
    ctx.fillStyle = berry.isGolden ? '#FFFFFF' : '#FFD700';
    var seeds = [
        [x - 3, y], [x + 3, y],
        [x - 4, y + r * 0.5], [x + 4, y + r * 0.5],
        [x, y + r * 0.8]
    ];
    for (var i = 0; i < seeds.length; i++) {
        ctx.beginPath();
        ctx.ellipse(seeds[i][0], seeds[i][1], 1, 2, 0, 0, Math.PI * 2);
        ctx.fill();
    }

    // Leaves
    ctx.fillStyle = '#228B22';
    ctx.beginPath();
    ctx.ellipse(x - 4, y - r * 0.7, 5, 3, -0.4, 0, Math.PI * 2);
    ctx.fill();
    ctx.beginPath();
    ctx.ellipse(x + 4, y - r * 0.7, 5, 3, 0.4, 0, Math.PI * 2);
    ctx.fill();

    // Stem
    ctx.strokeStyle = '#228B22';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(x, y - r * 0.6);
    ctx.lineTo(x, y - r * 0.9);
    ctx.stroke();

    // Golden sparkle
    if (berry.isGolden) {
        var sparkle = 0.5 + 0.5 * Math.sin(Date.now() * 0.005);
        ctx.fillStyle = 'rgba(255, 255, 255, ' + sparkle + ')';
        ctx.beginPath();
        ctx.moveTo(x + r + 4, y - 4);
        ctx.lineTo(x + r + 7, y);
        ctx.lineTo(x + r + 4, y + 4);
        ctx.lineTo(x + r + 1, y);
        ctx.closePath();
        ctx.fill();
    }

    ctx.restore();
}

function drawRock(rock) {
    ctx.fillStyle = '#696969';
    ctx.beginPath();
    ctx.moveTo(rock.x, rock.y + rock.height);
    ctx.lineTo(rock.x + 5, rock.y + 5);
    ctx.lineTo(rock.x + 15, rock.y);
    ctx.lineTo(rock.x + 25, rock.y + 3);
    ctx.lineTo(rock.x + rock.width, rock.y + rock.height);
    ctx.closePath();
    ctx.fill();

    // Highlight
    ctx.fillStyle = '#A9A9A9';
    ctx.beginPath();
    ctx.moveTo(rock.x + 10, rock.y + 5);
    ctx.lineTo(rock.x + 15, rock.y + 1);
    ctx.lineTo(rock.x + 22, rock.y + 5);
    ctx.closePath();
    ctx.fill();
}

function drawScore() {
    ctx.font = 'bold 28px "Segoe UI", Arial, sans-serif';
    ctx.fillStyle = '#000000';
    ctx.fillText('Score: ' + score, 22, 42);
    ctx.fillStyle = '#FFFFFF';
    ctx.fillText('Score: ' + score, 20, 40);
}

function drawScoreParticles() {
    for (var i = 0; i < scoreParticles.length; i++) {
        var p = scoreParticles[i];
        ctx.globalAlpha = Math.max(0, p.life);
        ctx.font = 'bold 22px "Segoe UI", Arial, sans-serif';
        ctx.fillStyle = p.color;
        ctx.fillText(p.text, p.x - 10, p.y);
    }
    ctx.globalAlpha = 1;
}

function drawMenuScreen() {
    // Draw background scene
    drawSky();
    drawClouds();
    drawGround();
    drawTiger();

    // Draw a small strawberry above the title
    drawStrawberry({ x: CANVAS_WIDTH / 2, y: 100, radius: 18, isGolden: false, collected: false });

    // Title
    ctx.font = 'bold 42px "Segoe UI", Arial, sans-serif';
    ctx.fillStyle = '#000000';
    ctx.textAlign = 'center';
    ctx.fillText('STRAWBERRY TIGER', CANVAS_WIDTH / 2 + 2, 162);
    ctx.fillStyle = '#C62828';
    ctx.fillText('STRAWBERRY TIGER', CANVAS_WIDTH / 2, 160);

    // Best score
    if (bestScore > 0) {
        ctx.font = '20px "Segoe UI", Arial, sans-serif';
        ctx.fillStyle = '#555555';
        ctx.fillText('Best: ' + bestScore, CANVAS_WIDTH / 2, 195);
    }

    // Click to jump notice
    var pulse = 0.5 + 0.5 * Math.sin(Date.now() * 0.003);
    ctx.globalAlpha = 0.5 + pulse * 0.5;
    ctx.font = '24px "Segoe UI", Arial, sans-serif';
    ctx.fillStyle = '#333333';
    ctx.fillText('Click to Jump', CANVAS_WIDTH / 2, 240);
    ctx.globalAlpha = 1;

    // Footer credit
    ctx.font = '13px "Segoe UI", Arial, sans-serif';
    ctx.fillStyle = '#777777';
    ctx.fillText('Designed and Created by Jiashi, Powered by Claude Code', CANVAS_WIDTH / 2, CANVAS_HEIGHT - 20);

    ctx.textAlign = 'left';
}

function drawGameOverScreen() {
    // Semi-transparent overlay
    ctx.fillStyle = 'rgba(0, 0, 0, 0.6)';
    ctx.fillRect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);

    ctx.textAlign = 'center';

    // Game Over text
    ctx.font = 'bold 44px "Segoe UI", Arial, sans-serif';
    ctx.fillStyle = '#FF2D55';
    ctx.fillText('GAME OVER', CANVAS_WIDTH / 2, 160);

    // Score
    ctx.font = 'bold 30px "Segoe UI", Arial, sans-serif';
    ctx.fillStyle = '#FFFFFF';
    ctx.fillText('Score: ' + score, CANVAS_WIDTH / 2, 210);

    // Best
    ctx.font = '22px "Segoe UI", Arial, sans-serif';
    ctx.fillStyle = '#FFD700';
    ctx.fillText('Best: ' + bestScore, CANVAS_WIDTH / 2, 245);

    // Tap to restart
    var pulse = 0.5 + 0.5 * Math.sin(Date.now() * 0.003);
    ctx.globalAlpha = 0.5 + pulse * 0.5;
    ctx.font = '22px "Segoe UI", Arial, sans-serif';
    ctx.fillStyle = '#FFFFFF';
    ctx.fillText('Tap to Restart', CANVAS_WIDTH / 2, 300);
    ctx.globalAlpha = 1;

    ctx.textAlign = 'left';
}

function render() {
    ctx.clearRect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);

    if (gameState === 'MENU') {
        drawMenuScreen();
        return;
    }

    // Draw game scene
    drawSky();
    drawClouds();
    drawGround();

    for (var i = 0; i < rocks.length; i++) {
        drawRock(rocks[i]);
    }
    for (var i = 0; i < strawberries.length; i++) {
        drawStrawberry(strawberries[i]);
    }

    drawTiger();
    drawScoreParticles();
    drawScore();

    if (gameState === 'GAME_OVER') {
        drawGameOverScreen();
    }
}

// ============================================================
// GAME LOOP
// ============================================================
function gameLoop(timestamp) {
    if (lastTime === 0) lastTime = timestamp;
    var deltaTime = (timestamp - lastTime) / 1000;
    lastTime = timestamp;

    var dt = Math.min(deltaTime, 0.05);

    update(dt);
    render();

    requestAnimationFrame(gameLoop);
}

// ============================================================
// STARTUP
// ============================================================
resetGame();
requestAnimationFrame(gameLoop);
