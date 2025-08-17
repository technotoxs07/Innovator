import 'dart:convert';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Authorization/Login.dart';
import 'package:innovator/Authorization/firebase_services.dart';
import 'package:innovator/main.dart';
import 'package:innovator/screens/Blocked/Blocked_Model.dart';
import 'package:innovator/screens/chatApp/controller/chat_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:innovator/screens/comment/JWT_Helper.dart';

import '../services/Notification_services.dart';

class AppData {
  // Singleton instance
  static final AppData _instance = AppData._internal();
  factory AppData() => _instance;
  AppData._internal();

  // In-memory storage
  String? _authToken;
  Map<String, dynamic>? _currentUser;
  
  // Keys for SharedPreferences
  static const String _tokenKey = 'auth_token';
  static const String _currentUserKey = 'current_user';
  
  // Getters
  String? get authToken => _authToken;
  Map<String, dynamic>? get currentUser => _currentUser;
  
  String? get currentUserEmail {
    final email = _currentUser?['email'];
    developer.log('Getting current user email: ${email ?? "null"}');
    return email;
  }
  
  String? get currentUserId {
    final id = JwtHelper.extractUserId(_authToken);
    developer.log('Getting current user ID from JWT: ${id ?? "null"}');
    return id;
  } 
  
  String? get currentUserName => _currentUser?['name'];
  
  String? get currentUserProfilePicture => _currentUser?['profilePicture'];
  
  // New getter for fcmTokens
  List<String>? get fcmTokens => _currentUser?['fcmTokens']?.cast<String>();
  
  // Initialize app data
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _authToken = prefs.getString(_tokenKey);
      developer.log('Auth token: ${_authToken ?? "null"}');
      
      final userJson = prefs.getString(_currentUserKey);
      if (userJson != null) {
        try {
          _currentUser = jsonDecode(userJson) as Map<String, dynamic>;
          developer.log('Loaded user data: $_currentUser');
          if (_currentUser?['_id'] == null) {
            developer.log('Warning: User data does not contain "id" field');
          }
        } catch (e) {
          developer.log('Error decoding user JSON: $e');
          _currentUser = null;
        }
      } else {
        developer.log('No user data found in SharedPreferences');
      }
      
