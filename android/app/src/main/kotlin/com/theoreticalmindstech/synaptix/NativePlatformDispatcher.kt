package com.theoreticalmindstech.synaptix

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import android.view.HapticFeedbackConstants
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NativePlatformDispatcher(
    private val activity: FlutterActivity
) : MethodChannel.MethodCallHandler {
    private val dialogHandler = NativeDialogHandler(activity)
    private val secretStore = AndroidSecureSecretStore(activity)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "showInputDialog" -> dialogHandler.showInputDialog(call, result)
                "secureSet" -> handleSecureSet(call, result)
                "secureGet" -> handleSecureGet(call, result)
                "secureDelete" -> handleSecureDelete(call, result)
                "secureClear" -> {
                    secretStore.clear()
                    result.success(true)
                }
                "getDeviceIntegrity" -> result.success(buildDeviceIntegrityPayload())
                "performHaptic" -> result.success(performHaptic(call.argument("pattern")))
                "openAndroidNotificationSettings" -> result.success(openNotificationSettings())
                else -> result.notImplemented()
            }
        } catch (e: IllegalArgumentException) {
            result.error("INVALID_ARGUMENT", e.message, null)
        } catch (e: Exception) {
            result.error("NATIVE_FAILURE", e.message, null)
        }
    }

    private fun handleSecureSet(call: MethodCall, result: MethodChannel.Result) {
        val key = call.argument<String>("key") ?: throw IllegalArgumentException("Missing key.")
        val value = call.argument<String>("value") ?: throw IllegalArgumentException("Missing value.")
        secretStore.set(key, value)
        result.success(true)
    }

    private fun handleSecureGet(call: MethodCall, result: MethodChannel.Result) {
        val key = call.argument<String>("key") ?: throw IllegalArgumentException("Missing key.")
        result.success(secretStore.get(key))
    }

    private fun handleSecureDelete(call: MethodCall, result: MethodChannel.Result) {
        val key = call.argument<String>("key") ?: throw IllegalArgumentException("Missing key.")
        secretStore.delete(key)
        result.success(true)
    }

    private fun buildDeviceIntegrityPayload(): Map<String, Any?> {
        val packageManager = activity.packageManager
        val packageName = activity.packageName
        val packageInfo = packageManager.getPackageInfo(packageName, 0)

        val installerPackageName = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            packageManager.getInstallSourceInfo(packageName).installingPackageName
        } else {
            @Suppress("DEPRECATION")
            packageManager.getInstallerPackageName(packageName)
        }

        val appVersionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            packageInfo.longVersionCode.toInt()
        } else {
            @Suppress("DEPRECATION")
            packageInfo.versionCode
        }

        return mapOf(
            "platform" to "android",
            "packageName" to packageName,
            "installerPackageName" to installerPackageName,
            "isDebuggable" to ((activity.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0),
            "isEmulator" to isLikelyEmulator(),
            "sdkInt" to Build.VERSION.SDK_INT,
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL,
            "fingerprint" to Build.FINGERPRINT,
            "appVersionName" to packageInfo.versionName,
            "appVersionCode" to appVersionCode
        )
    }

    private fun performHaptic(pattern: String?): Boolean {
        val view = activity.window?.decorView
        val fallbackConstant = when (pattern) {
            "selection" -> HapticFeedbackConstants.CLOCK_TICK
            "heavy", "error" -> HapticFeedbackConstants.LONG_PRESS
            else -> HapticFeedbackConstants.KEYBOARD_TAP
        }

        val duration = when (pattern) {
            "selection" -> 15L
            "light" -> 20L
            "medium", "success", "warning" -> 35L
            "heavy", "error" -> 60L
            else -> 25L
        }

        val amplitude = when (pattern) {
            "selection" -> 40
            "light" -> 60
            "medium", "success", "warning" -> 120
            "heavy", "error" -> 200
            else -> VibrationEffect.DEFAULT_AMPLITUDE
        }

        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val vibrator = getVibrator()
                vibrator.vibrate(VibrationEffect.createOneShot(duration, amplitude))
                true
            } else {
                @Suppress("DEPRECATION")
                getVibrator().vibrate(duration)
                true
            }
        } catch (_: Exception) {
            view?.performHapticFeedback(fallbackConstant) ?: false
        }
    }

    private fun getVibrator(): Vibrator {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = activity.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            manager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            activity.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
    }

    private fun openNotificationSettings(): Boolean {
        return try {
            val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, activity.packageName)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            activity.startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun isLikelyEmulator(): Boolean {
        return Build.FINGERPRINT.startsWith("generic") ||
            Build.FINGERPRINT.startsWith("unknown") ||
            Build.MODEL.contains("google_sdk", ignoreCase = true) ||
            Build.MODEL.contains("Emulator", ignoreCase = true) ||
            Build.MODEL.contains("Android SDK built for x86", ignoreCase = true) ||
            Build.MANUFACTURER.contains("Genymotion", ignoreCase = true) ||
            Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic") ||
            Build.PRODUCT == "google_sdk"
    }
}
