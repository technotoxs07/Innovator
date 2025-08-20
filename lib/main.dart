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

// ENHANCED: Background message handler with call support
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    developer.log('🔥 === BACKGROUND MESSAGE HANDLER START ===');
    developer.log('🔥 Message ID: ${message.messageId}');
    developer.log('🔥 Data: ${message.data}');
    
    // Initialize Firebase if not already done
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      developer.log('🔥 Firebase initialized in background');
    }
    
    // Get message type
    final messageType = message.data['type']?.toString() ?? '';
    
    switch (messageType) {
      case 'call':
        await _handleBackgroundCallWithPersistentRinging(message);
        break;
      case 'chat':
      case 'message':
        await _handleBackgroundChatNotification(message);
        break;
      default:
        await _handleBackgroundNotification(message);
        break;
    }
    
    developer.log('✅ Background notification processed');
    developer.log('🔥 === BACKGROUND MESSAGE HANDLER END ===');
  } catch (e) {
    developer.log('❌ Error in background handler: $e');
  }
}

Future<void> _handleBackgroundCallWithPersistentRinging(RemoteMessage message) async {
  try {
    developer.log('📞 === HANDLING BACKGROUND CALL WITH PERSISTENT RINGING ===');
    
    final data = message.data;
    final callId = data['callId']?.toString() ?? '';
    final callerName = data['callerName']?.toString() ?? 'Unknown Caller';
    final isVideoCall = data['isVideoCall']?.toString() == 'true';
    
    developer.log('📞 Call ID: $callId');
    developer.log('📞 Caller: $callerName');
    developer.log('📞 Video: $isVideoCall');
    
    // CRITICAL: Use the enhanced background call service
    await EnhancedBackgroundCallService.handleBackgroundCall(data);
    
    // Also show a persistent notification
    await _showPersistentCallNotification(
      callId: callId,
      callerName: callerName,
      isVideoCall: isVideoCall,
      data: data,
    );
    
    developer.log('✅ Background call handled with persistent ringing');
  } catch (e) {
    developer.log('❌ Error handling background call: $e');
  }
}


Future<void> _showPersistentCallNotification({
  required String callId,
  required String callerName,
  required bool isVideoCall,
  required Map<String, dynamic> data,
}) async {
  try {
    developer.log('📱 Showing persistent call notification...');
    
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    // Initialize with call-specific settings
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    
    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        _handleCallNotificationResponse(response, data);
      },
    );
    
    // Create incoming calls channel if not exists
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'incoming_calls',
          'Incoming Calls',
          description: 'Notifications for incoming calls',
          importance: Importance.max,
          enableVibration: true,
          enableLights: true,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('call_ringtone'),
        ),
      );
    }
    
    // Enhanced notification for calls
    final androidDetails = AndroidNotificationDetails(
      'incoming_calls',
      'Incoming Calls',
      channelDescription: 'Notifications for incoming calls',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.call,
      fullScreenIntent: true, // Shows over lock screen
      ongoing: true, // Persistent notification
      autoCancel: false,
      showWhen: false,
      timeoutAfter: 45000, // 45 seconds timeout
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        'Tap to answer or decline',
        htmlFormatBigText: true,
        contentTitle: '${isVideoCall ? 'Video' : 'Voice'} Call',
        htmlFormatContentTitle: true,
      ),
      actions: [
        AndroidNotificationAction(
          'accept_$callId',
          'Answer',
          titleColor: Colors.green,
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'decline_$callId',
          'Decline',
          titleColor: Colors.red,
          cancelNotification: true,
        ),
      ],
      visibility: NotificationVisibility.public,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
      enableLights: true,
      ledColor: Colors.blue,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('call_ringtone'),
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'call_ringtone.wav',
      interruptionLevel: InterruptionLevel.critical,
      categoryIdentifier: 'CALL_CATEGORY',
    );
    
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await flutterLocalNotificationsPlugin.show(
      callId.hashCode,
      '${isVideoCall ? 'Video' : 'Voice'} Call',
      'Incoming ${isVideoCall ? 'video' : 'voice'} call from $callerName',
      notificationDetails,
      payload: jsonEncode({
        ...data,
        'action': 'incoming_call',
      }),
    );
    
    developer.log('✅ Persistent call notification shown');
  } catch (e) {
    developer.log('❌ Error showing persistent notification: $e');
  }
}

