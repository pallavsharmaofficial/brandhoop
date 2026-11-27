package `in`.hooplock.agent.core

import android.annotation.SuppressLint
import android.content.Context
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Looper
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * One-off location fix, used only when the phone is locked, when the shop asks (theft/recovery,
 * logged on the server) or right after a SIM swap. Uses the platform LocationManager so it works
 * without Google Play services.
 */
object Locator {
    @SuppressLint("MissingPermission")
    fun current(ctx: Context, timeoutSec: Long = 25): Location? {
        val lm = ctx.getSystemService(LocationManager::class.java) ?: return null
        val providers = listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)
            .filter { runCatching { lm.isProviderEnabled(it) }.getOrDefault(false) }
        var best: Location? = null
        for (p in providers) {
            val l = runCatching { single(lm, p, timeoutSec) }.getOrNull()
            if (l != null && (best == null || l.accuracy < best.accuracy)) best = l
            if (best != null && best.accuracy < 50) break
        }
        if (best == null) {
            best = providers.mapNotNull { runCatching { lm.getLastKnownLocation(it) }.getOrNull() }
                .maxByOrNull { it.time }
        }
        return best
    }

    @SuppressLint("MissingPermission")
    private fun single(lm: LocationManager, provider: String, timeoutSec: Long): Location? {
        val latch = CountDownLatch(1)
        var result: Location? = null
        if (Build.VERSION.SDK_INT >= 30) {
            val exec = Executors.newSingleThreadExecutor()
            lm.getCurrentLocation(provider, null, exec) { result = it; latch.countDown() }
            latch.await(timeoutSec, TimeUnit.SECONDS)
            exec.shutdown()
        } else {
            val listener = LocationListener { result = it; latch.countDown() }
            @Suppress("DEPRECATION")
            lm.requestSingleUpdate(provider, listener, Looper.getMainLooper())
            latch.await(timeoutSec, TimeUnit.SECONDS)
            lm.removeUpdates(listener)
        }
        return result
    }
}
