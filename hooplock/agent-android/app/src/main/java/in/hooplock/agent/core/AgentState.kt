package `in`.hooplock.agent.core

import org.json.JSONObject
import java.security.MessageDigest
import java.util.Base64
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

enum class LockLevel(val wire: String, val rank: Int) {
    UNLOCKED("unlocked", 0), WARNING("warning", 1), RESTRICTED("restricted", 2), LOCKED("locked", 3);

    companion object {
        fun of(s: String?) = entries.firstOrNull { it.wire == s } ?: UNLOCKED
        fun max(a: LockLevel, b: LockLevel) = if (a.rank >= b.rank) a else b
    }
}

/** What the server wants this phone to do. Parsed only from a payload whose HMAC checked out. */
data class AgentState(
    val deviceId: String,
    val seq: Int,
    val level: LockLevel,
    val released: Boolean,
    val message: String,
    val shopName: String,
    val shopPhone: String,
    val callNumbers: List<String>,
    val dueAmount: Double,
    val overdueDays: Int,
    val nextDue: String?,
    val upi: String,
    /** Epoch seconds after which the phone restricts itself if it has not reached the server. */
    val noContactLockAt: Long?,
    val wantLocation: Boolean,
    val issuedAt: Long,
    /** Google account IDs that may set up the phone after a forced reset (Factory Reset Protection). */
    val frpAccounts: List<String> = emptyList(),
) {
    /** Lock level to enforce now, including the no-contact safety rule. */
    fun effectiveLevel(nowSec: Long): LockLevel {
        if (released) return LockLevel.UNLOCKED
        val ncl = noContactLockAt
        return if (ncl != null && nowSec > ncl) LockLevel.max(level, LockLevel.RESTRICTED) else level
    }

    companion object {
        fun parse(payload: String): AgentState {
            val j = JSONObject(payload)
            val shop = j.optJSONObject("shop") ?: JSONObject()
            val dues = j.optJSONObject("dues")
            val calls = j.optJSONArray("calls")
            return AgentState(
                deviceId = j.getString("d"),
                seq = j.getInt("s"),
                level = LockLevel.of(j.optString("st")),
                released = j.optBoolean("rel", false),
                message = j.optString("msg", ""),
                shopName = shop.optString("name", ""),
                shopPhone = shop.optString("phone", ""),
                callNumbers = (0 until (calls?.length() ?: 0)).map { calls!!.getString(it) },
                dueAmount = dues?.optDouble("amount", 0.0) ?: 0.0,
                overdueDays = dues?.optInt("overdueDays", 0) ?: 0,
                nextDue = dues?.optString("next")?.takeIf { it.isNotEmpty() && it != "null" },
                upi = j.optString("upi", ""),
                noContactLockAt = if (j.isNull("ncl")) null else j.optLong("ncl"),
                wantLocation = j.optBoolean("loc", false),
                issuedAt = j.optLong("t", 0),
                frpAccounts = j.optJSONArray("frp")?.let { a -> (0 until a.length()).map { a.getString(it) } } ?: emptyList(),
            )
        }
    }
}

object Crypto {
    fun hmac(keyHex: String, data: String): ByteArray {
        val mac = Mac.getInstance("HmacSHA256")
        mac.init(SecretKeySpec(hex(keyHex), "HmacSHA256"))
        return mac.doFinal(data.toByteArray(Charsets.UTF_8))
    }

    fun b64url(b: ByteArray): String = Base64.getUrlEncoder().withoutPadding().encodeToString(b)

    fun verifyState(keyHex: String, payload: String, sig: String): Boolean =
        MessageDigest.isEqual(b64url(hmac(keyHex, payload)).toByteArray(), sig.toByteArray())

    /** Offline SMS command: "HL1 <seq> <code> <sig>". Returns (seq, code) if valid for this device. */
    fun parseSms(keyHex: String, deviceId: String, text: String): Pair<Int, Char>? {
        val m = Regex("""HL1 (\d{1,9}) ([UWRLX]) ([A-Za-z0-9_-]{22})""").find(text.trim()) ?: return null
        val seq = m.groupValues[1].toInt()
        val code = m.groupValues[2][0]
        val expected = b64url(hmac(keyHex, "HL1|$deviceId|$seq|$code").copyOf(16))
        return if (MessageDigest.isEqual(expected.toByteArray(), m.groupValues[3].toByteArray())) seq to code else null
    }

    private fun hex(s: String) = ByteArray(s.length / 2) { s.substring(it * 2, it * 2 + 2).toInt(16).toByte() }
}
