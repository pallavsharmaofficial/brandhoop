package `in`.hooplock.agent.core

import android.content.Context
import android.content.SharedPreferences
import android.os.Build

/**
 * Stored in device-protected storage so the lock is re-applied right after a reboot, before the
 * customer unlocks the screen (direct boot).
 */
class Prefs(context: Context) {
    private val p: SharedPreferences = run {
        val ctx = if (Build.VERSION.SDK_INT >= 24) context.createDeviceProtectedStorageContext() else context
        ctx.getSharedPreferences("hooplock", Context.MODE_PRIVATE)
    }

    var server: String by str("server")
    var enrollToken: String by str("enroll_token")
    var deviceId: String by str("device_id")
    var apiToken: String by str("api_token")
    var commandKey: String by str("command_key")
    var statePayload: String by str("state_payload")
    var stateSig: String by str("state_sig")
    var fcmConfig: String by str("fcm_config")
    var lastSims: String by str("last_sims")
    var lastSeq: Int
        get() = p.getInt("last_seq", 0)
        set(v) = p.edit().putInt("last_seq", v).apply()
    var lastContactAt: Long
        get() = p.getLong("last_contact", 0)
        set(v) = p.edit().putLong("last_contact", v).apply()
    var consentGiven: Boolean
        get() = p.getBoolean("consent", false)
        set(v) = p.edit().putBoolean("consent", v).apply()
    var lastWarningShownAt: Long
        get() = p.getLong("warn_shown", 0)
        set(v) = p.edit().putLong("warn_shown", v).apply()
    var pendingEvents: String by str("pending_events")
    var pendingSuspended: String by str("suspended_pkgs")
    var releasedDone: Boolean
        get() = p.getBoolean("released_done", false)
        set(v) = p.edit().putBoolean("released_done", v).commit().let { }

    val enrolled get() = deviceId.isNotEmpty() && apiToken.isNotEmpty() && commandKey.isNotEmpty()

    /** The last verified state, or null. Re-verified every time it is read. */
    fun state(): AgentState? {
        if (statePayload.isEmpty() || commandKey.isEmpty()) return null
        if (!Crypto.verifyState(commandKey, statePayload, stateSig)) return null
        return runCatching { AgentState.parse(statePayload) }.getOrNull()
    }

    fun saveState(payload: String, sig: String) {
        p.edit().putString("state_payload", payload).putString("state_sig", sig).commit()
    }

    private fun str(key: String) = object : kotlin.properties.ReadWriteProperty<Any, String> {
        override fun getValue(thisRef: Any, property: kotlin.reflect.KProperty<*>) = p.getString(key, "") ?: ""
        override fun setValue(thisRef: Any, property: kotlin.reflect.KProperty<*>, value: String) {
            p.edit().putString(key, value).commit()
        }
    }
}
