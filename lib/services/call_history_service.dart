import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

class CallHistoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static Future<void> saveCallHistory({
    required String callId,
    required String callerId,
    required String receiverId,
    required String callerName,
    required String receiverName,
    required bool isVideoCall,
    required String status, // 'answered', 'missed', 'rejected', 'failed'
    required DateTime startTime,
    DateTime? endTime,
    int? duration,
  }) async {
    try {
      // FIXED: Add participants array for proper querying
      await _firestore.collection('call_history').doc(callId).set({
        'callId': callId,
        'callerId': callerId,
        'receiverId': receiverId,
        'callerName': callerName,
        'receiverName': receiverName,
        'participants': [callerId, receiverId], // ADDED for proper queries
        'isVideoCall': isVideoCall,
        'status': status,
        'startTime': startTime,
        'endTime': endTime,
        'duration': duration, // in seconds
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      developer.log('✅ Call history saved: $callId');
    } catch (e) {
      developer.log('❌ Error saving call history: $e');
    }
  }
  
  // FIXED: Updated query structure
  static Stream<QuerySnapshot> getUserCallHistory(String userId) {
    return _firestore
        .collection('call_history')
        .where('participants', arrayContains: userId)
        .orderBy('startTime', descending: true)
        .limit(50)
        .snapshots();
  }
}