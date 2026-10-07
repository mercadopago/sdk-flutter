package com.mercadopago.sdk

import android.content.Context
import com.google.gson.Gson
import com.mercadolibre.android.device.sdk.DeviceSDK

/**
 * Collects device fingerprint data via the versioned
 * `com.mercadolibre.android.device:sdk` dependency resolved from the
 * MercadoLibre Maven repository configured by the host application.
 *
 * Lifecycle: [initialise] must be called once when the plugin attaches to
 * the Flutter engine; [collect] reads the latest device info on demand.
 *
 * If the underlying SDK fails for any reason, [collect] returns an empty map.
 * Dart then omits the `device` field entirely, matching the native CoreMethods
 * contract (`DeviceSDK.info` or null) instead of inventing another schema.
 */
class FingerprintHandler private constructor(
    private val context: Context?,
    private val deviceInfo: () -> Any?,
) {

    constructor(context: Context) : this(
        context = context,
        deviceInfo = { DeviceSDK.getInstance()?.info },
    )

    internal constructor(deviceInfo: () -> Any?) : this(
        context = null,
        deviceInfo = deviceInfo,
    )

    private val gson = Gson()

    /**
     * Initialises the underlying DeviceSDK. Safe to call more than once —
     * DeviceSDK guards against re-execution.
     */
    fun initialise() {
        val appContext = context?.applicationContext ?: return
        try {
            DeviceSDK.getInstance().execute(appContext)
        } catch (_: RuntimeException) {
            // Init failure should never break tokenization. collect() will
            // return an empty map when DeviceSDK has no data.
        }
    }

    fun collect(): Map<String, Any?> {
        return try {
            val device = deviceInfo() ?: return emptyMap()
            val json = gson.toJson(device)
            @Suppress("UNCHECKED_CAST")
            gson.fromJson(json, Map::class.java) as Map<String, Any?>
        } catch (_: RuntimeException) {
            emptyMap()
        }
    }
}
