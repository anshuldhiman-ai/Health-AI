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

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Java 8+ Desugaring
-keep class java.time.** { *; }
-dontwarn java.time.**
