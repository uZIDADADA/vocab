package io.github.uzidadada.vocab

import android.Manifest
import android.os.Build
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var permissionResult: MethodChannel.Result? = null

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 43) {
            permissionResult?.success(null)
            permissionResult = null
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ReminderReceiver.schedule(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "vocab/reminders").setMethodCallHandler { call, result ->
            try {
                val prefs = ReminderReceiver.prefs(this)
                when (call.method) {
                    "load" -> result.success(mapOf("enabled" to prefs.getBoolean("enabled", false), "hour" to prefs.getInt("hour", 20), "minute" to prefs.getInt("minute", 0), "allowed" to ReminderReceiver.allowed(this)))
                    "save" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        val hour = call.argument<Int>("hour") ?: 20
                        val minute = call.argument<Int>("minute") ?: 0
                        require(hour in 0..23 && minute in 0..59)
                        check(prefs.edit().putBoolean("enabled", enabled).putInt("hour", hour).putInt("minute", minute).commit())
                        ReminderReceiver.channel(this)
                        ReminderReceiver.schedule(this)
                        if (enabled && Build.VERSION.SDK_INT >= 33 && !ReminderReceiver.allowed(this)) {
                            permissionResult = result
                            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 43)
                        } else result.success(null)
                    }
                    "test" -> { ReminderReceiver.notify(this); result.success(null) }
                    "settings" -> {
                        startActivity(Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, packageName))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (error: Exception) { result.error("REMINDER_FAILED", "提醒操作失败", null) }
        }
    }
}
