// // lib/screens/Call/enhanced_active_call_screen.dart - ENHANCED VERSION

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
// import 'package:innovator/services/webrtc_call_service.dart';
// import 'package:wakelock_plus/wakelock_plus.dart';
// import 'dart:developer' as developer;
// import 'dart:async';

// class ActiveCallScreen extends StatefulWidget {
//   @override
//   _ActiveCallScreenState createState() => _ActiveCallScreenState();
// }

// class _ActiveCallScreenState extends State<ActiveCallScreen> 
//     with TickerProviderStateMixin {
//   late WebRTCCallService callService;
//   late AnimationController _fadeController;
//   late AnimationController _pulseController;
//   late Animation<double> _fadeAnimation;
//   late Animation<double> _pulseAnimation;
  
//   bool _isControlsVisible = true;
//   Timer? _controlsTimer;
//   bool _isFullscreen = false;
//   bool _isPipMode = false;
  
//   // Call duration tracking
//   Timer? _durationTimer;
//   int _callDurationSeconds = 0;

//   @override
//   void initState() {
//     super.initState();
//     callService = WebRTCCallService.instance;
    
//     _setupAnimations();
//     _setupControlsAutoHide();
//     _enableWakelock();
//     _startCallDurationTimer();
    
//     // Listen for call end
//     ever(callService.isCallActive, (isActive) {
//       if (!isActive && mounted) {
//         Get.back();
//       }
//     });
    
//     developer.log('📱 Enhanced active call screen initialized');
//   }

//   void _setupAnimations() {
//     _fadeController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//     _fadeAnimation = _fadeController.drive(Tween(begin: 0.0, end: 1.0));
//     _fadeController.forward();
    
//     _pulseController = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     );
//     _pulseAnimation = Tween<double>(
//       begin: 1.0,
//       end: 1.05,
//     ).animate(CurvedAnimation(
//       parent: _pulseController,
//       curve: Curves.easeInOut,
//     ));
//     _pulseController.repeat(reverse: true);
//   }

//   void _setupControlsAutoHide() {
//     _resetControlsTimer();
//   }

//   void _resetControlsTimer() {
//     _controlsTimer?.cancel();
//     _controlsTimer = Timer(const Duration(seconds: 5), () {
//       if (mounted && _isControlsVisible) {
//         setState(() {
//           _isControlsVisible = false;
//         });
//       }
//     });
//   }

//   void _toggleControls() {
//     setState(() {
//       _isControlsVisible = !_isControlsVisible;
//     });
//     if (_isControlsVisible) {
//       _resetControlsTimer();
//     }
//   }

//   void _enableWakelock() async {
//     try {
//       await WakelockPlus.enable();
//     } catch (e) {
//       developer.log('❌ Error enabling wakelock: $e');
//     }
//   }

//   void _startCallDurationTimer() {
//     _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (mounted && callService.isCallActive.value) {
//         setState(() {
//           _callDurationSeconds++;
//         });
//       } else {
//         timer.cancel();
//       }
//     });
//   }

//   String _formatCallDuration(int seconds) {
//     final hours = seconds ~/ 3600;
//     final minutes = (seconds % 3600) ~/ 60;
//     final secs = seconds % 60;
    
//     if (hours > 0) {
//       return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
//     } else {
//       return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
//     }
//   }

//   @override
//   void dispose() {
//     _fadeController.dispose();
//     _pulseController.dispose();
//     _controlsTimer?.cancel();
//     _durationTimer?.cancel();
//     WakelockPlus.disable();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Obx(() {
//         final callData = callService.currentCallData;
//         final isVideoCall = callData['isVideoCall'] == true;
        
//         return GestureDetector(
//           onTap: _toggleControls,
//           child: Stack(
//             children: [
//               // Main call interface
//               if (isVideoCall)
//                 _buildVideoCallInterface()
//               else
//                 _buildVoiceCallInterface(),
              
