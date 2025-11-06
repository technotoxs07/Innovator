// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:innovator/Innovatorservices/Firebase_Messaging.dart';
// import 'dart:developer' as developer;
// import 'package:innovator/Innovatorservices/firebase_services.dart';
// import 'package:innovator/Innovatorservices/fcm_handler.dart';

// class CallNotificationService {
//   // Send call notification with enhanced payload
//   static Future<void> sendCallNotification({
//     required String receiverId,
//     required String callId,
//     required String callerName,
//     required String callerId,
//     required bool isVideoCall,
//     String? callerPhoto,
//   }) async {
//     try {
//       developer.log('📞 Sending enhanced call notification to: $receiverId');
      
//       // Get receiver's FCM token from Firestore
//       final receiverDoc = await FirebaseService.getUserById(receiverId);
//       if (!receiverDoc.exists) {
//         developer.log('❌ Receiver not found: $receiverId');
//         return;
//       }
      
//       final receiverData = receiverDoc.data() as Map<String, dynamic>;
//       final fcmToken = receiverData['fcmToken']?.toString();
      
//       if (fcmToken == null || fcmToken.isEmpty) {
//         developer.log('❌ No FCM token for receiver: $receiverId');
//         return;
//       }
      
//       // Enhanced call notification with more data
//       final success = await FCMHandler.sendToToken(
//         fcmToken,
//         title: isVideoCall ? 'Incoming Video Call' : 'Incoming Voice Call',
//         body: '$callerName is ${isVideoCall ? 'video' : ''} calling you',
//         type: 'call',
//         data: {
//           'callId': callId,
//           'callerId': callerId,
//           'callerName': callerName,
//           'callerPhoto': callerPhoto ?? '',
//           'receiverId': receiverId,
//           'isVideoCall': isVideoCall.toString(),
//           'action': 'incoming_call',
//           'timestamp': DateTime.now().toIso8601String(),
//           'priority': 'high',
//           'category': 'call',
//         },
//       );
      
//       if (success) {
//         developer.log('✅ Enhanced call notification sent successfully');
//       } else {
//         developer.log('❌ Failed to send enhanced call notification');
//       }
      
//     } catch (e) {
//       developer.log('❌ Error sending enhanced call notification: $e');
//     }
//   }
  
//   // Send call status update notification
//   static Future<void> sendCallStatusUpdate({
//     required String receiverId,
//     required String callId,
//     required String status, // 'answered', 'rejected', 'ended', 'missed'
//     required String callerName,
//   }) async {
//     try {
//       developer.log('📞 Sending call status update: $status');
      
//       final receiverDoc = await FirebaseService.getUserById(receiverId);
//       if (!receiverDoc.exists) return;
      
//       final receiverData = receiverDoc.data() as Map<String, dynamic>;
//       final fcmToken = receiverData['fcmToken']?.toString();
      
//       if (fcmToken == null || fcmToken.isEmpty) return;
      
//       String title = '';
//       String body = '';
      
//       switch (status) {
//         case 'answered':
//           title = 'Call Answered';
//           body = '$callerName answered your call';
//           break;
//         case 'rejected':
//           title = 'Call Declined';
//           body = '$callerName declined your call';
//           break;
//         case 'ended':
//           title = 'Call Ended';
//           body = 'Call with $callerName has ended';
//           break;
//         case 'missed':
//           title = 'Missed Call';
//           body = 'You missed a call from $callerName';
//           break;
//         default:
//           return;
//       }
      
//       await FCMHandler.sendToToken(
//         fcmToken,
//         title: title,
//         body: body,
//         type: 'call_status',
//         data: {
//           'callId': callId,
//           'status': status,
//           'callerName': callerName,
//           'timestamp': DateTime.now().toIso8601String(),
//         },
//       );
      
//     } catch (e) {
//       developer.log('❌ Error sending call status update: $e');
//     }
//   }
// }