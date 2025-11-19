import 'dart:async';
import 'dart:convert';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/KMS/screens/auth/login_screen.dart';
import 'package:innovator/KMS/screens/auth/signup_screen.dart';
import 'package:innovator/Innovator/services/in_app_notifcation.dart';
import 'package:innovator/Innovator/services/notifcation_polling_services.dart';
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
import 'package:innovator/Innovator/services/Firebase_Messaging.dart';
 
late Size mq;
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  GlobalKey<NavigatorState> get navigatorKey => Get.key;

// ✅ CRITICAL: Track Firebase initialization state
bool _isFirebaseInitialized = false;
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try { 
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    await _showBackgroundNotification(message);
  } catch (e) {

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

  }
}


Future<void> _initializeCriticalOnly() async {
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
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          try {
            final data = jsonDecode(details.payload!);
            _navigateToChatFromNotification(data);
          } catch (e) {
          }
        }
      },
    );
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'chat_messages',
          'Chat Messages',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );
    }
  } catch (e) {
  }
}
Future<void> _initializeNonCriticalServices() async {
  try {
    
    await Future.wait([
      _initializeFirebase(),
      _initializeAppData(),
      _initializeDailyNotifications(),
    ], eagerError: false);
  } catch (e) {
  }
}

Future<void> _initializeFirebase() async {
  try {
    if (_isFirebaseInitialized) {
      return;
    }

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isFirebaseInitialized = true;
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    } else {
      _isFirebaseInitialized = true;
    }
  } catch (e) {
    _isFirebaseInitialized = false;
  }
}

Future<void> _initializeAppData() async {
  try {
    await AppData().initialize();
  } catch (e) {
    try {
      await AppData().initializeOffline();
    } catch (offlineError) {
    }
  }
}

Future<void> _initializeDailyNotifications() async {
  try {
    await DailyNotificationService.initialize();
  } catch (e) {
  }
} 
Future<void> _initializeDeferredServices() async {
  try {
    developer.log('⏰ Starting deferred services...');
    
    // ✅ FIX: Wait longer for UI to be fully ready
    await Future.delayed(const Duration(seconds: 1));
    
    // ✅ Verify navigator is ready
    if (navigatorKey.currentContext == null) {
      developer.log('⚠️ Navigator not ready, waiting...');
      await Future.delayed(const Duration(seconds: 1));
    }
    
    // ✅ Make sure Firebase is initialized before these services
    if (!_isFirebaseInitialized) {
      developer.log('⚠️ Firebase not ready, initializing now...');
      await _initializeFirebase();
    }
    
    await Future.wait([
      _initializeNotificationServices(),
      _setupNotificationListeners(),
    ], eagerError: false); 
  } catch (e) { 
  }
}

Future<void> _initializeNotificationServices() async {
  try { 
    if (!_isFirebaseInitialized || Firebase.apps.isEmpty) { 
      return;
    } 
    final notificationService = FirebaseNotificationService();
    Get.put(notificationService, permanent: true);
    await notificationService.initialize(); 
  } catch (e) { 
  }
}

Future<void> _setupNotificationListeners() async {
  try { 
    if (!_isFirebaseInitialized || Firebase.apps.isEmpty) { 
      return;
    }

    if (!Get.isRegistered<FirebaseNotificationService>()) { 
      return;
    } 
    final notificationService = Get.find<FirebaseNotificationService>(); 
    FirebaseMessaging.onMessage.listen((RemoteMessage message) { 
      notificationService.handleForegroundMessage(message);
      _showImmediateFeedback(message);
    }); 
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) { 
      _handleNotificationTapFromMessage(message);
    }); 
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) { 
      Future.delayed(const Duration(seconds: 2), () {
        _handleNotificationTapFromMessage(initialMessage);
      });
    } 
  } catch (e) { 
  }
} 

void _showImmediateFeedback(RemoteMessage message) {
  try {
    final title = message.notification?.title ?? 
                  message.data['senderName'] ?? 
                  'New Message';
    final body = message.notification?.body ?? 
                 message.data['message'] ?? 
                 'New message';

    Get.snackbar(
      title,
      body,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color.fromRGBO(244, 135, 6, 0.95),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
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
    HapticFeedback.lightImpact();
  } catch (e) {
  }
}

void _handleNotificationTapFromMessage(RemoteMessage message) {
  try {
    final data = message.data;
    final type = data['type']?.toString() ?? '';

    switch (type) {
      case 'chat':
      case 'message':
        _navigateToChatFromNotification(data);
        break;
      default:
        Get.offAllNamed('/home');
        break;
    }
  } catch (e) {
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
  }
}


void main() async { 
  runZonedGuarded(() async {
    try { 
      WidgetsFlutterBinding.ensureInitialized(); 
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      );
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        _isFirebaseInitialized = true;
 
      }
      
      // Set background message handler (must be after Firebase init)
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Initialize critical UI components
      await _initializeCriticalOnly();
      
      // Start the app
      developer.log('🎨 Starting UI...');
      runApp(DevicePreview(builder: (context) => ProviderScope(child: InnovatorHomePage())));
      
      // Initialize non-critical services in background
      developer.log('🔧 Starting background initialization...');
      _initializeNonCriticalServices();
      
      developer.log('✅ App started successfully');
    } catch (e, stackTrace) {
      developer.log('❌ Critical error in main: $e\n$stackTrace');
      // Still try to run the app
      runApp(const ProviderScope(child: InnovatorHomePage()));
    }
  }, (error, stackTrace) {
  });
} 

class InnovatorHomePage extends ConsumerStatefulWidget {
  const InnovatorHomePage({super.key});

  @override
  ConsumerState<InnovatorHomePage> createState() => _InnovatorHomePageState();
}

class _InnovatorHomePageState extends ConsumerState<InnovatorHomePage> with WidgetsBindingObserver{

  final NotificationPollingService _pollingService = NotificationPollingService();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    developer.log('🏠 InnovatorHomePage initialized');
    
    // Initialize deferred services after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
  
      _initializeDeferredServices();
      
      // ✅ FIX: Wait longer before starting polling to ensure overlay is ready
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && InAppNotificationService().isReady) {
          _pollingService.startPolling();
          developer.log('✅ Notification polling started from main');
        } else {
          // Retry after another delay if not ready
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              // Force start even if not "ready" - the service will handle it
              _pollingService.startPolling();
              developer.log('✅ Notification polling started (forced retry)');
            }
          });
        }
      });
    });
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingService.stopPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        developer.log('📱 App resumed - restarting notification polling');
        _pollingService.startPolling();
        _pollingService.forceCheck(); // Immediate check
        break;
      case AppLifecycleState.paused:
        developer.log('⏸️ App paused - pausing notification polling');
        _pollingService.stopPolling();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;

    return GetMaterialApp(
      // ✅ FIX: Use the global navigator key for InAppNotificationService
      navigatorKey: navigatorKey,
      title: 'Innovator',
      theme: _buildAppTheme(),
      debugShowCheckedModeBanner: false,

      //USE  SPLASHSCREEN FOR RUNNING TH
      // home: const SplashScreen(),
   home: LoginScreen(),
      onInit: () {
        try {
          Get.lazyPut<FireChatController>(
            () => FireChatController(), 
            fenix: true
          );
          Get.lazyPut<CartStateManager>(
            () => CartStateManager(), 
            fenix: true
          );
        } catch (e) {
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