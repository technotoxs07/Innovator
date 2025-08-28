// Enhanced main.dart - COMPLETE BACKGROUND CALL HANDLING

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/firebase_options.dart';
import 'package:innovator/screens/Call/Incoming_Call_screen.dart';
import 'package:innovator/screens/Feed/Services/Feed_Cache_service.dart';
import 'package:innovator/screens/Feed/VideoPlayer/videoplayerpackage.dart';
import 'package:innovator/screens/Feed/Video_Feed.dart';
import 'package:innovator/screens/Shop/CardIconWidget/cart_state_manager.dart';
import 'package:innovator/screens/Shop/Shop_Page.dart';
import 'package:innovator/screens/Splash_Screen/splash_screen.dart';
import 'package:innovator/controllers/user_controller.dart';
import 'package:innovator/screens/chatApp/Add_to_Chat.dart';
import 'package:innovator/screens/chatApp/FollowStatusManager.dart';
import 'package:innovator/screens/chatApp/SearchchatUser.dart';
import 'package:innovator/screens/chatApp/chat_homepage.dart';
import 'package:innovator/screens/chatApp/chatlistpage.dart';
import 'package:innovator/screens/chatApp/chatscreen.dart';
import 'package:innovator/screens/chatApp/controller/chat_controller.dart';
import 'package:innovator/screens/chatApp/widgets/call_floating_widget.dart';
import 'package:innovator/services/Firebase_Messaging.dart';
import 'package:innovator/services/Notification_Like.dart';
import 'package:innovator/services/background_call_service.dart';
import 'package:innovator/services/call_permission_service.dart';
import 'package:innovator/services/fcm_handler.dart';
import 'package:innovator/services/webrtc_call_service.dart';
import 'package:innovator/utils/Drawer/drawer_cache_manager.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:developer' as developer;

// Global variables and constants
late Size mq;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
bool _isAppOnline = false;

// CRITICAL: Global notification plugin for background use
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

// Global timers for emergency sound/vibration
Timer? _emergencyRingtoneTimer;
Timer? _emergencyVibrationTimer;
bool _isEmergencyRinging = false;

// ENHANCED: Background message handler with GUARANTEED call ringing
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    developer.log('🔥 === BACKGROUND MESSAGE HANDLER START ===');
    developer.log('🔥 Message ID: ${message.messageId}');
    developer.log('🔥 Data: ${message.data}');
    developer.log('🔥 Notification: ${message.notification?.toMap()}');
    developer.log('🔥 Time: ${DateTime.now()}');
    
    // CRITICAL: Initialize Firebase if not already done
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      developer.log('🔥 Firebase initialized in background');
    }
    
    // Initialize local notifications for background
    await _initializeBackgroundNotifications();
    
    // Get message type
    final messageType = message.data['type']?.toString() ?? '';
    developer.log('🔥 Message type: $messageType');

    if (messageType == 'call') {
      // ONLY show notification - let notification handle sound
      await _showFullScreenCallNotification(
        callId: message.data['callId'] ?? '',
        callerName: message.data['callerName'] ?? 'Unknown',
        isVideoCall: message.data['isVideoCall'] == 'true',
        data: message.data,
      );
    }
    
    switch (messageType) {
      case 'call':
        await _handleBackgroundCallWithGuaranteedRinging(message);
        break;
      case 'chat':
      case 'message':
        await _handleBackgroundChatMessage(message);
        break;
      default:
        await _showBackgroundNotification(message);
        break;
    }
    
    developer.log('✅ Background message processed successfully');
    developer.log('🔥 === BACKGROUND MESSAGE HANDLER END ===');
  } catch (e) {
    developer.log('❌ CRITICAL: Background handler error: $e');
    developer.log('❌ Stack trace: ${StackTrace.current}');
    
    // Still try to show basic notification
    await _showEmergencyCallNotification(message);
  }
}

