package `in`.hooplock.agent

import android.app.Application
import `in`.hooplock.agent.core.Enforcer
import `in`.hooplock.agent.core.Prefs
import `in`.hooplock.agent.sync.Syncer

class HoopApp : Application() {
    override fun onCreate() {
        super.onCreate()
        Enforcer.ensureChannel(this)
        val prefs = Prefs(this)
        if (prefs.enrolled || prefs.enrollToken.isNotEmpty()) {
            Syncer.schedule(this)
        }
    }
}
