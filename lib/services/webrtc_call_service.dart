// lib/services/webrtc_call_service.dart - ENHANCED VERSION WITH VIDEO FIX

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:innovator/main.dart';
import 'package:innovator/screens/Call/Incoming_Call_screen.dart';
import 'package:innovator/services/Firebase_Messaging.dart';
import 'package:innovator/services/call_notification_service.dart';
import 'package:innovator/App_data/App_data.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;

class WebRTCCallService extends GetxService {
  static WebRTCCallService get instance => Get.find<WebRTCCallService>();
  
  // WebRTC components
  webrtc.RTCPeerConnection? _peerConnection;
  webrtc.MediaStream? _localStream;
  webrtc.MediaStream? _remoteStream;
  
  // Video renderers
  webrtc.RTCVideoRenderer? _localRenderer;
  webrtc.RTCVideoRenderer? _remoteRenderer;
  
  // Firebase Firestore for signaling
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Observables for UI
  final RxBool isCallActive = false.obs;
  final RxBool isVideoEnabled = true.obs;
  final RxBool isAudioEnabled = true.obs;
  final RxBool isIncomingCall = false.obs;
  final RxBool isOutgoingCall = false.obs;
  final RxBool isSpeakerOn = false.obs;
  final RxBool isCameraFront = true.obs;
  final RxString callStatus = ''.obs;
  final RxString currentCallId = ''.obs;
  final RxMap<String, dynamic> currentCallData = <String, dynamic>{}.obs;
  
  // Stream controllers
  final StreamController<webrtc.MediaStream?> _localStreamController = 
      StreamController<webrtc.MediaStream?>.broadcast();
  final StreamController<webrtc.MediaStream?> _remoteStreamController = 
      StreamController<webrtc.MediaStream?>.broadcast();
  
  Stream<webrtc.MediaStream?> get localStream => _localStreamController.stream;
  Stream<webrtc.MediaStream?> get remoteStream => _remoteStreamController.stream;
  
  // Video renderer getters
  webrtc.RTCVideoRenderer? get localRenderer => _localRenderer;
  webrtc.RTCVideoRenderer? get remoteRenderer => _remoteRenderer;
  
  // Enhanced ICE servers with multiple STUN/TURN servers
  final List<Map<String, String>> _iceServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    {'urls': 'stun:stun2.l.google.com:19302'},
    {'urls': 'stun:stun3.l.google.com:19302'},
    {'urls': 'stun:stun4.l.google.com:19302'},
    // Add more TURN servers here if needed for production
  ];
  
  // Stream subscriptions
  StreamSubscription<DocumentSnapshot>? _callDocSubscription;
  StreamSubscription<QuerySnapshot>? _incomingCallSubscription;
  
  @override
  void onInit() {
    super.onInit();
      _lastInitTime = DateTime.now();

  developer.log('WebRTC Call Service initialized');
  _initializeVideoRenderers();
  
  // CRITICAL: Clean up old calls before setting up listener
  _cleanupOldCalls().then((_) {
    // Only setup listener after cleanup is complete
    _setupIncomingCallListener();
  });
  }
  
  @override
  void onClose() {
    endCall();
    _callDocSubscription?.cancel();
    _incomingCallSubscription?.cancel();
    _localStreamController.close();
    _remoteStreamController.close();
    _disposeVideoRenderers();
    super.onClose();
  }
  
  // FIXED: Initialize video renderers on service start
  Future<void> _initializeVideoRenderers() async {
    try {
      developer.log('📹 Initializing video renderers...');
      
      _localRenderer = webrtc.RTCVideoRenderer();
      _remoteRenderer = webrtc.RTCVideoRenderer();
      
      await _localRenderer!.initialize();
      await _remoteRenderer!.initialize();
      
      developer.log('✅ Video renderers initialized successfully');
    } catch (e) {
      developer.log('❌ Error initializing video renderers: $e');
    }
  }
  
  void _disposeVideoRenderers() {
    try {
      _localRenderer?.dispose();
      _remoteRenderer?.dispose();
      _localRenderer = null;
      _remoteRenderer = null;
      developer.log('✅ Video renderers disposed');
    } catch (e) {
      developer.log('❌ Error disposing video renderers: $e');
    }
  }
  
  // FIXED: Setup proper incoming call listener
  void _setupIncomingCallListener() {
  final currentUserId = _getCurrentUserId();
  if (currentUserId.isEmpty) {
    developer.log('No current user ID, cannot setup call listener');
    return;
  }
  
  developer.log('Setting up incoming call listener for: $currentUserId');
  
  _incomingCallSubscription = _firestore
      .collection('calls')
      .where('receiverId', isEqualTo: currentUserId)
      .where('status', isEqualTo: 'calling')
      .snapshots()
      .listen(
        (snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final callData = change.doc.data() as Map<String, dynamic>;
              
              // CRITICAL: Check if call is recent (within last 2 minutes)
              final createdAt = callData['createdAt'] as Timestamp?;
              if (createdAt != null) {
                final callAge = DateTime.now().difference(createdAt.toDate());
                if (callAge.inMinutes > 2) {
                  developer.log('Ignoring old call: ${callData['callId']}, age: ${callAge.inMinutes} minutes');
                  
                  // Mark old call as expired
                  _firestore.collection('calls').doc(change.doc.id).update({
                    'status': 'expired',
                    'expiredAt': FieldValue.serverTimestamp(),
                  });
                  continue;
                }
              }
              
              developer.log('New incoming call detected: ${callData['callId']}');
              _handleIncomingCall(callData);
            }
          }
        },
        onError: (error) {
          developer.log('Error in incoming call listener: $error');
        },
      );
}

