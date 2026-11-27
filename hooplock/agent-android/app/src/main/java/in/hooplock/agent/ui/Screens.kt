package `in`.hooplock.agent.ui

import android.app.Activity
import android.app.role.RoleManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.WindowManager
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ProgressBar
import `in`.hooplock.agent.R
import `in`.hooplock.agent.admin.HoopAdminReceiver
import `in`.hooplock.agent.core.AgentState
import `in`.hooplock.agent.core.Api
import `in`.hooplock.agent.core.Enforcer
import `in`.hooplock.agent.core.LockLevel
import `in`.hooplock.agent.core.Policy
import `in`.hooplock.agent.core.Prefs
import `in`.hooplock.agent.sync.Syncer
import java.util.Locale

/**
 * Shown by the setup wizard right after the QR install (ADMIN_POLICY_COMPLIANCE): registers the
 * phone with the shop, shows the customer the agreement, and records their consent.
 */
class EnrollActivity : Activity() {
    private lateinit var prefs: Prefs

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        prefs = Prefs(this)
        HoopAdminReceiver.extrasOf(intent)?.let { HoopAdminReceiver.saveExtras(this, it) }
        Policy(this).applyBase()
        Syncer.schedule(this)
        if (prefs.enrolled) showConsent() else connect()
    }

    private fun connect() {
        val col = Ui.column(this, 32).apply { gravity = Gravity.CENTER }
        col.addView(ImageView(this).apply { setImageResource(R.drawable.ic_lock) })
        col.addView(Ui.text(this, getString(R.string.enroll_connecting), 18f, center = true))
        col.addView(ProgressBar(this))
        setContentView(col)
        Thread {
            val err = runCatching { Syncer.enroll(this) }.exceptionOrNull()
            runOnUiThread { if (err == null) showConsent() else showError(err.message) }
        }.start()
    }

    private fun showError(msg: String?) {
        val col = Ui.column(this, 32).apply { gravity = Gravity.CENTER }
        col.addView(Ui.text(this, getString(R.string.enroll_failed), 18f, bold = true, center = true))
        if (!msg.isNullOrBlank()) col.addView(Ui.text(this, msg, 14f, Ui.MUTED, center = true))
        col.addView(Ui.button(this, getString(R.string.retry)) { connect() })
        // The phone is already protected (Device Owner + base policy); enrollment retries in the background.
        col.addView(Ui.button(this, getString(R.string.later), 1) { done() })
        setContentView(col)
    }

    private fun showConsent() {
        val st = prefs.state()
        val col = Ui.column(this, 24)
        col.addView(ImageView(this).apply { setImageResource(R.drawable.ic_lock) })
        col.addView(Ui.text(this, getString(R.string.consent_title), 24f, bold = true))
        col.addView(Ui.text(this, getString(R.string.consent_body, st?.shopName ?: ""), 16f))
        if (st != null) {
            val card = Ui.card(this)
            card.addView(Ui.text(this, st.shopName, 18f, bold = true))
            if (st.shopPhone.isNotEmpty()) card.addView(Ui.text(this, st.shopPhone, 16f, Ui.MUTED))
            st.nextDue?.let { card.addView(Ui.text(this, "EMI: ₹${Ui.rupees(st.dueAmount)} • $it", 16f)) }
            col.addView(card)
        }
        col.addView(Ui.button(this, getString(R.string.consent_accept)) { accept() })
        setContentView(Ui.scroll(this, col))
    }

    private fun accept() {
        prefs.consentGiven = true
        val now = System.currentTimeMillis() / 1000
        val lang = Locale.getDefault().language
        Thread { runCatching { Api(prefs).consent(now, lang) } }.start()
        if (Build.VERSION.SDK_INT >= 29) {
            val rm = getSystemService(RoleManager::class.java)
            if (rm.isRoleAvailable(RoleManager.ROLE_CALL_REDIRECTION) && !rm.isRoleHeld(RoleManager.ROLE_CALL_REDIRECTION)) {
                runCatching { startActivityForResult(rm.createRequestRoleIntent(RoleManager.ROLE_CALL_REDIRECTION), 7) }.onSuccess { return }
            }
        }
        done()
    }

    @Deprecated("Activity result API not needed here")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 7) done()
    }

    private fun done() {
        Enforcer.enforce(this)
        setResult(RESULT_OK)
        finish()
    }
}

