package com.strawberrytiger.game

import android.util.Log
import android.view.SurfaceHolder

class GameThread(
    private val surfaceHolder: SurfaceHolder,
    private val gameSurfaceView: GameSurfaceView
) : Thread() {

    @Volatile
    var running = false

    override fun run() {
        var lastTime = System.nanoTime()
        Log.d("GameThread", "Thread started, running=$running")

        while (running) {
            val now = System.nanoTime()
            val deltaTime = (now - lastTime) / 1_000_000_000.0f
            lastTime = now

            val dt = deltaTime.coerceAtMost(0.05f)

            gameSurfaceView.update(dt)

            var canvas = null as android.graphics.Canvas?
            try {
                canvas = surfaceHolder.lockCanvas()
                if (canvas != null) {
                    synchronized(surfaceHolder) {
                        gameSurfaceView.render(canvas)
                    }
                }
            } catch (e: Exception) {
                Log.e("GameThread", "Render error", e)
            } finally {
                if (canvas != null) {
                    try {
                        surfaceHolder.unlockCanvasAndPost(canvas)
                    } catch (e: Exception) {
                        Log.e("GameThread", "unlockCanvas error", e)
                    }
                }
            }

            // Target ~60 fps
            val elapsed = (System.nanoTime() - now) / 1_000_000
            val sleepTime = (16 - elapsed).coerceAtLeast(1)
            try {
                sleep(sleepTime)
            } catch (e: InterruptedException) {
                // Ignore
            }
        }
        Log.d("GameThread", "Thread exiting")
    }
}