// Add this method to WebRTCCallService
Future<void> _startCallExpiryTimer(String callId) async {
  Timer(const Duration(minutes: 2), () async {
    try {
      final callDoc = await _firestore.collection('calls').doc(callId).get();
      if (callDoc.exists) {
        final data = callDoc.data()!;
        final status = data['status'] as String;
        
        // If call is still in calling state after 2 minutes, expire it
        if (status == 'calling') {
          await _firestore.collection('calls').doc(callId).update({
            'status': 'expired',
            'expiredAt': FieldValue.serverTimestamp(),
          });
          developer.log('Call expired due to timeout: $callId');
        }
      }
    } catch (e) {
      developer.log('Error expiring call: $e');
    }
  });
}
  
  // FIXED: Handle incoming call properly
  // In webrtc_call_service.dart
void _handleIncomingCall(Map<String, dynamic> callData) {
  try {
    // Check if already in a call
    if (isCallActive.value) {
      developer.log('📞 Already in call, rejecting incoming call');
      rejectCall(callData['callId']);
      return;
    }
    
    developer.log('📞 Processing incoming call: ${callData['callId']}');
    
    // Update call state
    isIncomingCall.value = true;
    currentCallData.value = callData;
    currentCallId.value = callData['callId'];
    
    // FIXED: Wait for next frame and check if Get context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<GetMaterialController>() || Get.key.currentContext != null) {
        _showIncomingCallScreen(callData);
      } else {
        developer.log('⚠️ GetX context not ready, showing notification instead');
        _showLocalCallNotification(callData);
      }
    });
    
    // Always show local notification as backup
    _showLocalCallNotification(callData);
    
  } catch (e) {
    developer.log('❌ Error handling incoming call: $e');
    // Fallback to notification
    _showLocalCallNotification(callData);
  }
}
  
  // FIXED: Show incoming call screen
  void _showIncomingCallScreen(Map<String, dynamic> callData) {
  try {
    if (!_isNavigationReady()) {
      developer.log('⚠️ Navigation not ready, showing notification instead');
      _showLocalCallNotification(callData);
      return;
    }
    
    developer.log('📱 Showing incoming call screen');
    
    Get.to(
      () => IncomingCallScreen(callData: callData),
      transition: Transition.fadeIn,
      fullscreenDialog: true,
      preventDuplicates: true, // Add this to prevent duplicates
    );
    
  } catch (e) {
    developer.log('❌ Error showing incoming call screen: $e');
    // Fallback to notification
    _showLocalCallNotification(callData);
  }
}

  bool _isNavigationReady() {
  try {
    return Get.key.currentContext != null && 
           WidgetsBinding.instance.lifecycleState != null;
  } catch (e) {
    return false;
  }
}
  

  // Add this method to WebRTCCallService class
