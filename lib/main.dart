// Optimized main.dart - MEMORY LEAK FIXES AND CRASH PREVENTION

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
import 'package:innovator/services/Daily_Notifcation.dart';
import 'package:innovator/services/Firebase_Messaging.dart';
import 'package:innovator/services/Notification_Like.dart';
import 'package:innovator/services/background_call_service.dart';
import 'package:innovator/services/call_permission_service.dart';
import 'package:innovator/services/fcm_handler.dart';
import 'package:innovator/services/firebase_services.dart';
import 'package:innovator/services/webrtc_call_service.dart';
import 'package:innovator/utils/Drawer/drawer_cache_manager.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:developer' as developer;

// Global variables and constants
late Size mq;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
bool _isAppOnline = false;

// CRITICAL: Global notification plugin for background use
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

// OPTIMIZED: Single timer manager to prevent leaks
class TimerManager {
  static Timer? _emergencyRingtoneTimer;
  static Timer? _emergencyVibrationTimer;
  static Timer? _autoStopTimer;
  static bool _isEmergencyRinging = false;

  static void cancelAllTimers() {
    _emergencyRingtoneTimer?.cancel();
    _emergencyVibrationTimer?.cancel();
    _autoStopTimer?.cancel();
    _isEmergencyRinging = false;
  }

  static bool get isRinging => _isEmergencyRinging;
  static void setRinging(bool value) => _isEmergencyRinging = value;
}

// ENHANCED: Lightweight background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // Reduce logging to prevent memory issues
    developer.log('Background message: ${message.messageId}');

    // CRITICAL: Initialize Firebase if not already done
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // Initialize local notifications ONCE
    // if (!_isNotificationInitialized) {
    //   await _initializeBackgroundNotifications();
    //   _isNotificationInitialized = true;
    // }

    final messageType = message.data['type']?.toString() ?? '';

    if (messageType == 'call') {
      // CRITICAL: Start ringtone immediately
      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      await _initializeBackgroundNotifications();
      await _startPersistentRinging();

      try {
        const platform = MethodChannel('com.innovation.innovator/call');
        await platform.invokeMethod('launchApp', message.data);
        developer.log('✅ App launch requested via platform channel');
      } catch (e) {
        developer.log('⚠️ Platform channel failed, using notification');
      }

      // Show full-screen notification
      await _showFullScreenCallNotification(
        callId: message.data['callId'] ?? '',
        callerName: message.data['callerName'] ?? 'Unknown',
        isVideoCall: message.data['isVideoCall'] == 'true',
        data: message.data,
      );

      // Try to launch app if possible
      await _launchAppForCall(message.data);
    } else {
      await _showBackgroundNotification(message);
    }
    developer.log('Background message processed');
  } catch (e) {
    developer.log('Background handler error: $e');
    // Still try emergency notification
    await _showEmergencyCallNotification(message);
  }
}

Future<void> _showBackgroundNotification(RemoteMessage message) async {
  try {
    final title = message.notification?.title ?? 'New Notification';
    final body = message.notification?.body ?? 'You have a new notification';

    const androidDetails = AndroidNotificationDetails(
      'general_notifications',
      'General Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: jsonEncode(message.data),
    );
  } catch (e) {
    developer.log('❌ Background notification error: $e');
  }
}

Future<void> _launchAppForCall(Map<String, dynamic> callData) async {
  try {
    // Use correct channel name matching MainActivity
    const platform = MethodChannel('com.innovation.innovator/call');

    // Call the platform method to launch app
    await platform.invokeMethod('launchApp', callData);

    developer.log('✅ App launch requested');
  } catch (e) {
    developer.log('❌ Failed to launch app: $e');

    // Fallback: Try to use the notification to launch
    await _showFullScreenCallNotification(
      callId: callData['callId'] ?? '',
      callerName: callData['callerName'] ?? 'Unknown',
      isVideoCall: callData['isVideoCall'] == 'true',
      data: callData,
    );
  }
}

