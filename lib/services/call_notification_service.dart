import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:innovator/services/Firebase_Messaging.dart';
import 'dart:developer' as developer;
import 'package:innovator/services/firebase_services.dart';
import 'package:innovator/services/fcm_handler.dart';

class CallNotificationService {
  // FIXED: Complete call notification with proper FCM v1 implementation
  static Future<void> sendCallNotification({
    required String receiverId,
    required String callId,
    required String callerName,
    required bool isVideoCall,
  }) async {
    try {
      developer.log('📞 Sending call notification to: $receiverId');
      
      // Get receiver's FCM token from Firestore
      final receiverDoc = await FirebaseService.getUserById(receiverId);
      if (!receiverDoc.exists) {
        developer.log('❌ Receiver not found: $receiverId');
        return;
      }
      
      final receiverData = receiverDoc.data() as Map<String, dynamic>;
      final fcmToken = receiverData['fcmToken']?.toString();
      
      if (fcmToken == null || fcmToken.isEmpty) {
        developer.log('❌ No FCM token for receiver: $receiverId');
        return;
      }
      
      // Use the improved FCMHandler for call notifications
      final success = await FCMHandler.sendToToken(
        fcmToken,
        title: isVideoCall ? 'Incoming Video Call' : 'Incoming Voice Call',
        body: '$callerName is calling you',
        type: 'call',
        data: {
          'callId': callId,
          'callerId': callerName, // Will be extracted from current user
          'callerName': callerName,
          'receiverId': receiverId,
          'isVideoCall': isVideoCall,
          'action': 'incoming_call',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      if (success) {
        developer.log('✅ Call notification sent successfully');
      } else {
        developer.log('❌ Failed to send call notification');
      }
      
    } catch (e) {
      developer.log('❌ Error sending call notification: $e');
    }
  }
}