import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:innovator/Authorization/firebase_services.dart';
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/screens/chatApp/FollowStatusManager.dart'
    show FollowStatusManager;
import 'package:innovator/services/Firebase_Messaging.dart';

class FireChatController extends GetxController {
  // Reactive variables
  final RxList<Map<String, dynamic>> allUsers = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> chatList = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> searchResults =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> recentUsers = <Map<String, dynamic>>[].obs;
  final RxMap<String, DateTime> userInteractionTimes = <String, DateTime>{}.obs;

  final RxBool isLoadingUsers = false.obs;
  final RxBool isLoadingChats = false.obs;
  final RxBool isSearching = false.obs;
  final RxBool isLoadingMessages = false.obs;
  final RxBool isSendingMessage = false.obs;
  final RxBool isTyping = false.obs;

  final RxString searchQuery = ''.obs;
  final RxString currentChatId = ''.obs;
  final RxString typingIndicator = ''.obs;

  final Rx<Map<String, dynamic>?> currentUser = Rx<Map<String, dynamic>?>(null);
  final RxString currentUserId = ''.obs;

  // Cache for user data
  final RxMap<String, Map<String, dynamic>> userCache =
      <String, Map<String, dynamic>>{}.obs;
  final RxMap<String, int> unreadCounts = <String, int>{}.obs;
  final RxMap<String, RxInt> badgeCounts = <String, RxInt>{}.obs;

  // Real-time message status tracking
  final RxMap<String, String> messageStatuses = <String, String>{}.obs;
  final RxMap<String, DateTime> lastMessageTimes = <String, DateTime>{}.obs;

  // UI state
  final RxInt selectedBottomIndex = 0.obs;
  final RxBool isDarkMode = false.obs;

  // Animation controllers
  final RxDouble fabScale = 1.0.obs;
  final RxBool showScrollToBottom = false.obs;

  // Stream subscriptions for real-time updates
  final Map<String, Stream<QuerySnapshot>> _activeStreams = {};

  late FollowStatusManager followStatusManager;

  // NEW: Loading states for better UX
  final RxBool isLoadingFollowStatus = false.obs;
  final RxString loadingStatusText = ''.obs;

  final RxBool _usersInitialized = false.obs;
  final RxBool _preventAutoReload = false.obs;

  final RxMap<String, RxInt> chatBadges = <String, RxInt>{}.obs;
  final RxInt totalUnreadBadges = 0.obs;

  @override
  void onInit() {
    super.onInit();

   _initializeFollowStatusManager();
  initializeUser();
  _setupReactiveListeners();
  _startGlobalMessageListener(); // This also needs to use badge handlers
  _initializeNotificationService();
  _loadRecentUsersFromStorage();

  // IMPORTANT: Initialize badge system
  chatBadges.clear();
  totalUnreadBadges.value = 0;
  developer.log('✅ Badge system initialized');
  }

  // Add these methods to your FireChatController class

// Initialize badge for a specific chat
void initializeBadgeForChat(String chatId) {
  if (!chatBadges.containsKey(chatId)) {
    chatBadges[chatId] = 0.obs;
  }
}

// Clear badge for specific chat
void clearBadgeForChat(String chatId) {
  if (chatBadges.containsKey(chatId)) {
    chatBadges[chatId]!.value = 0;
  }
  unreadCounts[chatId] = 0;
  // Update total badges
  updateTotalUnreadBadges();
  developer.log('🟢 Badge cleared for chat: $chatId');
}

// Calculate total unread badges across all chats
void updateTotalUnreadBadges() {
  int total = 0;
  for (final badge in chatBadges.values) {
    total += badge.value;
  }
  totalUnreadBadges.value = total;
  developer.log('📊 Total unread badges: $total');
}

// Animate new badge appearance
void _animateNewBadge(String chatId) {
  // Trigger badge pulse animation
  Future.delayed(const Duration(milliseconds: 100), () {
    // This will be used in UI for badge animation
    developer.log('🔴 New badge animation for chat: $chatId');
  });
}

// Enhanced update unread count with badge system
void _updateUnreadCountWithBadge(String chatId, String otherUserId) {
  if (chatId.isEmpty) return;

  try {
    initializeBadgeForChat(chatId);
    
    // Listen to unread message count
    FirebaseService.getUnreadMessageCount(chatId, currentUserId.value).listen(
      (snapshot) {
        final count = snapshot.docs.length;
        
        // Update local cache
        unreadCounts[chatId] = count;
        
        // Update reactive badge count
        chatBadges[chatId]!.value = count;
        
        // Update total unread badges
        updateTotalUnreadBadges();
        
        // Trigger animation if count increased
        if (count > 0) {
          _animateNewBadge(chatId);
          
          // Force UI refresh
          chatList.refresh();
        }
        
        developer.log('📊 Badge updated for chat $chatId: $count unread messages');
      },
      onError: (error) {
        developer.log('❌ Error updating badge count: $error');
      },
    );
  } catch (e) {
    developer.log('❌ Error updating unread count with badge: $e');
  }
}

// ENHANCED: Handle new incoming message with proper badge management
void _handleNewMessageWithBadge(String chatId, Map<String, dynamic> messageData) {
  try {
    final senderId = messageData['senderId']?.toString() ?? '';
    final isMyMessage = senderId == currentUserId.value;
    
    developer.log('📨 New message - Chat: $chatId, IsMyMessage: $isMyMessage');
    
    // CRITICAL: Process ALL new messages, not just received ones
    if (!isMyMessage) {
      // Initialize badge for this chat if not exists
      initializeBadgeForChat(chatId);
      
      // Check if user is currently viewing this chat
      final isViewingThisChat = currentChatId.value == chatId;
      
      if (!isViewingThisChat) {
        // CRITICAL: Increment badge for unread messages
        final currentBadge = chatBadges[chatId]?.value ?? 0;
        chatBadges[chatId]!.value = currentBadge + 1;
        unreadCounts[chatId] = currentBadge + 1;
        
        developer.log('🔴 NEW UNREAD MESSAGE - Badge incremented for chat $chatId: ${currentBadge + 1}');
        
        // Update total badges
        updateTotalUnreadBadges();
        
        // Animate badge
        _animateNewBadge(chatId);
        
        // Trigger UI refresh
        chatList.refresh();
      } else {
        developer.log('👀 User viewing chat $chatId, auto-marking as read');
        // Auto-mark as read after short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          markMessagesAsRead(chatId);
        });
      }
    }
    
    // ALWAYS move chat to top for any new message
    _moveChatToTopWithAnimation(chatId, messageData);
    
  } catch (e) {
    developer.log('❌ Error handling new message with badge: $e');
  }
}

// ENHANCED: Move chat to top with smooth animation
void _moveChatToTopWithAnimation(String chatId, Map<String, dynamic> messageData) {
  try {
    developer.log('⬆️ Moving chat to top: $chatId');
    
    final chatIndex = chatList.indexWhere((chat) => chat['chatId'] == chatId);
    
    if (chatIndex > 0) {
      // Remove from current position
      final chat = chatList.removeAt(chatIndex);
      
      // Update with latest message data
      chat['lastMessage'] = messageData['message']?.toString() ?? '';
      chat['lastMessageTime'] = messageData['timestamp'];
      chat['lastMessageSender'] = messageData['senderId']?.toString() ?? '';
      chat['lastMessageSenderName'] = messageData['senderName']?.toString() ?? '';
      chat['lastMessageId'] = messageData['id']?.toString() ?? '';
      
      // Insert at top
      chatList.insert(0, chat);
      
      developer.log('✅ Chat moved to top successfully');
      
      // Trigger animation
      _triggerChatMoveAnimation();
      
    } else if (chatIndex == 0) {
      // Already at top, just update data
      final chat = chatList[0];
      chat['lastMessage'] = messageData['message']?.toString() ?? '';
      chat['lastMessageTime'] = messageData['timestamp'];
      chat['lastMessageSender'] = messageData['senderId']?.toString() ?? '';
      chat['lastMessageSenderName'] = messageData['senderName']?.toString() ?? '';
      chat['lastMessageId'] = messageData['id']?.toString() ?? '';
      
      chatList.refresh(); // Trigger UI update
    }
    
  } catch (e) {
    developer.log('❌ Error moving chat to top: $e');
  }
}

// Trigger chat move animation
void _triggerChatMoveAnimation() {
  // This will be used in UI for smooth list reordering animation
  chatList.refresh();
}

// Get badge count for chat (reactive)
RxInt getBadgeCountReactive(String chatId) {
  initializeBadgeForChat(chatId);
  return chatBadges[chatId]!;
}

// Check if chat has unread messages
bool hasUnreadMessages(String chatId) {
  return (chatBadges[chatId]?.value ?? 0) > 0;
}

