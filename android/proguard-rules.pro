# Preserve the public MercadoPago SDK classes.
-keep class com.mercadopago.sdk.** { *; }

# Preserve the bundled Mercado Libre device-fingerprint AAR. Its domain
# objects are serialised by Gson reflection at runtime.
-keep class com.mercadolibre.android.device.** { *; }
-keepclassmembers class com.mercadolibre.android.device.sdk.domain.** {
    <fields>;
}
-dontwarn com.mercadolibre.android.device.**

# Gson runtime needs to keep generic signatures for TypeToken.
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Standard Flutter plugin rules.
-keep class io.flutter.embedding.engine.plugins.FlutterPlugin
-keep class io.flutter.plugin.common.MethodChannel { *; }

# Preserve generic signatures for reflection.
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
