# Android Notification Setup

After running `tool/bootstrap.sh`, follow the current `flutter_local_notifications` Android setup for the pinned plugin version.

At minimum:

1. Enable core library desugaring in the Android Gradle configuration.
2. Add the desugaring dependency required by the plugin documentation.
3. Add Android 13 notification permission handling.
4. Add exact-alarm permissions only if changing from inexact scheduling to exact scheduling.
5. Keep the supplied implementation on `inexactAllowWhileIdle` unless exact timing is genuinely necessary.

HoloRead intentionally favors respectful approximate reminders over battery-expensive exact alarms.