// Clear all badges (useful for mark all as read)
void clearAllBadges() {
  for (final chatId in chatBadges.keys) {
    clearBadgeForChat(chatId);
  }
  developer.log('🟢 All badges cleared');
}

// Get total unread count across all chats
int getTotalUnreadCount() {
  return totalUnreadBadges.value;
}

  void _initializeFollowStatusManager() {
    try {
      if (!Get.isRegistered<FollowStatusManager>()) {
        Get.put(FollowStatusManager(), permanent: true);
      }
      followStatusManager = Get.find<FollowStatusManager>();
      developer.log('✅ FollowStatusManager initialized in chat controller');
    } catch (e) {
      developer.log('❌ Error initializing FollowStatusManager: $e');
      // Create a fallback if needed
      Get.put(FollowStatusManager(), permanent: true);
      followStatusManager = Get.find<FollowStatusManager>();
    }
  }

  // ENHANCED: Clear badge when messages are read
  @override
Future<void> markMessagesAsRead(String chatId) async {
  if (chatId.isEmpty) return;

  try {
    // Call original Firebase method
    await FirebaseService.markMessagesAsRead(chatId, currentUserId.value);

    // Clear local badge immediately
    clearBadgeForChat(chatId);

    // Update UI immediately
    for (var message in messages) {
      if (message['chatId'] == chatId &&
          message['senderId'] != currentUserId.value) {
        message['isRead'] = true;
      }
    }
    messages.refresh();

    // Clear notification
    try {
      final notificationService = FirebaseNotificationService();
      await notificationService.clearNotification(chatId.hashCode);
    } catch (e) {
      developer.log('Error clearing notification: $e');
    }

    developer.log('✅ Messages marked as read and badge cleared for: $chatId');
  } catch (e) {
    developer.log('❌ Error marking messages as read: $e');
  }
}

  // Get badge count for chat (reactive)

  @override
  void onReady() {
    super.onReady();

    // Initialize with preloading when controller is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeWithPreloading();
    });
  }

  void addUserToRecent(Map<String, dynamic> user) {
    try {
      final userId =
          user['userId']?.toString() ??
          user['_id']?.toString() ??
          user['id']?.toString() ??
          '';

      if (userId.isEmpty) return;

      // Remove user if already exists in recent list
      recentUsers.removeWhere((recentUser) {
        final recentUserId =
            recentUser['userId']?.toString() ??
            recentUser['_id']?.toString() ??
            recentUser['id']?.toString() ??
            '';
        return recentUserId == userId;
      });

      // Add to the beginning of recent users
      recentUsers.insert(0, user);

      // Track interaction time
      userInteractionTimes[userId] = DateTime.now();

      // Keep only last 10 recent users
      if (recentUsers.length > 10) {
        recentUsers.removeRange(10, recentUsers.length);
      }

      developer.log('✅ User added to recent: ${user['name']} ($userId)');

      // Save to local storage or preferences if needed
      _saveRecentUsersToStorage();
    } catch (e) {
      developer.log('❌ Error adding user to recent: $e');
    }
  }

  // NEW: Get users for home page (combines recent + other users)
  List<Map<String, dynamic>> getUsersForHomePage() {
    try {
      final homeUsers = <Map<String, dynamic>>[];
      final addedUserIds = <String>{};

      // First, add recent users
      for (final recentUser in recentUsers) {
        final userId =
            recentUser['userId']?.toString() ??
            recentUser['_id']?.toString() ??
            recentUser['id']?.toString() ??
            '';

        if (userId.isNotEmpty && !addedUserIds.contains(userId)) {
          // Update with latest data from allUsers if available
          final latestUserData = allUsers.firstWhere((user) {
            final uId =
                user['userId']?.toString() ??
                user['_id']?.toString() ??
                user['id']?.toString() ??
                '';
            return uId == userId;
          }, orElse: () => recentUser);

          homeUsers.add(latestUserData);
          addedUserIds.add(userId);
        }
      }

      // Then add other users to fill up to 5 total
      for (final user in allUsers) {
        if (homeUsers.length >= 5) break;

        final userId =
            user['userId']?.toString() ??
            user['_id']?.toString() ??
            user['id']?.toString() ??
            '';

        if (userId.isNotEmpty && !addedUserIds.contains(userId)) {
          homeUsers.add(user);
          addedUserIds.add(userId);
        }
      }

      return homeUsers;
    } catch (e) {
      developer.log('❌ Error getting users for home page: $e');
      return allUsers.take(5).toList();
    }
  }

  // NEW: Save recent users to local storage
  void _saveRecentUsersToStorage() {
    try {
      // You can implement this using SharedPreferences or GetStorage
      // For now, just log
      developer.log('💾 Saving ${recentUsers.length} recent users to storage');
    } catch (e) {
      developer.log('❌ Error saving recent users: $e');
    }
  }

  // NEW: Load recent users from local storage
  void _loadRecentUsersFromStorage() {
    try {
      // You can implement this using SharedPreferences or GetStorage
      // For now, just log
      developer.log('📂 Loading recent users from storage');
    } catch (e) {
      developer.log('❌ Error loading recent users: $e');
    }
  }

  // MODIFIED: Enhanced addUserToChat method

  void _initializeNotificationService() async {
    try {
      final notificationService = FirebaseNotificationService();
      await notificationService.initialize();
      developer.log('✅ Notification service initialized in chat controller');
    } catch (e) {
      developer.log('❌ Error initializing notification service: $e');
    }
  }

  final Map<String, StreamSubscription> _streamSubscriptions = {};

  // ENHANCED: Complete logout with proper cleanup
  Future<void> completeLogout() async {
    try {
      developer.log('💬 Starting chat controller complete logout...');

      // Clear current chat
      clearCurrentChat();

      // Cancel all stream subscriptions
      await _cancelAllStreamSubscriptions();

      // Update user status to offline
      await _updateUserStatusToOffline();

      // Unsubscribe from FCM topics
      await _unsubscribeFromAllTopics();

      // Clear all notifications
      try {
        final notificationService = FirebaseNotificationService();
        await notificationService.clearAllNotifications();
      } catch (e) {
        developer.log('Error clearing notifications: $e');
      }

      // Clear all reactive variables
      _clearAllReactiveVariables();

      // Reset controller state
      _resetControllerState();

      developer.log('✅ Chat controller logout completed');
    } catch (e) {
      developer.log('❌ Error during chat controller logout: $e');
      _clearAllReactiveVariables();
      _resetControllerState();
    }
  }

  Future<void> subscribeToNotificationTopics() async {
    if (currentUserId.value.isEmpty) return;

    try {
      final notificationService = FirebaseNotificationService();

      // Subscribe to user-specific topics
      await notificationService.subscribeToTopic('user_${currentUserId.value}');
      await notificationService.subscribeToTopic('chat_${currentUserId.value}');

      // Subscribe to general topics
      await notificationService.subscribeToTopic('chat_notifications');
      await notificationService.subscribeToTopic('general_notifications');

      developer.log(
        '✅ Subscribed to notification topics for: ${currentUserId.value}',
      );
    } catch (e) {
      developer.log('❌ Error subscribing to notification topics: $e');
    }
  }

  // Unsubscribe from notification topics
  Future<void> _unsubscribeFromAllTopics() async {
    try {
      developer.log('📢 Unsubscribing from all FCM topics...');

      final notificationService = FirebaseNotificationService();
      final userId = currentUserId.value;

      if (userId.isNotEmpty) {
        await notificationService.unsubscribeFromTopic('user_$userId');
        await notificationService.unsubscribeFromTopic('chat_$userId');
      }

      await notificationService.unsubscribeFromTopic('chat_notifications');
      await notificationService.unsubscribeFromTopic('general_notifications');

      developer.log('✅ Unsubscribed from all FCM topics');
    } catch (e) {
      developer.log('❌ Error unsubscribing from FCM topics: $e');
    }
  }

  // Cancel all active stream subscriptions
  Future<void> _cancelAllStreamSubscriptions() async {
    try {
      developer.log('🔄 Canceling all stream subscriptions...');

      for (final subscription in _streamSubscriptions.values) {
        await subscription.cancel();
      }
      _streamSubscriptions.clear();

      developer.log('✅ All stream subscriptions canceled');
    } catch (e) {
      developer.log('❌ Error canceling stream subscriptions: $e');
    }
  }

  // Update user status to offline
  Future<void> _updateUserStatusToOffline() async {
    try {
      final userId = currentUserId.value;
      if (userId.isNotEmpty) {
        await FirebaseService.updateUserStatus(userId, false);
        developer.log('✅ User status set to offline: $userId');
      }
    } catch (e) {
      developer.log('❌ Error updating user status to offline: $e');
    }
  }

  // Unsubscribe from all FCM topics

  // Clear all reactive variables
  // Add these methods to your FireChatController:

  // Immediate stream cancellation to prevent permission errors
  Future<void> cancelAllStreamSubscriptionsImmediate() async {
    try {
      developer.log('🔄 Immediately canceling all stream subscriptions...');

      // Cancel all active stream subscriptions
      for (final subscription in _streamSubscriptions.values) {
        try {
          await subscription.cancel();
        } catch (e) {
          developer.log('Error canceling individual subscription: $e');
        }
      }
      _streamSubscriptions.clear();

      // Clear active streams map
      _activeStreams.clear();

      developer.log('✅ All stream subscriptions canceled immediately');
    } catch (e) {
      developer.log('❌ Error in immediate stream cancellation: $e');
    }
  }

  // Modified complete logout for after Firebase signout
  Future<void> completeLogoutAfterSignout() async {
    try {
      developer.log(
        '💬 Completing chat controller logout after Firebase signout...',
      );

      // Step 1: Unsubscribe from FCM topics (may fail, that's ok)
      await _unsubscribeFromAllTopicsSafely();

      // Step 2: Clear all reactive variables
      _clearAllReactiveVariables();

      // Step 3: Reset controller state
      _resetControllerState();

      developer.log('✅ Chat controller logout after signout completed');
    } catch (e) {
      developer.log('❌ Error during chat controller logout after signout: $e');
      // Force clear even if there are errors
      _clearAllReactiveVariables();
      _resetControllerState();
    }
  }

  // Safe FCM topic unsubscription (won't throw errors)
  Future<void> _unsubscribeFromAllTopicsSafely() async {
    try {
      developer.log('📢 Safely unsubscribing from FCM topics...');

      final userId = currentUserId.value;
      if (userId.isNotEmpty) {
        // These may fail after Firebase signout, but that's expected
        try {
          await FirebaseMessaging.instance
              .unsubscribeFromTopic('user_$userId')
              .timeout(const Duration(seconds: 2));
        } catch (e) {
          developer.log('FCM unsubscribe user topic failed (expected): $e');
        }

        try {
          await FirebaseMessaging.instance
              .unsubscribeFromTopic('chat_$userId')
              .timeout(const Duration(seconds: 2));
        } catch (e) {
          developer.log('FCM unsubscribe chat topic failed (expected): $e');
        }
      }

      try {
        await FirebaseMessaging.instance
            .unsubscribeFromTopic('chat_notifications')
            .timeout(const Duration(seconds: 2));
      } catch (e) {
        developer.log('FCM unsubscribe general topic failed (expected): $e');
      }

      developer.log(
        '✅ FCM topic unsubscription completed (with expected failures)',
      );
    } catch (e) {
      developer.log('❌ Error in safe FCM unsubscription: $e');
    }
  }

  Future<void> loadAllUsersWithFollowFilter() async {
    if (isLoadingUsers.value) return;

    isLoadingUsers.value = true;
    try {
      developer.log('📱 Loading users with follow status filter...');

      // Get filtered users from API
      final filteredUsers =
          await FirebaseService.getFilteredUsersWithFollowStatus();

      // Filter out current user
      final currentUserId = getCurrentUserId();
      final finalUsers =
          filteredUsers.where((user) {
            final userId =
                user['userId']?.toString() ??
                user['_id']?.toString() ??
                user['id']?.toString() ??
                '';
            return userId != currentUserId;
          }).toList();

      // Update cache and reactive list
      for (final user in finalUsers) {
        final userId =
            user['userId']?.toString() ??
            user['_id']?.toString() ??
            user['id']?.toString() ??
            '';
        if (userId.isNotEmpty) {
          userCache[userId] = user;
        }
      }

      allUsers.assignAll(finalUsers);

      developer.log('✅ Loaded ${finalUsers.length} mutual followers');
    } catch (e) {
      developer.log('❌ Error loading users with follow filter: $e');
      // Get.snackbar(
      //   'Error',
      //   'Failed to load users. Please try again.',
      //   snackPosition: SnackPosition.BOTTOM,
      //   backgroundColor: Colors.red.withOpacity(0.8),
      //   colorText: Colors.white,
      // );
    } finally {
      isLoadingUsers.value = false;
    }
  }

  // NEW: Enhanced search users with follow status
  Future<void> searchUsersWithFollowFilter(String query) async {
    if (query.trim().isEmpty) {
      searchResults.clear();
      return;
    }

    isSearching.value = true;
    try {
      developer.log('🔍 Searching users with follow filter: $query');

      // Get all filtered users first
      final filteredUsers =
          await FirebaseService.getFilteredUsersWithFollowStatus();

      // Filter by search query
      final queryLower = query.toLowerCase();
      final searchedUsers =
          filteredUsers.where((user) {
            final name = user['name']?.toString().toLowerCase() ?? '';
            final email = user['email']?.toString().toLowerCase() ?? '';
            return name.contains(queryLower) || email.contains(queryLower);
          }).toList();

      // Filter out current user
      final currentUserId = getCurrentUserId();
      final finalResults =
          searchedUsers.where((user) {
            final userId =
                user['userId']?.toString() ??
                user['_id']?.toString() ??
                user['id']?.toString() ??
                '';
            return userId != currentUserId;
          }).toList();

      searchResults.assignAll(finalResults);

      developer.log(
        '✅ Search returned ${finalResults.length} mutual followers',
      );
    } catch (e) {
      developer.log('❌ Error searching users with follow filter: $e');
      Get.snackbar(
        'Error',
        'Failed to search users',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isSearching.value = false;
    }
  }

  // NEW: Enhanced load user chats with API profile data
  Future<void> loadUserChatsWithEnhancedProfiles() async {
    if (isLoadingChats.value || currentUserId.value.isEmpty) return;

    isLoadingChats.value = true;
    try {
      developer.log('💬 Loading chats with enhanced profiles...');

      FirebaseService.getUserChats(currentUserId.value).listen((
        snapshot,
      ) async {
        final chats = <Map<String, dynamic>>[];

        for (var doc in snapshot.docs) {
          final chatData = Map<String, dynamic>.from(
            doc.data() as Map<String, dynamic>,
          );
          chatData['id'] = doc.id;

          final participants = List<String>.from(
            chatData['participants'] ?? [],
          );
          final otherUserId = participants.firstWhere(
            (id) => id != currentUserId.value,
            orElse: () => '',
          );

          if (otherUserId.isNotEmpty) {
            // Get enhanced user profile with API data
            Map<String, dynamic>? otherUser =
                await FirebaseService.getEnhancedUserProfile(otherUserId);

            // Only include chats with mutual followers
            if (otherUser != null && otherUser['isMutualFollow'] == true) {
              // Ensure proper ID mapping
              otherUser['id'] = otherUserId;
              otherUser['userId'] = otherUserId;
              if (!otherUser.containsKey('_id')) {
                otherUser['_id'] = otherUserId;
              }

              chatData['otherUser'] = otherUser;
              chats.add(chatData);

              final chatId = chatData['chatId'] ?? '';
              _updateUnreadCount(chatId, otherUserId);

              if (!badgeCounts.containsKey(chatId)) {
                badgeCounts[chatId] = 0.obs;
              }

              // Update user cache
              userCache[otherUserId] = otherUser;
            }
          }
        }

        // Sort chats by last message time (newest first)
        chats.sort((a, b) {
          final aTime = a['lastMessageTime'] as Timestamp?;
          final bTime = b['lastMessageTime'] as Timestamp?;

          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;

          return bTime.compareTo(aTime);
        });

        chatList.assignAll(chats);
        isLoadingChats.value = false;
        developer.log('✅ Loaded ${chats.length} chats with mutual followers');
      });
    } catch (e) {
      isLoadingChats.value = false;
      developer.log('❌ Error loading chats with enhanced profiles: $e');
    }
  }

  // NEW: Get profile picture URL with fallback
  String? getProfilePictureUrl(Map<String, dynamic>? user) {
    if (user == null) return null;

    // First try API picture URL
    final apiPictureUrl = user['apiPictureUrl']?.toString();
    if (apiPictureUrl != null && apiPictureUrl.isNotEmpty) {
      return apiPictureUrl;
    }

    // Fallback to picture field with base URL
    final picture = user['picture']?.toString();
    if (picture != null && picture.isNotEmpty) {
      if (picture.startsWith('http')) {
        return picture;
      } else {
        return 'http://182.93.94.210:3066$picture';
      }
    }

    // Fallback to photoURL (existing Firestore field)
    final photoURL = user['photoURL']?.toString();
    if (photoURL != null && photoURL.isNotEmpty) {
      return photoURL;
    }

    return null;
  }

  // Enhanced clear reactive variables with error handling
  // Replace your _clearAllReactiveVariables method with this updated version:

void _clearAllReactiveVariables() {
  try {
    developer.log('🧹 Clearing all reactive variables...');

    // Reset initialization flags
    _usersInitialized.value = false;
    _preventAutoReload.value = false;

    // Clear user data
    try {
      currentUser.value = null;
      currentUserId.value = '';
    } catch (e) {
      developer.log('Error clearing user data: $e');
    }

    // Clear lists
    try {
      allUsers.clear();
      chatList.clear();
      searchResults.clear();
      messages.clear();
      recentUsers.clear();
    } catch (e) {
      developer.log('Error clearing lists: $e');
    }

    // Clear maps and badges
    try {
      userCache.clear();
      unreadCounts.clear();
      badgeCounts.clear();
      messageStatuses.clear();
      lastMessageTimes.clear();
      userInteractionTimes.clear();
      
      // IMPORTANT: Clear badge system
      chatBadges.clear();
      totalUnreadBadges.value = 0;
    } catch (e) {
      developer.log('Error clearing maps and badges: $e');
    }

    // Reset search and states
    try {
      searchQuery.value = '';
      isLoadingUsers.value = false;
      isLoadingChats.value = false;
      isSearching.value = false;
      isLoadingMessages.value = false;
      isSendingMessage.value = false;
      isTyping.value = false;
      selectedBottomIndex.value = 0;
      currentChatId.value = '';
      typingIndicator.value = '';
      showScrollToBottom.value = false;
      fabScale.value = 1.0;
    } catch (e) {
      developer.log('Error resetting states: $e');
    }

    developer.log('✅ All reactive variables and badges cleared');
  } catch (e) {
    developer.log('❌ Error clearing reactive variables: $e');
  }
}

  // Reset controller state
  void _resetControllerState() {
    try {
      developer.log('🔄 Resetting controller state...');

      // Clear active streams
      _activeStreams.clear();

      developer.log('✅ Controller state reset');
    } catch (e) {
      developer.log('❌ Error resetting controller state: $e');
    }
  }

  // ENHANCED: Initialize user with proper stream management
  void initializeUser() {
    try {
      final userData = AppData().currentUser;
      if (userData != null && userData.isNotEmpty) {
        currentUser.value = Map<String, dynamic>.from(userData);
        currentUserId.value =
            userData['_id']?.toString() ??
            userData['uid']?.toString() ??
            userData['userId']?.toString() ??
            '';
        developer.log(
          'ChatController initialized with user: ${currentUserId.value}',
        );

        if (currentUserId.value.isNotEmpty) {
          updateUserStatus(true);

          _verifyUserInFirestore().then((_) {
            _setupManagedStreams(); // Use managed streams
          });
        }
      } else {
        developer.log('No current user data available');
        currentUser.value = null;
        currentUserId.value = '';
      }
    } catch (e) {
      developer.log('Error initializing user: $e');
      currentUser.value = null;
      currentUserId.value = '';
    }
  }

  // Setup managed streams with proper cleanup
  void _setupManagedStreams() {
  try {
    developer.log('📡 Setting up managed streams...');
    _cancelAllStreamSubscriptions();

    if (currentUserId.value.isEmpty) return;

    // Users stream
    _streamSubscriptions['users'] = FirebaseService.getAllUsers().listen(
      (snapshot) {
        if (!_usersInitialized.value) {
          _handleUsersUpdate(snapshot);
        }
      },
    );

    // FIXED: Use badge handler for chats
    _streamSubscriptions['chats'] = FirebaseService.getUserChats(
      currentUserId.value,
    ).listen(
      (snapshot) {
        _handleChatsUpdateWithBadges(snapshot); // ✅ CORRECT
      },
    );

    // FIXED: Use badge handler for messages
    _streamSubscriptions['messages'] = FirebaseFirestore.instance
        .collection('messages')
        .where('participants', arrayContains: currentUserId.value)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _handleGlobalMessagesUpdateWithBadges(snapshot); // ✅ CORRECT
          },
        );

    developer.log('✅ Managed streams setup completed');
  } catch (e) {
    developer.log('❌ Error setting up managed streams: $e');
  }
}

  // Handle users update
  void _handleUsersUpdate(QuerySnapshot snapshot) {
    try {
      // IMPORTANT: Only process if we haven't filtered users yet
      if (_usersInitialized.value) {
        developer.log(
          '🔒 Users already filtered, skipping Firestore users update',
        );
        return;
      }

      final users = <Map<String, dynamic>>[];
      for (var doc in snapshot.docs) {
        if (doc.id != currentUserId.value) {
          final userData = Map<String, dynamic>.from(
            doc.data() as Map<String, dynamic>,
          );
          userData['id'] = doc.id;
          userData['userId'] = doc.id;
          if (!userData.containsKey('_id')) {
            userData['_id'] = doc.id;
          }
          if (!userData.containsKey('uid')) {
            userData['uid'] = doc.id;
          }
          users.add(userData);
          userCache[doc.id] = userData;
        }
      }

      // Only update if we don't have filtered users yet
      if (allUsers.isEmpty) {
        allUsers.assignAll(users);
        developer.log('📱 Initial users loaded: ${users.length}');
      }

      isLoadingUsers.value = false;
    } catch (e) {
      developer.log('❌ Error handling users update: $e');
    }
  }

  // Handle chats update
  void _handleChatsUpdate(QuerySnapshot snapshot) async {
    try {
      final chats = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final chatData = Map<String, dynamic>.from(
          doc.data() as Map<String, dynamic>,
        );
        chatData['id'] = doc.id;

        final participants = List<String>.from(chatData['participants'] ?? []);
        final otherUserId = participants.firstWhere(
          (id) => id != currentUserId.value,
          orElse: () => '',
        );

        if (otherUserId.isNotEmpty) {
          Map<String, dynamic>? otherUser = userCache[otherUserId];
          if (otherUser == null) {
            try {
              final userDoc = await FirebaseService.getUserById(otherUserId);
              if (userDoc.exists) {
                otherUser = Map<String, dynamic>.from(
                  userDoc.data() as Map<String, dynamic>,
                );
                otherUser['id'] = otherUserId;
                otherUser['userId'] = otherUserId;
                if (!otherUser.containsKey('_id')) {
                  otherUser['_id'] = otherUserId;
                }
                userCache[otherUserId] = otherUser;
              }
            } catch (e) {
              developer.log('Error loading user $otherUserId: $e');
              continue;
            }
          }

          if (otherUser != null) {
            chatData['otherUser'] = otherUser;
            chats.add(chatData);

            final chatId = chatData['chatId'] ?? '';
            _updateUnreadCount(chatId, otherUserId);

            if (!badgeCounts.containsKey(chatId)) {
              badgeCounts[chatId] = 0.obs;
            }
          }
        }
      }

      // Sort chats by last message time
      chats.sort((a, b) {
        final aTime = a['lastMessageTime'] as Timestamp?;
        final bTime = b['lastMessageTime'] as Timestamp?;

        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;

        return bTime.compareTo(aTime);
      });

      chatList.assignAll(chats);
      isLoadingChats.value = false;
      developer.log('💬 Updated ${chats.length} chats');
    } catch (e) {
      developer.log('❌ Error handling chats update: $e');
    }
  }

  // Handle global messages update
  void _handleGlobalMessagesUpdate(QuerySnapshot snapshot) {
    try {
      for (var change in snapshot.docChanges) {
        final messageData = change.doc.data() as Map<String, dynamic>?;
        if (messageData == null) continue;

        final chatId = messageData['chatId']?.toString() ?? '';
        final senderId = messageData['senderId']?.toString() ?? '';
        final isMyMessage = senderId == currentUserId.value;

        switch (change.type) {
          case DocumentChangeType.added:
            if (!isMyMessage) {
              _handleNewMessage(chatId, messageData);
            }
            break;
          case DocumentChangeType.modified:
            _handleMessageUpdate(change.doc.id, messageData);
            break;
          default:
            break;
        }
      }
    } catch (e) {
      developer.log('❌ Error handling global messages update: $e');
    }
  }

  // ADDED: Verify current user exists in Firestore
  Future<void> _verifyUserInFirestore() async {
    try {
      if (currentUserId.value.isEmpty || currentUser.value == null) return;

      await FirebaseService.verifyAndCreateUser(
        userId: currentUserId.value,
        name: currentUser.value!['name']?.toString() ?? 'User',
        email: currentUser.value!['email']?.toString() ?? '',
        phone: currentUser.value!['phone']?.toString(),
        dob: currentUser.value!['dob']?.toString(),
        photoURL: currentUser.value!['photoURL']?.toString(),
        provider: currentUser.value!['provider']?.toString() ?? 'email',
      );
    } catch (e) {
      developer.log('Error verifying user in Firestore: $e');
    }
  }

  void _setupReactiveListeners() {
    // Listen to search query changes with debouncing
    ever(searchQuery, (String query) {
      if (query.isEmpty) {
        searchResults.clear();
      } else {
        _debounceSearch(query);
      }
    });

    // Listen to current chat changes
    ever(currentChatId, (String chatId) {
      if (chatId.isNotEmpty) {
        loadMessages(chatId);
        markMessagesAsRead(chatId);
      }
    });
  }

  // Global message listener for real-time updates
  void _startGlobalMessageListener() {
  if (currentUserId.value.isEmpty) return;

  try {
    FirebaseFirestore.instance
        .collection('messages')
        .where('participants', arrayContains: currentUserId.value)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            final messageData = change.doc.data() as Map<String, dynamic>?;
            if (messageData == null) continue;

            final chatId = messageData['chatId']?.toString() ?? '';
            final senderId = messageData['senderId']?.toString() ?? '';
            final isMyMessage = senderId == currentUserId.value;

            // Add message ID to data
            messageData['id'] = change.doc.id;

            switch (change.type) {
              case DocumentChangeType.added:
                // FIXED: Use badge handler for new messages
                _handleNewMessageWithBadge(chatId, messageData); // ✅ Use badge handler
                break;
              case DocumentChangeType.modified:
                _handleMessageUpdate(change.doc.id, messageData);
                break;
              default:
                break;
            }
          }
        });
  } catch (e) {
    developer.log('Error setting up global message listener: $e');
  }
}

  // Handle new incoming messages
  void _handleNewMessage(String chatId, Map<String, dynamic> messageData) {
    // Update chat list position (move to top)
    _moveChatToTop(chatId);

    // Update unread count
    if (currentChatId.value != chatId) {
      final currentCount = unreadCounts[chatId] ?? 0;
      unreadCounts[chatId] = currentCount + 1;

      // Update badge count
      if (!badgeCounts.containsKey(chatId)) {
        badgeCounts[chatId] = 0.obs;
      }
      badgeCounts[chatId]!.value = unreadCounts[chatId] ?? 0;

      // Show notification badge animation
      _animateBadge(chatId);
    }

    // Update last message time
    final timestamp = messageData['timestamp'] as Timestamp?;
    if (timestamp != null) {
      lastMessageTimes[chatId] = timestamp.toDate();
    }
  }

  // Handle message status updates (read receipts)
  void _handleMessageUpdate(
    String messageId,
    Map<String, dynamic> messageData,
  ) {
    final isRead = messageData['isRead'] ?? false;
    final senderId = messageData['senderId']?.toString() ?? '';

    // Update message status for blue tick
    if (senderId == currentUserId.value) {
      messageStatuses[messageId] = isRead ? 'read' : 'delivered';

      // Update message in current chat if viewing
      final messageIndex = messages.indexWhere((msg) => msg['id'] == messageId);
      if (messageIndex != -1) {
        messages[messageIndex]['isRead'] = isRead;
        messages.refresh(); // Trigger UI update
      }
    }
  }

  // Move chat to top of list
  void _moveChatToTop(String chatId) {
    final chatIndex = chatList.indexWhere((chat) => chat['chatId'] == chatId);
    if (chatIndex > 0) {
      final chat = chatList.removeAt(chatIndex);
      chatList.insert(0, chat);
    }
  }

  // Animate badge for new messages
  void _animateBadge(String chatId) {
    // Trigger badge animation (can be used in UI)
    Future.delayed(const Duration(milliseconds: 100), () {
      // Badge animation logic
    });
  }

  // Debounced search to prevent excessive API calls
  void _debounceSearch(String query) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (searchQuery.value == query) {
        searchUsers(query);
      }
    });
  }

  // User Management
  Future<void> updateUserStatus(bool isOnline) async {
    try {
      if (currentUserId.value.isNotEmpty) {
        await FirebaseService.updateUserStatus(currentUserId.value, isOnline);
      }
    } catch (e) {
      developer.log('Error updating user status: $e');
    }
  }

  // ENHANCED: Load all users with better caching and ID handling

  // ENHANCED: Load user chats with real-time updates and sorting

  void _updateUnreadCount(String chatId, String otherUserId) {
    if (chatId.isEmpty) return;

    try {
      FirebaseService.getUnreadMessageCount(chatId, currentUserId.value).listen(
        (snapshot) {
          final count = snapshot.docs.length;
          unreadCounts[chatId] = count;

          // Update badge count
          if (!badgeCounts.containsKey(chatId)) {
            badgeCounts[chatId] = 0.obs;
          }
          badgeCounts[chatId]!.value = count;
        },
      );
    } catch (e) {
      developer.log('Error updating unread count: $e');
    }
  }

  // ENHANCED: Search users with better error handling and caching

  // ENHANCED: Load messages with instant read receipt updates
  void loadMessages(String chatId) {
    if (chatId.isEmpty) return;

    currentChatId.value = chatId;
    isLoadingMessages.value = true;

    // Update current chat for notification suppression
    if (currentUserId.value.isNotEmpty) {
      FirebaseService.updateCurrentChat(currentUserId.value, chatId);
    }

    try {
      FirebaseService.getMessages(chatId).listen((snapshot) {
        final messageList = <Map<String, dynamic>>[];

        for (var doc in snapshot.docs) {
          final messageData = Map<String, dynamic>.from(
            doc.data() as Map<String, dynamic>,
          );
          messageData['id'] = doc.id;

          // Track message status for blue tick
          final senderId = messageData['senderId']?.toString() ?? '';
          if (senderId == currentUserId.value) {
            final isRead = messageData['isRead'] ?? false;
            messageStatuses[doc.id] = isRead ? 'read' : 'delivered';
          }

          messageList.add(messageData);
        }

        messages.assignAll(messageList);
        isLoadingMessages.value = false;

        if (messageList.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 100), () {
            scrollToBottom();
          });
        }
      });
    } catch (e) {
      isLoadingMessages.value = false;
      developer.log('Error loading messages: $e');
    }
  }

  // Add these methods to your FireChatController class

  // NEW: Check if user is already in chat list
  bool isUserInChatList(Map<String, dynamic> user) {
    final userId =
        user['userId']?.toString() ??
        user['_id']?.toString() ??
        user['id']?.toString() ??
        '';

    if (userId.isEmpty) return false;

    return chatList.any((chat) {
      final otherUser = chat['otherUser'] as Map<String, dynamic>?;
      if (otherUser == null) return false;

      final otherUserId =
          otherUser['userId']?.toString() ??
          otherUser['_id']?.toString() ??
          otherUser['id']?.toString() ??
          '';

      return otherUserId == userId;
    });
  }

  // NEW: Add user to chat list by creating initial chat document
  @override
  Future<void> addUserToChat(Map<String, dynamic> user) async {
    try {
      // Check if user is mutual follower
      if (!isMutualFollower(user)) {
        Get.snackbar(
          'Cannot Add User',
          'You can only add users you mutually follow to chat',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      final currentUserId = getCurrentUserId();
      final receiverId =
          user['userId']?.toString() ??
          user['_id']?.toString() ??
          user['id']?.toString() ??
          '';

      if (currentUserId.isEmpty || receiverId.isEmpty) {
        throw Exception('Invalid user IDs');
      }

      // Check if chat already exists
      if (isUserInChatList(user)) {
        developer.log('User already in chat list: ${user['name']}');
        addUserToRecent(user);
        return;
      }

      final chatId = generateChatId(currentUserId, receiverId);

      // Create initial chat document
      await FirebaseService.createInitialChat(
        chatId: chatId,
        currentUserId: currentUserId,
        receiverId: receiverId,
        receiverName: user['name']?.toString() ?? 'Unknown User',
      );

      // Add to recent users
      addUserToRecent(user);

      developer.log('✅ User added to chat and recent: ${user['name']}');

      // Refresh chat list to show the new chat
      await loadUserChats();
    } catch (e) {
      developer.log('❌ Error adding user to chat: $e');
      Get.snackbar(
        'Error',
        'Failed to add user to chat. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      rethrow;
    }
  }

  // NEW: Get users not in chat list
  List<Map<String, dynamic>> getUsersNotInChat() {
    return allUsers.where((user) => !isUserInChatList(user)).toList();
  }

  // NEW: Get online users count
  int getOnlineUsersCount() {
    return allUsers.where((user) => user['isOnline'] == true).length;
  }

  // NEW: Get users sorted by online status
  List<Map<String, dynamic>> getUsersSortedByStatus() {
    final users = List<Map<String, dynamic>>.from(allUsers);
    users.sort((a, b) {
      final aOnline = a['isOnline'] == true;
      final bOnline = b['isOnline'] == true;

      if (aOnline && !bOnline) return -1;
      if (!aOnline && bOnline) return 1;

      // If both have same online status, sort by name
      final aName = a['name']?.toString() ?? '';
      final bName = b['name']?.toString() ?? '';
      return aName.compareTo(bName);
    });

    return users;
  }

  // NEW: Enhanced navigation to chat with better error handling
  void navigateToChatEnhanced(Map<String, dynamic> user) {
    try {
      final userForNavigation = Map<String, dynamic>.from(user);

      // Ensure all necessary ID fields are present
      final userId =
          user['userId']?.toString() ??
          user['_id']?.toString() ??
          user['id']?.toString() ??
          '';

      if (userId.isEmpty) {
        throw Exception('Invalid user ID');
      }

      // Standardize ID fields
      userForNavigation['userId'] = userId;
      userForNavigation['_id'] = userId;
      userForNavigation['id'] = userId;

      // Add to recent users when navigating to chat
      addUserToRecent(userForNavigation);

      developer.log(
        'Navigating to chat with user: $userId (${userForNavigation['name']})',
      );

      Get.toNamed(
        '/chat',
        arguments: {
          'receiverUser': userForNavigation,
          'currentUser': currentUser.value,
        },
      );
    } catch (e) {
      developer.log('❌ Error navigating to chat: $e');
      Get.snackbar(
        'Error',
        'Unable to open chat. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  // NEW: Get chat statistics
  Map<String, int> getChatStatistics() {
    return {
      'totalUsers': allUsers.length,
      'onlineUsers': getOnlineUsersCount(),
      'activeChats': chatList.length,
      'unreadChats':
          chatList.where((chat) {
            final chatId = chat['chatId']?.toString() ?? '';
            return (unreadCounts[chatId] ?? 0) > 0;
          }).length,
      'totalUnreadMessages': unreadCounts.values.fold(
        0,
        (sum, count) => sum + count,
      ),
    };
  }

  // NEW: Search users in add to chat screen
  Future<void> searchUsersInAddScreen(String query) async {
    if (query.trim().isEmpty) {
      // Reset to show all users
      await loadAllUsers();
      return;
    }

    isSearching.value = true;
    try {
      final results = await FirebaseService.searchUsers(query.trim());
      final users = <Map<String, dynamic>>[];

      for (var doc in results.docs) {
        if (doc.id != currentUserId.value) {
          final userData = Map<String, dynamic>.from(
            doc.data() as Map<String, dynamic>,
          );

          // Ensure proper ID mapping
          userData['id'] = doc.id;
          userData['userId'] = doc.id;
          if (!userData.containsKey('_id')) {
            userData['_id'] = doc.id;
          }
          if (!userData.containsKey('uid')) {
            userData['uid'] = doc.id;
          }

          users.add(userData);
          userCache[doc.id] = userData;
        }
      }

      allUsers.assignAll(users);
      developer.log(
        'Search in add screen for "$query" returned ${users.length} results',
      );
    } catch (e) {
      developer.log('Error searching users in add screen: $e');
      Get.snackbar(
        'Error',
        'Failed to search users',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isSearching.value = false;
    }
  }

  // ENHANCED: Send message with proper user validation and instant status updates
  @override
  Future<void> sendMessage({
    required String receiverId,
    required String message,
    String? replyToId,
  }) async {
    if (message.trim().isEmpty || currentUserId.value.isEmpty) return;

    // Validate receiver exists
    Map<String, dynamic>? receiverUser = userCache[receiverId];
    if (receiverUser == null) {
      try {
        final receiverDoc = await FirebaseService.getUserById(receiverId);
        if (receiverDoc.exists) {
          receiverUser = Map<String, dynamic>.from(
            receiverDoc.data() as Map<String, dynamic>,
          );
          receiverUser['id'] = receiverId;
          receiverUser['userId'] = receiverId;
          if (!receiverUser.containsKey('_id')) {
            receiverUser['_id'] = receiverId;
          }
          userCache[receiverId] = receiverUser;
        } else {
          developer.log('Error: Receiver user not found: $receiverId');
          Get.snackbar(
            'Error',
            'Recipient user not found. Please try again.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withOpacity(0.8),
            colorText: Colors.white,
          );
          return;
        }
      } catch (e) {
        developer.log('Error validating receiver: $e');
        Get.snackbar(
          'Error',
          'Failed to validate recipient. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
        return;
      }
    }

    final chatId = FirebaseService.generateChatId(
      currentUserId.value,
      receiverId,
    );
    final tempMessageId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    // Optimistic update
    final tempMessage = {
      'id': tempMessageId,
      'chatId': chatId,
      'senderId': currentUserId.value,
      'receiverId': receiverId,
      'message': message.trim(),
      'senderName': currentUser.value?['name']?.toString() ?? 'User',
      'timestamp': Timestamp.now(),
      'isRead': false,
      'messageType': 'text',
      'isSending': true,
    };

    messages.insert(0, tempMessage);
    messageStatuses[tempMessageId] = 'sending';

    // IMMEDIATELY move chat to top when I send a message
    _moveChatToTopWhenSending(chatId, tempMessage);

    isSendingMessage.value = true;

    try {
      // Send message to Firebase
      final sentMessageRef = await FirebaseService.sendMessage(
        chatId: chatId,
        senderId: currentUserId.value,
        receiverId: receiverId,
        message: message.trim(),
        senderName: currentUser.value?['name']?.toString() ?? 'User',
      );

      // Update message status
      messageStatuses[tempMessageId] = 'delivered';

      // Remove temp message (real one will come through stream)
      messages.removeWhere((msg) => msg['id'] == tempMessageId);

      // Move chat to top again after successful send
      _moveChatToTopAfterSending(chatId);

      animateFab();

      developer.log('Message sent successfully: ${sentMessageRef.id}');
    } catch (e) {
      // Remove failed message
      messages.removeWhere((msg) => msg['id'] == tempMessageId);
      messageStatuses.remove(tempMessageId);

      developer.log('Error sending message: $e');

      String errorMessage = 'Failed to send message';
      if (e.toString().contains('not found')) {
        errorMessage = 'Recipient not found. They may need to sign up first.';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Permission denied. Please check your connection.';
      }

      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isSendingMessage.value = false;
    }
  }

  void _moveChatToTopWhenSending(
    String chatId,
    Map<String, dynamic> messageData,
  ) {
    try {
      final chatIndex = chatList.indexWhere((chat) => chat['chatId'] == chatId);

      if (chatIndex > 0) {
        final chat = chatList.removeAt(chatIndex);

        // Update with my message
        chat['lastMessage'] = messageData['message']?.toString() ?? '';
        chat['lastMessageTime'] = messageData['timestamp'];
        chat['lastMessageSender'] = currentUserId.value;
        chat['lastMessageSenderName'] =
            currentUser.value?['name']?.toString() ?? 'User';

        chatList.insert(0, chat);

        developer.log('⬆️ Chat moved to top when sending message');
      }
    } catch (e) {
      developer.log('❌ Error moving chat to top when sending: $e');
    }
  }

  // Move chat to top after successful send
  void _moveChatToTopAfterSending(String chatId) {
    // This will be handled by the real-time listener
    // Just trigger a refresh to ensure proper ordering
    Future.delayed(const Duration(milliseconds: 500), () {
      chatList.refresh();
    });
  }

  void clearCurrentChat() {
    if (currentUserId.value.isNotEmpty) {
      FirebaseService.updateCurrentChat(currentUserId.value, null);
    }
    currentChatId.value = '';
  }

  void _setupManagedStreamsWithBadges() {
    try {
      developer.log('📡 Setting up managed streams with badges...');

      // Cancel existing streams first
      _cancelAllStreamSubscriptions();

      if (currentUserId.value.isEmpty) return;

      // Users stream (unchanged)
      _streamSubscriptions['users'] = FirebaseService.getAllUsers().listen(
        (snapshot) {
          if (!_usersInitialized.value) {
            _handleUsersUpdate(snapshot);
          }
        },
        onError: (error) {
          developer.log('❌ Users stream error: $error');
        },
      );

      // UPDATED: Chats stream with badge management
      _streamSubscriptions['chats'] = FirebaseService.getUserChats(
        currentUserId.value,
      ).listen(
        (snapshot) {
          _handleChatsUpdateWithBadges(snapshot); // UPDATED
        },
        onError: (error) {
          developer.log('❌ Chats stream error: $error');
        },
      );

      // UPDATED: Global messages stream with badge management
      _streamSubscriptions['messages'] = FirebaseFirestore.instance
          .collection('messages')
          .where('participants', arrayContains: currentUserId.value)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen(
            (snapshot) {
              _handleGlobalMessagesUpdateWithBadges(snapshot); // UPDATED
            },
            onError: (error) {
              developer.log('❌ Messages stream error: $error');
            },
          );

      developer.log('✅ Managed streams with badges setup completed');
    } catch (e) {
      developer.log('❌ Error setting up managed streams with badges: $e');
    }
  }

  void _handleChatsUpdateWithBadges(QuerySnapshot snapshot) async {
  try {
    final chats = <Map<String, dynamic>>[];

    for (var doc in snapshot.docs) {
      final chatData = Map<String, dynamic>.from(
        doc.data() as Map<String, dynamic>,
      );
      chatData['id'] = doc.id;

      final participants = List<String>.from(chatData['participants'] ?? []);
      final otherUserId = participants.firstWhere(
        (id) => id != currentUserId.value,
        orElse: () => '',
      );

      if (otherUserId.isNotEmpty) {
        Map<String, dynamic>? otherUser = userCache[otherUserId];
        if (otherUser == null) {
          try {
            final userDoc = await FirebaseService.getUserById(otherUserId);
            if (userDoc.exists) {
              otherUser = Map<String, dynamic>.from(
                userDoc.data() as Map<String, dynamic>,
              );
              otherUser['id'] = otherUserId;
              otherUser['userId'] = otherUserId;
              if (!otherUser.containsKey('_id')) {
                otherUser['_id'] = otherUserId;
              }
              userCache[otherUserId] = otherUser;
            }
          } catch (e) {
            developer.log('Error loading user $otherUserId: $e');
            continue;
          }
        }

        if (otherUser != null) {
          chatData['otherUser'] = otherUser;
          chats.add(chatData);

          final chatId = chatData['chatId'] ?? '';
          
          // CRITICAL: Initialize badge and update unread count
          initializeBadgeForChat(chatId);
          _updateUnreadCountWithBadge(chatId, otherUserId);
        }
      }
    }

    // Sort chats by last message time (newest first)
    chats.sort((a, b) {
      final aTime = a['lastMessageTime'] as Timestamp?;
      final bTime = b['lastMessageTime'] as Timestamp?;

      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;

      return bTime.compareTo(aTime);
    });

    chatList.assignAll(chats);
    isLoadingChats.value = false;
    
    // Update total unread badges after loading chats
    updateTotalUnreadBadges();
    
    developer.log('💬 Updated ${chats.length} chats with badges');
  } catch (e) {
    developer.log('❌ Error handling chats update with badges: $e');
  }
}

  // Enhanced global message handler with badge management
  void _handleGlobalMessagesUpdateWithBadges(QuerySnapshot snapshot) {
  try {
    for (var change in snapshot.docChanges) {
      final messageData = change.doc.data() as Map<String, dynamic>?;
      if (messageData == null) continue;

      final chatId = messageData['chatId']?.toString() ?? '';
      final senderId = messageData['senderId']?.toString() ?? '';
      final isMyMessage = senderId == currentUserId.value;

      // Add message ID
      messageData['id'] = change.doc.id;

      switch (change.type) {
        case DocumentChangeType.added:
          // Handle new message with badge management
          _handleNewMessageWithBadge(chatId, messageData);
          break;
        case DocumentChangeType.modified:
          _handleMessageUpdate(change.doc.id, messageData);
          break;
        default:
          break;
      }
    }
  } catch (e) {
    developer.log('❌ Error handling global messages with badges: $e');
  }
}

  // Get message status for blue tick display
  String getMessageStatus(String messageId) {
    return messageStatuses[messageId] ?? 'sending';
  }

  // Get badge count for chat
  RxInt getBadgeCount(String chatId) {
    if (!badgeCounts.containsKey(chatId)) {
      badgeCounts[chatId] = 0.obs;
    }
    return badgeCounts[chatId]!;
  }

  // Clear badge for specific chat
  void clearBadge(String chatId) {
    if (badgeCounts.containsKey(chatId)) {
      badgeCounts[chatId]!.value = 0;
    }
    unreadCounts[chatId] = 0;
  }

  // ADDED: Refresh users and clear cache (useful after new user signup)

  // UI Animations
  void animateFab() {
    fabScale.value = 0.8;
    Future.delayed(const Duration(milliseconds: 150), () {
      fabScale.value = 1.0;
    });
  }

  void scrollToBottom() {
    showScrollToBottom.value = false;
  }

  void onScrollChanged(double pixels, double maxScrollExtent) {
    showScrollToBottom.value = pixels > 200;
  }

  // Navigation
  void changeBottomIndex(int index) {
    selectedBottomIndex.value = index;
  }

  @override
  void navigateToChat(Map<String, dynamic> user) async {
    try {
      // Quick fix: Always do a fresh API check if cache check fails
      bool canChat = isMutualFollower(user);

      if (!canChat) {
        final email = user['email']?.toString();
        if (email != null) {
          developer.log('🔄 Cache check failed, trying fresh API check...');
          final freshStatus = await followStatusManager.checkFollowStatus(
            email,
          );
          canChat = freshStatus?['isMutualFollow'] == true;
        }
      }

      if (!canChat) {
        Get.snackbar(
          'Access Denied',
          'You can only chat with users you mutually follow',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(milliseconds: 800),
        );
        return;
      }

      navigateToChatEnhanced(user);
    } catch (e) {
      developer.log('❌ Error in navigation: $e');
      // Show error but don't crash
    }
  }

  void setTyping(bool typing) {
    isTyping.value = typing;
  }

  // Theme management
  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  // Cleanup
  @override
  void onClose() {
    completeLogout();
    super.onClose();
  }

  // Utility methods
  String formatLastSeen(Timestamp? lastSeen) {
    if (lastSeen == null) return 'Never';

    final now = DateTime.now();
    final lastSeenDate = lastSeen.toDate();
    final difference = now.difference(lastSeenDate);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> loadAllUsersWithSmartCaching() async {
    if (isLoadingUsers.value) return;

    // IMPORTANT: If users are already loaded and filtered, don't reload
    if (_usersInitialized.value && allUsers.isNotEmpty) {
      developer.log('✅ Users already loaded and filtered, skipping reload');
      return;
    }

    isLoadingUsers.value = true;
    isLoadingFollowStatus.value = true;
    loadingStatusText.value = 'Loading users...';

    try {
      developer.log('📱 Smart loading users with caching...');

      // Step 1: Get all users from Firestore first
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      final allFirestoreUsers = <Map<String, dynamic>>[];

      for (var doc in usersSnapshot.docs) {
        final userData = Map<String, dynamic>.from(doc.data());
        userData['id'] = doc.id;
        userData['userId'] = doc.id;
        userData['_id'] = doc.id;
        allFirestoreUsers.add(userData);
      }

      developer.log('📱 Got ${allFirestoreUsers.length} users from Firestore');

      // Step 2: Show cached mutual followers immediately (if any)
      loadingStatusText.value = 'Checking follow status...';
      final cachedMutualFollowers = followStatusManager.filterMutualFollowers(
        allFirestoreUsers,
      );

      if (cachedMutualFollowers.isNotEmpty) {
        // Filter out current user
        final currentUserId = getCurrentUserId();
        final displayUsers =
            cachedMutualFollowers.where((user) {
              final userId = user['userId']?.toString() ?? '';
              return userId != currentUserId;
            }).toList();

        // Show cached data immediately
        allUsers.assignAll(displayUsers);
        _usersInitialized.value = true; // Mark as initialized
        developer.log(
          '✅ Showing ${displayUsers.length} cached mutual followers',
        );

        // Update cache
        for (final user in displayUsers) {
          final userId = user['userId']?.toString() ?? '';
          if (userId.isNotEmpty) {
            userCache[userId] = user;
          }
        }
      }

      // Step 3: Get emails that need follow status checking
      final emailsToCheck =
          allFirestoreUsers
              .map((user) => user['email']?.toString())
              .where((email) => email != null && email.isNotEmpty)
              .cast<String>()
              .toList();

      // Step 4: Batch check follow statuses for uncached users
      if (emailsToCheck.isNotEmpty) {
        loadingStatusText.value = 'Updating follow status...';

        await followStatusManager.batchCheckFollowStatus(emailsToCheck);

        // Step 5: Update with fresh data
        final updatedMutualFollowers = followStatusManager
            .filterMutualFollowers(allFirestoreUsers);
        final currentUserId = getCurrentUserId();
        final finalUsers =
            updatedMutualFollowers.where((user) {
              final userId = user['userId']?.toString() ?? '';
              return userId != currentUserId;
            }).toList();

        // Update reactive list
        allUsers.assignAll(finalUsers);
        _usersInitialized.value = true; // Mark as initialized

        // Update cache
        for (final user in finalUsers) {
          final userId = user['userId']?.toString() ?? '';
          if (userId.isNotEmpty) {
            userCache[userId] = user;
          }
        }

        developer.log('✅ Updated with ${finalUsers.length} mutual followers');
      }
    } catch (e) {
      developer.log('❌ Error in smart loading: $e');
      // Get.snackbar(
      //   'Error',
      //   'Failed to load users. Please try again.',
      //   snackPosition: SnackPosition.BOTTOM,
      //   backgroundColor: Colors.red.withOpacity(0.8),
      //   colorText: Colors.white,
      // );
    } finally {
      isLoadingUsers.value = false;
      isLoadingFollowStatus.value = false;
      loadingStatusText.value = '';
    }
  }

  // ENHANCED: Fast search with cached data
  Future<void> searchUsersWithSmartCaching(String query) async {
    if (query.trim().isEmpty) {
      searchResults.clear();
      return;
    }

    isSearching.value = true;

    try {
      developer.log('🔍 Smart searching: $query');

      // First, search in cached data
      final cachedResults = _searchInCachedData(query);
      if (cachedResults.isNotEmpty) {
        searchResults.assignAll(cachedResults);
        developer.log('✅ Found ${cachedResults.length} results in cache');
      }

      // Then, if we need more comprehensive search, do full search
      if (cachedResults.length < 5) {
        await _performFullSearch(query);
      }
    } catch (e) {
      developer.log('❌ Error in smart search: $e');
    } finally {
      isSearching.value = false;
    }
  }

  List<Map<String, dynamic>> _searchInCachedData(String query) {
    final queryLower = query.toLowerCase();
    return allUsers.where((user) {
      final name = user['name']?.toString().toLowerCase() ?? '';
      final email = user['email']?.toString().toLowerCase() ?? '';
      return name.contains(queryLower) || email.contains(queryLower);
    }).toList();
  }

  Future<void> _performFullSearch(String query) async {
    try {
      // Get all users and check follow status
      final results = await FirebaseService.searchUsers(query);
      final users = <Map<String, dynamic>>[];

      for (var doc in results.docs) {
        final userData = Map<String, dynamic>.from(
          doc.data() as Map<String, dynamic>,
        );
        userData['id'] = doc.id;
        userData['userId'] = doc.id;
        userData['_id'] = doc.id;
        users.add(userData);
      }

      // Check follow status for search results
      final emails =
          users
              .map((user) => user['email']?.toString())
              .where((email) => email != null && email.isNotEmpty)
              .cast<String>()
              .toList();

      if (emails.isNotEmpty) {
        await followStatusManager.batchCheckFollowStatus(emails);
        final mutualFollowers = followStatusManager.filterMutualFollowers(
          users,
        );

        final currentUserId = getCurrentUserId();
        final finalResults =
            mutualFollowers.where((user) {
              final userId = user['userId']?.toString() ?? '';
              return userId != currentUserId;
            }).toList();

        searchResults.assignAll(finalResults);
      }
    } catch (e) {
      developer.log('❌ Error in full search: $e');
    }
  }

  // ENHANCED: Preload follow statuses on app start
  Future<void> preloadFollowStatuses() async {
    try {
      developer.log('🚀 Preloading follow statuses...');

      // Get all user emails from Firestore
      final usersSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .get(); // REMOVED .select(['email']) as it's not supported

      final emails =
          usersSnapshot.docs
              .map((doc) => doc.data()['email']?.toString())
              .where((email) => email != null && email.isNotEmpty)
              .cast<String>()
              .toList();

      if (emails.isNotEmpty) {
        await followStatusManager.preloadFollowStatuses(emails);
        developer.log('✅ Preloaded follow statuses for ${emails.length} users');
      }
    } catch (e) {
      developer.log('❌ Error preloading follow statuses: $e');
    }
  }

  // ENHANCED: Load chats with cached profile data
  Future<void> loadUserChatsWithSmartCaching() async {
    if (isLoadingChats.value || currentUserId.value.isEmpty) return;

    isLoadingChats.value = true;
    try {
      developer.log('💬 Smart loading chats...');

      FirebaseService.getUserChats(currentUserId.value).listen((
        snapshot,
      ) async {
        final chats = <Map<String, dynamic>>[];

        for (var doc in snapshot.docs) {
          final chatData = Map<String, dynamic>.from(
            doc.data() as Map<String, dynamic>,
          );
          chatData['id'] = doc.id;

          final participants = List<String>.from(
            chatData['participants'] ?? [],
          );
          final otherUserId = participants.firstWhere(
            (id) => id != currentUserId.value,
            orElse: () => '',
          );

          if (otherUserId.isNotEmpty) {
            // Try to get enhanced user from cache first
            Map<String, dynamic>? otherUser = userCache[otherUserId];

            if (otherUser == null) {
              // Get from Firestore
              final userDoc = await FirebaseService.getUserById(otherUserId);
              if (userDoc.exists) {
                otherUser = Map<String, dynamic>.from(
                  userDoc.data() as Map<String, dynamic>,
                );
                otherUser['id'] = otherUserId;
                otherUser['userId'] = otherUserId;
                otherUser['_id'] = otherUserId;
              }
            }

            if (otherUser != null) {
              // Check if mutual follower using cached data
              if (followStatusManager.isMutualFollower(otherUser)) {
                // Get enhanced data from cache
                final email = otherUser['email']?.toString();
                if (email != null) {
                  final followStatus = followStatusManager
                      .getCachedFollowStatus(email);
                  if (followStatus != null) {
                    final apiUserData =
                        followStatus['user'] as Map<String, dynamic>;
                    otherUser = {
                      ...otherUser,
                      'name': apiUserData['name'],
                      'picture': apiUserData['picture'],
                      'apiPictureUrl':
                          'http://182.93.94.210:3066${apiUserData['picture']}',
                      'isMutualFollow': true,
                    };
                  }
                }

                chatData['otherUser'] = otherUser;
                chats.add(chatData);

                final chatId = chatData['chatId'] ?? '';
                _updateUnreadCount(chatId, otherUserId);

                if (!badgeCounts.containsKey(chatId)) {
                  badgeCounts[chatId] = 0.obs;
                }

                userCache[otherUserId] = otherUser;
              }
            }
          }
        }

        // Sort chats by last message time
        chats.sort((a, b) {
          final aTime = a['lastMessageTime'] as Timestamp?;
          final bTime = b['lastMessageTime'] as Timestamp?;

          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;

          return bTime.compareTo(aTime);
        });

        chatList.assignAll(chats);
        isLoadingChats.value = false;
        developer.log('✅ Loaded ${chats.length} chats (mutual followers only)');
      });
    } catch (e) {
      isLoadingChats.value = false;
      developer.log('❌ Error loading chats: $e');
    }
  }

  // Override existing methods
  @override
  Future<void> loadAllUsers() async {
    await loadAllUsersWithSmartCaching();
  }

  @override
  Future<void> loadUserChats() async {
    await loadUserChatsWithSmartCaching();
  }

  @override
  Future<void> searchUsers(String query) async {
    await searchUsersWithSmartCaching(query);
  }

  // Enhanced refresh with cache clearing
  @override
  Future<void> refreshUsersAndCache() async {
    try {
      developer.log('🔄 Refreshing users and clearing cache...');

      // Reset initialization flag to allow fresh loading
      _usersInitialized.value = false;

      // Clear caches
      userCache.clear();
      allUsers.clear();
      searchResults.clear();
      followStatusManager.clearCache();

      // Reload with fresh data
      await loadAllUsersWithSmartCaching();

      developer.log('✅ Refresh completed');
    } catch (e) {
      developer.log('❌ Error refreshing: $e');
    }
  }

  // NEW: Initialize with preloading
  Future<void> initializeWithPreloading() async {
    try {
      developer.log('🚀 Initializing with preloading...');

      // Start preloading in background
      preloadFollowStatuses();

      // Load users normally
      await loadAllUsersWithSmartCaching();
    } catch (e) {
      developer.log('❌ Error in initialization: $e');
    }
  }

  // Check if user is mutual follower (fast cached check)
  @override
  bool isMutualFollower(Map<String, dynamic>? user) {
    if (user == null) return false;
    return followStatusManager.isMutualFollower(user);
  }

  String formatMessageTime(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final messageTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(messageTime);

    if (difference.inDays > 0) {
      return '${messageTime.day}/${messageTime.month}/${messageTime.year}';
    } else {
      return '${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String formatChatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final chatTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(chatTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return weekdays[chatTime.weekday - 1];
      } else {
        return '${chatTime.day}/${chatTime.month}/${chatTime.year}';
      }
    } else if (difference.inHours > 0) {
      return '${chatTime.hour.toString().padLeft(2, '0')}:${chatTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String truncateMessage(String message, int maxLength) {
    if (message.length <= maxLength) return message;
    return '${message.substring(0, maxLength)}...';
  }

  int getUnreadCount(String chatId) {
    return unreadCounts[chatId] ?? 0;
  }

  String generateChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String getCurrentUserId() {
    return currentUser.value?['_id']?.toString() ??
        currentUser.value?['uid']?.toString() ??
        currentUser.value?['userId']?.toString() ??
        '';
  }

  bool isUserOnline(Map<String, dynamic>? user) {
    return user?['isOnline'] == true;
  }

  String getUserName(Map<String, dynamic>? user) {
    return user?['name']?.toString() ?? 'Unknown User';
  }

  String? getUserPhotoUrl(Map<String, dynamic>? user) {
    final photoUrl = user?['photoURL']?.toString();
    return (photoUrl != null && photoUrl.isNotEmpty) ? photoUrl : null;
  }

  String getUserInitials(Map<String, dynamic>? user) {
    final name = getUserName(user);
    return name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U';
  }
}
