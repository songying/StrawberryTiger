package com.strawberrytiger.game

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.PixelFormat
import android.view.MotionEvent
import android.view.SurfaceHolder
import android.view.SurfaceView
import com.strawberrytiger.game.GameConstants.BASE_SCROLL_SPEED
import com.strawberrytiger.game.GameConstants.CANVAS_HEIGHT
import com.strawberrytiger.game.GameConstants.CANVAS_WIDTH
import com.strawberrytiger.game.GameConstants.CLUSTER_CHANCE
import com.strawberrytiger.game.GameConstants.GOLDEN_PROBABILITY
import com.strawberrytiger.game.GameConstants.GRAVITY
import com.strawberrytiger.game.GameConstants.GROUND_Y
import com.strawberrytiger.game.GameConstants.HITBOX_INSET
import com.strawberrytiger.game.GameConstants.JUMP_VELOCITY
import com.strawberrytiger.game.GameConstants.MAX_FALL_SPEED
import com.strawberrytiger.game.GameConstants.MAX_SCROLL_SPEED
import com.strawberrytiger.game.GameConstants.ROCK_HEIGHT
import com.strawberrytiger.game.GameConstants.ROCK_SPAWN_INTERVAL
import com.strawberrytiger.game.GameConstants.ROCK_SPAWN_VARIANCE
import com.strawberrytiger.game.GameConstants.ROCK_WIDTH
import com.strawberrytiger.game.GameConstants.SPAWN_INTERVAL_VARIANCE
import com.strawberrytiger.game.GameConstants.SPEED_INCREASE_RATE
import com.strawberrytiger.game.GameConstants.STRAWBERRY_MAX_Y
import com.strawberrytiger.game.GameConstants.STRAWBERRY_MIN_Y
import com.strawberrytiger.game.GameConstants.STRAWBERRY_RADIUS
import com.strawberrytiger.game.GameConstants.STRAWBERRY_SPAWN_INTERVAL
import com.strawberrytiger.game.GameConstants.TIGER_HEIGHT
import com.strawberrytiger.game.GameConstants.TIGER_WIDTH
import com.strawberrytiger.game.GameConstants.TIGER_X
import com.strawberrytiger.game.rendering.BackgroundRenderer
import com.strawberrytiger.game.rendering.RockRenderer
import com.strawberrytiger.game.rendering.StrawberryRenderer
import com.strawberrytiger.game.rendering.TigerRenderer
import com.strawberrytiger.game.rendering.UIRenderer
import android.util.Log
import kotlin.math.floor
import kotlin.math.min
import kotlin.random.Random

class GameSurfaceView(context: Context) : SurfaceView(context), SurfaceHolder.Callback {

    private var gameThread: GameThread? = null
    private val scoreManager = ScoreManager(context)
    private val soundManager = SoundManager(context)

    // Renderers
    private val backgroundRenderer = BackgroundRenderer()
    private val tigerRenderer = TigerRenderer()
    private val strawberryRenderer = StrawberryRenderer()
    private val rockRenderer = RockRenderer()
    private val uiRenderer = UIRenderer()

    // Game state
    private var gameState = GameState.MENU
    private var score = 0
    private var bestScore = scoreManager.getHighScore()
    private var scrollSpeed = BASE_SCROLL_SPEED
    private var scrollOffset = 0f
    private var frameCount = 0
    private var playTime = 0f

    // Entities
    private lateinit var tiger: Tiger
    private val strawberries = mutableListOf<Strawberry>()
    private val rocks = mutableListOf<Rock>()
    private val clouds = mutableListOf<Cloud>()
    private val scoreParticles = mutableListOf<ScoreParticle>()
    private var strawberrySpawnTimer = 0f
    private var rockSpawnTimer = 0f

    // View dimensions for scaling
    private var viewWidth = 0
    private var viewHeight = 0

    init {
        holder.addCallback(this)
        holder.setFormat(PixelFormat.RGBA_8888)
        isFocusable = true
        keepScreenOn = true
        resetGame()
    }

    private fun initTiger() {
        tiger = Tiger(
            x = TIGER_X,
            y = GROUND_Y - TIGER_HEIGHT,
            width = TIGER_WIDTH,
            height = TIGER_HEIGHT,
            velocityY = 0f,
            isOnGround = true,
            groundY = GROUND_Y - TIGER_HEIGHT
        )
    }

    private fun initClouds() {
        clouds.clear()
        for (i in 0 until 5) {
            clouds.add(
                Cloud(
                    x = Random.nextFloat() * CANVAS_WIDTH,
                    y = 30f + Random.nextFloat() * 100f,
                    width = 60f + Random.nextFloat() * 80f,
                    height = 20f + Random.nextFloat() * 20f,
                    speed = 0.2f + Random.nextFloat() * 0.3f
                )
            )
        }
    }