//               // Controls overlay
//               AnimatedOpacity(
//                 opacity: _isControlsVisible ? 1.0 : 0.0,
//                 duration: const Duration(milliseconds: 300),
//                 child: _buildControlsOverlay(),
//               ),
              
//               // Call info overlay
//               AnimatedOpacity(
//                 opacity: _isControlsVisible ? 1.0 : 0.0,
//                 duration: const Duration(milliseconds: 300),
//                 child: _buildCallInfoOverlay(),
//               ),
//             ],
//           ),
//         );
//       }),
//     );
//   }

//   Widget _buildVideoCallInterface() {
//     return Stack(
//       children: [
//         // Remote video (full screen)
//         Container(
//           width: double.infinity,
//           height: double.infinity,
//           child: callService.remoteRenderer != null
//               ? webrtc.RTCVideoView(
//                   callService.remoteRenderer!,
//                   objectFit: webrtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
//                 )
//               : _buildWaitingForVideoView(),
//         ),
        
//         // Local video (picture-in-picture)
//         if (!_isFullscreen)
//           Positioned(
//             top: 80,
//             right: 20,
//             child: _buildLocalVideoView(),
//           ),
        
//         // Video call stats (debug info)
//         if (_isControlsVisible)
//           Positioned(
//             top: 120,
//             left: 20,
//             child: _buildVideoStats(),
//           ),
//       ],
//     );
//   }

//   Widget _buildWaitingForVideoView() {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [
//             Colors.blue.shade900,
//             Colors.black,
//           ],
//         ),
//       ),
//       child: Center(
//         child: Obx(() {
//           final callData = callService.currentCallData;
//           final receiverName = callData['receiverName']?.toString() ?? 
//                               callData['callerName']?.toString() ?? 'Unknown';
          
//           return Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               // Animated avatar
//               AnimatedBuilder(
//                 animation: _pulseAnimation,
//                 builder: (context, child) {
//                   return Transform.scale(
//                     scale: _pulseAnimation.value,
//                     child: Container(
//                       width: 120,
//                       height: 120,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: Colors.blue,
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.blue.withAlpha(30),
//                             blurRadius: 20,
//                             spreadRadius: 5,
//                           ),
//                         ],
//                       ),
//                       child: Center(
//                         child: Text(
//                           receiverName.isNotEmpty 
//                               ? receiverName.substring(0, 1).toUpperCase()
//                               : 'U',
//                           style: const TextStyle(
//                             fontSize: 50,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
              
//               const SizedBox(height: 30),
              
//               Text(
//                 receiverName,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
              
//               const SizedBox(height: 10),
              
//               Text(
//                 callService.callStatus.value,
//                 style: const TextStyle(
//                   color: Colors.white70,
//                   fontSize: 16,
//                 ),
//               ),
              
//               const SizedBox(height: 20),
              
//               const CircularProgressIndicator(
//                 color: Colors.white,
//                 strokeWidth: 2,
//               ),
//             ],
//           );
//         }),
//       ),
//     );
//   }

