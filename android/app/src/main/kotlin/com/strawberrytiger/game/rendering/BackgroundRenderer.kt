package com.strawberrytiger.game.rendering

import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Shader
import androidx.core.graphics.toColorInt
import com.strawberrytiger.game.Cloud
import com.strawberrytiger.game.GameConstants.CANVAS_HEIGHT
import com.strawberrytiger.game.GameConstants.CANVAS_WIDTH
import com.strawberrytiger.game.GameConstants.GROUND_Y

class BackgroundRenderer {

    private val skyPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        isDither = true
    }
    private val grassPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = "#4CAF50".toColorInt()
        style = Paint.Style.FILL
    }
    private val dirtPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = "#8B4513".toColorInt()
        style = Paint.Style.FILL
    }
    private val grassDetailPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = "#388E3C".toColorInt()
        style = Paint.Style.STROKE
        strokeWidth = 1f
    }
    private val cloudPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.argb(204, 255, 255, 255) // alpha 0.8
        style = Paint.Style.FILL
    }

    private var skyGradient: LinearGradient? = null
    private val ovalRect = RectF()

    fun drawSky(canvas: Canvas) {
        if (skyGradient == null) {
            skyGradient = LinearGradient(
                0f, 0f, 0f, GROUND_Y,
                "#87CEEB".toColorInt(),
                "#E0F0FF".toColorInt(),
                Shader.TileMode.CLAMP
            )
        }
        skyPaint.shader = skyGradient
        canvas.drawRect(0f, 0f, CANVAS_WIDTH, GROUND_Y, skyPaint)
    }

    fun drawClouds(canvas: Canvas, clouds: List<Cloud>) {
        for (c in clouds) {
            // Main ellipse
            ovalRect.set(c.x, c.y, c.x + c.width, c.y + c.height)
            canvas.drawOval(ovalRect, cloudPaint)

            // Secondary puff
            val px = c.x + c.width * 0.3f - c.width * 0.3f
            val py = c.y + c.height * 0.6f - c.height * 0.4f
            ovalRect.set(px, py, px + c.width * 0.6f, py + c.height * 0.8f)
            canvas.drawOval(ovalRect, cloudPaint)

            // Third puff
            val px2 = c.x + c.width * 0.7f - c.width * 0.35f
            val py2 = c.y + c.height * 0.6f - c.height * 0.35f
            ovalRect.set(px2, py2, px2 + c.width * 0.7f, py2 + c.height * 0.7f)
            canvas.drawOval(ovalRect, cloudPaint)
        }
    }

    fun drawGround(canvas: Canvas, scrollOffset: Float) {
        // Grass strip
        canvas.drawRect(0f, GROUND_Y, CANVAS_WIDTH, GROUND_Y + 20f, grassPaint)

        // Dirt
        canvas.drawRect(0f, GROUND_Y + 20f, CANVAS_WIDTH, CANVAS_HEIGHT, dirtPaint)

        // Scrolling grass detail
        val offset = scrollOffset % 20f
        var x = -offset
        while (x < CANVAS_WIDTH + 20f) {
            canvas.drawLine(x, GROUND_Y, x + 5f, GROUND_Y - 6f, grassDetailPaint)
            canvas.drawLine(x + 10f, GROUND_Y, x + 13f, GROUND_Y - 4f, grassDetailPaint)
            x += 20f
        }
    }
}
