package com.strawberrytiger.game.rendering

import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import androidx.core.graphics.toColorInt
import com.strawberrytiger.game.Rock

class RockRenderer {

    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val path = Path()

    fun draw(canvas: Canvas, rock: Rock) {
        // Gray polygon body
        paint.style = Paint.Style.FILL
        paint.color = "#696969".toColorInt()
        path.reset()
        path.moveTo(rock.x, rock.y + rock.height)
        path.lineTo(rock.x + 5f, rock.y + 5f)
        path.lineTo(rock.x + 15f, rock.y)
        path.lineTo(rock.x + 25f, rock.y + 3f)
        path.lineTo(rock.x + rock.width, rock.y + rock.height)
        path.close()
        canvas.drawPath(path, paint)

        // Highlight
        paint.color = "#A9A9A9".toColorInt()
        path.reset()
        path.moveTo(rock.x + 10f, rock.y + 5f)
        path.lineTo(rock.x + 15f, rock.y + 1f)
        path.lineTo(rock.x + 22f, rock.y + 5f)
        path.close()
        canvas.drawPath(path, paint)
    }
}