// CRITICAL: Handle background calls with GUARANTEED ringing
Future<void> _handleBackgroundCallWithGuaranteedRinging(RemoteMessage message) async {
  try {
    developer.log('📞 === BACKGROUND CALL WITH GUARANTEED RINGING ===');
    
    final data = message.data;
    final callId = data['callId']?.toString() ?? '';
    final callerName = data['callerName']?.toString() ?? 'Unknown Caller';
    final callerId = data['callerId']?.toString() ?? '';
    final receiverId = data['receiverId']?.toString() ?? '';
    final isVideoCall = data['isVideoCall']?.toString() == 'true';
    
    developer.log('📞 Call Details:');
    developer.log('   - ID: $callId');
    developer.log('   - Caller: $callerName');
    developer.log('   - Caller ID: $callerId');
    developer.log('   - Receiver ID: $receiverId');
    developer.log('   - Video: $isVideoCall');
    
    // STEP 1: Enable wakelock immediately
    await WakelockPlus.enable();
    developer.log('📞 Wakelock enabled');
    
    // STEP 2: Start emergency ringtone immediately (MULTIPLE METHODS)
    await _startMultiMethodRingtone();
    developer.log('📞 Multi-method ringtone started');
    
    // STEP 3: Start emergency vibration immediately  
    await _startEmergencyVibration();
    developer.log('📞 Emergency vibration started');
    
    // STEP 4: Show full-screen notification with HIGHEST priority
    await _showFullScreenCallNotification(
      callId: callId,
      callerName: callerName,
      isVideoCall: isVideoCall,
      data: data,
    );
    developer.log('📞 Full-screen notification shown');
    
    // STEP 5: Use enhanced background service (if available)
    try {
      // Only try if service is available
      await EnhancedBackgroundCallService.handleBackgroundCall(data);
      developer.log('📞 Enhanced background service started');
    } catch (e) {
      developer.log('⚠️ Enhanced service not available, continuing with basic: $e');
    }
    
    // STEP 6: Auto-stop after 45 seconds (WhatsApp-style)
    Timer(const Duration(seconds: 45), () async {
      await _stopAllEmergencyAlerts();
      developer.log('📞 Auto-stopped after timeout');
    });
    
    developer.log('✅ Background call handling completed successfully');
    
  } catch (e) {
    developer.log('❌ CRITICAL: Background call handling failed: $e');
    // Emergency fallback
    await _showEmergencyCallNotification(message);
  }
}

// MULTI-METHOD: Start ringtone with ALL possible methods
Future<void> _startMultiMethodRingtone() async {
  if (_isEmergencyRinging) return; // Prevent double-start
  
  _isEmergencyRinging = true;
  developer.log('🔔 Starting MULTI-METHOD ringtone...');
  
  // Method 1: Flutter Ringtone Player (Primary)
  try {
    await FlutterRingtonePlayer().playRingtone(
      looping: true,
      volume: 1.0,
      asAlarm: false,
    );
    developer.log('✅ Method 1: FlutterRingtonePlayer started');
  } catch (e) {
    developer.log('⚠️ Method 1 failed: $e');
  }
  
  // Method 2: System sound loop (Backup)
  try {
    _startSystemSoundLoop();
    developer.log('✅ Method 2: System sound loop started');
  } catch (e) {
    developer.log('⚠️ Method 2 failed: $e');
  }
  
  // Method 3: Haptic feedback loop (Additional)
  try {
    _startHapticFeedbackLoop();
    developer.log('✅ Method 3: Haptic feedback loop started');
  } catch (e) {
    developer.log('⚠️ Method 3 failed: $e');
  }
  
  // Method 4: Audio notification (Last resort)
  try {
    _playNotificationSound();
    developer.log('✅ Method 4: Notification sound started');
  } catch (e) {
    developer.log('⚠️ Method 4 failed: $e');
  }
}

// System sound loop as primary backup
void _startSystemSoundLoop() {
  _emergencyRingtoneTimer?.cancel();
  _emergencyRingtoneTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
    try {
      if (_isEmergencyRinging) {
        SystemSound.play(SystemSoundType.click);
        
        // Stop after 45 seconds
        if (timer.tick >= 37) { // 37 * 1.2 seconds ≈ 45 seconds
          timer.cancel();
          _isEmergencyRinging = false;
        }
      } else {
        timer.cancel();
      }
    } catch (e) {
      timer.cancel();
      _isEmergencyRinging = false;
    }
  });
}

