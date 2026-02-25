package com.strawberrytiger.game

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.media.MediaPlayer
import kotlin.math.PI
import kotlin.math.sin

class SoundManager(private val context: Context) {

    private var mediaPlayer: MediaPlayer? = null
    private val sampleRate = 44100

    // Pre-created AudioTrack instances (one per sound type, reusable)
    private var jumpTrack: AudioTrack? = null
    private var scoreTrack: AudioTrack? = null
    private var goldenTrack: AudioTrack? = null
    private var gameOverTrack: AudioTrack? = null

    init {
        val jumpBuffer = generateJumpSound()
        val scoreBuffer = generateScoreSound()
        val goldenBuffer = generateGoldenSound()
        val gameOverBuffer = generateGameOverSound()

        jumpTrack = createStaticTrack(jumpBuffer)
        scoreTrack = createStaticTrack(scoreBuffer)
        goldenTrack = createStaticTrack(goldenBuffer)
        gameOverTrack = createStaticTrack(gameOverBuffer)
    }

    private fun createStaticTrack(buffer: ShortArray): AudioTrack? {
        return try {
            val track = AudioTrack(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_GAME)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
                AudioFormat.Builder()
                    .setSampleRate(sampleRate)
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                    .build(),
                buffer.size * 2,
                AudioTrack.MODE_STATIC,
                AudioManager.AUDIO_SESSION_ID_GENERATE
            )
            track.write(buffer, 0, buffer.size)
            track
        } catch (e: Exception) {
            null
        }
    }

    private fun replayTrack(track: AudioTrack?) {
        track ?: return
        try {
            if (track.playState == AudioTrack.PLAYSTATE_PLAYING ||
                track.playState == AudioTrack.PLAYSTATE_PAUSED) {
                track.stop()
            }
            track.reloadStaticData()
            track.play()
        } catch (e: Exception) {
            // Fallback: try just playing
            try {
                track.play()
            } catch (_: Exception) {}
        }
    }

    // Triangle wave: value oscillates linearly between -1 and 1
    private fun triangleWave(phase: Double): Double {
        val p = phase % (2.0 * PI)
        val normalized = p / (2.0 * PI) // 0..1
        return if (normalized < 0.25) {
            normalized * 4.0
        } else if (normalized < 0.75) {
            2.0 - normalized * 4.0
        } else {
            normalized * 4.0 - 4.0
        }
    }

    // Square wave: +1 or -1
    private fun squareWave(phase: Double): Double {
        val p = phase % (2.0 * PI)
        return if (p < PI) 1.0 else -1.0
    }

    private fun generateJumpSound(): ShortArray {
        // Triangle wave 300->600Hz sweep over 0.15s, amplitude 0.15->0.01 over 0.2s
        val duration = 0.2
        val numSamples = (sampleRate * duration).toInt()
        val buffer = ShortArray(numSamples)
        var phase = 0.0
        for (i in 0 until numSamples) {
            val t = i.toDouble() / sampleRate
            val freq = if (t < 0.15) {
                300.0 * Math.pow(600.0 / 300.0, t / 0.15)
            } else {
                600.0
            }
            val amp = 0.15 * Math.pow(0.01 / 0.15, t / 0.2)
            phase += 2.0 * PI * freq / sampleRate
            val sample = triangleWave(phase) * amp
            buffer[i] = (sample * Short.MAX_VALUE).toInt().coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt()).toShort()
        }
        return buffer
    }

    private fun generateScoreSound(): ShortArray {
        // Sine 523Hz then 659Hz at 0.08s, amplitude 0.12->0.01 over 0.2s
        val duration = 0.2
        val numSamples = (sampleRate * duration).toInt()
        val buffer = ShortArray(numSamples)
        var phase = 0.0
        for (i in 0 until numSamples) {
            val t = i.toDouble() / sampleRate
            val freq = if (t < 0.08) 523.0 else 659.0
            val amp = 0.12 * Math.pow(0.01 / 0.12, t / 0.2)
            phase += 2.0 * PI * freq / sampleRate
            val sample = sin(phase) * amp
            buffer[i] = (sample * Short.MAX_VALUE).toInt().coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt()).toShort()
        }
        return buffer
    }

    private fun generateGoldenSound(): ShortArray {
        // 3 ascending sine notes (523, 659, 784Hz), spaced 0.08s apart, each 0.15s
        val totalDuration = 0.08 * 2 + 0.15
        val numSamples = (sampleRate * totalDuration).toInt()
        val buffer = ShortArray(numSamples)
        val notes = doubleArrayOf(523.0, 659.0, 784.0)
        val phases = DoubleArray(3)

        for (i in 0 until numSamples) {
            val t = i.toDouble() / sampleRate
            var sample = 0.0
            for (n in notes.indices) {
                val noteStart = n * 0.08
                val noteEnd = noteStart + 0.15
                if (t >= noteStart && t < noteEnd) {
                    val nt = t - noteStart
                    phases[n] += 2.0 * PI * notes[n] / sampleRate
                    val amp = if (nt < 0.02) {
                        0.15 * (nt / 0.02)
                    } else {
                        0.15 * Math.pow(0.01 / 0.15, (nt - 0.02) / (0.15 - 0.02))
                    }
                    sample += sin(phases[n]) * amp
                }
            }
            buffer[i] = (sample * Short.MAX_VALUE).toInt().coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt()).toShort()
        }
        return buffer
    }

    private fun generateGameOverSound(): ShortArray {
        // 3 descending square waves (400, 300, 200Hz), spaced 0.15s apart, each 0.25s
        val totalDuration = 0.15 * 2 + 0.25
        val numSamples = (sampleRate * totalDuration).toInt()
        val buffer = ShortArray(numSamples)
        val notes = doubleArrayOf(400.0, 300.0, 200.0)
        val phases = DoubleArray(3)

        for (i in 0 until numSamples) {
            val t = i.toDouble() / sampleRate
            var sample = 0.0
            for (n in notes.indices) {
                val noteStart = n * 0.15
                val noteEnd = noteStart + 0.25
                if (t >= noteStart && t < noteEnd) {
                    val nt = t - noteStart
                    phases[n] += 2.0 * PI * notes[n] / sampleRate
                    val amp = if (nt < 0.02) {
                        0.1 * (nt / 0.02)
                    } else {
                        0.1 * Math.pow(0.01 / 0.1, (nt - 0.02) / (0.25 - 0.02))
                    }
                    sample += squareWave(phases[n]) * amp
                }
            }
            buffer[i] = (sample * Short.MAX_VALUE).toInt().coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt()).toShort()
        }
        return buffer
    }

    fun playJumpSound() {
        replayTrack(jumpTrack)
    }

    fun playScoreSound() {
        replayTrack(scoreTrack)
    }

    fun playGoldenSound() {
        replayTrack(goldenTrack)
    }

    fun playGameOverSound() {
        replayTrack(gameOverTrack)
    }

    fun startBGM() {
        try {
            if (mediaPlayer == null) {
                mediaPlayer = MediaPlayer.create(context, R.raw.pixel_pulse_panic)
                mediaPlayer?.isLooping = true
                mediaPlayer?.setVolume(0.4f, 0.4f)
            }
            mediaPlayer?.seekTo(0)
            mediaPlayer?.start()
        } catch (e: Exception) {
            // Ignore
        }
    }

    fun stopBGM() {
        try {
            mediaPlayer?.pause()
            mediaPlayer?.seekTo(0)
        } catch (e: Exception) {
            // Ignore
        }
    }

    fun release() {
        try {
            mediaPlayer?.stop()
            mediaPlayer?.release()
            mediaPlayer = null
        } catch (e: Exception) {
            // Ignore
        }
        for (track in listOf(jumpTrack, scoreTrack, goldenTrack, gameOverTrack)) {
            try {
                track?.release()
            } catch (e: Exception) {
                // Ignore
            }
        }
        jumpTrack = null
        scoreTrack = null
        goldenTrack = null
        gameOverTrack = null
    }
}
