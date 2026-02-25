package com.strawberrytiger.game.rendering

import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import com.strawberrytiger.game.GameConstants.CANVAS_HEIGHT
import com.strawberrytiger.game.GameConstants.CANVAS_WIDTH
import com.strawberrytiger.game.ScoreParticle
import com.strawberrytiger.game.Strawberry
import kotlin.math.sin

class UIRenderer {

    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val overlayPaint = Paint().apply {
        color = Color.argb(153, 0, 0, 0) // rgba(0,0,0,0.6)
        style = Paint.Style.FILL
    }

    private val strawberryRenderer = StrawberryRenderer()

    fun drawScore(canvas: Canvas, score: Int) {
        textPaint.typeface = Typeface.DEFAULT_BOLD
        textPaint.textSize = 28f
        textPaint.textAlign = Paint.Align.LEFT

        // Shadow
        textPaint.color = Color.BLACK
        canvas.drawText("Score: $score", 22f, 42f, textPaint)
        // White on top
        textPaint.color = Color.WHITE
        canvas.drawText("Score: $score", 20f, 40f, textPaint)
    }

    fun drawScoreParticles(canvas: Canvas, particles: List<ScoreParticle>) {
        textPaint.typeface = Typeface.DEFAULT_BOLD
        textPaint.textSize = 22f
        textPaint.textAlign = Paint.Align.LEFT

        for (p in particles) {
            textPaint.alpha = (p.life.coerceAtLeast(0f) * 255).toInt()
            textPaint.color = p.color
            textPaint.alpha = (p.life.coerceAtLeast(0f) * 255).toInt()
            canvas.drawText(p.text, p.x - 10f, p.y, textPaint)
        }
        textPaint.alpha = 255
    }

    fun drawMenuScreen(
        canvas: Canvas,
        backgroundRenderer: BackgroundRenderer,
        tigerRenderer: TigerRenderer,
        tiger: com.strawberrytiger.game.Tiger,
        clouds: List<com.strawberrytiger.game.Cloud>,
        scrollOffset: Float,
        frameCount: Int,
        bestScore: Int,
        gameState: com.strawberrytiger.game.GameState
    ) {
        // Draw background scene
        backgroundRenderer.drawSky(canvas)
        backgroundRenderer.drawClouds(canvas, clouds)
        backgroundRenderer.drawGround(canvas, scrollOffset)
        tigerRenderer.draw(canvas, tiger, frameCount, gameState)

        // Draw a small strawberry above the title
        val menuBerry = Strawberry(
            x = CANVAS_WIDTH / 2f,
            y = 100f,
            radius = 18f,
            isGolden = false,
            collected = false
        )
        strawberryRenderer.draw(canvas, menuBerry)

        // Title
        textPaint.typeface = Typeface.DEFAULT_BOLD
        textPaint.textSize = 42f
        textPaint.textAlign = Paint.Align.CENTER
        // Shadow
        textPaint.color = Color.BLACK
        textPaint.alpha = 255
        canvas.drawText("STRAWBERRY TIGER", CANVAS_WIDTH / 2f + 2f, 162f, textPaint)
        // Red title
        textPaint.color = Color.parseColor("#C62828")
        canvas.drawText("STRAWBERRY TIGER", CANVAS_WIDTH / 2f, 160f, textPaint)

        // Best score
        if (bestScore > 0) {
            textPaint.typeface = Typeface.DEFAULT
            textPaint.textSize = 20f
            textPaint.color = Color.parseColor("#555555")
            canvas.drawText("Best: $bestScore", CANVAS_WIDTH / 2f, 195f, textPaint)
        }

        // Click to jump notice (pulsing)
        val pulse = 0.5f + 0.5f * sin(System.currentTimeMillis() * 0.003f)
        textPaint.typeface = Typeface.DEFAULT
        textPaint.textSize = 24f
        textPaint.color = Color.parseColor("#333333")
        textPaint.alpha = ((0.5f + pulse * 0.5f) * 255).toInt()
        canvas.drawText("Click to Jump", CANVAS_WIDTH / 2f, 240f, textPaint)
        textPaint.alpha = 255

        // Footer credit
        textPaint.textSize = 13f
        textPaint.color = Color.parseColor("#777777")
        canvas.drawText(
            "Designed and Created by Jiashi, Powered by Claude Code",
            CANVAS_WIDTH / 2f,
            CANVAS_HEIGHT - 20f,
            textPaint
        )

        textPaint.textAlign = Paint.Align.LEFT
    }

    fun drawGameOverScreen(canvas: Canvas, score: Int, bestScore: Int) {
        // Semi-transparent overlay
        canvas.drawRect(0f, 0f, CANVAS_WIDTH, CANVAS_HEIGHT, overlayPaint)

        textPaint.textAlign = Paint.Align.CENTER

        // Game Over text
        textPaint.typeface = Typeface.DEFAULT_BOLD
        textPaint.textSize = 44f
        textPaint.color = Color.parseColor("#FF2D55")
        textPaint.alpha = 255
        canvas.drawText("GAME OVER", CANVAS_WIDTH / 2f, 160f, textPaint)

        // Score
        textPaint.textSize = 30f
        textPaint.color = Color.WHITE
        canvas.drawText("Score: $score", CANVAS_WIDTH / 2f, 210f, textPaint)

        // Best
        textPaint.typeface = Typeface.DEFAULT
        textPaint.textSize = 22f
        textPaint.color = Color.parseColor("#FFD700")
        canvas.drawText("Best: $bestScore", CANVAS_WIDTH / 2f, 245f, textPaint)

        // Tap to restart (pulsing)
        val pulse = 0.5f + 0.5f * sin(System.currentTimeMillis() * 0.003f)
        textPaint.textSize = 22f
        textPaint.color = Color.WHITE
        textPaint.alpha = ((0.5f + pulse * 0.5f) * 255).toInt()
        canvas.drawText("Tap to Restart", CANVAS_WIDTH / 2f, 300f, textPaint)
        textPaint.alpha = 255

        textPaint.textAlign = Paint.Align.LEFT
    }
}