//   Widget _buildLocalVideoView() {
//     return Obx(() => GestureDetector(
//       onTap: () {
//         setState(() {
//           _isPipMode = !_isPipMode;
//         });
//       },
//       onDoubleTap: () {
//         setState(() {
//           _isFullscreen = !_isFullscreen;
//         });
//       },
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 300),
//         width: _isPipMode ? 100 : 140,
//         height: _isPipMode ? 140 : 180,
//         child: callService.isVideoEnabled.value && callService.localRenderer != null
//             ? Container(
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(
//                     color: Colors.white.withAlpha(50),
//                     width: 2,
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withAlpha(50),
//                       blurRadius: 15,
//                       spreadRadius: 2,
//                     ),
//                   ],
//                 ),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(14),
//                   child: Stack(
//                     children: [
//                       webrtc.RTCVideoView(
//                         callService.localRenderer!,
//                         mirror: true,
//                         objectFit: webrtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
//                       ),
                      
//                       // Video controls overlay
//                       Positioned(
//                         bottom: 8,
//                         right: 8,
//                         child: Container(
//                           padding: const EdgeInsets.all(4),
//                           decoration: BoxDecoration(
//                             color: Colors.black.withAlpha(50),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               GestureDetector(
//                                 onTap: callService.switchCamera,
//                                 child: const Icon(
//                                   Icons.flip_camera_ios,
//                                   color: Colors.white,
//                                   size: 16,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               )
//             : Container(
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade800,
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(
//                     color: Colors.white.withAlpha(30),
//                     width: 2,
//                   ),
//                 ),
//                 child: const Center(
//                   child: Icon(
//                     Icons.videocam_off,
//                     color: Colors.white,
//                     size: 30,
//                   ),
//                 ),
//               ),
//       ),
//     ));
//   } 

//   Widget _buildVideoStats() {
//     return Container(
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         color: Colors.black.withAlpha(50),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Video Quality: HD',
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 12,
//             ),
//           ),
//           Text(
//             'Connection: ${callService.callStatus.value}',
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildVoiceCallInterface() {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [
//             Colors.green.shade900,
//             Colors.black,
//           ],
//         ),
//       ),
//       child: Center(
//         child: Obx(() {
//           final callData = callService.currentCallData;
//           final receiverName = callData['receiverName']?.toString() ?? 
//                               callData['callerName']?.toString() ?? 'Unknown';
          
//           return Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               // Large animated avatar
//               AnimatedBuilder(
//                 animation: _pulseAnimation,
//                 builder: (context, child) {
//                   return Transform.scale(
//                     scale: _pulseAnimation.value,
//                     child: Container(
//                       width: 220,
//                       height: 220,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: Colors.green,
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.green.withAlpha(40),
//                             blurRadius: 30,
//                             spreadRadius: 10,
//                           ),
//                         ],
//                       ),
//                       child: Center(
//                         child: Text(
//                           receiverName.isEmpty
//                               ? receiverName.substring(0, 1).toUpperCase()
//                               : 'U',
//                           style: const TextStyle(
//                             fontSize: 90,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
              
//               const SizedBox(height: 40),
              
//               // Name
//               Text(
//                 receiverName,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 32,
//                   fontWeight: FontWeight.bold,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
              
//               const SizedBox(height: 16),
              
//               // Call status
//               Text(
//                 callService.callStatus.value,
//                 style: const TextStyle(
//                   color: Colors.white70,
//                   fontSize: 18,
//                 ),
//               ),
              
//               const SizedBox(height: 20),
              
//               // Call duration
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withAlpha(10),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Text(
//                   _formatCallDuration(_callDurationSeconds),
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ],
//           );
//         }),
//       ),
//     );
//   }

//   Widget _buildCallInfoOverlay() {
//     return Positioned(
//       top: 0,
//       left: 0,
//       right: 0,
//       child: Container(
//         padding: EdgeInsets.only(
//           top: MediaQuery.of(context).padding.top + 10,
//           left: 20,
//           right: 20,
//           bottom: 20,
//         ),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Colors.black.withAlpha(70),
//               Colors.transparent,
//             ],
//           ),
//         ),
//         child: Obx(() {
//           final callData = callService.currentCallData;
//           final isVideoCall = callData['isVideoCall'] == true;
//           final receiverName = callData['receiverName']?.toString() ?? 
//                               callData['callerName']?.toString() ?? 'Unknown';
//           final status = callService.callStatus.value;
          
//           return Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               // Call info
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       receiverName,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Row(
//                       children: [
//                         Icon(
//                           isVideoCall ? Icons.videocam : Icons.phone,
//                           color: Colors.white70,
//                           size: 16,
//                         ),
//                         const SizedBox(width: 6),
//                         Text(
//                           status,
//                           style: const TextStyle(
//                             color: Colors.white70,
//                             fontSize: 14,
//                           ),
//                         ),
//                         if (status == 'Connected') ...[
//                           const SizedBox(width: 10),
//                           Text(
//                             _formatCallDuration(_callDurationSeconds),
//                             style: const TextStyle(
//                               color: Colors.white70,
//                               fontSize: 14,
//                             ),
//                           ),
//                         ],
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
              
//               // Action buttons
//               Row(
//                 children: [
//                   // Minimize button
//                   IconButton(
//                     onPressed: () {
//                       Get.back();
//                     },
//                     icon: const Icon(
//                       Icons.minimize,
//                       color: Colors.white,
//                       size: 24,
//                     ),
//                   ),
                  
//                   // PiP mode toggle (for video calls)
//                   if (callData['isVideoCall'] == true)
//                     IconButton(
//                       onPressed: () {
//                         setState(() {
//                           _isPipMode = !_isPipMode;
//                         });
//                       },
//                       icon: Icon(
//                         _isPipMode ? Icons.picture_in_picture_alt : Icons.picture_in_picture,
//                         color: Colors.white,
//                         size: 24,
//                       ),
//                     ),
//                 ],
//               ),
//             ],
//           );
//         }),
//       ),
//     );
//   }

//   Widget _buildControlsOverlay() {
//     return Positioned(
//       bottom: 0,
//       left: 0,
//       right: 0,
//       child: Container(
//         padding: EdgeInsets.only(
//           left: 30,
//           right: 30,
//           bottom: MediaQuery.of(context).padding.bottom + 40,
//           top: 40,
//         ),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.bottomCenter,
//             end: Alignment.topCenter,
//             colors: [
//               Colors.black.withAlpha(80),
//               Colors.transparent,
//             ],
//           ),
//         ),
//         child: _buildCallActions(),
//       ),
//     );
//   }

//   Widget _buildCallActions() {
//     return Obx(() {
//       final isVideoCall = callService.currentCallData['isVideoCall'] == true;
      
//       if (isVideoCall) {
//         return Column(
//           children: [
//             // Main controls row
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 // Mute button
//                 _buildToggleButton(
//                   onPressed: callService.toggleAudio,
//                   icon: callService.isAudioEnabled.value ? Icons.mic : Icons.mic_off,
//                   isActive: callService.isAudioEnabled.value,
//                   color: Colors.blue,
//                 ),
                
//                 // Video toggle
//                 _buildToggleButton(
//                   onPressed: callService.toggleVideo,
//                   icon: callService.isVideoEnabled.value ? Icons.videocam : Icons.videocam_off,
//                   isActive: callService.isVideoEnabled.value,
//                   color: Colors.green,
//                 ),
                
//                 // Speaker button
//                 _buildToggleButton(
//                   onPressed: callService.toggleSpeaker,
//                   icon: callService.isSpeakerOn.value ? Icons.volume_up : Icons.volume_down,
//                   isActive: callService.isSpeakerOn.value,
//                   color: Colors.orange,
//                 ),
                
//                 // End call button
//                 _buildMainActionButton(
//                   onPressed: () async {
//                     HapticFeedback.heavyImpact();
//                     await callService.endCall();
//                     Get.back();
//                   },
//                   icon: Icons.call_end,
//                   color: Colors.red,
//                   size: 60,
//                 ),
//               ],
//             ),
            
//             const SizedBox(height: 20),
            
//             // Secondary controls row
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 // Camera switch
//                 _buildSecondaryButton(
//                   onPressed: callService.switchCamera,
//                   icon: Icons.flip_camera_ios,
//                   label: 'Flip',
//                 ),
                
//                 // Add participant (placeholder)
//                 _buildSecondaryButton(
//                   onPressed: () {
//                     // TODO: Implement add participant
//                   },
//                   icon: Icons.person_add,
//                   label: 'Add',
//                 ),
                
//                 // Chat (placeholder)
//                 _buildSecondaryButton(
//                   onPressed: () {
//                     // TODO: Implement chat
//                   },
//                   icon: Icons.chat,
//                   label: 'Chat',
//                 ),
                
//                 // More options
//                 _buildSecondaryButton(
//                   onPressed: () {
//                     _showMoreOptions();
//                   },
//                   icon: Icons.more_horiz,
//                   label: 'More',
//                 ),
//               ],
//             ),
//           ],
//         );
//       } else {
//         // Voice call controls
//         return Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: [
//             // Mute button
//             _buildToggleButton(
//               onPressed: callService.toggleAudio,
//               icon: callService.isAudioEnabled.value ? Icons.mic : Icons.mic_off,
//               isActive: callService.isAudioEnabled.value,
//               color: Colors.blue,
//             ),
            
//             // Speaker button
//             _buildToggleButton(
//               onPressed: callService.toggleSpeaker,
//               icon: callService.isSpeakerOn.value ? Icons.volume_up : Icons.volume_down,
//               isActive: callService.isSpeakerOn.value,
//               color: Colors.green,
//             ),
            
//             // Hold button (placeholder)
//             _buildToggleButton(
//               onPressed: () {
//                 // TODO: Implement hold
//               },
//               icon: Icons.pause,
//               isActive: false,
//               color: Colors.orange,
//             ),
            
//             // End call button
//             _buildMainActionButton(
//               onPressed: () async {
//                 HapticFeedback.heavyImpact();
//                 await callService.endCall();
//                 Get.back();
//               },
//               icon: Icons.call_end,
//               color: Colors.red,
//               size: 70,
//             ),
//           ],
//         );
//       }
//     });
//   }

//   Widget _buildToggleButton({
//     required VoidCallback onPressed,
//     required IconData icon,
//     required bool isActive,
//     required Color color,
//   }) {
//     return GestureDetector(
//       onTap: () {
//         HapticFeedback.lightImpact();
//         onPressed();
//       },
//       child: Container(
//         width: 56,
//         height: 56,
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           color: isActive ? color.withAlpha(30) : Colors.grey.withAlpha(30),
//           border: Border.all(
//             color: isActive ? color : Colors.grey,
//             width: 2,
//           ),
//         ),
//         child: Icon(
//           icon,
//           color: Colors.white,
//           size: 28,
//         ),
//       ),
//     );
//   }

//   Widget _buildMainActionButton({
//     required VoidCallback onPressed,
//     required IconData icon,
//     required Color color,
//     required double size,
//   }) {
//     return GestureDetector(
//       onTap: onPressed,
//       child: Container(
//         width: size,
//         height: size,
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           color: color,
//           boxShadow: [
//             BoxShadow(
//               color: color.withAlpha(40),
//               blurRadius: 20,
//               spreadRadius: 3,
//             ),
//           ],
//         ),
//         child: Icon(
//           icon,
//           color: Colors.white,
//           size: size * 0.45,
//         ),
//       ),
//     );
//   }

//   Widget _buildSecondaryButton({
//     required VoidCallback onPressed,
//     required IconData icon,
//     required String label,
//   }) {
//     return GestureDetector(
//       onTap: () {
//         HapticFeedback.lightImpact();
//         onPressed();
//       },
//       child: Column(
//         children: [
//           Container(
//             width: 48,
//             height: 48,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: Colors.white.withAlpha(10),
//               border: Border.all(
//                 color: Colors.white.withAlpha(30),
//                 width: 1,
//               ),
//             ),
//             child: Icon(
//               icon,
//               color: Colors.white,
//               size: 24,
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             label,
//             style: const TextStyle(
//               color: Colors.white70,
//               fontSize: 12,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showMoreOptions() {
//     Get.bottomSheet(
//       Container(
//         padding: const EdgeInsets.all(20),
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: const Icon(Icons.record_voice_over),
//               title: const Text('Record Call'),
//               onTap: () {
//                 Get.back();
//                 // TODO: Implement call recording
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.swap_calls),
//               title: const Text('Switch to Video'),
//               onTap: () {
//                 Get.back();
//                 // TODO: Implement call type switching
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.share),
//               title: const Text('Share Screen'),
//               onTap: () {
//                 Get.back();
//                 // TODO: Implement screen sharing
//               },
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }
// }