    private fun resetGame() {
        initTiger()
        initClouds()
        strawberries.clear()
        rocks.clear()
        scoreParticles.clear()
        score = 0
        scrollSpeed = BASE_SCROLL_SPEED
        scrollOffset = 0f
        playTime = 0f
        strawberrySpawnTimer = 1.0f
        rockSpawnTimer = 2.0f
        bestScore = scoreManager.getHighScore()
    }

    private fun startGame() {
        resetGame()
        gameState = GameState.PLAYING
        soundManager.startBGM()
    }

    // --- Update functions ---

    fun update(dt: Float) {
        if (gameState != GameState.PLAYING) return

        frameCount++
        scrollOffset += scrollSpeed * dt

        updateTiger(dt)
        spawnStrawberries(dt)
        updateStrawberries(dt)
        spawnRocks(dt)
        updateRocks(dt)
        updateClouds(dt)
        updateScoreParticles(dt)
        checkCollisions()
        updateDifficulty(dt)
    }

    private fun updateTiger(dt: Float) {
        if (!tiger.isOnGround) {
            tiger.velocityY += GRAVITY * dt
            tiger.velocityY = tiger.velocityY.coerceAtMost(MAX_FALL_SPEED)
            tiger.y += tiger.velocityY * dt

            if (tiger.y >= tiger.groundY) {
                tiger.y = tiger.groundY
                tiger.velocityY = 0f
                tiger.isOnGround = true
            }
        }
    }

    private fun spawnStrawberries(dt: Float) {
        strawberrySpawnTimer -= dt
        if (strawberrySpawnTimer <= 0f) {
            strawberrySpawnTimer = STRAWBERRY_SPAWN_INTERVAL +
                    (Random.nextFloat() - 0.5f) * SPAWN_INTERVAL_VARIANCE * 2f

            val count = if (Random.nextFloat() < CLUSTER_CHANCE) {
                floor(Random.nextFloat() * 2f).toInt() + 2
            } else {
                1
            }

            for (i in 0 until count) {
                val isGolden = Random.nextFloat() < GOLDEN_PROBABILITY
                val r = (Random.nextFloat() + Random.nextFloat()) / 2f
                val yPos = STRAWBERRY_MIN_Y + r * (STRAWBERRY_MAX_Y - STRAWBERRY_MIN_Y)

                strawberries.add(
                    Strawberry(
                        x = CANVAS_WIDTH + 20f + i * 45f,
                        y = yPos,
                        radius = STRAWBERRY_RADIUS,
                        isGolden = isGolden,
                        collected = false
                    )
                )
            }
        }
    }

    private fun updateStrawberries(dt: Float) {
        val iter = strawberries.iterator()
        while (iter.hasNext()) {
            val s = iter.next()
            s.x -= scrollSpeed * dt
            if (s.x < -30f) {
                iter.remove()
            }
        }
    }

    private fun spawnRocks(dt: Float) {
        rockSpawnTimer -= dt
        if (rockSpawnTimer <= 0f) {
            rockSpawnTimer = ROCK_SPAWN_INTERVAL +
                    (Random.nextFloat() - 0.5f) * ROCK_SPAWN_VARIANCE * 2f

            rocks.add(
                Rock(
                    x = CANVAS_WIDTH + 20f,
                    y = GROUND_Y - ROCK_HEIGHT,
                    width = ROCK_WIDTH,
                    height = ROCK_HEIGHT
                )
            )
        }
    }

    private fun updateRocks(dt: Float) {
        val iter = rocks.iterator()
        while (iter.hasNext()) {
            val r = iter.next()
            r.x -= scrollSpeed * dt
            if (r.x < -40f) {
                iter.remove()
            }
        }
    }

    private fun updateClouds(dt: Float) {
        for (c in clouds) {
            c.x -= c.speed * scrollSpeed * dt
            if (c.x + c.width < 0f) {
                c.x = CANVAS_WIDTH + Random.nextFloat() * 100f
                c.y = 30f + Random.nextFloat() * 100f
            }
        }
    }

    private fun updateScoreParticles(dt: Float) {
        val iter = scoreParticles.iterator()
        while (iter.hasNext()) {
            val p = iter.next()
            p.y += p.velocityY * dt
            p.life -= dt
            if (p.life <= 0f) {
                iter.remove()
            }
        }
    }

    private fun aabbCollision(
        ax: Float, ay: Float, aw: Float, ah: Float,
        bx: Float, by: Float, bw: Float, bh: Float
    ): Boolean {
        return ax < bx + bw && ax + aw > bx && ay < by + bh && ay + ah > by
    }

