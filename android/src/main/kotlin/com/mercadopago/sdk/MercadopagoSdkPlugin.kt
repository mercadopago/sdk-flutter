package com.mercadopago.sdk

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class MercadopagoSdkPlugin : FlutterPlugin, MethodCallHandler {
    private var channel: MethodChannel? = null
    private var fingerprintHandler: FingerprintHandler? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        fingerprintHandler = FingerprintHandler(binding.applicationContext)
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME).also {
            it.setMethodCallHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        fingerprintHandler = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val handler = fingerprintHandler
        if (handler == null) {
            result.error("NOT_INITIALIZED", "Plugin not attached to engine.", null)
            return
        }
        when (call.method) {
            "getDeviceData" -> result.success(handler.collect())
            else -> result.notImplemented()
        }
    }

    companion object {
        const val CHANNEL_NAME = "mercadopago/fingerprint"
    }
}
