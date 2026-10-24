# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# --- Capacitor (required now that minifyEnabled is true) ---
# Capacitor's bridge finds plugins and their @PluginMethod-annotated methods via reflection at
# runtime, driven by annotations and the generated plugin list; R8 can't see that from the call
# graph, so it must be told explicitly not to strip or rename any of this, or the JS side's calls
# into Filesystem/Preferences/Share (and your own future plugins) will fail silently at runtime.
-keep public class com.getcapacitor.** { *; }
-keep public class * extends com.getcapacitor.Plugin { *; }
-keepclassmembers public class * extends com.getcapacitor.Plugin {
    @com.getcapacitor.annotation.PluginMethod public *;
}
-keep @com.getcapacitor.annotation.CapacitorPlugin public class * { *; }
-keepattributes *Annotation*

# Cordova plugins bundled under capacitor-cordova-android-plugins (used for legacy Cordova-style
# plugins some Capacitor community plugins still wrap).
-keep public class org.apache.cordova.** { *; }
