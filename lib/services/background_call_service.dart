// // lib/services/enhanced_background_call_service.dart

// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
// import 'package:vibration/vibration.dart';
// import 'package:wakelock_plus/wakelock_plus.dart';
// import 'package:get/get.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:audioplayers/audioplayers.dart';
// import 'dart:developer' as developer;

// class EnhancedBackgroundCallService extends GetxService {
//   static EnhancedBackgroundCallService get instance => 
//       Get.find<EnhancedBackgroundCallService>();
  
//   // Singleton instance for background access
//   static final EnhancedBackgroundCallService _singleton = 
//       EnhancedBackgroundCallService._internal();
  
//   factory EnhancedBackgroundCallService() => _singleton;
  
//   EnhancedBackgroundCallService._internal();
  
//   // Call state management
//   final RxBool isRinging = false.obs;
//   final RxString currentCallId = ''.obs;
//   final RxMap<String, dynamic> currentCallData = <String, dynamic>{}.obs;
  
//   // Audio players for persistent ringing
//   AudioPlayer? _ringtonePlayer;
//   Timer? _vibrationTimer;
//   Timer? _autoEndTimer;
  
//   // Notification plugin
//   final FlutterLocalNotificationsPlugin _notificationsPlugin = 
//       FlutterLocalNotificationsPlugin();
  
//   // Static instance for background access
//   static Timer? _staticRingtoneTimer;
//   static bool _isStaticRinging = false;
  
//   @override
//   void onInit() {
//     super.onInit();
//     _initializeNotifications();
//     developer.log('📞 Enhanced Background Call Service initialized');
//   }
  
//   @override
//   void onClose() {
//     stopAllRinging();
//     _ringtonePlayer?.dispose();
//     super.onClose();
//   }
  
//   Future<void> _initializeNotifications() async {
//     const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const iosInit = DarwinInitializationSettings();
//     const initSettings = InitializationSettings(
//       android: androidInit,
//       iOS: iosInit,
//     );
    
//     await _notificationsPlugin.initialize(
//       initSettings,
//       onDidReceiveNotificationResponse: _handleNotificationResponse,
//     );
    
//     // Create call notification channel
//     const androidChannel = AndroidNotificationChannel(
//       'incoming_calls',
//       'Incoming Calls',
//       description: 'Notifications for incoming calls',
//       importance: Importance.max,
//       enableVibration: true,
//       enableLights: true,
//       playSound: true,
//       sound: RawResourceAndroidNotificationSound('call_ringtone'),
//     );
    
//     final androidPlugin = _notificationsPlugin
//         .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
//     await androidPlugin?.createNotificationChannel(androidChannel);
//   }
  
//   // CRITICAL: Start persistent ringing for incoming calls
//   Future<void> startPersistentRinging({
//     required String callId,
//     required Map<String, dynamic> callData,
//   }) async {
//     try {
//       developer.log('🔔 Starting PERSISTENT ringing for call: $callId');
      
//       // Stop any existing ringing
//       await stopAllRinging();
      
//       // Update state
//       currentCallId.value = callId;
//       currentCallData.value = callData;
//       isRinging.value = true;
//       _isStaticRinging = true;
      
//       // Enable wakelock to keep screen on
//       await WakelockPlus.enable();
      
//       // Show high-priority notification with actions
//       await _showCallNotificationWithActions(callId, callData);
      
//       // Start persistent ringtone
//       await _startPersistentRingtone();
      
//       // Start vibration pattern
//       await _startPersistentVibration();
      
//       // Auto-stop after 45 seconds (WhatsApp-like behavior)
//       _autoEndTimer = Timer(const Duration(seconds: 45), () {
//         developer.log('⏰ Auto-stopping ringtone after timeout');
//         stopAllRinging();
//       });
      
//       developer.log('✅ Persistent ringing started successfully');
//     } catch (e) {
//       developer.log('❌ Error starting persistent ringing: $e');
//     }
//   }
  
//   // ENHANCED: Start persistent ringtone using AudioPlayer
//   Future<void> _startPersistentRingtone() async {
//     try {
//       developer.log('🎵 Starting persistent ringtone...');
      
//       // Initialize audio player if needed
//       _ringtonePlayer ??= AudioPlayer();
      
//       // Set release mode to loop
//       await _ringtonePlayer!.setReleaseMode(ReleaseMode.loop);
      
//       // Play system ringtone or custom sound
//       try {
//         // Try to play system ringtone
//         await FlutterRingtonePlayer().playRingtone(
//           looping: true,
//           volume: 1.0,
//           asAlarm: false,
//         );
        
