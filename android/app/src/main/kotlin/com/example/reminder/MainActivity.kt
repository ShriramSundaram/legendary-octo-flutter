package com.sundaram.germanreminder.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val feedback by lazy { LearningFeedback(this) }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "german_reminder/reminders")
            .setMethodCallHandler { call, result -> ReminderAlarms.handle(this, call, result) }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "german_reminder/learning_feedback")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "play" -> { feedback.play(call.argument<String>("event") ?: "tap",
                        call.argument<Boolean>("sounds") ?: false,
                        call.argument<Boolean>("spoken") ?: false); result.success(null) }
                    "stop" -> { feedback.stop(); result.success(null) }
                    else -> result.notImplemented()
                }
            }
    }
    override fun onResume() { super.onResume(); feedback.resume() }
    override fun onPause() { feedback.pause(); super.onPause() }
    override fun onDestroy() { feedback.close(); super.onDestroy() }
}