// Haptic feedback loop for additional alert
void _startHapticFeedbackLoop() {
  Timer.periodic(const Duration(milliseconds: 800), (timer) {
    try {
      if (_isEmergencyRinging) {
        HapticFeedback.heavyImpact();
        
        if (timer.tick >= 56) { // 56 * 0.8 seconds ≈ 45 seconds
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    } catch (e) {
      timer.cancel();
    }
  });
}

// Play notification sound as additional method
void _playNotificationSound() {
  Timer.periodic(const Duration(milliseconds: 2000), (timer) {
    try {
      if (_isEmergencyRinging) {
        // This will trigger the system notification sound
        SystemSound.play(SystemSoundType.alert);
        
        if (timer.tick >= 22) { // 22 * 2 seconds ≈ 45 seconds
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    } catch (e) {
      timer.cancel();
    }
  });
}

// EMERGENCY: Start vibration with persistent pattern
Future<void> _startEmergencyVibration() async {
  try {
    developer.log('📳 Starting emergency vibration...');
    
    // Check if device supports vibration
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != true) {
      developer.log('📳 Device does not support vibration');
      return;
    }
    
    // Start repeating vibration pattern (WhatsApp-style)
    _emergencyVibrationTimer?.cancel();
    _emergencyVibrationTimer = Timer.periodic(const Duration(milliseconds: 2000), (timer) async {
      try {
        if (_isEmergencyRinging) {
          await Vibration.vibrate(
            pattern: [0, 1000, 300, 1000, 300, 1000], // Strong, varied pattern
            intensities: [0, 255, 0, 255, 0, 255],
          );
          
          // Stop after 45 seconds
          if (timer.tick >= 22) { // 22 * 2 seconds ≈ 45 seconds
            timer.cancel();
          }
        } else {
          timer.cancel();
        }
      } catch (e) {
        timer.cancel();
      }
    });
    
    developer.log('✅ Emergency vibration started');
    
  } catch (e) {
    developer.log('❌ Emergency vibration failed: $e');
  }
}

// Stop all emergency alerts
Future<void> _stopAllEmergencyAlerts() async {
  try {
    _isEmergencyRinging = false;
    
    // Stop ringtone
    try {
      await FlutterRingtonePlayer().stop();
    } catch (e) {
      developer.log('Warning: Error stopping ringtone: $e');
    }
    
    // Stop timers
    _emergencyRingtoneTimer?.cancel();
    _emergencyVibrationTimer?.cancel();
    
    // Stop vibration
    try {
      await Vibration.cancel();
    } catch (e) {
      developer.log('Warning: Error stopping vibration: $e');
    }
    
    // Disable wakelock
    try {
      await WakelockPlus.disable();
    } catch (e) {
      developer.log('Warning: Error disabling wakelock: $e');
    }
    
    developer.log('🔇 All emergency alerts stopped');
  } catch (e) {
    developer.log('❌ Error stopping emergency alerts: $e');
  }
}

// CRITICAL: Show full-screen call notification with MAXIMUM priority
Future<void> _showFullScreenCallNotification({
  required String callId,
  required String callerName,
  required bool isVideoCall,
  required Map<String, dynamic> data,
}) async {
  try {
    developer.log('📱 Showing MAXIMUM PRIORITY full-screen call notification...');
    
    // Create notification with ABSOLUTE HIGHEST priority
    final androidDetails = AndroidNotificationDetails(
      'incoming_calls',
      'Incoming Calls',
      channelDescription: 'Critical notifications for incoming calls',
      importance: Importance.max,        // MAXIMUM importance
      priority: Priority.max,            // MAXIMUM priority
      category: AndroidNotificationCategory.call,
      fullScreenIntent: true,            // CRITICAL: Shows over lock screen
      ongoing: true,                     // Persistent until action taken
      autoCancel: false,                 // Don't auto-dismiss
      showWhen: false,                   // Don't show timestamp
      timeoutAfter: 45000,              // 45 seconds timeout
      visibility: NotificationVisibility.public, // Show on lock screen
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        'Incoming ${isVideoCall ? 'video' : 'voice'} call from $callerName. Tap to answer or decline.',
        htmlFormatBigText: true,
        contentTitle: '📞 ${isVideoCall ? 'Video' : 'Voice'} Call',
        htmlFormatContentTitle: true,
        summaryText: 'Tap to answer or decline',
      ),
      actions: [
        AndroidNotificationAction(
          'accept_call_$callId',
          '✅ Answer',
          titleColor: Colors.green,
          showsUserInterface: true,        // Opens app
        ),
        AndroidNotificationAction(
          'decline_call_$callId',
          '❌ Decline',
          titleColor: Colors.red,
          cancelNotification: true,        // Dismisses notification
        ),
      ],
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000, 500, 1000]),
      enableLights: true,
      ledColor: Colors.blue,
      ledOnMs: 1000,
      ledOffMs: 500,
      playSound: true,

      // insistent : true,
      sound: const RawResourceAndroidNotificationSound('default'),
      ticker: 'Incoming call from $callerName',   // Shows in status bar
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      interruptionLevel: InterruptionLevel.critical,  // CRITICAL level for iOS
      categoryIdentifier: 'CALL_CATEGORY',
      threadIdentifier: 'call_thread',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      callId.hashCode.abs(),
      '📞 ${isVideoCall ? 'Video' : 'Voice'} Call',
      'Incoming call from $callerName',
      notificationDetails,
      payload: jsonEncode({
        ...data,
        'notification_shown': 'true',
        'show_time': DateTime.now().toIso8601String(),
      }),
    );
    
    developer.log('✅ MAXIMUM PRIORITY full-screen call notification shown');
    
  } catch (e) {
    developer.log('❌ Error showing full-screen notification: $e');
    // Try simpler notification as fallback
    await _showSimpleCallNotification(callerName, isVideoCall, data);
  }
}

// Fallback: Simple call notification
Future<void> _showSimpleCallNotification(
  String callerName, 
  bool isVideoCall, 
  Map<String, dynamic> data
) async {
  try {
    developer.log('📱 Showing simple fallback call notification...');
    
    const androidDetails = AndroidNotificationDetails(
      'incoming_calls',
      'Calls',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      enableVibration: true,
      playSound: true,
    );
    
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      'Call from $callerName',
      '${isVideoCall ? 'Video' : 'Voice'} call - Tap to answer',
      const NotificationDetails(android: androidDetails),
      payload: jsonEncode(data),
    );
    
    developer.log('✅ Simple fallback notification shown');
  } catch (e) {
    developer.log('❌ Even simple notification failed: $e');
  }
}

