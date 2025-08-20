// lib/screens/Call/enhanced_incoming_call_screen.dart - ENHANCED VERSION WITH WHATSAPP FEATURES

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:innovator/services/webrtc_call_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
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
  late AnimationController _acceptController;
  late AnimationController _rejectController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _acceptAnimation;
  late Animation<double> _rejectAnimation;
  
  // Audio and vibration
  AudioPlayer? _audioPlayer;
  bool _isRingtonePlaying = false;
  bool _isVibratingEnabled = true;
  Timer? _vibrationTimer;
  Timer? _autoRejectTimer;
  
  // Audio mode management
  bool _isSpeakerMode = false;
  bool _isMuted = false;
  
  // Video call components
  webrtc.RTCVideoRenderer? _localRenderer;
  bool _isVideoInitialized = false;
  bool _isLocalVideoEnabled = true;
  
  // Call information
  String get callerName => widget.callData['callerName']?.toString() ?? 'Unknown Caller';
  String get callerId => widget.callData['callerId']?.toString() ?? '';
  String get callId => widget.callData['callId']?.toString() ?? '';
  bool get isVideoCall => widget.callData['isVideoCall'] == true;
  String get callerPhoto => widget.callData['callerPhoto']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _enableWakelock();
    _setupAutoReject();
    _startRingtoneAndVibration();
    _initializeAudioPlayer();
    
    // Initialize video preview for video calls
    if (isVideoCall) {
      _initializeVideoPreview();
    }
    
    developer.log('📞 Enhanced incoming call screen initialized for: $callerName');
  }

  void _setupAnimations() {
    // Pulse animation for caller avatar
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Slide animation for screen entrance
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    // Accept button animation
    _acceptController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _acceptAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _acceptController,
      curve: Curves.elasticInOut,
    ));

    // Reject button animation
    _rejectController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _rejectAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _rejectController,
      curve: Curves.elasticInOut,
    ));
    
    // Start animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _pulseController.repeat(reverse: true);
        _slideController.forward();
        _acceptController.repeat(reverse: true);
        _rejectController.repeat(reverse: true);
      }
    });
  }

  Future<void> _initializeAudioPlayer() async {
    try {
      _audioPlayer = AudioPlayer();
      developer.log('🎵 Audio player initialized');
    } catch (e) {
      developer.log('❌ Error initializing audio player: $e');
    }
  }

  Future<void> _startRingtoneAndVibration() async {
    try {
      developer.log('🔔 Starting ringtone and vibration...');
      
      _isRingtonePlaying = true;
      
      // Start default ringtone
      await FlutterRingtonePlayer().playRingtone(
        looping: true,
        volume: 1.0,
        asAlarm: false,
      );
      
      // Start vibration pattern (WhatsApp-like)
      _startVibrationPattern();
      
      developer.log('✅ Ringtone and vibration started');
      
    } catch (e) {
      developer.log('❌ Error starting ringtone: $e');
      // Fallback to system sounds
      await _playSystemRingtone();
    }
  }

  void _startVibrationPattern() async {
    if (!_isVibratingEnabled) return;
    
    try {
      // Check if device supports vibration
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator != true) return;
      
      // WhatsApp-like vibration pattern
      _vibrationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (_isRingtonePlaying && mounted) {
          Vibration.vibrate(
            pattern: [0, 500, 200, 500, 200, 500], // Vibrate, pause, vibrate...
            intensities: [0, 255, 0, 255, 0, 255],
          );
        } else {
          timer.cancel();
        }
      });
      
    } catch (e) {
      developer.log('❌ Error starting vibration: $e');
    }
  }

  Future<void> _playSystemRingtone() async {
    try {
      // Create a repeating timer for system sounds as fallback
      Timer.periodic(const Duration(seconds: 3), (timer) {
        if (_isRingtonePlaying && mounted) {
          SystemSound.play(SystemSoundType.click);
          HapticFeedback.heavyImpact();
        } else {
          timer.cancel();
        }
      });
      
      developer.log('✅ System ringtone fallback started');
    } catch (e) {
      developer.log('❌ System ringtone fallback failed: $e');
    }
  }

  Future<void> _stopRingtoneAndVibration() async {
    try {
      _isRingtonePlaying = false;
      _vibrationTimer?.cancel();
      
      await FlutterRingtonePlayer().stop();
      await Vibration.cancel();
      
      developer.log('🔇 Ringtone and vibration stopped');
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
      
      // Get camera stream for preview (low quality for preview)
      final constraints = {
        'audio': false, // No audio for preview
        'video': {
          'width': {'ideal': 320},
          'height': {'ideal': 240},
          'frameRate': {'ideal': 15},
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

    if (_localRenderer != null) {
      if (!_isLocalVideoEnabled) {
        _localRenderer!.srcObject = null;
      } else {
        // Re-initialize if needed
        _initializeVideoPreview();
      }
    }
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerMode = !_isSpeakerMode;
    });
    
    // Apply speaker setting
    webrtc.Helper.setSpeakerphoneOn(_isSpeakerMode);
    
    developer.log('🔊 Speaker mode: ${_isSpeakerMode ? 'ON' : 'OFF'}');
    
    // Show feedback
    HapticFeedback.lightImpact();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    
    if (_isMuted) {
      _stopRingtoneAndVibration();
    } else {
      _startRingtoneAndVibration();
    }
    
    developer.log('🔇 Muted: ${_isMuted ? 'YES' : 'NO'}');
    
    // Show feedback
    HapticFeedback.lightImpact();
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
    // Auto reject after 45 seconds (WhatsApp-like)
    _autoRejectTimer = Timer(const Duration(seconds: 45), () {
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
    _acceptController.dispose();
    _rejectController.dispose();
    _stopRingtoneAndVibration();
    _vibrationTimer?.cancel();
    _autoRejectTimer?.cancel();
    WakelockPlus.disable();
    
    // Dispose video resources
    _localRenderer?.dispose();
    _audioPlayer?.dispose();
    
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
                isVideoCall 
                    ? Colors.blue.shade900.withOpacity(0.8)
                    : Colors.green.shade900.withOpacity(0.8),
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
                const SizedBox(height: 30),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Call type indicator
          Row(
            children: [
              Icon(
                isVideoCall ? Icons.videocam : Icons.phone,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isVideoCall ? 'Incoming video call' : 'Incoming call',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          // Audio controls
          Row(
            children: [
              // Mute toggle
              GestureDetector(
                onTap: _toggleMute,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(_isMuted ? 0.3 : 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Speaker toggle
              GestureDetector(
                onTap: _toggleSpeaker,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(_isSpeakerMode ? 0.3 : 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _isSpeakerMode ? Icons.speaker_phone : Icons.phone_android,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCallView() {
    return Column(
      children: [
        // Remote video area (placeholder)
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Placeholder for remote video
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.shade800,
                          Colors.blue.shade900,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Caller avatar
                        _buildCallerAvatar(size: 100),
                        const SizedBox(height: 16),
                        Text(
                          callerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Connecting...',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Local video preview (bottom right)
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: GestureDetector(
                      onTap: _toggleLocalVideo,
                      child: Container(
                        width: 120,
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
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
                          borderRadius: BorderRadius.circular(14),
                          child: _isVideoInitialized && 
                                 _localRenderer != null && 
                                 _isLocalVideoEnabled
                              ? webrtc.RTCVideoView(
                                  _localRenderer!,
                                  mirror: true,
                                  objectFit: webrtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.blue, Colors.blue.shade800],
                                    ),
                                  ),
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
                  ),
                  
                  // Video controls overlay
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: _toggleLocalVideo,
                            child: Icon(
                              _isLocalVideoEnabled ? Icons.videocam : Icons.videocam_off,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () {
                              // Switch camera
                              if (_localRenderer?.srcObject != null) {
                                final stream = _localRenderer!.srcObject as webrtc.MediaStream;
                                final videoTracks = stream.getVideoTracks();
                                if (videoTracks.isNotEmpty) {
                                  webrtc.Helper.switchCamera(videoTracks.first);
                                }
                              }
                            },
                            child: const Icon(
                              Icons.flip_camera_ios,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Caller info section (compact for video)
        Expanded(
          flex: 1,
          child: _buildCompactCallerInfo(),
        ),
      ],
    );
  }

  Widget _buildVoiceCallView() {
    return _buildFullCallerInfo();
  }

  Widget _buildCallerAvatar({double size = 150}) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isVideoCall ? Colors.blue : Colors.green).withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: size / 2,
              backgroundColor: isVideoCall ? Colors.blue : Colors.green,
              backgroundImage: callerPhoto.isNotEmpty 
                  ? NetworkImage(callerPhoto)
                  : null,
              child: callerPhoto.isEmpty
                  ? Text(
                      callerName.isNotEmpty 
                          ? callerName.substring(0, 1).toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontSize: size * 0.4,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFullCallerInfo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Main caller avatar
        _buildCallerAvatar(),
        
        const SizedBox(height: 30),
        
        // Caller name
        Text(
          callerName,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 12),
        
        // Call type badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isVideoCall ? Icons.videocam : Icons.phone,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                isVideoCall ? 'Video call' : 'Voice call',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 30),
        
        // Animated ringing indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final delay = index * 0.3;
                final animValue = (_pulseController.value + delay) % 1.0;
                final opacity = (0.3 + (0.7 * animValue)).clamp(0.0, 1.0);
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 12,
                  height: 12,
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
    );
  }

  Widget _buildCompactCallerInfo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          callerName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Video calling...',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildCallActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Decline button (animated)
          AnimatedBuilder(
            animation: _rejectAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _rejectAnimation.value,
                child: _buildMainActionButton(
                  onPressed: _rejectCall,
                  icon: Icons.call_end,
                  color: Colors.red,
                  size: 70,
                ),
              );
            },
          ),
          
          // Additional controls
          Column(
            children: [
              _buildSmallActionButton(
                onPressed: _toggleMute,
                icon: _isMuted ? Icons.volume_off : Icons.volume_up,
                color: _isMuted ? Colors.orange : Colors.grey,
                label: _isMuted ? 'Unmute' : 'Mute',
              ),
              const SizedBox(height: 20),
              _buildSmallActionButton(
                onPressed: _toggleSpeaker,
                icon: _isSpeakerMode ? Icons.speaker_phone : Icons.phone_android,
                color: _isSpeakerMode ? Colors.blue : Colors.grey,
                label: _isSpeakerMode ? 'Earpiece' : 'Speaker',
              ),
            ],
          ),
          
          // Accept button (animated)
          AnimatedBuilder(
            animation: _acceptAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _acceptAnimation.value,
                child: _buildMainActionButton(
                  onPressed: _acceptCall,
                  icon: isVideoCall ? Icons.videocam : Icons.call,
                  color: Colors.green,
                  size: 70,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainActionButton({
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
              color: color.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.45,
        ),
      ),
    );
  }

  Widget _buildSmallActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.3),
              border: Border.all(
                color: color.withOpacity(0.6),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptCall() async {
    try {
      developer.log('✅ Accepting call: $callId');
      
      // Stop ringtone and vibration
      await _stopRingtoneAndVibration();
      
      // Haptic feedback
      HapticFeedback.heavyImpact();
      
      // Get call service
      if (!Get.isRegistered<WebRTCCallService>()) {
        Get.put(WebRTCCallService(), permanent: true);
      }
      
      final callService = WebRTCCallService.instance;
      
      // For video calls, dispose preview renderer
      if (isVideoCall && _localRenderer != null) {
        _localRenderer!.srcObject = null;
        await _localRenderer!.dispose();
        _localRenderer = null;
      }
      
      // Set speaker mode for video calls
      if (isVideoCall) {
        await callService.setSpeaker(true);
      } else {
        await callService.setSpeaker(_isSpeakerMode);
      }
      
      // Answer the call
      await callService.answerCall(callId);
      
      // Navigate to active call screen
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
      
      _rejectCall(); // Fallback
    }
  }

  void _rejectCall() async {
    try {
      developer.log('❌ Rejecting call: $callId');
      
      // Stop ringtone and vibration
      await _stopRingtoneAndVibration();
      
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

// Enhanced Active Call Screen with proper video rendering
class ActiveCallScreen extends StatefulWidget {
  @override
  _ActiveCallScreenState createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State<ActiveCallScreen> with TickerProviderStateMixin {
  late WebRTCCallService callService;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  bool _isControlsVisible = true;
  Timer? _controlsTimer;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    callService = WebRTCCallService.instance;
    
    _setupAnimations();
    _setupControlsAutoHide();
    _enableWakelock();
    
    // Listen for call end
    ever(callService.isCallActive, (isActive) {
      if (!isActive && mounted) {
        Get.back();
      }
    });
    
    developer.log('📱 Active call screen initialized');
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = _fadeController.drive(Tween(begin: 0.0, end: 1.0));
    _fadeController.forward();
  }

  void _setupControlsAutoHide() {
    // Auto-hide controls after 5 seconds
    _resetControlsTimer();
  }

  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _isControlsVisible) {
        setState(() {
          _isControlsVisible = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _isControlsVisible = !_isControlsVisible;
    });
    if (_isControlsVisible) {
      _resetControlsTimer();
    }
  }

  void _enableWakelock() async {
    try {
      await WakelockPlus.enable();
    } catch (e) {
      developer.log('❌ Error enabling wakelock: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _controlsTimer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        final callData = callService.currentCallData;
        final isVideoCall = callData['isVideoCall'] == true;
        
        return GestureDetector(
          onTap: _toggleControls,
          child: Stack(
            children: [
              // Main call interface
              if (isVideoCall)
                _buildVideoCallInterface()
              else
                _buildVoiceCallInterface(),
              
              // Controls overlay
              if (_isControlsVisible)
                _buildControlsOverlay(),
              
              // Call info overlay
              if (_isControlsVisible)
                _buildCallInfoOverlay(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildVideoCallInterface() {
    return Stack(
      children: [
        // Remote video (full screen)
        Container(
          width: double.infinity,
          height: double.infinity,
          child: callService.remoteRenderer != null
              ? webrtc.RTCVideoView(
                  callService.remoteRenderer!,
                  objectFit: webrtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.blue.shade900,
                        Colors.black,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Connecting...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        
        // Local video (picture-in-picture)
        Positioned(
          top: 60,
          right: 20,
          child: Obx(() => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isFullscreen ? 0 : 120,
            height: _isFullscreen ? 0 : 160,
            child: callService.isVideoEnabled.value && callService.localRenderer != null
                ? GestureDetector(
                    onTap: () {
                      // Switch between main and PiP
                      setState(() {
                        _isFullscreen = !_isFullscreen;
                      });
                    },
                    child: Container(
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
                        child: webrtc.RTCVideoView(
                          callService.localRenderer!,
                          mirror: true,
                          objectFit: webrtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        ),
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.videocam_off,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
          )),
        ),
      ],
    );
  }

  Widget _buildVoiceCallInterface() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green.shade900,
            Colors.black,
          ],
        ),
      ),
      child: Center(
        child: Obx(() {
          final callData = callService.currentCallData;
          final receiverName = callData['receiverName']?.toString() ?? 
                              callData['callerName']?.toString() ?? 'Unknown';
          
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
                    receiverName.isNotEmpty 
                        ? receiverName.substring(0, 1).toUpperCase()
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
              
              // Name
              Text(
                receiverName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Call status
              Text(
                callService.callStatus.value,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCallInfoOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: _isControlsVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            bottom: 20,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
              ],
            ),
          ),
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
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: _isControlsVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: EdgeInsets.only(
            left: 40,
            right: 40,
            bottom: MediaQuery.of(context).padding.bottom + 30,
            top: 30,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.transparent,
              ],
            ),
          ),
          child: _buildCallActions(),
        ),
      ),
    );
  }

  Widget _buildCallActions() {
    return Obx(() {
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
            onPressed: callService.toggleSpeaker,
            icon: callService.isSpeakerOn.value ? Icons.volume_up : Icons.volume_down,
            isActive: callService.isSpeakerOn.value,
            color: Colors.green,
          ),
          
          // Camera switch (if video call)
          if (isVideoCall)
            _buildActionButton(
              onPressed: callService.switchCamera,
              icon: Icons.flip_camera_ios,
              color: Colors.orange,
              size: 50,
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
    });
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