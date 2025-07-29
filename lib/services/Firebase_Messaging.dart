import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/Authorization/firebase_services.dart';
import 'package:innovator/screens/chatApp/controller/chat_controller.dart';
import 'dart:developer' as developer;

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance = FirebaseNotificationService._internal();
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
      developer.log('🔔 Initializing Firebase Notification Service...');

      // Request permissions first
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize Firebase messaging
      await _initializeFirebaseMessaging();

      // Setup message handlers
      _setupMessageHandlers();

      _isInitialized = true;
      developer.log('✅ Firebase Notification Service initialized successfully');
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
      }
    } catch (e) {
      developer.log('❌ Error requesting permissions: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    try {
      developer.log('📱 Initializing local notifications...');
      
      // Android initialization
      const androidInitialization = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization
      const iosInitialization = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
      );

      const initializationSettings = InitializationSettings(
        android: androidInitialization,
        iOS: iosInitialization,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channels for Android
      await _createNotificationChannels();
      
      developer.log('✅ Local notifications initialized');
    } catch (e) {
      developer.log('❌ Error initializing local notifications: $e');
    }
  }

  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    try {
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        // Chat messages channel - CRITICAL: This must match FCM payload
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'chat_messages',
            'Chat Messages',
            description: 'Notifications for new chat messages',
            importance: Importance.high,
            enableVibration: true,
            enableLights: true,
            ledColor: Color.fromRGBO(244, 135, 6, 1),
            showBadge: true,
            playSound: true,
          ),
        );

        // General notifications channel
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'general_notifications',
            'General Notifications',
            description: 'General app notifications',
            importance: Importance.defaultImportance,
            enableVibration: true,
            showBadge: true,
          ),
        );

        // Call notifications channel
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
          ),
        );

        developer.log('✅ Android notification channels created successfully');
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
    
    // Foreground messages - ALWAYS show notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('📨 Foreground message received: ${message.messageId}');
      handleForegroundMessage(message);
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

  // ENHANCED: Handle foreground messages with better suppression logic
  Future<void> handleForegroundMessage(RemoteMessage message) async {
    try {
      developer.log('📱 === FOREGROUND MESSAGE HANDLER START ===');
      developer.log('📱 Message ID: ${message.messageId}');
      developer.log('📱 Data: ${message.data}');
      developer.log('📱 Notification: ${message.notification?.toMap()}');
      
      final notification = message.notification;
      final data = message.data;
      
      // Extract notification details
      String title = notification?.title ?? data['senderName'] ?? 'New Message';
      String body = notification?.body ?? data['message'] ?? 'You have a new message';
      
      developer.log('📱 Processed - Title: $title, Body: $body');

      // INTELLIGENT SUPPRESSION: Check if we should suppress this notification
      final shouldSuppress = _shouldSuppressForegroundNotification(data);
      developer.log('🔇 Should suppress: $shouldSuppress');
      
      if (shouldSuppress) {
        developer.log('🔇 Foreground notification suppressed - user actively chatting');
        
        // OPTIONAL: Still update badge count even if suppressing visual notification
        await _updateBadgeCount(data);
        return;
      }

      // Show local notification for foreground
      await _showLocalNotification(
        title: title,
        body: body,
        data: data,
        channelId: _chatChannelId,
      );

      // Update badge count
      await _updateBadgeCount(data);

      developer.log('✅ Foreground notification processed successfully');
      developer.log('=== END FOREGROUND MESSAGE HANDLER ===');

    } catch (e) {
      developer.log('❌ Error handling foreground message: $e');
    }
  }



  // IMPROVED: More refined suppression logic
  bool _shouldSuppressForegroundNotification(Map<String, dynamic> data) {
    try {
      final chatId = data['chatId']?.toString() ?? '';
      final senderId = data['senderId']?.toString() ?? '';
      
      // Don't suppress if no chat context
      if (chatId.isEmpty) return false;
      
      // Check if we have a chat controller
      if (!Get.isRegistered<FireChatController>()) {
        developer.log('🔇 No chat controller registered, showing notification');
        return false;
      }
      
      final chatController = Get.find<FireChatController>();
      
      // STRATEGY 1: Check if user is in the same chat
      final currentChatId = chatController.currentChatId.value;
      final isInSameChat = currentChatId == chatId;
      
      developer.log('💬 Current chat: $currentChatId');
      developer.log('💬 Message chat: $chatId');
      developer.log('💬 Is in same chat: $isInSameChat');
      
      // STRATEGY 2: Check if user is actively typing or recently active
      final isTyping = chatController.isTyping.value;
      final lastActivityTime = chatController.lastMessageTimes[chatId];
      
      bool isRecentlyActive = false;
      if (lastActivityTime != null) {
        final timeSinceLastActivity = DateTime.now().difference(lastActivityTime);
        isRecentlyActive = timeSinceLastActivity.inSeconds < 30; // 30 seconds threshold
      }
      
      developer.log('⌨️ User is typing: $isTyping');
      developer.log('🕒 Recently active in chat: $isRecentlyActive');
      
      // STRATEGY 3: Check current route
      final currentRoute = Get.currentRoute;
      final isInChatScreen = currentRoute.contains('/chat');
      
      developer.log('📍 Current route: $currentRoute');
      developer.log('📍 Is in chat screen: $isInChatScreen');
      
      // SUPPRESSION DECISION:
      // Suppress if user is in the same chat AND (typing OR recently active OR in chat screen)
      final shouldSuppress = isInSameChat && (isTyping || isRecentlyActive || isInChatScreen);
      
      developer.log('🤔 Suppression decision: $shouldSuppress');
      developer.log('   Reasons: inSameChat=$isInSameChat, typing=$isTyping, recentlyActive=$isRecentlyActive, inChatScreen=$isInChatScreen');
      
      return shouldSuppress;
      
    } catch (e) {
      developer.log('❌ Error checking notification suppression: $e');
      return false; // Show notification on error
    }
  }

  Future<void> _showLocalNotification({
  required String title,
  required String body,
  required Map<String, dynamic> data,
  required String channelId,
}) async {
  try {
    developer.log('📱 Showing local notification: $title');
    
    // FIXED: Corrected AndroidNotificationDetails structure
    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      channelDescription: _getChannelDescription(channelId),
      importance: Importance.high,
      priority: Priority.high, // This is correct for local notifications
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        body,
        htmlFormatBigText: true,
        contentTitle: title,
        htmlFormatContentTitle: true,
      ),
      actions: _getNotificationActions(data),
      // FIXED: Corrected local notification properties
      autoCancel: true,
      ongoing: false,
      visibility: NotificationVisibility.public, // This is correct for local notifications
      ticker: '$title: $body',
      enableVibration: true,
      enableLights: true,
      ledColor: const Color.fromRGBO(244, 135, 6, 1),
      // REMOVED: Invalid properties that were causing confusion
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default.wav',
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
      payload: jsonEncode(data),
    );

    developer.log('✅ Local notification shown with ID: $notificationId');
  } catch (e) {
    developer.log('❌ Error showing local notification: $e');
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
    }
    return [];
  }

  int _generateNotificationId(Map<String, dynamic> data) {
    final chatId = data['chatId']?.toString() ?? '';
    if (chatId.isNotEmpty) {
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
      default:
        return 'General Notifications';
    }
  }

  String _getChannelDescription(String channelId) {
    switch (channelId) {
      case _chatChannelId:
        return 'Notifications for new chat messages';
      case _callChannelId:
        return 'Incoming call notifications';
      default:
        return 'General app notifications';
    }
  }

  Future<void> _updateBadgeCount(Map<String, dynamic> data) async {
    try {
      if (!Get.isRegistered<FireChatController>()) return;
      
      final chatController = Get.find<FireChatController>();
      final chatId = data['chatId']?.toString() ?? '';
      
      if (chatId.isNotEmpty) {
        final currentCount = chatController.unreadCounts[chatId] ?? 0;
        chatController.unreadCounts[chatId] = currentCount + 1;
        
        if (!chatController.badgeCounts.containsKey(chatId)) {
          chatController.badgeCounts[chatId] = 0.obs;
        }
        chatController.badgeCounts[chatId]!.value = currentCount + 1;
        
        developer.log('📊 Badge count updated for chat $chatId: ${currentCount + 1}');
      }
    } catch (e) {
      developer.log('❌ Error updating badge count: $e');
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
        case 'call':
          _handleCallNotification(data);
          break;
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

  void _handleCallNotification(Map<String, dynamic> data) {
    developer.log('📞 Handling call notification: $data');
    // Implement call handling logic
  }

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

  // Handle notification tap response
  void _onNotificationTapped(NotificationResponse response) {
    developer.log('👆 Notification tapped: ${response.actionId}');
    
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        
        // Handle specific actions
        switch (response.actionId) {
          case 'reply':
            _handleQuickReply(data, response.input);
            break;
          case 'mark_read':
            _handleMarkAsRead(data);
            break;
          default:
            _handleNotificationTap(data);
            break;
        }
      } catch (e) {
        developer.log('❌ Error handling notification tap: $e');
      }
    }
  }

  void _handleQuickReply(Map<String, dynamic> data, String? replyText) {
    if (replyText == null || replyText.trim().isEmpty) return;
    
    try {
      if (!Get.isRegistered<FireChatController>()) {
        developer.log('⚠️ Chat controller not available for quick reply');
        return;
      }
      
      final chatController = Get.find<FireChatController>();
      final receiverId = data['senderId']?.toString() ?? '';
      
      if (receiverId.isNotEmpty) {
        chatController.sendMessage(
          receiverId: receiverId,
          message: replyText.trim(),
        );
        
        // Show confirmation
        Get.snackbar(
          'Sent',
          'Your reply has been sent',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
          backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      developer.log('❌ Error sending quick reply: $e');
    }
  }

  void _handleMarkAsRead(Map<String, dynamic> data) {
    try {
      if (!Get.isRegistered<FireChatController>()) {
        developer.log('⚠️ Chat controller not available for mark as read');
        return;
      }
      
      final chatController = Get.find<FireChatController>();
      final chatId = data['chatId']?.toString() ?? '';
      
      if (chatId.isNotEmpty) {
        chatController.markMessagesAsRead(chatId);
        
        // Clear badge
        chatController.clearBadge(chatId);
        
        // Cancel notification
        _flutterLocalNotificationsPlugin.cancel(_generateNotificationId(data));
        
        Get.snackbar(
          'Marked as Read',
          'Messages marked as read',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      developer.log('❌ Error marking as read: $e');
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
  }) async {
    await _showLocalNotification(
      title: title,
      body: body,
      data: data ?? {},
      channelId: channelId ?? _generalChannelId,
    );
  }

  // Test notification method
  Future<void> showTestNotification() async {
    await showNotification(
      title: 'Test Notification',
      body: 'This is a test notification to verify the setup',
      data: {'type': 'test'},
    );
  }
}