// Initialize background notifications with MAXIMUM settings
Future<void> _initializeBackgroundNotifications() async {
  try {
    developer.log('📱 Initializing MAXIMUM PRIORITY background notifications...');
    
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    
    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Create call notification channel with MAXIMUM importance
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      // CRITICAL: Incoming calls channel with MAXIMUM priority
      await androidPlugin.createNotificationChannel(
         AndroidNotificationChannel(
          'incoming_calls',
          'Incoming Calls',
          description: 'Critical notifications for incoming calls - MAXIMUM PRIORITY',
          importance: Importance.max,        // HIGHEST importance
          enableVibration: true,
          enableLights: true,
          playSound: true,
          showBadge: true,
          ledColor: Colors.blue,
vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000, 500, 1000]),
          sound: RawResourceAndroidNotificationSound('default'),
        ),
      );
      
      // High importance channel for chat messages
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'chat_messages',
          'Chat Messages',
          description: 'Notifications for chat messages',
          importance: Importance.high,
          enableVibration: true,
          enableLights: true,
          playSound: true,
          showBadge: true,
        ),
      );
      
      // Emergency channel for last-resort notifications
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'emergency_calls',
          'Emergency Calls',
          description: 'Emergency call notifications',
          importance: Importance.max,
          enableVibration: true,
          enableLights: true,
          playSound: true,
          showBadge: true,
          sound: RawResourceAndroidNotificationSound('default'),
        ),
      );
    }
    
    developer.log('✅ MAXIMUM PRIORITY background notifications initialized');
    
  } catch (e) {
    developer.log('❌ Background notification initialization failed: $e');
  }
}

// Handle notification taps
void _onNotificationTapped(NotificationResponse response) {
  try {
    developer.log('👆 Notification tapped: ${response.actionId}');
    
    // Stop all emergency alerts immediately
    _stopAllEmergencyAlerts();
    
    final actionId = response.actionId ?? '';
    
    if (actionId.startsWith('accept_call_')) {
      _handleCallAccept(response.payload);
    } else if (actionId.startsWith('decline_call_')) {
      _handleCallDecline(response.payload);

    } else if (response.payload != null) {
      _handleNotificationTap(response.payload!);
    }
    
  } catch (e) {
    developer.log('❌ Error handling notification tap: $e');
  }
}

// Handle call accept from notification
void _handleCallAccept(String? payload) {
  try {
    developer.log('✅ Accepting call from notification');
    
    if (payload != null) {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      
      // Navigate to incoming call screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.to(
          () => IncomingCallScreen(callData: data),
          transition: Transition.fadeIn,
          fullscreenDialog: true,
        );
      });
    }
  } catch (e) {
    developer.log('❌ Error handling call accept: $e');
  }
}

// Handle call decline from notification
void _handleCallDecline(String? payload) {
  try {
    developer.log('❌ Declining call from notification');
    
    if (payload != null) {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final callId = data['callId']?.toString() ?? '';
      
      if (callId.isNotEmpty) {
        // Update call status in Firestore
        FirebaseFirestore.instance
            .collection('calls')
            .doc(callId)
            .update({'status': 'rejected'});
        
        developer.log('📞 Call $callId rejected via notification');
      }
    }
  } catch (e) {
    developer.log('❌ Error handling call decline: $e');
  }
}

// Handle general notification tap
void _handleNotificationTap(String payload) {
  try {
    final data = jsonDecode(payload) as Map<String, dynamic>;
    final type = data['type']?.toString() ?? '';
    
    developer.log('👆 General notification tap: $type');
    
    switch (type) {
      case 'call':
        // Show incoming call screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.to(
            () => IncomingCallScreen(callData: data),
            transition: Transition.fadeIn,
            fullscreenDialog: true,
          );
        });
        break;
      case 'chat':
      case 'message':
        _navigateToChatFromNotification(data);
        break;
      default:
        // Navigate to home
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.toNamed('/home');
        });
        break;
    }
  } catch (e) {
    developer.log('❌ Error handling notification tap: $e');
  }
}

// Navigate to chat from notification
void _navigateToChatFromNotification(Map<String, dynamic> data) {
  try {
    final senderId = data['senderId']?.toString() ?? '';
    final senderName = data['senderName']?.toString() ?? 'Unknown';
    final chatId = data['chatId']?.toString() ?? '';
    
    if (senderId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.toNamed('/chat', arguments: {
          'receiverUser': {
            'id': senderId,
            'userId': senderId,
            '_id': senderId,
            'name': senderName,
          },
          'chatId': chatId,
          'fromNotification': true,
        });
      });
    }
  } catch (e) {
    developer.log('❌ Error navigating to chat: $e');
  }
}

// Handle background chat messages
Future<void> _handleBackgroundChatMessage(RemoteMessage message) async {
  try {
    developer.log('💬 Handling background chat message');
    
    final title = message.notification?.title ?? message.data['senderName'] ?? 'New Message';
    final body = message.notification?.body ?? message.data['message'] ?? 'You have a new message';
    
    await _showBackgroundChatNotification(title, body, message.data);
    
  } catch (e) {
    developer.log('❌ Error handling background chat: $e');
  }
}