Future<void> _cleanupOldCalls() async {
  try {
    final currentUserId = _getCurrentUserId();
    if (currentUserId.isEmpty) return;
    
    developer.log('Cleaning up old call documents...');
    
    // Get all calls where this user is receiver and status is 'calling'
    final oldCalls = await _firestore
        .collection('calls')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'calling')
        .get();
    
    // Update all old calling status to 'expired'
    final batch = _firestore.batch();
    for (var doc in oldCalls.docs) {
      batch.update(doc.reference, {
        'status': 'expired',
        'expiredAt': FieldValue.serverTimestamp(),
      });
    }
    
    if (oldCalls.docs.isNotEmpty) {
      await batch.commit();
      developer.log('Cleaned up ${oldCalls.docs.length} old call documents');
    }
    
  } catch (e) {
    developer.log('Error cleaning up old calls: $e');
  }
}

  // FIXED: Show local notification for incoming call
  // In webrtc_call_service.dart
void _showLocalCallNotification(Map<String, dynamic> callData) {
  try {
    final callerName = callData['callerName']?.toString() ?? 'Unknown Caller';
    final isVideoCall = callData['isVideoCall'] == true;
    final callId = callData['callId']?.toString() ?? '';
    
    // FIXED: Check if service is registered before using
    if (Get.isRegistered<FirebaseNotificationService>()) {
      final notificationService = Get.find<FirebaseNotificationService>();
      notificationService.sendCallNotification(
        token: '',
        callId: callId,
        callerName: callerName,
        isVideoCall: isVideoCall,
      );
      developer.log('📱 Local call notification shown via service');
    } else {
      // FIXED: Fallback to direct notification plugin usage
      _showDirectNotification(callId, callerName, isVideoCall, callData);
    }
    
  } catch (e) {
    developer.log('❌ Error showing local call notification: $e');
    // Final fallback
    _showDirectNotification(
      callData['callId']?.toString() ?? '',
      callData['callerName']?.toString() ?? 'Unknown',
      callData['isVideoCall'] == true,
      callData
    );
  }
}

