package com.strawberrytiger.game.rendering

import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import androidx.core.graphics.toColorInt
import androidx.core.graphics.withSave
import com.strawberrytiger.game.Strawberry
import kotlin.math.sin

class StrawberryRenderer {

    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val path = Path()
    private val ovalRect = RectF()

    private fun drawRotatedOval(canvas: Canvas, cx: Float, cy: Float, rx: Float, ry: Float, rotationRad: Float, p: Paint) {
        canvas.withSave {
            translate(cx, cy)
            rotate(Math.toDegrees(rotationRad.toDouble()).toFloat())
            ovalRect.set(-rx, -ry, rx, ry)
            drawOval(ovalRect, p)
        }
    }

    private fun drawOvalAt(canvas: Canvas, cx: Float, cy: Float, rx: Float, ry: Float, p: Paint) {
        ovalRect.set(cx - rx, cy - ry, cx + rx, cy + ry)
        canvas.drawOval(ovalRect, p)
    }

    fun draw(canvas: Canvas, berry: Strawberry) {
        val x = berry.x
        val y = berry.y
        val r = berry.radius

        canvas.withSave {
            // Glow for golden
            if (berry.isGolden) {
                paint.setShadowLayer(15f, 0f, 0f, "#FFD700".toColorInt())
            }

            // Berry body
            paint.style = Paint.Style.FILL
            paint.color = if (berry.isGolden) "#FFD700".toColorInt() else "#FF2D55".toColorInt()
            path.reset()
            path.moveTo(x, y - r * 0.6f)
            path.quadTo(x + r, y - r * 0.6f, x + r * 0.9f, y + r * 0.2f)
            path.quadTo(x + r * 0.5f, y + r * 1.3f, x, y + r * 1.2f)
            path.quadTo(x - r * 0.5f, y + r * 1.3f, x - r * 0.9f, y + r * 0.2f)
            path.quadTo(x - r, y - r * 0.6f, x, y - r * 0.6f)
            drawPath(path, paint)

            paint.clearShadowLayer()

            // Seeds
            paint.color = if (berry.isGolden) Color.WHITE else "#FFD700".toColorInt()
            val seeds = arrayOf(
                floatArrayOf(x - 3f, y),
                floatArrayOf(x + 3f, y),
                floatArrayOf(x - 4f, y + r * 0.5f),
                floatArrayOf(x + 4f, y + r * 0.5f),
                floatArrayOf(x, y + r * 0.8f)
            )
            for (seed in seeds) {
                drawOvalAt(this, seed[0], seed[1], 1f, 2f, paint)
            }

            // Leaves
            paint.color = "#228B22".toColorInt()
            drawRotatedOval(this, x - 4f, y - r * 0.7f, 5f, 3f, -0.4f, paint)
            drawRotatedOval(this, x + 4f, y - r * 0.7f, 5f, 3f, 0.4f, paint)

            // Stem
            paint.style = Paint.Style.STROKE
            paint.color = "#228B22".toColorInt()
            paint.strokeWidth = 2f
            drawLine(x, y - r * 0.6f, x, y - r * 0.9f, paint)

            // Golden sparkle
            if (berry.isGolden) {
                val sparkle = 0.5f + 0.5f * sin(System.currentTimeMillis() * 0.005f)
                paint.style = Paint.Style.FILL
                paint.color = Color.WHITE
                paint.alpha = (sparkle * 255).toInt().coerceIn(0, 255)
                path.reset()
                path.moveTo(x + r + 4f, y - 4f)
                path.lineTo(x + r + 7f, y)
                path.lineTo(x + r + 4f, y + 4f)
                path.lineTo(x + r + 1f, y)
                path.close()
                drawPath(path, paint)
                paint.alpha = 255
            }
        }
    }
}
