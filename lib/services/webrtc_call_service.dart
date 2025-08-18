// lib/services/webrtc_call_service.dart - FIXED VERSION

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:innovator/screens/Call/Incoming_Call_screen.dart';
import 'package:innovator/services/Firebase_Messaging.dart';
import 'package:innovator/services/call_notification_service.dart';
import 'package:innovator/App_data/App_data.dart';
import 'dart:developer' as developer;

class WebRTCCallService extends GetxService {
  static WebRTCCallService get instance => Get.find<WebRTCCallService>();
  
  // WebRTC components
  webrtc.RTCPeerConnection? _peerConnection;
  webrtc.MediaStream? _localStream;
  webrtc.MediaStream? _remoteStream;
  
  // Firebase Firestore for signaling
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Observables for UI
  final RxBool isCallActive = false.obs;
  final RxBool isVideoEnabled = true.obs;
  final RxBool isAudioEnabled = true.obs;
  final RxBool isIncomingCall = false.obs;
  final RxBool isOutgoingCall = false.obs;
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
  
  // ICE servers (STUN/TURN) - Free Google STUN servers
  final List<Map<String, String>> _iceServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    {'urls': 'stun:stun2.l.google.com:19302'},
    {'urls': 'stun:stun3.l.google.com:19302'},
    {'urls': 'stun:stun4.l.google.com:19302'},
  ];
  
  // Stream subscriptions
  StreamSubscription<DocumentSnapshot>? _callDocSubscription;
  StreamSubscription<QuerySnapshot>? _incomingCallSubscription;
  
  @override
  void onInit() {
    super.onInit();
    developer.log('🎥 WebRTC Call Service initialized');
    _setupIncomingCallListener();
  }
  
  @override
  void onClose() {
    endCall();
    _callDocSubscription?.cancel();
    _incomingCallSubscription?.cancel();
    _localStreamController.close();
    _remoteStreamController.close();
    super.onClose();
  }
  
  // FIXED: Setup proper incoming call listener
  void _setupIncomingCallListener() {
    final currentUserId = _getCurrentUserId();
    if (currentUserId.isEmpty) {
      developer.log('❌ No current user ID, cannot setup call listener');
      return;
    }
    
    developer.log('🔔 Setting up incoming call listener for: $currentUserId');
    
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
                developer.log('📞 New incoming call detected: ${callData['callId']}');
                _handleIncomingCall(callData);
              }
            }
          },
          onError: (error) {
            developer.log('❌ Error in incoming call listener: $error');
          },
        );
  }
  
  // FIXED: Handle incoming call properly
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
      
      // Show incoming call screen
      _showIncomingCallScreen(callData);
      
      // CRITICAL: Send local notification to ensure user sees the call
      _showLocalCallNotification(callData);
      
    } catch (e) {
      developer.log('❌ Error handling incoming call: $e');
    }
  }
  
  // FIXED: Show incoming call screen
  void _showIncomingCallScreen(Map<String, dynamic> callData) {
    try {
      developer.log('📱 Showing incoming call screen');
      
      // Navigate to incoming call screen with proper data
      Get.to(
        () => IncomingCallScreen(callData: callData),
        transition: Transition.fadeIn,
        fullscreenDialog: true,
        preventDuplicates: false, // Allow multiple call screens if needed
      );
      
    } catch (e) {
      developer.log('❌ Error showing incoming call screen: $e');
    }
  }
  
  // FIXED: Show local notification for incoming call
  void _showLocalCallNotification(Map<String, dynamic> callData) {
    try {
      final callerName = callData['callerName']?.toString() ?? 'Unknown Caller';
      final isVideoCall = callData['isVideoCall'] == true;
      final callId = callData['callId']?.toString() ?? '';
      
      // Use the Firebase notification service to show local notification
      final notificationService = Get.find<FirebaseNotificationService>();
      notificationService.sendCallNotification(
        token: '', // Empty token for local notification
        callId: callId,
        callerName: callerName,
        isVideoCall: isVideoCall,
      );
      
      developer.log('📱 Local call notification shown');
      
    } catch (e) {
      developer.log('❌ Error showing local call notification: $e');
    }
  }
  
  // Initialize WebRTC peer connection - FIXED VERSION
  Future<void> _createPeerConnection() async {
    try {
      developer.log('🔗 Creating peer connection...');
      
      final configuration = <String, dynamic>{
        'iceServers': _iceServers,
        'sdpSemantics': 'unified-plan',
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
  
  // FIXED: Add tracks individually instead of adding stream
  Future<void> _addLocalStreamToPeerConnection() async {
    if (_localStream == null || _peerConnection == null) return;
    
    try {
      // Add each track individually for Unified Plan
      for (var track in _localStream!.getTracks()) {
        developer.log('➕ Adding ${track.kind} track to peer connection');
        await _peerConnection!.addTrack(track, _localStream!);
      }
      
      developer.log('✅ All tracks added to peer connection');
    } catch (e) {
      developer.log('❌ Error adding tracks to peer connection: $e');
      // Fallback to addStream for Plan B compatibility
      try {
        await _peerConnection!.addStream(_localStream!);
        developer.log('✅ Stream added using fallback method');
      } catch (fallbackError) {
        developer.log('❌ Fallback addStream also failed: $fallbackError');
        throw Exception('Failed to add media to peer connection: $e');
      }
    }
  }
  
  // Get user media (camera/microphone)
  Future<webrtc.MediaStream> _getUserMedia({bool video = true, bool audio = true}) async {
    try {
      developer.log('📱 Getting user media - Video: $video, Audio: $audio');
      
      final constraints = <String, dynamic>{
        'audio': audio ? {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        } : false,
        'video': video ? {
          'width': {'ideal': 640},
          'height': {'ideal': 480},
          'frameRate': {'ideal': 30},
          'facingMode': 'user',
        } : false,
      };
      
      final stream = await webrtc.navigator.mediaDevices.getUserMedia(constraints);
      
      developer.log('✅ User media obtained successfully');
      return stream;
    } catch (e) {
      developer.log('❌ Error getting user media: $e');
      throw Exception('Failed to get user media: $e');
    }
  }
  
  // Start outgoing call - FIXED VERSION
  Future<String> startCall({
    required String receiverId,
    required String receiverName,
    required String callerId,
    required String callerName,
    required bool isVideoCall,
  }) async {
    try {
      developer.log('📞 Starting ${isVideoCall ? 'video' : 'voice'} call to $receiverId');
      
      // Create unique call ID
      final callId = '${callerId}_${receiverId}_${DateTime.now().millisecondsSinceEpoch}';
      currentCallId.value = callId;
      
      // Get user media
      _localStream = await _getUserMedia(video: isVideoCall, audio: true);
      _localStreamController.add(_localStream);
      
      // Create peer connection
      await _createPeerConnection();
      
      // Add tracks individually instead of adding stream
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
      
      // CRITICAL: Send call notification AFTER Firestore document is created
      await CallNotificationService.sendCallNotification(
        receiverId: receiverId,
        callId: callId,
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
  
  // Answer incoming call - FIXED VERSION
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
      
      // Get user media
      _localStream = await _getUserMedia(video: isVideoCall, audio: true);
      _localStreamController.add(_localStream);
      
      // Create peer connection
      await _createPeerConnection();
      
      // Add tracks individually instead of adding stream
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
  
  // End active call
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
      
      // Close peer connection
      await _peerConnection?.close();
      _peerConnection = null;
      
      // Stop local stream
      if (_localStream != null) {
        for (var track in _localStream!.getTracks()) {
          await track.stop();
        }
        _localStream = null;
      }
      
      // Clear remote stream
      _remoteStream = null;
      
      // Cancel call document subscription
      _callDocSubscription?.cancel();
      
      // Reset observables
      isCallActive.value = false;
      isIncomingCall.value = false;
      isOutgoingCall.value = false;
      isVideoEnabled.value = true;
      isAudioEnabled.value = true;
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
  
  // Toggle video on/off
  Future<void> toggleVideo() async {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        final videoTrack = videoTracks.first;
        videoTrack.enabled = !videoTrack.enabled;
        isVideoEnabled.value = videoTrack.enabled;
        developer.log('📹 Video ${videoTrack.enabled ? 'enabled' : 'disabled'}');
      }
    }
  }
  
  // Toggle audio on/off
  Future<void> toggleAudio() async {
    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        final audioTrack = audioTracks.first;
        audioTrack.enabled = !audioTrack.enabled;
        isAudioEnabled.value = audioTrack.enabled;
        developer.log('🎤 Audio ${audioTrack.enabled ? 'enabled' : 'disabled'}');
      }
    }
  }
  
  // Switch camera (front/back)
  Future<void> switchCamera() async {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        final videoTrack = videoTracks.first;
        await webrtc.Helper.switchCamera(videoTrack);
        developer.log('📱 Camera switched');
      }
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
      'participants': [callerId, receiverId], // ADDED for proper queries
    });
    
    developer.log('✅ Call document created: $callId');
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
  
  // Get current user ID - FIXED
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