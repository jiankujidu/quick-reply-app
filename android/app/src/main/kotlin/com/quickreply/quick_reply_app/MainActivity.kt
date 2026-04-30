package com.quickreply.quick_reply_app

import android.annotation.SuppressLint
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.database.Cursor
import android.graphics.Color
import android.graphics.PixelFormat
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.provider.CallLog
import android.text.Editable
import android.text.TextWatcher
import android.view.Gravity
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.HorizontalScrollView
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity : FlutterActivity() {
    private val CHANNEL = "app.quickreply/overlay"
    private var windowManager: WindowManager? = null
    private var bubbleView: View? = null
    private var panelView: View? = null
    private var isPanelShowing = false
    private var messages: List<Map<String, Any>> = emptyList()
    
    // 筛选状态
    private var selectedCategory: String? = null
    private var selectedLevel: String? = null  // null=全部, company, group, private
    private var searchQuery: String = ""
    private var searchEditText: EditText? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager

        // 处理从 Intent 传入的参数
        handleIntentExtras()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermission" -> result.success(checkOverlayPermission())
                "requestPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName")))
                    }
                    result.success(true)
                }
                "startBubble" -> {
                    @Suppress("UNCHECKED_CAST")
                    messages = (call.argument<List<Map<String, Any>>>("messages") as? List<Map<String, Any>>) ?: emptyList()
                    selectedCategory = null
                    selectedLevel = null
                    searchQuery = ""
                    result.success(showFloatingBubble())
                }
                "stopBubble" -> {
                    hideFloatingBubble()
                    result.success(true)
                }
                "updateMessages" -> {
                    @Suppress("UNCHECKED_CAST")
                    messages = (call.argument<List<Map<String, Any>>>("messages") as? List<Map<String, Any>>) ?: emptyList()
                    selectedCategory = null
                    selectedLevel = null
                    searchQuery = ""
                    if (isPanelShowing) rebuildPanel()
                    result.success(true)
                }
                "showOverlay" -> {
                    val title = call.argument<String>("title") ?: ""
                    val content = call.argument<String>("content") ?: ""
                    messages = listOf(mapOf("title" to title, "content" to content))
                    selectedCategory = null
                    selectedLevel = null
                    searchQuery = ""
                    result.success(showFloatingBubble())
                }
                "closeOverlay" -> {
                    hideFloatingBubble()
                    result.success(true)
                }
                "pickAndShareImage" -> {
                    // Flutter 调用图片选择器并分享
                    result.success(true)
                    // 实际逻辑由 Flutter 层处理
                }
                "pickAndShareFile" -> {
                    // Flutter 调用文件选择器并分享
                    result.success(true)
                    // 实际逻辑由 Flutter 层处理
                }
                "readCallLogs" -> {
                    // 读取手机通话记录
                    val logs = readDeviceCallLogs()
                    result.success(logs)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun checkOverlayPermission(): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) Settings.canDrawOverlays(this) else true

    private fun handleIntentExtras() {
        val route = intent?.getStringExtra("route")
        val action = intent?.getStringExtra("action")
        
        if (route == "/pick_image" && action == "share_direct") {
            // 通过 MethodChannel 通知 Flutter 打开图片选择器
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, CHANNEL).invokeMethod("pickAndShareImage", null)
            }
        } else if (route == "/pick_file" && action == "share_direct") {
            // 通过 MethodChannel 通知 Flutter 打开文件选择器
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, CHANNEL).invokeMethod("pickAndShareFile", null)
            }
        }
        
        // 清除 Intent 参数，避免重复处理
        intent?.removeExtra("route")
        intent?.removeExtra("action")
    }

    @SuppressLint("ClickableViewAccessibility", "InflateParams")
    private fun showFloatingBubble(): Boolean {
        if (!checkOverlayPermission()) return false
        if (bubbleView != null) return true

        val size = dpToPx(44)
        bubbleView = FrameLayout(this).apply {
            layoutParams = FrameLayout.LayoutParams(size, size)
            setBackgroundColor(0xFF2563EB.toInt())
            setPadding(dpToPx(4), dpToPx(4), dpToPx(4), dpToPx(4))
            val iv = ImageView(context).apply {
                setBackgroundResource(R.mipmap.ic_launcher)
                scaleType = ImageView.ScaleType.CENTER_CROP
            }
            addView(iv)
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else @Suppress("DEPRECATION") { WindowManager.LayoutParams.TYPE_PHONE },
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply { gravity = Gravity.TOP or Gravity.START; x = 0; y = 300 }

        windowManager?.addView(bubbleView, params)
        setupBubbleDrag(bubbleView!!, params)
        bubbleView?.setOnClickListener { if (!isPanelShowing) showPanel() }
        return true
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun setupBubbleDrag(view: View, params: WindowManager.LayoutParams) {
        var initialX = 0; var initialY = 0
        var tx = 0f; var ty = 0f; var lastClick = 0L
        view.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> { initialX = params.x; initialY = params.y; tx = event.rawX; ty = event.rawY; lastClick = System.currentTimeMillis(); true }
                MotionEvent.ACTION_MOVE -> { params.x = initialX + (event.rawX - tx).toInt(); params.y = initialY + (event.rawY - ty).toInt(); windowManager?.updateViewLayout(bubbleView, params); true }
                MotionEvent.ACTION_UP -> { if (System.currentTimeMillis() - lastClick < 200) view.performClick(); true }
                else -> false
            }
        }
    }

    @SuppressLint("InflateParams")
    private fun showPanel() {
        if (!checkOverlayPermission() || isPanelShowing) return
        isPanelShowing = true
        panelView = createPanelView()
        val params = WindowManager.LayoutParams(
            dpToPx(320),
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else @Suppress("DEPRECATION") { WindowManager.LayoutParams.TYPE_PHONE },
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,  // 改为可获取焦点以支持输入
            PixelFormat.TRANSLUCENT
        ).apply { gravity = Gravity.CENTER }
        windowManager?.addView(panelView, params)
    }

    private fun getFilteredMessages(): List<Map<String, Any>> {
        var filtered = messages
        
        // 按级别筛选
        if (selectedLevel != null) {
            filtered = filtered.filter { 
                (it["level"] as? String ?: "").lowercase() == selectedLevel 
            }
        }
        
        // 按分类筛选
        if (selectedCategory != null) {
            filtered = filtered.filter { 
                (it["category"] as? String ?: "") == selectedCategory 
            }
        }
        
        // 搜索过滤
        if (searchQuery.isNotBlank()) {
            val query = searchQuery.lowercase()
            filtered = filtered.filter {
                val title = (it["title"] as? String ?: "").lowercase()
                val content = (it["content"] as? String ?: "").lowercase()
                title.contains(query) || content.contains(query)
            }
        }
        
        return filtered
    }

    private fun getCategories(): List<String> =
        messages.mapNotNull { it["category"] as? String }.filter { it.isNotEmpty() }.distinct()

    private fun getCategoryColor(cat: String): Int = when (cat) {
        "欢迎语" -> 0xFF10B981.toInt()
        "咨询" -> 0xFFF59E0B.toInt()
        "售后" -> 0xFFEF4444.toInt()
        "活动" -> 0xFF8B5CF6.toInt()
        "常用" -> 0xFF2563EB.toInt()
        else -> 0xFF6B7280.toInt()
    }

    private fun getLevelColor(level: String?): Int = when (level) {
        "company" -> 0xFF3B82F6.toInt()
        "group" -> 0xFF10B981.toInt()
        "private" -> 0xFFF59E0B.toInt()
        else -> 0xFF6B7280.toInt()
    }

    private fun getLevelName(level: String?): String = when (level) {
        "company" -> "公司级"
        "group" -> "小组级"
        "private" -> "私人"
        else -> "全部"
    }

    @SuppressLint("InflateParams")
    private fun createPanelView(): View {
        val filtered = getFilteredMessages()
        val categories = getCategories()

        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(0xFFFFFFFF.toInt())
            setPadding(dpToPx(10), dpToPx(10), dpToPx(10), dpToPx(10))
        }

        // 标题栏
        val header = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
        }
        header.addView(TextView(this).apply {
            text = "💬 快回复"
            textSize = 15f
            setTextColor(0xFF1E293B.toInt())
            setTextColor(0xFF1E293B.toInt())
            setTypeface(null, android.graphics.Typeface.BOLD)
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        })
        header.addView(TextView(this).apply {
            text = "✕"
            textSize = 20f
            setPadding(dpToPx(8), 0, 0, 0)
            setOnClickListener { hidePanel() }
        })
        container.addView(header)

        // 搜索框
        val searchContainer = FrameLayout(this).apply {
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply {
                setMargins(0, dpToPx(8), 0, dpToPx(6))
            }
            setBackgroundColor(0xFFF1F5F9.toInt())
            setPadding(dpToPx(12), dpToPx(8), dpToPx(12), dpToPx(8))
        }
        searchEditText = EditText(this).apply {
            hint = "🔍 搜索话术..."
            textSize = 13f
            setTextColor(0xFF1E293B.toInt())
            setHintTextColor(0xFF94A3B8.toInt())
            background = null
            layoutParams = FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.WRAP_CONTENT)
            imeOptions = EditorInfo.IME_ACTION_SEARCH
            setOnEditorActionListener { _, actionId, _ ->
                if (actionId == EditorInfo.IME_ACTION_SEARCH) {
                    hideKeyboard()
                    true
                } else false
            }
            addTextChangedListener(object : TextWatcher {
                override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
                override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
                override fun afterTextChanged(s: Editable?) {
                    searchQuery = s?.toString() ?: ""
                    rebuildPanel()
                }
            })
        }
        searchContainer.addView(searchEditText)
        container.addView(searchContainer)

        // 级别筛选栏
        val levelRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply {
                setMargins(0, 0, 0, dpToPx(4))
            }
        }
        listOf(null to "全部", "company" to "🏢公司", "group" to "👥小组", "private" to "👤我的").forEach { (level, label) ->
            levelRow.addView(makeLevelChip(label, level))
        }
        container.addView(HorizontalScrollView(this).apply {
            isHorizontalScrollBarEnabled = false
            addView(levelRow)
        })

        // 分类筛选栏
        if (categories.isNotEmpty()) {
            val chipsRow = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
            }
            chipsRow.addView(makeChip("全部", null))
            categories.forEach { chipsRow.addView(makeChip(it, it)) }
            container.addView(HorizontalScrollView(this).apply {
                isHorizontalScrollBarEnabled = false
                addView(chipsRow)
            })
        }

        // 列表
        container.addView(ScrollView(this).apply {
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dpToPx(260))
            addView(LinearLayout(this.context).apply {
                orientation = LinearLayout.VERTICAL
                if (filtered.isEmpty()) {
                    addView(TextView(context).apply { 
                        text = if (searchQuery.isNotBlank()) "未找到匹配话术" else "暂无话术"
                        textSize = 12f
                        gravity = Gravity.CENTER
                        setPadding(0, dpToPx(20), 0, dpToPx(20))
                        setTextColor(0xFF94A3B8.toInt())
                    })
                } else {
                    filtered.forEach { addView(makeMessageItem(it)) }
                }
            })
        })

        // 底部按钮栏
        val footer = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply {
                setMargins(0, dpToPx(8), 0, 0)
            }
        }
        footer.addView(makeButton("📷 图片") {
            // 直接上传图片分享
            pickAndShareImage()
        })
        footer.addView(makeButton("📎 文件") {
            // 直接上传文件分享
            pickAndShareFile()
        })
        footer.addView(makeButton("➕ 新建") {
            // 跳转到Flutter新建话术页面
            openFlutterEditor()
        })
        container.addView(footer)

        // 底部提示
        container.addView(TextView(this).apply {
            text = "点击话术复制/分享 · 共${messages.size}条"
            textSize = 10f
            setTextColor(0xFF9CA3AF.toInt())
            gravity = Gravity.CENTER
            setPadding(0, dpToPx(4), 0, 0)
        })

        return container
    }

    private fun makeLevelChip(name: String, value: String?): View {
        val sel = value == selectedLevel
        return TextView(this).apply {
            text = name
            textSize = 11f
            setPadding(dpToPx(10), dpToPx(4), dpToPx(10), dpToPx(4))
            setTextColor(if (sel) Color.WHITE else 0xFF64748B.toInt())
            try {
                background = android.graphics.drawable.GradientDrawable().apply {
                    setColor(if (sel) getLevelColor(value) else 0xFFF1F5F9.toInt())
                    cornerRadius = dpToPx(12).toFloat()
                }
            } catch (_: Exception) {}
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply { 
                marginEnd = dpToPx(6) 
            }
            setOnClickListener { 
                selectedLevel = if (sel) null else value
                searchQuery = ""
                searchEditText?.setText("")
                rebuildPanel() 
            }
        }
    }

    private fun makeChip(name: String, value: String?): View {
        val sel = value == selectedCategory
        return TextView(this).apply {
            text = name
            textSize = 11f
            setPadding(dpToPx(8), dpToPx(3), dpToPx(8), dpToPx(3))
            val color = when {
                value == null && sel -> 0xFF2563EB.toInt()
                sel -> getCategoryColor(value!!)
                else -> 0xFFF1F5F9.toInt()
            }
            setTextColor(if (sel) Color.WHITE else 0xFF64748B.toInt())
            try {
                background = android.graphics.drawable.GradientDrawable().apply {
                    setColor(color)
                    cornerRadius = dpToPx(12).toFloat()
                }
            } catch (_: Exception) {}
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply { marginEnd = dpToPx(5) }
            setOnClickListener { 
                selectedCategory = if (sel) null else value
                rebuildPanel() 
            }
        }
    }

    private fun makeButton(text: String, onClick: () -> Unit): View {
        return TextView(this).apply {
            this.text = text
            textSize = 12f
            setTextColor(Color.WHITE)
            setPadding(dpToPx(16), dpToPx(8), dpToPx(16), dpToPx(8))
            gravity = Gravity.CENTER
            try {
                background = android.graphics.drawable.GradientDrawable().apply {
                    setColor(0xFF2563EB.toInt())
                    cornerRadius = dpToPx(8).toFloat()
                }
            } catch (_: Exception) {}
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            setOnClickListener { onClick() }
        }
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun makeMessageItem(msg: Map<String, Any>): View {
        val title = msg["title"] as? String ?: ""
        val content = msg["content"] as? String ?: ""
        val category = msg["category"] as? String ?: ""
        val level = msg["level"] as? String ?: ""
        val catColor = getCategoryColor(category)
        
        // 解析附件
        val images = parsePaths(msg["images"])
        val files = parsePaths(msg["files"])
        val hasAttachments = images.isNotEmpty() || files.isNotEmpty()
        
        // 构建附件指示文本
        val attachmentIndicator = buildString {
            if (images.isNotEmpty()) append("📷${images.size} ")
            if (files.isNotEmpty()) append("📎${files.size} ")
        }.trim()

        return LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dpToPx(6), dpToPx(5), dpToPx(6), dpToPx(5))
            setBackgroundColor(0xFFF8FAFC.toInt())
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply { setMargins(0, 0, 0, dpToPx(3)) }

            // 标题行
            val row = LinearLayout(context).apply { orientation = LinearLayout.HORIZONTAL; setPadding(dpToPx(4), 0, 0, 0) }
            row.addView(View(context).apply {
                layoutParams = LinearLayout.LayoutParams(dpToPx(3), dpToPx(24)).apply { marginEnd = dpToPx(5) }
                setBackgroundColor(catColor)
            })
            row.addView(TextView(context).apply {
                text = title
                textSize = 12f
                setTextColor(0xFF1E293B.toInt())
                maxLines = 1
                ellipsize = android.text.TextUtils.TruncateAt.END
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            })
            // 附件图标
            if (hasAttachments) {
                row.addView(TextView(context).apply {
                    text = attachmentIndicator
                    textSize = 10f
                    setTextColor(0xFF6B7280.toInt())
                    setPadding(0, 0, dpToPx(4), 0)
                })
            }
            // 级别标签
            if (level.isNotEmpty()) {
                row.addView(TextView(context).apply {
                    text = getLevelName(level)
                    textSize = 9f
                    setTextColor(Color.WHITE)
                    setPadding(dpToPx(4), dpToPx(1), dpToPx(4), dpToPx(1))
                    try {
                        background = android.graphics.drawable.GradientDrawable().apply { 
                            setColor(getLevelColor(level))
                            cornerRadius = dpToPx(6).toFloat() 
                        }
                    } catch (_: Exception) {}
                })
            }
            // 分类标签
            if (category.isNotEmpty()) {
                row.addView(TextView(context).apply {
                    text = category
                    textSize = 10f
                    setTextColor(Color.WHITE)
                    setPadding(dpToPx(4), dpToPx(1), dpToPx(4), dpToPx(1))
                    try {
                        background = android.graphics.drawable.GradientDrawable().apply { 
                            setColor(catColor)
                            cornerRadius = dpToPx(8).toFloat() 
                        }
                    } catch (_: Exception) {}
                })
            }
            addView(row)

            // 内容预览
            val contentPreview = if (content.length > 60) content.take(60) + "…" else content
            addView(TextView(context).apply {
                text = contentPreview
                textSize = 11f
                setTextColor(0xFF64748B.toInt())
                setPadding(dpToPx(7), dpToPx(2), dpToPx(4), 0)
            })

            // 点击事件：有附件→分享，纯文本→复制
            setOnClickListener {
                if (hasAttachments) {
                    shareMessage(title, content, images, files)
                } else {
                    copyToClipboard(title, content)
                }
            }
        }
    }

    private fun parsePaths(value: Any?): List<String> {
        val pathStr = when (value) {
            is String -> value
            is List<*> -> value.joinToString(",") { it.toString() }
            else -> return emptyList()
        }
        if (pathStr.isBlank()) return emptyList()
        
        // Flutter的getApplicationDocumentsDirectory()返回的是app_flutter目录
        val appDir = File(filesDir, "app_flutter").absolutePath
        android.util.Log.d("ShareDebug", "原始路径字符串: $pathStr")
        android.util.Log.d("ShareDebug", "App目录: $appDir")
        
        val result = pathStr.split(",")
            .map { it.trim() }
            .filter { it.isNotEmpty() }
            .map { path ->
                val converted = when {
                    // 已经是绝对路径，直接使用
                    path.startsWith("/") -> path
                    // attachments/xxx 格式，拼接app_flutter
                    path.startsWith("attachments/") -> "$appDir/$path"
                    // file://协议，移除前缀
                    path.startsWith("file://") -> path.removePrefix("file://")
                    // 其他相对路径，拼接app_flutter/attachments/
                    else -> "$appDir/attachments/${path.substringAfterLast("/")}"
                }
                android.util.Log.d("ShareDebug", "路径转换: $path -> $converted")
                converted
            }
        android.util.Log.d("ShareDebug", "解析结果: ${result.size} 个路径")
        return result
    }

    private fun shareMessage(title: String, content: String, images: List<String>, files: List<String>) {
        try {
            android.util.Log.d("ShareDebug", "=== 开始分享 ===")
            android.util.Log.d("ShareDebug", "标题: $title")
            android.util.Log.d("ShareDebug", "内容长度: ${content.length}")
            android.util.Log.d("ShareDebug", "图片路径数: ${images.size}")
            android.util.Log.d("ShareDebug", "文件路径数: ${files.size}")
            
            val allPaths = images + files
            android.util.Log.d("ShareDebug", "总路径数: ${allPaths.size}")
            
            val existingUris = mutableListOf<Uri>()
            
            for ((index, path) in allPaths.withIndex()) {
                android.util.Log.d("ShareDebug", "路径[$index]: $path")
                val file = File(path)
                android.util.Log.d("ShareDebug", "  文件存在: ${file.exists()}, 大小: ${if (file.exists()) file.length() else 0}")
                if (file.exists()) {
                    try {
                        val uri = FileProvider.getUriForFile(this, "${packageName}.fileprovider", file)
                        android.util.Log.d("ShareDebug", "  URI: $uri")
                        existingUris.add(uri)
                    } catch (e: Exception) {
                        android.util.Log.e("ShareDebug", "  FileProvider失败: ${e.message}")
                    }
                }
            }
            
            android.util.Log.d("ShareDebug", "有效URI数: ${existingUris.size}")
            
            // 优先处理附件
            if (existingUris.isNotEmpty()) {
                // 有附件：发送文件+图片，同时将文字复制到剪贴板
                val intent = when {
                    existingUris.size == 1 -> Intent(Intent.ACTION_SEND).apply {
                        type = getMimeType(existingUris[0])
                        putExtra(Intent.EXTRA_STREAM, existingUris[0])
                        // 尝试同时发送文字（部分应用支持）
                        if (content.isNotBlank()) putExtra(Intent.EXTRA_TEXT, content)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                    else -> Intent(Intent.ACTION_SEND_MULTIPLE).apply {
                        type = getCommonMimeType(existingUris)
                        putParcelableArrayListExtra(Intent.EXTRA_STREAM, ArrayList(existingUris))
                        // 尝试同时发送文字（部分应用支持）
                        if (content.isNotBlank()) putExtra(Intent.EXTRA_TEXT, content)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                }
                
                intent.putExtra(Intent.EXTRA_SUBJECT, title)
                intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                
                // 同时复制文字到剪贴板（确保不丢失）
                if (content.isNotBlank()) {
                    (getSystemService(CLIPBOARD_SERVICE) as ClipboardManager)
                        .setPrimaryClip(ClipData.newPlainText(title, content))
                }
                
                android.util.Log.d("ShareDebug", "Intent类型: ${intent.action}, MIME: ${intent.type}")
                
                val chooser = Intent.createChooser(intent, "分享到...")
                chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                
                startActivity(chooser)
                Toast.makeText(this, "文件已分享，文字已复制可粘贴", Toast.LENGTH_SHORT).show()
                hidePanel()
                
            } else {
                // 无附件：纯文本分享
                val intent = Intent(Intent.ACTION_SEND).apply {
                    type = "text/plain"
                    putExtra(Intent.EXTRA_TEXT, if (content.isNotBlank()) content else title)
                    putExtra(Intent.EXTRA_SUBJECT, title)
                }
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                
                val chooser = Intent.createChooser(intent, "分享到...")
                chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                
                startActivity(chooser)
                Toast.makeText(this, "分享: $title", Toast.LENGTH_SHORT).show()
                hidePanel()
            }
            
        } catch (e: Exception) {
            android.util.Log.e("ShareDebug", "分享失败: ${e.message}", e)
            Toast.makeText(this, "分享失败: ${e.message}", Toast.LENGTH_LONG).show()
        }
    }
    
    private fun getMimeType(uri: Uri): String {
        val path = uri.path ?: return "*/*"
        return when (path.substringAfterLast(".").lowercase()) {
            "jpg", "jpeg" -> "image/jpeg"
            "png" -> "image/png"
            "gif" -> "image/gif"
            "webp" -> "image/webp"
            "pdf" -> "application/pdf"
            "doc" -> "application/msword"
            "docx" -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            "xls" -> "application/vnd.ms-excel"
            "xlsx" -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            else -> "*/*"
        }
    }
    
    private fun getCommonMimeType(uris: List<Uri>): String {
        val mimeTypes = uris.map { getMimeType(it) }.distinct()
        if (mimeTypes.all { it.startsWith("image/") }) return "image/*"
        if (mimeTypes.all { it.startsWith("video/") }) return "video/*"
        return "*/*"
    }

    private fun rebuildPanel() {
        panelView?.let { old ->
            val p = old.layoutParams as? WindowManager.LayoutParams
            windowManager?.removeView(old)
            panelView = createPanelView()
            p?.let { windowManager?.addView(panelView, it) }
        }
    }

    private fun hidePanel() {
        panelView?.let { windowManager?.removeView(it); panelView = null; isPanelShowing = false }
        searchEditText = null
    }

    private fun hideFloatingBubble() {
        hidePanel()
        bubbleView?.let { windowManager?.removeView(it); bubbleView = null }
    }

    private fun copyToClipboard(title: String, content: String) {
        (getSystemService(CLIPBOARD_SERVICE) as ClipboardManager).setPrimaryClip(ClipData.newPlainText(title, content))
        Toast.makeText(this, "已复制: $title", Toast.LENGTH_SHORT).show()
        hidePanel()
    }

    private fun openFlutterEditor() {
        // 关闭悬浮窗
        hidePanel()
        
        // 通过 Intent 打开 Flutter 应用的编辑页面
        // 使用 MethodChannel 通知 Flutter 跳转
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            putExtra("route", "/editor")
            putExtra("action", "new")
        }
        startActivity(intent)
    }
    
    private fun pickAndShareImage() {
        try {
            // 通知 Flutter 打开图片选择器
            val intent = Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                putExtra("route", "/pick_image")
                putExtra("action", "share_direct")
            }
            startActivity(intent)
            hidePanel()
        } catch (e: Exception) {
            Toast.makeText(this, "无法打开图片选择器", Toast.LENGTH_SHORT).show()
        }
    }
    
    private fun pickAndShareFile() {
        try {
            // 通知 Flutter 打开文件选择器
            val intent = Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                putExtra("route", "/pick_file")
                putExtra("action", "share_direct")
            }
            startActivity(intent)
            hidePanel()
        } catch (e: Exception) {
            Toast.makeText(this, "无法打开文件选择器", Toast.LENGTH_SHORT).show()
        }
    }

    private fun hideKeyboard() {
        searchEditText?.let {
            val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
            imm.hideSoftInputFromWindow(it.windowToken, 0)
        }
    }

    private fun dpToPx(dp: Int) = (dp * resources.displayMetrics.density).toInt()

    private fun readDeviceCallLogs(): List<Map<String, Any>> {
        val logs = mutableListOf<Map<String, Any>>()
        try {
            // 检查权限
            if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.READ_CALL_LOG) != PackageManager.PERMISSION_GRANTED) {
                return listOf(mapOf("error" to "NO_PERMISSION"))
            }
            
            // 查询通话记录，按时间倒序
            val cursor: Cursor? = contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                arrayOf(
                    CallLog.Calls.NUMBER,
                    CallLog.Calls.CACHED_NAME,
                    CallLog.Calls.DATE,
                    CallLog.Calls.DURATION,
                    CallLog.Calls.TYPE
                ),
                null,
                null,
                "${CallLog.Calls.DATE} DESC"
            )
            
            cursor?.use {
                val numberIdx = it.getColumnIndex(CallLog.Calls.NUMBER)
                val nameIdx = it.getColumnIndex(CallLog.Calls.CACHED_NAME)
                val dateIdx = it.getColumnIndex(CallLog.Calls.DATE)
                val durationIdx = it.getColumnIndex(CallLog.Calls.DURATION)
                val typeIdx = it.getColumnIndex(CallLog.Calls.TYPE)
                
                while (it.moveToNext()) {
                    val number = it.getString(numberIdx) ?: continue
                    val name = it.getString(nameIdx) ?: number
                    val date = it.getLong(dateIdx)
                    val duration = it.getInt(durationIdx)
                    val type = it.getInt(typeIdx)
                    
                    val callType = when (type) {
                        CallLog.Calls.INCOMING_TYPE -> "incoming"
                        CallLog.Calls.OUTGOING_TYPE -> "outgoing"
                        CallLog.Calls.MISSED_TYPE -> "missed"
                        else -> "unknown"
                    }
                    
                    logs.add(mapOf(
                        "phoneNumber" to number,
                        "contactName" to name,
                        "startTime" to date,
                        "durationSeconds" to duration,
                        "callType" to callType
                    ))
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("CallLog", "读取失败: ${e.message}")
            return listOf(mapOf("error" to e.message.toString()))
        }
        return logs
    }

    override fun onDestroy() {
        super.onDestroy()
        hideFloatingBubble()
    }
}