Future<void> _startPersistentRinging() async {
  try {
    developer.log('🔔 Starting persistent ringing...');

    // Wake the device
    await WakelockPlus.enable();

    // Start ringtone - try multiple methods
    bool ringtoneStarted = false;

    // Method 1: FlutterRingtonePlayer with alarm
    try {
      await FlutterRingtonePlayer().playRingtone(
        looping: true,
        volume: 1.0,
        asAlarm: true, // Use alarm channel for higher priority
      );
      ringtoneStarted = true;
      developer.log('✅ Ringtone started with alarm priority');
    } catch (e) {
      developer.log('⚠️ Primary ringtone failed: $e');
    }

    // Method 2: Fallback to regular ringtone
    if (!ringtoneStarted) {
      try {
        await FlutterRingtonePlayer().playRingtone(
          looping: true,
          volume: 1.0,
          asAlarm: false,
        );
        ringtoneStarted = true;
        developer.log('✅ Ringtone started with regular priority');
      } catch (e) {
        developer.log('⚠️ Secondary ringtone failed: $e');
      }
    }

    // Method 3: System sound fallback
    if (!ringtoneStarted) {
      Timer.periodic(const Duration(seconds: 1), (timer) {
        if (timer.tick > 45) {
          timer.cancel();
        } else {
          SystemSound.play(SystemSoundType.click);
          HapticFeedback.heavyImpact();
        }
      });
      developer.log('⚠️ Using system sound fallback');
    }

    // Start vibration
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Timer.periodic(const Duration(milliseconds: 1500), (timer) {
          if (timer.tick > 30) {
            timer.cancel();
          } else {
            Vibration.vibrate(
              pattern: [0, 800, 200, 800],
              intensities: [0, 255, 0, 255],
            );
          }
        });
        developer.log('✅ Vibration started');
      }
    } catch (e) {
      developer.log('⚠️ Vibration failed: $e');
    }

    // Auto-stop after 45 seconds
    Timer(const Duration(seconds: 45), () async {
      await _stopAllRinging();
    });
  } catch (e) {
    developer.log('❌ Failed to start ringing: $e');
  }
}

Future<void> _stopAllRinging() async {
  try {
    await FlutterRingtonePlayer().stop();
    await Vibration.cancel();
    await WakelockPlus.disable();
    developer.log('✅ All ringing stopped');
  } catch (e) {
    developer.log('❌ Error stopping ringing: $e');
  }
}

// OPTIMIZED: Single method ringtone to prevent resource exhaustion
Future<void> _startOptimizedRingtone() async {
  if (TimerManager.isRinging) return;

  TimerManager.setRinging(true);

  try {
    // Use ONLY FlutterRingtonePlayer - most reliable method
    await FlutterRingtonePlayer().playRingtone(
      looping: true,
      volume: 1.0,
      asAlarm: false,
    );

    // Backup vibration pattern (simplified)
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      TimerManager._emergencyVibrationTimer = Timer.periodic(
        const Duration(milliseconds: 2000),
        (timer) async {
          if (TimerManager.isRinging && timer.tick <= 15) {
            // Max 30 seconds
            await Vibration.vibrate(pattern: [0, 500, 300, 500]);
          } else {
            timer.cancel();
          }
        },
      );
    }
  } catch (e) {
    developer.log('Optimized ringtone failed: $e');
    // Fallback to system sound only
    SystemSound.play(SystemSoundType.alert);
  }
}

// OPTIMIZED: Stop all alerts with better cleanup
Future<void> _stopAllEmergencyAlerts() async {
  try {
    TimerManager.setRinging(false);
    TimerManager.cancelAllTimers();

    // Stop ringtone
    try {
      await FlutterRingtonePlayer().stop();
    } catch (e) {}

    // Stop vibration
    try {
      await Vibration.cancel();
    } catch (e) {}

    // Disable wakelock
    try {
      await WakelockPlus.disable();
    } catch (e) {}

    developer.log('Emergency alerts stopped');
  } catch (e) {
    developer.log('Error stopping alerts: $e');
  }
}

