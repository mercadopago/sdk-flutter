package com.mercadopago.sdk

import android.content.Context
import android.os.Build
import com.google.gson.Gson
import com.mercadolibre.android.device.sdk.DeviceSDK

/**
 * Collects device fingerprint data via the bundled
 * `com.mercadolibre.android.device:sdk` AAR (under `android/libs/`).
 *
 * Lifecycle: [initialise] must be called once when the plugin attaches to
 * the Flutter engine; [collect] reads the latest device info on demand.
 *
 * If the underlying SDK fails for any reason (sensor read, permission
 * denial, internal exception), [collect] returns a minimal [fallback]
 * payload so tokenization still succeeds without the enriched signals.
 */
class FingerprintHandler(private val context: Context) {

    private val gson = Gson()

    /**
     * Initialises the underlying DeviceSDK. Safe to call more than once —
     * DeviceSDK guards against re-execution.
     */
    fun initialise() {
        try {
            DeviceSDK.getInstance().execute(context.applicationContext)
        } catch (_: RuntimeException) {
            // Init failure should never break the plugin; collect() returns
            // the fallback on subsequent calls.
        }
    }

    fun collect(): Map<String, Any?> {
        return try {
            val device = DeviceSDK.getInstance()?.info ?: return fallback()
            val json = gson.toJson(device)
            @Suppress("UNCHECKED_CAST")
            gson.fromJson(json, Map::class.java) as Map<String, Any?>
        } catch (_: RuntimeException) {
            fallback()
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
