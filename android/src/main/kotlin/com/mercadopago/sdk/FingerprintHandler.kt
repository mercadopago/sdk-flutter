package com.mercadopago.sdk

import android.content.Context
import android.os.Build
import org.json.JSONObject

/**
 * Collects device fingerprint data for fraud detection.
 *
 * The official Mercado Libre `com.mercadolibre.android.device:sdk` library is
 * looked up reflectively so the plugin compiles and runs even when the artifact
 * is not on the classpath. Usage mirrors sdk-android:
 *
 *   DeviceSDK.getInstance().execute(context)  // initialise
 *   DeviceSDK.getInstance()?.info             // get Device object
 *
 * When the library is unavailable a minimal fallback map is returned so
 * tokenization still succeeds without the enriched fraud signals.
 */
class FingerprintHandler(private val context: Context) {

    fun collect(): Map<String, Any?> {
        return tryNativeFingerprint() ?: fallback()
    }

    private fun tryNativeFingerprint(): Map<String, Any?>? {
        return try {
            val sdkClass = Class.forName("com.mercadolibre.android.device.sdk.DeviceSDK")

            // Static getInstance()
            val getInstance = sdkClass.getMethod("getInstance")
            val sdkInstance = getInstance.invoke(null) ?: return null

            // execute(context) — initialises the SDK; idempotent if called again
            val execute = sdkClass.getMethod("execute", Context::class.java)
            execute.invoke(sdkInstance, context)

            // getInfo() / info property accessor
            val getInfo = try {
                sdkClass.getMethod("getInfo")
            } catch (_: NoSuchMethodException) {
                sdkClass.getMethod("info") // Kotlin property accessor fallback
            }
            val device = getInfo.invoke(sdkInstance) ?: return null

            deviceToMap(device)
        } catch (_: ReflectiveOperationException) {
            null
        } catch (_: ClassCastException) {
            null
        }
    }

    /**
     * Serialises the Device object to a plain Map via Gson (which is almost
     * always present on Android) with a JSONObject fallback.
     */
    private fun deviceToMap(device: Any): Map<String, Any?>? {
        return try {
            val gsonClass = Class.forName("com.google.gson.Gson")
            val gsonInstance = gsonClass.getDeclaredConstructor().newInstance()
            val toJson = gsonClass.getMethod("toJson", Any::class.java)
            val json = toJson.invoke(gsonInstance, device) as? String ?: return null
            jsonStringToMap(json)
        } catch (_: ReflectiveOperationException) {
            null
        }
    }

    private fun jsonStringToMap(json: String): Map<String, Any?> {
        val obj = JSONObject(json)
        return obj.keys().asSequence().associateWith { key ->
            when (val v = obj.get(key)) {
                is JSONObject -> jsonStringToMap(v.toString())
                JSONObject.NULL -> null
                else -> v
            }
        }
    }

    private fun fallback(): Map<String, Any?> = mapOf(
        "platform" to "android",
        "manufacturer" to Build.MANUFACTURER,
        "model" to Build.MODEL,
        "os_version" to Build.VERSION.RELEASE,
        "sdk_int" to Build.VERSION.SDK_INT,
        "package_name" to context.packageName,
    )
}
