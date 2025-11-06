import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Innivator//models/Blocked_Model.dart';
import 'package:innovator/Innivator//screens/chatApp/controller/chat_controller.dart';
import 'package:innovator/Innivator//screens/comment/JWT_Helper.dart';
import 'package:innovator/Innivator//services/firebase_services.dart';

import 'package:shared_preferences/shared_preferences.dart';

class AppData {
  static final AppData _instance = AppData._internal();
  factory AppData() => _instance;
  AppData._internal();

  // In-memory storage
  String? _authToken;
  Map<String, dynamic>? _currentUser;
  String? _apiToken;
  bool _isOfflineMode = false;
  bool _isInitialized = false;

  // Cache SharedPreferences instance
  SharedPreferences? _prefs;

  // Keys for SharedPreferences
  static const String _tokenKey = 'auth_token';
  static const String _currentUserKey = 'current_user';
  static const String _apiTokenKey = 'api_token';

  // Getters
  String? get authToken => _authToken;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get apiToken => _apiToken;
  bool get isOfflineMode => _isOfflineMode;
  bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;

  String? get currentUserEmail => _currentUser?['email'];
  String? get currentUserId => JwtHelper.extractUserId(_authToken);
  String? get currentUserName => _currentUser?['name'];
  String? get currentUserProfilePicture => _currentUser?['picture'];
  List<String>? get fcmTokens => _currentUser?['fcmTokens']?.cast<String>();

  // OPTIMIZED: Fast synchronous initialization
  Future<void> initialize() async {
    if (_isInitialized) {
      developer.log('AppData already initialized, skipping...');
      return;
    }

    try {
      // Cache the SharedPreferences instance
      _prefs ??= await SharedPreferences.getInstance();

      // Load essential data only
      _authToken = _prefs!.getString(_tokenKey);
      _apiToken = _prefs!.getString(_apiTokenKey);

      final userJson = _prefs!.getString(_currentUserKey);
      if (userJson != null) {
        try {
          _currentUser = jsonDecode(userJson) as Map<String, dynamic>;
        } catch (e) {
          developer.log('Error decoding user JSON: $e');
          _currentUser = null;
        }
      }

      _isInitialized = true;
      developer.log('✅ AppData initialized (Fast mode)');
    } catch (e) {
      developer.log('❌ Error initializing AppData: $e');
    }
  }

  Future<void> initializeOffline() async {
    try {
      _isOfflineMode = true;
      _prefs ??= await SharedPreferences.getInstance();
      
      // Load cached data only
      _authToken = _prefs!.getString(_tokenKey);
      _apiToken = _prefs!.getString(_apiTokenKey);
      
      final userJson = _prefs!.getString(_currentUserKey);
      if (userJson != null) {
        _currentUser = jsonDecode(userJson) as Map<String, dynamic>;
      }
      
      _isInitialized = true;
      developer.log('✅ AppData initialized (Offline mode)');
    } catch (e) {
      developer.log('❌ Offline initialization failed: $e');
      rethrow;
    }
  }

  // OPTIMIZED: Non-blocking token save
  Future<void> setApiToken(String token) async {
    _apiToken = token;
    _saveToPrefsAsync(_apiTokenKey, token);
  }

  Future<void> setAuthToken(String token) async {
    _authToken = token;
    _saveToPrefsAsync(_tokenKey, token);
  }

  Future<void> clearAuthToken() async {
    _authToken = null;
    _removeFromPrefsAsync(_tokenKey);
  }

  Future<void> setCurrentUser(Map<String, dynamic> userData) async {
    if (userData['_id'] == null) {
      developer.log('Error: User data missing "_id" field');
      return;
    }
    _currentUser = userData;
    _saveToPrefsAsync(_currentUserKey, jsonEncode(userData));
  }

  Future<void> clearCurrentUser() async {
    _currentUser = null;
    _removeFromPrefsAsync(_currentUserKey);
  }

  Future<void> updateCurrentUserField(String field, dynamic value) async {
    if (_currentUser == null) return;
    
    _currentUser![field] = value;
    _saveToPrefsAsync(_currentUserKey, jsonEncode(_currentUser));
  }

  Future<void> updateProfilePicture(String pictureUrl) async {
    if (_currentUser == null) return;
    
    _currentUser!['picture'] = pictureUrl;
    _saveToPrefsAsync(_currentUserKey, jsonEncode(_currentUser));
  }

