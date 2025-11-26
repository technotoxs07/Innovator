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
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:innovator/Innovator/App_data/App_data.dart';
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
import 'dart:developer' as developer;

// ============================================================================
// GLOBAL VARIABLES
// ============================================================================
late Size mq;
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  GlobalKey<NavigatorState> get navigatorKey => Get.key;

// ✅ CRITICAL: Track Firebase initialization state
bool _isFirebaseInitialized = false;

// ============================================================================
// BACKGROUND MESSAGE HANDLER
// ============================================================================
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // ✅ FIX: Check if Firebase is already initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    await _showBackgroundNotification(message);
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

// ============================================================================
// INITIALIZATION FUNCTIONS
// ============================================================================

// ✅ STEP 1: Initialize ONLY what's needed for first screen
Future<void> _initializeCriticalOnly() async {
  try {
    developer.log('🚀 Starting critical initialization...');
    
    // Initialize local notifications
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
            developer.log('Notification tap error: $e');
          }
        }
      },
    );

    // Create notification channel
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
    
    developer.log('✅ Critical initialization complete');
  } catch (e) {
    developer.log('❌ Critical init failed: $e');
  }
}

// ✅ STEP 2: Initialize non-critical services in parallel
Future<void> _initializeNonCriticalServices() async {
  try {
    developer.log('🔧 Starting non-critical services...');
    
    await Future.wait([
      _initializeFirebase(),
      _initializeAppData(),
      _initializeDailyNotifications(),
    ], eagerError: false);
    
    developer.log('✅ Non-critical services complete');
  } catch (e) {
    developer.log('❌ Non-critical services error: $e');
  }
}

Future<void> _initializeFirebase() async {
  try {
    // ✅ FIX: Only initialize if not already initialized
    if (_isFirebaseInitialized) {
      developer.log('ℹ️ Firebase already initialized, skipping...');
      return;
    }

    if (Firebase.apps.isEmpty) {
      developer.log('🔥 Initializing Firebase...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isFirebaseInitialized = true;
      
      // Set background message handler AFTER initialization
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      developer.log('✅ Firebase initialized successfully');
    } else {
      developer.log('ℹ️ Firebase already initialized (apps exist)');
      _isFirebaseInitialized = true;
    }
  } catch (e) {
    developer.log('❌ Firebase init failed: $e');
    _isFirebaseInitialized = false;
  }
}

Future<void> _initializeAppData() async {
  try {
    developer.log('📦 Initializing AppData...');
    await AppData().initialize();
    developer.log('✅ AppData initialized');
  } catch (e) {
    developer.log('⚠️ AppData init failed, trying offline: $e');
    try {
      await AppData().initializeOffline();
      developer.log('✅ AppData initialized (offline mode)');
    } catch (offlineError) {
      developer.log('❌ Offline init failed: $offlineError');
    }
  }
}

Future<void> _initializeDailyNotifications() async {
  try {
    developer.log('📅 Initializing daily notifications...');
    await DailyNotificationService.initialize();
    developer.log('✅ Daily notifications initialized');
  } catch (e) {
    developer.log('⚠️ Daily notification failed (non-critical): $e');
  }
}

// ✅ STEP 3: Initialize deferred services after UI is shown
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
    
    developer.log('✅ Deferred services complete');
  } catch (e) {
    developer.log('❌ Deferred services error: $e');
  }
}

Future<void> _initializeNotificationServices() async { 
  try {
    // ✅ Check Firebase is ready
    if (!_isFirebaseInitialized || Firebase.apps.isEmpty) {
      developer.log('⚠️ Cannot initialize notification service - Firebase not ready');
      return;
    }

    developer.log('🔔 Initializing notification service...');
    final notificationService = FirebaseNotificationService();
    Get.put(notificationService, permanent: true);
    await notificationService.initialize();
    developer.log('✅ Notification service initialized');
  } catch (e) {
    developer.log('❌ Notification service failed: $e');
  }
}

Future<void> _setupNotificationListeners() async {
  try {
    // ✅ Check dependencies
    if (!_isFirebaseInitialized || Firebase.apps.isEmpty) {
      developer.log('⚠️ Cannot setup listeners - Firebase not ready');
      return;
    }

    if (!Get.isRegistered<FirebaseNotificationService>()) {
      developer.log('⚠️ Cannot setup listeners - Service not registered');
      return;
    }

    developer.log('👂 Setting up notification listeners...');
    final notificationService = Get.find<FirebaseNotificationService>();

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('📨 Foreground message received');
      notificationService.handleForegroundMessage(message);
      _showImmediateFeedback(message);
    });

    // App opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log('📱 App opened from notification');
      _handleNotificationTapFromMessage(message);
    });

    // Initial message (app launched from terminated state)
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      developer.log('🚀 App launched from notification');
      Future.delayed(const Duration(seconds: 2), () {
        _handleNotificationTapFromMessage(initialMessage);
      });
    }
    
    developer.log('✅ Notification listeners setup complete');
  } catch (e) {
    developer.log('❌ Listener setup failed: $e');
  }
}

// ============================================================================
// NOTIFICATION HANDLERS
// ============================================================================

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
    developer.log('❌ Immediate feedback error: $e');
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
    developer.log('❌ Notification tap error: $e');
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
    developer.log('❌ Chat navigation error: $e');
  }
}

// ============================================================================
// MAIN ENTRY POINT
// ============================================================================

void main() async {
  // Wrap in error handling zone
  runZonedGuarded(() async {
    try {
      developer.log('🚀 App starting...');
      
      // Ensure Flutter is initialized
      WidgetsFlutterBinding.ensureInitialized();
      
      // Set system UI
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      );
      
      // ✅ CRITICAL: Initialize Firebase FIRST before anything else
      developer.log('🔥 Pre-initializing Firebase in main()...');
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        _isFirebaseInitialized = true;
        developer.log('✅ Firebase pre-initialized');
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
      runApp(DevicePreview(builder:(context) =>  ProviderScope(child: InnovatorHomePage())));
    }
  }, (error, stackTrace) {
    developer.log('❌ Uncaught error: $error\n$stackTrace');
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

class _InnovatorHomePageState extends ConsumerState<InnovatorHomePage> with WidgetsBindingObserver{

  final NotificationPollingService _pollingService = NotificationPollingService();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    developer.log('🏠 InnovatorHomePage initialized');
    
    // Initialize deferred services after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      developer.log('🎬 First frame rendered, starting deferred services...');
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
      home: const SplashScreen(),
      onInit: () {
        developer.log('🎮 GetX onInit called');
        // Lazy initialization of controllers
        try {
          Get.lazyPut<FireChatController>(
            () => FireChatController(), 
            fenix: true
          );
          Get.lazyPut<CartStateManager>(
            () => CartStateManager(), 
            fenix: true
          );
          developer.log('✅ Controllers registered');
        } catch (e) {
          developer.log('❌ Controller initialization error: $e');
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