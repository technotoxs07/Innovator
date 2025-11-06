import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/screens/chatApp/FollowStatusManager.dart'
    show FollowStatusManager;
import 'package:innovator/Innovator/services/Firebase_Messaging.dart';
import 'package:innovator/Innovator/services/call_permission_service.dart';
import 'package:innovator/Innovator/services/firebase_services.dart';
import 'package:innovator/Innovator/services/webrtc_call_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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
setupFirebaseAuthListener();
  // IMPORTANT: Initialize badge system
  chatBadges.clear();
  totalUnreadBadges.value = 0;
  developer.log('✅ Badge system initialized');
   WidgetsBinding.instance.addPostFrameCallback((_) {
    _initializeData();
  });
  }

  Future<void> _initializeData() async {
  try {
    developer.log('🚀 Initializing data on ready...');
    
    // Only load if not already loaded
    if (allUsers.isEmpty && !isLoadingUsers.value) {
      await loadAllUsersWithSmartCaching();
    }
    
    // Load chats after users
    if (chatList.isEmpty && !isLoadingChats.value) {
      await loadUserChatsWithEnhancedProfiles();
    }
    
  } catch (e) {
    developer.log('❌ Error in initialization: $e');
  }
}

  // Add these methods to your FireChatController class

// Initialize badge for a specific chat
void initializeBadgeForChat(String chatId) {
  if (!chatBadges.containsKey(chatId)) {
    chatBadges[chatId] = 0.obs;
  }
}
// Future<void> startVoiceCall(Map<String, dynamic> user) async {
//   try {
//     developer.log('📞 Starting voice call to: ${user['name']}');
    
//     // Check if user is mutual follower
//     if (!isMutualFollower(user)) {
//       Get.snackbar(
//         'Cannot Call User',
//         'You can only call users you mutually follow',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.orange.withAlpha(80),
//         colorText: Colors.white,
//         duration: const Duration(seconds: 3),
//       );
//       return;
//     }
    
//     // Check permissions
//     final hasPermissions = await CallPermissionService.requestPermissions(isVideoCall: false);
//     if (!hasPermissions) {
//       Get.snackbar(
//         'Permission Required',
//         'Microphone permission is required for voice calls',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red.withAlpha(80),
//         colorText: Colors.white,
//       );
//       return;
//     }
    
//     final receiverId = user['userId']?.toString() ?? 
//                       user['_id']?.toString() ?? 
//                       user['id']?.toString() ?? '';
//     final receiverName = user['name']?.toString() ?? 'Unknown User';
    
//     if (receiverId.isEmpty || receiverName.isEmpty) {
//       Get.snackbar('Error', 'Invalid user data');
//       return;
//     }
    
//     // Initialize call service if not already done
//     // if (!Get.isRegistered<WebRTCCallService>()) {
//     //   Get.put(WebRTCCallService(), permanent: true);
//     // }
    
//     //final callService = WebRTCCallService.instance;
    
//     // Enable wake lock during calls
//     await WakelockPlus.enable();
    
//     // Start the call
//     final callId = await callService.startCall(
//       receiverId: receiverId,
//       receiverName: receiverName,
//       callerId: currentUserId.value,
//       callerName: currentUser.value?['name']?.toString() ?? 'User',
//       isVideoCall: false,
//     );
    
//     // Add to recent users
//     addUserToRecent(user);
    
//     // Navigate to outgoing call screen
//     Get.to(
//       () => OutgoingCallScreen(
//         callData: {
//           'callId': callId,
//           'receiverId': receiverId,
//           'receiverName': receiverName,
//           'callerId': currentUserId.value,
//           'callerName': currentUser.value?['name']?.toString() ?? 'User',
//           'isVideoCall': false,
//         },
//       ),
//       transition: Transition.fadeIn,
//       fullscreenDialog: true,
//     );
    
//     developer.log('✅ Voice call started: $callId');
    
//     // Track call in analytics (optional)
//     _trackCallEvent('voice_call_started', receiverId, receiverName);
    
//   } catch (e) {
//     developer.log('❌ Error starting voice call: $e');
//     await WakelockPlus.disable();
//     Get.snackbar(
//       'Call Failed',
//       'Failed to start voice call. Please try again.',
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: Colors.red.withAlpha(80),
//       colorText: Colors.white,
//     );
//   }
// }


// // Start video call
// Future<void> startVideoCall(Map<String, dynamic> user) async {
//   try {
//     developer.log('📹 Starting video call to: ${user['name']}');
    
//     // Check if user is mutual follower
//     if (!isMutualFollower(user)) {
//       Get.snackbar(
//         'Cannot Call User',
//         'You can only call users you mutually follow',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.orange.withAlpha(80),
//         colorText: Colors.white,
//         duration: const Duration(seconds: 3),
//       );
//       return;
//     }
    
//     // Check permissions
//     final hasPermissions = await CallPermissionService.requestPermissions(isVideoCall: true);
//     if (!hasPermissions) {
//       Get.snackbar(
//         'Permissions Required',
//         'Camera and microphone permissions are required for video calls',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red.withAlpha(80),
//         colorText: Colors.white,
//       );
//       return;
//     }
    
//     final receiverId = user['userId']?.toString() ?? 
//                       user['_id']?.toString() ?? 
//                       user['id']?.toString() ?? '';
//     final receiverName = user['name']?.toString() ?? 'Unknown User';
    
//     if (receiverId.isEmpty || receiverName.isEmpty) {
//       Get.snackbar('Error', 'Invalid user data');
//       return;
//     }
    
//     // Initialize call service if not already done
//     if (!Get.isRegistered<WebRTCCallService>()) {
//       Get.put(WebRTCCallService(), permanent: true);
//     }
    
//     final callService = WebRTCCallService.instance;
    
//     // Enable wake lock during calls
//     await WakelockPlus.enable();
    
//     // Start the call
//     final callId = await callService.startCall(
//       receiverId: receiverId,
//       receiverName: receiverName,
//       callerId: currentUserId.value,
//       callerName: currentUser.value?['name']?.toString() ?? 'User',
//       isVideoCall: true,
//     );
    
//     // Add to recent users
//     addUserToRecent(user);
    
//     // Navigate to outgoing call screen
//     Get.to(
//       () => OutgoingCallScreen(
//         callData: {
//           'callId': callId,
//           'receiverId': receiverId,
//           'receiverName': receiverName,
//           'callerId': currentUserId.value,
//           'callerName': currentUser.value?['name']?.toString() ?? 'User',
//           'isVideoCall': true,
//         },
//       ),
//       transition: Transition.fadeIn,
//       fullscreenDialog: true,
//     );
    
//     developer.log('✅ Video call started: $callId');
    
