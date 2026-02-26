package com.strawberrytiger.game

import android.content.Context
import android.content.SharedPreferences
import androidx.core.content.edit

class ScoreManager(context: Context) {

    private val prefs: SharedPreferences =
        context.getSharedPreferences("strawberrytiger_prefs", Context.MODE_PRIVATE)

    fun getHighScore(): Int {
        return prefs.getInt("strawberrytiger_best", 0)
    }

    fun saveHighScore(score: Int) {
        val best = getHighScore()
        if (score > best) {
            prefs.edit { putInt("strawberrytiger_best", score) }
        }
    }
}
