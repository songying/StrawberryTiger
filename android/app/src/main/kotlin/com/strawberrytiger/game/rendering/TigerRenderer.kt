package com.strawberrytiger.game.rendering

import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import com.strawberrytiger.game.GameState
import com.strawberrytiger.game.Tiger
import kotlin.math.sin

class TigerRenderer {

    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val path = Path()
    private val ovalRect = RectF()

    private fun drawRotatedOval(canvas: Canvas, cx: Float, cy: Float, rx: Float, ry: Float, rotationRad: Float, p: Paint) {
        canvas.save()
        canvas.translate(cx, cy)
        canvas.rotate(Math.toDegrees(rotationRad.toDouble()).toFloat())
        ovalRect.set(-rx, -ry, rx, ry)
        canvas.drawOval(ovalRect, p)
        canvas.restore()
    }

    private fun drawOvalAt(canvas: Canvas, cx: Float, cy: Float, rx: Float, ry: Float, p: Paint) {
        ovalRect.set(cx - rx, cy - ry, cx + rx, cy + ry)
        canvas.drawOval(ovalRect, p)
    }

    // Port of roundRect helper
    private fun drawRoundRect(canvas: Canvas, x: Float, y: Float, w: Float, h: Float, radius: Float, p: Paint) {
        ovalRect.set(x, y, x + w, y + h)
        canvas.drawRoundRect(ovalRect, radius, radius, p)
    }