//     // Track call in analytics (optional)
//     _trackCallEvent('video_call_started', receiverId, receiverName);
    
//   } catch (e) {
//     developer.log('❌ Error starting video call: $e');
//     await WakelockPlus.disable();
//     Get.snackbar(
//       'Call Failed',
//       'Failed to start video call. Please try again.',
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: Colors.red.withAlpha(80),
//       colorText: Colors.white,
//     );
//   }
// }


// void _trackCallEvent(String event, String receiverId, String receiverName) {
//   try {
//     // You can integrate with your analytics service here
//     developer.log('📊 Call event: $event to $receiverName ($receiverId)');
//   } catch (e) {
//     developer.log('❌ Error tracking call event: $e');
//   }
// }

// bool canCallUser(Map<String, dynamic> user) {
//   final isOnline = user['isOnline'] == true;
//   final isMutual = isMutualFollower(user);
  
//   return isOnline && isMutual;
// }

// Get call button for user
// Widget buildCallButtons(Map<String, dynamic> user) {
//   if (!canCallUser(user)) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: Colors.grey.withAlpha(30),
//         borderRadius: BorderRadius.circular(15),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(Icons.phone_disabled, size: 16, color: Colors.grey.shade600),
//           const SizedBox(width: 4),
//           Text(
//             'Unavailable',
//             style: TextStyle(
//               fontSize: 12,
//               color: Colors.grey.shade600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
  
//   return Row(
//     mainAxisSize: MainAxisSize.min,
//     children: [
//       // Voice call button
//       GestureDetector(
//         onTap: () => startVoiceCall(user),
//         child: Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: Colors.green,
//             shape: BoxShape.circle,
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.green.withAlpha(30),
//                 blurRadius: 8,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: const Icon(
//             Icons.call,
//             color: Colors.white,
//             size: 18,
//           ),
//         ),
//       ),
      
//       const SizedBox(width: 8),
      
//       // Video call button
//       GestureDetector(
//         onTap: () => startVideoCall(user),
//         child: Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: Colors.blue,
//             shape: BoxShape.circle,
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.blue.withAlpha(30),
//                 blurRadius: 8,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: const Icon(
//             Icons.videocam,
//             color: Colors.white,
//             size: 18,
//           ),
//         ),
//       ),
//     ],
//   );
// }
  
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


Future<String> getOrCreateChatId(Map<String, dynamic> user) async {
  try {
    final userId = user['userId']?.toString() ?? 
                  user['_id']?.toString() ?? 
                  user['id']?.toString() ?? '';
    
    if (userId.isEmpty) throw Exception('Invalid user ID');
    
    final chatId = generateChatId(currentUserId.value, userId);
    
    // Check if chat exists in local list
    final existingChat = chatList.firstWhere(
      (chat) => chat['chatId'] == chatId,
      orElse: () => {},
    );
    
    if (existingChat.isEmpty) {
      // Create initial chat document
      await FirebaseService.createInitialChat(
        chatId: chatId,
        currentUserId: currentUserId.value,
        receiverId: userId,
        receiverName: user['name']?.toString() ?? 'Unknown User',
      );
      
      developer.log('✅ New chat created: $chatId');
    }
    
    return chatId;
  } catch (e) {
    developer.log('❌ Error getting or creating chat: $e');
    rethrow;
  }
}

// Trigger chat move animation
void _triggerChatMoveAnimation() {
  try {
    // Trigger smooth animation
    chatList.refresh();
    
    // Optional: Add a subtle pulse animation to the top item
    Future.delayed(const Duration(milliseconds: 300), () {
      if (chatList.isNotEmpty) {
        // You can add animation logic here if needed
        developer.log('🎬 Chat move animation triggered');
      }
    });
  } catch (e) {
    developer.log('❌ Error triggering chat animation: $e');
  }
}

