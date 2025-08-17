import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
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
import 'package:innovator/services/Firebase_Messaging.dart';
import 'package:innovator/services/Notification_services.dart';
import 'package:innovator/services/fcm_handler.dart';
import 'package:innovator/utils/Drawer/drawer_cache_manager.dart';
import 'dart:developer' as developer;

// Global variables and constants
late Size mq;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
bool _isAppOnline = false;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    developer.log('🔥 === BACKGROUND MESSAGE HANDLER START ===');
    developer.log('🔥 Message ID: ${message.messageId}');
    developer.log('🔥 From: ${message.from}');
    developer.log('🔥 Data: ${message.data}');
    developer.log('🔥 Notification: ${message.notification?.toMap()}');
    
    // Initialize Firebase if not already done
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      developer.log('🔥 Firebase initialized in background handler');
    }
    
    // Handle the notification display
    await _handleBackgroundNotification(message);
    
    developer.log('✅ Background notification processed: ${message.messageId}');
    developer.log('🔥 === BACKGROUND MESSAGE HANDLER END ===');
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
          importance: Importance.max,
          enableVibration: true,
          enableLights: true,
          ledColor: Color.fromRGBO(244, 135, 6, 1),
          showBadge: true,
          playSound: true,
        ),
      );
      
      // Additional fallback channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'fallback_channel',
          'Fallback Notifications',
          description: 'Fallback notifications',
          importance: Importance.high,
          enableVibration: true,
          showBadge: true,
          playSound: true,
        ),
      );
    }
    
    developer.log('✅ Background notifications initialized');
  } catch (e) {
    developer.log('❌ Error initializing background notifications: $e');
  }
}

Future<void> _showBackgroundLocalNotification(
  FlutterLocalNotificationsPlugin plugin,
  String title,
  String body,
  Map<String, dynamic> data,
) async {
  try {
    // Enhanced background notification structure
    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription: 'Notifications for new chat messages',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        '',
        htmlFormatBigText: true,
      ),
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
      enableVibration: true,
      playSound: true,
      enableLights: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default.wav',
      interruptionLevel: InterruptionLevel.active,
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
  final chatId = data['chatId']?.toString() ?? '';
  if (chatId.isNotEmpty) {
    return chatId.hashCode.abs();
  }
  return DateTime.now().millisecondsSinceEpoch.remainder(100000);
}

// Enhanced connectivity check function
Future<bool> _checkInternetConnectivity() async {
  try {
    // First check connectivity status
    final connectivityResults = await Connectivity().checkConnectivity();
    
    // Check if any connection type is available
    if (connectivityResults.every((result) => result == ConnectivityResult.none)) {
      developer.log('📶 No connectivity reported by system');
      return false;
    }
    
    // Double-check with a simple network call
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      
      bool hasInternet = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      developer.log('📶 Internet lookup result: $hasInternet');
      return hasInternet;
    } catch (e) {
      developer.log('📶 Internet lookup failed: $e');
      return false;
    }
  } catch (e) {
    developer.log('❌ Connectivity check failed: $e');
    return false;
  }
}

// Enhanced Firebase initialization with offline support
Future<void> _initializeFirebaseWithFallback(bool hasInternet) async {
  try {
    // Always try to initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    if (hasInternet) {
      developer.log('✅ Firebase initialized with internet connectivity');
      // Set background handler only if online
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      developer.log('✅ Background message handler set');
    } else {
      developer.log('✅ Firebase initialized in offline mode');
    }
  } catch (e) {
    developer.log('❌ Firebase initialization failed: $e');
    // Don't rethrow - allow app to continue
  }
}

// Enhanced AppData initialization with fallback
Future<void> _initializeAppDataWithFallback(bool hasInternet) async {
  try {
    if (hasInternet) {
      await AppData().initialize();
      developer.log('✅ AppData initialized with internet');
    } else {
      // Try offline initialization
      try {
        // You'll need to add this method to your AppData class
        await AppData().initializeOffline();
        developer.log('✅ AppData initialized in offline mode');
      } catch (offlineError) {
        developer.log('⚠️ AppData offline initialization failed, using minimal setup');
        // Minimal initialization fallback
        await _initializeMinimalAppData();
      }
    }
  } catch (e) {
    developer.log('❌ AppData initialization failed: $e');
    // Try minimal initialization as last resort
    await _initializeMinimalAppData();
  }
}

// Minimal AppData initialization for offline mode
Future<void> _initializeMinimalAppData() async {
  try {
    // Initialize only essential offline components
    developer.log('⚠️ Using minimal AppData initialization');
  } catch (e) {
    developer.log('❌ Even minimal AppData initialization failed: $e');
  }
}