// OPTIMIZED: Simplified notification with less resource usage
Future<void> _showFullScreenCallNotification({
  required String callId,
  required String callerName,
  required bool isVideoCall,
  required Map<String, dynamic> data,
}) async {
  try {
    // Create incoming_calls channel if not exists
    final androidPlugin =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'incoming_calls',
          'Incoming Calls',
          description: 'Incoming call notifications',
          importance: Importance.max,
          enableVibration: true,
          enableLights: true,
          playSound: true,
          showBadge: true,
        ),
      );
    }

    final androidDetails = AndroidNotificationDetails(
      'incoming_calls',
      'Incoming Calls',
      channelDescription: 'Incoming call notifications',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.call,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      visibility: NotificationVisibility.public,
      playSound: false,
      enableVibration: false,
      actions: [
        AndroidNotificationAction(
          'answer_$callId',
          'Answer',
          showsUserInterface: true,
          cancelNotification: false,
        ),
        AndroidNotificationAction(
          'decline_$callId',
          'Decline',
          cancelNotification: true,
        ),
      ],
      styleInformation: BigTextStyleInformation(
        'Incoming ${isVideoCall ? "video" : "voice"} call',
        contentTitle: '$callerName is calling',
        htmlFormatBigText: true,
      ),
      additionalFlags: Int32List.fromList([
        0x00000020, // FLAG_INSISTENT
        0x00000040, // FLAG_HIGH_PRIORITY
        0x00000004, // FLAG_NO_CLEAR
      ]),
    );

    await flutterLocalNotificationsPlugin.show(
      callId.hashCode.abs(),
      '$callerName is calling',
      'Incoming ${isVideoCall ? "video" : "voice"} call',
      NotificationDetails(android: androidDetails),
      payload: jsonEncode(data),
    );
  } catch (e) {
    developer.log('Notification error: $e');
  }
}

// Simplified fallback notification

// OPTIMIZED: Lightweight notification initialization
Future<void> _initializeBackgroundNotifications() async {
  try {
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

    final androidPlugin =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin != null) {
      // Create channels ONLY ONCE
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'incoming_calls',
          'Incoming Calls',
          description: 'Notifications for incoming calls',
          importance: Importance.max,
          enableVibration: true,
          enableLights: true,
          playSound: true,
          showBadge: true,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'chat_messages',
          'Chat Messages',
          description: 'Notifications for chat messages',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );
    }
  } catch (e) {
    developer.log('Notification initialization failed: $e');
  }
}

// Handle notification taps with cleanup
void _onNotificationTapped(NotificationResponse response) async {
  if (response.payload != null &&
      (response.payload == 'daily_thought' ||
          response.payload!.startsWith('daily_thought_'))) {
    // User tapped daily notification - could navigate to motivation screen or just dismiss
    Get.snackbar(
      'Daily Motivation',
      'Keep innovating!',
      backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
      colorText: Colors.white,
    );
    return;
  }
  try {
    developer.log('📱 Notification tapped');

    // Stop ringing immediately
    await _stopAllRinging();

    final actionId = response.actionId ?? '';

    if (actionId.startsWith('answer_')) {
      // Handle answer action
      if (response.payload != null) {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;

        // Initialize WebRTC and show call screen
        final callService = await WebRTCCallService.initializeForBackground();
        await callService.handleBackgroundCall(data);

        // Ensure app is ready
        if (Get.context == null) {
          runApp(
            GetMaterialApp(
              navigatorKey: navigatorKey,
              home: IncomingCallScreen(callData: data),
            ),
          );
        } else {
          Get.to(
            () => IncomingCallScreen(callData: data),
            transition: Transition.noTransition,
            fullscreenDialog: true,
          );
        }
      }
    } else if (actionId.startsWith('decline_')) {
      // Handle decline
      if (response.payload != null) {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        final callId = data['callId']?.toString() ?? '';

        if (callId.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('calls')
              .doc(callId)
              .update({'status': 'rejected'});
        }
      }
    } else if (response.payload != null) {
      // Regular tap - show incoming call screen
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;

      if (data['type'] == 'call') {
        await _handleCallNotificationTap(data);
      }
    }
  } catch (e) {
    developer.log('❌ Notification tap error: $e');
  }
}

Future<void> _handleCallNotificationTap(Map<String, dynamic> data) async {
  try {
    final callService = await WebRTCCallService.initializeForBackground();
    await callService.handleBackgroundCall(data);
  } catch (e) {
    developer.log('❌ Error handling call tap: $e');
  }
}
// Handle call accept from notification

// Handle call decline from notification

// Handle general notification tap

