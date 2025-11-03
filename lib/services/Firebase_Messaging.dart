

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:innovator/App_data/App_data.dart';
import 'dart:developer' as developer;
import 'package:innovator/screens/chatApp/controller/chat_controller.dart';
import 'package:innovator/services/firebase_services.dart';

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance = 
      FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Notification channels - MATCH with Android manifest
  static const String _chatChannelId = 'chat_messages';
  static const String _generalChannelId = 'general_notifications';
  static const String _callChannelId = 'call_notifications';

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      developer.log('⚠️ Notification service already initialized');
      return;
    }

    try {
      developer.log('🔔 === INITIALIZING NOTIFICATION SERVICE ===');

      // Request permissions first
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize Firebase messaging
      await _initializeFirebaseMessaging();

      // Setup message handlers
      _setupMessageHandlers();

      _isInitialized = true;
      developer.log('✅ === NOTIFICATION SERVICE INITIALIZED SUCCESSFULLY ===');
    } catch (e) {
      developer.log('❌ Error initializing notification service: $e');
      rethrow;
    }
  }

  Future<void> _requestPermissions() async {
    try {
      developer.log('📱 Requesting notification permissions...');
      
      // Request Firebase messaging permissions
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      developer.log('📱 FCM Permission status: ${settings.authorizationStatus}');

      // Request local notification permissions for Android 13+
      if (Platform.isAndroid) {
        final plugin = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        final granted = await plugin?.requestNotificationsPermission();
        developer.log('📱 Local notification permission: $granted');
        
        // Request exact alarm permission for Android 12+
        final exactAlarmPermission = await plugin?.requestExactAlarmsPermission();
        developer.log('📱 Exact alarm permission: $exactAlarmPermission');
      }
    } catch (e) {
      developer.log('❌ Error requesting permissions: $e');
    }
  }

  // ENHANCED: Call notification handling
  Future<void> sendCallNotification({
    required String token,
    required String callId,
    required String callerName,
    required bool isVideoCall,
  }) async {
    try {
      developer.log('📞 Sending ${isVideoCall ? 'video' : 'voice'} call notification');
      
      final callType = isVideoCall ? 'Video Call' : 'Voice Call';
      
      // Enhanced call notification with high priority
      final androidDetails = AndroidNotificationDetails(
        _callChannelId,
        'Call Notifications',
        channelDescription: 'Incoming call notifications',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.call,
        fullScreenIntent: true, // Show as full screen
        ongoing: true, // Keep notification until answered/declined
        autoCancel: false,
        showWhen: false,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(
          'Incoming $callType from $callerName',
          htmlFormatBigText: true,
          contentTitle: callType,
          htmlFormatContentTitle: true,
        ),
        actions: [
          AndroidNotificationAction(
            'accept_call',
            'Accept',
            titleColor: Colors.green,
          ),
          AndroidNotificationAction(
            'decline_call',
            'Decline',
            titleColor: Colors.red,
          ),
        ],
        timeoutAfter: 30000, // 30 seconds timeout
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
        enableLights: true,
        ledColor: Colors.blue,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('default'),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        interruptionLevel: InterruptionLevel.critical, // Critical for calls
        categoryIdentifier: 'CALL_CATEGORY',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        callId.hashCode,
        callType,
        'Incoming $callType from $callerName',
        notificationDetails,
        payload: jsonEncode({
          'type': 'call',
          'callId': callId,
          'callerName': callerName,
          'isVideoCall': isVideoCall,
          'action': 'incoming_call',
        }),
      );
      
      developer.log('✅ Call notification displayed');
      
    } catch (e) {
      developer.log('❌ Error showing call notification: $e');
    }
  }

  // ENHANCED: Handle call notification actions
  // void _handleCallNotificationAction(String action, Map<String, dynamic> data) {
  //   final callId = data['callId']?.toString() ?? '';
    
  //   switch (action) {
  //     case 'accept_call':
  //       _acceptCallFromNotification(callId, data);
  //       break;
  //     case 'decline_call':
  //       _declineCallFromNotification(callId);
  //       break;
  //     default:
  //       // Show incoming call screen
  //       _showIncomingCallFromNotification(data);
  //       break;
  //   }
  // }

  // void _acceptCallFromNotification(String callId, Map<String, dynamic> data) {
  //   try {
  //     if (Get.isRegistered<WebRTCCallService>()) {
  //       final callService = WebRTCCallService.instance;
  //       callService.answerCall(data);
        
  //       // Navigate to call screen
  //       Get.to(() => ActiveCallScreen());
        
  //       // Clear notification
  //       clearNotification(callId.hashCode);
  //     } else {
  //       // Show incoming call screen if service not ready
  //       _showIncomingCallFromNotification(data);
  //     }
  //   } catch (e) {
  //     developer.log('❌ Error accepting call from notification: $e');
  //     _showIncomingCallFromNotification(data);
  //   }
  // }

  // void _declineCallFromNotification(String callId) {
  //   try {
  //     if (Get.isRegistered<WebRTCCallService>()) {
  //       final callService = WebRTCCallService.instance;
  //       callService.rejectCall(callId);
        
  //       // Clear notification
  //       clearNotification(callId.hashCode);
  //     }
  //   } catch (e) {
  //     developer.log('❌ Error declining call from notification: $e');
  //   }
  // }

  // void _showIncomingCallFromNotification(Map<String, dynamic> data) {
  //   Get.to(
  //     () => IncomingCallScreen(callData: data),
  //     transition: Transition.fadeIn,
  //     fullscreenDialog: true,
  //   );
  // }

  Future<void> _initializeLocalNotifications() async {
    try {
      developer.log('📱 Initializing local notifications...');
      
      // Android initialization with custom settings
      const androidInitialization = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // iOS initialization with enhanced settings
      const iosInitialization = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        requestCriticalPermission: false,
        requestProvisionalPermission: false,
        onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
      );

      const initializationSettings = InitializationSettings(
        android: androidInitialization,
        iOS: iosInitialization,
      );

      final initialized = await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      developer.log('📱 Local notifications initialized: $initialized');

      // Create notification channels for Android
      await _createNotificationChannels();
      
      developer.log('✅ Local notifications setup completed');
    } catch (e) {
      developer.log('❌ Error initializing local notifications: $e');
      rethrow;
    }
  }

  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    try {
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        developer.log('📱 Creating Android notification channels...');
        
        // Chat messages channel - HIGH PRIORITY
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
            sound: RawResourceAndroidNotificationSound('default'),
          ),
        );

        // General notifications channel
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'general_notifications',
            'General Notifications',
            description: 'General app notifications',
            importance: Importance.high,
            enableVibration: true,
            showBadge: true,
            playSound: true,
          ),
        );

        // ENHANCED: Call notifications channel - HIGHEST PRIORITY
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'call_notifications',
            'Call Notifications',
            description: 'Incoming call notifications',
            importance: Importance.max,
            enableVibration: true,
            enableLights: true,
            showBadge: true,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('default'),
          ),
        );

        developer.log('✅ All Android notification channels created successfully');
      }
    } catch (e) {
      developer.log('❌ Error creating notification channels: $e');
    }
  }

  Future<void> _initializeFirebaseMessaging() async {
    try {
      developer.log('🔥 Initializing Firebase messaging...');
      
      // Get FCM token
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        developer.log('📱 FCM Token obtained: ${token.substring(0, 20)}...');
        await _saveTokenToUserData(token);
      } else {
        developer.log('⚠️ Failed to get FCM token');
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        developer.log('🔄 FCM Token refreshed: ${newToken.substring(0, 20)}...');
        _saveTokenToUserData(newToken);
      });
      
      developer.log('✅ Firebase messaging initialized');
    } catch (e) {
      developer.log('❌ Error initializing Firebase messaging: $e');
    }
  }

  Future<void> _saveTokenToUserData(String token) async {
    try {
      // Save to AppData
      await AppData().saveFcmToken(token);
      
      // Save to Firebase if user is logged in
      final userData = AppData().currentUser;
      if (userData != null && userData.isNotEmpty) {
        final userId = userData['_id']?.toString() ?? 
                      userData['uid']?.toString() ?? '';
        
        if (userId.isNotEmpty) {
          await FirebaseService.updateUserFCMToken(userId, token);
          developer.log('✅ FCM token saved for user: $userId');
        }
      }
    } catch (e) {
      developer.log('❌ Error saving FCM token: $e');
    }
  }

  void _setupMessageHandlers() {
    developer.log('📨 Setting up FCM message handlers...');
    
    // CRITICAL: Foreground messages handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('📨 === FOREGROUND MESSAGE RECEIVED ===');
      developer.log('Message ID: ${message.messageId}');
      developer.log('From: ${message.from}');
      developer.log('Data: ${message.data}');
      developer.log('Notification: ${message.notification?.toMap()}');
      
      // ENHANCED: Handle different message types
      final messageType = message.data['type']?.toString() ?? '';
      
      switch (messageType) {
        // case 'call':
        //   _handleIncomingCallMessage(message);
        //   break;
        case 'chat':
        case 'message':
          handleForegroundMessage(message);
          break;
        default:
          handleForegroundMessage(message);
          break;
      }
    });

    // Background/terminated app - user taps notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log('👆 Notification tapped (background): ${message.messageId}');
      _handleNotificationTap(message.data);
    });

    // App launched from notification (terminated state)
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        developer.log('🚀 App launched from notification: ${message.messageId}');
        Future.delayed(const Duration(seconds: 1), () {
          _handleNotificationTap(message.data);
        });
      }
    });
    
    developer.log('✅ FCM message handlers setup completed');
  }

  // ENHANCED: Handle incoming call messages
  // void _handleIncomingCallMessage(RemoteMessage message) {
  //   try {
  //     developer.log('📞 === HANDLING INCOMING CALL MESSAGE ===');
      
  //     final data = message.data;
  //     final callId = data['callId']?.toString() ?? '';
  //     final callerName = data['callerName']?.toString() ?? 'Unknown Caller';
  //     final isVideoCall = data['isVideoCall'] == 'true';
      
  //     developer.log('📞 Call ID: $callId');
  //     developer.log('📞 Caller: $callerName');
  //     developer.log('📞 Video: $isVideoCall');
      
  //     // Show call notification
  //     sendCallNotification(
  //       token: '', // Empty for local notification
  //       callId: callId,
  //       callerName: callerName,
  //       isVideoCall: isVideoCall,
  //     );
      
  //     // If app is in foreground, directly show incoming call screen
  //     if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
  //       developer.log('📞 App in foreground, showing call screen directly');
        
  //       Future.delayed(const Duration(milliseconds: 500), () {
  //         Get.to(
  //           () => IncomingCallScreen(callData: data),
  //           transition: Transition.fadeIn,
  //           fullscreenDialog: true,
  //         );
  //       });
  //     }
      
  //     developer.log('✅ Incoming call message handled');
      
  //   } catch (e) {
  //     developer.log('❌ Error handling incoming call message: $e');
  //   }
  // }

  // Handle foreground messages with badge management (existing method enhanced)
  Future<void> handleForegroundMessage(RemoteMessage message) async {
    try {
      developer.log('📱 ========= FOREGROUND MESSAGE WITH BADGE START =========');
      developer.log('📱 Message ID: ${message.messageId}');
      developer.log('📱 Time: ${DateTime.now()}');
      
      final notification = message.notification;
      final data = message.data;
      
      // Extract notification details
      String title = notification?.title ?? data['senderName'] ?? 'New Message';
      String body = notification?.body ?? data['message'] ?? 'You have a new message';
      String chatId = data['chatId']?.toString() ?? '';
      String senderId = data['senderId']?.toString() ?? '';
      
      developer.log('📱 Processed - Title: $title, Body: $body, ChatId: $chatId');

      // Update badge in chat controller
      try {
        if (Get.isRegistered<FireChatController>()) {
          final chatController = Get.find<FireChatController>();
          
          // Check if user is currently viewing this specific chat
          final isViewingThisChat = chatController.currentChatId.value == chatId;
          
          if (!isViewingThisChat && chatId.isNotEmpty) {
            // Increment badge for this chat
            chatController.initializeBadgeForChat(chatId);
            final currentBadge = chatController.chatBadges[chatId]!.value;
            chatController.chatBadges[chatId]!.value = currentBadge + 1;
            chatController.unreadCounts[chatId] = currentBadge + 1;
            
            // Update total badges
            chatController.updateTotalUnreadBadges();
            
            developer.log('🔴 Badge incremented for chat $chatId: ${currentBadge + 1}');
            
            // Show notification only if not viewing the chat
            await _showLocalNotificationWithBadge(
              title: title,
              body: body,
              data: data,
              channelId: 'chat_messages',
              badgeCount: currentBadge + 1,
            );
          } else if (isViewingThisChat) {
            // Auto-mark as read if viewing the chat
            developer.log('📱 User viewing chat, auto-marking as read');
            Future.delayed(const Duration(milliseconds: 500), () {
              chatController.markMessagesAsRead(chatId);
            });
          } else {
            // Still show notification even without chat ID
            await _showLocalNotificationWithBadge(
              title: title,
              body: body,
              data: data,
              channelId: 'chat_messages',
              badgeCount: 1,
            );
          }
        } else {
          // Controller not available, show notification anyway
          await _showLocalNotificationWithBadge(
            title: title,
            body: body,
            data: data,
            channelId: 'chat_messages',
            badgeCount: 1,
          );
        }
        
        developer.log('📱 ✅ Badge and notification updated');
      } catch (e) {
        developer.log('📱 ❌ Error updating badge: $e');
      }

      // Show in-app notification
      _showInAppNotificationWithBadge(title, body, chatId);

      developer.log('📱 ✅ Foreground notification with badge completed');
      developer.log('📱 ========= FOREGROUND MESSAGE WITH BADGE END =========');

    } catch (e) {
      developer.log('📱 ❌ CRITICAL ERROR in handleForegroundMessageWithBadge: $e');
    }
  }

  void _showInAppNotificationWithBadge(String title, String body, String chatId) {
    try {
      // Get current badge count for this chat
      int badgeCount = 1;
      try {
        if (Get.isRegistered<FireChatController>()) {
          final chatController = Get.find<FireChatController>();
          if (chatId.isNotEmpty && chatController.chatBadges.containsKey(chatId)) {
            badgeCount = chatController.chatBadges[chatId]!.value;
          }
        }
      } catch (e) {
        developer.log('Could not get badge count for in-app notification: $e');
      }

      // Show enhanced GetX snackbar with badge indication
      Get.snackbar(
        title,
        body,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withAlpha(90),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: Stack(
          children: [
            const Icon(
              Icons.message_rounded,
              color: Colors.white,
              size: 28,
            ),
            if (badgeCount > 1)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red, width: 1),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        shouldIconPulse: true,
        barBlur: 15,
        isDismissible: true,
        dismissDirection: DismissDirection.horizontal,
        mainButton: TextButton(
          onPressed: () {
            Get.back();
            _handleNotificationTapFromSnackbar(chatId);
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
      
      // Haptic feedback for unread messages
      HapticFeedback.mediumImpact();
      
      developer.log('📱 ✅ In-app notification with badge shown');
    } catch (e) {
      developer.log('📱 ❌ Error showing in-app notification with badge: $e');
    }
  }

  void _handleNotificationTapFromSnackbar(String chatId) {
    try {
      if (chatId.isNotEmpty && Get.isRegistered<FireChatController>()) {
        final chatController = Get.find<FireChatController>();
        
        // Find the chat and navigate
        final chat = chatController.chatList.firstWhere(
          (chat) => chat['chatId'] == chatId,
          orElse: () => <String, dynamic>{},
        );
        
        if (chat.isNotEmpty) {
          final otherUser = chat['otherUser'] as Map<String, dynamic>?;
          if (otherUser != null) {
            chatController.navigateToChat(otherUser);
            // Mark as read will be handled automatically when opening chat
          }
        }
      }
    } catch (e) {
      developer.log('❌ Error handling snackbar tap: $e');
    }
  }

  Future<void> _showLocalNotificationWithBadge({
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required String channelId,
    required int badgeCount,
  }) async {
    try {
      developer.log('📱 ========= SHOWING NOTIFICATION WITH BADGE =========');
      developer.log('📱 Badge Count: $badgeCount');
      
      // Calculate total badge count across all chats
      int totalBadges = badgeCount;
      try {
        if (Get.isRegistered<FireChatController>()) {
          final chatController = Get.find<FireChatController>();
          totalBadges = chatController.getTotalUnreadCountFromMutualFollowers();
        }
      } catch (e) {
        developer.log('📱 Could not get total badge count: $e');
      }
      
      // Enhanced Android notification with badge number
      final androidDetails = AndroidNotificationDetails(
        channelId,
        _getChannelName(channelId),
        channelDescription: _getChannelDescription(channelId),
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(
          body,
          htmlFormatBigText: true,
          contentTitle: title,
          htmlFormatContentTitle: true,
          summaryText: badgeCount > 1 ? '$badgeCount new messages' : 'New message',
        ),
        actions: _getNotificationActions(data),
        autoCancel: true,
        ongoing: false,
        visibility: NotificationVisibility.public,
        ticker: '$title: $body',
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
        enableLights: true,
        ledColor: Colors.red,
        ledOnMs: 1000,
        ledOffMs: 500,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('default'),
        category: AndroidNotificationCategory.message,
        fullScreenIntent: false,
        timeoutAfter: null,
        groupKey: 'chat_messages',
        setAsGroupSummary: false,
        number: badgeCount,
      );

      // Enhanced iOS notification with badge
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default.wav',
        badgeNumber: totalBadges,
        threadIdentifier: data['chatId']?.toString() ?? 'chat_thread',
        categoryIdentifier: 'MESSAGE_CATEGORY',
        interruptionLevel: InterruptionLevel.active,
        subtitle: badgeCount > 1 ? '$badgeCount messages' : null,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final notificationId = _generateNotificationId(data);
      
      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: jsonEncode({
          ...data,
          'badgeCount': badgeCount,
          'totalBadges': totalBadges,
        }),
      );

      developer.log('📱 ✅ Notification with badge shown successfully');
      
    } catch (e) {
      developer.log('📱 ❌ Error showing notification with badge: $e');
    }
  }

  List<AndroidNotificationAction> _getNotificationActions(Map<String, dynamic> data) {
    if (data['type'] == 'chat' || data['type'] == 'message') {
      return [
        const AndroidNotificationAction(
          'reply',
          'Reply',
          inputs: [
            AndroidNotificationActionInput(
              label: 'Type a message...',
            ),
          ],
        ),
        const AndroidNotificationAction(
          'mark_read',
          'Mark as Read',
        ),
      ];
    } else if (data['type'] == 'call') {
      return [
        const AndroidNotificationAction(
          'accept_call',
          'Answer',
          titleColor: Colors.green,
        ),
        const AndroidNotificationAction(
          'decline_call',
          'Decline',
          titleColor: Colors.red,
        ),
      ];
    }
    return [];
  }

  int _generateNotificationId(Map<String, dynamic> data) {
    final chatId = data['chatId']?.toString() ?? '';
    final callId = data['callId']?.toString() ?? '';
    
    if (callId.isNotEmpty) {
      return callId.hashCode.abs();
    } else if (chatId.isNotEmpty) {
      return chatId.hashCode.abs();
    }
    return DateTime.now().millisecondsSinceEpoch.remainder(100000);
  }

  String _getChannelName(String channelId) {
    switch (channelId) {
      case _chatChannelId:
        return 'Chat Messages';
      case _callChannelId:
        return 'Calls';
      case _generalChannelId:
        return 'General Notifications';
      default:
        return 'Notifications';
    }
  }

  String _getChannelDescription(String channelId) {
    switch (channelId) {
      case _chatChannelId:
        return 'Notifications for new chat messages';
      case _callChannelId:
        return 'Incoming call notifications';
      case _generalChannelId:
        return 'General app notifications';
      default:
        return 'App notifications';
    }
  }

  // Handle notification tap response
  void _onNotificationTapped(NotificationResponse response) {
    developer.log('👆 Notification tapped with badge handling: ${response.actionId}');
    
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        
        // Handle specific actions
        switch (response.actionId) {
          case 'reply':
            _handleQuickReplyWithBadge(data, response.input);
            break;
          case 'mark_read':
            _handleMarkAsReadWithBadge(data);
            break;
          // case 'accept_call':
          //   _handleCallNotificationAction('accept_call', data);
          //   break;
          // case 'decline_call':
          //   _handleCallNotificationAction('decline_call', data);
          //   break;
          default:
            _handleNotificationTapWithBadge(data);
            break;
        }
      } catch (e) {
        developer.log('❌ Error handling notification tap with badge: $e');
      }
    }
  }

  void _handleQuickReplyWithBadge(Map<String, dynamic> data, String? replyText) {
    if (replyText == null || replyText.trim().isEmpty) return;
    
    try {
      if (!Get.isRegistered<FireChatController>()) {
        developer.log('⚠️ Chat controller not available for quick reply');
        return;
      }
      
      final chatController = Get.find<FireChatController>();
      final receiverId = data['senderId']?.toString() ?? '';
      final chatId = data['chatId']?.toString() ?? '';
      
      if (receiverId.isNotEmpty) {
        chatController.sendMessage(
          receiverId: receiverId,
          message: replyText.trim(),
        );
        
        // Clear badge for this chat after replying
        if (chatId.isNotEmpty) {
          chatController.clearBadgeForChat(chatId);
        }
        
        // Show confirmation
        Get.snackbar(
          'Reply Sent',
          'Your message has been sent',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );
      }
    } catch (e) {
      developer.log('❌ Error sending quick reply with badge: $e');
    }
  }

  void _handleMarkAsReadWithBadge(Map<String, dynamic> data) {
    try {
      if (!Get.isRegistered<FireChatController>()) {
        developer.log('⚠️ Chat controller not available for mark as read');
        return;
      }
      
      final chatController = Get.find<FireChatController>();
      final chatId = data['chatId']?.toString() ?? '';
      
      if (chatId.isNotEmpty) {
        // Mark messages as read
        chatController.markMessagesAsRead(chatId);
        
        // Clear badge immediately
        chatController.clearBadgeForChat(chatId);
        
        // Cancel notification
        _flutterLocalNotificationsPlugin.cancel(_generateNotificationId(data));
        
        Get.snackbar(
          'Marked as Read',
          'Messages marked as read',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.green,
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );
      }
    } catch (e) {
      developer.log('❌ Error marking as read with badge: $e');
    }
  }

  void _handleNotificationTapWithBadge(Map<String, dynamic> data) {
    try {
      developer.log('👆 Handling notification tap with badge: $data');
      
      final type = data['type']?.toString() ?? '';
      final chatId = data['chatId']?.toString() ?? '';
      
      // Clear badge when tapping notification
      if (chatId.isNotEmpty && Get.isRegistered<FireChatController>()) {
        final chatController = Get.find<FireChatController>();
        chatController.clearBadgeForChat(chatId);
      }
      
      switch (type) {
        case 'chat':
        case 'message':
          _navigateToChatWithBadge(data);
          break;
        // case 'call':
        //   _handleCallNotification(data);
        //   break;
        default:
          Get.toNamed('/home');
          break;
      }
    } catch (e) {
      developer.log('❌ Error handling notification tap with badge: $e');
    }
  }

  void _navigateToChatWithBadge(Map<String, dynamic> data) {
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
        
        // Mark messages as read and clear badge
        if (Get.isRegistered<FireChatController>()) {
          final chatController = Get.find<FireChatController>();
          if (chatId.isNotEmpty) {
            chatController.markMessagesAsRead(chatId);
            chatController.clearBadgeForChat(chatId);
          }
        }
      }
    } catch (e) {
      developer.log('❌ Error navigating to chat with badge: $e');
    }
  }

  // Handle notification tap
  void _handleNotificationTap(Map<String, dynamic> data) {
    try {
      developer.log('👆 Handling notification tap: $data');
      
      final type = data['type']?.toString() ?? '';
      
      switch (type) {
        case 'chat':
        case 'message':
          _navigateToChat(data);
          break;
        // case 'call':
        //   _handleCallNotification(data);
        //   break;
        default:
          // Navigate to home
          Get.toNamed('/home');
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
        if (Get.isRegistered<FireChatController>()) {
          final chatController = Get.find<FireChatController>();
          if (chatId.isNotEmpty) {
            chatController.markMessagesAsRead(chatId);
          }
        }
      }
    } catch (e) {
      developer.log('❌ Error navigating to chat: $e');
    }
  }

  // void _handleCallNotification(Map<String, dynamic> data) {
  //   developer.log('📞 Handling call notification: $data');
    
  //   // Show incoming call screen
  //   Get.to(
  //     () => IncomingCallScreen(callData: data),
  //     transition: Transition.fadeIn,
  //     fullscreenDialog: true,
  //   );
  // }

  // iOS-specific callback
  static void _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    developer.log('📱 iOS local notification received: $title');
    if (payload != null) {
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        FirebaseNotificationService()._handleNotificationTap(data);
      } catch (e) {
        developer.log('❌ Error parsing iOS notification payload: $e');
      }
    }
  }

  // Public methods
  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      developer.log('❌ Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      developer.log('✅ Subscribed to topic: $topic');
    } catch (e) {
      developer.log('❌ Error subscribing to topic $topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      developer.log('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      developer.log('❌ Error unsubscribing from topic $topic: $e');
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      developer.log('✅ All notifications cleared');
    } catch (e) {
      developer.log('❌ Error clearing notifications: $e');
    }
  }

  Future<void> clearNotification(int id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      developer.log('✅ Notification $id cleared');
    } catch (e) {
      developer.log('❌ Error clearing notification $id: $e');
    }
  }

  // Show custom notification
  Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? channelId,
    int? id,
    int badgeCount = 1,
  }) async {
    await _showLocalNotificationWithBadge(
      title: title,
      body: body,
      data: data ?? {},
      channelId: channelId ?? _generalChannelId,
      badgeCount: badgeCount,
    );
  }

  // Test notification method
  Future<void> showTestNotification() async {
    developer.log('🧪 Showing test notification...');
    await showNotification(
      title: 'Test Notification',
      body: 'This is a test notification to verify the foreground setup',
      data: {'type': 'test'},
    );
  }

  // Debug method to check notification status
  Future<void> debugNotificationStatus() async {
    try {
      developer.log('📱 === NOTIFICATION DEBUG STATUS ===');
      
      // Check if initialized
      developer.log('📱 Service initialized: $_isInitialized');
      
      // Check pending notifications
      final pending = await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      developer.log('📱 Pending notifications: ${pending.length}');
      
      // Check active notifications (Android only)
      if (Platform.isAndroid) {
        final activeNotifications = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.getActiveNotifications();
        developer.log('📱 Active notifications: ${activeNotifications?.length ?? 0}');
      }
      
      // Check FCM token
      final token = await getFCMToken();
      developer.log('📱 FCM token available: ${token != null}');
      
      developer.log('📱 === END NOTIFICATION DEBUG STATUS ===');
    } catch (e) {
      developer.log('❌ Error in debug status: $e');
    }
  }
}
