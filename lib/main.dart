// For generating unique call IDs
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/firebase_options.dart';
import 'package:innovator/screens/Feed/Services/Feed_Cache_service.dart';
import 'package:innovator/screens/Shop/CardIconWidget/cart_state_manager.dart';
import 'package:innovator/screens/Shop/Shop_Page.dart';
import 'package:innovator/screens/Splash_Screen/splash_screen.dart';
import 'package:innovator/screens/chatApp/SearchchatUser.dart';
import 'package:innovator/screens/chatApp/chat_homepage.dart';
import 'package:innovator/screens/chatApp/chatlistpage.dart';
import 'package:innovator/screens/chatApp/chatscreen.dart';
import 'package:innovator/screens/chatApp/controller/chat_controller.dart';
import 'package:innovator/services/Daily_Notifcation.dart';
import 'package:innovator/services/Firebase_Messaging.dart';
import 'package:innovator/utils/Drawer/drawer_cache_manager.dart';
import 'dart:developer' as developer;
import 'package:innovator/screens/Eliza_ChatBot/global.dart';

// Global variables and constants
late Size mq;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
bool _isAppOnline = false;

// CRITICAL: Global notification plugin for background use
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;


// ENHANCED: Lightweight background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    developer.log('📞 Background message: ${message.messageId}');
    
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
          await _showBackgroundNotification(message);

    // final messageType = message.data['type']?.toString() ?? '';
    
    // if (messageType == 'call') {
    //   await _handleBackgroundCallMessage(message);
    // } else {
    //   // Handle other message types
    // }
  } catch (e) {
    developer.log('❌ Background handler error: $e');
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

 

    final androidPlugin =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin != null) {
      // Create channels ONLY ONCE
      // await androidPlugin.createNotificationChannel(
      //   const AndroidNotificationChannel(
      //     'incoming_calls',
      //     'Incoming Calls',
      //     description: 'Notifications for incoming calls',
      //     importance: Importance.max,
      //     enableVibration: true,
      //     enableLights: true,
      //     playSound: true,
      //     showBadge: true,
      //   ),
      // );

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


// OPTIMIZED: App initialization with better error handling
Future<void> _initializeApp() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // try {
    //   AdaptiveVideoSystem.initialize();
    // } catch (e) {}

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
    
    await _initializeAppDataWithFallback(hasInternet);
    //await _initializeCallServices();

    // Initialize notification service only if online
    if (hasInternet) {
      try {
        // FIXED: Register the service with GetX BEFORE using it
        final notificationService = FirebaseNotificationService();
        Get.put(notificationService, permanent: true); // Add this line

        await notificationService.initialize();
        //await AppData().initializeFcmAfterLogin();
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

    // try {
    //   Get.put(FollowStatusManager(), permanent: true);
    // } catch (e) {}

    developer.log('App initialization completed');
  } catch (e) {
    developer.log('App initialization failed: $e');
  }
}

// Setup notification listeners with better error handling
void _setupNotificationListeners() {
  try {
    final notificationService = FirebaseNotificationService();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final messageType = message.data['type']?.toString() ?? '';

      if (messageType == 'call') {
        //_handleForegroundCallMessage(message);
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
      // case 'call':
      //   _handleCallNotificationTapFromMessage(data);
      //   break;
      default:
        Get.offAllNamed('/home');
        break;
    }
  } catch (e) {
    developer.log('Notification tap from message error: $e');
  }
}


// OPTIMIZED: Main function
void main() async {
  Gemini.init(apiKey: apiKey);
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Firebase first
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize local notifications
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await _initializeBackgroundNotifications();
    
    // Initialize CallKit listener
    //await initCallKit();
    
    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
     
    // Rest of your initialization
    await _initializeApp();
    
  } catch (e) {
    developer.log('Critical initialization error: $e');
  }

  runApp(
      // DevicePreview(
      //   enabled: !kReleaseMode,
      //   child: ProviderScope(child: InnovatorHomePage())),
       DevicePreview(
    enabled: !kReleaseMode,
    builder: (context) => ProviderScope(child: InnovatorHomePage()), 
  ),
  );
}

// OPTIMIZED: Main app class with better memory management
class InnovatorHomePage extends ConsumerStatefulWidget {
  const InnovatorHomePage({super.key});

  @override
  ConsumerState<InnovatorHomePage> createState() => _InnovatorHomePageState();
}

class _InnovatorHomePageState extends ConsumerState<InnovatorHomePage> {

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;

    return GetMaterialApp(
      navigatorKey: navigatorKey,
      title: 'Innovator',
      theme: _buildAppTheme(),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      // builder: (context, child) {
      //   return Stack(children: [child!, const CallFloatingWidget()]);
      // },
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

        // // OPTIMIZED: Delayed notification test only if online
        // if (_isAppOnline) {
        //   Future.delayed(const Duration(seconds: 5), () {
        //     _performAppReadyNotificationTest();
        //   });
        // }
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

        // GetPage(
        //   name: '/add-to-chat',
        //   page: () => const AddToChatScreen(),
        //   binding: BindingsBuilder(() {
        //     Get.lazyPut<FireChatController>(() => FireChatController());
        //   }),
        // ),

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

  
  _buildAppTheme() {
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
