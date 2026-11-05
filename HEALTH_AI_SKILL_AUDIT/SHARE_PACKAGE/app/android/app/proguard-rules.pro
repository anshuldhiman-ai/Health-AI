# R8 / ProGuard rules for release shrinking and optimization

# Flutter framework
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

# Preserve all native method signatures
-keepclasseswithmembernames class * {
    native <methods>;
}

# LiteRT / TensorFlow Lite
-keep class org.tensorflow.lite.** { *; }
-keep interface org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**
-keep class com.google.ai.edge.litert.** { *; }
-dontwarn com.google.ai.edge.litert.**

# SQLCipher
-keep class net.sqlcipher.** { *; }
-keep interface net.sqlcipher.** { *; }
-keep class net.sqlcipher.database.** { *; }
-dontwarn net.sqlcipher.**

# Pedometer
-keep class com.example.pedometer.** { *; }
-dontwarn com.example.pedometer.**
-keep class dk.cachet.pedometer.** { *; }
-dontwarn dk.cachet.pedometer.**

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Java 8+ Desugaring
-keep class java.time.** { *; }
-dontwarn java.time.**

# Play Core
-dontwarn com.google.android.play.core.**

# ---------------------------------------------------------------------------
# Plugins that resolve classes BY NAME at runtime.
#
# Each of these was verified against the release R8 mapping: without these
# rules R8 renames or removes the class the plugin looks up, and the plugin
# then throws at runtime (which surfaces as a black screen, not a crash).
# ---------------------------------------------------------------------------

# dart-lang/jni: the JNI bridge itself. The plugin ships these as
# consumer rules, but they are listed here too so a dependency bump
# cannot silently break the release build.
-keep class com.github.dart_lang.jni.** { *; }
-keep class com.github.dart_lang.jni_flutter.** { *; }
-dontwarn com.github.dart_lang.jni.**

# shared_preferences_android resolves these through JNI and Pigeon
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-dontwarn io.flutter.plugins.sharedpreferences.**
-keep class dev.flutter.pigeon.shared_preferences_android.** { *; }
-dontwarn dev.flutter.pigeon.shared_preferences_android.**
-keep class androidx.datastore.** { *; }
-dontwarn androidx.datastore.**
-keep class androidx.preference.** { *; }
-dontwarn androidx.preference.**

# path_provider_android resolves android/content/Context subclasses by name.
-keep class io.flutter.plugins.pathprovider.** { *; }
-dontwarn io.flutter.plugins.pathprovider.**

# health (Health Connect): the plugin's data types are looked up by name.
-keep class cachet.plugins.health.** { *; }
-dontwarn cachet.plugins.health.**

# permission_handler: PermissionUtils reflects over the manifest.
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# flutter_secure_storage: reads the Android Keystore.
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-dontwarn com.it_nomads.fluttersecurestorage.**

# local_auth: the BiometricPrompt fragment is resolved by name.
-keep class io.flutter.plugins.localauth.** { *; }
-dontwarn io.flutter.plugins.localauth.**

# device_info_plus
-keep class dev.fluttercommunity.plus.device_info.** { *; }
-dontwarn dev.fluttercommunity.plus.device_info.**

# sqlcipher_flutter_libs: the native loader.
-keep class eu.simonbinder.sqlite3_flutter_libs.** { *; }
-dontwarn eu.simonbinder.sqlite3_flutter_libs.**

# androidx.security.crypto + Tink: EncryptedSharedPreferences resolves
# the key managers BY CLASS NAME (AesGcmKeyManager, HmacKeyManager, ...).
# R8 renaming them makes the keystore throw at runtime.
-keep class androidx.security.crypto.** { *; }
-dontwarn androidx.security.crypto.**
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**
-keep class com.google.crypto.tink.aead.** { *; }
-keep class com.google.crypto.tink.mac.** { *; }
-keep class com.google.crypto.tink.subtle.** { *; }
-keep class com.google.crypto.tink.synthetic.** { *; }
-keep class com.google.crypto.tink.integration.** { *; }