/** Full lock screen. Only: call the shop, emergency call, pay by UPI QR (from another phone), check again. */
class LockActivity : Activity() {
    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(c: Context, i: Intent) = refresh()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        if (Build.VERSION.SDK_INT >= 33) {
            onBackInvokedDispatcher.registerOnBackInvokedCallback(android.window.OnBackInvokedDispatcher.PRIORITY_OVERLAY) { }
        }
    }

    override fun onResume() {
        super.onResume()
        val f = IntentFilter(Enforcer.ACTION_STATE_CHANGED)
        if (Build.VERSION.SDK_INT >= 33) registerReceiver(receiver, f, RECEIVER_NOT_EXPORTED) else registerReceiver(receiver, f)
        refresh()
    }

    override fun onPause() {
        super.onPause()
        runCatching { unregisterReceiver(receiver) }
    }

    @Deprecated("Back is disabled on the lock screen")
    override fun onBackPressed() { /* stay */ }

    private fun refresh() {
        val st = Prefs(this).state()
        val locked = st != null && !st.released && st.effectiveLevel(System.currentTimeMillis() / 1000) == LockLevel.LOCKED
        if (!locked) {
            runCatching { stopLockTask() }
            finish()
            return
        }
        if (Policy(this).isDeviceOwner) runCatching { startLockTask() }
        render(st!!)
    }

    private fun render(st: AgentState) {
        val col = Ui.column(this, 20)
        val header = Ui.column(this, 20).apply {
            setBackgroundColor(Ui.BRAND); gravity = Gravity.CENTER_HORIZONTAL
        }
        header.addView(ImageView(this).apply { setImageResource(R.drawable.ic_lock) })
        header.addView(Ui.text(this, getString(R.string.locked_title), 26f, 0xFFFFFFFF.toInt(), bold = true, center = true))
        header.addView(Ui.text(this, getString(R.string.locked_sub), 16f, 0xFFFFFFFF.toInt(), center = true))
        col.addView(header)

        val card = Ui.card(this)
        card.addView(Ui.text(this, st.shopName, 20f, bold = true))
        if (st.message.isNotBlank()) card.addView(Ui.text(this, st.message, 16f))
        if (st.dueAmount > 0) card.addView(Ui.text(this, getString(R.string.due_amount, Ui.rupees(st.dueAmount)), 22f, Ui.BRAND, bold = true))
        if (st.overdueDays > 0) card.addView(Ui.text(this, getString(R.string.overdue_days, st.overdueDays), 16f, Ui.MUTED))
        col.addView(card)

        if (st.upi.isNotEmpty()) {
            val qrCard = Ui.card(this).apply { gravity = Gravity.CENTER_HORIZONTAL }
            val size = Ui.dp(this, 200)
            qrCard.addView(ImageView(this).apply {
                setImageBitmap(Ui.qr(st.upi, size))
                layoutParams = LinearLayout.LayoutParams(size, size)
            })
            qrCard.addView(Ui.text(this, getString(R.string.pay_qr), 14f, Ui.MUTED, center = true))
            col.addView(qrCard)
        }

        for (n in st.callNumbers) {
            col.addView(Ui.button(this, getString(R.string.call_shop, n)) {
                runCatching { startActivity(Intent(Intent.ACTION_CALL, Uri.parse("tel:$n"))) }
            })
        }
        col.addView(Ui.button(this, getString(R.string.emergency), 2) { emergency() })
        col.addView(Ui.button(this, getString(R.string.refresh), 1) {
            Syncer.syncNow(this, "customer_check")
            it(getString(R.string.checking))
        })
        setContentView(Ui.scroll(this, col))
    }

    private fun it(msg: String) = android.widget.Toast.makeText(this, msg, android.widget.Toast.LENGTH_SHORT).show()

    private fun emergency() {
        val tries = listOf(
            Intent("com.android.phone.EmergencyDialer.DIAL"),
            Intent(Intent.ACTION_DIAL, Uri.parse("tel:112")),
        )
        for (i in tries) if (runCatching { startActivity(i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }.isSuccess) return
    }
}

