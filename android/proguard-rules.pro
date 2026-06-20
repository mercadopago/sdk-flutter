# Preserve the public MercadoPago SDK classes.
-keep class com.mercadopago.sdk.** { *; }

# Preserve the Mercado Libre device-fingerprint classes that the plugin
# loads reflectively. R8 may strip them otherwise.
-keep class com.mercadolibre.android.device.** { *; }
-dontwarn com.mercadolibre.android.device.**

# Standard Flutter plugin rules.
-keep class io.flutter.embedding.engine.plugins.FlutterPlugin
-keep class io.flutter.plugin.common.MethodChannel { *; }

# Preserve generic signatures for reflection.
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
