package `in`.hooplock.agent.sync

import android.content.Context
import android.util.Log
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.OutOfQuotaPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import com.google.android.gms.tasks.Tasks
import com.google.firebase.FirebaseApp
import com.google.firebase.FirebaseOptions
import com.google.firebase.messaging.FirebaseMessaging
import `in`.hooplock.agent.core.Api
import `in`.hooplock.agent.core.ApiException
import `in`.hooplock.agent.core.DeviceInfo
import `in`.hooplock.agent.core.Enforcer
import `in`.hooplock.agent.core.Locator
import `in`.hooplock.agent.core.Prefs
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.TimeUnit

/** Talks to the server: enrollment, heartbeat, location. Blocking; call from a worker thread. */
object Syncer {
    private const val TAG = "HoopLock"

    fun enroll(ctx: Context) {
        val prefs = Prefs(ctx)
        val body = DeviceInfo.collect(ctx).put("token", prefs.enrollToken)
        val r = Api(prefs).enroll(body)
        prefs.deviceId = r.getString("deviceId")
        prefs.apiToken = r.getString("apiToken")
        prefs.commandKey = r.getString("commandKey")
        prefs.fcmConfig = r.optJSONObject("fcm")?.toString() ?: ""
        prefs.lastSims = DeviceInfo.simFingerprint(body.getJSONArray("sims"))
        prefs.enrollToken = ""
        prefs.lastContactAt = System.currentTimeMillis()
        val st = r.getJSONObject("state")
        Enforcer.accept(ctx, st.getString("payload"), st.getString("sig"))
    }

    fun sync(ctx: Context, reason: String) {
        val prefs = Prefs(ctx)
        if (prefs.releasedDone) return
        if (!prefs.enrolled) {
            if (prefs.enrollToken.isEmpty()) return
            enroll(ctx)
        }
        Enforcer.enforce(ctx) // keep enforcing offline (no-contact rule) even if the network call fails
        val api = Api(prefs)
        val info = DeviceInfo.collect(ctx)
        val events = JSONArray(prefs.pendingEvents.ifEmpty { "[]" })
        val fp = DeviceInfo.simFingerprint(info.getJSONArray("sims"))
        val simChanged = prefs.lastSims.isNotEmpty() && fp != prefs.lastSims
        if (simChanged) {
            events.put(JSONObject().put("type", "sim_changed").put("data", JSONObject().put("sims", info.getJSONArray("sims"))).put("at", now()))
        }
        val state = prefs.state()
        val body = info
            .put("appliedSeq", prefs.lastSeq)
            .put("appliedState", state?.effectiveLevel(now())?.wire ?: "unlocked")
            .put("battery", DeviceInfo.battery(ctx).coerceIn(0, 100))
            .put("events", events)
        fcmToken(ctx)?.let { body.put("fcmToken", it) }
        var sentLocation = false
        if (state?.wantLocation == true || simChanged) {
            Locator.current(ctx)?.let {
                body.put("location", JSONObject().put("lat", it.latitude).put("lng", it.longitude)
                    .put("accuracy", it.accuracy.toDouble()).put("reason", if (simChanged) "sim_changed" else reason))
                sentLocation = true
            }
        }
        val r = try { api.sync(body) } catch (e: ApiException) {
            Log.w(TAG, "sync refused: ${e.status} ${e.message}"); return
        }
        prefs.lastContactAt = System.currentTimeMillis()
        prefs.pendingEvents = ""
        prefs.lastSims = fp
        val st = r.getJSONObject("state")
        Enforcer.accept(ctx, st.getString("payload"), st.getString("sig"))
        val notices = r.optJSONArray("notices") ?: JSONArray()
        for (i in 0 until notices.length()) {
            val n = notices.getJSONObject(i)
            Enforcer.notice(ctx, n.optInt("id"), n.optString("message"))
        }
        // The shop asked for the location in this very sync: answer straight away.
        if (!sentLocation && prefs.state()?.wantLocation == true) {
            Locator.current(ctx)?.let { runCatching { api.location(it.latitude, it.longitude, it.accuracy, "requested") } }
        }
    }

    /** Queue an event for the next sync (works offline). */
    fun addEvent(ctx: Context, type: String, data: JSONObject = JSONObject()) {
        val prefs = Prefs(ctx)
        val arr = JSONArray(prefs.pendingEvents.ifEmpty { "[]" })
        if (arr.length() < 50) arr.put(JSONObject().put("type", type).put("data", data).put("at", now()))
        prefs.pendingEvents = arr.toString()
    }

    private fun fcmToken(ctx: Context): String? {
        val cfg = Prefs(ctx).fcmConfig
        if (cfg.isEmpty()) return null
        return runCatching {
            if (FirebaseApp.getApps(ctx).isEmpty()) {
                val j = JSONObject(cfg)
                FirebaseApp.initializeApp(
                    ctx,
                    FirebaseOptions.Builder()
                        .setProjectId(j.getString("projectId"))
                        .setApplicationId(j.getString("appId"))
                        .setApiKey(j.getString("apiKey"))
                        .setGcmSenderId(j.getString("senderId"))
                        .build(),
                )
            }
            Tasks.await(FirebaseMessaging.getInstance().token, 20, TimeUnit.SECONDS)
        }.onFailure { Log.w(TAG, "push setup failed: ${it.message}") }.getOrNull()
    }

    private fun now() = System.currentTimeMillis() / 1000

    // ---- scheduling ----
    fun schedule(ctx: Context) {
        val wm = WorkManager.getInstance(ctx)
        wm.enqueueUniquePeriodicWork(
            "sync", ExistingPeriodicWorkPolicy.KEEP,
            PeriodicWorkRequestBuilder<SyncWorker>(15, TimeUnit.MINUTES).build(),
        )
    }

    fun syncNow(ctx: Context, reason: String = "now") {
        WorkManager.getInstance(ctx).enqueueUniqueWork(
            "sync-now", ExistingWorkPolicy.REPLACE,
            OneTimeWorkRequestBuilder<SyncWorker>()
                .setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
                .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
                .setInputData(androidx.work.workDataOf("reason" to reason))
                .build(),
        )
    }
}

class SyncWorker(ctx: Context, params: WorkerParameters) : Worker(ctx, params) {
    override fun doWork(): Result = try {
        Syncer.sync(applicationContext, inputData.getString("reason") ?: "periodic")
        Result.success()
    } catch (t: Throwable) {
        Log.w("HoopLock", "sync failed: ${t.message}")
        Result.retry()
    }
}
