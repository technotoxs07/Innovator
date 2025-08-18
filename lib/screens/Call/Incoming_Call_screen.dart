import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:innovator/services/webrtc_call_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:developer' as developer;

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
    
    developer.log('📞 Incoming call screen initialized for: $callerName');
  }

  void _setupAnimations() {
    // Pulse animation for incoming call effect - Fixed with safer values
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // Use safer scale values to avoid painting issues
    _pulseAnimation = Tween<double>(
      begin: 1.0,  // Changed from 0.8 to 1.0
      end: 1.1,    // Changed from 1.2 to 1.1
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
    
    // Start animations after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _pulseController.repeat(reverse: true);
        _slideController.forward();
      }
    });
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
                Colors.blue.shade900,
                Colors.black,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildCallerInfo()),
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

  Widget _buildCallerInfo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Fixed animated caller avatar
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            // Add safety checks for animation values
            final scale = _pulseAnimation.value.clamp(0.5, 2.0);
            
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 75,
                  backgroundColor: Colors.blue,
                  child: Text(
                    callerName.isNotEmpty 
                        ? callerName.substring(0, 1).toUpperCase()
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
        
        // Caller name
        Text(
          callerName,
          style: const TextStyle(
            fontSize: 28,
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
          child: Text(
            isVideoCall ? 'Video Call' : 'Voice Call',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Fixed pulsing dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                // Simplified animation for dots to avoid painting issues
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
          
          // Additional options (mute, speaker, etc.)
          Column(
            children: [
              _buildSmallActionButton(
                onPressed: () {
                  // TODO: Implement mute
                },
                icon: Icons.mic_off,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              _buildSmallActionButton(
                onPressed: () {
                  // TODO: Implement speaker
                },
                icon: Icons.volume_up,
                color: Colors.grey,
              ),
            ],
          ),
          
          // Accept button
          _buildActionButton(
            onPressed: _acceptCall,
            icon: Icons.call,
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

  void _acceptCall() async {
    try {
      developer.log('✅ Accepting call: $callId');
      
      // Haptic feedback
      HapticFeedback.heavyImpact();
      
      // Get call service
      if (!Get.isRegistered<WebRTCCallService>()) {
        Get.put(WebRTCCallService(), permanent: true);
      }
      
      final callService = WebRTCCallService.instance;
      
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
      
      _rejectCall(); // Fallback to reject
    }
  }

  void _rejectCall() async {
    try {
      developer.log('❌ Rejecting call: $callId');
      
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

// Active Call Screen for when call is answered
class ActiveCallScreen extends StatefulWidget {
  @override
  _ActiveCallScreenState createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State<ActiveCallScreen> {
  late WebRTCCallService callService;

  @override
  void initState() {
    super.initState();
    callService = WebRTCCallService.instance;
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
                    ? _buildVideoCallView()
                    : _buildVoiceCallView(),
              ),
              _buildActiveCallActions(),
              const SizedBox(height: 40),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCallHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Obx(() {
        final callData = callService.currentCallData;
        final callerName = callData['callerName']?.toString() ?? 'Unknown';
        final status = callService.callStatus.value;
        
        return Column(
          children: [
            Text(
              callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              status,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildVideoCallView() {
    // TODO: Implement video call view with local and remote video streams
    return Container(
      color: Colors.grey.shade900,
      child: const Center(
        child: Text(
          'Video Call View\n(To be implemented)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildVoiceCallView() {
    return Container(
      child: Center(
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
                  color: Colors.blue,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
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
      ),
    );
  }

  Widget _buildActiveCallActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Obx(() {
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
            if (callService.currentCallData['isVideoCall'] == true)
              _buildToggleButton(
                onPressed: callService.toggleVideo,
                icon: callService.isVideoEnabled.value ? Icons.videocam : Icons.videocam_off,
                isActive: callService.isVideoEnabled.value,
                color: Colors.blue,
              ),
            
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