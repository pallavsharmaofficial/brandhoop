package `in`.hooplock.agent

import android.app.Application
import android.os.UserManager
import `in`.hooplock.agent.core.Enforcer
import `in`.hooplock.agent.core.Prefs
import `in`.hooplock.agent.sync.Syncer

class HoopApp : Application() {
    override fun onCreate() {
        super.onCreate()
        Enforcer.ensureChannel(this)
        // After a reboot the app can start before the screen is first unlocked (direct boot, to re-apply
        // the lock). WorkManager lives in normal storage and is not available yet: schedule later.
        if (!getSystemService(UserManager::class.java).isUserUnlocked) return
        val prefs = Prefs(this)
        if (prefs.enrolled || prefs.enrollToken.isNotEmpty()) {
            Syncer.schedule(this)
        }
    }
}