void _handleCallNotificationResponse(
  NotificationResponse response,
  Map<String, dynamic> data,
) {
  try {
    final actionId = response.actionId ?? '';
    
    if (actionId.startsWith('accept_')) {
      // Accept call
      developer.log('✅ Accepting call from notification');
      EnhancedBackgroundCallService().stopAllRinging();
      
      // Open app and navigate to call screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.toNamed('/incoming-call', arguments: data);
      });
      
    } else if (actionId.startsWith('decline_')) {
      // Decline call
      developer.log('❌ Declining call from notification');
      EnhancedBackgroundCallService().stopAllRinging();
      
      // Update Firebase
      final callId = data['callId']?.toString() ?? '';
      if (callId.isNotEmpty) {
        FirebaseFirestore.instance
            .collection('calls')
            .doc(callId)
            .update({'status': 'rejected'});
      }
      
    } else {
      // Notification tapped - show incoming call screen
      EnhancedBackgroundCallService().stopAllRinging();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.toNamed('/incoming-call', arguments: data);
      });
    }
  } catch (e) {
    developer.log('❌ Error handling call notification response: $e');
  }
}

// NEW: Handle background call notifications with ringtone
Future<void> _handleBackgroundCallNotification(RemoteMessage message) async {
  try {
    developer.log('📞 === HANDLING BACKGROUND CALL NOTIFICATION ===');
    
    final data = message.data;
    final callId = data['callId']?.toString() ?? '';
    final callerName = data['callerName']?.toString() ?? 'Unknown Caller';
    final isVideoCall = data['isVideoCall']?.toString() == 'true';
    
    developer.log('📞 Call ID: $callId');
    developer.log('📞 Caller: $callerName');
    developer.log('📞 Video Call: $isVideoCall');
    
    // Enable wakelock for incoming call
    await WakelockPlus.enable();
    
    // Start ringtone in background
    await _startBackgroundRingtone();
    
    // Start vibration pattern
    await _startBackgroundVibration();
    
    // Show full-screen call notification
    await _showFullScreenCallNotification(
      callId: callId,
      callerName: callerName,
      isVideoCall: isVideoCall,
      data: data,
    );
    
    // Auto-stop ringtone after 45 seconds (like WhatsApp)
    Timer(const Duration(seconds: 45), () async {
      await _stopBackgroundRingtone();
      await _stopBackgroundVibration();
      await WakelockPlus.disable();
    });
    
    developer.log('✅ Background call notification handled');
  } catch (e) {
    developer.log('❌ Error handling background call: $e');
  }
}

// NEW: Start ringtone in background
Future<void> _startBackgroundRingtone() async {
  try {
    developer.log('🔔 Starting background ringtone...');
    
    // Use FlutterRingtonePlayer for system ringtone
    await FlutterRingtonePlayer().playRingtone(
      looping: true,
      volume: 1.0,
      asAlarm: false, // Use ringtone, not alarm
    );
    
    developer.log('✅ Background ringtone started');
  } catch (e) {
    developer.log('❌ Error starting background ringtone: $e');
    
    // Fallback to system sound
    try {
      await _playSystemSoundLoop();
    } catch (fallbackError) {
      developer.log('❌ Fallback sound also failed: $fallbackError');
    }
  }
}

// Fallback system sound loop
Future<void> _playSystemSoundLoop() async {
  Timer.periodic(const Duration(seconds: 2), (timer) async {
    try {
      await SystemSound.play(SystemSoundType.click);
      HapticFeedback.heavyImpact();
      
      // Stop after 45 seconds
      if (timer.tick >= 22) { // 22 * 2 seconds = 44 seconds
        timer.cancel();
      }
    } catch (e) {
      timer.cancel();
    }
  });
}

