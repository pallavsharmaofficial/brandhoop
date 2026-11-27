package `in`.hooplock.agent.admin

import android.app.Activity
import android.app.admin.DeviceAdminReceiver
import android.app.admin.DevicePolicyManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.PersistableBundle
import `in`.hooplock.agent.R
import `in`.hooplock.agent.core.Enforcer
import `in`.hooplock.agent.core.LockLevel
import `in`.hooplock.agent.core.Prefs
import `in`.hooplock.agent.sync.Syncer
import `in`.hooplock.agent.ui.EnrollActivity
import `in`.hooplock.agent.ui.LockActivity

class HoopAdminReceiver : DeviceAdminReceiver() {

    override fun onEnabled(context: Context, intent: Intent) {
        Syncer.schedule(context)
    }

    /** Android 9 and older finish QR provisioning here (no compliance screen in setup wizard). */
    override fun onProfileProvisioningComplete(context: Context, intent: Intent) {
        val extras = extrasOf(intent)
        if (extras != null) saveExtras(context, extras)
        Enforcer.enforce(context)
        Syncer.schedule(context)
        if (Build.VERSION.SDK_INT < 29 && !Prefs(context).enrolled) {
            context.startActivity(Intent(context, EnrollActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        }
    }

    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        Syncer.addEvent(context, "admin_disable_requested")
        return context.getString(R.string.admin_description)
    }

    override fun onDisabled(context: Context, intent: Intent) {
        Syncer.addEvent(context, "admin_disabled")
    }

    override fun onLockTaskModeExiting(context: Context, intent: Intent) {
        val st = Prefs(context).state() ?: return
        if (!st.released && st.effectiveLevel(System.currentTimeMillis() / 1000) == LockLevel.LOCKED) {
            context.startActivity(Intent(context, LockActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        }
    }

    companion object {
        @Suppress("DEPRECATION")
        fun extrasOf(intent: Intent): PersistableBundle? =
            if (Build.VERSION.SDK_INT >= 33) intent.getParcelableExtra(DevicePolicyManager.EXTRA_PROVISIONING_ADMIN_EXTRAS_BUNDLE, PersistableBundle::class.java)
            else intent.getParcelableExtra(DevicePolicyManager.EXTRA_PROVISIONING_ADMIN_EXTRAS_BUNDLE)

        fun saveExtras(context: Context, b: PersistableBundle) {
            val prefs = Prefs(context)
            if (prefs.enrolled) return
            b.getString("server")?.let { prefs.server = it }
            b.getString("token")?.let { prefs.enrollToken = it }
        }
    }
}

/** Setup wizard asks how this app wants to manage the phone: fully managed (Device Owner). */
class ProvisioningModeActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val result = Intent()
        if (Build.VERSION.SDK_INT >= 29) {
            result.putExtra(DevicePolicyManager.EXTRA_PROVISIONING_MODE, DevicePolicyManager.PROVISIONING_MODE_FULLY_MANAGED_DEVICE)
        }
        setResult(RESULT_OK, result)
        finish()
    }
}