  // CRITICAL: Non-blocking preference saves
  void _saveToPrefsAsync(String key, String value) {
    Future.microtask(() async {
      try {
        _prefs ??= await SharedPreferences.getInstance();
        await _prefs!.setString(key, value);
      } catch (e) {
        developer.log('Error saving $key: $e');
      }
    });
  }

  void _removeFromPrefsAsync(String key) {
    Future.microtask(() async {
      try {
        _prefs ??= await SharedPreferences.getInstance();
        await _prefs!.remove(key);
      } catch (e) {
        developer.log('Error removing $key: $e');
      }
    });
  }

  // OPTIMIZED: FCM token management
  Future<void> saveFcmToken(String fcmToken) async {
    if (_currentUser == null || !_isValidFCMToken(fcmToken)) return;

    developer.log('📱 Saving FCM token...');

    _currentUser!['fcmTokens'] ??= [];
    final currentTokens = List<String>.from(_currentUser!['fcmTokens'] ?? []);
    
    if (!currentTokens.contains(fcmToken)) {
      currentTokens.insert(0, fcmToken);
      if (currentTokens.length > 3) {
        currentTokens.removeRange(3, currentTokens.length);
      }
      
      _currentUser!['fcmTokens'] = currentTokens;
      _currentUser!['fcmToken'] = fcmToken;
      
      // Save locally (non-blocking)
      _saveToPrefsAsync(_currentUserKey, jsonEncode(_currentUser));
      
      // Update backend asynchronously (don't block)
      _updateFcmTokenOnBackend(fcmToken);
      _updateFirestoreFcmToken(fcmToken);
    }
  }

  bool _isValidFCMToken(String token) {
    return token.isNotEmpty && token.length >= 50;
  }

