import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/firebase_options.dart';
import 'package:innovator/screens/Feed/Services/Feed_Cache_service.dart';
import 'package:innovator/screens/Shop/CardIconWidget/cart_state_manager.dart';
import 'package:innovator/screens/Shop/Shop_Page.dart';
import 'package:innovator/screens/Splash_Screen/splash_screen.dart';
import 'package:innovator/controllers/user_controller.dart';
import 'package:innovator/screens/chatApp/Add_to_Chat.dart';
import 'package:innovator/screens/chatApp/SearchchatUser.dart';
import 'package:innovator/screens/chatApp/chat_homepage.dart';
import 'package:innovator/screens/chatApp/chatlistpage.dart';
import 'package:innovator/screens/chatApp/chatscreen.dart';
import 'package:innovator/screens/chatApp/controller/chat_controller.dart';
import 'package:innovator/services/Firebase_Messaging.dart';
import 'package:innovator/services/Notification_services.dart';
import 'package:innovator/services/fcm_handler.dart';
import 'package:innovator/utils/Drawer/drawer_cache_manager.dart';
import 'dart:developer' as developer;

// Global variables and constants
late Size mq;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    developer.log('🔥 Background Message Received: ${message.messageId}');
    
    // Initialize Firebase if not already done
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    
    // Handle the notification display
    await _handleBackgroundNotification(message);
    
    developer.log('✅ Background notification processed: ${message.messageId}');
  } catch (e) {
    developer.log('❌ Error handling background message: $e');
  }
}

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

Future<void> _initializeBackgroundNotifications(FlutterLocalNotificationsPlugin plugin) async {
  try {
    const androidInitialization = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInitialization = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidInitialization,
      iOS: iosInitialization,
    );
    
    await plugin.initialize(initializationSettings);
    
    // Create notification channel for Android
    final androidPlugin = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
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
        ),
      );
    }
    
    developer.log('✅ Background notifications initialized');
  } catch (e) {
    developer.log('❌ Error initializing background notifications: $e');
  }
}

Future<void> _ensureFreshFCMToken() async {
  try {
    developer.log('🔄 Ensuring fresh FCM token...');
    
    final currentUser = AppData().currentUser;
    if (currentUser != null) {
      // Delete any existing token to force refresh
      await FirebaseMessaging.instance.deleteToken();
      await Future.delayed(const Duration(seconds: 2));
      
      // Get fresh token
      final newToken = await FirebaseMessaging.instance.getToken();
      if (newToken != null) {
        await AppData().saveFcmToken(newToken);
        developer.log('✅ Fresh FCM token obtained and saved');
      }
    }
  } catch (e) {
    developer.log('❌ Error ensuring fresh FCM token: $e');
  }
}

Future<void> _showBackgroundLocalNotification(
  FlutterLocalNotificationsPlugin plugin,
  String title,
  String body,
  Map<String, dynamic> data,
) async {
  try {
    // FIXED: Simplified background notification structure
    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription: 'Notifications for new chat messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        '', // Will be filled with body
        htmlFormatBigText: true,
      ),
      // FIXED: Simplified actions for background
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
  // Generate unique ID based on chat ID or use timestamp
  final chatId = data['chatId']?.toString() ?? '';
  if (chatId.isNotEmpty) {
    return chatId.hashCode.abs();
  }
  return DateTime.now().millisecondsSinceEpoch.remainder(100000);
}

Future<void> _initializeApp() async {
  try {
    developer.log('🚀 Starting app initialization...');
    
    // Ensure Flutter binding is initialized
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    developer.log('✅ Firebase initialized');
    
    // CRITICAL: Set background handler BEFORE any other FCM operations
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    developer.log('✅ Background message handler set');
    
    // Initialize notification service ONCE
    final notificationService = FirebaseNotificationService();
    await notificationService.initialize();
    developer.log('✅ Notification service initialized');
    
    // Initialize other services
    await AppData().initialize();
   // await _forceFreshFCMToken(); // After successful login
await AppData().initializeFcmAfterLogin(); 
    //await AppData().initializeFcm();
    await DrawerProfileCache.initialize();
    await CacheManager.initialize();
    developer.log('✅ App services initialized');
    
    // Setup notification listeners
    _setupNotificationListeners();
    
    developer.log('🎉 App initialization completed successfully');
  } catch (e) {
    developer.log('❌ App initialization failed: $e');
    rethrow;
  }
}

void _setupNotificationListeners() {
  try {
    developer.log('📱 Setting up notification listeners...');
    
    // Get notification service instance
    final notificationService = FirebaseNotificationService();
    
    // Handle foreground messages - let the service handle it
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('📨 Foreground message: ${message.messageId}');
      notificationService.handleForegroundMessage(message);
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
        _handleCallNotification(data);
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

void _handleCallNotification(Map<String, dynamic> data) {
  developer.log('📞 Handling call notification: $data');
  // Implement call handling logic here
  Get.snackbar(
    'Incoming Call',
    'Call feature coming soon!',
    snackPosition: SnackPosition.TOP,
    backgroundColor: Colors.blue,
    colorText: Colors.white,
  );
}

void main() async {
  await _initializeApp();
  runApp(const ProviderScope(child: InnovatorHomePage()));
}

class InnovatorHomePage extends ConsumerStatefulWidget {
  const InnovatorHomePage({super.key});

  @override
  ConsumerState<InnovatorHomePage> createState() => _InnovatorHomePageState();
}

class _InnovatorHomePageState extends ConsumerState<InnovatorHomePage> {
  Timer? _notificationTimer;
  late NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _initializeNotifications() async {
    try {
      _notificationService = NotificationService();
      await _notificationService.initialize();
      developer.log('✅ Notification service initialized in main app');
    } catch (e) {
      developer.log('❌ Error initializing notifications in main app: $e');
    }
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
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
      onInit: () {
        // Initialize chat controller globally
        Get.put<FireChatController>(FireChatController(), permanent: true);
                Get.put<CartStateManager>(CartStateManager(), permanent: true); // Add this line

        developer.log('✅ Chat controller initialized globally');
      },
      getPages: [
        // Chat Home Page
        GetPage(
          name: '/home',
          page: () => const OptimizedChatHomePage(),
          binding: BindingsBuilder(() {
            Get.lazyPut<FireChatController>(() => FireChatController());
            Get.lazyPut<CartStateManager>(() => CartStateManager()); // Add this

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
        
        // Add to Chat Page - NEW
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