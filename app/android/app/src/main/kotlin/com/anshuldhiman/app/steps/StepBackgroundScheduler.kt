package com.anshuldhiman.app.steps

import android.content.Context
import androidx.work.BackoffPolicy
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

/**
 * Registers the single background step-capture job.
 *
 * The 15-minute interval is the WorkManager minimum. `KEEP` makes the
 * call idempotent: every launch asks for the same unique work, and an
 * existing registration is left alone (so its schedule is not reset on
 * every cold start).
 */
object StepBackgroundScheduler {

    private const val UNIQUE_NAME = "health_ai_step_capture"

    fun schedule(context: Context) {
        val request = PeriodicWorkRequestBuilder<StepCaptureWorker>(
            15,
            TimeUnit.MINUTES,
        )
            .setBackoffCriteria(
                BackoffPolicy.LINEAR,
                5,
                TimeUnit.MINUTES,
            )
            .build()

        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            UNIQUE_NAME,
            ExistingPeriodicWorkPolicy.KEEP,
            request,
        )
    }
}