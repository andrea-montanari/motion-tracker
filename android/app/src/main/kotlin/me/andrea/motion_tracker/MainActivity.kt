package me.andrea.motion_tracker

import android.content.Intent
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {

    private val channelName = "me.andrea.motion_tracker/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "launchHumanoidAnimation" -> {
                    // Intent to launch the native activity
                    val intent = Intent(this, HumanoidAnimationActivity::class.java)
                    startActivity(intent)

                    // Optionally return a result to Flutter
                    result.success("Native activity closed")
                }
                "activateAnimation" -> {
                    val animationName = call.argument<String>("animationName")
                    val intent = Intent(this, HumanoidAnimationActivity::class.java).apply {
                        putExtra("animationName", animationName)
                    }
                    startActivity(intent)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

}