  Future<void> _updateFirestoreFcmToken(String fcmToken) async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
        'fcmToken': fcmToken,
        'fcmTokens': _currentUser!['fcmTokens'] ?? [fcmToken],
        'lastTokenUpdate': FieldValue.serverTimestamp(),
        'tokenDevice': Platform.isAndroid ? 'android' : 'ios',
        'notificationsEnabled': true,
      }, SetOptions(merge: true));

      developer.log('✅ FCM token updated in Firestore');
    } catch (e) {
      developer.log('❌ Firestore update error: $e');
    }
  }

 Future<void> _updateFcmTokenOnBackend(String fcmToken) async {
  try {
    final userId = currentUserId;
    
    // CRITICAL: Check if we have authentication token
    if (userId == null || _authToken == null) {
      developer.log('⚠️ Cannot update FCM token: Missing auth token or userId');
      return;
    }

    final url = Uri.parse('http://182.93.94.210:3067/api/v1/update-fcm-token');
    
    developer.log('📱 Updating FCM token on backend...');
    developer.log('📱 User ID: $userId');
    developer.log('📱 Auth Token: ${_authToken!.substring(0, 20)}...');
    developer.log('📱 FCM Token: ${fcmToken.substring(0, 20)}...');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_authToken', // CRITICAL: Add auth header
      },
      body: jsonEncode({
        'token': fcmToken, // This is the FCM token
        'deviceType': Platform.isAndroid ? 'android' : 'ios', // Optional but useful
      }),
    ).timeout(const Duration(seconds: 10));
    
    developer.log('📱 Backend response status: ${response.statusCode}');
    developer.log('📱 Backend response body: ${response.body}');
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      developer.log('✅ FCM token updated on backend successfully');
    } else {
      developer.log('⚠️ Backend returned non-success status: ${response.statusCode}');
      developer.log('⚠️ Response: ${response.body}');
    }
  } catch (e) {
    developer.log('❌ Backend update error: $e');
    // Don't rethrow - FCM token update is non-critical
  }
}

  String? getMostRecentFcmToken() {
    final tokens = _currentUser?['fcmTokens'] as List<dynamic>?;
    if (tokens != null && tokens.isNotEmpty) {
      for (final token in tokens) {
        final tokenStr = token.toString();
        if (_isValidFCMToken(tokenStr)) return tokenStr;
      }
    }

    final singleToken = _currentUser?['fcmToken']?.toString();
    if (singleToken != null && _isValidFCMToken(singleToken)) {
      return singleToken;
    }
    
    return null;
  }

  Future<void> refreshFcmToken() async {
    try {
      developer.log('🔄 Refreshing FCM token...');
      await FirebaseMessaging.instance.deleteToken();
      await Future.delayed(const Duration(seconds: 1));

      final newToken = await FirebaseMessaging.instance.getToken();
      if (newToken != null) {
        await saveFcmToken(newToken);
      }
    } catch (e) {
      developer.log('❌ Error refreshing FCM token: $e');
    }
  }

  // DEFERRED: Initialize FCM after login (non-blocking)
  Future<void> initializeFcmAfterLogin() async {
    // Run in background, don't block
    Future.microtask(() async {
      try {
        if (_currentUser == null) return;

        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

        if (settings.authorizationStatus != AuthorizationStatus.authorized) {
          return;
        }

        String? fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await saveFcmToken(fcmToken);
          
          if (currentUserId != null) {
            await FirebaseMessaging.instance.subscribeToTopic('user_$currentUserId');
            await FirebaseMessaging.instance.subscribeToTopic('all_users');
          }
        }

        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
          await saveFcmToken(newToken);
          if (currentUserId != null) {
            await FirebaseMessaging.instance.subscribeToTopic('user_$currentUserId');
          }
        });
      } catch (e) {
        developer.log('❌ FCM initialization error: $e');
      }
    });
  }

  bool isCurrentUser(String userId) {
    final currentId = JwtHelper.extractUserId(_authToken);
    return currentId != null && currentId == userId;
  }

  bool isCurrentUserByEmail(String email) {
    if (_currentUser == null || _currentUser!['email'] == null) return false;
    
    return _currentUser!['email'].toString().trim().toLowerCase() ==
           email.trim().toLowerCase();
  }

  // OPTIMIZED: Enhanced logout with proper cleanup
  Future<void> logout() async {
    try {
      developer.log('🚪 Starting logout...');

      // Stop listeners
      if (Get.isRegistered<FireChatController>()) {
        await Get.find<FireChatController>().completeLogout();
      }

      // Update status
      if (_currentUser?['_id'] != null) {
        try {
          await FirebaseService.updateUserStatus(_currentUser!['_id'], false);
        } catch (e) {}
      }

      // Clear FCM
      await _clearFcmTokenFromBackend();

      // Sign out
      await _signOutFromFirebase();

      // Clear data
      _authToken = null;
      _currentUser = null;
      _apiToken = null;
      _isInitialized = false;

      // Clear preferences
      _prefs?.clear();

      developer.log('✅ Logout complete');
    } catch (e) {
      developer.log('❌ Logout error: $e');
      // Force clear anyway
      _authToken = null;
      _currentUser = null;
      _apiToken = null;
      _isInitialized = false;
    }
  }

  Future<void> _clearFcmTokenFromBackend() async {
    try {
      if (_authToken == null || _currentUser == null) return;

      final url = Uri.parse('http://182.93.94.210:3067/api/v1/clear-fcm-token');
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({'userId': _currentUser!['_id'], 'fcmTokens': []}),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {}
  }

  Future<void> _signOutFromFirebase() async {
    try {
      await Future.wait([
        FirebaseAuth.instance.signOut(),
        GoogleSignIn().signOut(),
      ]);
    } catch (e) {}
  }

  // Rest of your existing methods...
  Future<List<dynamic>> fetchNotifications() async {
    try {
      final url = Uri.parse('http://182.93.94.210:3067/api/v1/notifications');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<BlockedUsersResponse> fetchBlockedUsers({
    int page = 0,
    int limit = 20,
  }) async {
    try {
      if (_authToken == null) {
        throw Exception('Authentication required');
      }

      final uri = Uri.parse('http://182.93.94.210:3067/api/v1/blocked-users')
          .replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return BlockedUsersResponse.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to fetch blocked users');
    } catch (e) {
      return BlockedUsersResponse(
        status: 500,
        blockedUsers: [],
        pagination: BlockedUsersPagination.fromJson({}),
        error: e.toString(),
        message: '',
      );
    }
  }

  Future<bool> isUserBlocked(String userId) async {
    try {
      final response = await fetchBlockedUsers(limit: 100);
      return response.blockedUsers.any((user) => user.id == userId);
    } catch (e) {
      return false;
    }
  }
}