// Show background chat notification
Future<void> _showBackgroundChatNotification(
  String title, 
  String body, 
  Map<String, dynamic> data
) async {
  try {
    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription: 'Notifications for chat messages',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
      enableLights: true,
      ledColor: Color.fromRGBO(244, 135, 6, 1),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: jsonEncode(data),
    );
    
    developer.log('✅ Background chat notification shown');
    
  } catch (e) {
    developer.log('❌ Error showing chat notification: $e');
  }
}

// Show basic background notification
Future<void> _showBackgroundNotification(RemoteMessage message) async {
  try {
    final title = message.notification?.title ?? 'New Notification';
    final body = message.notification?.body ?? 'You have a new notification';
    
    await _showBackgroundChatNotification(title, body, message.data);
    
  } catch (e) {
    developer.log('❌ Error showing background notification: $e');
  }
}

// Emergency call notification as absolute last resort
Future<void> _showEmergencyCallNotification(RemoteMessage message) async {
  try {
    developer.log('🚨 === SHOWING EMERGENCY CALL NOTIFICATION ===');
    
    // Start emergency alerts
    await _startMultiMethodRingtone();
    await _startEmergencyVibration();
    
    final callerName = message.data['callerName'] ?? 'Unknown Caller';
    
    const androidDetails = AndroidNotificationDetails(
      'emergency_calls',
      'Emergency Calls',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      enableVibration: true,
      playSound: true,
      enableLights: true,
      ledColor: Colors.red,
    );
    
    const notificationDetails = NotificationDetails(android: androidDetails);
    
    await flutterLocalNotificationsPlugin.show(
      999999, // Emergency ID
      '🚨 EMERGENCY CALL 🚨',
      'CALL FROM $callerName - TAP TO ANSWER',
      notificationDetails,
      payload: jsonEncode(message.data),
    );
    
    developer.log('🚨 EMERGENCY notification shown');
    
  } catch (e) {
    developer.log('❌ CRITICAL: Emergency notification failed: $e');
  }
}

// Enhanced connectivity check function
Future<bool> _checkInternetConnectivity() async {
  try {
    final connectivityResults = await Connectivity().checkConnectivity();
    
    if (connectivityResults.every((result) => result == ConnectivityResult.none)) {
      developer.log('📶 No connectivity reported by system');
      return false;
    }
    
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      
      bool hasInternet = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      developer.log('📶 Internet lookup result: $hasInternet');
      return hasInternet;
    } catch (e) {
      developer.log('📶 Internet lookup failed: $e');
      return false;
    }
  } catch (e) {
    developer.log('❌ Connectivity check failed: $e');
    return false;
  }
}

// Enhanced Firebase initialization with offline support
Future<void> _initializeFirebaseWithFallback(bool hasInternet) async {
  try {
    // Always try to initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    if (hasInternet) {
      developer.log('✅ Firebase initialized with internet connectivity');
      // Set background handler only if online
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      developer.log('✅ Background message handler set');
    } else {
      developer.log('✅ Firebase initialized in offline mode');
    }
  } catch (e) {
    developer.log('❌ Firebase initialization failed: $e');
    // Don't rethrow - allow app to continue
  }
}

// Enhanced AppData initialization with fallback
Future<void> _initializeAppDataWithFallback(bool hasInternet) async {
  try {
    if (hasInternet) {
      await AppData().initialize();
      developer.log('✅ AppData initialized with internet');
    } else {
      // Try offline initialization
      try {
        await AppData().initializeOffline();
        developer.log('✅ AppData initialized in offline mode');
      } catch (offlineError) {
        developer.log('⚠️ AppData offline initialization failed, using minimal setup');
        await _initializeMinimalAppData();
      }
    }
  } catch (e) {
    developer.log('❌ AppData initialization failed: $e');
    await _initializeMinimalAppData();
  }
}

// Minimal AppData initialization for offline mode
Future<void> _initializeMinimalAppData() async {
  try {
    developer.log('⚠️ Using minimal AppData initialization');
    // Initialize only essential offline components
  } catch (e) {
    developer.log('❌ Even minimal AppData initialization failed: $e');
  }
}

// Initialize call services
Future<void> _initializeCallServices() async {
  try {
    // Initialize WebRTC call service
    Get.put(WebRTCCallService(), permanent: true);
    developer.log('✅ WebRTC Call Service initialized');
    
    // Initialize call permissions
    await CallPermissionService.checkPermissions(isVideoCall: true);
    
  } catch (e) {
    developer.log('❌ Error initializing call services: $e');
  }
}

