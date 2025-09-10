// Create: lib/screens/Follow/Follow_status_Manager.dart

import 'dart:convert';
import 'dart:developer' as developer;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';

class FollowStatusManager extends GetxService {
  // Singleton instance - FIXED
  static FollowStatusManager get instance => Get.find<FollowStatusManager>();
  
  // Cache for follow status with expiry
  final Map<String, Map<String, dynamic>> _followStatusCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _cacheExpiry = const Duration(minutes: 5); // Cache for 5 minutes
  
  // Loading states
  final RxMap<String, bool> loadingStates = <String, bool>{}.obs;
  final RxBool isInitializing = false.obs;
  
  // Batch processing
  final Set<String> _pendingRequests = {};
  
  @override
  void onInit() {
    super.onInit();
    developer.log('🔄 FollowStatusManager initialized');
  }

  // Check if cached data is still valid
  bool _isCacheValid(String email) {
    final timestamp = _cacheTimestamps[email];
    if (timestamp == null) return false;
    
    final now = DateTime.now();
    final isValid = now.difference(timestamp) < _cacheExpiry;
    
    if (!isValid) {
      // Remove expired cache
      _followStatusCache.remove(email);
      _cacheTimestamps.remove(email);
    }
    
    return isValid;
  }

  // Get cached follow status
  Map<String, dynamic>? getCachedFollowStatus(String email) {
    if (_isCacheValid(email)) {
      return _followStatusCache[email];
    }
    return null;
  }

  // Set follow status cache
  void _setCacheData(String email, Map<String, dynamic> data) {
    _followStatusCache[email] = data;
    _cacheTimestamps[email] = DateTime.now();
  }

  // Check follow status with caching and batching
  Future<Map<String, dynamic>?> checkFollowStatus(String email) async {
    if (email.isEmpty) return null;
    
    // Check cache first
    final cachedData = getCachedFollowStatus(email);
    if (cachedData != null) {
      developer.log('✅ Using cached follow status for: $email');
      return cachedData;
    }
    
    // Prevent duplicate requests
    if (_pendingRequests.contains(email)) {
      developer.log('⏳ Request already pending for: $email');
      // Wait for pending request
      while (_pendingRequests.contains(email)) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return getCachedFollowStatus(email);
    }
    
    _pendingRequests.add(email);
    loadingStates[email] = true;
    
    try {
      developer.log('🔍 Fetching follow status for: $email');
      
      final url = Uri.parse('http://182.93.94.210:3067/api/v1/check?email=$email');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppData().authToken}',
      };

