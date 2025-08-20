import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:innovator/screens/Call/Active_Call_Screen.dart';
import 'package:innovator/services/webrtc_call_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;

class CallFloatingWidget extends StatelessWidget {
  const CallFloatingWidget({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final callService = WebRTCCallService.instance;
      
      if (!callService.isCallActive.value) {
        return const SizedBox.shrink();
      }
      
      final callData = callService.currentCallData;
      final isVideoCall = callData['isVideoCall'] == true;
      final receiverName = callData['receiverName']?.toString() ?? 
                          callData['callerName']?.toString() ?? 'Unknown';
      
      return Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        right: 16,
        child: GestureDetector(
          onTap: () {
            Get.to(() => ActiveCallScreen());
          },
          child: Container(
            width: isVideoCall ? 120 : 220,
            height: isVideoCall ? 160 : 70,
            decoration: BoxDecoration(
              color: isVideoCall ? Colors.transparent : Colors.green,
              borderRadius: BorderRadius.circular(isVideoCall ? 16 : 35),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: isVideoCall ? _buildVideoFloatingWidget() : _buildVoiceFloatingWidget(receiverName),
          ),
        ),
      );
    });
  }
  
  Widget _buildVideoFloatingWidget() {
    final callService = WebRTCCallService.instance;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // Local video
          if (callService.localRenderer != null && callService.isVideoEnabled.value)
            webrtc.RTCVideoView(
              callService.localRenderer!,
              mirror: true,
              objectFit: webrtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            )
          else
            Container(
              color: Colors.grey.shade800,
              child: const Center(
                child: Icon(
                  Icons.videocam_off,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          
          // Status overlay
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.videocam,
                    color: Colors.white,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Obx(() => Text(
                      callService.callStatus.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    )),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVoiceFloatingWidget(String receiverName) {
    final callService = WebRTCCallService.instance;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Pulsing call indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Call info
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receiverName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Obx(() => Text(
                  callService.callStatus.value,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                )),
              ],
            ),
          ),
          
          // Call type icon
          Icon(
            Icons.phone,
            color: Colors.white,
            size: 20,
          ),
        ],
      ),
    );
  }
}