package com.mercadopago.sdk

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class FingerprintHandlerTest {
    @Test
    fun `collect preserves native device info fields`() {
        val handler = FingerprintHandler {
            mapOf("fingerprint" to "opaque", "score" to 1)
        }

        assertEquals(
            mapOf("fingerprint" to "opaque", "score" to 1.0),
            handler.collect(),
        )
    }

    @Test
    fun `collect returns empty map when DeviceSDK has no info`() {
        val handler = FingerprintHandler { null }

        assertTrue(handler.collect().isEmpty())
    }

    @Test
    fun `collect returns empty map when DeviceSDK fails`() {
        val handler = FingerprintHandler { throw RuntimeException("failure") }

        assertTrue(handler.collect().isEmpty())
    }
}