      final response = await http.get(url, headers: headers)
          .timeout(const Duration(seconds: 8)); // Reduced timeout

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['status'] == 200 && responseData['data'] != null) {
          final userData = responseData['data']['user'];
          final isFollowing = responseData['data']['isFollowing'] as bool;
          final isFollowedBy = responseData['data']['isFollowedBy'] as bool;
          
          final followData = {
            'user': userData,
            'isFollowing': isFollowing,
            'isFollowedBy': isFollowedBy,
            'isMutualFollow': isFollowing && isFollowedBy,
            'lastChecked': DateTime.now().toIso8601String(),
          };
          
          // Cache the result
          _setCacheData(email, followData);
          
          developer.log('✅ Follow status cached for: $email (Mutual: ${followData['isMutualFollow']})');
          return followData;
        }
      }
      
      developer.log('❌ Invalid response for: $email');
      return null;
      
    } catch (e) {
      developer.log('❌ Error checking follow status for $email: $e');
      return null;
    } finally {
      _pendingRequests.remove(email);
      loadingStates[email] = false;
    }
  }

  // ADDED: Batch check multiple emails efficiently
  Future<Map<String, Map<String, dynamic>>> batchCheckFollowStatus(List<String> emails) async {
    developer.log('📦 Batch checking ${emails.length} follow statuses');
    
    final results = <String, Map<String, dynamic>>{};
    final uncachedEmails = <String>[];
    
    // First, get all cached results
    for (final email in emails) {
      final cached = getCachedFollowStatus(email);
      if (cached != null) {
        results[email] = cached;
      } else {
        uncachedEmails.add(email);
      }
    }
    
    developer.log('📦 Found ${results.length} cached, ${uncachedEmails.length} need fetching');
    
    if (uncachedEmails.isNotEmpty) {
      // Process uncached emails in batches of 5 to avoid overwhelming the server
      const batchSize = 5;
      for (int i = 0; i < uncachedEmails.length; i += batchSize) {
        final batch = uncachedEmails.skip(i).take(batchSize).toList();
        
        // Process batch concurrently
        final futures = batch.map((email) => checkFollowStatus(email)).toList();
        final batchResults = await Future.wait(futures);
        
        for (int j = 0; j < batch.length; j++) {
          final email = batch[j];
          final result = batchResults[j];
          if (result != null) {
            results[email] = result;
          }
        }
        
        // Small delay between batches to be server-friendly
        if (i + batchSize < uncachedEmails.length) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
    }
    
    developer.log('📦 Batch complete: ${results.length} total results');
    return results;
  }

  // ADDED: Pre-load follow statuses for better UX
  Future<void> preloadFollowStatuses(List<String> emails) async {
    developer.log('🚀 Preloading follow statuses for ${emails.length} users');
    
    isInitializing.value = true;
    
    try {
      await batchCheckFollowStatus(emails);
      developer.log('✅ Preloading complete');
    } catch (e) {
      developer.log('❌ Error preloading follow statuses: $e');
    } finally {
      isInitializing.value = false;
    }
  }

  // ADDED: Filter users by mutual follow status (cached version)
  List<Map<String, dynamic>> filterMutualFollowers(List<Map<String, dynamic>> users) {
    final mutualFollowers = <Map<String, dynamic>>[];
    
    for (final user in users) {
      final email = user['email']?.toString();
      if (email != null) {
        final followStatus = getCachedFollowStatus(email);
        if (followStatus != null && followStatus['isMutualFollow'] == true) {
          // Enhance user data with API info
          final apiUserData = followStatus['user'] as Map<String, dynamic>;
          final enhancedUser = {
            ...user,
            'name': apiUserData['name'],
            'picture': apiUserData['picture'],
            'apiPictureUrl': 'http://182.93.94.210:3067${apiUserData['picture']}',
            'isFollowing': followStatus['isFollowing'],
            'isFollowedBy': followStatus['isFollowedBy'],
            'isMutualFollow': true,
          };
          
          mutualFollowers.add(enhancedUser);
        }
      }
    }
    
    return mutualFollowers;
  }

  // Get mutual followers count (cached)
  int getMutualFollowersCount(List<Map<String, dynamic>> users) {
    return filterMutualFollowers(users).length;
  }

  // ADDED: Check if specific user is mutual follower (cached)
  bool isMutualFollower(Map<String, dynamic> user) {
    final email = user['email']?.toString();
    if (email == null) return false;
    
    final followStatus = getCachedFollowStatus(email);
    return followStatus?['isMutualFollow'] == true;
  }

  // Clear cache (useful for refresh scenarios)
  void clearCache() {
    developer.log('🧹 Clearing follow status cache');
    _followStatusCache.clear();
    _cacheTimestamps.clear();
    loadingStates.clear();
  }

  // Clear expired cache entries
  void cleanupExpiredCache() {
    final now = DateTime.now();
    final expiredEmails = <String>[];
    
    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) >= _cacheExpiry) {
        expiredEmails.add(entry.key);
      }
    }
    
    for (final email in expiredEmails) {
      _followStatusCache.remove(email);
      _cacheTimestamps.remove(email);
    }
    
    if (expiredEmails.isNotEmpty) {
      developer.log('🧹 Cleaned ${expiredEmails.length} expired cache entries');
    }
  }

  // Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'totalCached': _followStatusCache.length,
      'oldestCacheAge': _cacheTimestamps.isEmpty 
          ? 0 
          : DateTime.now().difference(_cacheTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b)).inMinutes,
      'pendingRequests': _pendingRequests.length,
      'loadingStates': loadingStates.length,
    };
  }
}