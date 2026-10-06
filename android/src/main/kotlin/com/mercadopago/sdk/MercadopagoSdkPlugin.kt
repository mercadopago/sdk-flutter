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
import java.util.concurrent.RejectedExecutionException
import java.util.concurrent.atomic.AtomicLong

class MercadopagoSdkPlugin : FlutterPlugin, MethodCallHandler {
    private var channel: MethodChannel? = null
    private var fingerprintHandler: FingerprintHandler? = null
    private var executor: ExecutorService? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val attachmentGeneration = AtomicLong(0)

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        attachmentGeneration.incrementAndGet()
        val pool = Executors.newSingleThreadExecutor()
        val handler = FingerprintHandler(binding.applicationContext)
        executor = pool
        fingerprintHandler = handler
        // Queue initialization before collection while keeping SDK work off
        // the platform thread.
        pool.execute { handler.initialise() }
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME).also {
            it.setMethodCallHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        attachmentGeneration.incrementAndGet()
        channel?.setMethodCallHandler(null)
        channel = null
        fingerprintHandler = null
        val pool = executor
        executor = null
        // Interrupt queued work and prevent a completed task from replying to
        // a Flutter engine that has already detached.
        pool?.shutdownNow()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val handler = fingerprintHandler
        val pool = executor
        if (handler == null || pool == null) {
            result.error("NOT_INITIALIZED", "Plugin not attached to engine.", null)
            return
        }
        when (call.method) {
            "getDeviceData" -> collectFingerprint(handler, pool, result)
            else -> result.notImplemented()
        }
    }

    private fun collectFingerprint(
        handler: FingerprintHandler,
        pool: ExecutorService,
        result: Result,
    ) {
        val generation = attachmentGeneration.get()
        try {
            pool.execute {
                val data = handler.collect()
                mainHandler.post {
                    if (isCurrentAttachment(handler, pool, generation)) {
                        result.success(data)
                    }
                }
            }
        } catch (_: RejectedExecutionException) {
            // Detach may race a method call. Complete the call when this is
            // still the active engine; Dart converts the error into fallback.
            mainHandler.post {
                if (isCurrentAttachment(handler, pool, generation)) {
                    result.error(
                        "EXECUTOR_UNAVAILABLE",
                        "Fingerprint worker is shutting down.",
                        null,
                    )
                }
            }
        }
    }

    private fun isCurrentAttachment(
        handler: FingerprintHandler,
        pool: ExecutorService,
        generation: Long,
    ): Boolean =
        attachmentGeneration.get() == generation &&
            fingerprintHandler === handler &&
            executor === pool

    companion object {
        const val CHANNEL_NAME = "mercadopago/fingerprint"
    }
}