// NEW: Start vibration in background
Future<void> _startBackgroundVibration() async {
  try {
    developer.log('📳 Starting background vibration...');
    
    // Check if device has vibrator
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != true) {
      developer.log('📳 Device does not support vibration');
      return;
    }
    
    // WhatsApp-like vibration pattern
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        await Vibration.vibrate(
          pattern: [0, 800, 200, 800, 200, 800], // Long, short, long pattern
          intensities: [0, 255, 0, 255, 0, 255],
        );
        
        // Stop after 45 seconds
        if (timer.tick >= 22) {
          timer.cancel();
        }
      } catch (e) {
        timer.cancel();
      }
    });
    
    developer.log('✅ Background vibration started');
  } catch (e) {
    developer.log('❌ Error starting background vibration: $e');
  }
}

// NEW: Stop background ringtone
Future<void> _stopBackgroundRingtone() async {
  try {
    await FlutterRingtonePlayer().stop();
    developer.log('🔇 Background ringtone stopped');
  } catch (e) {
    developer.log('❌ Error stopping background ringtone: $e');
  }
}

// NEW: Stop background vibration
Future<void> _stopBackgroundVibration() async {
  try {
    await Vibration.cancel();
    developer.log('📳 Background vibration stopped');
  } catch (e) {
    developer.log('❌ Error stopping background vibration: $e');
  }
}

// NEW: Show full-screen call notification
Future<void> _showFullScreenCallNotification({
  required String callId,
  required String callerName,
  required bool isVideoCall,
  required Map<String, dynamic> data,
}) async {
  try {
    developer.log('📱 Showing full-screen call notification...');
    
    // Initialize local notifications
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await _initializeCallNotifications(flutterLocalNotificationsPlugin);
    
    // Enhanced call notification details
    final androidDetails = AndroidNotificationDetails(
      'call_notifications',
      'Incoming Calls',
      channelDescription: 'Notifications for incoming calls',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.call,
      fullScreenIntent: true, // CRITICAL: Shows over lock screen
      ongoing: true, // Keep notification until action taken
      autoCancel: false,
      showWhen: false,
      timeoutAfter: 45000, // Auto-dismiss after 45 seconds
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        'Tap to answer or decline the ${isVideoCall ? 'video' : 'voice'} call',
        htmlFormatBigText: true,
        contentTitle: '${isVideoCall ? 'Video' : 'Voice'} Call',
        htmlFormatContentTitle: true,
      ),
      actions: [
        AndroidNotificationAction(
          'accept_call',
          'Answer',
          icon: DrawableResourceAndroidBitmap('@drawable/ic_call_accept'),
          contextual: true,
          titleColor: Colors.green,
        ),
        AndroidNotificationAction(
          'decline_call',
          'Decline',
          icon: DrawableResourceAndroidBitmap('@drawable/ic_call_decline'),
          contextual: true,
          titleColor: Colors.red,
        ),
      ],
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
      enableLights: true,
      ledColor: Colors.blue,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('call_ringtone'),
      visibility: NotificationVisibility.public, // Show on lock screen
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'call_ringtone.wav',
      interruptionLevel: InterruptionLevel.critical, // Critical for calls
      categoryIdentifier: 'CALL_CATEGORY',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      callId.hashCode,
      '${isVideoCall ? 'Video' : 'Voice'} Call',
      'Incoming ${isVideoCall ? 'video' : 'voice'} call from $callerName',
      notificationDetails,
      payload: jsonEncode({
        ...data,
        'action': 'incoming_call',
        'showCallScreen': 'true',
      }),
    );
    
    developer.log('✅ Full-screen call notification shown');
  } catch (e) {
    developer.log('❌ Error showing full-screen call notification: $e');
  }
}