// Navigate to chat from notification
void _navigateToChatFromNotification(Map<String, dynamic> data) {
  try {
    final senderId = data['senderId']?.toString() ?? '';
    final senderName = data['senderName']?.toString() ?? 'Unknown';
    final chatId = data['chatId']?.toString() ?? '';

    if (senderId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.toNamed(
          '/chat',
          arguments: {
            'receiverUser': {
              'id': senderId,
              'userId': senderId,
              '_id': senderId,
              'name': senderName,
            },
            'chatId': chatId,
            'fromNotification': true,
          },
        );
      });
    }
  } catch (e) {
    developer.log('Chat navigation error: $e');
  }
}

// Handle background chat messages

// Show background chat notification

// Emergency call notification as last resort
Future<void> _showEmergencyCallNotification(RemoteMessage message) async {
  try {
    // Start emergency alerts
    await _startOptimizedRingtone();

    final callerName = message.data['callerName'] ?? 'Unknown Caller';

    const androidDetails = AndroidNotificationDetails(
      'incoming_calls',
      'Emergency Calls',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      enableVibration: true,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      999999,
      'EMERGENCY CALL',
      'CALL FROM $callerName',
      notificationDetails,
      payload: jsonEncode(message.data),
    );
  } catch (e) {
    developer.log('Emergency notification failed: $e');
  }
}

// OPTIMIZED: Lightweight connectivity check
Future<bool> _checkInternetConnectivity() async {
  try {
    final connectivityResults = await Connectivity().checkConnectivity();

    if (connectivityResults.every(
      (result) => result == ConnectivityResult.none,
    )) {
      return false;
    }

    // Quick connectivity test (reduced timeout)
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));

      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  } catch (e) {
    return false;
  }
}

// OPTIMIZED: Firebase initialization
Future<void> _initializeFirebaseWithFallback(bool hasInternet) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (hasInternet) {
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
    }
  } catch (e) {
    developer.log('Firebase initialization failed: $e');
  }
}

// OPTIMIZED: AppData initialization
Future<void> _initializeAppDataWithFallback(bool hasInternet) async {
  try {
    if (hasInternet) {
      await AppData().initialize();
    } else {
      try {
        await AppData().initializeOffline();
      } catch (offlineError) {
        await _initializeMinimalAppData();
      }
    }
  } catch (e) {
    await _initializeMinimalAppData();
  }
}

Future<void> _initializeMinimalAppData() async {
  try {
    // Minimal offline setup
    developer.log('Using minimal AppData initialization');
  } catch (e) {
    developer.log('Minimal AppData initialization failed: $e');
  }
}

// Initialize call services
Future<void> _initializeCallServices() async {
  try {
    Get.put(WebRTCCallService(), permanent: true);
    await CallPermissionService.checkPermissions(isVideoCall: true);
  } catch (e) {
    developer.log('Call services initialization failed: $e');
  }
}

// OPTIMIZED: App initialization with better error handling
Future<void> _initializeApp() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      AdaptiveVideoSystem.initialize();
    } catch (e) {}

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    try {
      await DailyNotificationService.initialize();
      developer.log(
        'Daily notification service initialized with automatic scheduling',
      );
    } catch (e) {
      developer.log('Daily notification service failed: $e');
    }

    bool hasInternet = await _checkInternetConnectivity();
    _isAppOnline = hasInternet;

    await _initializeFirebaseWithFallback(hasInternet);

    // CRITICAL FIX: Check for Firebase Auth state mismatch after reinstall
    await _handleReinstallAuthState(hasInternet);

    await _initializeAppDataWithFallback(hasInternet);
    await _initializeCallServices();

    // Initialize notification service only if online
    if (hasInternet) {
      try {
        // FIXED: Register the service with GetX BEFORE using it
        final notificationService = FirebaseNotificationService();
        Get.put(notificationService, permanent: true); // Add this line

        await notificationService.initialize();
        await AppData().initializeFcmAfterLogin();
        _setupNotificationListeners();
      } catch (e) {
        developer.log('Online services failed: $e');
      }
    }

    // Initialize offline-capable services
    try {
      await DrawerProfileCache.initialize();
    } catch (e) {}

    try {
      await CacheManager.initialize();
    } catch (e) {}

    try {
      Get.put(FollowStatusManager(), permanent: true);
    } catch (e) {}

    developer.log('App initialization completed');
  } catch (e) {
    developer.log('App initialization failed: $e');
  }
}