// Enhanced app initialization with comprehensive offline support
Future<void> _initializeApp() async {
  try {
    developer.log('🚀 === APP INITIALIZATION START ===');
    
    // Ensure Flutter binding is initialized
    WidgetsFlutterBinding.ensureInitialized();
    
    try {
      AdaptiveVideoSystem.initialize();
      developer.log('✅ AdaptiveVideoSystem initialized');
    } catch (e) {
      developer.log('⚠️ AdaptiveVideoSystem initialization failed: $e');
    }

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    
    // Check internet connectivity first
    bool hasInternet = await _checkInternetConnectivity();
    _isAppOnline = hasInternet;
    developer.log('📶 Internet connectivity: $hasInternet');
    
    // Initialize Firebase with offline handling
    await _initializeFirebaseWithFallback(hasInternet);
    
    // Initialize AppData with offline support
    await _initializeAppDataWithFallback(hasInternet);

    await _initializeCallServices();
    
    // Initialize notification service only if online
    if (hasInternet) {
      try {
        developer.log('📱 === NOTIFICATION SERVICE INITIALIZATION ===');
        final notificationService = FirebaseNotificationService();
        await notificationService.initialize();
        developer.log('✅ Notification service initialized');
        
        // Initialize other online services
        await AppData().initializeFcmAfterLogin();
        _setupNotificationListeners();
        await _testFCMToken();
      } catch (e) {
        developer.log('⚠️ Online services initialization failed: $e');
      }
    } else {
      developer.log('⚠️ Skipping online services due to no internet connectivity');
    }
    
    // Initialize offline-capable services
    try {
      await DrawerProfileCache.initialize();
      developer.log('✅ DrawerProfileCache initialized');
    } catch (e) {
      developer.log('⚠️ DrawerProfileCache initialization failed: $e');
    }
    
    try {
      await CacheManager.initialize();
      developer.log('✅ CacheManager initialized');
    } catch (e) {
      developer.log('⚠️ CacheManager initialization failed: $e');
    }
    
    // Initialize follow status manager
    try {
      Get.put(FollowStatusManager(), permanent: true);
      developer.log('✅ FollowStatusManager initialized');
    } catch (e) {
      developer.log('⚠️ FollowStatusManager initialization failed: $e');
    }

    developer.log('🎉 === APP INITIALIZATION COMPLETED SUCCESSFULLY ===');
  } catch (e) {
    developer.log('❌ App initialization failed: $e');
    developer.log('❌ Stack trace: ${StackTrace.current}');
    
    // Don't rethrow - allow app to continue with limited functionality
    developer.log('⚠️ Continuing with limited functionality...');
  }
}

// Test FCM token
Future<void> _testFCMToken() async {
  try {
    developer.log('🧪 === TESTING FCM TOKEN ===');
    
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      developer.log('✅ FCM Token available: ${token.substring(0, 30)}...');
      
      // Test token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        developer.log('🔄 FCM Token refreshed: ${newToken.substring(0, 30)}...');
      });
    } else {
      developer.log('❌ FCM Token not available');
    }
  } catch (e) {
    developer.log('❌ FCM Token test failed: $e');
  }
}

// Setup notification listeners
void _setupNotificationListeners() {
  try {
    developer.log('📱 === SETTING UP NOTIFICATION LISTENERS ===');
    
    // Get notification service instance
    final notificationService = FirebaseNotificationService();
    
    // Handle foreground messages with enhanced logging
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('📨 === FOREGROUND MESSAGE RECEIVED IN MAIN ===');
      developer.log('📨 Message ID: ${message.messageId}');
      developer.log('📨 From: ${message.from}');
      developer.log('📨 Data: ${message.data}');
      developer.log('📨 Notification: ${message.notification?.toMap()}');
      developer.log('📨 Time: ${DateTime.now()}');
      
      // CRITICAL: Handle call messages in foreground
      final messageType = message.data['type']?.toString() ?? '';
      
      if (messageType == 'call') {
        _handleForegroundCallMessage(message);
      } else {
        // Handle regular messages
        notificationService.handleForegroundMessage(message);
        _showImmediateFeedback(message);
      }
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log('👆 App opened from notification: ${message.messageId}');
      _handleNotificationTapFromMessage(message);
    });

    // Handle notification taps when app is terminated
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        developer.log('🚀 App launched from notification: ${message.messageId}');
        // Delay navigation to ensure app is fully loaded
        Future.delayed(const Duration(seconds: 2), () {
          _handleNotificationTapFromMessage(message);
        });
      }
    });
    
    developer.log('✅ Notification listeners setup completed');
  } catch (e) {
    developer.log('❌ Error setting up notification listeners: $e');
  }
}

// Handle foreground call messages
void _handleForegroundCallMessage(RemoteMessage message) {
  try {
    developer.log('📞 === HANDLING FOREGROUND CALL MESSAGE ===');
    
    final data = message.data;
    final callId = data['callId']?.toString() ?? '';
    final callerName = data['callerName']?.toString() ?? 'Unknown Caller';
    final isVideoCall = data['isVideoCall']?.toString() == 'true';
    
    developer.log('📞 Foreground Call ID: $callId');
    developer.log('📞 Foreground Caller: $callerName');
    developer.log('📞 Foreground Video: $isVideoCall');
    
    // If app is in foreground, directly show incoming call screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.to(
        () => IncomingCallScreen(callData: data),
        transition: Transition.fadeIn,
        fullscreenDialog: true,
      );
    });
    
    developer.log('✅ Foreground call message handled');
  } catch (e) {
    developer.log('❌ Error handling foreground call message: $e');
  }
}

