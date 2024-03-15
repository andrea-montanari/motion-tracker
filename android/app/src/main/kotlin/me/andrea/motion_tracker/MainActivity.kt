package me.andrea.motion_tracker

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {

    private val channelName = "motion_tracker_channel";

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        var channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName);
        channel.setMethodCallHandler { call, result ->
            if (call.method == "launchHumanoidAnimation") {
                // Intent to launch the native activity
                val intent = Intent(this, HumanoidAnimationActivity::class.java);
                startActivity(intent);

                // Optionally return a result to Flutter
                result.success("Native activity launched");
            } else {
                result.notImplemented();
            }
        }
    }
}