      developer.log('AppData initialized: ${_authToken != null ? "Token exists" : "No token"}, ${_currentUser != null ? "User exists" : "No user"}');
    } catch (e) {
      developer.log('Error initializing AppData: $e');
    }
  }
  
  // Set token
  Future<void> setAuthToken(String token) async {
    _authToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      developer.log('Token saved successfully in AppData');
    } catch (e) {
      developer.log('Error saving token in AppData: $e');
    }
  }
  
  // Clear token
  Future<void> clearAuthToken() async {
    _authToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      developer.log('Token cleared from AppData');
    } catch (e) {
      developer.log('Error clearing token from AppData: $e');
    }
  }
  
  // Set current user data
  Future<void> setCurrentUser(Map<String, dynamic> userData) async {
    if (userData['_id'] == null) {
      developer.log('Error: Attempted to set user data without "_id" field: $userData');
      return;
    }
    _currentUser = userData;
    developer.log('Setting current user: $_currentUser');
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(userData);
      await prefs.setString(_currentUserKey, userJson);
      developer.log('Current user data saved successfully');
    } catch (e) {
      developer.log('Error saving current user data: $e');
    }
  }
  
  // Clear current user data
  Future<void> clearCurrentUser() async {
    _currentUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserKey);
      developer.log('Current user data cleared');
    } catch (e) {
      developer.log('Error clearing current user data: $e');
    }
  }
  
  // Update specific user field
  Future<void> updateCurrentUserField(String field, dynamic value) async {
    if (_currentUser == null) {
      developer.log('Cannot update user field - current user is null');
      return;
    }
    
    _currentUser![field] = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(_currentUser);
      await prefs.setString(_currentUserKey, userJson);
      developer.log('Updated user field: $field');
    } catch (e) {
      developer.log('Error updating user field: $e');
    }
  }
  
  // Update profile picture
 Future<void> updateProfilePicture(String pictureUrl) async {
    if (_currentUser == null) return;
    
    _currentUser!['picture'] = pictureUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, jsonEncode(_currentUser));
    } catch (e) {
      developer.log('Error updating profile picture: $e');
    }
  }
  
  // New method to save or update FCM token
 Future<void> saveFcmToken(String fcmToken) async {
    if (_currentUser == null) {
      developer.log('Cannot save FCM token - current user is null');
      return;
    }
    
    // Validate token format
    if (!_isValidFCMToken(fcmToken)) {
      developer.log('❌ Invalid FCM token format: ${fcmToken.substring(0, 20)}...');
      return;
    }
    
    // Initialize fcmTokens if it doesn't exist
    _currentUser!['fcmTokens'] ??= [];
    
    // Clean old tokens and avoid duplicates
    final currentTokens = List<String>.from(_currentUser!['fcmTokens'] ?? []);
    
    // Remove the new token if it already exists
    currentTokens.removeWhere((token) => token == fcmToken);
    
    // Add the new token at the beginning (most recent first)
    currentTokens.insert(0, fcmToken);
    
    // Keep only the last 2 tokens to prevent bloat
    if (currentTokens.length > 2) {
      currentTokens.removeRange(2, currentTokens.length);
    }
    
    _currentUser!['fcmTokens'] = currentTokens;
    developer.log('✅ FCM token added: $fcmToken');
    developer.log('📱 Total tokens: ${currentTokens.length}');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(_currentUser);
      await prefs.setString(_currentUserKey, userJson);
      developer.log('✅ FCM token saved successfully in SharedPreferences');
      
      // REMOVED: No longer calling backend
      // await _updateFcmTokenOnBackend(fcmToken);
      
      // ADDED: Update Firestore directly
      await _updateFirestoreFcmToken(fcmToken);
    } catch (e) {
      developer.log('❌ Error saving FCM token to SharedPreferences: $e');
    }
  }

  bool _isValidFCMToken(String token) {
    // Basic FCM token validation
    if (token.isEmpty || token.length < 100) return false;
    
    // FCM tokens typically contain these patterns
    if (token.contains(':') && token.length > 140) {
      return true;
    }
    
    return false;
  }
  
  // NEW: Update Firestore directly with FCM token
  Future<void> _updateFirestoreFcmToken(String fcmToken) async {
    try {
      final userId = currentUserId;
      if (userId == null || userId.isEmpty) {
        developer.log('❌ Cannot update Firestore FCM token - no user ID');
        return;
      }

      developer.log('📤 Updating FCM token in Firestore for user: $userId');
      
      // Update Firestore using FirebaseService
      await FirebaseService.updateUserFCMToken(userId, fcmToken);
      developer.log('✅ FCM token updated in Firestore successfully');
      
    } catch (e) {
      developer.log('❌ Error updating FCM token in Firestore: $e');
    }
  }

   Future<void> initializeOffline() async {
    try {
      developer.log('🔄 Initializing AppData in offline mode...');
      
      // Initialize only offline-capable components
      // Skip any network-dependent initialization like FCM, API calls, etc.
      
      // Initialize shared preferences if you have them
      // await _initializeSharedPreferences();
      
      // Initialize local database if you have one
      // await _initializeLocalDatabase();
      
      // Initialize cached data
      // await _loadCachedUserData();
      
      // Set offline flag
      _isOfflineMode = true;
      
      developer.log('✅ AppData initialized successfully in offline mode');
    } catch (e) {
      developer.log('❌ AppData offline initialization failed: $e');
      rethrow;
    }
  }


    // Add offline mode flag
  bool _isOfflineMode = false;
  bool get isOfflineMode => _isOfflineMode;
  

  String? getMostRecentFcmToken() {
    final tokens = _currentUser?['fcmTokens'] as List<dynamic>?;
    if (tokens == null || tokens.isEmpty) return null;
    
    for (final token in tokens) {
      final tokenStr = token.toString();
      if (_isValidFCMToken(tokenStr)) {
        return tokenStr;
      }
    }
    return null;
  }

  Future<void> refreshFcmToken() async {
    try {
      developer.log('🔄 Refreshing FCM token...');
      
      // Delete the current token to force refresh
      await FirebaseMessaging.instance.deleteToken();
      await Future.delayed(const Duration(seconds: 1));
      
      // Get a new token
      final newToken = await FirebaseMessaging.instance.getToken();
      if (newToken != null) {
        await saveFcmToken(newToken);
        developer.log('✅ FCM token refreshed successfully');
      } else {
        developer.log('❌ Failed to get new FCM token');
      }
    } catch (e) {
      developer.log('❌ Error refreshing FCM token: $e');
    }
  }
