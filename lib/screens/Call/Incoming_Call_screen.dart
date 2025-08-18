import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:innovator/services/webrtc_call_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'dart:developer' as developer;
import 'dart:async';

class IncomingCallScreen extends StatefulWidget {
  final Map<String, dynamic> callData;

  const IncomingCallScreen({
    Key? key,
    required this.callData,
  }) : super(key: key);

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isRingtonePlaying = false;
  
  // Video call components
  webrtc.RTCVideoRenderer? _localRenderer;
  bool _isVideoInitialized = false;
  bool _isLocalVideoEnabled = true;
  
  String get callerName => widget.callData['callerName']?.toString() ?? 'Unknown Caller';
  String get callerId => widget.callData['callerId']?.toString() ?? '';
  String get callId => widget.callData['callId']?.toString() ?? '';
  bool get isVideoCall => widget.callData['isVideoCall'] == true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _enableWakelock();
    _setupAutoReject();
    _startRingtone();
    
    // Initialize video if it's a video call
    if (isVideoCall) {
      _initializeVideoPreview();
    }
    
    developer.log('📞 Enhanced incoming call screen initialized for: $callerName');
  }

  void _setupAnimations() {
    // Pulse animation for incoming call effect
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Slide animation for screen entrance
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    // Start animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _pulseController.repeat(reverse: true);
        _slideController.forward();
      }
    });
  }

  Future<void> _startRingtone() async {
    try {
      developer.log('🔔 Starting default ringtone...');
      
      _isRingtonePlaying = true;
      
      FlutterRingtonePlayer().playRingtone(looping: true, volume: 1.0, asAlarm: false);
      
      developer.log('✅ Default ringtone started');
      
      // Also vibrate
      _startVibration();
      
    } catch (e) {
      developer.log('❌ Error starting default ringtone: $e');
      // Fallback to system sounds
      await _playSystemRingtone();
    }
  }

  Future<void> _playSystemRingtone() async {
    try {
      // Use system sounds as fallback
      await SystemSound.play(SystemSoundType.click);
      
      // Create a repeating timer for system sounds
      Timer.periodic(const Duration(seconds: 2), (timer) {
        if (_isRingtonePlaying && mounted) {
          SystemSound.play(SystemSoundType.click);
        } else {
          timer.cancel();
        }
      });
      
      developer.log('✅ System ringtone fallback started');
    } catch (e) {
      developer.log('❌ System ringtone fallback failed: $e');
    }
  }

  void _startVibration() {
    // Vibration pattern for incoming call
    Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (_isRingtonePlaying && mounted) {
        HapticFeedback.heavyImpact();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _stopRingtone() async {
    try {
      _isRingtonePlaying = false;
      FlutterRingtonePlayer().stop();
      developer.log('🔇 Ringtone stopped');
    } catch (e) {
      developer.log('❌ Error stopping ringtone: $e');
    }
  }

  Future<void> _initializeVideoPreview() async {
    try {
      developer.log('📹 Initializing video preview...');
      
      // Initialize local renderer
      _localRenderer = webrtc.RTCVideoRenderer();
      await _localRenderer!.initialize();
      
      // Get camera stream for preview
      final constraints = {
        'audio': false, // Only video for preview
        'video': {
          'width': {'ideal': 320},
          'height': {'ideal': 240},
          'frameRate': {'ideal': 15}, // Lower framerate for preview
          'facingMode': 'user',
        },
      };
      
      final localStream = await webrtc.navigator.mediaDevices.getUserMedia(constraints);
      _localRenderer!.srcObject = localStream;
      
      setState(() {
        _isVideoInitialized = true;
        _isLocalVideoEnabled = true;
      });
      
      developer.log('✅ Video preview initialized');
    } catch (e) {
      developer.log('❌ Error initializing video preview: $e');
      setState(() {
        _isVideoInitialized = false;
      });
    }
  }

  void _toggleLocalVideo() {
    if (!_isVideoInitialized) {
      _initializeVideoPreview();
      return;
    }

    setState(() {
      _isLocalVideoEnabled = !_isLocalVideoEnabled;
    });

    if (_isLocalVideoEnabled) {
      _localRenderer!.srcObject = _localRenderer!.srcObject; // Re-enable
    } else {
      _localRenderer!.srcObject = null;
    }
  }

  void _enableWakelock() async {
    try {
      await WakelockPlus.enable();
      developer.log('🔒 Wakelock enabled for incoming call');
    } catch (e) {
      developer.log('❌ Error enabling wakelock: $e');
    }
  }

  void _setupAutoReject() {
    // Auto reject after 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        developer.log('⏰ Auto-rejecting call after timeout');
        _rejectCall();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _stopRingtone();
    WakelockPlus.disable();
    
    // Dispose video resources
    _localRenderer?.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                isVideoCall ? Colors.blue.shade900 : Colors.green.shade900,
                Colors.black,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: isVideoCall 
                      ? _buildVideoCallView()
                      : _buildVoiceCallView(),
                ),
                _buildCallActions(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isVideoCall ? Icons.videocam : Icons.phone,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            isVideoCall ? 'Incoming Video Call' : 'Incoming Voice Call',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCallView() {
    return Column(
      children: [
        // Remote video area (placeholder since not connected yet)
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Placeholder for remote
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.grey.shade800,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person,
                            size: 80,
                            color: Colors.white54,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Waiting for video...',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Local video preview (bottom right corner)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      width: 120,
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _isVideoInitialized && _localRenderer != null && _isLocalVideoEnabled
                            ? webrtc.RTCVideoView(
                                _localRenderer!,
                                mirror: true,
                              )
                            : Container(
                                color: Colors.blue,
                                child: const Center(
                                  child: Icon(
                                    Icons.videocam_off,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Caller info for video call
        Expanded(
          flex: 1,
          child: _buildCallerInfoSection(),
        ),
      ],
    );
  }

  Widget _buildVoiceCallView() {
    return _buildCallerInfoSection();
  }

  Widget _buildCallerInfoSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated caller avatar
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            final scale = _pulseAnimation.value.clamp(0.5, 2.0);
            
            return Transform.scale(
              scale: scale,
              child: Container(
                width: isVideoCall ? 80 : 150,
                height: isVideoCall ? 80 : 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isVideoCall ? Colors.blue : Colors.green).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: isVideoCall ? 40 : 75,
                  backgroundColor: isVideoCall ? Colors.blue : Colors.green,
                  child: Text(
                    callerName.isNotEmpty 
                        ? callerName.substring(0, 1).toUpperCase()
                        : 'U',
                    style: TextStyle(
                      fontSize: isVideoCall ? 35 : 60,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 20),
        
        // Caller name
        Text(
          callerName,
          style: TextStyle(
            fontSize: isVideoCall ? 22 : 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        // Call type indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isVideoCall ? Icons.videocam : Icons.phone,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                isVideoCall ? 'Video Call' : 'Voice Call',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        
        if (!isVideoCall) ...[
          const SizedBox(height: 20),
          
          // Pulsing dots indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final opacity = (0.3 + (0.7 * (_pulseController.value))).clamp(0.0, 1.0);
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(opacity),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildCallActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Decline button
          _buildActionButton(
            onPressed: _rejectCall,
            icon: Icons.call_end,
            color: Colors.red,
            size: 70,
          ),
          
          // Additional options
          if (isVideoCall)
            Column(
              children: [
                _buildSmallActionButton(
                  onPressed: _toggleLocalVideo,
                  icon: _isLocalVideoEnabled ? Icons.videocam : Icons.videocam_off,
                  color: _isLocalVideoEnabled ? Colors.blue : Colors.grey,
                ),
                const SizedBox(height: 16),
                _buildSmallActionButton(
                  onPressed: _toggleSpeaker,
                  icon: Icons.volume_up,
                  color: Colors.grey,
                ),
              ],
            )
          else
            Column(
              children: [
                _buildSmallActionButton(
                  onPressed: _toggleMutePreview,
                  icon: Icons.mic_off,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                _buildSmallActionButton(
                  onPressed: _toggleSpeaker,
                  icon: Icons.volume_up,
                  color: Colors.grey,
                ),
              ],
            ),
          
          // Accept button
          _buildActionButton(
            onPressed: _acceptCall,
            icon: isVideoCall ? Icons.videocam : Icons.call,
            color: Colors.green,
            size: 70,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
    required double size,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.4,
        ),
      ),
    );
  }

  Widget _buildSmallActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.3),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  void _toggleMutePreview() {
    // For voice call preview, but since no audio in preview, perhaps mute ringtone or something
    // Implementing as toggle ringtone mute for simplicity
    if (_isRingtonePlaying) {
      FlutterRingtonePlayer().stop();
    } else {
      FlutterRingtonePlayer().playRingtone(looping: true);
    }
    setState(() {
      _isRingtonePlaying = !_isRingtonePlaying;
    });
  }

  void _toggleSpeaker() {
    // For ringtone, but flutter_ringtone_player doesn't directly support speaker toggle
    // For simplicity, we can assume it's for future audio, or ignore in incoming
    developer.log('Speaker toggle in incoming call (for ringtone/audio preview)');
    webrtc.Helper.setSpeakerphoneOn(true); // Force to speaker for example
  }

  Future<void> _acceptCall() async {
    try {
      developer.log('✅ Accepting call: $callId');
      
      // Stop ringtone
      await _stopRingtone();
      
      // Haptic feedback
      HapticFeedback.heavyImpact();
      
      // Get call service
      if (!Get.isRegistered<WebRTCCallService>()) {
        Get.put(WebRTCCallService(), permanent: true);
      }
      
      final callService = WebRTCCallService.instance;
      
      // For video calls, dispose preview renderer (service will handle new streams)
      if (isVideoCall && _localRenderer != null) {
        _localRenderer!.srcObject = null;
        await _localRenderer!.dispose();
        _localRenderer = null;
      }
      
      // Answer the call
      await callService.answerCall(callId);
      
      // Navigate to enhanced active call screen
      Get.off(() => ActiveCallScreen());
      
    } catch (e) {
      developer.log('❌ Error accepting call: $e');
      
      Get.snackbar(
        'Call Error',
        'Failed to accept call: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      
      _rejectCall(); // Fallback to reject
    }
  }

  void _rejectCall() async {
    try {
      developer.log('❌ Rejecting call: $callId');
      
      // Stop ringtone
      await _stopRingtone();
      
      // Haptic feedback
      HapticFeedback.mediumImpact();
      
      // Get call service
      if (!Get.isRegistered<WebRTCCallService>()) {
        Get.put(WebRTCCallService(), permanent: true);
      }
      
      final callService = WebRTCCallService.instance;
      
      // Reject the call
      await callService.rejectCall(callId);
      
      // Close this screen
      Get.back();
      
    } catch (e) {
      developer.log('❌ Error rejecting call: $e');
      
      // Still close the screen even if reject fails
      Get.back();
    }
  }
}

// Enhanced Active Call Screen with full video support
class ActiveCallScreen extends StatefulWidget {
  @override
  _ActiveCallScreenState createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State<ActiveCallScreen> {
  late WebRTCCallService callService;
  webrtc.RTCVideoRenderer? _localRenderer;
  webrtc.RTCVideoRenderer? _remoteRenderer;
  bool _isLocalVideoVisible = true;
  bool _isSpeakerOn = false;

  @override
  void initState() {
    super.initState();
    callService = WebRTCCallService.instance;
    _initializeVideoRenderers();
    _setupStreamListeners();
    _toggleSpeaker(); // Default to earpiece or speaker
  }

  Future<void> _initializeVideoRenderers() async {
    try {
      _localRenderer = webrtc.RTCVideoRenderer();
      _remoteRenderer = webrtc.RTCVideoRenderer();
      
      await _localRenderer!.initialize();
      await _remoteRenderer!.initialize();
      
      developer.log('✅ Video renderers initialized');
    } catch (e) {
      developer.log('❌ Error initializing video renderers: $e');
    }
  }

  void _setupStreamListeners() {
    // Listen to local stream
    callService.localStream.listen((stream) {
      if (stream != null && _localRenderer != null) {
        _localRenderer!.srcObject = stream;
        setState(() {});
      }
    });
    
    // Listen to remote stream
    callService.remoteStream.listen((stream) {
      if (stream != null && _remoteRenderer != null) {
        _remoteRenderer!.srcObject = stream;
        setState(() {});
      }
    });
  }

  void _toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    webrtc.Helper.setSpeakerphoneOn(_isSpeakerOn);
    developer.log('Speaker toggled to ${_isSpeakerOn ? "on" : "off"}');
  }

  @override
  void dispose() {
    _localRenderer?.dispose();
    _remoteRenderer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        final callData = callService.currentCallData;
        final isVideoCall = callData['isVideoCall'] == true;
        
        return SafeArea(
          child: Column(
            children: [
              _buildCallHeader(),
              Expanded(
                child: isVideoCall 
                    ? _buildVideoCallInterface()
                    : _buildVoiceCallInterface(),
              ),
              _buildActiveCallActions(),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCallHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        final callData = callService.currentCallData;
        final isVideoCall = callData['isVideoCall'] == true;
        final receiverName = callData['receiverName']?.toString() ?? 
                            callData['callerName']?.toString() ?? 'Unknown';
        final status = callService.callStatus.value;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Call info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receiverName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isVideoCall ? Icons.videocam : Icons.phone,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Minimize button
            IconButton(
              onPressed: () {
                // Minimize to floating widget (implement as needed)
                Get.back();
              },
              icon: const Icon(
                Icons.minimize,
                color: Colors.white,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildVideoCallInterface() {
    return Stack(
      children: [
        // Remote video (full screen)
        if (_remoteRenderer != null)
          webrtc.RTCVideoView(
            _remoteRenderer!,
            objectFit: webrtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          )
        else
          Container(
            color: Colors.grey.shade900,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person,
                    size: 100,
                    color: Colors.white54,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Connecting...',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Local video (picture-in-picture)
        if (_isLocalVideoVisible)
          Positioned(
            top: 20,
            right: 20,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isLocalVideoVisible = !_isLocalVideoVisible;
                });
              },
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _localRenderer != null
                      ? webrtc.RTCVideoView(
                          _localRenderer!,
                          mirror: true,
                          objectFit: webrtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        )
                      : Container(
                          color: Colors.blue,
                          child: const Center(
                            child: Icon(
                              Icons.videocam_off,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        
        // Video controls overlay
        Positioned(
          bottom: 20,
          left: 20,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    callService.switchCamera();
                  },
                  icon: const Icon(
                    Icons.flip_camera_ios,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: callService.toggleVideo,
                  icon: Icon(
                    callService.isVideoEnabled.value ? Icons.videocam : Icons.videocam_off,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceCallInterface() {
    return Center(
      child: Obx(() {
        final callData = callService.currentCallData;
        final callerName = callData['callerName']?.toString() ?? 'Unknown';
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Large avatar
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  callerName.isNotEmpty 
                      ? callerName.substring(0, 1).toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Call status
            Text(
              callService.callStatus.value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildActiveCallActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Obx(() {
        final isVideoCall = callService.currentCallData['isVideoCall'] == true;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Mute button
            _buildToggleButton(
              onPressed: callService.toggleAudio,
              icon: callService.isAudioEnabled.value ? Icons.mic : Icons.mic_off,
              isActive: callService.isAudioEnabled.value,
              color: Colors.grey,
            ),
            
            // Video toggle (if video call)
            if (isVideoCall)
              _buildToggleButton(
                onPressed: callService.toggleVideo,
                icon: callService.isVideoEnabled.value ? Icons.videocam : Icons.videocam_off,
                isActive: callService.isVideoEnabled.value,
                color: Colors.blue,
              ),
            
            // Speaker button
            _buildToggleButton(
              onPressed: _toggleSpeaker,
              icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
              isActive: _isSpeakerOn,
              color: Colors.green,
            ),
            
            // End call button
            _buildActionButton(
              onPressed: () async {
                await callService.endCall();
                Get.back();
              },
              icon: Icons.call_end,
              color: Colors.red,
              size: 60,
            ),
          ],
        );
      }),
    );
  }

  Widget _buildToggleButton({
    required VoidCallback onPressed,
    required IconData icon,
    required bool isActive,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? color.withOpacity(0.3) : Colors.red.withOpacity(0.3),
          border: Border.all(
            color: isActive ? color : Colors.red,
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
    required double size,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.4,
        ),
      ),
    );
  }
}