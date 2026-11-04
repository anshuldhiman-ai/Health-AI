package com.anshuldhiman.app.steps

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.SystemClock
import androidx.core.content.ContextCompat
import androidx.work.Worker
import androidx.work.WorkerParameters

/**
 * Periodic background sample of the cumulative step counter.
 *
 * WorkManager persists this across app kills and reboots. It is a
 * best-effort 15-minute cadence: Doze and OEM battery managers may defer
 * it, and a user "Force stop" suspends all background work until the app
 * is launched again. Every run stores a timestamped reading, so the Dart
 * ledger can attribute the delta to the hours it actually spans.
 */
class StepCaptureWorker(
    appContext: Context,
    params: WorkerParameters,
) : Worker(appContext, params) {

    override fun doWork(): Result {
        val context = applicationContext

        // Since Android 10, reading the step counter requires the runtime
        // activity-recognition permission. Without it the job is a no-op
        // rather than a failure: the user can grant it later.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val granted = ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.ACTIVITY_RECOGNITION,
            ) == PackageManager.PERMISSION_GRANTED
            if (!granted) return Result.success()
        }

        val steps = StepSensorReader.read(context) ?: return Result.success()
        StepSnapshotStore(context).append(
            atMillis = System.currentTimeMillis(),
            steps = steps,
            elapsedMillis = SystemClock.elapsedRealtime(),
        )
        return Result.success()
    }
}