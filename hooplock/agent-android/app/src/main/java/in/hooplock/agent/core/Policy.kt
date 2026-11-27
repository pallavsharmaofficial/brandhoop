package `in`.hooplock.agent.core

import android.Manifest
import android.app.admin.DevicePolicyManager
import android.app.admin.FactoryResetProtectionPolicy
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.UserManager
import android.provider.Telephony
import android.telecom.TelecomManager
import android.util.Log
import `in`.hooplock.agent.admin.HoopAdminReceiver

/** Everything that needs Device Owner powers lives here. */
class Policy(private val ctx: Context) {
    private val dpm = ctx.getSystemService(DevicePolicyManager::class.java)
    private val admin = ComponentName(ctx, HoopAdminReceiver::class.java)
    private val pkg = ctx.packageName
    private val lockHome = ComponentName(pkg, "in.hooplock.agent.ui.LockHome")

    val isDeviceOwner: Boolean get() = dpm.isDeviceOwnerApp(pkg)

    private val baseRestrictions = listOf(
        UserManager.DISALLOW_FACTORY_RESET,
        UserManager.DISALLOW_SAFE_BOOT,
        UserManager.DISALLOW_DEBUGGING_FEATURES,
        UserManager.DISALLOW_ADD_USER,
        UserManager.DISALLOW_USB_FILE_TRANSFER,
        UserManager.DISALLOW_MOUNT_PHYSICAL_MEDIA,
        // the no-contact safety rule depends on a true clock
        UserManager.DISALLOW_CONFIG_DATE_TIME,
    )

    private val runtimePermissions = buildList {
        add(Manifest.permission.ACCESS_FINE_LOCATION)
        add(Manifest.permission.ACCESS_COARSE_LOCATION)
        if (Build.VERSION.SDK_INT >= 29) add(Manifest.permission.ACCESS_BACKGROUND_LOCATION)
        add(Manifest.permission.READ_PHONE_STATE)
        add(Manifest.permission.READ_PHONE_NUMBERS)
        add(Manifest.permission.RECEIVE_SMS)
        add(Manifest.permission.CALL_PHONE)
        add(Manifest.permission.PROCESS_OUTGOING_CALLS)
        if (Build.VERSION.SDK_INT >= 33) add(Manifest.permission.POST_NOTIFICATIONS)
    }

    /** Protection that stays on for the whole loan, whatever the lock level. */
    fun applyBase(frpAccounts: List<String> = emptyList()) {
        if (!isDeviceOwner) return
        safe("restrictions") { baseRestrictions.forEach { dpm.addUserRestriction(admin, it) } }
        safe("uninstall") { dpm.setUninstallBlocked(admin, pkg, true) }
        safe("permissions") {
            runtimePermissions.forEach {
                dpm.setPermissionGrantState(admin, pkg, it, DevicePolicyManager.PERMISSION_GRANT_STATE_GRANTED)
            }
        }
        if (Build.VERSION.SDK_INT >= 30 && frpAccounts.isNotEmpty()) safe("frp") {
            dpm.setFactoryResetProtectionPolicy(
                admin,
                FactoryResetProtectionPolicy.Builder()
                    .setFactoryResetProtectionAccounts(frpAccounts)
                    .setFactoryResetProtectionEnabled(true)
                    .build(),
            )
        }
        if (Build.VERSION.SDK_INT >= 30) safe("autotime") { dpm.setAutoTimeEnabled(admin, true) }
    }

