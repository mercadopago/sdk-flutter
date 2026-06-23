package com.mercadopago.sdk

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MercadopagoSdkPlugin : FlutterPlugin, MethodCallHandler {
    private var channel: MethodChannel? = null
    private var fingerprintHandler: FingerprintHandler? = null
    private var executor: ExecutorService? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        executor = Executors.newSingleThreadExecutor()
        fingerprintHandler = FingerprintHandler(binding.applicationContext).also {
            // Initialise the device SDK once, off the main thread, so the
            // first tokenization call is not blocked by SDK warm-up.
            executor?.submit { it.initialise() }
        }
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME).also {
            it.setMethodCallHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        fingerprintHandler = null
        executor?.shutdown()
        executor = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val handler = fingerprintHandler
        val pool = executor
        if (handler == null || pool == null) {
            result.error("NOT_INITIALIZED", "Plugin not attached to engine.", null)
            return
        }
        when (call.method) {
            "getDeviceData" -> pool.submit {
                val data = handler.collect()
                mainHandler.post { result.success(data) }
            }
            else -> result.notImplemented()
        }
    }

    companion object {
        const val CHANNEL_NAME = "mercadopago/fingerprint"
    }
}
