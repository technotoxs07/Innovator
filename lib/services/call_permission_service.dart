import 'dart:developer' as developer;
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class CallPermissionService {
  static Future<bool> requestPermissions({required bool isVideoCall}) async {
    try {
      developer.log('📱 Requesting call permissions...');
      
      // Required permissions for voice calls
      List<Permission> permissions = [
        Permission.microphone,
        Permission.phone,
      ];
      
      // Add camera permission for video calls
      if (isVideoCall) {
        permissions.add(Permission.camera);
      }
      
      // Request permissions one by one for better UX
      bool allGranted = true;
      
      for (Permission permission in permissions) {
        final status = await permission.status;
        
        if (status.isDenied || status.isRestricted) {
          developer.log('📱 Requesting ${permission.toString()}...');
          
          final result = await permission.request();
          
          if (result != PermissionStatus.granted) {
            allGranted = false;
            developer.log('❌ Permission ${permission.toString()} denied');
            
            // Show specific error for each permission
            _showPermissionError(permission, isVideoCall);
          } else {
            developer.log('✅ Permission ${permission.toString()} granted');
          }
        } else if (status.isPermanentlyDenied) {
          allGranted = false;
          developer.log('❌ Permission ${permission.toString()} permanently denied');
          _showPermanentlyDeniedDialog(permission);
        }
      }
      
      if (allGranted) {
        developer.log('✅ All call permissions granted');
        
        // Show success message
        // Get.snackbar(
        //   'Permissions Granted',
        //   'All required permissions have been granted',
        //   snackPosition: SnackPosition.TOP,
        //   backgroundColor: Colors.green,
        //   colorText: Colors.white,
        //   duration: const Duration(seconds: 2),
        //   icon: const Icon(Icons.check_circle, color: Colors.white),
        // );
      } else {
        developer.log('❌ Some call permissions were denied');
      }
      
      return allGranted;
      
    } catch (e) {
      developer.log('❌ Error requesting call permissions: $e');
      
      Get.snackbar(
        'Permission Error',
        'Failed to request permissions: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      
      return false;
    }
  }
  
  static Future<bool> checkPermissions({required bool isVideoCall}) async {
    try {
      List<Permission> permissions = [
        Permission.microphone,
        Permission.phone,
      ];
      
      if (isVideoCall) {
        permissions.add(Permission.camera);
      }
      
      for (var permission in permissions) {
        final status = await permission.status;
        if (status != PermissionStatus.granted) {
          developer.log('❌ Permission ${permission.toString()} not granted: $status');
          return false;
        }
      }
      
      return true;
      
    } catch (e) {
      developer.log('❌ Error checking call permissions: $e');
      return false;
    }
  }
  
  static void _showPermissionError(Permission permission, bool isVideoCall) {
    String title = '';
    String message = '';
    IconData icon = Icons.error;
    
    switch (permission) {
      case Permission.microphone:
        title = 'Microphone Permission Required';
        message = 'To make ${isVideoCall ? 'video' : 'voice'} calls, we need access to your microphone.';
        icon = Icons.mic;
        break;
      case Permission.camera:
        title = 'Camera Permission Required';
        message = 'To make video calls, we need access to your camera.';
        icon = Icons.videocam;
        break;
      case Permission.phone:
        title = 'Phone Permission Required';
        message = 'To manage calls properly, we need phone access permission.';
        icon = Icons.phone;
        break;
      default:
        title = 'Permission Required';
        message = 'This permission is required for calls to work properly.';
        break;
    }
    
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      icon: Icon(icon, color: Colors.white),
      mainButton: TextButton(
        onPressed: () {
          Get.back();
          openAppSettings();
        },
        child: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
  
  static void _showPermanentlyDeniedDialog(Permission permission) {
    String permissionName = '';
    
    switch (permission) {
      case Permission.microphone:
        permissionName = 'Microphone';
        break;
      case Permission.camera:
        permissionName = 'Camera';
        break;
      case Permission.phone:
        permissionName = 'Phone';
        break;
      default:
        permissionName = 'Required';
        break;
    }
    
    Get.dialog(
      AlertDialog(
        title: Text('$permissionName Permission Denied'),
        content: Text(
          'You have permanently denied $permissionName permission. '
          'To enable calls, please go to Settings and grant the permission.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
  
  static Future<void> showPermissionEducation({required bool isVideoCall}) async {
    await Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(
              isVideoCall ? Icons.videocam : Icons.phone,
              color: isVideoCall ? Colors.blue : Colors.green,
            ),
            const SizedBox(width: 8),
            Text('${isVideoCall ? 'Video' : 'Voice'} Call Permissions'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To make ${isVideoCall ? 'video' : 'voice'} calls, we need the following permissions:',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            
            // Microphone permission
            Row(
              children: [
                const Icon(Icons.mic, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Microphone - To transmit your voice'),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Camera permission (for video calls)
            if (isVideoCall) ...[
              Row(
                children: [
                  const Icon(Icons.videocam, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Camera - To transmit your video'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            
            // Phone permission
            Row(
              children: [
                const Icon(Icons.phone_android, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Phone - To manage call states'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'These permissions are only used during calls and help ensure the best calling experience.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isVideoCall ? Colors.blue : Colors.green,
            ),
            child: const Text('Grant Permissions'),
          ),
        ],
      ),
    );
  }
}