// Attempt to restore user data from Firebase/Firestore
Future<bool> _restoreUserDataFromFirebase(User firebaseUser) async {
  try {
    developer.log('🔄 Attempting to restore user data from Firebase...');

    // Get fresh ID token
    final idToken = await firebaseUser.getIdToken(true);
    if (idToken == null) return false;

    // Try to get user data from Firestore
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .get();

    if (userDoc.exists) {
      final userData = userDoc.data() ?? {};

      // Ensure all required fields
      userData['_id'] = firebaseUser.uid;
      userData['id'] = firebaseUser.uid;
      userData['userId'] = firebaseUser.uid;
      userData['uid'] = firebaseUser.uid;
      userData['email'] = userData['email'] ?? firebaseUser.email ?? '';
      userData['name'] = userData['name'] ?? firebaseUser.displayName ?? 'User';
      userData['photoURL'] = userData['photoURL'] ?? firebaseUser.photoURL;
      userData['fcmTokens'] = userData['fcmTokens'] ?? [];

      // Save to AppData
      await AppData().setAuthToken(idToken);
      await AppData().setCurrentUser(userData);

      // Get fresh FCM token
      try {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await AppData().saveFcmToken(fcmToken);
        }
      } catch (e) {
        developer.log('FCM token error: $e');
      }

      developer.log('✅ User data successfully restored from Firestore');
      return true;
    } else {
      developer.log('❌ User document not found in Firestore');

      // Try to create basic user data from Firebase Auth
      final basicUserData = {
        '_id': firebaseUser.uid,
        'id': firebaseUser.uid,
        'userId': firebaseUser.uid,
        'uid': firebaseUser.uid,
        'email': firebaseUser.email ?? '',
        'name':
            firebaseUser.displayName ??
            firebaseUser.email?.split('@')[0] ??
            'User',
        'photoURL': firebaseUser.photoURL,
        'provider': 'google',
        'fcmTokens': [],
      };

      // Create user document in Firestore
      await FirebaseService.verifyAndCreateUser(
        userId: firebaseUser.uid,
        name: basicUserData['name'] as String,
        email: basicUserData['email'] as String,
        photoURL: firebaseUser.photoURL,
        provider: 'google',
      );

      // Save to AppData
      await AppData().setAuthToken(idToken);
      await AppData().setCurrentUser(basicUserData);

      developer.log('✅ Created new user data from Firebase Auth');
      return true;
    }
  } catch (e) {
    developer.log('❌ Failed to restore user data: $e');
    return false;
  }
}

// Verify and update Firestore user document
Future<void> _verifyAndUpdateFirestoreUser(
  User firebaseUser,
  String localUserJson,
) async {
  try {
    final userData = jsonDecode(localUserJson) as Map<String, dynamic>;

    // Ensure user document exists in Firestore
    await FirebaseService.verifyAndCreateUser(
      userId: userData['_id'] ?? firebaseUser.uid,
      name: userData['name'] ?? firebaseUser.displayName ?? 'User',
      email: userData['email'] ?? firebaseUser.email ?? '',
      phone: userData['phone'],
      dob: userData['dob'],
      photoURL: userData['photoURL'] ?? firebaseUser.photoURL,
      provider: userData['provider'] ?? 'email',
    );

    developer.log('✅ Firestore user document verified/updated');
  } catch (e) {
    developer.log('❌ Error verifying Firestore user: $e');
  }
}

