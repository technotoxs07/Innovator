import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/Authorization/Forget_PWD.dart';
import 'package:innovator/Authorization/cross_platform.dart';
import 'package:innovator/Authorization/signup.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:innovator/helper/dialogs.dart';
import 'package:innovator/innovator_home.dart';
import 'package:innovator/screens/chatApp/FollowStatusManager.dart';
import 'package:innovator/screens/chatApp/controller/chat_controller.dart';
import 'package:innovator/services/firebase_services.dart';
import 'package:lottie/lottie.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.clearFields = false});
  final bool clearFields;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Color preciseGreen = Color.fromRGBO(244, 135, 6, 1);
  bool _isPasswordVisible = false;

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool isRememberMe = false;
  bool rememberMe = false;

  // Create focus nodes for email and password fields
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  // Create form key to manage AutofillGroup
  final _formKey = GlobalKey<FormState>();

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  // Google Sign-In instance
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  // Firebase Messaging instance
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    if (widget.clearFields) {
      emailController.clear();
      passwordController.clear();
    } else {
      _loadSavedCredentials();
    }
  }

  void _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('email');
      final savedPassword = prefs.getString('password');
      final remember = prefs.getBool('rememberMe') ?? false;

      if (remember && mounted) {
        setState(() {
          rememberMe = true;
          emailController.text = savedEmail ?? '';
          passwordController.text = savedPassword ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading saved credentials: $e');
    }
  }

  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (rememberMe) {
        await prefs.setString('email', emailController.text.trim());
        await prefs.setString('password', passwordController.text.trim());
        await prefs.setBool('rememberMe', true);
      } else {
        await prefs.remove('email');
        await prefs.remove('password');
        await prefs.setBool('rememberMe', false);
      }
    } catch (e) {
      debugPrint('Error saving credentials: $e');
    }
  }

  // Request notification permission for FCM
  Future<void> _requestNotificationPermission() async {
    try {
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(alert: true, badge: true, sound: true);
      developer.log(
        'Notification permission status: ${settings.authorizationStatus}',
      );
    } catch (e) {
      developer.log('Error requesting notification permission: $e');
    }
  }

  @override
  void dispose() {
    // Clean up controllers and focus nodes when the widget is disposed
    emailController.dispose();
    passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loginWithAPI() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Dialogs.showSnackbar(context, 'Please enter both email and password');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get fresh FCM token BEFORE login request
      String? fcmToken;
      try {
        // Force token refresh for new login
        await FirebaseMessaging.instance.deleteToken();
        await Future.delayed(const Duration(milliseconds: 500));

        fcmToken = await FirebaseMessaging.instance.getToken();
        developer.log(
          '✅ Got fresh FCM token for login: ${fcmToken?.substring(0, 30)}...',
        );
      } catch (e) {
        developer.log('⚠️ Could not get FCM token: $e');
        // Continue without token - will retry after login
      }

      final url = Uri.parse('http://182.93.94.210:3067/api/v1/login');
      final body = jsonEncode({
        'email': emailController.text.trim(),
        'password': passwordController.text.trim(),
        'fcmToken': fcmToken ?? '',
        'deviceType': Platform.isAndroid ? 'android' : 'ios',
        'timestamp': DateTime.now().toIso8601String(),
      });

      final headers = {'Content-Type': 'application/json'};
      final response = await http.post(url, headers: headers, body: body);

      developer.log('API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        await _handleSuccessfulLogin(response.body);

        // Ensure FCM token is saved after successful login
        if (fcmToken != null && fcmToken.isNotEmpty) {
          await AppData().saveFcmToken(fcmToken);
        } else {
          // Try again if we didn't get it earlier
          await _refreshFcmTokenAfterLogin();
        }
      } else {
        _handleLoginError(response);
      }
    } catch (e) {
      developer.log('Login error: $e');
      Dialogs.showSnackbar(
        context,
        'Network error. Please check your connection.',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });

      TextInput.finishAutofillContext(shouldSave: false);
    }
  }

  Future<void> _refreshFcmTokenAfterLogin() async {
    try {
      developer.log('🔄 Refreshing FCM token after login...');

      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await AppData().saveFcmToken(fcmToken);
        developer.log('✅ FCM token refreshed and saved');

        // Also update on backend with correct endpoint
        await _updateFcmTokenOnBackend(fcmToken);
      }
    } catch (e) {
      developer.log('❌ Error refreshing FCM token after login: $e');
    }
  }

  Future<void> _updateFcmTokenOnBackend(String fcmToken) async {
    try {
      final userId = AppData().currentUserId;
      if (userId == null) {
        developer.log('No user ID available for FCM update');
        return;
      }

      // Try port 3067 if API token is available

      // Always try port 3067 with auth token
      final authToken = AppData().authToken;
      if (authToken != null && authToken.isNotEmpty) {
        await _updateFcmTokenPort3067(fcmToken, userId, authToken);
      }
    } catch (e) {
      developer.log('Error updating FCM token on backend: $e');
    }
  }

  Future<void> _updateFcmTokenPort3067(
    String fcmToken,
    String userId,
    String authToken,
  ) async {
    try {
      final url = Uri.parse(
        'http://182.93.94.210:3067/api/v1/update-fcm-token',
      );
      final body = jsonEncode({
        'userId': userId,
        'fcmToken': fcmToken,
        'deviceType': Platform.isAndroid ? 'android' : 'ios',
      });

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        developer.log('✅ FCM token updated on port 3067');
      }
    } catch (e) {
      developer.log('Error updating FCM token on port 3067: $e');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    // Check platform support first
    if (!CrossPlatformAuth.isGoogleSignInSupported) {
      Dialogs.showSnackbar(
        context,
        'Google Sign-In is not supported on this platform. Please use email/password login.',
      );
      return;
    }

    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final UserCredential? userCredential =
          await CrossPlatformAuth.signInWithGoogle();

      if (userCredential == null) {
        setState(() {
          _isGoogleLoading = false;
        });
        return;
      }

      final User? user = userCredential.user;
      if (user != null) {
        // Get the ID token for API authentication
        final String? idToken = await user.getIdToken(true);

        if (idToken == null || idToken.isEmpty) {
          Dialogs.showSnackbar(
            context,
            'Failed to get authentication token from Google',
          );
          return;
        }

        // Single optimized login/register attempt
        await _handleGoogleAuthOptimized(user, idToken);
      }
    } catch (error) {
      developer.log('Google Sign-In error: $error');

      if (error.toString().contains('MissingPluginException')) {
        Dialogs.showSnackbar(
          context,
          'Google Sign-In is not available on this platform. Please use email/password login.',
        );
      } else {
        Dialogs.showSnackbar(
          context,
          'Google Sign-In failed: ${error.toString()}',
        );
      }
    } finally {
      setState(() {
        _isGoogleLoading = false;
      });
    }
  }

  Future<void> _handleGoogleAuthOptimized(User user, String idToken) async {
    try {
      developer.log(
        '🚀 Starting optimized Google authentication for: ${user.email}',
      );
      String? fcmToken;

      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
        developer.log('Got FCM token for Google login');
      } catch (e) {
        developer.log('Could not get FCM token $e');
      }

      // STEP 1: Try login first with the most likely to succeed format
      final loginSuccess = await _attemptOptimizedGoogleLogin(
        user,
        idToken,
        fcmToken,
      );

      if (loginSuccess) {
        developer.log('✅ Google login successful');
        return;
      }

      // STEP 2: If login fails, try registration
      developer.log('🔄 Login failed, attempting registration...');
      final registerSuccess = await _attemptOptimizedGoogleRegister(
        user,
        idToken,
        fcmToken,
      );

      if (registerSuccess) {
        developer.log('✅ Google registration successful');
        return;
      }

      // STEP 3: Fallback to Firebase-only authentication
      developer.log('🔄 API methods failed, using Firebase fallback...');
      await _handleFirebaseFallback(user, idToken);
    } catch (e) {
      developer.log('❌ Error in optimized Google auth: $e');
      Dialogs.showSnackbar(context, 'Authentication failed. Please try again.');
    }
  }

  // Firebase-only fallback (fastest option)
  Future<void> _handleFirebaseFallback(User user, String idToken) async {
    try {
      developer.log('🔥 Using Firebase-only authentication...');

      // Create minimal user data
      Map<String, dynamic> userData = {
        '_id': user.uid,
        'id': user.uid,
        'userId': user.uid,
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName ?? user.email?.split('@')[0] ?? 'User',
        'photoURL': user.photoURL,
        'isEmailVerified': user.emailVerified,
        'provider': 'google',
        'firebaseUser': true,
        'fcmTokens': [],
      };

      // FAST parallel operations
      await Future.wait([
        AppData().setAuthToken(idToken),
        AppData().setCurrentUser(userData),
        FirebaseService.verifyAndCreateUser(
          userId: user.uid,
          name: userData['name'],
          email: user.email ?? '',
          photoURL: user.photoURL,
          provider: 'google',
        ),
      ]);

      // Initialize FCM in background
      _initializeFcmInBackground();

      // Navigate immediately
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => Homepage()),
        (route) => false,
      );

      Dialogs.showSnackbar(context, 'Welcome! Signed in with Google.');
      developer.log('✅ Firebase fallback authentication completed');
    } catch (e) {
      developer.log('❌ Firebase fallback error: $e');
      rethrow;
    }
  }

  Future<bool> _attemptOptimizedGoogleLogin(
    User user,
    String idToken,
    String? fcmToken,
  ) async {
    try {
      final url = Uri.parse('http://182.93.94.210:3067/api/v1/login');

      // Use the most comprehensive format that's most likely to work
      final body = jsonEncode({
        'email': user.email,
        'firebaseToken': idToken,
        'isGoogleLogin': true,
        'provider': 'google',
        'fcmToken': fcmToken ?? '',
        'deviceType': Platform.isAndroid ? 'android' : 'ios',
      });

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      };

      developer.log('🔑 Attempting optimized Google login...');

      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 10)); // Add timeout

      if (response.statusCode == 200) {
        await _handleOptimizedSuccessfulAuth(
          response.body,
          user,
          isNewUser: false,
        );
        return true;
      }

      developer.log('⚠️ Login failed with status: ${response.statusCode}');
      return false;
    } catch (e) {
      developer.log('❌ Optimized Google login error: $e');
      return false;
    }
  }

  Future<bool> _attemptOptimizedGoogleRegister(
    User user,
    String idToken,
    String? fcmToken,
  ) async {
    try {
      final url = Uri.parse('http://182.93.94.210:3067/api/v1/register-user');

      final body = jsonEncode({
        'email': user.email,
        'name': user.displayName ?? user.email?.split('@')[0] ?? 'User',
        'firebaseToken': idToken,
        'isGoogleSignup': true,
        'isEmailVerified': user.emailVerified,
        'uid': user.uid,
        'photoURL': user.photoURL,
        'provider': 'google',
        'fcmToken': fcmToken ?? '',
        'deviceType': Platform.isAndroid ? 'android' : 'ios',
      });

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      };

      developer.log('📝 Attempting optimized Google registration...');

      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _handleOptimizedSuccessfulAuth(
          response.body,
          user,
          isNewUser: true,
        );
        return true;
      }

      developer.log(
        '⚠️ Registration failed with status: ${response.statusCode}',
      );
      return false;
    } catch (e) {
      developer.log('❌ Optimized Google registration error: $e');
      return false;
    }
  }

  // Streamlined success handler
  Future<void> _handleOptimizedSuccessfulAuth(
    String responseBody,
    User user, {
    required bool isNewUser,
  }) async {
    try {
      developer.log('🎯 Processing successful authentication...');

      // Parse response once
      final responseData = jsonDecode(responseBody) as Map<String, dynamic>;

      // Extract data
      final token = _extractToken(responseData);
      final userData = _extractUserData(responseData) ?? {};

      // Ensure proper ID consistency
      final userId =
          userData['_id']?.toString() ?? userData['id']?.toString() ?? user.uid;

      userData['_id'] = userId;
      userData['id'] = userId;
      userData['userId'] = userId;
      userData['uid'] = userId;
      userData['fcmTokens'] = userData['fcmTokens'] ?? [];

      // BATCH OPERATIONS for speed
      await Future.wait([
        // Save token and user data in parallel
        if (token != null) AppData().setAuthToken(token),
        AppData().setCurrentUser(userData),

        // Create/verify user in Firestore (in background)
        FirebaseService.verifyAndCreateUser(
          userId: userId,
          name: user.displayName ?? userData['name'] ?? 'User',
          email: user.email ?? '',
          photoURL: user.photoURL,
          provider: 'google',
        ),
      ]);

      // Initialize FCM in background (don't wait)
      _initializeFcmInBackground();

      // Navigate immediately
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => Homepage()),
        (route) => false,
      );

      final message =
          isNewUser
              ? 'Account created successfully with Google!'
              : 'Welcome back! Signed in with Google.';
      Dialogs.showSnackbar(context, message);

      developer.log('✅ Optimized auth completed successfully');
    } catch (e) {
      developer.log('❌ Error in optimized success handler: $e');
      rethrow;
    }
  }

  void _initializeFcmInBackground() {
    Future.delayed(const Duration(milliseconds: 100), () async {
      try {
        developer.log('🔥 Initializing FCM in background...');

        final fcmToken = await _firebaseMessaging.getToken();
        if (fcmToken != null) {
          await AppData().saveFcmToken(fcmToken);
          developer.log('🔥 FCM token saved in background');
        }

        // Subscribe to user topic
        if (AppData().currentUserId != null) {
          await _firebaseMessaging.subscribeToTopic(
            'user_${AppData().currentUserId}',
          );
          developer.log('🔥 Subscribed to user topic in background');
        }
      } catch (e) {
        developer.log('⚠️ Background FCM initialization error: $e');
      }
    });
  }

  Future<bool> _attemptGoogleLoginForExistingUser(
    User user,
    String? idToken,
  ) async {
    try {
      developer.log(
        'Attempting to login existing Google user with Firebase token',
      );

      // First, try to get user data from your API using the Firebase token
      bool apiLoginSuccess = await _tryApiLoginWithFirebaseToken(user, idToken);
      if (apiLoginSuccess) {
        return true;
      }

      // If API login fails, save Firebase token and basic user data as fallback
      if (idToken != null && idToken.isNotEmpty) {
        try {
          await AppData().setAuthToken(idToken);
          developer.log('Firebase ID token saved to AppData successfully');

          // Create user data with proper format and ID consistency
          Map<String, dynamic> userData = {
            '_id': user.uid,
            'id': user.uid,
            'userId': user.uid,
            'uid': user.uid,
            'email': user.email,
            'name': user.displayName ?? user.email?.split('@')[0] ?? 'User',
            'photoURL': user.photoURL,
            'isEmailVerified': user.emailVerified,
            'provider': 'google',
            'firebaseUser': true,
            'fcmTokens': [], // Initialize fcmTokens
          };

          await AppData().setCurrentUser(userData);
          developer.log(
            'User data saved successfully with _id: ${userData['_id']}',
          );

          // ENHANCED: Use verifyAndCreateUser for better consistency
          await FirebaseService.verifyAndCreateUser(
            userId: user.uid,
            name: user.displayName ?? user.email?.split('@')[0] ?? 'User',
            email: user.email ?? '',
            photoURL: user.photoURL,
            provider: 'google',
          );

          // Save FCM token
          try {
            final token = await _firebaseMessaging.getToken();
            if (token != null) {
              await AppData().saveFcmToken(token);
              developer.log('FCM token saved for Google user: $token');
              final updatedUserData = AppData().currentUser;
              developer.log(
                'Updated user data after FCM save: $updatedUserData',
              );
            } else {
              developer.log('Failed to retrieve FCM token for Google user');
            }
          } catch (e) {
            developer.log('Error saving FCM token for Google user: $e');
          }

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => Homepage()),
            (route) => false,
          );

          Dialogs.showSnackbar(context, 'Welcome back! Signed in with Google.');
          return true;
        } catch (e) {
          developer.log('Error saving Firebase token or user data: $e');
          Dialogs.showSnackbar(context, 'Error saving authentication data');
          return false;
        }
      } else {
        developer.log('No Firebase token available for existing user');
        return false;
      }
    } catch (e) {
      developer.log('Error in _attemptGoogleLoginForExistingUser: $e');
      return false;
    }
  }

  Future<bool> _tryApiLoginWithFirebaseToken(User user, String? idToken) async {
    try {
      developer.log('Trying API login with Firebase token for existing user');

      final url = Uri.parse('http://182.93.94.210:3067/api/v1/login');
      final body = jsonEncode({
        'email': user.email,
        'firebaseToken': idToken ?? '',
        'isExistingGoogleUser': true,
      });

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      };

      developer.log('Existing user login request: $body');
      final response = await http.post(url, headers: headers, body: body);

      developer.log(
        'Existing user login API Response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        await _handleSuccessfulLogin(response.body);
        return true;
      } else {
        developer.log(
          'API login failed for existing user, will use Firebase token as fallback',
        );
        return false;
      }
    } catch (e) {
      developer.log('Error in API login for existing user: $e');
      return false;
    }
  }

  Future<bool> _attemptGoogleLogin(User user, String? idToken) async {
    try {
      final url = Uri.parse('http://182.93.94.210:3067/api/v1/login');

      // Try multiple request formats to see which one works
      List<Map<String, dynamic>> requestFormats = [
        {'firebaseToken': idToken ?? ''},
        {'email': user.email, 'firebaseToken': idToken ?? ''},
        {
          'email': user.email,
          'firebaseToken': idToken ?? '',
          'isGoogleLogin': true,
        },
      ];

      for (int i = 0; i < requestFormats.length; i++) {
        final body = requestFormats[i];
        final jsonBody = jsonEncode(body);
        final headers = {'Content-Type': 'application/json'};

        developer.log('Google Login Attempt ${i + 1} Request Body: $jsonBody');
        final response = await http.post(url, headers: headers, body: jsonBody);

        developer.log(
          'Google Login Attempt ${i + 1} API Response: ${response.statusCode} - ${response.body}',
        );

        if (response.statusCode == 200) {
          await _handleSuccessfulLogin(response.body);
          return true;
        } else if (response.statusCode != 400) {
          break;
        }
      }

      developer.log(
        'All Google login attempts failed, will attempt registration',
      );
      return false;
    } catch (e) {
      developer.log('Google login error: $e');
      return false;
    }
  }

  Future<bool> _attemptGoogleRegister(User user, String? idToken) async {
    try {
      final url = Uri.parse('http://182.93.94.210:3067/api/v1/register-user');

      // Prepare registration data with consistent ID fields
      Map<String, dynamic> body = {
        'email': user.email,
        'name': user.displayName ?? user.email?.split('@')[0] ?? 'User',
        'firebaseToken': idToken ?? '',
        'isGoogleSignup': true,
        'isEmailVerified': user.emailVerified,
        'uid': user.uid, // Include Firebase UID
      };

      if (user.photoURL != null) {
        body['photoURL'] = user.photoURL;
      }

      final jsonBody = jsonEncode(body);
      final headers = {'Content-Type': 'application/json'};

      developer.log('Google Register Request Body: $jsonBody');
      final response = await http.post(url, headers: headers, body: jsonBody);

      developer.log(
        'Google Register API Response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ENHANCED: Use verifyAndCreateUser for consistency
        await FirebaseService.verifyAndCreateUser(
          userId: user.uid,
          name: user.displayName ?? user.email?.split('@')[0] ?? 'User',
          email: user.email ?? '',
          photoURL: user.photoURL,
          provider: 'google',
        );

        await _handleSuccessfulLogin(response.body);
        Dialogs.showSnackbar(
          context,
          'Account created successfully with Google!',
        );
        return true;
      } else if (response.statusCode == 409) {
        developer.log(
          'Email already exists (409), will attempt login for existing user',
        );
        return false;
      } else {
        Map<String, dynamic>? responseData;
        try {
          responseData = jsonDecode(response.body) as Map<String, dynamic>?;
        } catch (e) {
          developer.log('Error parsing registration error response: $e');
        }

        final message =
            responseData?['message'] ??
            responseData?['error']?['error'] ??
            responseData?['error'] ??
            'Registration failed with status ${response.statusCode}';
        Dialogs.showSnackbar(context, message.toString());
        return false;
      }
    } catch (e) {
      developer.log('Google registration error: $e');
      Dialogs.showSnackbar(context, 'Registration failed. Please try again.');
      return false;
    }
  }

  Future<void> _handleSuccessfulLogin(String responseBody) async {
    try {
      developer.log('🚀 Processing successful login...');

      final responseData = jsonDecode(responseBody) as Map<String, dynamic>;

      // Extract tokens
      final authToken = _extractToken(responseData);
      final apiToken = _extractApiToken(
        responseData,
      ); // Extract API token if present
      final userData = _extractUserData(responseData);

      if (userData != null) {
        // Ensure proper ID consistency
        String? userId =
            userData['_id']?.toString() ??
            userData['id']?.toString() ??
            userData['userId']?.toString();

        if (userId != null) {
          userData['_id'] = userId;
          userData['id'] = userId;
          userData['userId'] = userId;
          userData['uid'] = userId;
        }

        userData['fcmTokens'] ??= [];
      }

      // Save all data
      await Future.wait([
        if (authToken != null) AppData().setAuthToken(authToken),
        if (apiToken != null) AppData().setApiToken(apiToken),
        if (userData != null) AppData().setCurrentUser(userData),
      ]);

      // Initialize FCM after login data is saved
      await AppData().initializeFcmAfterLogin();

      // Additional FCM token refresh to ensure it's saved
      await _ensureFcmTokenIsSaved();

      // Firebase Auth session
      await _createFirebaseAuthSession(userData);

      // Initialize other services

     // await _initializeFollowStatusManager();
      //await _initializeChatControllerWithFollowStatus();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => Homepage()),
        (route) => false,
      );
    } catch (e) {
      developer.log('❌ Error in login handler: $e');
      Dialogs.showSnackbar(context, 'Login processing failed');
    }
  }

  String? _extractApiToken(Map<String, dynamic> responseData) {
    return responseData['apiToken'] ??
        responseData['api_token'] ??
        responseData['token'];
  }

  Future<void> _ensureFcmTokenIsSaved() async {
    try {
      // Get current token
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken == null || fcmToken.isEmpty) {
        // Force refresh if no token
        await FirebaseMessaging.instance.deleteToken();
        await Future.delayed(const Duration(seconds: 1));
        fcmToken = await FirebaseMessaging.instance.getToken();
      }

      if (fcmToken != null && fcmToken.isNotEmpty) {
        await AppData().saveFcmToken(fcmToken);
        await _updateFcmTokenOnBackend(fcmToken);

        // Subscribe to user topic
        final userId = AppData().currentUserId;
        if (userId != null) {
          await FirebaseMessaging.instance.subscribeToTopic('user_$userId');
          await FirebaseMessaging.instance.subscribeToTopic('all_users');
        }

        developer.log('✅ FCM token ensured and saved');
      }
    } catch (e) {
      developer.log('Error ensuring FCM token: $e');
    }
  }

  Future<void> _initializeFollowStatusManager() async {
    try {
      developer.log('👥 Setting up Follow Status Manager...');

      // Ensure FollowStatusManager is registered
      if (!Get.isRegistered<FollowStatusManager>()) {
        Get.put(FollowStatusManager(), permanent: true);
      }

      final followStatusManager = Get.find<FollowStatusManager>();

      // Get all users from Firestore to preload follow statuses
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get()
          .timeout(const Duration(seconds: 10));

      final emails =
          usersSnapshot.docs
              .map((doc) => doc.data()['email']?.toString())
              .where((email) => email != null && email.isNotEmpty)
              .cast<String>()
              .toList();

      if (emails.isNotEmpty) {
        developer.log(
          '👥 Preloading follow statuses for ${emails.length} users...',
        );
        await followStatusManager.preloadFollowStatuses(emails);
        developer.log('✅ Follow statuses preloaded successfully');
      }
    } catch (e) {
      developer.log('❌ Error initializing Follow Status Manager: $e');
      // Don't throw - let the app continue with limited functionality
    }
  }

  // 🔥 NEW: Initialize chat controller with follow status integration
  Future<void> _initializeChatControllerWithFollowStatus() async {
    try {
      developer.log('💬 Initializing chat controller with follow status...');

      // Wait for Firebase Auth to be fully ready
      await Future.delayed(const Duration(milliseconds: 1000));

      // Register chat controller if not already registered
      if (!Get.isRegistered<FireChatController>()) {
        Get.put(FireChatController(), permanent: true);
        developer.log('💬 Chat controller registered');
      }

      final chatController = Get.find<FireChatController>();

      // Initialize user data
      chatController.initializeUser();
      developer.log('💬 Chat controller user initialized');

      // 🔥 IMPORTANT: Load users with follow status filter
      await Future.wait([
        chatController
            .loadAllUsersWithFollowFilter(), // Load only mutual followers
        chatController
            .loadUserChatsWithEnhancedProfiles(), // Load chats with API profile data
      ]);

      developer.log(
        '✅ Chat controller fully initialized with follow status filtering',
      );
    } catch (e) {
      developer.log(
        '❌ Error initializing chat controller with follow status: $e',
      );
      // Don't throw - let the app continue even if chat has issues
    }
  }

  Future<void> _createFirebaseAuthSession(
    Map<String, dynamic>? userData,
  ) async {
    try {
      developer.log('🔥 Creating Firebase Auth session...');

      // Check if already signed in
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        developer.log('✅ Firebase user already signed in: ${currentUser.uid}');
        return;
      }

      // Try anonymous sign-in first
      try {
        developer.log('🔄 Attempting anonymous Firebase Auth...');
        final anonCredential = await FirebaseAuth.instance.signInAnonymously();
        developer.log(
          '✅ Firebase Auth anonymous session: ${anonCredential.user?.uid}',
        );

        // Update user document with Firebase UID
        if (userData != null && userData['_id'] != null) {
          await _updateFirestoreUserDocument(
            userData,
            anonCredential.user?.uid,
          );
        }
        return;
      } catch (anonymousError) {
        if (anonymousError.toString().contains('admin-restricted-operation')) {
          developer.log(
            '⚠️ Anonymous auth disabled, trying email/password method...',
          );

          // Try email/password method
          if (userData != null && userData['email'] != null) {
            await _tryEmailPasswordAuth(userData);
            return;
          }
        }

        throw anonymousError;
      }
    } catch (e) {
      developer.log('❌ All Firebase Auth methods failed: $e');

      // Fallback: Just update Firestore and use permissive rules
      if (userData != null) {
        await _updateFirestoreUserDocument(userData, null);
        developer.log(
          '⚠️ Using Firestore-only mode. Some features may be limited.',
        );
      }
    }
  }

  Future<void> _tryEmailPasswordAuth(Map<String, dynamic> userData) async {
    try {
      final email = userData['email'].toString();
      final userId = userData['_id'].toString();
      final dummyPassword = 'temp_${userId}_password123';

      try {
        // Try to sign in first
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: dummyPassword,
        );
        developer.log('✅ Firebase Auth email sign-in successful');
      } catch (signInError) {
        // If sign-in fails, try to create account
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: email,
              password: dummyPassword,
            );
        developer.log(
          '✅ Firebase Auth account created: ${credential.user?.uid}',
        );

        // Update display name
        if (userData['name'] != null) {
          await credential.user?.updateDisplayName(userData['name'].toString());
        }
      }

      // Update Firestore with Firebase UID
      final firebaseUser = FirebaseAuth.instance.currentUser;
      await _updateFirestoreUserDocument(userData, firebaseUser?.uid);
    } catch (e) {
      developer.log('❌ Email/password auth failed: $e');
      throw e;
    }
  }

  Future<void> _updateFirestoreUserDocument(
    Map<String, dynamic> userData,
    String? firebaseUID,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final docData = {
        'userId': userData['_id'],
        '_id': userData['_id'],
        'id': userData['_id'],
        'uid': userData['_id'],
        'authMethod': firebaseUID != null ? 'firebase_auth' : 'custom_auth',
        'lastUpdate': FieldValue.serverTimestamp(),
        'name': userData['name'] ?? 'User',
        'email': userData['email'] ?? '',
        'phone': userData['phone'] ?? '',
        'dob': userData['dob'] ?? '',
        'photoURL': userData['photoURL'] ?? '',
        'provider': userData['provider'] ?? 'email',
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'nameSearchable': (userData['name'] ?? '').toLowerCase(),
        'emailSearchable': (userData['email'] ?? '').toLowerCase(),
        'notificationsEnabled': true,
      };

      // Add Firebase UID if available
      if (firebaseUID != null) {
        docData['firebaseUID'] = firebaseUID;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userData['_id'])
          .set(docData, SetOptions(merge: true));

      developer.log(
        '✅ User document updated in Firestore with follow status support',
      );
    } catch (e) {
      developer.log('❌ Error updating Firestore user document: $e');
      throw e;
    }
  }

  // Extract token from response
  String? _extractToken(Map<String, dynamic> responseData) {
    if (responseData['token'] is String) {
      return responseData['token'];
    } else if (responseData['access_token'] is String) {
      return responseData['access_token'];
    } else if (responseData['data'] is Map &&
        responseData['data']?['token'] is String) {
      return responseData['data']['token'];
    } else if (responseData['authToken'] is String) {
      return responseData['authToken'];
    } else if (responseData['accessToken'] is String) {
      return responseData['accessToken'];
    }
    return null;
  }

  // Extract user data from response
  Map<String, dynamic>? _extractUserData(Map<String, dynamic> responseData) {
    if (responseData['user'] is Map) {
      return Map<String, dynamic>.from(responseData['user']);
    } else if (responseData['data'] is Map &&
        responseData['data']['user'] is Map) {
      return Map<String, dynamic>.from(responseData['data']['user']);
    } else if (responseData['data'] is Map) {
      return Map<String, dynamic>.from(responseData['data']);
    }
    return null;
  }

  void _handleLoginError(http.Response response) {
    Map<String, dynamic>? responseData;
    try {
      responseData = jsonDecode(response.body) as Map<String, dynamic>?;
    } catch (e) {
      developer.log('Error parsing error response: $e');
    }

    final message =
        responseData?['message'] ??
        responseData?['error'] ??
        'Login failed with status ${response.statusCode}';
    Dialogs.showSnackbar(context, message.toString());
  }

  Future<void> _showAccountPicker() async {
    if (!CrossPlatformAuth.isGoogleSignInSupported) {
      Dialogs.showSnackbar(
        context,
        'Google Sign-In is not supported on this platform.',
      );
      return;
    }

    try {
      await CrossPlatformAuth.signOut();
      _handleGoogleSignIn();
    } catch (e) {
      developer.log('Error showing account picker: $e');
      _handleGoogleSignIn();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final mq = MediaQuery.of(context).size;

    return Theme(
      data: ThemeData(primaryColor: preciseGreen),
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 2.0,
              decoration: BoxDecoration(
                color: Color.fromRGBO(244, 135, 6, 1),
                // color: Color(0xffFFC067),
                // color: Colors.orange.shade800,
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(70),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: mq.width * 0.03,
                  top: mq.height * 0.02,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      'Welcome\nBack,',
                      style: TextStyle(
                        fontSize: 30,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),

                    Align(
                      alignment: Alignment.topRight,
                      child: Image.asset(
                        'animation/loginimage.gif',
                        width: screenSize.width * 0.5,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 1.6,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(70)),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: mq.height * 0.05,
                    right: mq.width * 0.05,
                    left: mq.width * 0.05,
                    bottom: mq.height * 0.02,
                  ),
                  child: SingleChildScrollView(
                    child: AutofillGroup(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Email',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'InterThin',
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: mq.height * 0.004),
                                TextFormField(
                                  controller: emailController,
                                  focusNode: _emailFocusNode,
                                  autofillHints: [
                                    AutofillHints.username,
                                    AutofillHints.email,
                                  ],
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  onEditingComplete:
                                      () => _passwordFocusNode.requestFocus(),
                                  decoration: InputDecoration(
                                    hintText: 'Enter your email',
                                    hintStyle: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                      fontFamily: 'InterThin',
                                    ),
                                    prefixIcon: Icon(
                                      Icons.email,
                                      color: Colors.black54,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Color.fromRGBO(244, 135, 6, 1),
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.red),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.red),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: mq.height * 0.025),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Password',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'InterThin',
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: mq.height * 0.004),
                                TextFormField(
                                  controller: passwordController,
                                  focusNode: _passwordFocusNode,
                                  obscureText: !_isPasswordVisible,
                                  autofillHints: [AutofillHints.password],
                                  onEditingComplete: () {
                                    TextInput.finishAutofillContext();
                                    _loginWithAPI();
                                  },

                                  decoration: InputDecoration(
                                    hintText: 'Enter your password',
                                    hintStyle: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                      fontFamily: 'InterThin',
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible =
                                              !_isPasswordVisible;
                                        });
                                      },
                                    ),

                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Color.fromRGBO(244, 135, 6, 1),
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.red),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.red),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: mq.height * 0.01),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Checkbox(value: false, onChanged: (value) {}),
                                Row(
                                  children: [
                                    Checkbox(
                                      activeColor: Color.fromRGBO(
                                        244,
                                        135,
                                        6,
                                        1,
                                      ),
                                      checkColor: Colors.white,
                                      value: rememberMe,
                                      onChanged: (value) {
                                        setState(() {
                                          rememberMe = value!;
                                        });
                                      },
                                    ),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          rememberMe = !rememberMe;
                                        });
                                      },
                                      child: Text('Remember Me'),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: (() => Get.to(Forgot_PWD())),
                                  child: Text(
                                    'Forgot Password ?',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey,
                                      fontFamily: 'InterThin',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: mq.height * 0.02),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color.fromRGBO(244, 135, 6, 1),
                                // backgroundColor: Color(0xffFFC067),
                                // foregroundColor: Colors.white,
                                elevation: 10,
                                shadowColor: Colors.transparent,
                                minimumSize: Size(200, 50),
                                maximumSize: Size(200, 100),
                                padding: EdgeInsets.all(10),
                                side: BorderSide(
                                  width: 1,
                                  color: Colors.transparent,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _isLoading ? null : _loginWithAPI,
                              child:
                                  _isLoading
                                      ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      )
                                      : Text(
                                        'Login',
                                        style: TextStyle(
                                          fontSize: 16,

                                          color: Colors.white,

                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'InterThin',
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                            ),
                            SizedBox(height: mq.height * 0.02),

                            //_buildGoogleSignInButton(),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color.fromRGBO(244, 135, 6, 1),
                                // backgroundColor: Color(0xffFFC067),
                                shape: StadiumBorder(),
                                elevation: 1,
                              ),
                              onPressed:
                                  _isGoogleLoading ? null : _showAccountPicker,
                              icon:
                                  _isGoogleLoading
                                      ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : Image.asset(
                                        // 'animation/Googlesignup.json',
                                        'assets/icon/google.png',

                                        height: mq.height * .02,
                                      ),
                              label: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 19,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Sign In with ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'InterThin',
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Google',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'InterThin',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: mq.height * 0.02),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Don\'t have an account?',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'InterThin',
                                  ),
                                ),
                                SizedBox(width: mq.width * 0.01),
                                InkWell(
                                  onTap: () {
                                    TextInput.finishAutofillContext(
                                      shouldSave: false,
                                    );
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => Signup(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Sign Up',

                                    style: TextStyle(
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.blue,
                                      fontSize: 15,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'InterThin',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
