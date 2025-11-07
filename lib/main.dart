import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/services/Notification_Like.dart';
import 'package:innovator/firebase_options.dart';
import 'package:innovator/Innovator/screens/Shop/CardIconWidget/cart_state_manager.dart';
import 'package:innovator/Innovator/screens/Shop/Shop_Page.dart';
import 'package:innovator/Innovator/screens/Splash_Screen/splash_screen.dart';
import 'package:innovator/Innovator/screens/chatApp/SearchchatUser.dart';
import 'package:innovator/Innovator/screens/chatApp/chat_homepage.dart';
import 'package:innovator/Innovator/screens/chatApp/chatlistpage.dart';
import 'package:innovator/Innovator/screens/chatApp/chatscreen.dart';
import 'package:innovator/Innovator/screens/chatApp/controller/chat_controller.dart';
import 'package:innovator/Innovator/services/Daily_Notifcation.dart';

// ============================================================================
// GLOBAL VARIABLES
// ============================================================================
late Size mq;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// CRITICAL: Initialize this immediately (not late)
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Global notification service
NotificationService? globalNotificationService;
bool _isFirebaseInitialized = false;

// ============================================================================
// BACKGROUND MESSAGE HANDLER
// ============================================================================
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    developer.log('🔔 Background: ${message.messageId}');
  } catch (e) {
    developer.log('❌ Background handler error: $e');
  }
}

// ============================================================================
// FAST CRITICAL INIT - Only Firebase (< 100ms)
// ============================================================================
Future<void> _initializeCritical() async {
  try {
    // Initialize Firebase - super fast
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isFirebaseInitialized = true;
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      developer.log('✅ Firebase ready (fast)');
    }
  } catch (e) {
    developer.log('❌ Firebase init failed: $e');
  }
}

// ============================================================================
// DEFERRED INIT - Everything else runs AFTER UI shows
// ============================================================================
Future<void> _initializeDeferred() async {
  try {
    developer.log('🔧 Starting deferred init...');
    
    // Small delay to let UI render first
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Step 1: Initialize notification service
    developer.log('🔔 Initializing notifications...');
    globalNotificationService = NotificationService();
    await globalNotificationService!.initialize();
    developer.log('✅ Notifications ready');
    
    // Step 2: Setup FCM listeners IMMEDIATELY
    _setupFCMListeners();
    
    // Step 3: Initialize other services in parallel (non-blocking)
    Future.wait([
      _initializeAppData(),
      _initializeDailyNotifications(),
    ], eagerError: false);
    
    developer.log('✅ Deferred init complete');
  } catch (e) {
    developer.log('❌ Deferred init error: $e');
  }
}

Future<void> _initializeAppData() async {
  try {
    await AppData().initialize();
    developer.log('✅ AppData ready');
  } catch (e) {
    developer.log('⚠️ AppData failed: $e');
    try {
      await AppData().initializeOffline();
      developer.log('✅ AppData offline mode');
    } catch (_) {}
  }
}

Future<void> _initializeDailyNotifications() async {
  try {
    await DailyNotificationService.initialize();
    developer.log('✅ Daily notifications ready');
  } catch (e) {
    developer.log('⚠️ Daily notifications failed: $e');
  }
}

// ============================================================================
// SETUP FCM LISTENERS
// ============================================================================
void _setupFCMListeners() {
  if (globalNotificationService == null) {
    developer.log('❌ Cannot setup listeners - service not ready!');
    return;
  }

  // FOREGROUND MESSAGE HANDLER
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    developer.log('📨 ═══════════════════════════════════════');
    developer.log('📨 FOREGROUND MESSAGE!');
    developer.log('📨 Title: ${message.notification?.title}');
    developer.log('📨 Body: ${message.notification?.body}');
    developer.log('📨 Data: ${message.data}');
    developer.log('📨 ═══════════════════════════════════════');
    
    // Show notification
    globalNotificationService?.handleForegroundMessage(message);
    
    // Show in-app banner (non-blocking)
    _showInAppBanner(message);
  }, onError: (error) {
    developer.log('❌ Foreground listener error: $error');
  });

  // App opened from notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    developer.log('📱 App opened from notification');
    _handleNotificationTap(message.data);
  });

  // Initial message
  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      developer.log('🚀 Launched from notification');
      Future.delayed(const Duration(seconds: 1), () {
        _handleNotificationTap(message.data);
      });
    }
  });
  
  developer.log('✅ FCM listeners active');
}