Future<void> initializeFcmAfterLogin() async {
  try {
    developer.log('🔥 Initializing FCM after login...');
    
    // Get the current user
    if (_currentUser == null) {
      developer.log('❌ Cannot initialize FCM - no current user');
      return;
    }
    
    // Request permissions
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    developer.log('🔥 FCM Permission status: ${settings.authorizationStatus}');
    
    // The token should already be fresh from login, but verify
    final currentToken = getMostRecentFcmToken();
    if (currentToken != null) {
      developer.log('🔥 Using existing fresh token: ${currentToken.substring(0, 20)}...');
      
      // Subscribe to user topic
      if (currentUserId != null) {
        await FirebaseMessaging.instance.subscribeToTopic('user_$currentUserId');
        developer.log('🔥 Subscribed to topic: user_$currentUserId');
      }
    } else {
      developer.log('⚠️ No fresh token found, getting new one...');
      final newToken = await FirebaseMessaging.instance.getToken();
      if (newToken != null) {
        await saveFcmToken(newToken);
      }
    }


    
    // Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      developer.log('🔄 FCM Token refreshed during session: ${newToken.substring(0, 20)}...');
      await saveFcmToken(newToken);
      
      if (currentUserId != null) {
        await FirebaseMessaging.instance.subscribeToTopic('user_$currentUserId');
      }
    });
    
    // Setup message handlers
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('🔥 Received foreground message: ${message.messageId}');
      NotificationService().handleForegroundMessage(message);
    });
    
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log('🔥 App opened from notification: ${message.messageId}');
      NotificationService().handleForegroundMessage(message);
    });
    
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      developer.log('🔥 App launched from notification: ${initialMessage.messageId}');
      NotificationService().handleForegroundMessage(initialMessage);
    }
    
    developer.log('✅ FCM initialized successfully after login');
  } catch (e) {
    developer.log('❌ Error initializing FCM after login: $e');
  }
}



  // Helper method to update FCM token on the backend
  // Future<void> _updateFcmTokenOnBackend(String fcmToken) async {
  //   try {
  //     final url = Uri.parse('http://182.93.94.210:3066/api/v1/update-fcm-token');
  //     final body = jsonEncode({
  //       'userId': currentUserId,
  //       'fcmToken': fcmToken,
  //     });
  //     final headers = {
  //       'Content-Type': 'application/json',
  //       'Authorization': 'Bearer $_authToken',
  //     };
      
  //     final response = await http.post(url, headers: headers, body: body);
  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       developer.log('FCM token updated on backend');
  //     } else {
  //       developer.log('Failed to update FCM token on backend: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     developer.log('Error updating FCM token on backend: $e');
  //   }
  // }

  Future<void> initializeFcm() async {
    try {
      developer.log('🔥 Initializing FCM...');
      
      // Request permissions
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      developer.log('🔥 FCM Permission status: ${settings.authorizationStatus}');
      
      // Get FCM token
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await saveFcmToken(fcmToken);
        developer.log('🔥 FCM token saved: ${fcmToken.substring(0, 20)}...');
        
        // Subscribe to user topic
        if (currentUserId != null) {
          await FirebaseMessaging.instance.subscribeToTopic('user_$currentUserId');
          developer.log('🔥 Subscribed to topic: user_$currentUserId');
        }
      }
      
      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        await saveFcmToken(newToken);
        developer.log('🔥 FCM token refreshed');
        
        if (currentUserId != null) {
          await FirebaseMessaging.instance.subscribeToTopic('user_$currentUserId');
        }
      });
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        developer.log('🔥 Received foreground message: ${message.messageId}');
        NotificationService().handleForegroundMessage(message);
      });
      
      // Handle messages when app is opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        developer.log('🔥 App opened from notification: ${message.messageId}');
        NotificationService().handleForegroundMessage(message);
      });
      
      // Check for initial message when app is launched from terminated state
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        developer.log('🔥 App launched from notification: ${initialMessage.messageId}');
        NotificationService().handleForegroundMessage(initialMessage);
      }
      
      developer.log('✅ FCM initialized successfully');
    } catch (e) {
      developer.log('❌ Error initializing FCM: $e');
    }
  }
  
  
  bool isCurrentUser(String userId) {
    final currentId = JwtHelper.extractUserId(_authToken);
    final result = currentId != null && currentId == userId;
    developer.log('isCurrentUser check - Current user ID from JWT: ${currentId ?? "null"}, Comparing with: $userId, Result: $result');
    return result;
  }
  
  bool isCurrentUserByEmail(String email) {
    if (_currentUser == null || _currentUser!['email'] == null) {
      developer.log('isCurrentUserByEmail - Current user is null or has no email');
      return false;
    }
    
    final currentEmail = _currentUser!['email'].toString().trim().toLowerCase();
    final compareEmail = email.trim().toLowerCase();
    final result = currentEmail == compareEmail;
    
    developer.log('isCurrentUserByEmail check - Current email: $currentEmail, Comparing with: $compareEmail, Result: $result');
    return result;
  }
  



  bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;
  
 // Enhanced AppData logout method with complete cleanup
