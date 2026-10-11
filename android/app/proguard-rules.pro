# R8 rules for the release build.

# Strip android.util.Log calls from release code.
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
    public static int i(...);
}

# Flutter embedding + plugins register through reflection.
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**

# Play Core is referenced by the Flutter engine but not used (no Play Store
# deferred components), so silence missing-class warnings.
-dontwarn com.google.android.play.core.**
