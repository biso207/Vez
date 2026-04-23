package com.outly.vez

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.outly.vez/haptics"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "play") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val type = call.argument<String>("type") ?: "tap"
                playHaptic(type)
                result.success(null)
            }
    }

    private fun playHaptic(type: String) {
        val vibrator = getSystemVibrator() ?: return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val effectId = when (type) {
                "selection" -> VibrationEffect.EFFECT_TICK
                "emphasis" -> VibrationEffect.EFFECT_HEAVY_CLICK
                "success" -> VibrationEffect.EFFECT_DOUBLE_CLICK
                else -> VibrationEffect.EFFECT_CLICK
            }
            vibrator.vibrate(VibrationEffect.createPredefined(effectId))
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val effect = when (type) {
                "selection" -> VibrationEffect.createOneShot(18, 120)
                "emphasis" -> VibrationEffect.createOneShot(35, 255)
                "success" -> VibrationEffect.createWaveform(
                    longArrayOf(0, 24, 40, 42),
                    intArrayOf(0, 180, 0, 255),
                    -1
                )
                else -> VibrationEffect.createOneShot(24, 180)
            }
            vibrator.vibrate(effect)
            return
        }

        @Suppress("DEPRECATION")
        vibrator.vibrate(
            when (type) {
                "selection" -> 18L
                "emphasis" -> 35L
                "success" -> 65L
                else -> 24L
            }
        )
    }

    private fun getSystemVibrator(): Vibrator? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
            manager?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }
}
