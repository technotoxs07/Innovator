import 'dart:developer' as developer;

import 'package:permission_handler/permission_handler.dart';

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
      
      // Request permissions
      Map<Permission, PermissionStatus> statuses = await permissions.request();
      
      // Check if all permissions are granted
      bool allGranted = true;
      for (var permission in permissions) {
        final status = statuses[permission];
        if (status != PermissionStatus.granted) {
          allGranted = false;
          developer.log('❌ Permission ${permission.toString()} denied');
        }
      }
      
      if (allGranted) {
        developer.log('✅ All call permissions granted');
      } else {
        developer.log('❌ Some call permissions were denied');
      }
      
      return allGranted;
      
    } catch (e) {
      developer.log('❌ Error requesting call permissions: $e');
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
          return false;
        }
      }
      
      return true;
      
    } catch (e) {
      developer.log('❌ Error checking call permissions: $e');
      return false;
    }
  }
}