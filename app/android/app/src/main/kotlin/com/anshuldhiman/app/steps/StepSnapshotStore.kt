package com.anshuldhiman.app.steps

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * One cumulative step-counter reading.
 *
 * [steps] is the hardware counter (steps since boot). [elapsedMillis] is
 * `SystemClock.elapsedRealtime()` at capture time: it moves backwards
 * only across a reboot, which the Dart ledger uses to re-anchor instead
 * of subtracting a negative delta.
 */
data class StepSample(
    val atMillis: Long,
    val steps: Int,
    val elapsedMillis: Long,
)

/**
 * App-private ring buffer of background step readings.
 *
 * Kept in SharedPreferences rather than the encrypted user database
 * because the worker runs without the Flutter engine and must not block
 * on key-store access. The values are step counts and timestamps only;
 * they are consumed and folded into the encrypted ledger on next launch.
 * Entries older than [RETENTION_MS] are dropped so the file cannot grow
 * without bound.
 */
class StepSnapshotStore(context: Context) {

    private val prefs = context.applicationContext
        .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun append(atMillis: Long, steps: Int, elapsedMillis: Long) {
        val existing = readAll()
        val cutoff = atMillis - RETENTION_MS
        val kept = existing.filter { it.atMillis >= cutoff }
        val merged = kept + StepSample(atMillis, steps, elapsedMillis)
        writeAll(merged.takeLast(MAX_SAMPLES))
    }

    fun readAll(): List<StepSample> {
        val raw = prefs.getString(KEY_SAMPLES, null) ?: return emptyList()
        return try {
            val array = JSONArray(raw)
            buildList {
                for (i in 0 until array.length()) {
                    val item = array.optJSONObject(i) ?: continue
                    add(
                        StepSample(
                            atMillis = item.optLong("t", 0L),
                            steps = item.optInt("s", -1),
                            elapsedMillis = item.optLong("e", -1L),
                        )
                    )
                }
            }.filter { it.steps >= 0 && it.atMillis > 0L }
        } catch (_: Exception) {
            emptyList()
        }
    }

    /** JSON-friendly form for the platform channel. */
    fun readAllAsMaps(): List<Map<String, Any>> = readAll().map {
        mapOf("t" to it.atMillis, "s" to it.steps, "e" to it.elapsedMillis)
    }

    private fun writeAll(samples: List<StepSample>) {
        val array = JSONArray()
        for (sample in samples) {
            array.put(
                JSONObject()
                    .put("t", sample.atMillis)
                    .put("s", sample.steps)
                    .put("e", sample.elapsedMillis)
            )
        }
        // commit() rather than apply(): the worker may be stopped as soon
        // as doWork() returns, and a deferred write can be lost there.
        prefs.edit().putString(KEY_SAMPLES, array.toString()).commit()
    }

    companion object {
        private const val PREFS_NAME = "health_ai_step_samples"
        private const val KEY_SAMPLES = "samples.v1"
        private const val RETENTION_MS = 8L * 24 * 60 * 60 * 1000
        private const val MAX_SAMPLES = 1200
    }
}