Future<void> refreshChatOrder() async {
  try {
    developer.log('🔄 Refreshing chat order...');
    
    // Re-sort the existing chats
    _sortChatListByTime();
    
    // Refresh the UI
    chatList.refresh();
    
    developer.log('✅ Chat order refreshed');
  } catch (e) {
    developer.log('❌ Error refreshing chat order: $e');
  }
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
int getTotalUnreadCountFromMutualFollowers() {
  int total = 0;
  
  try {
    for (var chat in chatList) {
      final otherUser = chat['otherUser'] as Map<String, dynamic>?;
      final chatId = chat['chatId']?.toString() ?? '';
      
      if (otherUser != null && chatId.isNotEmpty) {
        // Only count badges from mutual followers (using SYNC method)
        if (isMutualFollower(otherUser)) {
          final badgeCount = chatBadges[chatId]?.value ?? 0;
          total += badgeCount;
        }
      }
    }
  } catch (e) {
    developer.log('❌ Error calculating total unread count from mutual followers: $e');
  }
  
  developer.log('📊 Total unread count from mutual followers: $total');
  return total;
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

  Future<void> _handleOutgoingMessage(String chatId, Map<String, dynamic> messageData) async {
  try {
    developer.log('📤 Handling outgoing message: $chatId');
    
    // Always move to top when I send a message
    await _moveChatsToTopOnActivity(chatId, messageData);
    
    // Update recent users
    final receiverId = messageData['receiverId']?.toString() ?? '';
    if (receiverId.isNotEmpty) {
      try {
        final receiverDoc = await FirebaseService.getUserById(receiverId);
        if (receiverDoc.exists) {
          final receiverData = receiverDoc.data() as Map<String, dynamic>;
          receiverData['id'] = receiverId;
          receiverData['userId'] = receiverId;
          receiverData['_id'] = receiverId;
          
          addUserToRecent(receiverData);
        }
      } catch (e) {
        developer.log('Error adding receiver to recent: $e');
      }
    }
    
  } catch (e) {
    developer.log('❌ Error handling outgoing message: $e');
  }
}

// ENHANCED: Handle incoming messages (when I receive a message)
Future<void> _handleIncomingMessageForTop(String chatId, Map<String, dynamic> messageData) async {
  try {
    final senderId = messageData['senderId']?.toString() ?? '';
    developer.log('📥 Handling incoming message: $chatId from $senderId');
    
    // Check if sender is mutual follower
    final senderDoc = await FirebaseService.getUserById(senderId);
    if (!senderDoc.exists) return;
    
    final senderData = senderDoc.data() as Map<String, dynamic>;
    senderData['id'] = senderId;
    senderData['userId'] = senderId;
    senderData['_id'] = senderId;
    
    if (!isMutualFollower(senderData)) {
      developer.log('🚫 Not moving to top - sender is not mutual follower: $senderId');
      return;
    }
    
    // Move to top for mutual followers
    await _moveChatsToTopOnActivity(chatId, messageData);
    
    // Add sender to recent users
    addUserToRecent(senderData);
    
    // Handle badge counting (only if not currently viewing this chat)
    if (currentChatId.value != chatId) {
      initializeBadgeForChat(chatId);
      final currentBadge = chatBadges[chatId]?.value ?? 0;
      chatBadges[chatId]!.value = currentBadge + 1;
      unreadCounts[chatId] = currentBadge + 1;
      updateTotalUnreadBadges();
      _animateNewBadge(chatId);
    }
    
  } catch (e) {
    developer.log('❌ Error handling incoming message for top: $e');
  }
}

  // ENHANCED: Clear badge when messages are read
  //@override
Future<void> markMessagesAsRead(String chatId) async {
  if (chatId.isEmpty) return;

  try {
    developer.log('📖 Marking messages as read for chat: $chatId');
    
    // Call original Firebase method
    await FirebaseService.markMessagesAsRead(chatId, currentUserId.value);

    // CRITICAL: Clear local badge immediately
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
    WidgetsBinding.instance.addPostFrameCallback((_) async{
      initializeWithPreloading();
          await refreshBadgeSystemWithFollowFilter();

    });

    
  }


  Future<void> fixUnreadBadgeCount() async {
  try {
    developer.log('🔧 Fixing unread badge count...');
    
    // Step 1: Clear all badges
    clearAllBadges();
    
    // Step 2: Refresh with proper filtering
    await refreshBadgeSystemWithFollowFilter();
    
    // Step 3: Force UI refresh
    chatList.refresh();
    allUsers.refresh();
    
    developer.log('✅ Badge count fixed successfully');
    
    // Show success message
    // Get.snackbar(
    //   'Badge System Updated', 
    //   'Unread message count has been refreshed',
    //   backgroundColor: Colors.green,
    //   colorText: Colors.white,
    //   duration: Duration(seconds: 2),
    // );
    
  } catch (e) {
    developer.log('❌ Error fixing badge count: $e');
  }
}

// ENHANCED: Move chat to top for ANY new activity (send/receive)
Future<void> _moveChatsToTopOnActivity(String chatId, Map<String, dynamic> messageData) async {
  try {
    final senderId = messageData['senderId']?.toString() ?? '';
    final isMyMessage = senderId == currentUserId.value;
    
    developer.log('📤📥 Moving chat to top - ChatID: $chatId, IsMyMessage: $isMyMessage');
    
    // Update the chat document in Firestore first to ensure timestamp is current
    await _updateChatTimestamp(chatId, messageData);
    
    // Then move in local list
    await _moveLocalChatToTop(chatId, messageData);
    
  } catch (e) {
    developer.log('❌ Error moving chat to top on activity: $e');
  }
}

Future<void> _updateChatTimestamp(String chatId, Map<String, dynamic> messageData) async {
  try {
    final chatDocRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    
    await chatDocRef.update({
      'lastMessage': messageData['message']?.toString() ?? '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSender': messageData['senderId']?.toString() ?? '',
      'lastMessageSenderName': messageData['senderName']?.toString() ?? '',
      'lastMessageId': messageData['id']?.toString() ?? '',
      'lastMessageType': messageData['messageType']?.toString() ?? 'text',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    developer.log('✅ Chat timestamp updated in Firestore: $chatId');
  } catch (e) {
    developer.log('❌ Error updating chat timestamp: $e');
  }
}

// Move chat to top in local list with animation
Future<void> _moveLocalChatToTop(String chatId, Map<String, dynamic> messageData) async {
  try {
    final chatIndex = chatList.indexWhere((chat) => chat['chatId'] == chatId);
    
    if (chatIndex == -1) {
      // Chat doesn't exist in list - create it if it's from/to a mutual follower
      await _createNewChatEntry(chatId, messageData);
      return;
    }
    
    if (chatIndex == 0) {
      // Already at top, just update the data
      final chat = chatList[0];
      _updateChatData(chat, messageData);
      chatList.refresh();
      developer.log('📌 Chat already at top, data updated: $chatId');
      return;
    }
    
    // Move chat from current position to top
    final chat = chatList.removeAt(chatIndex);
    _updateChatData(chat, messageData);
    chatList.insert(0, chat);
    
    developer.log('⬆️ Chat moved to top: $chatId (from position $chatIndex)');
    
    // Trigger smooth animation
    _triggerChatMoveAnimation();
    
  } catch (e) {
    developer.log('❌ Error moving local chat to top: $e');
  }
}

void _updateChatData(Map<String, dynamic> chat, Map<String, dynamic> messageData) {
  chat['lastMessage'] = messageData['message']?.toString() ?? '';
  chat['lastMessageTime'] = messageData['timestamp'] ?? Timestamp.now();
  chat['lastMessageSender'] = messageData['senderId']?.toString() ?? '';
  chat['lastMessageSenderName'] = messageData['senderName']?.toString() ?? '';
  chat['lastMessageId'] = messageData['id']?.toString() ?? '';
  chat['lastMessageType'] = messageData['messageType']?.toString() ?? 'text';
  chat['updatedAt'] = Timestamp.now();
}

// Create new chat entry for first-time conversations
Future<void> _createNewChatEntry(String chatId, Map<String, dynamic> messageData) async {
  try {
    final senderId = messageData['senderId']?.toString() ?? '';
    final receiverId = messageData['receiverId']?.toString() ?? '';
    final isMyMessage = senderId == currentUserId.value;
    
    // Determine the other user ID
    final otherUserId = isMyMessage ? receiverId : senderId;
    
    if (otherUserId.isEmpty) return;
    
    // Get other user data
    final otherUserDoc = await FirebaseService.getUserById(otherUserId);
    if (!otherUserDoc.exists) return;
    
    final otherUserData = Map<String, dynamic>.from(
      otherUserDoc.data() as Map<String, dynamic>,
    );
    otherUserData['id'] = otherUserId;
    otherUserData['userId'] = otherUserId;
    otherUserData['_id'] = otherUserId;
    
    // Check if mutual follower
    if (!isMutualFollower(otherUserData)) {
      developer.log('🚫 Not creating chat entry - user is not mutual follower: $otherUserId');
      return;
    }
    
    // Enhance user data if possible
    final email = otherUserData['email']?.toString();
    if (email != null) {
      final followStatus = await followStatusManager.checkFollowStatus(email);
      if (followStatus != null && followStatus['isMutualFollow'] == true) {
        final apiUserData = followStatus['user'] as Map<String, dynamic>;
        otherUserData['name'] = apiUserData['name'];
        otherUserData['picture'] = apiUserData['picture'];
        otherUserData['apiPictureUrl'] = 'http://182.93.94.210:3067${apiUserData['picture']}';
        otherUserData['isMutualFollow'] = true;
      }
    }
    
    // Create new chat entry
    final newChat = {
      'id': chatId,
      'chatId': chatId,
      'participants': [currentUserId.value, otherUserId],
      'otherUser': otherUserData,
      'lastMessage': messageData['message']?.toString() ?? '',
      'lastMessageTime': messageData['timestamp'] ?? Timestamp.now(),
      'lastMessageSender': senderId,
      'lastMessageSenderName': messageData['senderName']?.toString() ?? '',
      'lastMessageId': messageData['id']?.toString() ?? '',
      'lastMessageType': messageData['messageType']?.toString() ?? 'text',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'isActive': true,
    };
    
    // Add at the top of the list
    chatList.insert(0, newChat);
    
    // Initialize badge for this chat
    initializeBadgeForChat(chatId);
    
    developer.log('✅ New chat entry created and added to top: $chatId');
    
    _triggerChatMoveAnimation();
    
  } catch (e) {
    developer.log('❌ Error creating new chat entry: $e');
  }
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
  isLoadingFollowStatus.value = true;
  loadingStatusText.value = 'Loading mutual followers...';
  
  try {
    developer.log('📱 Loading users with follow status filter...');
    
    // Step 1: Get all users from Firestore first
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .orderBy('name')
        .get()
        .timeout(const Duration(seconds: 30));
    
    developer.log('📱 Got ${usersSnapshot.docs.length} users from Firestore');
    loadingStatusText.value = 'Checking follow status...';
    
    // Step 2: Get all emails for batch follow status check
    final allUsers = <Map<String, dynamic>>[];
    final emails = <String>[];
    
    for (var doc in usersSnapshot.docs) {
      if (doc.id != currentUserId.value) {
        final userData = Map<String, dynamic>.from(doc.data());
        userData['id'] = doc.id;
        userData['userId'] = doc.id;
        userData['_id'] = doc.id;
        
        allUsers.add(userData);
        
        final email = userData['email']?.toString();
        if (email != null && email.isNotEmpty) {
          emails.add(email);
        }
      }
    }
    
    // Step 3: Batch check follow statuses
    developer.log('👥 Batch checking follow status for ${emails.length} users...');
    final followResults = await followStatusManager.batchCheckFollowStatus(emails);
    
    // Step 4: Filter and enhance users with mutual follow status
    final mutualFollowers = <Map<String, dynamic>>[];
    
    for (final user in allUsers) {
      final email = user['email']?.toString();
      if (email != null) {
        final followStatus = followResults[email];
        if (followStatus != null && followStatus['isMutualFollow'] == true) {
          // Enhance user data with API info
          final apiUserData = followStatus['user'] as Map<String, dynamic>;
          final enhancedUser = {
            ...user, // Keep Firestore data (for chat functionality)
            'name': apiUserData['name'], // Use API name
            'picture': apiUserData['picture'], // Use API picture
            'apiPictureUrl': 'http://182.93.94.210:3067${apiUserData['picture']}', // Full picture URL
            'isFollowing': followStatus['isFollowing'],
            'isFollowedBy': followStatus['isFollowedBy'],
            'isMutualFollow': true,
          };
          
          mutualFollowers.add(enhancedUser);
          
          // Update cache
          userCache[user['_id']] = enhancedUser;
        }
      }
    }
    
    // Step 5: Update users list
    allUsers.assignAll(mutualFollowers);
    _usersInitialized.value = true; // Mark as initialized to prevent Firestore overrides
    
    developer.log('✅ Loaded ${mutualFollowers.length} mutual followers');
    loadingStatusText.value = 'Complete!';
    
  } catch (e) {
    developer.log('❌ Error loading users with follow filter: $e');
    loadingStatusText.value = 'Error loading users';
    
    // Fallback: Load from Firestore without follow filter
    try {
      await loadAllUsersWithSmartCaching();
    } catch (fallbackError) {
      developer.log('❌ Fallback loading also failed: $fallbackError');
    }
  } finally {
    isLoadingUsers.value = false;
    isLoadingFollowStatus.value = false;
    
    // Clear loading text after delay
    Future.delayed(const Duration(seconds: 1), () {
      loadingStatusText.value = '';
    });
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
        backgroundColor: Colors.red.withAlpha(80),
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
    developer.log('💬 Loading chats with enhanced profiles and follow validation...');

    FirebaseService.getUserChats(currentUserId.value).listen((snapshot) async {
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
          // Get user from cache first (which includes follow status)
          Map<String, dynamic>? otherUser = userCache[otherUserId];
          
          if (otherUser == null) {
            // Get from Firestore if not in cache
            try {
              final userDoc = await FirebaseService.getUserById(otherUserId);
              if (userDoc.exists) {
                otherUser = Map<String, dynamic>.from(
                  userDoc.data() as Map<String, dynamic>,
                );
                otherUser['id'] = otherUserId;
                otherUser['userId'] = otherUserId;
                otherUser['_id'] = otherUserId;
                
                // Check follow status for this user
                final email = otherUser['email']?.toString();
                if (email != null) {
                  final followStatus = await followStatusManager.checkFollowStatus(email);
                  if (followStatus != null && followStatus['isMutualFollow'] == true) {
                    // Enhance with API data
                    final apiUserData = followStatus['user'] as Map<String, dynamic>;
                    otherUser = {
                      ...otherUser,
                      'name': apiUserData['name'],
                      'picture': apiUserData['picture'],
                      'apiPictureUrl': 'http://182.93.94.210:3067${apiUserData['picture']}',
                      'isMutualFollow': true,
                    };
                    userCache[otherUserId] = otherUser;
                  } else {
                    // Not a mutual follower, skip this chat
                    continue;
                  }
                }
              }
            } catch (e) {
              developer.log('Error loading user $otherUserId: $e');
              continue;
            }
          }

          // Only include chats with mutual followers
          if (otherUser != null && (otherUser['isMutualFollow'] == true || isMutualFollower(otherUser))) {
            chatData['otherUser'] = otherUser;
            chats.add(chatData);

            final chatId = chatData['chatId'] ?? '';
            
            // Initialize badge system for this chat
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
      
      // Update total badges
      updateTotalUnreadBadges();
      
      developer.log('✅ Loaded ${chats.length} chats (mutual followers only)');
    });
  } catch (e) {
    isLoadingChats.value = false;
    developer.log('❌ Error loading chats with enhanced profiles: $e');
  }
}


Future<void> searchUsersWithFollowValidation(String query) async {
  if (query.trim().isEmpty) {
    searchResults.clear();
    return;
  }

  isSearching.value = true;
  try {
    developer.log('🔍 Searching users with follow validation: $query');

    // Search in cached mutual followers first
    final cachedResults = _searchInMutualFollowers(query);
    
    if (cachedResults.isNotEmpty) {
      searchResults.assignAll(cachedResults);
      developer.log('✅ Found ${cachedResults.length} mutual followers in cache');
    } else {
      // Perform broader search and validate follow status
      await _performSearchWithFollowCheck(query);
    }
    
  } catch (e) {
    developer.log('❌ Error searching with follow validation: $e');
    Get.snackbar(
      'Search Error',
      'Failed to search users. Please try again.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withAlpha(80),
      colorText: Colors.white,
    );
  } finally {
    isSearching.value = false;
  }
}

List<Map<String, dynamic>> _searchInMutualFollowers(String query) {
  final queryLower = query.toLowerCase();
  return allUsers.where((user) {
    final name = user['name']?.toString().toLowerCase() ?? '';
    final email = user['email']?.toString().toLowerCase() ?? '';
    return (name.contains(queryLower) || email.contains(queryLower)) && 
           (user['isMutualFollow'] == true);
  }).toList();
}

// Perform search with follow status check
Future<void> _performSearchWithFollowCheck(String query) async {
  try {
    final results = await FirebaseService.searchUsers(query);
    final users = <Map<String, dynamic>>[];
    final emails = <String>[];

    for (var doc in results.docs) {
      if (doc.id != currentUserId.value) {
        final userData = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
        userData['id'] = doc.id;
        userData['userId'] = doc.id;
        userData['_id'] = doc.id;
        
        users.add(userData);
        
        final email = userData['email']?.toString();
        if (email != null && email.isNotEmpty) {
          emails.add(email);
        }
      }
    }

    // Batch check follow status
    if (emails.isNotEmpty) {
      final followResults = await followStatusManager.batchCheckFollowStatus(emails);
      
      final mutualFollowers = <Map<String, dynamic>>[];
      for (final user in users) {
        final email = user['email']?.toString();
        if (email != null) {
          final followStatus = followResults[email];
          if (followStatus != null && followStatus['isMutualFollow'] == true) {
            // Enhance with API data
            final apiUserData = followStatus['user'] as Map<String, dynamic>;
            final enhancedUser = {
              ...user,
              'name': apiUserData['name'],
              'picture': apiUserData['picture'],
              'apiPictureUrl': 'http://182.93.94.210:3067${apiUserData['picture']}',
              'isMutualFollow': true,
            };
            mutualFollowers.add(enhancedUser);
          }
        }
      }
      
      searchResults.assignAll(mutualFollowers);
      developer.log('✅ Search found ${mutualFollowers.length} mutual followers');
    }
  } catch (e) {
    developer.log('❌ Error in search with follow check: $e');
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
        return 'http://182.93.94.210:3067$picture';
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
  Future<void> initializeUser() async {
  try {
    developer.log('👤 Initializing chat controller user...');
    
    final userData = AppData().currentUser;
    if (userData != null) {
      currentUser.value = userData;
      currentUserId.value = userData['_id']?.toString() ?? 
                           userData['uid']?.toString() ?? '';
      
      developer.log('👤 Current user set: ${currentUserId.value}');
      
      // Update user status to online
      if (currentUserId.value.isNotEmpty) {
        await updateUserStatus(true);
        developer.log('👤 User status updated to online');
      }
    } else {
      developer.log('⚠️ No user data found in AppData');
    }
  } catch (e) {
    developer.log('❌ Error initializing user: $e');
  }
}

Future<void> cleanupNonMutualFollowerBadges() async {
  try {
    developer.log('🧹 Cleaning up badges from non-mutual followers...');
    
    final chatIdsToClean = <String>[];
    
    // Check each chat's other user
    for (var chat in chatList) {
      final otherUser = chat['otherUser'] as Map<String, dynamic>?;
      final chatId = chat['chatId']?.toString() ?? '';
      
      if (otherUser != null && chatId.isNotEmpty) {
        // If user is not a mutual follower, mark for cleanup
        if (!isMutualFollower(otherUser)) {
          chatIdsToClean.add(chatId);
        }
      }
    }
    
    // Clean up badges for non-mutual followers
    for (String chatId in chatIdsToClean) {
      developer.log('🧹 Clearing badge for non-mutual follower chat: $chatId');
      chatBadges[chatId]?.value = 0;
      unreadCounts[chatId] = 0;
    }
    
    // Update total badges
    updateTotalUnreadBadges();
    
    developer.log('✅ Cleaned up ${chatIdsToClean.length} badges from non-mutual followers');
  } catch (e) {
    developer.log('❌ Error cleaning up non-mutual follower badges: $e');
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
            _updateUnreadCountWithFollowFilter(chatId, otherUserId);

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
              _handleNewMessageWithMutualFollowerCheck(chatId, messageData);
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

  void _sortChatListByTime() {
  try {
    chatList.sort((a, b) {
      final aTime = a['lastMessageTime'] as Timestamp?;
      final bTime = b['lastMessageTime'] as Timestamp?;
      
      // Handle null timestamps
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1; // Move to bottom
      if (bTime == null) return -1; // Move to top
      
      // Most recent first
      return bTime.compareTo(aTime);
    });
    
    developer.log('📊 Chat list sorted by timestamp');
  } catch (e) {
    developer.log('❌ Error sorting chat list: $e');
  }
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
                if (isMyMessage) {
                  // Handle outgoing message
                  _handleOutgoingMessage(chatId, messageData);
                } else {
                  // Handle incoming message
                  _handleIncomingMessageForTop(chatId, messageData);
                }
                break;
              case DocumentChangeType.modified:
                _handleMessageUpdate(change.doc.id, messageData);
                break;
              default:
                break;
            }
          }
        });
        
    developer.log('✅ Global message listener with top movement started');
  } catch (e) {
    developer.log('❌ Error setting up global message listener with top movement: $e');
  }
}

  // Handle new incoming messages
  void _handleNewMessageWithMutualFollowerCheck(String chatId, Map<String, dynamic> messageData) {
  try {
    final senderId = messageData['senderId']?.toString() ?? '';
    final isMyMessage = senderId == currentUserId.value;
    
    developer.log('📨 New message - Chat: $chatId, IsMyMessage: $isMyMessage, Sender: $senderId');
    
    // Only process messages I didn't send
    if (!isMyMessage) {
      // Check if sender is a mutual follower
      _checkSenderMutualFollowStatus(chatId, senderId, messageData);
    }
    
    // ALWAYS move chat to top for any new message (if it's from mutual follower)
    _moveChatToTopWithMutualCheck(chatId, messageData);
    
  } catch (e) {
    developer.log('❌ Error handling new message with mutual follower check: $e');
  }
}

Future<void> _checkSenderMutualFollowStatus(String chatId, String senderId, Map<String, dynamic> messageData) async {
  try {
    // Get sender user data
    final senderDoc = await FirebaseService.getUserById(senderId);
    if (!senderDoc.exists) {
      developer.log('⚠️ Sender user not found: $senderId');
      return;
    }
    
    final senderData = senderDoc.data() as Map<String, dynamic>;
    senderData['id'] = senderId;
    senderData['userId'] = senderId;
    senderData['_id'] = senderId;
    
    // Use SYNC check for speed (since this runs frequently)
    if (!isMutualFollower(senderData)) {
      developer.log('🚫 Ignoring message from non-mutual follower: $senderId');
      return;
    }
    
    // Initialize badge for this chat if sender is mutual follower
    initializeBadgeForChat(chatId);
    
    // Check if user is currently viewing this chat
    final isViewingThisChat = currentChatId.value == chatId;
    
    if (!isViewingThisChat) {
      // Increment badge for unread messages from mutual followers
      final currentBadge = chatBadges[chatId]?.value ?? 0;
      chatBadges[chatId]!.value = currentBadge + 1;
      unreadCounts[chatId] = currentBadge + 1;
      
      developer.log('🔴 NEW UNREAD MESSAGE from mutual follower - Badge incremented for chat $chatId: ${currentBadge + 1}');
      
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
  } catch (e) {
    developer.log('❌ Error checking sender mutual follow status: $e');
  }
}

// Enhanced move chat to top with mutual follower check
void _moveChatToTopWithMutualCheck(String chatId, Map<String, dynamic> messageData) async {
  try {
    final senderId = messageData['senderId']?.toString() ?? '';
    
    // Only move to top if sender is mutual follower (or if it's my message)
    if (senderId != currentUserId.value) {
      final senderDoc = await FirebaseService.getUserById(senderId);
      if (senderDoc.exists) {
        final senderData = senderDoc.data() as Map<String, dynamic>;
        senderData['id'] = senderId;
        senderData['userId'] = senderId;
        senderData['_id'] = senderId;
        
        // Use SYNC check for performance
        if (!isMutualFollower(senderData)) {
          developer.log('🚫 Not moving chat to top - sender is not mutual follower: $senderId');
          return;
        }
      }
    }
    
    // Move chat to top
    _moveChatToTopWithAnimation(chatId, messageData);
    
  } catch (e) {
    developer.log('❌ Error moving chat to top with mutual check: $e');
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

  Future<void> _updateUnreadCountWithFollowFilter(String chatId, String otherUserId) async {
  if (chatId.isEmpty) return;

  try {
    initializeBadgeForChat(chatId);
    
    // Get other user data to check follow status
    final otherUserDoc = await FirebaseService.getUserById(otherUserId);
    if (!otherUserDoc.exists) {
      developer.log('⚠️ Other user not found: $otherUserId');
      return;
    }
    
    final otherUserData = otherUserDoc.data() as Map<String, dynamic>;
    
    // Check if user is mutual follower
    if (!isMutualFollower(otherUserData)) {
      developer.log('🚫 Skipping badge count for non-mutual follower: $otherUserId');
      // Clear any existing badge for this non-mutual user
      chatBadges[chatId]?.value = 0;
      unreadCounts[chatId] = 0;
      updateTotalUnreadBadges();
      return;
    }
    
    // Listen to unread message count only for mutual followers
    FirebaseService.getUnreadMessageCount(chatId, currentUserId.value).listen(
      (snapshot) {
        final count = snapshot.docs.length;
        
        // Double-check: verify each unread message is from a mutual follower
        int validUnreadCount = 0;
        for (var doc in snapshot.docs) {
          final messageData = doc.data() as Map<String, dynamic>;
          final senderId = messageData['senderId']?.toString() ?? '';
          
          // Only count if sender is the mutual follower we're checking
          if (senderId == otherUserId) {
            validUnreadCount++;
          }
        }
        
        // Update local cache
        unreadCounts[chatId] = validUnreadCount;
        
        // Update reactive badge count
        chatBadges[chatId]!.value = validUnreadCount;
        
        // Update total unread badges
        updateTotalUnreadBadges();
        
        // Trigger animation if count increased
        if (validUnreadCount > 0) {
          _animateNewBadge(chatId);
          chatList.refresh();
        }
        
        developer.log('📊 Badge updated for mutual follower chat $chatId: $validUnreadCount unread messages');
      },
      onError: (error) {
        developer.log('❌ Error updating badge count: $error');
      },
    );
  } catch (e) {
    developer.log('❌ Error updating unread count with follow filter: $e');
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
          backgroundColor: Colors.orange.withAlpha(80),
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
        backgroundColor: Colors.red.withAlpha(80),
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
        backgroundColor: Colors.red.withAlpha(80),
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
        backgroundColor: Colors.red.withAlpha(80),
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

  // Validate receiver exists and is mutual follower
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
        receiverUser['_id'] = receiverId;
        userCache[receiverId] = receiverUser;
      } else {
        developer.log('Error: Receiver user not found: $receiverId');
        Get.snackbar(
          'Error',
          'Recipient user not found. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withAlpha(80),
          colorText: Colors.white,
        );
        return;
      }
    } catch (e) {
      developer.log('Error validating receiver: $e');
      return;
    }
  }

  final chatId = FirebaseService.generateChatId(currentUserId.value, receiverId);
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
  await _handleOutgoingMessage(chatId, tempMessage);

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

    animateFab();

    developer.log('Message sent successfully and chat moved to top: ${sentMessageRef.id}');
  } catch (e) {
    // Remove failed message
    messages.removeWhere((msg) => msg['id'] == tempMessageId);
    messageStatuses.remove(tempMessageId);

    developer.log('Error sending message: $e');
    Get.snackbar(
      'Error',
      'Failed to send message. Please try again.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withAlpha(80),
      colorText: Colors.white,
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

  //@override
void navigateToChat(Map<String, dynamic> user) async {
  try {
    // Check if user is mutual follower (sync first for speed)
    bool canChat = isMutualFollower(user);

    if (!canChat) {
      // Try fresh API check if cache check fails
      developer.log('🔄 Verifying follow status with fresh API check...');
      canChat = await isMutualFollowerAsync(user, forceRefresh: true);
      
      if (canChat) {
        // Update user data with fresh API data if needed
        final email = user['email']?.toString();
        if (email != null) {
          final freshStatus = await followStatusManager.checkFollowStatus(email);
          if (freshStatus != null && freshStatus['isMutualFollow'] == true) {
            final apiUserData = freshStatus['user'] as Map<String, dynamic>;
            user['name'] = apiUserData['name'];
            user['picture'] = apiUserData['picture'];
            user['apiPictureUrl'] = 'http://182.93.94.210:3067${apiUserData['picture']}';
            user['isMutualFollow'] = true;
          }
        }
      }
    }

    if (!canChat) {
      Get.snackbar(
        'Cannot Chat',
        'You can only chat with users you mutually follow',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withAlpha(80),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.people_outline, color: Colors.white),
      );
      return;
    }

    // Generate chat ID and clear badges BEFORE navigation
    final receiverId = user['userId']?.toString() ?? 
                      user['_id']?.toString() ?? 
                      user['id']?.toString() ?? '';
    
    if (receiverId.isNotEmpty) {
      final chatId = generateChatId(currentUserId.value, receiverId);
      
      // IMPORTANT: Clear badge when opening chat
      clearBadgeForChat(chatId);
      
      // Create mock message data for moving to top (since we're opening the chat)
      final mockMessageData = {
        'chatId': chatId,
        'senderId': currentUserId.value,
        'receiverId': receiverId,
        'message': 'Chat opened',
        'senderName': currentUser.value?['name']?.toString() ?? 'User',
        'timestamp': Timestamp.now(),
        'messageType': 'system',
        'id': 'system_${DateTime.now().millisecondsSinceEpoch}',
      };
      
      // Move to top when opening chat
      await _moveLocalChatToTop(chatId, mockMessageData);
      
      // Add user to recent
      addUserToRecent(user);
      
      // Navigate to chat
      navigateToChatEnhanced(user);
      
      developer.log('✅ Chat opened and moved to top: $chatId');
    }
    
  } catch (e) {
    developer.log('❌ Error in navigation: $e');
   
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
  void setupFirebaseAuthListener() {
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user != null) {
      developer.log('🔥 Firebase Auth state changed: ${user.uid}');
      // Reload users when auth state changes
      if (allUsers.isEmpty) {
        loadAllUsersWithSmartCaching();
      }
    } else {
      developer.log('🔥 Firebase Auth signed out');
    }
  });
}

Future<void> loadAllUsersWithSmartCaching() async {
  try {
    developer.log('📱 Loading all users with smart caching and follow status filtering...');
    isLoadingUsers.value = true;
    isLoadingFollowStatus.value = true;
    loadingStatusText.value = 'Loading mutual followers...';
    
    // Check Firebase Auth status
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      developer.log('⚠️ No Firebase Auth user - some features may be limited');
    } else {
      developer.log('✅ Firebase Auth user: ${firebaseUser.uid}');
    }
    
    // Step 1: Load users from Firestore
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .orderBy('name')
        .get()
        .timeout(const Duration(seconds: 30));
    
    developer.log('📱 Firestore query completed: ${usersSnapshot.docs.length} users found');
    loadingStatusText.value = 'Checking follow status...';
    
    // Step 2: Prepare user list and emails for follow status check
    final firestoreUsers = <Map<String, dynamic>>[];
    final emails = <String>[];
    
    for (var doc in usersSnapshot.docs) {
      if (doc.id != currentUserId.value) {
        final userData = Map<String, dynamic>.from(doc.data());
        userData['id'] = doc.id;
        userData['userId'] = doc.id;
        userData['_id'] = doc.id;
        
        firestoreUsers.add(userData);
        
        final email = userData['email']?.toString();
        if (email != null && email.isNotEmpty) {
          emails.add(email);
        }
      }
    }
    
    // Step 3: Batch check follow statuses
    developer.log('👥 Batch checking follow status for ${emails.length} users...');
    final followResults = await followStatusManager.batchCheckFollowStatus(emails);
    
    // Step 4: Filter and enhance users with mutual follow status
    final mutualFollowers = <Map<String, dynamic>>[];
    
    for (final user in firestoreUsers) {
      final email = user['email']?.toString();
      if (email != null) {
        final followStatus = followResults[email];
        if (followStatus != null && followStatus['isMutualFollow'] == true) {
          // Enhance user data with API info
          final apiUserData = followStatus['user'] as Map<String, dynamic>;
          final enhancedUser = {
            ...user, // Keep Firestore data (for chat functionality)
            'name': apiUserData['name'] ?? user['name'], // Use API name if available
            'picture': apiUserData['picture'],
            'apiPictureUrl': apiUserData['picture'] != null 
                ? 'http://182.93.94.210:3067${apiUserData['picture']}' 
                : null,
            'isFollowing': followStatus['isFollowing'],
            'isFollowedBy': followStatus['isFollowedBy'],
            'isMutualFollow': true,
          };
          
          mutualFollowers.add(enhancedUser);
          
          // Update cache
          userCache[user['_id']] = enhancedUser;
        }
      }
    }
    
    // Step 5: CRITICAL FIX - Update users list properly
    developer.log('📊 Before assignment - allUsers length: ${allUsers.length}');
    
    // Clear and reassign to trigger UI update
    allUsers.clear();
    allUsers.addAll(mutualFollowers);
    
    // Force refresh the reactive list
    allUsers.refresh();
    
    _usersInitialized.value = true; // Mark as initialized
    
    developer.log('✅ After assignment - allUsers length: ${allUsers.length}');
    developer.log('✅ Loaded ${mutualFollowers.length} mutual followers (filtered from ${firestoreUsers.length} total users)');
    loadingStatusText.value = 'Complete!';
    
    // Debug: Log first few users to verify data
    if (allUsers.isNotEmpty) {
      developer.log('🔍 Sample user data:');
      for (int i = 0; i < (allUsers.length > 3 ? 3 : allUsers.length); i++) {
        developer.log('User ${i + 1}: ${allUsers[i]['name']} - ${allUsers[i]['email']}');
      }
    }
    
  } catch (e) {
    developer.log('❌ Error loading users with smart caching and follow filter: $e');
    loadingStatusText.value = 'Error loading users';
    
    // Fallback: Try to load without follow filter (emergency fallback)
    try {
      await _loadUsersWithoutFollowFilter();
    } catch (fallbackError) {
      developer.log('❌ Fallback loading also failed: $fallbackError');
      
      // Show user-friendly error
      // Get.snackbar(
      //   'Loading Error', 
      //   'Failed to load users. Please check your connection and try again.',
      //   snackPosition: SnackPosition.BOTTOM,
      //   backgroundColor: Colors.red.withAlpha(0.8),
      //   colorText: Colors.white,
      //   duration: const Duration(seconds: 3),
      // );
    }
  } finally {
    isLoadingUsers.value = false;
    isLoadingFollowStatus.value = false;
    
    // Clear loading text after delay
    Future.delayed(const Duration(seconds: 1), () {
      loadingStatusText.value = '';
    });
  }
}

Future<void> _loadUsersWithoutFollowFilter() async {
  try {
    developer.log('⚠️ Loading users without follow filter (emergency fallback)...');
    
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .orderBy('name')
        .get()
        .timeout(const Duration(seconds: 15));
    
    final users = <Map<String, dynamic>>[];
    for (var doc in usersSnapshot.docs) {
      if (doc.id != currentUserId.value) {
        final userData = Map<String, dynamic>.from(doc.data());
        userData['id'] = doc.id;
        userData['userId'] = doc.id;
        userData['_id'] = doc.id;
        
        users.add(userData);
        userCache[doc.id] = userData;
      }
    }
    
    allUsers.assignAll(users);
    developer.log('⚠️ Emergency fallback: Loaded ${users.length} users without follow filtering');
  } catch (e) {
    developer.log('❌ Emergency fallback failed: $e');
    throw e;
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

  Future<void> refreshBadgeSystemWithFollowFilter() async {
  try {
    developer.log('🔄 Refreshing badge system with follow filter...');
    
    // Step 1: Clear all current badges
    clearAllBadges();
    
    // Step 2: Reload chats with proper filtering
    await loadUserChats();
    
    // Step 3: Clean up any remaining non-mutual follower badges
    await cleanupNonMutualFollowerBadges();
    
    developer.log('✅ Badge system refreshed with follow filter');
  } catch (e) {
    developer.log('❌ Error refreshing badge system: $e');
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
                          'http://182.93.94.210:3067${apiUserData['picture']}',
                      'isMutualFollow': true,
                    };
                  }
                }

                chatData['otherUser'] = otherUser;
                chats.add(chatData);

                final chatId = chatData['chatId'] ?? '';
                _updateUnreadCountWithFollowFilter(chatId, otherUserId);

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
        await loadAllUsersWithSmartCaching();

     if (isLoadingChats.value || currentUserId.value.isEmpty) return;

  isLoadingChats.value = true;
  try {
    developer.log('💬 Loading chats with filtered badges...');

    FirebaseService.getUserChats(currentUserId.value).listen((snapshot) async {
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
          // Get user from cache first (which includes follow status)
          Map<String, dynamic>? otherUser = userCache[otherUserId];
          
          if (otherUser == null) {
            // Get from Firestore if not in cache
            try {
              final userDoc = await FirebaseService.getUserById(otherUserId);
              if (userDoc.exists) {
                otherUser = Map<String, dynamic>.from(
                  userDoc.data() as Map<String, dynamic>,
                );
                otherUser['id'] = otherUserId;
                otherUser['userId'] = otherUserId;
                otherUser['_id'] = otherUserId;
                
                // Check follow status for this user
                final email = otherUser['email']?.toString();
                if (email != null) {
                  final followStatus = await followStatusManager.checkFollowStatus(email);
                  if (followStatus != null && followStatus['isMutualFollow'] == true) {
                    // Enhance with API data
                    final apiUserData = followStatus['user'] as Map<String, dynamic>;
                    otherUser = {
                      ...otherUser,
                      'name': apiUserData['name'],
                      'picture': apiUserData['picture'],
                      'apiPictureUrl': 'http://182.93.94.210:3067${apiUserData['picture']}',
                      'isMutualFollow': true,
                    };
                    userCache[otherUserId] = otherUser;
                  } else {
                    // Not a mutual follower, skip this chat
                    continue;
                  }
                }
              }
            } catch (e) {
              developer.log('Error loading user $otherUserId: $e');
              continue;
            }
          }

          // Only include chats with mutual followers
          if (otherUser != null && (otherUser['isMutualFollow'] == true || isMutualFollower(otherUser))) {
            chatData['otherUser'] = otherUser;
            chats.add(chatData);

            final chatId = chatData['chatId'] ?? '';
            initializeBadgeForChat(chatId);
            
            // CRITICAL: Use filtered badge counting for mutual followers only
            _updateUnreadCountWithFollowFilter(chatId, otherUserId);
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
      updateTotalUnreadBadges();
      
      // Clean up any remaining badges from non-mutual followers
      await cleanupNonMutualFollowerBadges();
      
      developer.log('✅ Loaded ${chats.length} chats with filtered badges (mutual followers only)');
    });
  } catch (e) {
    isLoadingChats.value = false;
    developer.log('❌ Error loading chats with filtered badges: $e');
  }
  }

  @override
  Future<void> searchUsers(String query) async {
  if (query.trim().isEmpty) {
    searchResults.clear();
    return;
  }

  isSearching.value = true;
  try {
    developer.log('🔍 Searching users with follow status validation: $query');

    // First, search in cached mutual followers
    final cachedResults = _searchInMutualFollowers(query);
    
    if (cachedResults.isNotEmpty) {
      searchResults.assignAll(cachedResults);
      developer.log('✅ Found ${cachedResults.length} mutual followers in cache');
    } else {
      // Perform broader search and validate follow status
      await _performSearchWithFollowCheck(query);
    }
    
  } catch (e) {
    developer.log('❌ Error searching with follow validation: $e');
    Get.snackbar(
      'Search Error',
      'Failed to search users. Please try again.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withAlpha(80),
      colorText: Colors.white,
    );
  } finally {
    isSearching.value = false;
  }
}

// Search in cached mutual followers
Future<void> refreshUsersWithFollowStatus() async {
  try {
    developer.log('🔄 Refreshing users with follow status...');
    
    // Clear caches to force fresh data
    userCache.clear();
    followStatusManager.clearCache();
    
    // Reset initialization flag to allow reload
    _usersInitialized.value = false;
    
    // Clear current list to show loading state
    allUsers.clear();
    
    // Reload with fresh data
    await loadAllUsersWithSmartCaching();
    
    developer.log('✅ Users refreshed with follow status');
  } catch (e) {
    developer.log('❌ Error refreshing users with follow status: $e');
    
    Get.snackbar(
      'Refresh Failed',
      'Unable to refresh users. Please try again.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withAlpha(80),
      colorText: Colors.white,
    );
  }
}

  // Enhanced refresh with cache clearing
  @override
  Future<void> refreshUsersAndCache() async {
  await refreshUsersWithFollowStatus();
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
  
  // First check if user data already has follow status
  if (user['isMutualFollow'] == true) {
    return true;
  }
  
  // Fallback to followStatusManager
  return followStatusManager.isMutualFollower(user);
}

Future<bool> isMutualFollowerAsync(Map<String, dynamic>? user, {bool forceRefresh = false}) async {
  if (user == null) return false;
  
  return await followStatusManager.isMutualFollowerAsync(user, forceRefresh: forceRefresh);
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