Future<void> logout() async {
  try {
    developer.log('🚪 Starting complete logout process...');

    // Step 1: Stop all real-time listeners and clear controller state
    if (Get.isRegistered<FireChatController>()) {
      final chatController = Get.find<FireChatController>();
      await chatController.completeLogout();
    }

    // Step 2: Update user status to offline before clearing data
    if (_currentUser != null && _currentUser!['_id'] != null) {
      try {
        await FirebaseService.updateUserStatus(_currentUser!['_id'], false);
        developer.log('✅ User status updated to offline');
      } catch (e) {
        developer.log('⚠️ Failed to update user status: $e');
      }
    }

    // Step 3: Clear FCM token from backend
    await _clearFcmTokenFromBackend();

    // Step 4: Sign out from Firebase Auth
    await _signOutFromFirebase();

    // Step 5: Clear all local data
    await clearAuthToken();
    await clearCurrentUser();
    
    // Step 6: Clear in-memory state
    _authToken = null;
    _currentUser = null;

    // Step 7: Clear shared preferences completely
    await _clearAllSharedPreferences();

    developer.log('✅ Complete logout successful');
    
    
  } catch (e) {
    developer.log('❌ Error during logout: $e');
    // Force clear even if there were errors
    _authToken = null;
    _currentUser = null;
  }
}

// Clear FCM token from backend
Future<void> _clearFcmTokenFromBackend() async {
  try {
    if (_authToken != null && _currentUser != null) {
      final url = Uri.parse('http://182.93.94.210:3066/api/v1/clear-fcm-token');
      final body = jsonEncode({
        'userId': _currentUser!['_id'],
      });
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_authToken',
      };
      
      final response = await http.post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        developer.log('✅ FCM token cleared from backend');
      } else {
        developer.log('⚠️ Failed to clear FCM token from backend: ${response.statusCode}');
      }
    }
  } catch (e) {
    developer.log('⚠️ Error clearing FCM token from backend: $e');
  }
}

// Sign out from Firebase Auth
Future<void> _signOutFromFirebase() async {
  try {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    developer.log('✅ Signed out from Firebase and Google');
  } catch (e) {
    developer.log('⚠️ Error signing out from Firebase: $e');
  }
}

// Clear all shared preferences
Future<void> _clearAllSharedPreferences() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    developer.log('✅ All SharedPreferences cleared');
  } catch (e) {
    developer.log('❌ Error clearing SharedPreferences: $e');
  }
}

  Future<List<dynamic>> fetchNotifications() async {
  try {
    final url = Uri.parse('http://182.93.94.210:3066/api/v1/notifications');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_authToken',
    };

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      developer.log('Notifications fetched successfully: $data');

      // Show local notifications for new notifications
      for (var notification in data) {
        await NotificationService().showNotification(
          id: notification['_id'] ?? DateTime.now().millisecondsSinceEpoch % 1000,
          title: notification['title'] ?? 'New Notification',
          body: notification['body'] ?? 'You have a new notification!',
          payload: notification.toString(),
        );
      }
      return data as List<dynamic>;
    } else {
      developer.log('Failed to fetch notifications: ${response.statusCode} - ${response.body}');
      return [];
    }
  } catch (e) {
    developer.log('Error fetching notifications: $e');
    return [];
  }
}



