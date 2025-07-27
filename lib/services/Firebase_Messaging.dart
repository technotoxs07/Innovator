import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
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

  // Notification channels
  static const String _chatChannelId = 'chat_messages';
  static const String _generalChannelId = 'general_notifications';
  static const String _callChannelId = 'call_notifications';

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      developer.log('🔔 Initializing Notification Service...');

      // Request permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize Firebase messaging
      await _initializeFirebaseMessaging();

      // Setup message handlers
      _setupMessageHandlers();

      _isInitialized = true;
      developer.log('✅ Notification Service initialized successfully');
    } catch (e) {
      developer.log('❌ Error initializing notification service: $e');
    }
  }

  Future<void> _requestPermissions() async {
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
      await plugin?.requestNotificationsPermission();
    }
  }

  Future<void> _initializeLocalNotifications() async {
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
  }

  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Chat messages channel
      await androidPlugin.createNotificationChannel(
         AndroidNotificationChannel(
          _chatChannelId,
          'Chat Messages',
          description: 'Notifications for new chat messages',
          importance: Importance.high,
          sound: RawResourceAndroidNotificationSound('notification_sound'),
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
          enableLights: true,
          ledColor: Color.fromARGB(255, 244, 135, 6),
        ),
      );

      // General notifications channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _generalChannelId,
          'General Notifications',
          description: 'General app notifications',
          importance: Importance.defaultImportance,
        ),
      );

      // Call notifications channel
      await androidPlugin.createNotificationChannel(
         AndroidNotificationChannel(
          _callChannelId,
          'Calls',
          description: 'Incoming call notifications',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('call_sound'),
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
        ),
      );
    }
  }

  Future<void> _initializeFirebaseMessaging() async {
    // Get FCM token
    final token = await _firebaseMessaging.getToken();
    developer.log('📱 FCM Token: $token');

    // Save token to user data
    if (token != null) {
      await _saveTokenToUserData(token);
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      developer.log('🔄 FCM Token refreshed: $newToken');
      _saveTokenToUserData(newToken);
    });
  }

  Future<void> _saveTokenToUserData(String token) async {
    try {
      final userData = AppData().currentUser;
      if (userData != null && userData.isNotEmpty) {
        final userId = userData['_id']?.toString() ?? 
                      userData['uid']?.toString() ?? '';
        
        if (userId.isNotEmpty) {
          // Update user's FCM token in Firebase
          await FirebaseService.updateUserFCMToken(userId, token);
          developer.log('✅ FCM token saved for user: $userId');
        }
      }
    } catch (e) {
      developer.log('❌ Error saving FCM token: $e');
    }
  }

  void _setupMessageHandlers() {
    // Foreground messages
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
        _handleNotificationTap(message.data);
      }
    });
  }

  // Handle foreground messages
  Future<void> handleForegroundMessage(RemoteMessage message) async {
    try {
      developer.log('📱 Processing foreground message...');
      
      final notification = message.notification;
      final data = message.data;
      
      if (notification == null) return;

      // Check if user is currently in the chat screen for this message
      if (_shouldSuppressNotification(data)) {
        developer.log('🔇 Notification suppressed - user in active chat');
        return;
      }

      // Show local notification
      await _showLocalNotification(
        title: notification.title ?? 'New Message',
        body: notification.body ?? '',
        data: data,
        channelId: _getChannelId(data['type']),
      );

      // Update badge count
      await _updateBadgeCount(data);

    } catch (e) {
      developer.log('❌ Error handling foreground message: $e');
    }
  }

  bool _shouldSuppressNotification(Map<String, dynamic> data) {
  try {
    // Check if GetX is initialized and controller exists
    if (!Get.isRegistered<FireChatController>()) {
      return false;
    }
    
    final chatController = Get.find<FireChatController>();
    final currentChatId = chatController.currentChatId.value;
    final messageChatId = data['chatId']?.toString() ?? '';
    
    // Also check if app is in foreground and user is actively viewing the chat
    final isAppVisible = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    
    return isAppVisible && 
           currentChatId.isNotEmpty && 
           currentChatId == messageChatId;
  } catch (e) {
    developer.log('Error checking notification suppression: $e');
    return false;
  }
}

  String _getChannelId(String? type) {
    switch (type) {
      case 'chat':
      case 'message':
        return _chatChannelId;
      case 'call':
        return _callChannelId;
      default:
        return _generalChannelId;
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required String channelId,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        _getChannelName(channelId),
        channelDescription: _getChannelDescription(channelId),
        importance: Importance.high,
        priority: Priority.high,
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
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification_sound.wav',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        _generateNotificationId(data),
        title,
        body,
        notificationDetails,
        payload: jsonEncode(data),
      );

      developer.log('✅ Local notification shown: $title');
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
    // Generate unique ID based on chat ID or use timestamp
    final chatId = data['chatId']?.toString() ?? '';
    if (chatId.isNotEmpty) {
      return chatId.hashCode;
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
      final chatController = Get.find<FireChatController>();
      final chatId = data['chatId']?.toString() ?? '';
      
      if (chatId.isNotEmpty) {
        final currentCount = chatController.unreadCounts[chatId] ?? 0;
        chatController.unreadCounts[chatId] = currentCount + 1;
        
        if (!chatController.badgeCounts.containsKey(chatId)) {
          chatController.badgeCounts[chatId] = 0.obs;
        }
        chatController.badgeCounts[chatId]!.value = currentCount + 1;
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
      final screen = data['screen']?.toString() ?? '';
      
      switch (type) {
        case 'chat':
        case 'message':
          _navigateToChat(data);
          break;
        case 'call':
          _handleCallNotification(data);
          break;
        default:
          if (screen.isNotEmpty) {
            Get.toNamed(screen, arguments: data);
          }
          break;
      }
    } catch (e) {
      developer.log('❌ Error handling notification tap: $e');
    }
  }

  void _navigateToChat(Map<String, dynamic> data) {
    try {
      final receiverUserId = data['senderId']?.toString() ?? '';
      final chatId = data['chatId']?.toString() ?? '';
      
      if (receiverUserId.isNotEmpty) {
        // Navigate to chat screen
        Get.toNamed('/chat', arguments: {
          'receiverUserId': receiverUserId,
          'chatId': chatId,
          'fromNotification': true,
        });
        
        // Mark messages as read
        final chatController = Get.find<FireChatController>();
        if (chatId.isNotEmpty) {
          chatController.markMessagesAsRead(chatId);
        }
      }
    } catch (e) {
      developer.log('❌ Error navigating to chat: $e');
    }
  }

  void _handleCallNotification(Map<String, dynamic> data) {
    // Handle call notification - navigate to call screen
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
        );
      }
    } catch (e) {
      developer.log('❌ Error sending quick reply: $e');
    }
  }

  void _handleMarkAsRead(Map<String, dynamic> data) {
    try {
      final chatController = Get.find<FireChatController>();
      final chatId = data['chatId']?.toString() ?? '';
      
      if (chatId.isNotEmpty) {
        chatController.markMessagesAsRead(chatId);
        
        // Clear badge
        chatController.clearBadge(chatId);
        
        // Cancel notification
        _flutterLocalNotificationsPlugin.cancel(_generateNotificationId(data));
      }
    } catch (e) {
      developer.log('❌ Error marking as read: $e');
    }
  }

  // Public methods
  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
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
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> clearNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  // Show custom notification
  Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? channelId,
  }) async {
    await _showLocalNotification(
      title: title,
      body: body,
      data: data ?? {},
      channelId: channelId ?? _generalChannelId,
    );
  }
}