// Enhanced app initialization with comprehensive offline support
Future<void> _initializeApp() async {
  try {
    developer.log('🚀 === APP INITIALIZATION START ===');
    
    // Ensure Flutter binding is initialized
    WidgetsFlutterBinding.ensureInitialized();
    
    try {
      AdaptiveVideoSystem.initialize();
      developer.log('✅ AdaptiveVideoSystem initialized');
    } catch (e) {
      developer.log('⚠️ AdaptiveVideoSystem initialization failed: $e');
    }

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    
    // Check internet connectivity first
    bool hasInternet = await _checkInternetConnectivity();
    _isAppOnline = hasInternet;
    developer.log('📶 Internet connectivity: $hasInternet');
    
    // Initialize Firebase with offline handling
    await _initializeFirebaseWithFallback(hasInternet);
    
    // Initialize AppData with offline support
    await _initializeAppDataWithFallback(hasInternet);
    
    // Initialize notification service only if online
    if (hasInternet) {
      try {
        developer.log('📱 === NOTIFICATION SERVICE INITIALIZATION ===');
        final notificationService = FirebaseNotificationService();
        await notificationService.initialize();
        developer.log('✅ Notification service initialized');
        
        // Initialize other online services
        await AppData().initializeFcmAfterLogin();
        _setupNotificationListeners();
        await _testFCMToken();
      } catch (e) {
        developer.log('⚠️ Online services initialization failed: $e');
      }
    } else {
      developer.log('⚠️ Skipping online services due to no internet connectivity');
    }
    
    // Initialize offline-capable services
    try {
      await DrawerProfileCache.initialize();
      developer.log('✅ DrawerProfileCache initialized');
    } catch (e) {
      developer.log('⚠️ DrawerProfileCache initialization failed: $e');
    }
    
    try {
      await CacheManager.initialize();
      developer.log('✅ CacheManager initialized');
    } catch (e) {
      developer.log('⚠️ CacheManager initialization failed: $e');
    }
    
    // Initialize follow status manager
    try {
      Get.put(FollowStatusManager(), permanent: true);
      developer.log('✅ FollowStatusManager initialized');
    } catch (e) {
      developer.log('⚠️ FollowStatusManager initialization failed: $e');
    }

    developer.log('🎉 === APP INITIALIZATION COMPLETED SUCCESSFULLY ===');
  } catch (e) {
    developer.log('❌ App initialization failed: $e');
    developer.log('❌ Stack trace: ${StackTrace.current}');
    
    // Don't rethrow - allow app to continue with limited functionality
    developer.log('⚠️ Continuing with limited functionality...');
  }
}

Future<void> _testNotificationSystem() async {
  try {
    developer.log('🧪 === TESTING NOTIFICATION SYSTEM ===');
    
    final notificationService = FirebaseNotificationService();
    
    // Wait a moment for initialization to complete
    await Future.delayed(const Duration(seconds: 1));
    
    // Show test notification
    await notificationService.showTestNotification();
    
    // Debug notification status
    await notificationService.debugNotificationStatus();
    
    developer.log('✅ Notification system test completed');
  } catch (e) {
    developer.log('❌ Notification system test failed: $e');
  }
}

Future<void> _testFCMToken() async {
  try {
    developer.log('🧪 === TESTING FCM TOKEN ===');
    
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      developer.log('✅ FCM Token available: ${token.substring(0, 30)}...');
      
      // Test token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        developer.log('🔄 FCM Token refreshed: ${newToken.substring(0, 30)}...');
      });
    } else {
      developer.log('❌ FCM Token not available');
    }
  } catch (e) {
    developer.log('❌ FCM Token test failed: $e');
  }
}