    private fun checkCollisions() {
        // Tiger hitbox (inset from visual bounds)
        val thx = tiger.x + HITBOX_INSET
        val thy = tiger.y + HITBOX_INSET
        val thw = tiger.width - HITBOX_INSET * 2
        val thh = tiger.height - HITBOX_INSET * 2

        // Strawberry collisions
        val collectedList = mutableListOf<Strawberry>()
        for (s in strawberries) {
            if (s.collected) continue
            val sbx = s.x - s.radius
            val sby = s.y - s.radius
            val sbw = s.radius * 2
            val sbh = s.radius * 2

            if (aabbCollision(thx, thy, thw, thh, sbx, sby, sbw, sbh)) {
                s.collected = true
                collectedList.add(s)
                val points = if (s.isGolden) 3 else 1
                score += points
                if (s.isGolden) {
                    soundManager.playGoldenSound()
                } else {
                    soundManager.playScoreSound()
                }

                scoreParticles.add(
                    ScoreParticle(
                        x = s.x,
                        y = s.y,
                        text = "+$points",
                        color = if (s.isGolden) Color.parseColor("#FFD700") else Color.WHITE,
                        life = 1.0f,
                        velocityY = -80f
                    )
                )
            }
        }

        // Remove collected strawberries
        strawberries.removeAll { it.collected }

        // Rock collisions
        for (r in rocks) {
            if (aabbCollision(thx, thy, thw, thh, r.x, r.y, r.width, r.height)) {
                scoreManager.saveHighScore(score)
                bestScore = scoreManager.getHighScore()
                gameState = GameState.GAME_OVER
                soundManager.stopBGM()
                soundManager.playGameOverSound()
                return
            }
        }
    }

    private fun updateDifficulty(dt: Float) {
        playTime += dt
        scrollSpeed = min(
            BASE_SCROLL_SPEED + playTime * SPEED_INCREASE_RATE,
            MAX_SCROLL_SPEED
        )
    }

    // --- Render ---

    fun render(canvas: Canvas) {
        canvas.save()

        // Clear entire physical screen first
        canvas.drawColor(Color.BLACK)

        // If the surface is portrait but the game needs landscape, rotate 90° clockwise
        val isPortrait = viewHeight > viewWidth && viewWidth > 0
        val scaleX: Float
        val scaleY: Float

        if (isPortrait) {
            canvas.translate(viewWidth.toFloat(), 0f)
            canvas.rotate(90f)
            // After rotation, effective dimensions are viewHeight x viewWidth
            scaleX = viewHeight / CANVAS_WIDTH
            scaleY = viewWidth / CANVAS_HEIGHT
        } else {
            scaleX = viewWidth / CANVAS_WIDTH
            scaleY = viewHeight / CANVAS_HEIGHT
        }
        canvas.scale(scaleX, scaleY)

        if (gameState == GameState.MENU) {
            uiRenderer.drawMenuScreen(
                canvas, backgroundRenderer, tigerRenderer,
                tiger, clouds, scrollOffset, frameCount, bestScore, gameState
            )
            canvas.restore()
            return
        }

        // Draw game scene
        backgroundRenderer.drawSky(canvas)
        backgroundRenderer.drawClouds(canvas, clouds)
        backgroundRenderer.drawGround(canvas, scrollOffset)

        for (rock in rocks) {
            rockRenderer.draw(canvas, rock)
        }
        for (berry in strawberries) {
            strawberryRenderer.draw(canvas, berry)
        }

        tigerRenderer.draw(canvas, tiger, frameCount, gameState)
        uiRenderer.drawScoreParticles(canvas, scoreParticles)
        uiRenderer.drawScore(canvas, score)

        if (gameState == GameState.GAME_OVER) {
            uiRenderer.drawGameOverScreen(canvas, score, bestScore)
        }

        canvas.restore()
    }

    // --- Touch input ---

    override fun onTouchEvent(event: MotionEvent): Boolean {
        if (event.action == MotionEvent.ACTION_DOWN) {
            handleInput()
            return true
        }
        return super.onTouchEvent(event)
    }

    private fun handleInput() {
        when (gameState) {
            GameState.MENU -> {
                startGame()
            }
            GameState.PLAYING -> {
                if (tiger.isOnGround) {
                    tiger.velocityY = JUMP_VELOCITY
                    tiger.isOnGround = false
                    soundManager.playJumpSound()
                }
            }
            GameState.GAME_OVER -> {
                gameState = GameState.MENU
                resetGame()
            }
        }
    }

    // --- SurfaceHolder.Callback ---

    override fun surfaceCreated(holder: SurfaceHolder) {
        Log.d("GameSurface", "surfaceCreated")
        startThread(holder)
    }

    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
        Log.d("GameSurface", "surfaceChanged: ${width}x${height}")
        viewWidth = width
        viewHeight = height
    }

    override fun surfaceDestroyed(holder: SurfaceHolder) {
        Log.d("GameSurface", "surfaceDestroyed")
        stopThread()
    }

    private fun startThread(holder: SurfaceHolder) {
        stopThread()
        gameThread = GameThread(holder, this).apply {
            running = true
            start()
        }
    }

    private fun stopThread() {
        gameThread?.running = false
        var retry = true
        while (retry) {
            try {
                gameThread?.join(500)
                retry = false
            } catch (e: InterruptedException) {
                // Retry
            }
        }
        gameThread = null
    }

    fun pause() {
        soundManager.stopBGM()
    }

    fun resume() {
        if (gameState == GameState.PLAYING) {
            soundManager.startBGM()
        }
    }

    fun destroy() {
        soundManager.release()
    }
}
