package com.example.frontend

import android.accessibilityservice.AccessibilityService
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.widget.ImageView
import android.widget.TextView
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class FrameCountAccessibilityService : AccessibilityService() {

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var layoutParams: WindowManager.LayoutParams? = null
    private var isOverlayAttached = false

    private var initialX = 0
    private var initialY = 0
    private var initialTouchX = 0f
    private var initialTouchY = 0f

    // Target Packages
    private val PKG_INSTAGRAM = "com.instagram.android"
    private val PKG_TIKTOK = "com.zhiliaoapp.musically"
    private val PKG_TIKTOK_ALT = "com.ss.android.ugc.trill"
    private val PKG_YOUTUBE = "com.google.android.youtube"

    // Safe package check
    private val TARGET_PACKAGES = setOf(
        PKG_INSTAGRAM,
        PKG_TIKTOK,
        PKG_TIKTOK_ALT,
        PKG_YOUTUBE
    )

    // Ignore transient system packages
    private val SYSTEM_PACKAGES = setOf(
        "com.android.systemui",
        "android",
        "com.google.android.inputmethod.latin",
        "com.samsung.android.honeyboard",
        "com.google.android.gms",
        "com.sec.android.inputmethod"
    )

    private val mainHandler = Handler(Looper.getMainLooper())
    private var hideRunnable: Runnable? = null

    // Scroll debounce
    private val DEBOUNCE_THRESHOLD_MS = 2000L
    private var lastScrollTimestamp = 0L
    private var currentActivePlatform: String? = null

    override fun onServiceConnected() {
        super.onServiceConnected()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        initOverlayView()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        val packageName = event.packageName?.toString() ?: return

        // 1. If event comes from system UI / keyboard, completely ignore it (do not touch overlay state)
        if (SYSTEM_PACKAGES.contains(packageName)) return

        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED,
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                handlePackageState(packageName)
            }
            AccessibilityEvent.TYPE_VIEW_SCROLLED -> {
                handleScrollEvent(packageName)
            }
        }
    }

    private fun handlePackageState(packageName: String) {
        if (TARGET_PACKAGES.contains(packageName)) {
            // User is inside a target video app! Keep or restore overlay immediately
            cancelPendingHide()
            val platform = when (packageName) {
                PKG_INSTAGRAM -> "reels"
                PKG_TIKTOK, PKG_TIKTOK_ALT -> "tiktok"
                PKG_YOUTUBE -> "shorts"
                else -> "reels"
            }
            currentActivePlatform = platform

            val color = when (platform) {
                "reels" -> Color.parseColor("#00FF66")
                "tiktok" -> Color.parseColor("#00E5FF")
                "shorts" -> Color.parseColor("#FF2A55")
                else -> Color.parseColor("#FFFFFF")
            }
            showOverlay(platform, color)
        } else {
            // User went to another app (e.g. Launcher, WhatsApp, Settings)
            // Verify current active window root before hiding
            scheduleHideOverlay()
        }
    }

    private fun cancelPendingHide() {
        hideRunnable?.let { mainHandler.removeCallbacks(it) }
        hideRunnable = null
    }

    private fun scheduleHideOverlay() {
        cancelPendingHide()
        hideRunnable = Runnable {
            // Check if top window is still one of our target apps before hiding
            val activeRootPkg = rootInActiveWindow?.packageName?.toString()
            if (activeRootPkg != null && TARGET_PACKAGES.contains(activeRootPkg)) {
                // User is still in the video app! Do not hide!
                return@Runnable
            }
            currentActivePlatform = null
            hideOverlay()
        }
        mainHandler.postDelayed(hideRunnable!!, 1500L) // 1.5 second buffer
    }

    private fun handleScrollEvent(packageName: String) {
        // If scroll happens in target app, ensure overlay is showing
        if (TARGET_PACKAGES.contains(packageName)) {
            cancelPendingHide()
            if (!isOverlayAttached) {
                handlePackageState(packageName)
            }
        }

        val platform = currentActivePlatform ?: return
        val isTarget = when (platform) {
            "reels" -> packageName == PKG_INSTAGRAM
            "tiktok" -> packageName == PKG_TIKTOK || packageName == PKG_TIKTOK_ALT
            "shorts" -> packageName == PKG_YOUTUBE
            else -> false
        }
        if (!isTarget) return

        val now = System.currentTimeMillis()
        if (now - lastScrollTimestamp > DEBOUNCE_THRESHOLD_MS) {
            lastScrollTimestamp = now
            val newCount = incrementDailyCount(platform)
            val color = when (platform) {
                "reels" -> Color.parseColor("#00FF66")
                "tiktok" -> Color.parseColor("#00E5FF")
                "shorts" -> Color.parseColor("#FF2A55")
                else -> Color.parseColor("#FFFFFF")
            }
            updateOverlayUI(newCount, platform, color)
        }
    }

    private fun initOverlayView() {
        if (overlayView != null) return
        val inflater = LayoutInflater.from(this)
        overlayView = inflater.inflate(R.layout.layout_floating_hud, null)

        layoutParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 35
            y = 260
        }

        setupDragListener()
    }

    private fun showOverlay(platformName: String, accentColor: Int) {
        if (overlayView == null) {
            initOverlayView()
        }

        val count = getDailyCount(platformName)
        updateOverlayUI(count, platformName, accentColor)

        if (!isOverlayAttached && overlayView != null && layoutParams != null) {
            try {
                windowManager?.addView(overlayView, layoutParams)
                isOverlayAttached = true
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun hideOverlay() {
        if (isOverlayAttached && overlayView != null) {
            try {
                windowManager?.removeView(overlayView)
                isOverlayAttached = false
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun updateOverlayUI(count: Int, platformLabel: String, accentColor: Int) {
        overlayView?.let { view ->
            val avatarImageView = view.findViewById<ImageView>(R.id.hud_character_avatar)
            val counterTextView = view.findViewById<TextView>(R.id.hud_counter_text)
            val labelTextView = view.findViewById<TextView>(R.id.hud_label)
            val moodView = view.findViewById<TextView>(R.id.hud_mood_text)

            counterTextView?.text = count.toString()
            labelTextView?.text = platformLabel.uppercase()
            labelTextView?.setTextColor(accentColor)

            // Dynamic 3D model avatar expression:
            // Happy winking 3D girl (< 30) vs Crying sad 3D girl (>= 30)
            if (count < 30) {
                avatarImageView?.setImageResource(R.drawable.ic_girl_happy)
                moodView?.text = "CHILL"
                moodView?.setTextColor(Color.parseColor("#00FF66"))
            } else {
                avatarImageView?.setImageResource(R.drawable.ic_girl_sad)
                moodView?.text = "SAD 😢"
                moodView?.setTextColor(Color.parseColor("#FF2A55"))
            }
        }
    }

    private fun setupDragListener() {
        overlayView?.setOnTouchListener { _, event ->
            val params = layoutParams ?: return@setOnTouchListener false
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = params.x
                    initialY = params.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    params.x = initialX + (event.rawX - initialTouchX).toInt()
                    params.y = initialY + (event.rawY - initialTouchY).toInt()
                    if (isOverlayAttached && overlayView != null) {
                        try {
                            windowManager?.updateViewLayout(overlayView, params)
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }
                    }
                    true
                }
                else -> false
            }
        }
    }

    private fun getTodayDateString(): String {
        return SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
    }

    private fun getDailyCount(platformKey: String): Int {
        val prefs = getSharedPreferences("framecount_stats", MODE_PRIVATE)
        val today = getTodayDateString()
        return prefs.getInt("${today}_$platformKey", 0)
    }

    private fun incrementDailyCount(platformKey: String): Int {
        val prefs = getSharedPreferences("framecount_stats", MODE_PRIVATE)
        val today = getTodayDateString()
        val current = prefs.getInt("${today}_$platformKey", 0) + 1
        val total = prefs.getInt("${today}_total", 0) + 1
        prefs.edit()
            .putInt("${today}_$platformKey", current)
            .putInt("${today}_total", total)
            .apply()
        return current
    }

    override fun onInterrupt() {
        hideOverlay()
    }

    override fun onDestroy() {
        super.onDestroy()
        hideOverlay()
    }
}
