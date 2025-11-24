import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:innovator/screens/Call/Incoming_Call_screen.dart';
import 'package:innovator/services/webrtc_call_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:developer' as developer;

class OutgoingCallScreen extends StatefulWidget {
  final Map<String, dynamic> callData;

  const OutgoingCallScreen({
    Key? key,
    required this.callData,
  }) : super(key: key);

  @override
  State<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends State<OutgoingCallScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  String get receiverName => widget.callData['receiverName']?.toString() ?? 'Unknown User';
  String get receiverId => widget.callData['receiverId']?.toString() ?? '';
  String get callId => widget.callData['callId']?.toString() ?? '';
  bool get isVideoCall => widget.callData['isVideoCall'] == true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _enableWakelock();
    _setupAutoEndCall();
    _listenToCallStatus();
    
    developer.log('📞 Outgoing call screen initialized for: $receiverName');
  }

  void _setupAnimations() {
    // Pulse animation for calling effect
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);

    // Slide animation for screen entrance
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    _slideController.forward();
  }

  void _enableWakelock() async {
    try {
      await WakelockPlus.enable();
      developer.log('🔒 Wakelock enabled for outgoing call');
    } catch (e) {
      developer.log('❌ Error enabling wakelock: $e');
    }
  }

  void _setupAutoEndCall() {
    // Auto end call after 60 seconds if not answered
    Future.delayed(const Duration(seconds: 60), () {
      if (mounted) {
        developer.log('⏰ Auto-ending call after timeout');
        _endCall();
      }
    });
  }

  void _listenToCallStatus() {
    // Listen to call service status changes
    ever(WebRTCCallService.instance.callStatus, (status) {
      if (mounted) {
        switch (status) {
          case 'Connected':
            // Navigate to active call screen
            Get.off(() => ActiveCallScreen());
            break;
          case 'Call rejected':
          case 'Call ended':
          case 'Connection failed':
            // End call and go back
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Get.back();
              }
            });
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    WakelockPlus.disable();
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
                Colors.green.shade900,
                Colors.black,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildReceiverInfo()),
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
            isVideoCall ? 'Video Calling' : 'Voice Calling',
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

  Widget _buildReceiverInfo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated receiver avatar
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withAlpha(30),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withAlpha(30),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 75,
                  backgroundColor: Colors.green,
                  child: Text(
                    receiverName.isNotEmpty 
                        ? receiverName.substring(0, 1).toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 30),
        
        // Receiver name
        Text(
          receiverName,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        // Call status
        Obx(() {
          return Text(
            WebRTCCallService.instance.callStatus.value,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          );
        }),
        
        const SizedBox(height: 20),
        
        // Animated calling indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                // Stagger the animation for each dot
                final delayedValue = (_pulseController.value + (index * 0.2)) % 1.0;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(
                      0.3 + (0.7 * delayedValue),
                    ),
                  ),
                );
              },
            );
          }),
        ),
        
        const SizedBox(height: 30),
        
        // Connection status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Connecting...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCallActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute button
          Obx(() {
            final isAudioEnabled = WebRTCCallService.instance.isAudioEnabled.value;
            return _buildToggleButton(
              onPressed: () {
                WebRTCCallService.instance.toggleAudio();
              },
              icon: isAudioEnabled ? Icons.mic : Icons.mic_off,
              isActive: isAudioEnabled,
              color: Colors.grey,
            );
          }),
          
          // Video toggle (if video call)
          if (isVideoCall)
            Obx(() {
              final isVideoEnabled = WebRTCCallService.instance.isVideoEnabled.value;
              return _buildToggleButton(
                onPressed: () {
                  WebRTCCallService.instance.toggleVideo();
                },
                icon: isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                isActive: isVideoEnabled,
                color: Colors.blue,
              );
            }),
          
          // Speaker button
          _buildToggleButton(
            onPressed: () {
              // TODO: Implement speaker toggle
            },
            icon: Icons.volume_up,
            isActive: true,
            color: Colors.green,
          ),
          
          // End call button
          _buildActionButton(
            onPressed: _endCall,
            icon: Icons.call_end,
            color: Colors.red,
            size: 70,
          ),
        ],
      ),
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
          color: isActive ? color.withAlpha(30) : Colors.red.withAlpha(30),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(30),
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

  void _endCall() async {
    try {
      developer.log('📞 Ending outgoing call: $callId');
      
      // Haptic feedback
      HapticFeedback.mediumImpact();
      
      // End the call through WebRTC service
      await WebRTCCallService.instance.endCall();
      
      // Navigate back
      Get.back();
      
    } catch (e) {
      developer.log('❌ Error ending call: $e');
      
      // Still go back even if ending fails
      Get.back();
    }
  }
}