//         developer.log('✅ System ringtone started');
//       } catch (e) {
//         developer.log('⚠️ System ringtone failed, using AudioPlayer fallback');
        
//         // Fallback to AudioPlayer with custom sound
//         await _ringtonePlayer!.play(
//           AssetSource('sounds/ringtone.mp3'), // Add your ringtone file
//           volume: 1.0,
//         );
//       }
      
//       // Additional fallback with timer-based system sounds
//       _startSystemSoundFallback();
      
//     } catch (e) {
//       developer.log('❌ Error starting persistent ringtone: $e');
//       // Last resort fallback
//       _startSystemSoundFallback();
//     }
//   }
  
//   // System sound fallback for maximum compatibility
//   void _startSystemSoundFallback() {
//     _staticRingtoneTimer?.cancel();
//     _staticRingtoneTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
//       if (_isStaticRinging) {
//         try {
//           SystemSound.play(SystemSoundType.click);
//           HapticFeedback.heavyImpact();
//         } catch (e) {
//           developer.log('❌ System sound failed: $e');
//         }
//       } else {
//         timer.cancel();
//       }
//     });
//   }
  
//   // ENHANCED: Persistent vibration pattern
//   Future<void> _startPersistentVibration() async {
//     try {
//       developer.log('📳 Starting persistent vibration...');
      
//       bool? hasVibrator = await Vibration.hasVibrator();
//       if (hasVibrator != true) {
//         developer.log('📳 Device does not support vibration');
//         return;
//       }
      
//       _vibrationTimer?.cancel();
//       _vibrationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
//         if (isRinging.value || _isStaticRinging) {
//           Vibration.vibrate(
//             pattern: [0, 800, 200, 800, 200, 800], // WhatsApp-like pattern
//             intensities: [0, 255, 0, 255, 0, 255],
//           );
//         } else {
//           timer.cancel();
//         }
//       });
      
//       developer.log('✅ Persistent vibration started');
//     } catch (e) {
//       developer.log('❌ Error starting vibration: $e');
//     }
//   }
  
//   // CRITICAL: Show call notification with actions
//   Future<void> _showCallNotificationWithActions(
//     String callId,
//     Map<String, dynamic> callData,
//   ) async {
//     try {
//       final callerName = callData['callerName']?.toString() ?? 'Unknown Caller';
//       final isVideoCall = callData['isVideoCall'] == true;
      
//       // Create notification with HIGH priority and full-screen intent
//       final androidDetails = AndroidNotificationDetails(
//         'incoming_calls',
//         'Incoming Calls',
//         channelDescription: 'Notifications for incoming calls',
//         importance: Importance.max,
//         priority: Priority.max,
//         category: AndroidNotificationCategory.call,
//         fullScreenIntent: true, // CRITICAL: Shows over lock screen
//         ongoing: true, // Keeps notification persistent
//         autoCancel: false,
//         showWhen: false,
//         timeoutAfter: 45000, // Auto-dismiss after 45 seconds
//         visibility: NotificationVisibility.public,
//         icon: '@mipmap/ic_launcher',
//         largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
//         styleInformation: BigTextStyleInformation(
//           'Tap to answer or decline',
//           htmlFormatBigText: true,
//           contentTitle: '${isVideoCall ? 'Video' : 'Voice'} Call',
//           htmlFormatContentTitle: true,
//         ),
//         actions: [
//           AndroidNotificationAction(
//             'accept_call_$callId',
//             'Answer',
//             titleColor: Colors.green,
//             showsUserInterface: true, // Opens app
//           ),
//           AndroidNotificationAction(
//             'decline_call_$callId',
//             'Decline',
//             titleColor: Colors.red,
//             cancelNotification: true,
//           ),
//         ],
//         enableVibration: true,
//         vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
//         enableLights: true,
//         ledColor: Colors.blue,
//         ledOnMs: 1000,
//         ledOffMs: 500,
//         playSound: true,
//         sound: const RawResourceAndroidNotificationSound('call_ringtone'),
//       );
      
//       const iosDetails = DarwinNotificationDetails(
//         presentAlert: true,
//         presentBadge: true,
//         presentSound: true,
//         sound: 'call_ringtone.wav',
//         interruptionLevel: InterruptionLevel.critical,
//         categoryIdentifier: 'CALL_CATEGORY',
//       );
      
//       final notificationDetails = NotificationDetails(
//         android: androidDetails,
//         iOS: iosDetails,
//       );
      