void _setupNotificationListeners() {
  try {
    developer.log('📱 === SETTING UP NOTIFICATION LISTENERS ===');
    
    // Get notification service instance
    final notificationService = FirebaseNotificationService();
    
    // Handle foreground messages with enhanced logging
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('📨 === FOREGROUND MESSAGE RECEIVED IN MAIN ===');
      developer.log('📨 Message ID: ${message.messageId}');
      developer.log('📨 From: ${message.from}');
      developer.log('📨 Data: ${message.data}');
      developer.log('📨 Notification: ${message.notification?.toMap()}');
      developer.log('📨 Time: ${DateTime.now()}');
      
      // Handle foreground messages
      notificationService.handleForegroundMessage(message);
      
      // Additional immediate feedback
      _showImmediateFeedback(message);
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

// Show immediate visual feedback for foreground messages
void _showImmediateFeedback(RemoteMessage message) {
  try {
    final title = message.notification?.title ?? message.data['senderName'] ?? 'New Message';
    final body = message.notification?.body ?? message.data['message'] ?? 'You have a new message';
    
    // Show GetX snackbar immediately
    Get.snackbar(
      title,
      body,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color.fromRGBO(244, 135, 6, 0.95),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(
        Icons.message_rounded,
        color: Colors.white,
        size: 28,
      ),
      shouldIconPulse: true,
      barBlur: 15,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      mainButton: TextButton(
        onPressed: () {
          Get.back();
          _handleNotificationTap(message);
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
    
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    developer.log('📱 ✅ Immediate feedback shown for foreground message');
  } catch (e) {
    developer.log('📱 ❌ Error showing immediate feedback: $e');
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
  Get.snackbar(
    'Incoming Call',
    'Call feature coming soon!',
    snackPosition: SnackPosition.TOP,
    backgroundColor: Colors.blue,
    colorText: Colors.white,
  );
}

// Enhanced Offline-Aware Splash Screen
class OfflineAwareSplashScreen extends StatefulWidget {
  const OfflineAwareSplashScreen({Key? key}) : super(key: key);

  @override
  State<OfflineAwareSplashScreen> createState() => _OfflineAwareSplashScreenState();
}

class _OfflineAwareSplashScreenState extends State<OfflineAwareSplashScreen> with TickerProviderStateMixin {
  bool _isOnline = true;
  bool _isLoading = true;
  String _loadingText = 'Loading...';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _checkConnectivityAndProceed();
    _listenToConnectivityChanges();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  void _listenToConnectivityChanges() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (mounted) {
        // Check if any connection type is available
        final bool isOnline = results.any((result) => result != ConnectivityResult.none);
        if (_isOnline != isOnline) {
          setState(() {
            _isOnline = isOnline;
            _loadingText = isOnline ? 'Connecting...' : 'Offline Mode';
          });
        }
      }
    });
  }

  Future<void> _checkConnectivityAndProceed() async {
    try {
      setState(() {
        _loadingText = 'Checking connection...';
      });

      // Check connectivity
      final hasInternet = await _checkInternetConnectivity();
      
      if (mounted) {
        setState(() {
          _isOnline = hasInternet;
          _loadingText = hasInternet ? 'Loading services...' : 'Offline Mode';
        });
      }
      
      // Wait minimum splash time
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Small delay before navigation
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Navigate to appropriate screen
        _navigateToHome();
      }
    } catch (e) {
      developer.log('❌ Splash screen error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isOnline = false;
          _loadingText = 'Error occurred';
        });
        
        // Still navigate after error
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _navigateToHome();
        });
      }
    }
  }

  void _navigateToHome() {
    if (mounted) {
      // Use your original splash screen navigation logic
      // Replace with your actual home screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => SplashScreen(), // Use your original SplashScreen here
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo/icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.chat_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              
              // App name
              const Text(
                'Innovator',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 50),
              
              // Loading content
              if (_isLoading) ...[
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _loadingText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ] else if (!_isOnline) ...[
                // Offline indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.wifi_off,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Offline Mode',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Some features may be limited',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
              
              const SizedBox(height: 60),
              
              // Connection status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isOnline ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isOnline ? 'Online' : 'Offline',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Enhanced main function with comprehensive error handling
void main() async {
  try {
    await _initializeApp();
  } catch (e) {
    developer.log('❌ Critical initialization error: $e');
    // Still run the app with basic functionality
  }
  
  runApp(const ProviderScope(child: InnovatorHomePage()));
}

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
    _setupPeriodicNotificationTest();
    _setupConnectivityMonitoring();
  }

  void _initializeAppNotifications() async {
    try {
      _notificationService = NotificationService();
      await _notificationService.initialize();
      developer.log('✅ App-level notification service initialized');
    } catch (e) {
      developer.log('❌ Error initializing app-level notifications: $e');
    }
  }

  // Periodic test to ensure notifications are working
  void _setupPeriodicNotificationTest() {
    if (_isAppOnline) {
      _notificationTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
        developer.log('🔔 Periodic notification system health check');
        _testNotificationHealth();
      });
    }
  }

  // Monitor connectivity changes
  void _setupConnectivityMonitoring() {
    _connectivityTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkAndUpdateConnectivity();
    });
  }

  Future<void> _checkAndUpdateConnectivity() async {
    try {
      final wasOnline = _isAppOnline;
      final isOnline = await _checkInternetConnectivity();
      
      if (wasOnline != isOnline) {
        _isAppOnline = isOnline;
        developer.log('📶 Connectivity changed: $isOnline');
        
        if (isOnline) {
          // Reconnected - reinitialize online services
          _handleReconnection();
        } else {
          // Disconnected - handle offline mode
          _handleDisconnection();
        }
      }
    } catch (e) {
      developer.log('❌ Error checking connectivity: $e');
    }
  }

  Future<void> _handleReconnection() async {
    try {
      developer.log('🔄 Handling reconnection...');
      
      // Reinitialize Firebase services
      final notificationService = FirebaseNotificationService();
      await notificationService.initialize();
      
      // Refresh FCM token
      await AppData().refreshFcmToken();
      
      // Show reconnection snackbar
      Get.snackbar(
        'Back Online',
        'All features are now available',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.wifi, color: Colors.white),
      );
      
      // Restart periodic health checks
      _setupPeriodicNotificationTest();
      
    } catch (e) {
      developer.log('❌ Error handling reconnection: $e');
    }
  }

  void _handleDisconnection() {
    developer.log('📶 Handling disconnection...');
    
    // Cancel periodic tests
    _notificationTimer?.cancel();
    
    // Show offline snackbar
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
      
      // Test if we can still show notifications
      final token = await notificationService.getFCMToken();
      if (token == null) {
        developer.log('⚠️ FCM token lost, reinitializing...');
        await AppData().refreshFcmToken();
      }
    } catch (e) {
      developer.log('❌ Notification health check failed: $e');
    }
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    _connectivityTimer?.cancel();
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
 
      // Use the enhanced offline-aware splash screen
      //home: const OfflineAwareSplashScreen(),
      onInit: () {
        // Initialize chat controller globally with error handling
        try {
          Get.put<FireChatController>(FireChatController(), permanent: true);
          developer.log('✅ Chat controller initialized globally');
        } catch (e) {
          developer.log('❌ Error initializing chat controller: $e');
        }

        try {
          Get.put<CartStateManager>(CartStateManager(), permanent: true);
          developer.log('✅ Cart state manager initialized globally');
        } catch (e) {
          developer.log('❌ Error initializing cart state manager: $e');
        }
        
        // Test notification after app is ready (only if online)
        if (_isAppOnline) {
          Future.delayed(const Duration(seconds: 3), () {
            _performAppReadyNotificationTest();
          });
        }
      },
      getPages: [
        // Chat Home Page
        GetPage(
          name: '/home',
          page: () => const OptimizedChatHomePage(),
          binding: BindingsBuilder(() {
            Get.lazyPut<FireChatController>(() => FireChatController());
            Get.lazyPut<CartStateManager>(() => CartStateManager());
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
        
        // Add to Chat Page
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

        // Shop Page
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

  // Test notifications when app is fully ready
  void _performAppReadyNotificationTest() async {
    try {
      if (!_isAppOnline) return;
      
      developer.log('🧪 === PERFORMING APP-READY NOTIFICATION TEST ===');
      
      final notificationService = FirebaseNotificationService();
      
      // Show a "system ready" notification
      await notificationService.showNotification(
        title: 'Chat System Ready',
        body: 'Your chat notifications are now active and working!',
        data: {'type': 'system_ready'},
      );
      
      // Debug current status
      await notificationService.debugNotificationStatus();
      
      developer.log('✅ App-ready notification test completed');
    } catch (e) {
      developer.log('❌ App-ready notification test failed: $e');
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

// Enhanced Connectivity Status Widget (optional - can be used in your screens)
class ConnectivityStatusWidget extends StatefulWidget {
  final Widget child;
  
  const ConnectivityStatusWidget({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<ConnectivityStatusWidget> createState() => _ConnectivityStatusWidgetState();
}

class _ConnectivityStatusWidgetState extends State<ConnectivityStatusWidget> {
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _listenToConnectivityChanges();
  }

  Future<void> _checkInitialConnectivity() async {
    final isOnline = await _checkInternetConnectivity();
    if (mounted) {
      setState(() {
        _isOnline = isOnline;
      });
    }
  }

  void _listenToConnectivityChanges() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        // Check if any connection type is available
        final isOnline = results.any((result) => result != ConnectivityResult.none);
        
        // Double-check with actual internet access
        if (isOnline) {
          final hasInternet = await _checkInternetConnectivity();
          if (mounted && _isOnline != hasInternet) {
            setState(() {
              _isOnline = hasInternet;
            });
          }
        } else {
          if (mounted && _isOnline) {
            setState(() {
              _isOnline = false;
            });
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_isOnline)
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.red.withOpacity(0.9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.wifi_off,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'No internet connection',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}