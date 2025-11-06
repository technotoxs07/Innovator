// FIXED: Notification_Like.dart - Enhanced notification handling
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // FIXED: Matching channel IDs with backend
  static const AndroidNotificationChannel highImportanceChannel = 
      AndroidNotificationChannel(
    'high_importance_channel', // Must match backend _getChannelId
    'High Importance Notifications',
    description: 'Critical notifications for likes, comments, and messages',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
    enableLights: true,
    ledColor: Color(0xFFF48706),
  );

  static const AndroidNotificationChannel chatChannel = 
      AndroidNotificationChannel(
    'chat_messages', // Must match backend for chat messages
    'Chat Messages',
    description: 'Notifications for chat messages',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  static const AndroidNotificationChannel regularChannel = 
      AndroidNotificationChannel(
    'regular_channel', // Must match backend _getChannelId
    'Regular Notifications',
    description: 'General app notifications',
    importance: Importance.defaultImportance,
    playSound: true,
    enableVibration: true,
  );

  Future<void> initialize() async {
    try {
      developer.log('🔔 Initializing NotificationService...');
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Create notification channels for Android
      await _createNotificationChannels();
      
      // Request permissions
      await _requestPermissions();
      
      // Setup message handlers
      _setupMessageHandlers();
      
      developer.log('✅ NotificationService initialized successfully');
    } catch (e) {
      developer.log('❌ Error initializing notifications: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true, // Add for critical alerts
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTapped,
    );
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Create all channels
      await androidPlugin.createNotificationChannel(highImportanceChannel);
      await androidPlugin.createNotificationChannel(chatChannel);
      await androidPlugin.createNotificationChannel(regularChannel);
      
      developer.log('✅ Android notification channels created');
    }
  }

  Future<void> _requestPermissions() async {
    final messaging = FirebaseMessaging.instance;
    
    // Request enhanced permissions
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: true,
      carPlay: false,
      announcement: false,
    );
    
    developer.log('🔥 FCM permission status: ${settings.authorizationStatus}');
    
    // Check if notifications are enabled
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      developer.log('✅ Notifications fully authorized');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      developer.log('⚠️ Provisional notification permission');
    } else {
      developer.log('❌ Notifications not authorized');
    }
  }

  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('📨 Foreground message received: ${message.messageId}');
      handleForegroundMessage(message);
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log('📱 App opened from notification: ${message.messageId}');
      _handleNotificationNavigation(message.data);
    });

    // Check for initial message (app launched from terminated state)
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        developer.log('🚀 App launched from notification: ${message.messageId}');
        Future.delayed(const Duration(seconds: 1), () {
          _handleNotificationNavigation(message.data);
        });
      }
    });
  }

  // FIXED: Enhanced foreground message handler
  Future<void> handleForegroundMessage(RemoteMessage message) async {
    try {
      developer.log('🔥 Processing foreground message...');
      developer.log('Data: ${message.data}');
      developer.log('Notification: ${message.notification?.toMap()}');
      
      final data = message.data;
      final notification = message.notification;
      final notificationType = data['type']?.toString().toLowerCase() ?? '';
      
      // Check if notification should be suppressed (user is in the same chat)
      if (notificationType == 'chat' || notificationType == 'message') {
        final chatId = data['chatId']?.toString() ?? '';
        // Check if user is currently viewing this chat
        if (_isUserInChat(chatId)) {
          developer.log('📵 Suppressing notification - user in chat');
          return;
        }
      }
      
      switch (notificationType) {
        case 'like':
          await showLikeNotification(
            userName: data['senderName'] ?? data['userName'] ?? 'Someone',
            postTitle: data['itemType'] ?? data['postTitle'] ?? 'your post',
            data: data,
          );
          break;
          
        case 'comment':
        case 'comment_reply':
          await showCommentNotification(
            userName: data['senderName'] ?? data['userName'] ?? 'Someone',
            comment: data['comment'] ?? data['body'] ?? 'commented on your post',
            postTitle: data['itemType'] ?? data['postTitle'] ?? 'your post',
            isReply: notificationType == 'comment_reply',
            data: data,
          );
          break;
          
        case 'follow':
          await showFollowNotification(
            userName: data['senderName'] ?? data['userName'] ?? 'Someone',
            userPicture: data['senderPicture'] ?? data['userPicture'],
            data: data,
          );
          break;
          
        case 'message':
        case 'chat':
          await showChatNotification(
            senderName: data['senderName'] ?? 'Someone',
            message: data['message'] ?? notification?.body ?? 'New message',
            data: data,
          );
          break;
          
        default:
          // Show generic notification
          if (notification != null) {
            await showNotification(
              id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
              title: notification.title ?? 'New Notification',
              body: notification.body ?? 'You have a new notification',
              payload: jsonEncode(data),
              channelId: _getChannelIdForType(notificationType),
            );
          }
      }
    } catch (e) {
      developer.log('❌ Error handling foreground message: $e');
    }
  }

  // Helper to check if user is currently in a specific chat
  bool _isUserInChat(String chatId) {
    // Check current route
    final currentRoute = Get.currentRoute;
    final routeArgs = Get.arguments as Map<String, dynamic>?;
    
    if (currentRoute == '/chat' && routeArgs != null) {
      final currentChatId = routeArgs['chatId']?.toString() ?? '';
      return currentChatId == chatId;
    }
    
    return false;
  }

  // FIXED: Core notification display with proper channel
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? channelId,
  }) async {
    try {
      developer.log('🔔 Showing notification - Title: $title');
      
      // Determine channel based on importance
      final channel = channelId ?? 'regular_channel';
      
      final androidDetails = AndroidNotificationDetails(
        channel,
        _getChannelName(channel),
        channelDescription: _getChannelDescription(channel),
        importance: _getChannelImportance(channel),
        priority: Priority.high,
        color: const Color(0xFFF48706),
        enableVibration: true,
        playSound: true,
        visibility: NotificationVisibility.public,
        autoCancel: true,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: null,
        ),
        groupKey: 'com.example.innovator',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        badgeNumber: 1,
        interruptionLevel: InterruptionLevel.active,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      
      developer.log('✅ Notification displayed successfully');
    } catch (e) {
      developer.log('❌ Error showing notification: $e');
    }
  }

  // Channel helper methods
  String _getChannelIdForType(String type) {
    switch(type) {
      case 'like':
      case 'comment':
      case 'follow':
        return 'high_importance_channel';
      case 'message':
      case 'chat':
        return 'chat_messages';
      default:
        return 'regular_channel';
    }
  }

  String _getChannelName(String channelId) {
    switch(channelId) {
      case 'high_importance_channel':
        return 'High Importance Notifications';
      case 'chat_messages':
        return 'Chat Messages';
      default:
        return 'Regular Notifications';
    }
  }

  String _getChannelDescription(String channelId) {
    switch(channelId) {
      case 'high_importance_channel':
        return 'Critical notifications for social interactions';
      case 'chat_messages':
        return 'Notifications for chat messages';
      default:
        return 'General app notifications';
    }
  }

  Importance _getChannelImportance(String channelId) {
    switch(channelId) {
      case 'high_importance_channel':
        return Importance.max;
      case 'chat_messages':
        return Importance.high;
      default:
        return Importance.defaultImportance;
    }
  }

  // Specific notification methods
  Future<void> showLikeNotification({
    required String userName,
    required String postTitle,
    Map<String, dynamic>? data,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: 'New Like! 👍',
      body: '$userName liked your $postTitle',
      payload: jsonEncode(data ?? {'type': 'like'}),
      channelId: 'high_importance_channel',
    );
  }

  Future<void> showCommentNotification({
    required String userName,
    required String comment,
    required String postTitle,
    bool isReply = false,
    Map<String, dynamic>? data,
  }) async {
    final truncatedComment = comment.length > 50 
        ? '${comment.substring(0, 47)}...' 
        : comment;

    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: isReply ? 'New Reply! 💬' : 'New Comment! 💬',
      body: '$userName: $truncatedComment',
      payload: jsonEncode(data ?? {'type': 'comment'}),
      channelId: 'high_importance_channel',
    );
  }

  Future<void> showFollowNotification({
    required String userName,
    String? userPicture,
    Map<String, dynamic>? data,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: 'New Follower! 🎉',
      body: '$userName started following you',
      payload: jsonEncode(data ?? {'type': 'follow'}),
      channelId: 'high_importance_channel',
    );
  }

  Future<void> showChatNotification({
    required String senderName,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    final truncatedMessage = message.length > 100
        ? '${message.substring(0, 97)}...'
        : message;

    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: senderName,
      body: truncatedMessage,
      payload: jsonEncode(data ?? {'type': 'chat'}),
      channelId: 'chat_messages',
    );
  }

  // Notification tap handlers
  void _onNotificationTapped(NotificationResponse response) {
    developer.log('🔔 Notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _handleNotificationNavigation(data);
      } catch (e) {
        developer.log('❌ Error parsing notification payload: $e');
      }
    }
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    // Handle background notification tap
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        // Navigate to appropriate screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.toNamed('/home', arguments: data);
        });
      } catch (e) {
        developer.log('Error handling background notification tap: $e');
      }
    }
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type']?.toString().toLowerCase() ?? '';
    
    developer.log('🚀 Navigating from notification - Type: $type');
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (type) {
        case 'like':
        case 'comment':
        case 'comment_reply':
          final itemId = data['itemId'] ?? data['uid'];
          if (itemId != null) {
            Get.toNamed('/post-detail', arguments: {
              'postId': itemId,
              'scrollToComments': type.contains('comment'),
            });
          } else {
            Get.toNamed('/home');
          }
          break;
          
        case 'follow':
          final userId = data['senderId'] ?? data['userId'];
          if (userId != null) {
            Get.toNamed('/profile', arguments: {
              'userId': userId,
              'userName': data['senderName'] ?? data['userName'],
            });
          }
          break;
          
        case 'message':
        case 'chat':
          final senderId = data['senderId'];
          final senderName = data['senderName'];
          final chatId = data['chatId'];
          
          if (senderId != null) {
            Get.toNamed('/chat', arguments: {
              'receiverUser': {
                'id': senderId,
                'userId': senderId,
                '_id': senderId,
                'name': senderName ?? 'User',
              },
              'chatId': chatId,
              'fromNotification': true,
            });
          }
          break;
          
        default:
          Get.toNamed('/home');
      }
    });
  }
}