// Initialize call-specific notifications
Future<void> _initializeCallNotifications(FlutterLocalNotificationsPlugin plugin) async {
  try {
    const androidInitialization = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInitialization = DarwinInitializationSettings();
    
    const initializationSettings = InitializationSettings(
      android: androidInitialization,
      iOS: iosInitialization,
    );
    
    await plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onCallNotificationTapped,
    );
    
    // Create call notification channel
    final androidPlugin = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'call_notifications',
          'Incoming Calls',
          description: 'Notifications for incoming calls',
          importance: Importance.max,
          enableVibration: true,
          enableLights: true,
          ledColor: Colors.blue,
          showBadge: true,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('call_ringtone'),
        ),
      );
    }
    
    developer.log('✅ Call notifications initialized');
  } catch (e) {
    developer.log('❌ Error initializing call notifications: $e');
  }
}

// Handle call notification taps
void _onCallNotificationTapped(NotificationResponse response) {
  try {
    developer.log('📞 Call notification tapped: ${response.actionId}');
    
    if (response.payload != null) {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      
      switch (response.actionId) {
        case 'accept_call':
          _handleCallAcceptFromNotification(data);
          break;
        case 'decline_call':
          _handleCallDeclineFromNotification(data);
          break;
        default:
          _showIncomingCallScreen(data);
          break;
      }
    }
  } catch (e) {
    developer.log('❌ Error handling call notification tap: $e');
  }
}

// Handle call accept from notification
void _handleCallAcceptFromNotification(Map<String, dynamic> data) {
  try {
    developer.log('✅ Accepting call from notification');
    
    // Stop ringtone and vibration
    _stopBackgroundRingtone();
    _stopBackgroundVibration();
    
    // Navigate to app and accept call
    _navigateToCallAccept(data);
    
  } catch (e) {
    developer.log('❌ Error accepting call from notification: $e');
  }
}

// Handle call decline from notification
void _handleCallDeclineFromNotification(Map<String, dynamic> data) {
  try {
    developer.log('❌ Declining call from notification');
    
    // Stop ringtone and vibration
    _stopBackgroundRingtone();
    _stopBackgroundVibration();
    
    // Decline the call
    _declineCallDirectly(data);
    
  } catch (e) {
    developer.log('❌ Error declining call from notification: $e');
  }
}

// Navigate to app to accept call
void _navigateToCallAccept(Map<String, dynamic> data) {
  // Use platform channel or deep link to open app and accept call
  // This would require additional native code integration
  _showIncomingCallScreen(data);
}

// Decline call directly
void _declineCallDirectly(Map<String, dynamic> data) {
  // Implement direct call decline logic
  // This could involve Firebase update or API call
  final callId = data['callId']?.toString() ?? '';
  if (callId.isNotEmpty) {
    // Update call status in Firebase
    // FirebaseFirestore.instance.collection('calls').doc(callId).update({'status': 'rejected'});
  }
}

// Show incoming call screen when app opens
void _showIncomingCallScreen(Map<String, dynamic> data) {
  try {
    developer.log('📱 Showing incoming call screen');
    
    // Stop ringtone when screen is shown
    _stopBackgroundRingtone();
    
    // Navigate to incoming call screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.to(
        () => IncomingCallScreen(callData: data),
        transition: Transition.fadeIn,
        fullscreenDialog: true,
      );
    });
    
  } catch (e) {
    developer.log('❌ Error showing incoming call screen: $e');
  }
}

// Enhanced background chat notification handler
Future<void> _handleBackgroundChatNotification(RemoteMessage message) async {
  try {
    developer.log('💬 === HANDLING BACKGROUND CHAT NOTIFICATION ===');
    
    final notification = message.notification;
    final data = message.data;
    
    // Create notification service instance
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    // Initialize local notifications
    await _initializeBackgroundNotifications(flutterLocalNotificationsPlugin);
    
    // Extract notification details
    String title = notification?.title ?? data['senderName'] ?? 'New Message';
    String body = notification?.body ?? data['message'] ?? 'You have a new message';
    
    // Show local notification
    await _showBackgroundLocalNotification(
      flutterLocalNotificationsPlugin,
      title,
      body,
      data,
    );
    
    developer.log('✅ Background chat notification handled');
  } catch (e) {
    developer.log('❌ Error handling background chat notification: $e');
  }
}