// Show immediate visual feedback for foreground messages
void _showImmediateFeedback(RemoteMessage message) {
  try {
    final title = message.notification?.title ?? message.data['senderName'] ?? 'New Message';
    final body = message.notification?.body ?? message.data['message'] ?? 'You have a new message';
    
    // Show GetX snackbar immediately
    Get.snackbar(
      title,
      body,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color.fromRGBO(244, 135, 6, 0.95),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(
        Icons.message_rounded,
        color: Colors.white,
        size: 28,
      ),
      shouldIconPulse: true,
      barBlur: 15,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      mainButton: TextButton(
        onPressed: () {
          Get.back();
          _handleNotificationTapFromMessage(message);
        },
        child: const Text(
          'View',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
    
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    developer.log('📱 ✅ Immediate feedback shown for foreground message');
  } catch (e) {
    developer.log('📱 ❌ Error showing immediate feedback: $e');
  }
}

// Handle notification tap from message
void _handleNotificationTapFromMessage(RemoteMessage message) {
  try {
    developer.log('👆 Handling notification tap from message...');
    developer.log('Data: ${message.data}');
    
    final data = message.data;
    final type = data['type']?.toString() ?? '';
    
    switch (type) {
      case 'chat':
      case 'message':
        _navigateToChatFromNotification(data);
        break;
      case 'call':
        _handleCallNotificationTapFromMessage(data);
        break;
      default:
        // Navigate to home if no specific action
        Get.offAllNamed('/home');
        break;
    }
  } catch (e) {
    developer.log('❌ Error handling notification tap from message: $e');
  }
}

// Handle call notification tap from message
void _handleCallNotificationTapFromMessage(Map<String, dynamic> data) {
  try {
    developer.log('📞 Handling call notification tap from message: $data');
    
    // Stop any emergency alerts
    _stopAllEmergencyAlerts();
    
    // Show incoming call screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.to(
        () => IncomingCallScreen(callData: data),
        transition: Transition.fadeIn,
        fullscreenDialog: true,
      );
    });
    
  } catch (e) {
    developer.log('❌ Error handling call notification tap: $e');
  }
}

// Enhanced main function with comprehensive error handling
void main() async {
  try {
    await _initializeApp();
  } catch (e) {
    developer.log('❌ Critical initialization error: $e');
    // Still run the app with basic functionality
  }
  
  runApp(const ProviderScope(child: InnovatorHomePage()));
}

class InnovatorHomePage extends ConsumerStatefulWidget {
  const InnovatorHomePage({super.key});

  @override
  ConsumerState<InnovatorHomePage> createState() => _InnovatorHomePageState();
}

