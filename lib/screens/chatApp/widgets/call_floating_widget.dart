import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:innovator/screens/Call/Incoming_Call_screen.dart';
import 'package:innovator/services/webrtc_call_service.dart';

class CallFloatingWidget extends StatelessWidget {
  const CallFloatingWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final callService = WebRTCCallService.instance;
      
      if (!callService.isCallActive.value) {
        return const SizedBox.shrink();
      }
      
      return Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        right: 10,
        child: GestureDetector(
          onTap: () {
            Get.to(() => ActiveCallScreen());
          },
          child: Container(
            width: 200,
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                // Call indicator
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Call info
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ongoing Call',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Obx(() => Text(
                        callService.callStatus.value,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      )),
                    ],
                  ),
                ),
                
                // Return to call button
                Icon(
                  callService.currentCallData['isVideoCall'] == true 
                      ? Icons.videocam 
                      : Icons.phone,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}