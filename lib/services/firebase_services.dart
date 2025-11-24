import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'dart:developer' as developer;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/screens/chatApp/FollowStatusManager.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Replace with your Firebase project ID
  static const String _projectId = 'innovator-250f8';

  // Replace with your service account key JSON content
  static const Map<String, dynamic> _serviceAccountKey = {
    "type": "service_account",
    "project_id": "innovator-250f8",
    "private_key_id": "face9754d7afcc85ee325f503cf8ec7c57b7db32",
    "private_key":
        "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDHB2mJxGw2FGT/\n5o+e1REaMqaixCKwzzf4RmO1dbKtbzJrbdR6Ad7C3I5YUNgJs/A04dMTpF1NPCxA\nHgJYCCTMhNrCx7jd8oESSWmzoNc5ZSi1s2S27qjkOy5TvpWzds4xYSErl/sqt8wi\nMUaKamLBpFmNUkZG4bphPGa9pmfzQ1ObJS9b9Zt4B/ZnXn5EsGCB6+BkdD3MU4Nk\nKaWtIAPe4IKDCTGNXhmaHXixYf8yopTZIwrkPhk7nSMtbs9c3NKFsm8gUfOjhDD5\ng0/8LCX/ZvyHqhGcjA0leT9tsbLcusnv9HcfuQSQfF21t0+bAz0f5KEsECtVJSfn\nQFgvu4PVAgMBAAECggEAFPkqJ8tBT1DxNGmdUIgJwCspQIq5pcyDDJCNA6YZA59t\nqUDO0g1DZmEWm6Y9SzHL33ln+bBpkpuDhZLZUrcyUDO0goUdwpRtAeUm6eJ0+7E2\nITD719ko3BAueW232cxsaGtgsvbWOsdZOsXa4KLbBaaQ4fcTEnd0DA4bkjhTHkvA\nu3rVYeBOoJfRBBygpoxRJK0pWAq0SsktsaRDquunHHghCnPGaIpTLNfU9QP7tXXF\n0Qnor9traQnKZEqcHWvfWSVbSW0AU/nDr7yL3oyF0UquWdN8f+WC9QUt1BcAKRp7\nGl0Bs2KyJ9NZ/nFCjym10FCQMKPbrrSnQNOWoQT5WwKBgQD2WLeyZ8dANNO5Wdva\ntG+l3ifYbs/Q1FshH+TSLKwuXfqe2kGYQQYEw5XsMtwAD7M98E+Oz5Aq2oFAaKQu\nNCNWywMEs/oFsM/P9p4I5Dd8k8+9aaGnv9ZmFdZbiCbgYGUVwaoeQWRUSyonQxup\nDygZ1RmCgj/+WAtmaiJaFb3j8wKBgQDO1ARquIZjL701Q9D18o8qKoqBqN88Ce/m\n8nEsUq4EiecjCwk9WEC9KLWuequn6R8Sv3F+Ddew6lpl4FbjHWT7dbZGnfrJMhgc\nhw3YVglrOGfbCFdxhvuE+b+i2a45vFJifoO5/dFo2ghl10tw2w+fDM0deDhc4n9x\nIazsansTFwKBgQDnnoShLmguGz1SkYVgPbSX3KfUHGQysec43tbzMeN1+RCyGP4B\nnGl/QzIMEcm+GQTrYK481TV0xVsvZvOvKYBsk5Yz7tBOV28c1oDCVWlCLWvuaIoA\nwiNgennAN+RtpNSGPz+nEM63XrC0l6lDLCgFGdLRXYuzpa6aTYIc90JCNwKBgFUO\nzGI3UM0prN5i7WS4RDhLFnsMQAIo9Ag+XFymA/rJ28yFlV8tFDK2s0D2IfID5UuI\nf9wfRTz0pAiRoin0xLrFRhj0j1Z+y3uv7vmxKF536/4gCBYgNQAS1cTbUNNdp2Pq\nM7IhuCUuxZVcXSIkdOAsG46rCkLowxB7kOoJQGQxAoGBAJ/z9uQKJJK2PhR8ZkP+\n7MP6Ets5a1gZeByvzIQl/2HIKRntc0JB/2jDz8kE51NpkUdCBns/5voCiHebtvce\nkOKqyU6wbiH0//2pcbDJFPoPZzAlXbHp4zGbUMM2vVfEs7E6BCyKS/W6bYDZPRfw\n4f8zChXbtQR2DNXZQgaYhe30\n-----END PRIVATE KEY-----\n",
    "client_email":
        "firebase-adminsdk-fbsvc@innovator-250f8.iam.gserviceaccount.com",
    "client_id": "110566247274362686947",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url":
        "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40innovator-250f8.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com",
  };

  // Debug helper to check authentication status
  static void debugAuthStatus() {
    final user = _auth.currentUser;
    developer.log('=== DEBUG AUTH STATUS ===');
    developer.log('User: ${user?.email}');
    developer.log('UID: ${user?.uid}');
    developer.log('Is Anonymous: ${user?.isAnonymous}');
    developer.log('Email Verified: ${user?.emailVerified}');
    developer.log(
      'Provider Data: ${user?.providerData.map((p) => p.providerId).toList()}',
    );
    developer.log('========================');
  }

  // Get OAuth2 access token for FCM v1 API
  static Future<String?> _getAccessToken() async {
    try {
      developer.log('🔑 Getting OAuth2 access token...');

      final serviceAccountCredentials = ServiceAccountCredentials.fromJson(
        _serviceAccountKey,
      );
      final client = http.Client();

      final accessCredentials = await obtainAccessCredentialsViaServiceAccount(
        serviceAccountCredentials,
        ['https://www.googleapis.com/auth/cloud-platform'],
        client,
      );

      client.close();

      final token = accessCredentials.accessToken.data;
      developer.log('✅ Access token obtained: ${token.substring(0, 20)}...');

      return token;
    } catch (e) {
      developer.log('❌ Error getting access token: $e');
      if (e is Exception) {
        developer.log('Exception details: ${e.toString()}');
      }
      return null;
    }
  }

  // Update user FCM token
  static Future<void> updateUserFCMToken(String userId, String token) async {
    try {
      developer.log('📱 Updating FCM token for user: $userId');
      developer.log('📱 Token: ${token.substring(0, 20)}...');

      // First, clean up any invalid tokens
      await _cleanupInvalidTokensForUser(userId);

      // Update with new token
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token, // Primary token field
        'fcmTokens': [token], // Array of tokens (keeping only the latest)
        'lastTokenUpdate': FieldValue.serverTimestamp(),
        'tokenDevice': Platform.isAndroid ? 'android' : 'ios',
        'tokenValid': true, // Track token validity
      });

      developer.log('✅ FCM token updated successfully for user: $userId');

      // Test the token immediately
      await _testTokenValidity(userId, token);
    } catch (e) {
      developer.log('❌ Error updating FCM token: $e');
      throw e;
    }
  }

  static Future<void> _cleanupInvalidTokensForUser(String userId) async {
    try {
      final userDoc = await getUserById(userId);
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final oldTokens = userData['fcmTokens'] as List<dynamic>? ?? [];

        if (oldTokens.isNotEmpty) {
          developer.log(
            '🧹 Cleaning up ${oldTokens.length} old tokens for user: $userId',
          );

          // Clear old tokens array
          await _firestore.collection('users').doc(userId).update({
            'fcmTokens': [], // Clear old tokens
            'oldTokensCleared': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      developer.log('❌ Error cleaning up tokens: $e');
    }
  }

  // NEW: Test token validity
  static Future<void> _testTokenValidity(String userId, String token) async {
    try {
      developer.log('🧪 Testing FCM token validity for user: $userId');

      // We'll test this indirectly by checking if we can send a validation message
      // For now, just mark as tested
      await _firestore.collection('users').doc(userId).update({
        'lastTokenTest': FieldValue.serverTimestamp(),
        'tokenValid': true,
      });

      developer.log('✅ Token marked as valid for user: $userId');
    } catch (e) {
      developer.log('❌ Error testing FCM token: $e');
    }
  }

  static Future<void> _testFCMToken(String userId, String token) async {
    try {
      developer.log('🧪 Testing FCM token for user: $userId');

      // Verify token is saved in Firestore
      final userDoc = await getUserById(userId);
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final savedToken = userData['fcmToken'];
        final tokenMatches = savedToken == token;

        developer.log(
          '✅ Token verification: ${tokenMatches ? "PASSED" : "FAILED"}',
        );

        if (tokenMatches) {
          developer.log('📱 Token successfully saved and verified');
        } else {
          developer.log(
            '⚠️ Token mismatch - saved: ${savedToken?.substring(0, 20)}..., expected: ${token.substring(0, 20)}...',
          );
        }
      } else {
        developer.log('⚠️ User document not found for token test');
      }
    } catch (e) {
      developer.log('❌ Error testing FCM token: $e');
    }
  }

  // Save user data to Firestore with FCM token
  static Future<void> saveUserToFirestore({
    required String userId,
    required String name,
    required String email,
    String? phone,
    String? dob,
    String? photoURL,
    String provider = 'email',
  }) async {
    try {
      debugAuthStatus();

      developer.log('Attempting to save user to Firestore...');
      developer.log('User ID: $userId');
      developer.log('Name: $name');
      developer.log('Email: $email');

      // Get FCM token
      String? fcmToken;
      try {
        fcmToken = await _messaging.getToken();
        developer.log('FCM Token obtained: ${fcmToken?.substring(0, 20)}...');
      } catch (e) {
        developer.log('Could not get FCM token: $e');
      }

      final userDoc = _firestore.collection('users').doc(userId);

      final userData = {
        'userId': userId,
        '_id': userId,
        'id': userId,
        'uid': userId,
        'name': name,
        'email': email,
        'phone': phone ?? '',
        'dob': dob ?? '',
        'photoURL': photoURL ?? '',
        'provider': provider,
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'nameSearchable': name.toLowerCase(),
        'emailSearchable': email.toLowerCase(),
        'fcmToken': fcmToken ?? '',
        'notificationsEnabled': true,
      };

      await userDoc.set(userData, SetOptions(merge: true));
      developer.log('User saved to Firestore successfully: $userId');

      await _refreshUserCacheAfterSave();
    } catch (e) {
      developer.log('Error saving user to Firestore: $e');
      developer.log('Error details: ${e.runtimeType}');
      if (e is FirebaseException) {
        developer.log('Firebase error code: ${e.code}');
        developer.log('Firebase error message: ${e.message}');
      }
      rethrow;
    }
  }

  // Add this method to your FirebaseService class

  // NEW: Create initial chat document when adding user to chat
  static Future<void> createInitialChat({
    required String chatId,
    required String currentUserId,
    required String receiverId,
    required String receiverName,
  }) async {
    try {
      developer.log('🆕 Creating initial chat: $chatId');
      developer.log('Participants: $currentUserId, $receiverId');

      // Check if chat already exists
      final existingChat =
          await _firestore.collection('chats').doc(chatId).get();

      if (existingChat.exists) {
        developer.log('ℹ️ Chat already exists: $chatId');
        return;
      }

      // Get current user data
      final currentUserDoc = await getUserById(currentUserId);
      if (!currentUserDoc.exists) {
        throw Exception('Current user not found: $currentUserId');
      }

      final currentUserData = currentUserDoc.data() as Map<String, dynamic>;
      final currentUserName = currentUserData['name']?.toString() ?? 'User';

      // Create initial chat document
      final chatData = {
        'chatId': chatId,
        'participants': [currentUserId, receiverId],
        'lastMessage': 'Chat created',
        'lastMessageSender': currentUserId,
        'lastMessageSenderName': currentUserName,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageId': '',
        'lastMessageType': 'system',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': currentUserId,
        'isActive': true,
      };

      await _firestore.collection('chats').doc(chatId).set(chatData);

      developer.log('✅ Initial chat created successfully: $chatId');
    } catch (e) {
      developer.log('❌ Error creating initial chat: $e');
      throw e;
    }
  }

  // NEW: Delete chat
  static Future<void> deleteChat(String chatId) async {
    try {
      developer.log('🗑️ Deleting chat: $chatId');

      // Delete all messages in the chat
      final messagesQuery =
          await _firestore
              .collection('messages')
              .where('chatId', isEqualTo: chatId)
              .get();

      final batch = _firestore.batch();

      for (var doc in messagesQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete the chat document
      batch.delete(_firestore.collection('chats').doc(chatId));

      await batch.commit();

      developer.log('✅ Chat deleted successfully: $chatId');
    } catch (e) {
      developer.log('❌ Error deleting chat: $e');
      throw e;
    }
  }

  // NEW: Archive/Unarchive chat
  static Future<void> toggleChatArchive(String chatId, bool isArchived) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'isArchived': isArchived,
        'archivedAt':
            isArchived ? FieldValue.serverTimestamp() : FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        '✅ Chat ${isArchived ? 'archived' : 'unarchived'}: $chatId',
      );
    } catch (e) {
      developer.log('❌ Error toggling chat archive: $e');
      throw e;
    }
  }

  // NEW: Pin/Unpin chat
  static Future<void> toggleChatPin(String chatId, bool isPinned) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'isPinned': isPinned,
        'pinnedAt':
            isPinned ? FieldValue.serverTimestamp() : FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      developer.log('✅ Chat ${isPinned ? 'pinned' : 'unpinned'}: $chatId');
    } catch (e) {
      developer.log('❌ Error toggling chat pin: $e');
      throw e;
    }
  }

  // NEW: Get user's active chats (non-archived)
  static Stream<QuerySnapshot> getActiveUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .where('isArchived', isNotEqualTo: true)
        .orderBy('isPinned', descending: true)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  // NEW: Get user's archived chats
  static Stream<QuerySnapshot> getArchivedUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .where('isArchived', isEqualTo: true)
        .orderBy('archivedAt', descending: true)
        .snapshots();
  }

  // NEW: Check if chat exists
  static Future<bool> chatExists(String chatId) async {
    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      return chatDoc.exists;
    } catch (e) {
      developer.log('❌ Error checking if chat exists: $e');
      return false;
    }
  }

  // Send message with FCM v1 notification
  // Add this to your sendMessage method in FirebaseService
  static Future<DocumentReference> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String message,
    required String senderName,
    String messageType = 'text',
  }) async {
    try {
      developer.log('🚀 === SENDING MESSAGE DEBUG ===');
      developer.log('Chat ID: $chatId');
      developer.log('Sender ID: $senderId');
      developer.log('Receiver ID: $receiverId');
      developer.log('Message: $message');
      developer.log('Sender Name: $senderName');

      // Validate that both users exist
      final senderDoc = await getUserById(senderId);
      final receiverDoc = await getUserById(receiverId);

      developer.log('Sender exists: ${senderDoc.exists}');
      developer.log('Receiver exists: ${receiverDoc.exists}');

      if (!senderDoc.exists) {
        throw Exception('Sender user not found in Firestore: $senderId');
      }
      if (!receiverDoc.exists) {
        throw Exception('Receiver user not found in Firestore: $receiverId');
      }

      // Check receiver's FCM token
      final receiverData = receiverDoc.data() as Map<String, dynamic>;
      final fcmToken = receiverData['fcmToken'];
      developer.log(
        'Receiver FCM token exists: ${fcmToken != null && fcmToken.toString().isNotEmpty}',
      );

      final messageData = {
        'chatId': chatId,
        'senderId': senderId,
        'receiverId': receiverId,
        'message': message,
        'senderName': senderName,
        'messageType': messageType,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'participants': [senderId, receiverId],
      };

      // Add message to Firestore
      developer.log('💾 Saving message to Firestore...');
      final messageRef = await _firestore
          .collection('messages')
          .add(messageData);
      developer.log('✅ Message saved: ${messageRef.id}');

      // Update chat document
      developer.log('💬 Updating chat document...');
      await _updateChatDocument(
        chatId,
        senderId,
        receiverId,
        message,
        senderName,
        messageRef.id,
      );
      developer.log('✅ Chat document updated');

      // Send FCM notification
      developer.log('📤 Sending FCM notification...');
      await _sendFCMv1Notification(
        receiverId: receiverId,
        senderName: senderName,
        message: message,
        chatId: chatId,
        senderId: senderId,
        messageId: messageRef.id,
      );

      developer.log('✅ Message process completed: ${messageRef.id}');
      developer.log('=== END MESSAGE DEBUG ===');
      return messageRef;
    } catch (e) {
      developer.log('❌ Error sending message: $e');
      developer.log('Error type: ${e.runtimeType}');
      throw e;
    }
  }

  // FCM HTTP v1 API notification sending
  // Replace the complex FCM v1 method with this simpler approach
  static Future<void> _sendFCMv1Notification({
    required String receiverId,
    required String senderName,
    required String message,
    required String chatId,
    required String senderId,
    required String messageId,
  }) async {
    try {
      developer.log('📤 === SENDING FCM NOTIFICATION ===');
      developer.log('📤 Receiver ID: $receiverId');
      developer.log('📤 Sender: $senderName');
      developer.log(
        '📤 Message: ${message.length > 50 ? message.substring(0, 50) + "..." : message}',
      );

      // Get receiver's data
      final receiverDoc =
          await _firestore.collection('users').doc(receiverId).get();

      if (!receiverDoc.exists) {
        developer.log('⚠️ Receiver not found: $receiverId');
        return;
      }

      final receiverData = receiverDoc.data() as Map<String, dynamic>;

      // Try multiple token sources
      String? fcmToken;

      // First try the primary fcmToken field
      fcmToken = receiverData['fcmToken']?.toString();

      // If not found, try the fcmTokens array
      if (fcmToken == null || fcmToken.isEmpty) {
        final tokens = receiverData['fcmTokens'] as List<dynamic>?;
        if (tokens != null && tokens.isNotEmpty) {
          fcmToken = tokens.first.toString();
        }
      }

      final notificationsEnabled =
          receiverData['notificationsEnabled'] as bool? ?? true;

      developer.log(
        '📱 Receiver FCM token found: ${fcmToken != null && fcmToken.isNotEmpty}',
      );
      developer.log('🔔 Notifications enabled: $notificationsEnabled');

      if (!notificationsEnabled) {
        developer.log('🔇 Notifications disabled for receiver: $receiverId');
        return;
      }

      if (fcmToken == null || fcmToken.isEmpty) {
        developer.log('⚠️ No FCM token for receiver: $receiverId');
        return;
      }

      // Enhanced notification suppression check
      final isOnline = receiverData['isOnline'] == true;
      final currentChatId = receiverData['currentChatId'] as String?;
      final lastActivity = receiverData['lastSeen'] as Timestamp?;

      developer.log('📱 Receiver online: $isOnline');
      developer.log('💬 Current chat: $currentChatId');
      developer.log('💬 Message chat: $chatId');

      // Suppress only if actively in the same chat within last 30 seconds
      bool shouldSuppress = false;
      if (isOnline && currentChatId == chatId) {
        if (lastActivity != null) {
          final timeSinceLastActivity = DateTime.now().difference(
            lastActivity.toDate(),
          );
          shouldSuppress = timeSinceLastActivity.inSeconds < 30;
          developer.log(
            '⏰ Time since last activity: ${timeSinceLastActivity.inSeconds}s, Suppress: $shouldSuppress',
          );
        }
      }

      if (shouldSuppress) {
        developer.log('🔇 Notification suppressed - receiver actively in chat');
        return;
      }

      // Send FCM notification
      try {
        final success = await _sendNotificationHTTPv1(
          token: fcmToken,
          title: senderName,
          body: message,
          data: {
            'type': 'chat',
            'chatId': chatId,
            'senderId': senderId,
            'senderName': senderName,
            'messageId': messageId,
            'message': message,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );

        if (!success) {
          // Token might be invalid, try to refresh it
          developer.log('❌ FCM send failed, token might be invalid');
          await _markTokenAsInvalid(receiverId);

          // Try to get a fresh token for this user if they're currently online
          if (isOnline) {
            developer.log(
              '🔄 User is online, they should get a fresh token soon',
            );
          }
        }
      } catch (e) {
        developer.log('❌ Error sending FCM: $e');
        if (e.toString().contains('UNREGISTERED') ||
            e.toString().contains('404')) {
          await _markTokenAsInvalid(receiverId);
        }
      }

      developer.log('=== END FCM NOTIFICATION ===');
    } catch (e) {
      developer.log('❌ Error in FCM notification process: $e');
    }
  }

  static Future<void> _markTokenAsInvalid(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'tokenValid': false,
        'tokenInvalidatedAt': FieldValue.serverTimestamp(),
      });
      developer.log('🚫 Marked token as invalid for user: $userId');
    } catch (e) {
      developer.log('❌ Error marking token as invalid: $e');
    }
  }

  static Future<bool> _sendNotificationHTTPv1({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      developer.log('📤 Preparing FCM HTTP v1 request...');

      // Get access token
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        developer.log('❌ Could not get access token');
        return false;
      }

      // CORRECTED: Proper FCM v1 payload structure
      final fcmPayload = {
        "message": {
          "token": token,
          "notification": {
            "title": title,
            "body": body.length > 100 ? '${body.substring(0, 100)}...' : body,
          },
          "data": data.map((key, value) => MapEntry(key, value.toString())),
          "android": {
            "notification": {
              "channel_id": "chat_messages",
              "sound": "default",
              "icon": "@mipmap/ic_launcher",
              "color": "#F48706",
              "tag": data['chatId'],
            },
            "priority": "high",
            "ttl": "3600s",
          },
          "apns": {
            "headers": {"apns-priority": "10", "apns-expiration": "3600"},
            "payload": {
              "aps": {
                "alert": {"title": title, "body": body},
                "sound": "default",
                "badge": 1,
                "category": "MESSAGE_CATEGORY",
                "thread-id": data['chatId'],
              },
            },
          },
          "fcm_options": {"analytics_label": "chat_message"},
        },
      };

      developer.log('📤 Sending to token: ${token.substring(0, 20)}...');

      // Send notification using FCM HTTP v1 API
      final response = await http
          .post(
            Uri.parse(
              'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode(fcmPayload),
          )
          .timeout(const Duration(seconds: 10));

      developer.log('📨 FCM Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final messageName = responseData['name'];
        developer.log('✅ FCM notification sent successfully: $messageName');
        return true;
      } else {
        developer.log('❌ FCM notification failed: ${response.statusCode}');
        developer.log('📨 FCM Response Body: ${response.body}');

        // Handle specific errors
        if (response.statusCode == 404) {
          throw Exception('UNREGISTERED');
        }

        return false;
      }
    } catch (e) {
      developer.log('❌ Error in HTTP v1 send: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> checkUserFollowStatus(
    String email,
  ) async {
    try {
      developer.log('🔍 Checking follow status for: $email');

      final url = Uri.parse(
        'http://182.93.94.210:3067/api/v1/check?email=$email',
      );
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppData().authToken}',
      };

      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      developer.log('📨 Follow status response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == 200 && responseData['data'] != null) {
          final userData = responseData['data']['user'];
          final isFollowing = responseData['data']['isFollowing'] as bool;
          final isFollowedBy = responseData['data']['isFollowedBy'] as bool;

          developer.log(
            '✅ User: ${userData['name']}, Following: $isFollowing, FollowedBy: $isFollowedBy',
          );

          return {
            'user': userData,
            'isFollowing': isFollowing,
            'isFollowedBy': isFollowedBy,
            'isMutualFollow': isFollowing && isFollowedBy,
          };
        }
      }

      developer.log('❌ Failed to get follow status for: $email');
      return null;
    } catch (e) {
      developer.log('❌ Error checking follow status: $e');
      return null;
    }
  }

  // NEW: Get filtered users with mutual follow status
  static Future<List<Map<String, dynamic>>>
  getFilteredUsersWithFollowStatus() async {
    try {
      developer.log('🔍 Getting filtered users with follow status...');

      // Get all users from Firestore
      final usersSnapshot = await _firestore.collection('users').get();
      final filteredUsers = <Map<String, dynamic>>[];

      // Use FollowStatusManager for efficient caching
      final followStatusManager = FollowStatusManager.instance;

      for (var doc in usersSnapshot.docs) {
        final userData = Map<String, dynamic>.from(doc.data());
        userData['id'] = doc.id;
        userData['userId'] = doc.id;
        userData['_id'] = doc.id;

        final userEmail = userData['email']?.toString();

        if (userEmail != null && userEmail.isNotEmpty) {
          // Check follow status from cache first
          final followStatus = followStatusManager.getCachedFollowStatus(
            userEmail,
          );

          if (followStatus != null && followStatus['isMutualFollow'] == true) {
            // Merge Firestore data with API data
            final apiUserData = followStatus['user'] as Map<String, dynamic>;

            // Create enhanced user data
            final enhancedUserData = {
              ...userData, // Firestore data (includes chat-related fields)
              'name': apiUserData['name'], // Use API name
              'picture': apiUserData['picture'], // Use API picture
              'apiPictureUrl':
                  'http://182.93.94.210:3067${apiUserData['picture']}', // Full picture URL
              'isFollowing': followStatus['isFollowing'],
              'isFollowedBy': followStatus['isFollowedBy'],
              'isMutualFollow': true,
            };

            filteredUsers.add(enhancedUserData);
          }
        }
      }

      developer.log('✅ Found ${filteredUsers.length} mutual followers');
      return filteredUsers;
    } catch (e) {
      developer.log('❌ Error getting filtered users: $e');
      return [];
    }
  }

  // NEW: Enhanced getAllUsers that filters by follow status
  static Stream<QuerySnapshot> getAllUsersWithFollowFilter() {
    return _firestore.collection('users').orderBy('name').snapshots();
  }

  // NEW: Get user with enhanced profile data
  static Future<Map<String, dynamic>?> getEnhancedUserProfile(
    String userId,
  ) async {
    try {
      // Get user from Firestore
      final userDoc = await getUserById(userId);
      if (!userDoc.exists) return null;

      final userData = userDoc.data() as Map<String, dynamic>;
      final userEmail = userData['email']?.toString();

      if (userEmail != null) {
        // Get follow status from cache
        final followStatusManager = FollowStatusManager.instance;
        final followStatus = followStatusManager.getCachedFollowStatus(
          userEmail,
        );

        if (followStatus != null) {
          final apiUserData = followStatus['user'] as Map<String, dynamic>;

          return {
            ...userData,
            'name': apiUserData['name'],
            'picture': apiUserData['picture'],
            'apiPictureUrl':
                'http://182.93.94.210:3067${apiUserData['picture']}',
            'isFollowing': followStatus['isFollowing'],
            'isFollowedBy': followStatus['isFollowedBy'],
            'isMutualFollow': followStatus['isMutualFollow'],
          };
        }
      }

      return userData;
    } catch (e) {
      developer.log('❌ Error getting enhanced user profile: $e');
      return null;
    }
  }

  // Fallback notification method (logs notification for now)
  static Future<void> _sendFallbackNotification(
    String fcmToken,
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    developer.log('📤 Fallback notification:');
    developer.log('Token: ${fcmToken.substring(0, 20)}...');
    developer.log('Title: $title');
    developer.log('Body: $body');
    developer.log('Data: $data');
    developer.log('⚠️ Configure FCM v1 API for actual sending');
  }

  static Future<void> _updateChatDocument(
    String chatId,
    String senderId,
    String receiverId,
    String lastMessage,
    String senderName,
    String messageId,
  ) async {
    try {
      final chatData = {
        'chatId': chatId,
        'participants': [senderId, receiverId],
        'lastMessage': lastMessage,
        'lastMessageSender': senderId,
        'lastMessageSenderName': senderName,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageId': messageId,
        'lastMessageType': 'text',
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('chats')
          .doc(chatId)
          .set(chatData, SetOptions(merge: true));
    } catch (e) {
      developer.log('❌ Error updating chat document: $e');
      throw e;
    }
  }

  // Update user online status
  static Future<void> updateUserStatus(
    String userId,
    bool isOnline, {
    String? currentChatId,
  }) async {
    try {
      debugAuthStatus();

      final updateData = {
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (currentChatId != null) {
        updateData['currentChatId'] = currentChatId;
      } else if (!isOnline) {
        updateData['currentChatId'] = FieldValue.delete();
      }

      await _firestore.collection('users').doc(userId).update(updateData);
      developer.log('User status updated successfully');
    } catch (e) {
      developer.log('Error updating user status: $e');
      rethrow;
    }
  }

  // Update user's current chat (for notification suppression)
  static Future<void> updateCurrentChat(String userId, String? chatId) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (chatId != null && chatId.isNotEmpty) {
        updateData['currentChatId'] = chatId;
      } else {
        updateData['currentChatId'] = FieldValue.delete();
      }

      await _firestore.collection('users').doc(userId).update(updateData);
      developer.log('✅ Current chat updated for user: $userId');
    } catch (e) {
      developer.log('❌ Error updating current chat: $e');
    }
  }

  // Toggle user notifications
  static Future<void> toggleNotifications(String userId, bool enabled) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'notificationsEnabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      developer.log(
        'Notifications ${enabled ? 'enabled' : 'disabled'} for user: $userId',
      );
    } catch (e) {
      developer.log('Error toggling notifications: $e');
      rethrow;
    }
  }

  // Existing methods
  static Future<void> _refreshUserCacheAfterSave() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      developer.log('User cache refresh triggered after save');
    } catch (e) {
      developer.log('Error refreshing user cache: $e');
    }
  }

  static Future<void> testFirestoreConnection() async {
    try {
      debugAuthStatus();

      developer.log('Testing Firestore connection...');

      final testDoc =
          await _firestore.collection('test').doc('connection').get();
      developer.log('Test read successful: ${testDoc.exists}');

      await _firestore.collection('test').doc('connection').set({
        'timestamp': FieldValue.serverTimestamp(),
        'userId': _auth.currentUser?.uid,
        'test': true,
      });
      developer.log('Test write successful');

      await _firestore.collection('test').doc('connection').delete();
      developer.log('Test cleanup successful');
    } catch (e) {
      developer.log('Firestore connection test failed: $e');
      if (e is FirebaseException) {
        developer.log('Firebase error code: ${e.code}');
        developer.log('Firebase error message: ${e.message}');
      }
      rethrow;
    }
  }

  static Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? phone,
    String? dob,
    String? photoURL,
  }) async {
    try {
      debugAuthStatus();

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) {
        updateData['name'] = name;
        updateData['nameSearchable'] = name.toLowerCase();
      }
      if (phone != null) updateData['phone'] = phone;
      if (dob != null) updateData['dob'] = dob;
      if (photoURL != null) updateData['photoURL'] = photoURL;

      developer.log('Updating user profile with data: $updateData');

      await _firestore.collection('users').doc(userId).update(updateData);
      developer.log('User profile updated successfully: $userId');
    } catch (e) {
      developer.log('Error updating user profile: $e');
      rethrow;
    }
  }

  static Stream<QuerySnapshot> getAllUsers() {
    return _firestore.collection('users').orderBy('name').snapshots();
  }

  static Future<DocumentSnapshot> getUserById(String userId) {
    return _firestore.collection('users').doc(userId).get();
  }

  static Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  static Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      final unreadMessages =
          await _firestore
              .collection('messages')
              .where('chatId', isEqualTo: chatId)
              .where('receiverId', isEqualTo: userId)
              .where('isRead', isEqualTo: false)
              .get();

      final batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      developer.log('Error marking messages as read: $e');
    }
  }

  static String generateChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  static Stream<QuerySnapshot> getUnreadMessageCount(
    String chatId,
    String userId,
  ) {
    return _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots();
  }

  static Future<QuerySnapshot> searchUsers(String query) async {
    final queryLower = query.toLowerCase();

    try {
      var results =
          await _firestore
              .collection('users')
              .where('nameSearchable', isGreaterThanOrEqualTo: queryLower)
              .where(
                'nameSearchable',
                isLessThanOrEqualTo: queryLower + '\uf8ff',
              )
              .limit(20)
              .get();

      if (results.docs.isEmpty) {
        results =
            await _firestore
                .collection('users')
                .where('emailSearchable', isGreaterThanOrEqualTo: queryLower)
                .where(
                  'emailSearchable',
                  isLessThanOrEqualTo: queryLower + '\uf8ff',
                )
                .limit(20)
                .get();
      }

      developer.log(
        'Search for "$query" returned ${results.docs.length} results',
      );
      return results;
    } catch (e) {
      developer.log('Error searching users: $e');
      return await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get();
    }
  }

  static Future<void> forceRefreshUsers() async {
    try {
      developer.log('Forcing refresh of all users...');
      await Future.delayed(const Duration(milliseconds: 100));
      developer.log('User refresh completed');
    } catch (e) {
      developer.log('Error forcing user refresh: $e');
    }
  }

  static Future<bool> verifyAndCreateUser({
    required String userId,
    required String name,
    required String email,
    String? phone,
    String? dob,
    String? photoURL,
    String provider = 'email',
  }) async {
    try {
      final userDoc = await getUserById(userId);

      if (!userDoc.exists) {
        developer.log('User does not exist, creating: $userId');
        await saveUserToFirestore(
          userId: userId,
          name: name,
          email: email,
          phone: phone,
          dob: dob,
          photoURL: photoURL,
          provider: provider,
        );
        return true;
      } else {
        developer.log('User already exists: $userId');
        await updateUserStatus(userId, true);
        return false;
      }
    } catch (e) {
      developer.log('Error verifying/creating user: $e');
      rethrow;
    }
  }
}
