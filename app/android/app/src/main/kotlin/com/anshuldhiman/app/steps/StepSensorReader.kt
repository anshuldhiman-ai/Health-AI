package com.anshuldhiman.app.steps

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Handler
import android.os.Looper
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger

/**
 * Reads the cumulative hardware step counter once.
 *
 * `TYPE_STEP_COUNTER` is an on-change sensor: it reports the count since
 * boot and (on compliant devices) delivers the current value as soon as
 * a listener registers. The latch plus timeout covers devices that only
 * deliver on the next step — in that case there was no new movement in
 * the window, so returning null loses nothing.
 */
object StepSensorReader {

    fun read(context: Context, timeoutMs: Long = 4000L): Int? {
        val manager = context.getSystemService(Context.SENSOR_SERVICE)
            as? SensorManager ?: return null
        val sensor = manager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
            ?: return null

        val latch = CountDownLatch(1)
        val value = AtomicInteger(-1)
        val handler = Handler(Looper.getMainLooper())
        val listener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                if (event.values.isNotEmpty()) {
                    value.set(event.values[0].toInt())
                }
                latch.countDown()
            }

            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit
        }

        return try {
            manager.registerListener(
                listener,
                sensor,
                SensorManager.SENSOR_DELAY_NORMAL,
                handler,
            )
            latch.await(timeoutMs, TimeUnit.MILLISECONDS)
            value.get().takeIf { it >= 0 }
        } catch (_: Exception) {
            null
        } finally {
            runCatching { manager.unregisterListener(listener) }
        }
    }
}