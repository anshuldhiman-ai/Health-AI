package com.anshuldhiman.app.steps

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import androidx.core.app.NotificationCompat
import com.anshuldhiman.app.MainActivity
import java.util.Calendar

/**
 * 100% Offline 24/7 Step Tracking Foreground Service.
 *
 * Keeps an on-device hardware step sensor listener active even when the app
 * is closed or swiped from recents. Uses hardware batching (60s latency) so
 * the main CPU sleeps while the sensor DSP counts movement at near-zero battery.
 *
 * Accurately tracks daily and hourly step boundaries so day transitions (midnight)
 * never mix steps across days.
 */
class StepForegroundService : Service(), SensorEventListener {

    private var sensorManager: SensorManager? = null
    private var stepSensor: Sensor? = null
    private lateinit var store: StepSnapshotStore
    private val mainHandler = Handler(Looper.getMainLooper())
    private var lastRecordedDay = -1
    private var lastRecordedHour = -1
    private var lastSensorSteps = -1

    private val periodicChecker = object : Runnable {
        override fun run() {
            checkDateAndHourRollover()
            mainHandler.postDelayed(this, 60_000L) // Check every minute
        }
    }

    override fun onCreate() {
        super.onCreate()
        store = StepSnapshotStore(applicationContext)
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as? SensorManager
        stepSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)

        val cal = Calendar.getInstance()
        lastRecordedDay = cal.get(Calendar.DAY_OF_YEAR)
        lastRecordedHour = cal.get(Calendar.HOUR_OF_DAY)

        createNotificationChannel()
        startForegroundServiceWithNotification(todaySteps = 0)
        registerSensorListener()

        mainHandler.post(periodicChecker)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    private fun registerSensorListener() {
        val sensor = stepSensor ?: return
        val manager = sensorManager ?: return
        try {
            // 60,000,000 microseconds = 60s hardware batching.
            manager.registerListener(
                this,
                sensor,
                SensorManager.SENSOR_DELAY_NORMAL,
                60_000_000,
            )
        } catch (_: Exception) {
            manager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_NORMAL)
        }
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null || event.values.isEmpty()) return
        val steps = event.values[0].toInt()
        if (steps <= 0) return

        lastSensorSteps = steps
        val nowMillis = System.currentTimeMillis()
        val elapsed = SystemClock.elapsedRealtime()

        store.append(
            atMillis = nowMillis,
            steps = steps,
            elapsedMillis = elapsed,
        )
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit

    private fun checkDateAndHourRollover() {
        val cal = Calendar.getInstance()
        val currentDay = cal.get(Calendar.DAY_OF_YEAR)
        val currentHour = cal.get(Calendar.HOUR_OF_DAY)

        val stepsToRecord = if (lastSensorSteps > 0) {
            lastSensorSteps
        } else {
            StepSensorReader.read(applicationContext) ?: -1
        }

        if (stepsToRecord > 0 && (currentDay != lastRecordedDay || currentHour != lastRecordedHour)) {
            // Record an exact anchor sample at the turn of the hour or day
            val nowMillis = System.currentTimeMillis()
            val elapsed = SystemClock.elapsedRealtime()
            store.append(
                atMillis = nowMillis,
                steps = stepsToRecord,
                elapsedMillis = elapsed,
            )
            lastSensorSteps = stepsToRecord
            lastRecordedDay = currentDay
            lastRecordedHour = currentHour
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Health AI Step Counter",
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Runs 100% offline on-device step counting"
                setShowBadge(false)
                enableLights(false)
                enableVibration(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun startForegroundServiceWithNotification(todaySteps: Int) {
        val openIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            openIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Health AI • Step Tracker")
            .setContentText("Tracking steps 100% offline")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(pendingIntent)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH,
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        mainHandler.removeCallbacks(periodicChecker)
        try {
            sensorManager?.unregisterListener(this)
        } catch (_: Exception) {}
    }

    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        const val CHANNEL_ID = "health_ai_steps_channel"
        const val NOTIFICATION_ID = 40401

        fun start(context: Context) {
            val intent = Intent(context, StepForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                try {
                    context.startForegroundService(intent)
                } catch (_: Exception) {
                    context.startService(intent)
                }
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, StepForegroundService::class.java)
            context.stopService(intent)
        }
    }
}
