package `in`.hooplock.agent.core

import android.annotation.SuppressLint
import android.content.Context
import android.os.BatteryManager
import android.os.Build
import android.telephony.SubscriptionManager
import android.telephony.TelephonyManager
import `in`.hooplock.agent.BuildConfig
import org.json.JSONArray
import org.json.JSONObject
import java.security.MessageDigest

/** Phone identity sent at enrollment and on each sync. Only device and SIM identifiers, nothing personal. */
object DeviceInfo {

    @SuppressLint("MissingPermission", "HardwareIds")
    fun collect(ctx: Context): JSONObject {
        val tm = ctx.getSystemService(TelephonyManager::class.java)
        val imeis = (0 until 2).map { slot -> runCatching { tm.getImei(slot) ?: "" }.getOrDefault("") }
        val serial = runCatching { Build.getSerial() }.getOrDefault("")
        return JSONObject()
            .put("imei1", imeis[0])
            .put("imei2", imeis[1])
            .put("serial", if (serial == Build.UNKNOWN) "" else serial)
            .put("brand", Build.BRAND.replaceFirstChar { it.uppercase() })
            .put("model", Build.MODEL)
            .put("osVersion", Build.VERSION.RELEASE)
            .put("agentVersion", BuildConfig.VERSION_NAME)
            .put("sims", sims(ctx))
    }

    @SuppressLint("MissingPermission")
    fun sims(ctx: Context): JSONArray {
        val out = JSONArray()
        val sm = ctx.getSystemService(SubscriptionManager::class.java) ?: return out
        val list = runCatching { sm.activeSubscriptionInfoList }.getOrNull().orEmpty().sortedBy { it.simSlotIndex }
        for (info in list.take(2)) {
            @Suppress("DEPRECATION")
            val number = runCatching {
                if (Build.VERSION.SDK_INT >= 33) sm.getPhoneNumber(info.subscriptionId) else info.number ?: ""
            }.getOrDefault("")
            @Suppress("DEPRECATION")
            val iccid = runCatching { info.iccId ?: "" }.getOrDefault("")
            out.put(
                JSONObject()
                    .put("number", number.takeLast(10))
                    .put("operator", info.carrierName?.toString() ?: "")
                    .put("iccidHash", sha(iccid.ifEmpty { "${info.subscriptionId}|${info.mccString}${info.mncString}" })),
            )
        }
        return out
    }

    fun battery(ctx: Context): Int =
        runCatching { ctx.getSystemService(BatteryManager::class.java).getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY) }.getOrDefault(-1)

    /** A short fingerprint of the inserted SIM cards, to notice when someone swaps them. */
    fun simFingerprint(sims: JSONArray): String =
        (0 until sims.length()).map { sims.getJSONObject(it).optString("iccidHash") }.sorted().joinToString(",")

    private fun sha(s: String): String =
        MessageDigest.getInstance("SHA-256").digest(s.toByteArray()).take(12).joinToString("") { "%02x".format(it) }
}
