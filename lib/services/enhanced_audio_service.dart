import 'dart:developer' as developer;
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:get/get.dart';

class EnhancedAudioService {
  static bool _isSpeakerOn = false;
  static bool _isBluetoothConnected = false;
  static bool _isHeadphonesConnected = false;
  
  // Audio route management
  static Future<void> setSpeakerMode(bool enabled) async {
    try {
      _isSpeakerOn = enabled;
      await webrtc.Helper.setSpeakerphoneOn(enabled);
      developer.log('🔊 Speaker mode: ${enabled ? 'ON' : 'OFF'}');
    } catch (e) {
      developer.log('❌ Error setting speaker mode: $e');
    }
  }
  
  static Future<void> setEarpieceMode() async {
    try {
      _isSpeakerOn = false;
      await webrtc.Helper.setSpeakerphoneOn(false);
      developer.log('📱 Earpiece mode enabled');
    } catch (e) {
      developer.log('❌ Error setting earpiece mode: $e');
    }
  }
  
  static Future<void> optimizeAudioForCall({required bool isVideoCall}) async {
    try {
      developer.log('🎵 Optimizing audio for ${isVideoCall ? 'video' : 'voice'} call...');
      
      // For video calls, default to speaker
      if (isVideoCall) {
        await setSpeakerMode(true);
      } else {
        // For voice calls, default to earpiece unless headphones are connected
        if (_isHeadphonesConnected || _isBluetoothConnected) {
          // Keep current audio route
          developer.log('🎧 External audio device detected, maintaining current route');
        } else {
          await setEarpieceMode();
        }
      }
      
      developer.log('✅ Audio optimization completed');
    } catch (e) {
      developer.log('❌ Error optimizing audio: $e');
    }
  }
  
  static Future<void> handleAudioRouteChange() async {
    try {
      // Detect audio route changes
      // This would typically integrate with platform-specific audio route detection
      developer.log('🔄 Audio route changed');
      
      // Auto-adjust based on connected devices
      if (_isBluetoothConnected) {
        developer.log('🔵 Bluetooth audio detected');
      } else if (_isHeadphonesConnected) {
        developer.log('🎧 Headphones detected');
      } else if (_isSpeakerOn) {
        developer.log('🔊 Speaker mode active');
      } else {
        developer.log('📱 Earpiece mode active');
      }
    } catch (e) {
      developer.log('❌ Error handling audio route change: $e');
    }
  }
  
  static bool get isSpeakerOn => _isSpeakerOn;
  static bool get isBluetoothConnected => _isBluetoothConnected;
  static bool get isHeadphonesConnected => _isHeadphonesConnected;
  
  // Mock methods for device detection (integrate with platform channels in real app)
  static void setBluetoothConnected(bool connected) {
    _isBluetoothConnected = connected;
    developer.log('🔵 Bluetooth ${connected ? 'connected' : 'disconnected'}');
  }
  
  static void setHeadphonesConnected(bool connected) {
    _isHeadphonesConnected = connected;
    developer.log('🎧 Headphones ${connected ? 'connected' : 'disconnected'}');
  }
}