package me.andrea.motion_tracker

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {

    private val channelName = "me.andrea.motion_tracker/native"
    private final val ANIMATION_ACTIVITY_REQUEST_CODE = 1
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "launchHumanoidAnimation" -> {
                    // Intent to launch the native activity
                    val intent = Intent(this, HumanoidAnimationActivity::class.java)
                    startActivityForResult(intent, ANIMATION_ACTIVITY_REQUEST_CODE)

                    pendingResult = result;
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


    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == ANIMATION_ACTIVITY_REQUEST_CODE) {
            val resultData = data?.getStringExtra("resultKey") ?: "No result"
            pendingResult?.success(resultData)
        }
    }

}
