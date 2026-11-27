package `in`.hooplock.agent.core

import org.json.JSONObject
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL

class ApiException(val status: Int, message: String) : IOException(message)

/** Small HTTPS client for the HoopLock server (no third-party HTTP library, keeps the APK small). */
class Api(private val prefs: Prefs) {

    fun enroll(body: JSONObject): JSONObject = post("/agent/v1/enroll", body, auth = false)
    fun sync(body: JSONObject): JSONObject = post("/agent/v1/sync", body)
    fun consent(acceptedAt: Long, language: String) =
        post("/agent/v1/consent", JSONObject().put("acceptedAt", acceptedAt).put("language", language))
    fun location(lat: Double, lng: Double, accuracy: Float, reason: String) =
        post("/agent/v1/location", JSONObject().put("lat", lat).put("lng", lng).put("accuracy", accuracy.toDouble()).put("reason", reason))
    fun released() = post("/agent/v1/released", JSONObject())

    private fun post(path: String, body: JSONObject, auth: Boolean = true): JSONObject {
        val base = prefs.server.trimEnd('/')
        require(base.startsWith("https://") || base.startsWith("http://10.0.2.2")) { "Server must use HTTPS" }
        val c = URL(base + path).openConnection() as HttpURLConnection
        try {
            c.requestMethod = "POST"
            c.connectTimeout = 15_000
            c.readTimeout = 20_000
            c.doOutput = true
            c.setRequestProperty("content-type", "application/json")
            if (auth) c.setRequestProperty("authorization", "Device ${prefs.deviceId}.${prefs.apiToken}")
            c.outputStream.use { it.write(body.toString().toByteArray()) }
            val code = c.responseCode
            val text = (if (code in 200..299) c.inputStream else c.errorStream)?.bufferedReader()?.use { it.readText() } ?: ""
            if (code !in 200..299) {
                val msg = runCatching { JSONObject(text).optString("message") }.getOrNull().orEmpty().ifEmpty { "HTTP $code" }
                throw ApiException(code, msg)
            }
            return if (text.isBlank()) JSONObject() else JSONObject(text)
        } finally {
            c.disconnect()
        }
    }
}