// Enhanced background notification handler (existing function - keep as is)
Future<void> _handleBackgroundNotification(RemoteMessage message) async {
  try {
    final notification = message.notification;
    final data = message.data;
    
    developer.log('📱 Background notification data: $data');
    developer.log('📱 Background notification payload: ${notification?.toMap()}');
    
    // Create notification service instance
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    // Initialize local notifications with proper channel
    await _initializeBackgroundNotifications(flutterLocalNotificationsPlugin);
    
    // Extract notification details
    String title = notification?.title ?? data['senderName'] ?? 'New Message';
    String body = notification?.body ?? data['message'] ?? 'You have a new message';
    
    // Show local notification
    await _showBackgroundLocalNotification(
      flutterLocalNotificationsPlugin,
      title,
      body,
      data,
    );
    
    developer.log('✅ Background local notification shown');
    
  } catch (e) {
    developer.log('❌ Error in background notification handler: $e');
  }
}

// Rest of your existing functions...
Future<void> _initializeBackgroundNotifications(FlutterLocalNotificationsPlugin plugin) async {
  try {
    const androidInitialization = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInitialization = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidInitialization,
      iOS: iosInitialization,
    );
    
    await plugin.initialize(initializationSettings);
    
    // Create notification channels for Android
    final androidPlugin = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'chat_messages',
          'Chat Messages',
          description: 'Notifications for new chat messages',
          importance: Importance.max,
          enableVibration: true,
          enableLights: true,
          ledColor: Color.fromRGBO(244, 135, 6, 1),
          showBadge: true,
          playSound: true,
        ),
      );
      
      // Call notifications channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'call_notifications',
          'Incoming Calls',
          description: 'Notifications for incoming calls',
          importance: Importance.max,
          enableVibration: true,
          enableLights: true,
          ledColor: Colors.blue,
          showBadge: true,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('call_ringtone'),
        ),
      );
      
      // Additional fallback channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'fallback_channel',
          'Fallback Notifications',
          description: 'Fallback notifications',
          importance: Importance.high,
          enableVibration: true,
          showBadge: true,
          playSound: true,
        ),
      );
    }
    
    developer.log('✅ Background notifications initialized');
  } catch (e) {
    developer.log('❌ Error initializing background notifications: $e');
  }
}

Future<void> _showBackgroundLocalNotification(
  FlutterLocalNotificationsPlugin plugin,
  String title,
  String body,
  Map<String, dynamic> data,
) async {
  try {
    // Enhanced background notification structure
    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription: 'Notifications for new chat messages',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        '',
        htmlFormatBigText: true,
      ),
      actions: [
        AndroidNotificationAction(
          'reply',
          'Reply',
          inputs: [
            AndroidNotificationActionInput(
              label: 'Type a message...',
            ),
          ],
        ),
        AndroidNotificationAction(
          'mark_read',
          'Mark as Read',
        ),
      ],
      autoCancel: true,
      visibility: NotificationVisibility.public,
      ticker: 'New message received',
      enableVibration: true,
      playSound: true,
      enableLights: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default.wav',
      interruptionLevel: InterruptionLevel.active,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notificationId = _generateNotificationId(data);
    
    await plugin.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: jsonEncode(data),
    );
    
    developer.log('✅ Background local notification displayed with ID: $notificationId');
  } catch (e) {
    developer.log('❌ Error showing background local notification: $e');
  }
}

int _generateNotificationId(Map<String, dynamic> data) {
  final chatId = data['chatId']?.toString() ?? '';
  if (chatId.isNotEmpty) {
    return chatId.hashCode.abs();
  }
  return DateTime.now().millisecondsSinceEpoch.remainder(100000);
}

// Continue with your existing functions...
// (Keep all your existing connectivity, initialization, and app functions as they are)