class _InnovatorHomePageState extends ConsumerState<InnovatorHomePage> {
  Timer? _notificationTimer;
  Timer? _connectivityTimer;
  late NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _initializeAppNotifications();
    _setupPeriodicNotificationTest();
    _setupConnectivityMonitoring();
  }

  void _initializeAppNotifications() async {
    try {
      _notificationService = NotificationService();
      await _notificationService.initialize();
      developer.log('✅ App-level notification service initialized');
    } catch (e) {
      developer.log('❌ Error initializing app-level notifications: $e');
    }
  }

  // Periodic test to ensure notifications are working
  void _setupPeriodicNotificationTest() {
    if (_isAppOnline) {
      _notificationTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
        developer.log('🔔 Periodic notification system health check');
        _testNotificationHealth();
      });
    }
  }

  // Monitor connectivity changes
  void _setupConnectivityMonitoring() {
    _connectivityTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkAndUpdateConnectivity();
    });
  }

  Future<void> _checkAndUpdateConnectivity() async {
    try {
      final wasOnline = _isAppOnline;
      final isOnline = await _checkInternetConnectivity();
      
      if (wasOnline != isOnline) {
        _isAppOnline = isOnline;
        developer.log('📶 Connectivity changed: $isOnline');
        
        if (isOnline) {
          _handleReconnection();
        } else {
          _handleDisconnection();
        }
      }
    } catch (e) {
      developer.log('❌ Error checking connectivity: $e');
    }
  }

  Future<void> _handleReconnection() async {
    try {
      developer.log('🔄 Handling reconnection...');
      
      // Reinitialize Firebase services
      final notificationService = FirebaseNotificationService();
      await notificationService.initialize();
      
      // Refresh FCM token
      await AppData().refreshFcmToken();
      
      // Show reconnection snackbar
      Get.snackbar(
        'Back Online',
        'All features are now available',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.wifi, color: Colors.white),
      );
      
      // Restart periodic health checks
      _setupPeriodicNotificationTest();
      
    } catch (e) {
      developer.log('❌ Error handling reconnection: $e');
    }
  }

  void _handleDisconnection() {
    developer.log('📶 Handling disconnection...');
    
    // Cancel periodic tests
    _notificationTimer?.cancel();
    
    // Show offline snackbar
    Get.snackbar(
      'Offline',
      'Some features may be limited',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.wifi_off, color: Colors.white),
    );
  }

  Future<void> _testNotificationHealth() async {
    try {
      if (!_isAppOnline) return;
      
      final notificationService = FirebaseNotificationService();
      await notificationService.debugNotificationStatus();
      
      // Test if we can still show notifications
      final token = await notificationService.getFCMToken();
      if (token == null) {
        developer.log('⚠️ FCM token lost, reinitializing...');
        await AppData().refreshFcmToken();
      }
    } catch (e) {
      developer.log('❌ Notification health check failed: $e');
    }
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    _connectivityTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;

    return GetMaterialApp(
      navigatorKey: navigatorKey,
      title: 'Innovator',
      theme: _buildAppTheme(),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            // Add floating call widget overlay
            const CallFloatingWidget(),
          ],
        );
      },
      onInit: () {
        // Initialize chat controller globally with error handling
        try {
          Get.put<FireChatController>(FireChatController(), permanent: true);
          developer.log('✅ Chat controller initialized globally');
        } catch (e) {
          developer.log('❌ Error initializing chat controller: $e');
        }

        try {
          Get.put<CartStateManager>(CartStateManager(), permanent: true);
          developer.log('✅ Cart state manager initialized globally');
        } catch (e) {
          developer.log('❌ Error initializing cart state manager: $e');
        }
        
        // Test notification after app is ready (only if online)
        if (_isAppOnline) {
          Future.delayed(const Duration(seconds: 3), () {
            _performAppReadyNotificationTest();
          });
        }
      },
      getPages: [
        // Chat Home Page
        GetPage(
          name: '/home',
          page: () => const OptimizedChatHomePage(),
          binding: BindingsBuilder(() {
            Get.lazyPut<FireChatController>(() => FireChatController());
            Get.lazyPut<CartStateManager>(() => CartStateManager());
          }),
        ),
        
        // Chat List Page
        GetPage(
          name: '/chat-list',
          page: () => const OptimizedChatListPage(),
          binding: BindingsBuilder(() {
            Get.lazyPut<FireChatController>(() => FireChatController());
          }),
        ),
        
        // Add to Chat Page
        GetPage(
          name: '/add-to-chat',
          page: () => const AddToChatScreen(),
          binding: BindingsBuilder(() {
            Get.lazyPut<FireChatController>(() => FireChatController());
          }),
        ),
        
        // Search Users Page
        GetPage(
          name: '/search',
          page: () => const OptimizedSearchUsersPage(),
          binding: BindingsBuilder(() {
            Get.lazyPut<FireChatController>(() => FireChatController());
          }),
        ),

        // Shop Page
        GetPage(
          name: '/shop',
          page: () => const ShopPage(),
          binding: BindingsBuilder(() {
            Get.lazyPut<CartStateManager>(() => CartStateManager());
          }),
        ),
        
        // Individual Chat Page
        GetPage(
          name: '/chat',
          page: () {
            final args = Get.arguments as Map<String, dynamic>? ?? {};
            return OptimizedChatScreen(
              receiverUser: args['receiverUser'] ?? {},
              currentUser: args['currentUser'],
            );
          },
          binding: BindingsBuilder(() {
            Get.lazyPut<FireChatController>(() => FireChatController());
          }),
        ),
      ],
    );
  }

  // Test notifications when app is fully ready
  void _performAppReadyNotificationTest() async {
    try {
      if (!_isAppOnline) return;
      
      developer.log('🧪 === PERFORMING APP-READY NOTIFICATION TEST ===');
      
      final notificationService = FirebaseNotificationService();
      
      // Show a "system ready" notification
      await notificationService.showNotification(
        title: 'Chat System Ready',
        body: 'Your chat notifications are now active and working!',
        data: {'type': 'system_ready'},
      );
      
      // Debug current status
      await notificationService.debugNotificationStatus();
      
      developer.log('✅ App-ready notification test completed');
    } catch (e) {
      developer.log('❌ App-ready notification test failed: $e');
    }
  }

  ThemeData _buildAppTheme() {
    return ThemeData(
      fontFamily: 'Segoe UI',
      primarySwatch: Colors.orange,
      primaryColor: const Color.fromRGBO(244, 135, 6, 1),
      appBarTheme: const AppBarTheme(
        elevation: 1,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 19,
        ), 
        backgroundColor: Color.fromRGBO(244, 135, 6, 1),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
          foregroundColor: Colors.white,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color.fromRGBO(244, 135, 6, 1),
        foregroundColor: Colors.white,
      ),
    );
  }
}