package `in`.hooplock.agent.sync

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Telephony
import android.telecom.CallRedirectionService
import android.telecom.PhoneAccountHandle
import android.telephony.TelephonyManager
import androidx.annotation.RequiresApi
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import `in`.hooplock.agent.core.Crypto
import `in`.hooplock.agent.core.Enforcer
import `in`.hooplock.agent.core.LockLevel
import `in`.hooplock.agent.core.Prefs
import org.json.JSONObject

/** Re-apply the lock immediately after every boot, before anything else runs. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        Enforcer.enforce(ctx)
        if (intent.action != Intent.ACTION_LOCKED_BOOT_COMPLETED) {
            Syncer.addEvent(ctx, "boot")
            Syncer.schedule(ctx)
            Syncer.syncNow(ctx, "boot")
        }
    }
}

/** Offline commands by SMS ("HL1 <seq> <code> <sig>"), signed with this phone's own key. */
class SmsCommandReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        val prefs = Prefs(ctx)
        if (!prefs.enrolled) return
        val msgs = Telephony.Sms.Intents.getMessagesFromIntent(intent) ?: return
        val text = msgs.joinToString("") { it.messageBody ?: "" }
        if (!text.contains("HL1 ")) return
        val cmd = Crypto.parseSms(prefs.commandKey, prefs.deviceId, text) ?: return
        if (Enforcer.acceptSms(ctx, cmd.first, cmd.second)) {
            Syncer.addEvent(ctx, "sms_command", JSONObject().put("seq", cmd.first).put("code", cmd.second.toString()))
            Syncer.syncNow(ctx, "sms")
        }
    }
}

/** Which numbers a fully locked phone may call: the shop's numbers. Emergency numbers are never blocked. */
object CallRules {
    fun allowed(ctx: Context, number: String?): Boolean {
        val prefs = Prefs(ctx)
        val st = prefs.state() ?: return true
        if (st.effectiveLevel(System.currentTimeMillis() / 1000) != LockLevel.LOCKED) return true
        val n = number?.filter { it.isDigit() }?.takeLast(10).orEmpty()
        if (n.isEmpty()) return false
        if (isEmergency(ctx, number!!)) return true
        return st.callNumbers.any { it.filter(Char::isDigit).takeLast(10) == n }
    }

    private fun isEmergency(ctx: Context, number: String): Boolean {
        val digits = number.filter { it.isDigit() }
        if (digits in setOf("112", "100", "101", "102", "108", "1091", "1098", "181")) return true
        return Build.VERSION.SDK_INT >= 29 &&
            runCatching { ctx.getSystemService(TelephonyManager::class.java).isEmergencyNumber(number) }.getOrDefault(false)
    }
}

/** Older and most current phones: cancel outgoing calls to numbers that are not allowed while locked. */
class OutgoingCallGuard : BroadcastReceiver() {
    @Suppress("DEPRECATION")
    override fun onReceive(ctx: Context, intent: Intent) {
        val number = resultData ?: intent.getStringExtra(Intent.EXTRA_PHONE_NUMBER)
        if (!CallRules.allowed(ctx, number)) {
            resultData = null
            Syncer.addEvent(ctx, "call_blocked")
        }
    }
}

/** Android 10+: the same rule through the call-redirection role (granted during setup). */
@RequiresApi(29)
class CallGuardService : CallRedirectionService() {
    override fun onPlaceCall(handle: Uri, initialPhoneAccount: PhoneAccountHandle, allowInteractiveResponse: Boolean) {
        if (CallRules.allowed(this, handle.schemeSpecificPart)) placeCallUnmodified() else cancelCall()
    }
}

/** Push from the server only means "sync now"; the state itself is fetched and verified over HTTPS. */
class PushService : FirebaseMessagingService() {
    override fun onMessageReceived(message: RemoteMessage) = Syncer.syncNow(this, "push")
    override fun onNewToken(token: String) = Syncer.syncNow(this, "token")
}