Future<void> _handleReinstallAuthState(bool hasInternet) async {
  try {
    developer.log('🔍 Checking for reinstall auth state mismatch...');

    // Check if Firebase Auth has a user but local storage doesn't
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    final localToken = prefs.getString('auth_token');
    final localUserJson = prefs.getString('current_user');

    if (firebaseUser != null && (localToken == null || localUserJson == null)) {
      developer.log(
        '⚠️ Detected app reinstall - Firebase user exists but local data missing',
      );

      if (hasInternet) {
        // Try to restore user data from Firebase
        final restored = await _restoreUserDataFromFirebase(firebaseUser);

        if (!restored) {
          // If restoration fails, sign out to force fresh login
          developer.log('📤 Restoration failed, signing out Firebase user');
          await FirebaseAuth.instance.signOut();
          await GoogleSignIn().signOut();
        }
      } else {
        // Offline: Can't restore, must sign out
        developer.log('📤 Offline - signing out Firebase user');
        await FirebaseAuth.instance.signOut();
      }
    } else if (firebaseUser != null &&
        localToken != null &&
        localUserJson != null) {
      developer.log('✅ Auth state consistent - user properly logged in');

      // Verify and update Firestore user document
      await _verifyAndUpdateFirestoreUser(firebaseUser, localUserJson);
    } else {
      developer.log('✅ No Firebase user - clean state');
    }
  } catch (e) {
    developer.log('❌ Error handling reinstall auth state: $e');
    // On error, sign out to ensure clean state
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
    } catch (signOutError) {
      developer.log('Error signing out: $signOutError');
    }
  }
}

// Setup notification listeners with better error handling
void _setupNotificationListeners() {
  try {
    final notificationService = FirebaseNotificationService();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final messageType = message.data['type']?.toString() ?? '';

      if (messageType == 'call') {
        _handleForegroundCallMessage(message);
      } else {
        notificationService.handleForegroundMessage(message);
        _showImmediateFeedback(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTapFromMessage(message);
    });

    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null) {
        Future.delayed(const Duration(seconds: 2), () {
          _handleNotificationTapFromMessage(message);
        });
      }
    });
  } catch (e) {
    developer.log('Notification listeners setup failed: $e');
  }
}

// Handle foreground call messages
void _handleForegroundCallMessage(RemoteMessage message) {
  try {
    final data = message.data;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.to(
        () => IncomingCallScreen(callData: data),
        transition: Transition.fadeIn,
        fullscreenDialog: true,
      );
    });
  } catch (e) {
    developer.log('Foreground call message error: $e');
  }
}

// OPTIMIZED: Lightweight immediate feedback
void _showImmediateFeedback(RemoteMessage message) {
  try {
    final title =
        message.notification?.title ??
        message.data['senderName'] ??
        'New Message';
    final body =
        message.notification?.body ?? message.data['message'] ?? 'New message';

    Get.snackbar(
      title,
      body,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color.fromRGBO(244, 135, 6, 0.95),
      colorText: Colors.white,
      duration: const Duration(seconds: 3), // Reduced duration
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      isDismissible: true,
      mainButton: TextButton(
        onPressed: () {
          Get.back();
          _handleNotificationTapFromMessage(message);
        },
        child: const Text(
          'View',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );

    HapticFeedback.lightImpact(); // Reduced impact
  } catch (e) {
    developer.log('Immediate feedback error: $e');
  }
}

// Handle notification tap from message
void _handleNotificationTapFromMessage(RemoteMessage message) {
  try {
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
        Get.offAllNamed('/home');
        break;
    }
  } catch (e) {
    developer.log('Notification tap from message error: $e');
  }
}

// Handle call notification tap from message
void _handleCallNotificationTapFromMessage(Map<String, dynamic> data) {
  try {
    _stopAllEmergencyAlerts();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.to(
        () => IncomingCallScreen(callData: data),
        transition: Transition.fadeIn,
        fullscreenDialog: true,
      );
    });
  } catch (e) {
    developer.log('Call notification tap error: $e');
  }
}

// OPTIMIZED: Main function
void main() async {
  try {
    await _initializeApp();
  } catch (e) {
    developer.log('Critical initialization error: $e');
  }

  runApp(const ProviderScope(child: InnovatorHomePage()));
}

