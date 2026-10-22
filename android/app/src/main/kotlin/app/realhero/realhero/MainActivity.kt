package app.realhero.realhero

import android.content.ActivityNotFoundException
import android.content.Intent
import android.app.Activity
import android.util.Xml
import java.io.ByteArrayOutputStream
import java.io.StringReader
import org.json.JSONObject
import org.xmlpull.v1.XmlPullParser
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var fileResult: MethodChannel.Result? = null
    private var exportContent: String? = null
    private val openBackupRequest = 4101
    private val saveBackupRequest = 4102

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "realhero/actions")
            .setMethodCallHandler { call, result ->
                if (call.method == "openBackup" || call.method == "saveBackup") {
                    if (fileResult != null) {
                        result.error("FILE_BUSY", "Уже открыт выбор файла", null)
                        return@setMethodCallHandler
                    }
                    val saving = call.method == "saveBackup"
                    val content = call.argument<String>("content")
                    if (saving && content.isNullOrBlank()) {
                        result.error("EMPTY_BACKUP", "Нет сохранения", null)
                        return@setMethodCallHandler
                    }
                    val intent = Intent(if (saving) Intent.ACTION_CREATE_DOCUMENT else Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = if (saving) "application/json" else "*/*"
                        if (saving) putExtra(Intent.EXTRA_TITLE, "RealHero-history.json")
                    }
                    fileResult = result
                    exportContent = content
                    try {
                        startActivityForResult(intent, if (saving) saveBackupRequest else openBackupRequest)
                    } catch (_: ActivityNotFoundException) {
                        fileResult = null
                        exportContent = null
                        result.error("NO_FILE_PICKER", "Нет приложения для выбора файла", null)
                    }
                    return@setMethodCallHandler
                }
                if (call.method == "openUrl") {
                    val url = call.argument<String>("url") ?: ""
                    val uri = android.net.Uri.parse(url)
                    if (uri.scheme != "https" || uri.host.isNullOrBlank() || uri.userInfo != null) {
                        result.error("INVALID_URL", "Некорректная ссылка", null)
                        return@setMethodCallHandler
                    }
                    try {
                        startActivity(Intent(Intent.ACTION_VIEW, uri))
                        result.success(null)
                    } catch (_: ActivityNotFoundException) {
                        result.error("NO_BROWSER", "Нет браузера для открытия ссылки", null)
                    }
                    return@setMethodCallHandler
                }
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

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != openBackupRequest && requestCode != saveBackupRequest) return
        val result = fileResult ?: return
        val content = exportContent
        fileResult = null
        exportContent = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return
        }
        try {
            if (requestCode == saveBackupRequest) {
                requireNotNull(content)
                val stream = requireNotNull(contentResolver.openOutputStream(uri, "wt"))
                stream.use { it.write(content.toByteArray(Charsets.UTF_8)) }
                result.success(true)
            } else {
                val stream = requireNotNull(contentResolver.openInputStream(uri))
                val bytes = ByteArrayOutputStream()
                stream.use {
                    val buffer = ByteArray(8192)
                    while (true) {
                        val count = it.read(buffer)
                        if (count < 0) break
                        require(bytes.size() + count <= 16 * 1024 * 1024)
                        bytes.write(buffer, 0, count)
                    }
                }
                val text = bytes.toString("UTF-8").trimStart('\uFEFF', ' ', '\n', '\r', '\t')
                result.success(if (text.startsWith("<")) legacyBackup(text) else text)
            }
        } catch (_: Exception) {
            result.error("BACKUP_FILE_ERROR", "Не удалось обработать файл сохранения", null)
        }
    }

    private fun legacyBackup(text: String): String {
        require(!text.contains("<!DOCTYPE", ignoreCase = true) && !text.contains("<!ENTITY", ignoreCase = true))
        val allowed = setOf("flutter.realhero.snapshot.v1", "flutter.realhero.snapshot.backup.v1", "flutter.realhero.personal.v1")
        val preferences = JSONObject()
        val parser = Xml.newPullParser()
        parser.setInput(StringReader(text))
        require(parser.nextTag() == XmlPullParser.START_TAG && parser.name == "map")
        var event = parser.next()
        while (event != XmlPullParser.END_DOCUMENT) {
            if (event == XmlPullParser.START_TAG && parser.name == "string") {
                val name = parser.getAttributeValue(null, "name").orEmpty()
                if (name in allowed) {
                    require(!preferences.has(name))
                    preferences.put(name, parser.nextText())
                }
            }
            event = parser.next()
        }
        require(preferences.has("flutter.realhero.snapshot.v1") || preferences.has("flutter.realhero.snapshot.backup.v1"))
        return JSONObject().put("format", "realhero.backup").put("version", 1).put("preferences", preferences).toString()
    }
}

