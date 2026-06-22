package com.mercadopago.sdk

import android.content.Context
import android.os.Build

/**
 * Collects device fingerprint data for fraud detection.
 *
 * The official Mercado Libre `com.mercadolibre.android:device` library is
 * looked up reflectively so the plugin still compiles and runs in
 * environments where the artifact is unavailable. When missing, a minimal
 * fallback object is emitted; tokenization succeeds without the enriched
 * signals.
 */
class FingerprintHandler(private val context: Context) {

    fun collect(): Map<String, Any?> {
        val native = tryNativeFingerprint()
        if (native != null) return native
        return fallback()
    }

    private fun tryNativeFingerprint(): Map<String, Any?>? {
        return try {
            val clazz = Class.forName("com.mercadolibre.android.device.Device")
            val instance = clazz.getDeclaredConstructor(Context::class.java)
                .newInstance(context)
            val method = clazz.getMethod("getDeviceInformation")
            @Suppress("UNCHECKED_CAST")
            method.invoke(instance) as? Map<String, Any?>
        } catch (_: ReflectiveOperationException) {
            null
        } catch (_: ClassCastException) {
            null
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
