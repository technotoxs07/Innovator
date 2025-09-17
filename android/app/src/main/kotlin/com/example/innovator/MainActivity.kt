package com.innovation.innovator

import android.app.KeyguardManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.innovation.innovator/call"
    private val NOTIFICATION_CHANNEL_ID = "incoming_calls"
    private var wakeLock: PowerManager.WakeLock? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Create notification channels
        createNotificationChannels()
        
        // Setup method channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "launchApp" -> {
                        launchAppForCall()
                        result.success(true)
                    }
                    "showCallScreen" -> {
                        showCallScreen()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
    
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            // Incoming calls channel
            val callChannel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Incoming Calls",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Incoming call notifications"
                enableLights(true)
                enableVibration(true)
                setShowBadge(true)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
                setBypassDnd(true)
            }
            notificationManager.createNotificationChannel(callChannel)
            
            // Chat messages channel
            val chatChannel = NotificationChannel(
                "chat_messages",
                "Chat Messages",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Chat message notifications"
                enableLights(true)
                enableVibration(true)
                setShowBadge(true)
            }
            notificationManager.createNotificationChannel(chatChannel)
            
            // General notifications channel
            val generalChannel = NotificationChannel(
                "general_notifications",
                "General Notifications",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "General app notifications"
            }
            notificationManager.createNotificationChannel(generalChannel)
        }
    }
    
    private fun launchAppForCall() {
        // Wake up the device
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.SCREEN_BRIGHT_WAKE_LOCK or 
            PowerManager.ACQUIRE_CAUSES_WAKEUP or
            PowerManager.ON_AFTER_RELEASE,
            "innovator:call"
        )
        wakeLock?.acquire(10000) // 10 seconds
        
        // Show on lock screen
        showCallScreen()
        
        // Bring app to foreground
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                   Intent.FLAG_ACTIVITY_CLEAR_TOP or
                   Intent.FLAG_ACTIVITY_SINGLE_TOP or
                   Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            action = "INCOMING_CALL"
        }
        startActivity(intent)
    }
    
    private fun showCallScreen() {
        runOnUiThread {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                setShowWhenLocked(true)
                setTurnScreenOn(true)
                val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
                keyguardManager.requestDismissKeyguard(this, null)
            } else {
                @Suppress("DEPRECATION")
                window.addFlags(
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                )
            }
        }
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Handle incoming call intent
        if (intent?.action == "INCOMING_CALL" || 
            intent?.action == "com.hiennv.flutter_callkit_incoming.ACTION_CALL_INCOMING") {
            showCallScreen()
        }
        
        handleNotificationClick(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleNotificationClick(intent)
    }
    
    private fun handleNotificationClick(intent: Intent?) {
        intent?.extras?.let { extras ->
            val type = extras.getString("type")
            val action = intent.action
            
            when {
                type == "call" -> showCallScreen()
                action == "com.hiennv.flutter_callkit_incoming.ACTION_CALL_ACCEPT" -> {
                    showCallScreen()
                    // Send event to Flutter
                    flutterEngine?.dartExecutor?.let {
                        MethodChannel(it.binaryMessenger, CHANNEL)
                            .invokeMethod("onCallAccepted", extras)
                    }
                }
                action == "com.hiennv.flutter_callkit_incoming.ACTION_CALL_DECLINE" -> {
                    // Send event to Flutter
                    flutterEngine?.dartExecutor?.let {
                        MethodChannel(it.binaryMessenger, CHANNEL)
                            .invokeMethod("onCallDeclined", extras)
                    }
                }
                else -> {
                    // No action needed or log for debugging
                }
            }
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        wakeLock?.release()
    }
}