// Add this fallback method
void _showDirectNotification(String callId, String callerName, bool isVideoCall, Map<String, dynamic> data) {
  try {
    // Use the global notification plugin directly
    const androidDetails = AndroidNotificationDetails(
      'incoming_calls',
      'Incoming Calls',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      enableVibration: true,
      playSound: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );
    
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    flutterLocalNotificationsPlugin.show(
      callId.hashCode.abs(),
      'Incoming ${isVideoCall ? 'Video' : 'Voice'} Call',
      'Call from $callerName',
      notificationDetails,
      payload: jsonEncode(data),
    );
    
    developer.log('📱 Direct notification shown successfully');
  } catch (e) {
    developer.log('❌ Direct notification failed: $e');
  }
}
  
  // ENHANCED: Request permissions before starting call
  Future<bool> _requestPermissions({required bool isVideoCall}) async {
    try {
      developer.log('📱 Requesting call permissions...');
      
      List<Permission> permissions = [Permission.microphone];
      if (isVideoCall) {
        permissions.add(Permission.camera);
      }
      
      Map<Permission, PermissionStatus> statuses = await permissions.request();
      
      bool allGranted = true;
      for (var permission in permissions) {
        if (statuses[permission] != PermissionStatus.granted) {
          allGranted = false;
          developer.log('❌ Permission ${permission.toString()} denied');
        }
      }
      
      return allGranted;
    } catch (e) {
      developer.log('❌ Error requesting permissions: $e');
      return false;
    }
  }
  
  // Initialize WebRTC peer connection - ENHANCED VERSION
  Future<void> _createPeerConnection() async {
    try {
      developer.log('🔗 Creating peer connection...');
      
      final configuration = <String, dynamic>{
        'iceServers': _iceServers,
        'sdpSemantics': 'unified-plan',
        'iceCandidatePoolSize': 10,
      };
      
      final constraints = <String, dynamic>{
        'mandatory': {},
        'optional': [
          {'DtlsSrtpKeyAgreement': true},
        ],
      };
      
      _peerConnection = await webrtc.createPeerConnection(configuration, constraints);
      
      _peerConnection?.onIceCandidate = (webrtc.RTCIceCandidate candidate) {
        _handleIceCandidate(candidate);
      };
      
      _peerConnection?.onTrack = (webrtc.RTCTrackEvent event) {
        developer.log('📺 Remote track received: ${event.track.kind}');
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams.first;
          if (_remoteRenderer != null) {
            _remoteRenderer!.srcObject = _remoteStream;
          }
          _remoteStreamController.add(_remoteStream);
        }
      };
      
      _peerConnection?.onConnectionState = (webrtc.RTCPeerConnectionState state) {
        developer.log('🔗 Connection state: $state');
        _handleConnectionStateChange(state);
      };
      
      developer.log('✅ Peer connection created successfully');
    } catch (e) {
      developer.log('❌ Error creating peer connection: $e');
      throw Exception('Failed to create peer connection: $e');
    }
  }
  
  // ENHANCED: Get user media with proper constraints
  Future<webrtc.MediaStream> _getUserMedia({bool video = true, bool audio = true}) async {
    try {
      developer.log('📱 Getting user media - Video: $video, Audio: $audio');
      
      final constraints = <String, dynamic>{
        'audio': audio ? {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
          'sampleRate': 44100,
        } : false,
        'video': video ? {
          'width': {'min': 320, 'ideal': 640, 'max': 1280},
          'height': {'min': 240, 'ideal': 480, 'max': 720},
          'frameRate': {'min': 10, 'ideal': 30, 'max': 30},
          'facingMode': isCameraFront.value ? 'user' : 'environment',
        } : false,
      };
      
      final stream = await webrtc.navigator.mediaDevices.getUserMedia(constraints);
      
      // CRITICAL: Set video renderer source immediately after getting stream
      if (video && _localRenderer != null) {
        _localRenderer!.srcObject = stream;
        developer.log('✅ Local video renderer source set');
      }
      
      developer.log('✅ User media obtained successfully');
      return stream;
    } catch (e) {
      developer.log('❌ Error getting user media: $e');
      throw Exception('Failed to get user media: $e');
    }
  }
  
  // ENHANCED: Add tracks with proper error handling
  Future<void> _addLocalStreamToPeerConnection() async {
    if (_localStream == null || _peerConnection == null) return;
    
    try {
      developer.log('➕ Adding media tracks to peer connection...');
      
      // Add each track individually for better compatibility
      for (var track in _localStream!.getTracks()) {
        developer.log('➕ Adding ${track.kind} track: ${track.id}');
        await _peerConnection!.addTrack(track, _localStream!);
      }
      
      developer.log('✅ All tracks added to peer connection');
    } catch (e) {
      developer.log('❌ Error adding tracks: $e');
      // Fallback to addStream for older implementations
      try {
        await _peerConnection!.addStream(_localStream!);
        developer.log('✅ Stream added using fallback method');
      } catch (fallbackError) {
        developer.log('❌ Fallback addStream failed: $fallbackError');
        throw Exception('Failed to add media to peer connection: $e');
      }
    }
  }
  
  // ENHANCED: Start outgoing call with permission check
  Future<String> startCall({
    required String receiverId,
    required String receiverName,
    required String callerId,
    required String callerName,
    required bool isVideoCall,
  }) async {
    try {
      developer.log('📞 Starting ${isVideoCall ? 'video' : 'voice'} call to $receiverId');
      
      // Request permissions first
      final hasPermissions = await _requestPermissions(isVideoCall: isVideoCall);
      if (!hasPermissions) {
        throw Exception('Required permissions not granted');
      }
      
      // Create unique call ID
      final callId = '${callerId}_${receiverId}_${DateTime.now().millisecondsSinceEpoch}';
      currentCallId.value = callId;
      
      // Get user media
      _localStream = await _getUserMedia(video: isVideoCall, audio: true);
      _localStreamController.add(_localStream);
      
      // Create peer connection
      await _createPeerConnection();
      
      // Add tracks to peer connection
      await _addLocalStreamToPeerConnection();
      
      // Create call document in Firestore FIRST
      await _createCallDocument(
        callId: callId,
        callerId: callerId,
        callerName: callerName,
        receiverId: receiverId,
        receiverName: receiverName,
        isVideoCall: isVideoCall,
      );
      
      // Create offer
      final offer = await _peerConnection?.createOffer();
      await _peerConnection?.setLocalDescription(offer!);
      
      // Save offer to Firestore
      await _saveOfferToFirestore(callId, offer!);
      
      // Start listening to call document changes
      _listenToCallDocument(callId);
      
      // Send call notification
      await CallNotificationService.sendCallNotification(
        receiverId: receiverId,
        callId: callId,
        callerId: callerId,
        callerName: callerName,
        isVideoCall: isVideoCall,
      );
      
      isOutgoingCall.value = true;
      isCallActive.value = true;
      callStatus.value = 'Calling...';
      
      developer.log('✅ Outgoing call initiated: $callId');
      return callId;
      
    } catch (e) {
      developer.log('❌ Error starting call: $e');
      await endCall();
      throw Exception('Failed to start call: $e');
    }
  }
  
  // ENHANCED: Answer incoming call with video handling
  Future<void> answerCall(String callId) async {
    try {
      developer.log('✅ Answering call: $callId');
      
      currentCallId.value = callId;
      
      // Get call data
      final callDoc = await _firestore.collection('calls').doc(callId).get();
      if (!callDoc.exists) {
        throw Exception('Call document not found');
      }
      
      final callData = callDoc.data()!;
      final isVideoCall = callData['isVideoCall'] as bool;
      
      // Request permissions
      final hasPermissions = await _requestPermissions(isVideoCall: isVideoCall);
      if (!hasPermissions) {
        throw Exception('Required permissions not granted');
      }
      
      // Get user media
      _localStream = await _getUserMedia(video: isVideoCall, audio: true);
      _localStreamController.add(_localStream);
      
      // Create peer connection
      await _createPeerConnection();
      
      // Add tracks to peer connection
      await _addLocalStreamToPeerConnection();
      
      // Get offer from Firestore and create answer
      final offerData = callData['offer'] as Map<String, dynamic>;
      final offer = webrtc.RTCSessionDescription(offerData['sdp'], offerData['type']);
      
      await _peerConnection?.setRemoteDescription(offer);
      
      // Create and set answer
      final answer = await _peerConnection?.createAnswer();
      await _peerConnection?.setLocalDescription(answer!);
      
      // Save answer to Firestore
      await _saveAnswerToFirestore(callId, answer!);
      
      // Update call status
      await _firestore.collection('calls').doc(callId).update({
        'status': 'answered',
        'answeredAt': FieldValue.serverTimestamp(),
      });
      
      // Start listening to call document
      _listenToCallDocument(callId);
      
      isIncomingCall.value = false;
      isCallActive.value = true;
      callStatus.value = 'Connected';
      
      developer.log('✅ Call answered successfully');
      
    } catch (e) {
      developer.log('❌ Error answering call: $e');
      await endCall();
      throw Exception('Failed to answer call: $e');
    }
  }
  
  // Reject incoming call
  Future<void> rejectCall(String callId) async {
    try {
      developer.log('❌ Rejecting call: $callId');
      
      await _firestore.collection('calls').doc(callId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });
      
      isIncomingCall.value = false;
      currentCallId.value = '';
      currentCallData.clear();
      
      developer.log('✅ Call rejected');
    } catch (e) {
      developer.log('❌ Error rejecting call: $e');
    }
  }
  
  // ENHANCED: End call with proper cleanup
  Future<void> endCall() async {
    try {
      developer.log('📞 Ending call...');
      
      // Update call status in Firestore
      if (currentCallId.value.isNotEmpty) {
        await _firestore.collection('calls').doc(currentCallId.value).update({
          'status': 'ended',
          'endedAt': FieldValue.serverTimestamp(),
        });
      }
      
      // Stop local stream tracks
      if (_localStream != null) {
        for (var track in _localStream!.getTracks()) {
          await track.stop();
        }
        _localStream = null;
      }
      
      // Clear remote stream
      _remoteStream = null;
      
      // Clear video renderers
      if (_localRenderer != null) {
        _localRenderer!.srcObject = null;
      }
      if (_remoteRenderer != null) {
        _remoteRenderer!.srcObject = null;
      }
      
      // Close peer connection
      await _peerConnection?.close();
      _peerConnection = null;
      
      // Cancel call document subscription
      _callDocSubscription?.cancel();
      
      // Reset observables
      isCallActive.value = false;
      isIncomingCall.value = false;
      isOutgoingCall.value = false;
      isVideoEnabled.value = true;
      isAudioEnabled.value = true;
      isSpeakerOn.value = false;
      callStatus.value = '';
      currentCallId.value = '';
      currentCallData.clear();
      
      // Update streams
      _localStreamController.add(null);
      _remoteStreamController.add(null);
      
      developer.log('✅ Call ended successfully');
      
    } catch (e) {
      developer.log('❌ Error ending call: $e');
    }
  }
  
  // ENHANCED: Toggle video with proper error handling
  Future<void> toggleVideo() async {
    if (_localStream != null) {
      try {
        final videoTracks = _localStream!.getVideoTracks();
        if (videoTracks.isNotEmpty) {
          final videoTrack = videoTracks.first;
          videoTrack.enabled = !videoTrack.enabled;
          isVideoEnabled.value = videoTrack.enabled;
          
          // Update renderer visibility
          if (_localRenderer != null) {
            if (!videoTrack.enabled) {
              _localRenderer!.srcObject = null;
            } else {
              _localRenderer!.srcObject = _localStream;
            }
          }
          
          developer.log('📹 Video ${videoTrack.enabled ? 'enabled' : 'disabled'}');
        }
      } catch (e) {
        developer.log('❌ Error toggling video: $e');
      }
    }
  }
  
  // ENHANCED: Toggle audio
  Future<void> toggleAudio() async {
    if (_localStream != null) {
      try {
        final audioTracks = _localStream!.getAudioTracks();
        if (audioTracks.isNotEmpty) {
          final audioTrack = audioTracks.first;
          audioTrack.enabled = !audioTrack.enabled;
          isAudioEnabled.value = audioTrack.enabled;
          developer.log('🎤 Audio ${audioTrack.enabled ? 'enabled' : 'disabled'}');
        }
      } catch (e) {
        developer.log('❌ Error toggling audio: $e');
      }
    }
  }
  
  // ENHANCED: Switch camera with proper handling
  Future<void> switchCamera() async {
    if (_localStream != null) {
      try {
        final videoTracks = _localStream!.getVideoTracks();
        if (videoTracks.isNotEmpty) {
          await webrtc.Helper.switchCamera(videoTracks.first);
          isCameraFront.value = !isCameraFront.value;
          developer.log('📱 Camera switched to ${isCameraFront.value ? 'front' : 'back'}');
        }
      } catch (e) {
        developer.log('❌ Error switching camera: $e');
      }
    }
  }
  
  // ENHANCED: Toggle speaker
  Future<void> toggleSpeaker() async {
    try {
      isSpeakerOn.value = !isSpeakerOn.value;
      await webrtc.Helper.setSpeakerphoneOn(isSpeakerOn.value);
      developer.log('🔊 Speaker ${isSpeakerOn.value ? 'enabled' : 'disabled'}');
    } catch (e) {
      developer.log('❌ Error toggling speaker: $e');
    }
  }
  
  // ENHANCED: Enable/disable speaker
  Future<void> setSpeaker(bool enabled) async {
    try {
      isSpeakerOn.value = enabled;
      await webrtc.Helper.setSpeakerphoneOn(enabled);
      developer.log('🔊 Speaker set to ${enabled ? 'on' : 'off'}');
    } catch (e) {
      developer.log('❌ Error setting speaker: $e');
    }
  }

  DateTime _lastInitTime = DateTime.now();


  bool _isDevelopmentRestart() {
  try {
    // Check if this is a development restart by looking at app lifecycle
    return WidgetsBinding.instance.lifecycleState == null ||
           DateTime.now().difference(_lastInitTime).inSeconds < 10;
  } catch (e) {
    return false;
  }
}
  
  // Create call document in Firestore
  Future<void> _createCallDocument({
  required String callId,
  required String callerId,
  required String callerName,
  required String receiverId,
  required String receiverName,
  required bool isVideoCall,
}) async {
  await _firestore.collection('calls').doc(callId).set({
    'callId': callId,
    'callerId': callerId,
    'callerName': callerName,
    'receiverId': receiverId,
    'receiverName': receiverName,
    'isVideoCall': isVideoCall,
    'status': 'calling',
    'createdAt': FieldValue.serverTimestamp(),
    'participants': [callerId, receiverId],
    'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 2))), // Add expiry
  });
  
  developer.log('Call document created: $callId');
  
  // Start expiry timer
  _startCallExpiryTimer(callId);
}
  
  // Save WebRTC offer to Firestore
  Future<void> _saveOfferToFirestore(String callId, webrtc.RTCSessionDescription offer) async {
    await _firestore.collection('calls').doc(callId).update({
      'offer': {
        'type': offer.type,
        'sdp': offer.sdp,
      },
    });
  }
  
  // Save WebRTC answer to Firestore
  Future<void> _saveAnswerToFirestore(String callId, webrtc.RTCSessionDescription answer) async {
    await _firestore.collection('calls').doc(callId).update({
      'answer': {
        'type': answer.type,
        'sdp': answer.sdp,
      },
    });
  }
  
  // Handle ICE candidates
  void _handleIceCandidate(webrtc.RTCIceCandidate candidate) {
    if (currentCallId.value.isNotEmpty) {
      _firestore.collection('calls').doc(currentCallId.value).collection('candidates').add({
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMlineIndex': candidate.sdpMLineIndex,
        'from': _getCurrentUserId(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }
  
  // Listen to call document changes
  void _listenToCallDocument(String callId) {
    _callDocSubscription = _firestore.collection('calls').doc(callId).snapshots().listen(
      (snapshot) async {
        if (snapshot.exists) {
          final data = snapshot.data()!;
          currentCallData.value = data;
          
          final status = data['status'] as String;
          callStatus.value = status;
          
          // Handle call status changes
          switch (status) {
            case 'answered':
              if (isOutgoingCall.value) {
                await _handleCallAnswered(data);
              }
              break;
            case 'rejected':
              _handleCallRejected();
              break;
            case 'ended':
              _handleCallEnded();
              break;
          }
        }
      },
      onError: (error) {
        developer.log('❌ Error listening to call document: $error');
      },
    );
    
    // Listen to ICE candidates
    _firestore.collection('calls').doc(callId).collection('candidates').snapshots().listen(
      (snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data()!;
            final from = data['from'] as String;
            
            // Only process candidates from the other user
            if (from != _getCurrentUserId()) {
              final candidate = webrtc.RTCIceCandidate(
                data['candidate'],
                data['sdpMid'],
                data['sdpMlineIndex'],
              );
              _peerConnection?.addCandidate(candidate);
            }
          }
        }
      },
    );
  }
  
  // Handle call answered
  Future<void> _handleCallAnswered(Map<String, dynamic> data) async {
    try {
      if (data.containsKey('answer')) {
        final answerData = data['answer'] as Map<String, dynamic>;
        final answer = webrtc.RTCSessionDescription(answerData['sdp'], answerData['type']);
        await _peerConnection?.setRemoteDescription(answer);
        callStatus.value = 'Connected';
      }
    } catch (e) {
      developer.log('❌ Error handling call answered: $e');
    }
  }
  
  // Handle call rejected
  void _handleCallRejected() {
    callStatus.value = 'Call rejected';
    Future.delayed(const Duration(seconds: 2), () {
      endCall();
    });
  }
  
  // Handle call ended
  void _handleCallEnded() {
    callStatus.value = 'Call ended';
    endCall();
  }
  
  // Handle connection state changes
  void _handleConnectionStateChange(webrtc.RTCPeerConnectionState state) {
    switch (state) {
      case webrtc.RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        callStatus.value = 'Connected';
        // Auto-enable speaker for video calls
        if (currentCallData['isVideoCall'] == true) {
          setSpeaker(true);
        }
        break;
      case webrtc.RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        callStatus.value = 'Disconnected';
        break;
      case webrtc.RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        callStatus.value = 'Connection failed';
        endCall();
        break;
      case webrtc.RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        callStatus.value = 'Connection closed';
        break;
      default:
        break;
    }
  }
  
  // Get current user ID
  String _getCurrentUserId() {
    try {
      final currentUser = AppData().currentUser;
      return currentUser?['_id']?.toString() ??
             currentUser?['uid']?.toString() ??
             currentUser?['userId']?.toString() ??
             '';
    } catch (e) {
      developer.log('❌ Error getting current user ID: $e');
      return '';
    }
  }
}