//       await _notificationsPlugin.show(
//         callId.hashCode,
//         '${isVideoCall ? 'Video' : 'Voice'} Call',
//         'Incoming ${isVideoCall ? 'video' : 'voice'} call from $callerName',
//         notificationDetails,
//         payload: jsonEncode({
//           ...callData,
//           'action': 'incoming_call',
//         }),
//       );
      
//       developer.log('✅ Call notification with actions shown');
//     } catch (e) {
//       developer.log('❌ Error showing call notification: $e');
//     }
//   }
  
//   // Handle notification responses
//   void _handleNotificationResponse(NotificationResponse response) {
//     try {
//       developer.log('📞 Notification action: ${response.actionId}');
      
//       if (response.actionId?.startsWith('accept_call_') == true) {
//         _handleAcceptFromNotification(response.payload);
//       } else if (response.actionId?.startsWith('decline_call_') == true) {
//         _handleDeclineFromNotification(response.payload);
//       } else if (response.payload != null) {
//         // Notification body tapped - show incoming call screen
//         final data = jsonDecode(response.payload!) as Map<String, dynamic>;
//         _showIncomingCallScreen(data);
//       }
//     } catch (e) {
//       developer.log('❌ Error handling notification response: $e');
//     }
//   }
  
//   void _handleAcceptFromNotification(String? payload) {
//     try {
//       stopAllRinging();
      
//       if (payload != null) {
//         final data = jsonDecode(payload) as Map<String, dynamic>;
//         final callId = data['callId']?.toString() ?? '';
        
//         // Navigate to app and accept call
//         Get.toNamed('/incoming-call', arguments: data);
        
//         // Update Firestore
//         FirebaseFirestore.instance
//             .collection('calls')
//             .doc(callId)
//             .update({'status': 'answered'});
//       }
//     } catch (e) {
//       developer.log('❌ Error accepting call from notification: $e');
//     }
//   }
  
//   void _handleDeclineFromNotification(String? payload) {
//     try {
//       stopAllRinging();
      
//       if (payload != null) {
//         final data = jsonDecode(payload) as Map<String, dynamic>;
//         final callId = data['callId']?.toString() ?? '';
        
//         // Update Firestore
//         FirebaseFirestore.instance
//             .collection('calls')
//             .doc(callId)
//             .update({'status': 'rejected'});
//       }
//     } catch (e) {
//       developer.log('❌ Error declining call from notification: $e');
//     }
//   }
  
//   void _showIncomingCallScreen(Map<String, dynamic> data) {
//     stopAllRinging();
//     Get.toNamed('/incoming-call', arguments: data);
//   }
  
//   // CRITICAL: Stop all ringing
//   Future<void> stopAllRinging() async {
//     try {
//       developer.log('🔇 Stopping all ringing...');
      
//       isRinging.value = false;
//       _isStaticRinging = false;
      
//       // Stop ringtone
//       await FlutterRingtonePlayer().stop();
//       await _ringtonePlayer?.stop();
//       _staticRingtoneTimer?.cancel();
      
//       // Stop vibration
//       await Vibration.cancel();
//       _vibrationTimer?.cancel();
      
//       // Cancel timers
//       _autoEndTimer?.cancel();
      
//       // Disable wakelock
//       await WakelockPlus.disable();
      
//       // Clear notification
//       if (currentCallId.value.isNotEmpty) {
//         await _notificationsPlugin.cancel(currentCallId.value.hashCode);
//       }
      
//       // Clear state
//       currentCallId.value = '';
//       currentCallData.clear();
      
//       developer.log('✅ All ringing stopped');
//     } catch (e) {
//       developer.log('❌ Error stopping ringing: $e');
//     }
//   }
  
//   // Check if ringing for specific call
//   bool isRingingForCall(String callId) {
//     return (isRinging.value || _isStaticRinging) && currentCallId.value == callId;
//   }
  
//   // STATIC METHOD FOR BACKGROUND HANDLER
//   static Future<void> handleBackgroundCall(Map<String, dynamic> callData) async {
//     try {
//       developer.log('📞 === HANDLING BACKGROUND CALL (STATIC) ===');
      
//       final callId = callData['callId']?.toString() ?? '';
      
//       // Initialize service if needed
//       if (!Get.isRegistered<EnhancedBackgroundCallService>()) {
//         Get.put(EnhancedBackgroundCallService(), permanent: true);
//       }
      
//       final service = EnhancedBackgroundCallService.instance;
      
//       // Start persistent ringing
//       await service.startPersistentRinging(
//         callId: callId,
//         callData: callData,
//       );
      
//       developer.log('✅ Background call handled with persistent ringing');
//     } catch (e) {
//       developer.log('❌ Error in static background call handler: $e');
//     }
//   }
// }