    /** Full lock: only our lock screen, the emergency dialer and incoming-call UI can run. */
    fun enterLock() {
        if (!isDeviceOwner) return
        val allowed = listOfNotNull(pkg, defaultDialer(), "com.android.phone", "com.android.server.telecom", "com.android.emergency")
            .filter { it == pkg || installed(it) }.distinct().toTypedArray()
        safe("locktask pkgs") { dpm.setLockTaskPackages(admin, allowed) }
        if (Build.VERSION.SDK_INT >= 28) safe("locktask features") {
            dpm.setLockTaskFeatures(
                admin,
                DevicePolicyManager.LOCK_TASK_FEATURE_GLOBAL_ACTIONS or
                    DevicePolicyManager.LOCK_TASK_FEATURE_KEYGUARD or
                    DevicePolicyManager.LOCK_TASK_FEATURE_SYSTEM_INFO,
            )
        }
        safe("home") {
            ctx.packageManager.setComponentEnabledSetting(lockHome, PackageManager.COMPONENT_ENABLED_STATE_ENABLED, PackageManager.DONT_KILL_APP)
            val f = IntentFilter(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME); addCategory(Intent.CATEGORY_DEFAULT)
            }
            dpm.addPersistentPreferredActivity(admin, f, lockHome)
        }
        safe("statusbar") { dpm.setStatusBarDisabled(admin, true) }
        if (Build.VERSION.SDK_INT >= 30) safe("location on") { dpm.setLocationEnabled(admin, true) }
    }

    fun exitLock() {
        if (!isDeviceOwner) return
        safe("home clear") {
            dpm.clearPackagePersistentPreferredActivities(admin, pkg)
            ctx.packageManager.setComponentEnabledSetting(lockHome, PackageManager.COMPONENT_ENABLED_STATE_DISABLED, PackageManager.DONT_KILL_APP)
        }
        safe("statusbar") { dpm.setStatusBarDisabled(admin, false) }
        safe("locktask clear") { dpm.setLockTaskPackages(admin, arrayOf()) }
    }

    /** Restricted stage: pause every app with an icon except phone, SMS and HoopLock. */
    fun suspendApps(prefs: Prefs, on: Boolean) {
        if (!isDeviceOwner) return
        val keep = setOfNotNull(pkg, defaultDialer(), defaultSms(), "com.android.phone", "com.android.settings", "com.android.server.telecom")
        val launchable = launchablePackages()
        val previous = prefs.suspended()
        safe("suspend") {
            if (on) {
                val target = (launchable - keep).toTypedArray()
                val failed = dpm.setPackagesSuspended(admin, target, true).toSet()
                prefs.setSuspended(target.toSet() - failed)
            } else if (previous.isNotEmpty() || launchable.isNotEmpty()) {
                dpm.setPackagesSuspended(admin, (previous + launchable).toTypedArray(), false)
                prefs.setSuspended(emptySet())
            }
        }
    }

    /** Loan closed: remove every restriction and give up Device Owner. */
    fun releaseAll() {
        if (!isDeviceOwner) return
        exitLock()
        safe("restrictions clear") { baseRestrictions.forEach { dpm.clearUserRestriction(admin, it) } }
        safe("uninstall unblock") { dpm.setUninstallBlocked(admin, pkg, false) }
        if (Build.VERSION.SDK_INT >= 30) safe("frp clear") { dpm.setFactoryResetProtectionPolicy(admin, null) }
        @Suppress("DEPRECATION")
        safe("clear owner") { dpm.clearDeviceOwnerApp(pkg) }
    }

    fun defaultDialer(): String? = runCatching { ctx.getSystemService(TelecomManager::class.java).defaultDialerPackage }.getOrNull()
    private fun defaultSms(): String? = runCatching { Telephony.Sms.getDefaultSmsPackage(ctx) }.getOrNull()

    private fun installed(p: String) = runCatching { ctx.packageManager.getPackageInfo(p, 0); true }.getOrDefault(false)

    private fun launchablePackages(): Set<String> {
        val i = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        return ctx.packageManager.queryIntentActivities(i, PackageManager.MATCH_ALL).map { it.activityInfo.packageName }.toSet()
    }

    private inline fun safe(what: String, block: () -> Unit) {
        try { block() } catch (t: Throwable) { Log.w("HoopLock", "policy $what failed: ${t.message}") }
    }
}

fun Prefs.suspended(): Set<String> = pendingSuspended.split(',').filter { it.isNotBlank() }.toSet()
fun Prefs.setSuspended(s: Set<String>) { pendingSuspended = s.joinToString(",") }
