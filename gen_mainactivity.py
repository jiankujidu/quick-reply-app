import os

path = r'C:\Users\Administrator\.qclaw\workspace\quick-reply-app\quick_reply_app\android\app\src\main\kotlin\com\quickreply\quick_reply_app\MainActivity.kt'

content = r'''package com.quickreply.quick_reply_app

import android.annotation.SuppressLint
import android.content.Intent
import android.graphics.PixelFormat
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.util.TypedValue

class MainActivity : FlutterActivity() {
    private val CHANNEL = "app.quickreply/overlay"
    private var overlayView: View? = null
    private var isPanelExpanded = false
    private var wm: WindowManager? = null
    private var msgTitle = ""
    private var msgContent = ""
    private var msgImages = listOf<String>()
    private var msgFiles = listOf<String>()
    private val handler = Handler(Looper.getMainLooper())
    // store positions as plain fields to avoid R.id dependency
    private var posX = 0
    private var posY = 200

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        wm = getSystemService(WINDOW_SERVICE) as WindowManager
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkPermission" -> result.success(Settings.canDrawOverlays(this))
                    "requestPermission" -> {
                        startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")))
                        result.success(true)
                    }
                    "showOverlay" -> {
                        msgTitle = call.argument<String>("title") ?: ""
                        msgContent = call.argument<String>("content") ?: ""
                        msgImages = call.argument<List<String>>("images") ?: listOf()
                        msgFiles = call.argument<List<String>>("files") ?: listOf()
                        showOverlay()
                        result.success(true)
                    }
                    "closeOverlay" -> { closeOverlay(); result.success(true) }
                    "updateOverlay" -> {
                        msgTitle = call.argument<String>("title") ?: ""
                        msgContent = call.argument<String>("content") ?: ""
                        msgImages = call.argument<List<String>>("images") ?: listOf()
                        msgFiles = call.argument<List<String>>("files") ?: listOf()
                        refreshPanel()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()

    // ===== Show / Close =====

    private fun showOverlay() {
        if (overlayView != null) { refreshPanel(); return }
        if (!Settings.canDrawOverlays(this)) return
        handler.post {
            try {
                val v = makeBubble()
                val p = bubbleParams()
                wm?.addView(v, p)
                overlayView = v
                isPanelExpanded = false
            } catch (e: Exception) { e.printStackTrace() }
        }
    }

    private fun closeOverlay() {
        handler.post {
            try { overlayView?.let { wm?.removeView(it) } } catch (_: Exception) {}
            overlayView = null; isPanelExpanded = false
        }
    }

    private fun refreshPanel() {
        handler.post {
            if (isPanelExpanded && overlayView != null) {
                try {
                    val tv = overlayView?.findViewWithTag<TextView>("content_text")
                    tv?.text = if (msgContent.length > 80) msgContent.substring(0, 80) + "\u2026" else msgContent
                    val tt = overlayView?.findViewWithTag<TextView>("title_text")
                    tt?.text = msgTitle
                } catch (_: Exception) {}
            }
        }
    }

    // ===== Bubble (collapsed) =====

    @SuppressLint("ClickableViewAccessibility")
    private fun makeBubbleView(): FrameLayout {
        val container = FrameLayout(this)
        val bubble = ImageView(this).apply {
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                colors = intArrayOf(0xFF2563EB.toInt(), 0xFF7C3AED.toInt())
                gradientType = GradientDrawable.LINEAR_GRADIENT
            }
            setImageResource(android.R.drawable.ic_menu_send)
            setColorFilter(Color.WHITE)
            setPadding(dp(10), dp(10), dp(10), dp(10))
            scaleType = ImageView.ScaleType.FIT_CENTER
        }
        val size = dp(48)
        container.addView(bubble, FrameLayout.LayoutParams(size, size, Gravity.CENTER))

        bubble.setOnClickListener { if (!isPanelExpanded) showPanel() }

        var itx = 0f; var ity = 0f; var drag = false
        bubble.setOnTouchListener { v, ev ->
            when (ev.action) {
                MotionEvent.ACTION_DOWN -> { itx = ev.rawX; ity = ev.rawY; drag = false }
                MotionEvent.ACTION_MOVE -> {
                    val dx = (ev.rawX - itx).toInt(); val dy = (ev.rawY - ity).toInt()
                    if (Math.abs(dx) > 10 || Math.abs(dy) > 10) {
                        drag = true
                        try {
                            val p = overlayView?.layoutParams as? WindowManager.LayoutParams
                            if (p != null) {
                                posX += dx; posY += dy
                                p.x = posX; p.y = posY
                                wm?.updateViewLayout(overlayView, p)
                            }
                        } catch (_: Exception) {}
                        itx = ev.rawX; ity = ev.rawY
                    }
                }
                MotionEvent.ACTION_UP -> { if (!drag) v.performClick() }
            }
            true
        }
        return container
    }

    // Alias for clarity
    private fun makeBubble() = makeBubbleView()

    private fun bubbleParams(): WindowManager.LayoutParams {
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE
        return WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            type, WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply { gravity = Gravity.TOP or Gravity.START; x = posX; y = posY }
    }

    // ===== Panel (expanded) =====

    @SuppressLint("ClickableViewAccessibility")
    private fun showPanel() {
        val old = overlayView ?: return
        try { wm?.removeView(old) } catch (_: Exception) {}
        handler.post {
            try {
                val panel = makePanel()
                val p = panelParams()
                wm?.addView(panel, p)
                overlayView = panel
                isPanelExpanded = true
            } catch (e: Exception) { e.printStackTrace() }
        }
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun makePanel(): LinearLayout {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            background = GradientDrawable().apply {
                setColor(Color.WHITE); cornerRadius = dp(16).toFloat()
            }
            elevation = dp(12).toFloat()
        }

        // --- Header ---
        val header = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            background = GradientDrawable().apply {
                colors = intArrayOf(0xFF2563EB.toInt(), 0xFF7C3AED.toInt())
                gradientType = GradientDrawable.LINEAR_GRADIENT
                cornerRadii = floatArrayOf(dp(15).toFloat(),dp(15).toFloat(),dp(15).toFloat(),dp(15).toFloat(),0f,0f,0f,0f)
            }
            setPadding(dp(14), dp(10), dp(8), dp(10))
        }

        header.addView(ImageView(this).apply {
            setImageResource(android.R.drawable.ic_menu_send); setColorFilter(Color.WHITE)
            layoutParams = LinearLayout.LayoutParams(dp(16), dp(16))
        })
        header.addView(TextView(this).apply {
            text = " 蹇洖澶?; setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        })
        // minimize button
        header.addView(TextView(this).apply {
            text = " \u2014 "; setTextColor(0xB0BEC5FF.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            setPadding(dp(8), 0, dp(4), 0)
            setOnClickListener { collapseToBubble() }
        })
        // close button
        header.addView(TextView(this).apply {
            text = " \u2715 "; setTextColor(0xB0BEC5FF.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            setPadding(dp(4),