    fun draw(canvas: Canvas, tiger: Tiger, frameCount: Int, gameState: GameState) {
        val x = tiger.x
        val y = tiger.y

        // --- Tail ---
        paint.style = Paint.Style.STROKE
        paint.strokeCap = Paint.Cap.ROUND

        val tipWag = sin(frameCount * 0.12f) * 4f

        // Orange tail
        paint.color = Color.parseColor("#FF8C00")
        paint.strokeWidth = 5f
        path.reset()
        path.moveTo(x + 8f, y + 20f)
        path.quadTo(x - 6f, y + 16f, x - 14f, y + 12f + tipWag)
        canvas.drawPath(path, paint)

        // Black rings on tail
        paint.color = Color.parseColor("#1a1a1a")
        paint.strokeWidth = 2f
        canvas.drawLine(x - 1f, y + 17.5f, x - 3f, y + 19f, paint)
        canvas.drawLine(x - 7f, y + 15f, x - 9f, y + 16.5f, paint)
        canvas.drawLine(x - 12f, y + 12.5f + tipWag * 0.7f, x - 14f, y + 14f + tipWag * 0.7f, paint)

        // --- Body ---
        paint.style = Paint.Style.FILL
        paint.color = Color.parseColor("#FF8C00")
        drawRoundRect(canvas, x + 6f, y + 10f, 46f, 32f, 8f, paint)

        // White belly
        paint.color = Color.parseColor("#FFF3E0")
        drawOvalAt(canvas, x + 30f, y + 36f, 18f, 6f, paint)

        // Body stripes
        paint.style = Paint.Style.STROKE
        paint.color = Color.parseColor("#1a1a1a")
        paint.strokeWidth = 2.5f
        // Stripe 1
        path.reset()
        path.moveTo(x + 16f, y + 12f)
        path.quadTo(x + 14f, y + 24f, x + 17f, y + 36f)
        canvas.drawPath(path, paint)
        // Stripe 2
        path.reset()
        path.moveTo(x + 24f, y + 11f)
        path.quadTo(x + 22f, y + 22f, x + 25f, y + 35f)
        canvas.drawPath(path, paint)
        // Stripe 3
        path.reset()
        path.moveTo(x + 32f, y + 11f)
        path.quadTo(x + 34f, y + 22f, x + 31f, y + 36f)
        canvas.drawPath(path, paint)
        // Stripe 4
        path.reset()
        path.moveTo(x + 40f, y + 12f)
        path.quadTo(x + 42f, y + 24f, x + 39f, y + 35f)
        canvas.drawPath(path, paint)

        // --- Ears ---
        paint.style = Paint.Style.FILL
        // Left ear
        paint.color = Color.parseColor("#FF8C00")
        drawRotatedOval(canvas, x + 43f, y + 3f, 5f, 6f, -0.15f, paint)
        // Right ear
        drawRotatedOval(canvas, x + 57f, y + 3f, 5f, 6f, 0.15f, paint)

        // Black ear backs (only top half: from PI to 2*PI)
        // We approximate by drawing a smaller oval shifted up
        paint.color = Color.parseColor("#1a1a1a")
        // Left ear back - top half
        canvas.save()
        canvas.translate(x + 43f, y + 1f)
        canvas.rotate(Math.toDegrees(-0.15).toFloat())
        canvas.clipRect(-5f, -5f, 5f, 0f)
        ovalRect.set(-4f, -4f, 4f, 4f)
        canvas.drawOval(ovalRect, paint)
        canvas.restore()
        // Right ear back - top half
        canvas.save()
        canvas.translate(x + 57f, y + 1f)
        canvas.rotate(Math.toDegrees(0.15).toFloat())
        canvas.clipRect(-5f, -5f, 5f, 0f)
        ovalRect.set(-4f, -4f, 4f, 4f)
        canvas.drawOval(ovalRect, paint)
        canvas.restore()

        // White ear spots
        paint.color = Color.WHITE
        canvas.drawCircle(x + 43f, y + 1f, 2f, paint)
        canvas.drawCircle(x + 57f, y + 1f, 2f, paint)

        // --- Head ---
        paint.color = Color.parseColor("#FFA500")
        drawOvalAt(canvas, x + 50f, y + 13f, 13f, 12f, paint)

        // White muzzle
        paint.color = Color.parseColor("#FFF8E1")
        drawOvalAt(canvas, x + 50f, y + 18f, 8f, 6f, paint)

        // White cheek patches
        paint.color = Color.parseColor("#FFF3E0")
        drawRotatedOval(canvas, x + 42f, y + 15f, 4f, 3f, -0.3f, paint)
        drawRotatedOval(canvas, x + 58f, y + 15f, 4f, 3f, 0.3f, paint)

        // Face stripes
        paint.style = Paint.Style.STROKE
        paint.color = Color.parseColor("#1a1a1a")
        paint.strokeWidth = 2f
        // Left face stripes
        path.reset()
        path.moveTo(x + 40f, y + 6f)
        path.quadTo(x + 42f, y + 9f, x + 44f, y + 8f)
        canvas.drawPath(path, paint)
        path.reset()
        path.moveTo(x + 38f, y + 9f)
        path.quadTo(x + 41f, y + 12f, x + 43f, y + 11f)
        canvas.drawPath(path, paint)
        // Right face stripes
        path.reset()
        path.moveTo(x + 60f, y + 6f)
        path.quadTo(x + 58f, y + 9f, x + 56f, y + 8f)
        canvas.drawPath(path, paint)
        path.reset()
        path.moveTo(x + 62f, y + 9f)
        path.quadTo(x + 59f, y + 12f, x + 57f, y + 11f)
        canvas.drawPath(path, paint)

        // --- Eyes ---
        paint.style = Paint.Style.FILL
        // White
        paint.color = Color.WHITE
        drawRotatedOval(canvas, x + 45f, y + 11f, 3.5f, 2.5f, -0.1f, paint)
        drawRotatedOval(canvas, x + 55f, y + 11f, 3.5f, 2.5f, 0.1f, paint)
        // Amber iris
        paint.color = Color.parseColor("#E6A800")
        canvas.drawCircle(x + 46f, y + 11f, 2f, paint)
        canvas.drawCircle(x + 56f, y + 11f, 2f, paint)
        // Black pupils
        paint.color = Color.BLACK
        canvas.drawCircle(x + 46f, y + 11f, 1f, paint)
        canvas.drawCircle(x + 56f, y + 11f, 1f, paint)

        // --- Nose ---
        paint.color = Color.parseColor("#D4576B")
        drawOvalAt(canvas, x + 50f, y + 16f, 3f, 2f, paint)
        // Black half (bottom half only)
        paint.color = Color.parseColor("#1a1a1a")
        canvas.save()
        canvas.translate(x + 50f, y + 15.5f)
        canvas.clipRect(-3f, 0f, 3f, 2f)
        ovalRect.set(-2.5f, -1.5f, 2.5f, 1.5f)
        canvas.drawOval(ovalRect, paint)
        canvas.restore()

        // --- Mouth ---
        paint.style = Paint.Style.STROKE
        paint.color = Color.parseColor("#1a1a1a")
        paint.strokeWidth = 1f
        canvas.drawLine(x + 50f, y + 17.5f, x + 50f, y + 19f, paint)
        // Left arc
        ovalRect.set(x + 44f, y + 16f, x + 50f, y + 22f)
        canvas.drawArc(ovalRect, 0f, 180f, false, paint)
        // Right arc
        ovalRect.set(x + 50f, y + 16f, x + 56f, y + 22f)
        canvas.drawArc(ovalRect, 0f, 180f, false, paint)

        // --- Whiskers ---
        paint.color = Color.WHITE
        paint.strokeWidth = 1.5f
        paint.strokeCap = Paint.Cap.ROUND
        // Left whiskers
        canvas.drawLine(x + 43f, y + 17f, x + 32f, y + 15f, paint)
        canvas.drawLine(x + 43f, y + 18f, x + 31f, y + 19f, paint)
        canvas.drawLine(x + 43f, y + 19f, x + 33f, y + 23f, paint)
        // Right whiskers
        canvas.drawLine(x + 57f, y + 17f, x + 68f, y + 15f, paint)
        canvas.drawLine(x + 57f, y + 18f, x + 69f, y + 19f, paint)
        canvas.drawLine(x + 57f, y + 19f, x + 67f, y + 23f, paint)

        // --- Legs ---
        paint.color = Color.parseColor("#FF8C00")
        paint.strokeWidth = 4f
        paint.strokeCap = Paint.Cap.ROUND

        if (tiger.isOnGround && gameState == GameState.PLAYING) {
            val legPhase = sin(frameCount * 0.3f)
            // Front legs
            canvas.drawLine(x + 38f, y + 40f, x + 38f + legPhase * 6f, y + 50f, paint)
            canvas.drawLine(x + 44f, y + 40f, x + 44f - legPhase * 6f, y + 50f, paint)
            // Back legs
            canvas.drawLine(x + 16f, y + 40f, x + 16f - legPhase * 6f, y + 50f, paint)
            canvas.drawLine(x + 22f, y + 40f, x + 22f + legPhase * 6f, y + 50f, paint)
        } else if (!tiger.isOnGround) {
            // Tucked legs in air
            canvas.drawLine(x + 38f, y + 40f, x + 42f, y + 46f, paint)
            canvas.drawLine(x + 44f, y + 40f, x + 48f, y + 46f, paint)
            canvas.drawLine(x + 16f, y + 40f, x + 12f, y + 46f, paint)
            canvas.drawLine(x + 22f, y + 40f, x + 18f, y + 46f, paint)
        } else {
            // Standing still (menu)
            canvas.drawLine(x + 38f, y + 40f, x + 38f, y + 50f, paint)
            canvas.drawLine(x + 44f, y + 40f, x + 44f, y + 50f, paint)
            canvas.drawLine(x + 16f, y + 40f, x + 16f, y + 50f, paint)
            canvas.drawLine(x + 22f, y + 40f, x + 22f, y + 50f, paint)
        }
    }
}
