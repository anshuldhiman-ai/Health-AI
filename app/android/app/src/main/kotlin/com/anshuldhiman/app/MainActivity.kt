package com.anshuldhiman.app

import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import com.anshuldhiman.app.steps.StepBackgroundScheduler
import com.anshuldhiman.app.steps.StepForegroundService
import com.anshuldhiman.app.steps.StepSensorReader
import com.anshuldhiman.app.steps.StepSnapshotStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {

    private val ioExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "schedule" -> {
                    try {
                        StepForegroundService.start(applicationContext)
                        StepBackgroundScheduler.schedule(applicationContext)
                        result.success(true)
                    } catch (error: Exception) {
                        result.error("schedule_failed", error.message, null)
                    }
                }

                "startService" -> {
                    try {
                        StepForegroundService.start(applicationContext)
                        result.success(true)
                    } catch (error: Exception) {
                        result.error("service_start_failed", error.message, null)
                    }
                }

                // Readings are never cleared here: the Dart ledger keeps a
                // cursor and ignores duplicates, which also survives the
                // process being killed between drain and save.
                "drain" -> result.success(
                    StepSnapshotStore(applicationContext).readAllAsMaps(),
                )

                "collectNow" -> ioExecutor.execute {
                    val steps = StepSensorReader.read(applicationContext)
                    if (steps != null) {
                        StepSnapshotStore(applicationContext).append(
                            atMillis = System.currentTimeMillis(),
                            steps = steps,
                            elapsedMillis = SystemClock.elapsedRealtime(),
                        )
                    }
                    val payload =
                        StepSnapshotStore(applicationContext).readAllAsMaps()
                    mainHandler.post { result.success(payload) }
                }

                else -> result.notImplemented()
            }
        }
    }

    private companion object {
        const val CHANNEL = "health_ai/steps_background"
    }
}
