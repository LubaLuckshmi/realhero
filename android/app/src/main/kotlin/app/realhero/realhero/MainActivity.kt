package app.realhero.realhero

import android.content.ActivityNotFoundException
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "realhero/actions")
            .setMethodCallHandler { call, result ->
                if (call.method != "shareText") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val text = call.argument<String>("text")?.trim()
                val title = call.argument<String>("title") ?: "Поделиться материалом"
                if (text.isNullOrEmpty()) {
                    result.error("EMPTY_TEXT", "В сообщении нет текста", null)
                    return@setMethodCallHandler
                }
                val intent = Intent(Intent.ACTION_SEND).apply {
                    type = "text/plain"
                    putExtra(Intent.EXTRA_TEXT, text)
                    putExtra(Intent.EXTRA_SUBJECT, title)
                }
                try {
                    startActivity(Intent.createChooser(intent, title))
                    // Only the chooser opening is confirmed. The app cannot know
                    // whether the user sent the text through the selected app.
                    result.success(null)
                } catch (error: ActivityNotFoundException) {
                    result.error("NO_SHARE_APP", "Нет приложения для отправки", null)
                }
            }
    }
}