// Enhanced connectivity check function
Future<bool> _checkInternetConnectivity() async {
  try {
    // First check connectivity status
    final connectivityResults = await Connectivity().checkConnectivity();
    
    // Check if any connection type is available
    if (connectivityResults.every((result) => result == ConnectivityResult.none)) {
      developer.log('📶 No connectivity reported by system');
      return false;
    }
    
    // Double-check with a simple network call
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
        // You'll need to add this method to your AppData class
        await AppData().initializeOffline();
        developer.log('✅ AppData initialized in offline mode');
      } catch (offlineError) {
        developer.log('⚠️ AppData offline initialization failed, using minimal setup');
        // Minimal initialization fallback
        await _initializeMinimalAppData();
      }
    }
  } catch (e) {
    developer.log('❌ AppData initialization failed: $e');
    // Try minimal initialization as last resort
    await _initializeMinimalAppData();
  }
}

// Minimal AppData initialization for offline mode
Future<void> _initializeMinimalAppData() async {
  try {
    // Initialize only essential offline components
    developer.log('⚠️ Using minimal AppData initialization');
  } catch (e) {
    developer.log('❌ Even minimal AppData initialization failed: $e');
  }
}

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

Future<void> _testNotificationSystem() async {
  try {
    developer.log('🧪 === TESTING NOTIFICATION SYSTEM ===');
    
    final notificationService = FirebaseNotificationService();
    
    // Wait a moment for initialization to complete
    await Future.delayed(const Duration(seconds: 1));
    
    // Show test notification
    await notificationService.showTestNotification();
    
    // Debug notification status
    await notificationService.debugNotificationStatus();
    
    developer.log('✅ Notification system test completed');
  } catch (e) {
    developer.log('❌ Notification system test failed: $e');
  }
}

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
      _handleNotificationTap(message);
    });

    // Handle notification taps when app is terminated
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        developer.log('🚀 App launched from notification: ${message.messageId}');
        // Delay navigation to ensure app is fully loaded
        Future.delayed(const Duration(seconds: 2), () {
          _handleNotificationTap(message);
        });
      }
    });
    
    developer.log('✅ Notification listeners setup completed');
  } catch (e) {
    developer.log('❌ Error setting up notification listeners: $e');
  }
}

// NEW: Handle foreground call messages
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
          _handleNotificationTap(message);
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

void _handleNotificationTap(RemoteMessage message) {
  try {
    developer.log('👆 Handling notification tap...');
    developer.log('Data: ${message.data}');
    
    final data = message.data;
    final type = data['type']?.toString() ?? '';
    
    switch (type) {
      case 'chat':
      case 'message':
        _navigateToChat(data);
        break;
      case 'call':
        _handleCallNotificationTap(data);
        break;
      default:
        // Navigate to home if no specific action
        Get.offAllNamed('/home');
        break;
    }
  } catch (e) {
    developer.log('❌ Error handling notification tap: $e');
  }
}

void _navigateToChat(Map<String, dynamic> data) {
  try {
    final senderId = data['senderId']?.toString() ?? '';
    final senderName = data['senderName']?.toString() ?? 'Unknown';
    final chatId = data['chatId']?.toString() ?? '';
    
    if (senderId.isNotEmpty) {
      // Navigate to chat screen
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
      
      // Mark messages as read
      try {
        final chatController = Get.find<FireChatController>();
        if (chatId.isNotEmpty) {
          chatController.markMessagesAsRead(chatId);
        }
      } catch (e) {
        developer.log('Controller not found, will mark as read when available');
      }
    }
  } catch (e) {
    developer.log('❌ Error navigating to chat: $e');
  }
}

void _handleCallNotificationTap(Map<String, dynamic> data) {
  try {
    developer.log('📞 Handling call notification tap: $data');
    
    // Stop any background ringtone
    _stopBackgroundRingtone();
    _stopBackgroundVibration();
    
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
          // Reconnected - reinitialize online services
          _handleReconnection();
        } else {
          // Disconnected - handle offline mode
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