// OPTIMIZED: Main app class with better memory management
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

    // OPTIMIZED: Less frequent checks to prevent resource exhaustion
    if (_isAppOnline) {
      _setupPeriodicChecks();
    }
  }

  void _initializeAppNotifications() async {
    try {
      _notificationService = NotificationService();
      await _notificationService.initialize();
    } catch (e) {
      developer.log('App notification service failed: $e');
    }
  }

  // OPTIMIZED: Less frequent checks
  void _setupPeriodicChecks() {
    // Notification health check every 10 minutes (was 5)
    _notificationTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      _testNotificationHealth();
    });

    // Connectivity check every 2 minutes (was 1)
    _connectivityTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _checkAndUpdateConnectivity();
    });
  }

  Future<void> _checkAndUpdateConnectivity() async {
    try {
      final wasOnline = _isAppOnline;
      final isOnline = await _checkInternetConnectivity();

      if (wasOnline != isOnline) {
        _isAppOnline = isOnline;

        if (isOnline) {
          _handleReconnection();
        } else {
          _handleDisconnection();
        }
      }
    } catch (e) {
      developer.log('Connectivity check error: $e');
    }
  }

  Future<void> _handleReconnection() async {
    try {
      developer.log('Handling reconnection...');

      final notificationService = FirebaseNotificationService();
      await notificationService.initialize();
      await AppData().refreshFcmToken();

      Get.snackbar(
        'Back Online',
        'All features are now available',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.wifi, color: Colors.white),
      );

      // Restart periodic checks if they were stopped
      if (_notificationTimer?.isActive != true) {
        _setupPeriodicChecks();
      }
    } catch (e) {
      developer.log('Reconnection handling error: $e');
    }
  }

  void _handleDisconnection() {
    developer.log('Handling disconnection...');

    // Cancel resource-heavy periodic tests
    _notificationTimer?.cancel();

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

      final token = await notificationService.getFCMToken();
      if (token == null) {
        developer.log('FCM token lost, reinitializing...');
        await AppData().refreshFcmToken();
      }
    } catch (e) {
      developer.log('Notification health check failed: $e');
    }
  }

  @override
  void dispose() {
    // CRITICAL: Cleanup all timers and resources
    _notificationTimer?.cancel();
    _connectivityTimer?.cancel();
    TimerManager.cancelAllTimers();
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
        return Stack(children: [child!, const CallFloatingWidget()]);
      },
      onInit: () {
        // Initialize controllers with better error handling
        try {
          Get.put<FireChatController>(FireChatController(), permanent: true);
          Get.put<CartStateManager>(CartStateManager(), permanent: true);

          // FIXED: Register notification service here too as backup
          if (!Get.isRegistered<FirebaseNotificationService>()) {
            try {
              Get.put(FirebaseNotificationService(), permanent: true);
            } catch (e) {
              developer.log(
                'Failed to register notification service in onInit: $e',
              );
            }
          }
        } catch (e) {
          developer.log('Controller initialization error: $e');
        }

        // OPTIMIZED: Delayed notification test only if online
        if (_isAppOnline) {
          Future.delayed(const Duration(seconds: 5), () {
            _performAppReadyNotificationTest();
          });
        }
      },

      getPages: [
        GetPage(
          name: '/home',
          page: () => const OptimizedChatHomePage(),
          binding: BindingsBuilder(() {
            Get.lazyPut<FireChatController>(() => FireChatController());
            Get.lazyPut<CartStateManager>(() => CartStateManager());
          }),
        ),

        GetPage(
          name: '/chat-list',
          page: () => const OptimizedChatListPage(),
          binding: BindingsBuilder(() {
            Get.lazyPut<FireChatController>(() => FireChatController());
          }),
        ),

        GetPage(
          name: '/add-to-chat',
          page: () => const AddToChatScreen(),
          binding: BindingsBuilder(() {
            Get.lazyPut<FireChatController>(() => FireChatController());
          }),
        ),

        GetPage(
          name: '/search',
          page: () => const OptimizedSearchUsersPage(),
          binding: BindingsBuilder(() {
            Get.lazyPut<FireChatController>(() => FireChatController());
          }),
        ),

        GetPage(
          name: '/shop',
          page: () => const ShopPage(),
          binding: BindingsBuilder(() {
            Get.lazyPut<CartStateManager>(() => CartStateManager());
          }),
        ),

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

  // OPTIMIZED: Lightweight notification test
  void _performAppReadyNotificationTest() async {
    try {
      if (!_isAppOnline) return;

      final notificationService = FirebaseNotificationService();

      // Simple test notification
      await notificationService.showNotification(
        title: 'System Ready',
        body: 'Notifications are active',
        data: {'type': 'system_ready'},
      );
    } catch (e) {
      developer.log('App-ready notification test failed: $e');
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
