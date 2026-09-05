package io.github.uzidadada.vocab

import android.app.*
import android.content.*
import android.os.Build
import java.util.Calendar

class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (!prefs(context).getBoolean("enabled", false)) return
        if (intent.action == "vocab.DAILY_REMINDER") notify(context)
        schedule(context)
    }
    companion object {
        private const val CHANNEL = "learning_reminders"
        fun prefs(context: Context) = context.getSharedPreferences("learning_reminders", Context.MODE_PRIVATE)
        fun manager(context: Context) = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        fun channel(context: Context) {
            if (Build.VERSION.SDK_INT >= 26) manager(context).createNotificationChannel(NotificationChannel(CHANNEL, "学习提醒", NotificationManager.IMPORTANCE_DEFAULT))
        }
        fun allowed(context: Context): Boolean {
            channel(context)
            return manager(context).areNotificationsEnabled() && (Build.VERSION.SDK_INT < 26 || manager(context).getNotificationChannel(CHANNEL).importance != NotificationManager.IMPORTANCE_NONE)
        }
        fun schedule(context: Context) {
            val pending = PendingIntent.getBroadcast(context, 41, Intent(context, ReminderReceiver::class.java).setAction("vocab.DAILY_REMINDER"), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarm.cancel(pending)
            val prefs = prefs(context)
            if (!prefs.getBoolean("enabled", false)) { manager(context).cancel(42); return }
            val next = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, prefs.getInt("hour", 20)); set(Calendar.MINUTE, prefs.getInt("minute", 0)); set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
                if (timeInMillis <= System.currentTimeMillis()) add(Calendar.DAY_OF_YEAR, 1)
            }
            alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next.timeInMillis, pending)
        }
        fun notify(context: Context) {
            if (!allowed(context)) return
            val open = PendingIntent.getActivity(context, 42, Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, CHANNEL) else Notification.Builder(context)
            val notification = builder.setSmallIcon(R.drawable.ic_reminder).setContentTitle("该复习啦")
                .setContentText("打开 Vocab，巩固今天的词汇与表达。")
                .setContentIntent(open).setAutoCancel(true).build()
            try { manager(context).notify(42, notification) } catch (_: SecurityException) { }
        }
    }
}
