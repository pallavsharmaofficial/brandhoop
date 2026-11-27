package `in`.hooplock.agent.core

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.util.Log
import `in`.hooplock.agent.R
import `in`.hooplock.agent.ui.LockActivity
import `in`.hooplock.agent.ui.StatusActivity
import `in`.hooplock.agent.ui.WarningActivity

/** Turns the verified desired state into what the phone actually does. Safe to call any time. */
object Enforcer {
    const val ACTION_STATE_CHANGED = "in.hooplock.agent.STATE_CHANGED"
    private const val CHANNEL = "emi"
    private const val NOTE_RESTRICTED = 10
    private const val WARN_EVERY_MS = 4 * 3600_000L

    /** Accepts a signed state from the server. Returns false if it is forged, for another phone, or older. */
    @Synchronized
    fun accept(ctx: Context, payload: String, sig: String): Boolean {
        val prefs = Prefs(ctx)
        if (!Crypto.verifyState(prefs.commandKey, payload, sig)) { Log.w("HoopLock", "bad state signature"); return false }
        val s = runCatching { AgentState.parse(payload) }.getOrNull() ?: return false
        if (s.deviceId != prefs.deviceId) return false
        if (s.seq < prefs.lastSeq) return false
        prefs.saveState(payload, sig)
        prefs.lastSeq = s.seq
        enforce(ctx)
        return true
    }

    /**
     * Applies an offline SMS command. The SMS only carries the level; the rest (message, dues)
     * stays from the last full state until the phone is online again.
     */
    @Synchronized
    fun acceptSms(ctx: Context, seq: Int, code: Char): Boolean {
        val prefs = Prefs(ctx)
        if (seq <= prefs.lastSeq) return false
        val cur = prefs.state() ?: return false
        val level = when (code) { 'U' -> LockLevel.UNLOCKED; 'W' -> LockLevel.WARNING; 'R' -> LockLevel.RESTRICTED; 'L' -> LockLevel.LOCKED; else -> cur.level }
        val json = org.json.JSONObject(prefs.statePayload)
            .put("s", seq).put("st", level.wire).put("rel", code == 'X')
        // A lifted lock must not snap back because of an old no-contact date.
        if (code == 'U' || code == 'X') json.put("ncl", org.json.JSONObject.NULL)
        val payload = json.toString()
        prefs.saveState(payload, Crypto.b64url(Crypto.hmac(prefs.commandKey, payload)))
        prefs.lastSeq = seq
        enforce(ctx)
        return true
    }

    @Synchronized
    fun enforce(ctx: Context) {
        val prefs = Prefs(ctx)
        val policy = Policy(ctx)
        val state = prefs.state()
        if (state == null) {
            if (prefs.enrolled || prefs.enrollToken.isNotEmpty()) policy.applyBase()
            return
        }
        if (state.released) { Release.run(ctx); return }
        policy.applyBase(state.frpAccounts)
        when (state.effectiveLevel(System.currentTimeMillis() / 1000)) {
            LockLevel.UNLOCKED -> {
                policy.exitLock(); policy.suspendApps(prefs, false); cancelRestrictedNote(ctx)
            }
            LockLevel.WARNING -> {
                policy.exitLock(); policy.suspendApps(prefs, false); cancelRestrictedNote(ctx)
                if (System.currentTimeMillis() - prefs.lastWarningShownAt > WARN_EVERY_MS) {
                    prefs.lastWarningShownAt = System.currentTimeMillis()
                    start(ctx, WarningActivity::class.java)
                }
            }
            LockLevel.RESTRICTED -> {
                policy.exitLock(); policy.suspendApps(prefs, true); showRestrictedNote(ctx)
            }
            LockLevel.LOCKED -> {
                policy.suspendApps(prefs, true); policy.enterLock(); start(ctx, LockActivity::class.java)
            }
        }
        ctx.sendBroadcast(Intent(ACTION_STATE_CHANGED).setPackage(ctx.packageName))
    }

    private fun start(ctx: Context, cls: Class<*>) {
        runCatching { ctx.startActivity(Intent(ctx, cls).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)) }
            .onFailure { Log.w("HoopLock", "could not start ${cls.simpleName}: ${it.message}") }
    }

    fun notice(ctx: Context, id: Int, text: String) {
        ensureChannel(ctx)
        val pi = PendingIntent.getActivity(ctx, 0, Intent(ctx, StatusActivity::class.java), PendingIntent.FLAG_IMMUTABLE)
        val n = Notification.Builder(ctx, CHANNEL)
            .setSmallIcon(R.drawable.ic_lock)
            .setContentTitle(ctx.getString(R.string.app_name))
            .setContentText(text)
            .setStyle(Notification.BigTextStyle().bigText(text))
            .setContentIntent(pi)
            .setAutoCancel(true)
            .build()
        runCatching { ctx.getSystemService(NotificationManager::class.java).notify(1000 + id, n) }
    }

    private fun showRestrictedNote(ctx: Context) {
        ensureChannel(ctx)
        val pi = PendingIntent.getActivity(ctx, 1, Intent(ctx, StatusActivity::class.java), PendingIntent.FLAG_IMMUTABLE)
        val n = Notification.Builder(ctx, CHANNEL)
            .setSmallIcon(R.drawable.ic_lock)
            .setContentTitle(ctx.getString(R.string.warning_title))
            .setContentText(ctx.getString(R.string.restricted_notice))
            .setOngoing(true)
            .setContentIntent(pi)
            .build()
        runCatching { ctx.getSystemService(NotificationManager::class.java).notify(NOTE_RESTRICTED, n) }
    }

    private fun cancelRestrictedNote(ctx: Context) =
        runCatching { ctx.getSystemService(NotificationManager::class.java).cancel(NOTE_RESTRICTED) }

    fun ensureChannel(ctx: Context) {
        val nm = ctx.getSystemService(NotificationManager::class.java)
        if (nm.getNotificationChannel(CHANNEL) == null) {
            nm.createNotificationChannel(NotificationChannel(CHANNEL, ctx.getString(R.string.channel_name), NotificationManager.IMPORTANCE_HIGH))
        }
    }
}

/** Last EMI paid: free the phone. */
object Release {
    fun run(ctx: Context) {
        val prefs = Prefs(ctx)
        if (prefs.releasedDone) return
        val policy = Policy(ctx)
        policy.suspendApps(prefs, false)
        policy.releaseAll()
        prefs.releasedDone = true
        Thread { runCatching { Api(prefs).released() } }.start()
        ctx.startActivity(Intent(ctx, StatusActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK).putExtra(StatusActivity.EXTRA_RELEASED, true))
        ctx.sendBroadcast(Intent(Enforcer.ACTION_STATE_CHANGED).setPackage(ctx.packageName))
    }
}