/** Dismissable overdue notice (first step, before any restriction). */
class WarningActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val st = Prefs(this).state() ?: return finish()
        val col = Ui.column(this, 24)
        col.addView(ImageView(this).apply { setImageResource(R.drawable.ic_lock) })
        col.addView(Ui.text(this, getString(R.string.warning_title), 24f, Ui.BRAND, bold = true))
        col.addView(Ui.text(this, st.message.ifBlank { getString(R.string.warning_body) }, 17f))
        if (st.dueAmount > 0) col.addView(Ui.text(this, getString(R.string.due_amount, Ui.rupees(st.dueAmount)), 22f, bold = true))
        if (st.overdueDays > 0) col.addView(Ui.text(this, getString(R.string.overdue_days, st.overdueDays), 16f, Ui.MUTED))
        if (st.upi.isNotEmpty()) col.addView(Ui.button(this, "UPI ₹${Ui.rupees(st.dueAmount)}") {
            runCatching { startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(st.upi))) }
        })
        st.callNumbers.firstOrNull()?.let { n ->
            col.addView(Ui.button(this, getString(R.string.call_shop, n), 1) { runCatching { startActivity(Intent(Intent.ACTION_DIAL, Uri.parse("tel:$n"))) } })
        }
        col.addView(Ui.button(this, getString(R.string.ok), 1) { finish() })
        setContentView(Ui.scroll(this, col))
    }
}

/** App icon screen: what this is, the next EMI, and (after payoff) a button to remove the app. */
class StatusActivity : Activity() {
    companion object { const val EXTRA_RELEASED = "released" }

    override fun onResume() {
        super.onResume()
        val prefs = Prefs(this)
        val col = Ui.column(this, 24)
        col.addView(ImageView(this).apply { setImageResource(R.drawable.ic_lock) })
        col.addView(Ui.text(this, getString(R.string.app_name), 24f, bold = true))
        val st = prefs.state()
        when {
            prefs.releasedDone || intent.getBooleanExtra(EXTRA_RELEASED, false) -> {
                col.addView(Ui.text(this, getString(R.string.released_title), 20f, Ui.BRAND, bold = true))
                col.addView(Ui.text(this, getString(R.string.released_body), 16f))
                col.addView(Ui.button(this, getString(R.string.remove_app)) {
                    runCatching { startActivity(Intent(Intent.ACTION_DELETE, Uri.parse("package:$packageName"))) }
                })
            }
            st == null -> col.addView(Ui.text(this, getString(R.string.status_not_enrolled), 16f))
            else -> {
                col.addView(Ui.text(this, getString(R.string.status_ok, st.shopName, st.nextDue ?: "-"), 16f))
                if (st.dueAmount > 0) col.addView(Ui.text(this, getString(R.string.due_amount, Ui.rupees(st.dueAmount)), 18f, bold = true))
                if (st.level == LockLevel.RESTRICTED) col.addView(Ui.text(this, getString(R.string.restricted_notice), 15f, Ui.BRAND))
                st.callNumbers.firstOrNull()?.let { n ->
                    col.addView(Ui.button(this, getString(R.string.call_shop, n), 1) { runCatching { startActivity(Intent(Intent.ACTION_DIAL, Uri.parse("tel:$n"))) } })
                }
                col.addView(Ui.button(this, getString(R.string.refresh), 1) { Syncer.syncNow(this, "customer_check") })
            }
        }
        setContentView(Ui.scroll(this, col))
    }
}
