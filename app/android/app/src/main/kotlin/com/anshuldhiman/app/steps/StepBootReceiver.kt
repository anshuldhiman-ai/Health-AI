package com.anshuldhiman.app.steps

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Resumes 100% offline step tracking after device boot or package update.
 */
class StepBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return
        val action = intent.action
        if (action == Intent.ACTION_BOOT_COMPLETED || action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            StepForegroundService.start(context)
            StepBackgroundScheduler.schedule(context)
        }
    }
}