Future<BlockedUsersResponse> fetchBlockedUsers({
  int page = 0,
  int limit = 20,
}) async {
  try {
    developer.log('🚫 Fetching blocked users - Page: $page, Limit: $limit');
    
    if (AppData().authToken == null || AppData().authToken!.isEmpty) {
      throw Exception('Authentication required to fetch blocked users');
    }

    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final uri = Uri.parse('http://182.93.94.210:3066/api/v1/blocked-users')
        .replace(queryParameters: queryParams);

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${AppData().authToken}',
    };

    developer.log('🚫 Request URL: $uri');

    final response = await http.get(uri, headers: headers)
        .timeout(const Duration(seconds: 30));

    developer.log('🚫 Response Status: ${response.statusCode}');
    developer.log('🚫 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final blockedUsersResponse = BlockedUsersResponse.fromJson(responseData);
      
      developer.log('✅ Successfully fetched ${blockedUsersResponse.blockedUsers.length} blocked users');
      developer.log('📊 Pagination - Total: ${blockedUsersResponse.pagination.total}, HasMore: ${blockedUsersResponse.pagination.hasMore}');
      
      return blockedUsersResponse;
    } else if (response.statusCode == 401) {
      throw Exception('Authentication failed - please login again');
    } else if (response.statusCode == 404) {
      throw Exception('Blocked users endpoint not found');
    } else {
      final errorData = jsonDecode(response.body);
      final errorMessage = errorData['message'] ?? 'Failed to fetch blocked users';
      throw Exception('Server error (${response.statusCode}): $errorMessage');
    }
  } catch (e) {
    developer.log('❌ Error fetching blocked users: $e');
    
    // Return empty response with error for better error handling
    return BlockedUsersResponse(
      status: 500,
      blockedUsers: [],
      pagination: BlockedUsersPagination.fromJson({}),
      error: e.toString(),
      message: 'Failed to fetch blocked users: ${e.toString()}',
    );
  }
}

// Fetch all blocked users (handles pagination automatically)
Future<List<BlockedUser>> fetchAllBlockedUsers() async {
  try {
    developer.log('🚫 Fetching all blocked users...');
    
    List<BlockedUser> allBlockedUsers = [];
    int currentPage = 0;
    bool hasMore = true;

    while (hasMore) {
      final response = await fetchBlockedUsers(
        page: currentPage,
        limit: 50, // Larger limit for efficiency
      );

      if (response.status == 200) {
        allBlockedUsers.addAll(response.blockedUsers);
        hasMore = response.pagination.hasMore;
        currentPage++;
        
        developer.log('🚫 Fetched page $currentPage, total users so far: ${allBlockedUsers.length}');
      } else {
        developer.log('❌ Error on page $currentPage: ${response.error}');
        break;
      }
    }

    developer.log('✅ Fetched all blocked users - Total: ${allBlockedUsers.length}');
    return allBlockedUsers;
  } catch (e) {
    developer.log('❌ Error fetching all blocked users: $e');
    return [];
  }
}

// Check if a specific user is blocked
Future<bool> isUserBlocked(String userId) async {
  try {
    developer.log('🚫 Checking if user is blocked: $userId');
    
    final response = await fetchBlockedUsers(limit: 100); // Get first 100
    
    if (response.status == 200) {
      final isBlocked = response.blockedUsers.any((user) => user.id == userId);
      developer.log('🚫 User $userId blocked status: $isBlocked');
      return isBlocked;
    }
    
    return false;
  } catch (e) {
    developer.log('❌ Error checking if user is blocked: $e');
    return false;
  }
}

// Get blocked user details by ID
Future<BlockedUser?> getBlockedUserById(String userId) async {
  try {
    developer.log('🚫 Getting blocked user details: $userId');
    
    final response = await fetchBlockedUsers(limit: 100);
    
    if (response.status == 200) {
      final blockedUser = response.blockedUsers
          .where((user) => user.id == userId)
          .firstOrNull;
      
      if (blockedUser != null) {
        developer.log('✅ Found blocked user: ${blockedUser.name}');
      } else {
        developer.log('⚠️ User not found in blocked list: $userId');
      }
      
      return blockedUser;
    }
    
    return null;
  } catch (e) {
    developer.log('❌ Error getting blocked user details: $e');
    return null;
  }
}

// Search blocked users by name or email
Future<List<BlockedUser>> searchBlockedUsers(String query) async {
  try {
    developer.log('🚫 Searching blocked users: $query');
    
    final allUsers = await fetchAllBlockedUsers();
    final searchQuery = query.toLowerCase().trim();
    
    final filteredUsers = allUsers.where((user) {
      return user.name.toLowerCase().contains(searchQuery) ||
             user.email.toLowerCase().contains(searchQuery);
    }).toList();
    
    developer.log('🚫 Found ${filteredUsers.length} users matching "$query"');
    return filteredUsers;
  } catch (e) {
    developer.log('❌ Error searching blocked users: $e');
    return [];
  }
}

// Refresh blocked users cache (useful after blocking/unblocking)
Future<BlockedUsersResponse> refreshBlockedUsers() async {
  try {
    developer.log('🚫 Refreshing blocked users cache...');
    return await fetchBlockedUsers(page: 0, limit: 20);
  } catch (e) {
    developer.log('❌ Error refreshing blocked users: $e');
    rethrow;
  }
}
}