// ============================================================================
// NOTIFICATION HANDLERS
// ============================================================================
void _showInAppBanner(RemoteMessage message) {
  try {
    final title = message.notification?.title ?? 
                  message.data['senderName'] ?? 
                  'New Message';
    final body = message.notification?.body ?? 
                 message.data['message'] ?? 
                 'New notification';

    // Check if GetX is ready before showing snackbar
    Future.delayed(const Duration(milliseconds: 200), () {
      if (Get.context != null) {
        Get.snackbar(
          title,
          body,
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color.fromRGBO(244, 135, 6, 0.95),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          mainButton: TextButton(
            onPressed: () {
              Get.back();
              _handleNotificationTap(message.data);
            },
            child: const Text(
              'View',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
        HapticFeedback.lightImpact();
      }
    });
  } catch (e) {
    developer.log('❌ Banner error: $e');
  }
}

void _handleNotificationTap(Map<String, dynamic> data) {
  try {
    final type = data['type']?.toString().toLowerCase() ?? '';
    
    Future.delayed(const Duration(milliseconds: 100), () {
      switch (type) {
        case 'chat':
        case 'message':
          final senderId = data['senderId']?.toString() ?? '';
          final senderName = data['senderName']?.toString() ?? 'Unknown';
          final chatId = data['chatId']?.toString() ?? '';

          if (senderId.isNotEmpty) {
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
          }
          break;
          
        default:
          Get.toNamed('/home');
      }
    });
  } catch (e) {
    developer.log('❌ Navigation error: $e');
  }
}

// ============================================================================
// MAIN ENTRY POINT - FAST START
// ============================================================================
void main() async {
  runZonedGuarded(() async {
    try {
      developer.log('🚀 App starting...');
      
      WidgetsFlutterBinding.ensureInitialized();
      
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      );
      
      // FAST: Only initialize Firebase (< 100ms)
      await _initializeCritical();
      
      // START UI IMMEDIATELY
      developer.log('🎨 Starting UI (fast)...');
      runApp(const ProviderScope(child: InnovatorHomePage()));
      
      // Initialize everything else in background (non-blocking)
      _initializeDeferred();
      
      developer.log('✅ App started (UI visible)');
    } catch (e, stackTrace) {
      developer.log('❌ Error: $e\n$stackTrace');
      runApp(const ProviderScope(child: InnovatorHomePage()));
    }
  }, (error, stackTrace) {
    developer.log('❌ Uncaught: $error\n$stackTrace');
  });
}

// ============================================================================
// MAIN APP WIDGET
// ============================================================================
class InnovatorHomePage extends ConsumerStatefulWidget {
  const InnovatorHomePage({super.key});

  @override
  ConsumerState<InnovatorHomePage> createState() => _InnovatorHomePageState();
}

class _InnovatorHomePageState extends ConsumerState<InnovatorHomePage> {
  @override
  void initState() {
    super.initState();
    developer.log('🏠 HomePage init');
    
    // Setup FCM token after UI loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupFCMToken();
    });
  }

  Future<void> _setupFCMToken() async {
    try {
      // Wait a bit for notification service to be ready
      await Future.delayed(const Duration(milliseconds: 500));
      
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        developer.log('📱 FCM Token: ${token.substring(0, 20)}...');
        await AppData().saveFcmToken(token);
      }
      
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        developer.log('🔄 Token refreshed');
        AppData().saveFcmToken(newToken);
      });
    } catch (e) {
      developer.log('❌ FCM token error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;

    return GetMaterialApp(
      navigatorKey: navigatorKey,
      title: 'Innovator',
      theme: _buildAppTheme(),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      onInit: () {
        developer.log('🎮 GetX init');
        try {
          Get.lazyPut<FireChatController>(() => FireChatController(), fenix: true);
          Get.lazyPut<CartStateManager>(() => CartStateManager(), fenix: true);
          developer.log('✅ Controllers registered');
        } catch (e) {
          developer.log('❌ Controller error: $e');
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

  ThemeData _buildAppTheme() {
    return ThemeData(
      fontFamily: 'InterThin',
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