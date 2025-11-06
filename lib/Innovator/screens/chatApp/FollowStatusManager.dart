// Updated: lib/screens/Follow/Follow_status_Manager.dart

import 'dart:convert';
import 'dart:developer' as developer;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/App_data/App_data.dart';

class FollowStatusManager extends GetxService {
  // Singleton instance
  static FollowStatusManager get instance => Get.find<FollowStatusManager>();
  
  // Cache for follow status with expiry
  final Map<String, Map<String, dynamic>> _followStatusCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _cacheExpiry = const Duration(minutes: 5);
  
  // NEW: Cache for mutual followings
  List<Map<String, dynamic>>? _mutualFollowingsCache;
  DateTime? _mutualFollowingsCacheTime;
  final Duration _mutualFollowingsCacheExpiry = const Duration(minutes: 10); // Longer cache for mutual followings
  
  // Loading states
  final RxMap<String, bool> loadingStates = <String, bool>{}.obs;
  final RxBool isInitializing = false.obs;
  final RxBool isFetchingMutualFollowings = false.obs;
  
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
      _followStatusCache.remove(email);
      _cacheTimestamps.remove(email);
    }
    
    return isValid;
  }

  // NEW: Check if mutual followings cache is valid
  bool _isMutualFollowingsCacheValid() {
    if (_mutualFollowingsCacheTime == null || _mutualFollowingsCache == null) return false;
    
    final now = DateTime.now();
    final isValid = now.difference(_mutualFollowingsCacheTime!) < _mutualFollowingsCacheExpiry;
    
    if (!isValid) {
      _mutualFollowingsCache = null;
      _mutualFollowingsCacheTime = null;
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

  // NEW: Fetch mutual followings from the new API
  Future<List<Map<String, dynamic>>> fetchMutualFollowings({bool forceRefresh = false}) async {
    // Return cached data if valid and not forcing refresh
    if (!forceRefresh && _isMutualFollowingsCacheValid()) {
      developer.log('✅ Using cached mutual followings data');
      return _mutualFollowingsCache!;
    }

    if (isFetchingMutualFollowings.value) {
      developer.log('⏳ Mutual followings request already in progress');
      // Wait for the ongoing request
      while (isFetchingMutualFollowings.value) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _mutualFollowingsCache ?? [];
    }

    isFetchingMutualFollowings.value = true;

    try {
      developer.log('🚀 Fetching mutual followings from API');
      
      final url = Uri.parse('http://182.93.94.210:3067/api/v1/mutual-followings');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppData().authToken}',
      };

      final response = await http.get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['status'] == 200 && responseData['data'] != null) {
          final List<dynamic> mutualFollowingsRaw = responseData['data'];
          
          // Process the data and enhance it
          final List<Map<String, dynamic>> mutualFollowings = mutualFollowingsRaw.map((user) {
            final Map<String, dynamic> userData = Map<String, dynamic>.from(user);
            
            // Add enhanced picture URL for local uploads
            if (userData['picture'] != null && userData['picture'].startsWith('/uploads/')) {
              userData['apiPictureUrl'] = 'http://182.93.94.210:3067${userData['picture']}';
            } else {
              userData['apiPictureUrl'] = userData['picture'];
            }
            
            // Mark as mutual follower
            userData['isMutualFollow'] = true;
            userData['isFollowing'] = true;
            userData['isFollowedBy'] = true;
            userData['lastChecked'] = DateTime.now().toIso8601String();
            
            return userData;
          }).toList();
          
          // Cache the results
          _mutualFollowingsCache = mutualFollowings;
          _mutualFollowingsCacheTime = DateTime.now();
          
          // Also update individual follow status cache for these users
          for (final user in mutualFollowings) {
            final email = user['email']?.toString();
            if (email != null) {
              _setCacheData(email, {
                'user': user,
                'isFollowing': true,
                'isFollowedBy': true,
                'isMutualFollow': true,
                'lastChecked': DateTime.now().toIso8601String(),
              });
            }
          }
          
          developer.log('✅ Cached ${mutualFollowings.length} mutual followings');
          return mutualFollowings;
        }
      }
      
      developer.log('❌ Failed to fetch mutual followings: ${response.statusCode}');
      return [];
      
    } catch (e) {
      developer.log('❌ Error fetching mutual followings: $e');
      return [];
    } finally {
      isFetchingMutualFollowings.value = false;
    }
  }

  // UPDATED: Get mutual followers using the new API (much faster)
  Future<List<Map<String, dynamic>>> getMutualFollowers({bool forceRefresh = false}) async {
    return await fetchMutualFollowings(forceRefresh: forceRefresh);
  }

  // UPDATED: Get mutual followers count using cached API data
  Future<int> getMutualFollowersCount({bool forceRefresh = false}) async {
    final mutualFollowings = await fetchMutualFollowings(forceRefresh: forceRefresh);
    return mutualFollowings.length;
  }

  // NEW: Check if user is in mutual followings list (super fast)
  Future<bool> isMutualFollowerFast(String email, {bool forceRefresh = false}) async {
    if (email.isEmpty) return false;
    
    final mutualFollowings = await fetchMutualFollowings(forceRefresh: forceRefresh);
    return mutualFollowings.any((user) => user['email']?.toString() == email);
  }

  // SYNC: Check if specific user is mutual follower (cache only - for UI)
  bool isMutualFollower(Map<String, dynamic> user) {
    final email = user['email']?.toString();
    if (email == null) return false;
    
    // First check if user data already has follow status
    if (user['isMutualFollow'] == true) {
      return true;
    }
    
    // Check cached individual status
    final followStatus = getCachedFollowStatus(email);
    if (followStatus != null) {
      return followStatus['isMutualFollow'] == true;
    }
    
    // Check cached mutual followings list
    if (_mutualFollowingsCache != null) {
      return _mutualFollowingsCache!.any((mutualUser) => mutualUser['email'] == email);
    }
    
    return false;
  }

  // ASYNC: Check if specific user is mutual follower (with API fallback)
  Future<bool> isMutualFollowerAsync(Map<String, dynamic> user, {bool forceRefresh = false}) async {
    final email = user['email']?.toString();
    if (email == null) return false;
    
    // Try cached individual status first
    if (!forceRefresh) {
      final followStatus = getCachedFollowStatus(email);
      if (followStatus != null) {
        return followStatus['isMutualFollow'] == true;
      }
    }
    
    // Fallback to mutual followings API check
    return await isMutualFollowerFast(email, forceRefresh: forceRefresh);
  }

  // NEW: Filter any user list to show only mutual followers
  Future<List<Map<String, dynamic>>> filterToMutualFollowers(
    List<Map<String, dynamic>> users, 
    {bool forceRefresh = false}
  ) async {
    final mutualFollowings = await fetchMutualFollowings(forceRefresh: forceRefresh);
    final mutualEmails = mutualFollowings.map((user) => user['email']?.toString()).toSet();
    
    return users.where((user) {
      final email = user['email']?.toString();
      return email != null && mutualEmails.contains(email);
    }).map((user) {
      // Enhance with API data if available
      final email = user['email']?.toString();
      final apiUser = mutualFollowings.firstWhereOrNull((mu) => mu['email'] == email);
      
      if (apiUser != null) {
        return {
          ...user,
          'name': apiUser['name'] ?? user['name'],
          'picture': apiUser['picture'] ?? user['picture'],
          'apiPictureUrl': apiUser['apiPictureUrl'],
          'isFollowing': true,
          'isFollowedBy': true,
          'isMutualFollow': true,
        };
      }
      
      return user;
    }).toList();
  }

  // FAST: Check follow status using only mutual followings API (NO individual API calls)
  Future<Map<String, dynamic>?> checkFollowStatus(String email) async {
    if (email.isEmpty) return null;
    
    // Check cache first
    final cachedData = getCachedFollowStatus(email);
    if (cachedData != null) {
      developer.log('✅ Using cached follow status for: $email');
      return cachedData;
    }
    
    // Use ONLY the fast mutual followings API
    final mutualFollowings = await fetchMutualFollowings();
    final user = mutualFollowings.firstWhereOrNull((u) => u['email'] == email);
    
    if (user != null) {
      // User is a mutual follower
      final followData = {
        'user': user,
        'isFollowing': true,
        'isFollowedBy': true,
        'isMutualFollow': true,
        'lastChecked': DateTime.now().toIso8601String(),
      };
      _setCacheData(email, followData);
      developer.log('✅ Found mutual follower via fast API: $email');
      return followData;
    } else {
      // User is NOT a mutual follower - cache negative result
      final followData = {
        'user': null,
        'isFollowing': false,
        'isFollowedBy': false,
        'isMutualFollow': false,
        'lastChecked': DateTime.now().toIso8601String(),
      };
      _setCacheData(email, followData);
      developer.log('✅ User is not mutual follower: $email');
      return followData;
    }
  }

  // ULTRA-FAST: Batch check using ONLY mutual followings API (NO individual API calls)
  Future<Map<String, Map<String, dynamic>>> batchCheckFollowStatus(List<String> emails) async {
    developer.log('📦 Fast batch checking ${emails.length} follow statuses (mutual followings API only)');
    
    final results = <String, Map<String, dynamic>>{};
    
    // Get mutual followings data (single fast API call)
    final mutualFollowings = await fetchMutualFollowings();
    final mutualEmailsMap = <String, Map<String, dynamic>>{};
    
    // Create lookup map for mutual followers
    for (final user in mutualFollowings) {
      final email = user['email']?.toString();
      if (email != null) {
        mutualEmailsMap[email] = {
          'user': user,
          'isFollowing': true,
          'isFollowedBy': true,
          'isMutualFollow': true,
          'lastChecked': DateTime.now().toIso8601String(),
        };
      }
    }
    
    // Process all emails
    for (final email in emails) {
      // Check cache first
      final cached = getCachedFollowStatus(email);
      if (cached != null) {
        results[email] = cached;
      } 
      // Check if in mutual followings
      else if (mutualEmailsMap.containsKey(email)) {
        final mutualData = mutualEmailsMap[email]!;
        _setCacheData(email, mutualData); // Cache it
        results[email] = mutualData;
      } 
      // User is NOT a mutual follower - create negative result
      else {
        final nonMutualData = {
          'user': null,
          'isFollowing': false,
          'isFollowedBy': false,
          'isMutualFollow': false,
          'lastChecked': DateTime.now().toIso8601String(),
        };
        _setCacheData(email, nonMutualData); // Cache negative result too
        results[email] = nonMutualData;
      }
    }
    
    developer.log('📦 FAST batch complete: ${results.length} total results (${mutualEmailsMap.length} mutual followers found)');
    developer.log('🚀 NO slow individual API calls were made!');
    
    return results;
  }

  // FAST: Preload using ONLY mutual followings API (NO individual calls)
  Future<void> preloadFollowStatuses(List<String> emails) async {
    developer.log('🚀 Fast preloading follow statuses for ${emails.length} users (mutual followings API only)');
    
    isInitializing.value = true;
    
    try {
      // Single API call to get all mutual followings
      await fetchMutualFollowings();
      
      // Process all emails using only the mutual followings data (no additional API calls)
      await batchCheckFollowStatus(emails);
      
      developer.log('✅ Fast preloading complete - NO slow API calls made!');
    } catch (e) {
      developer.log('❌ Error preloading follow statuses: $e');
    } finally {
      isInitializing.value = false;
    }
  }

  // LEGACY: Keep original filter method for compatibility
  List<Map<String, dynamic>> filterMutualFollowers(List<Map<String, dynamic>> users) {
    final mutualFollowers = <Map<String, dynamic>>[];
    
    for (final user in users) {
      final email = user['email']?.toString();
      if (email != null) {
        final followStatus = getCachedFollowStatus(email);
        if (followStatus != null && followStatus['isMutualFollow'] == true) {
          final apiUserData = followStatus['user'] as Map<String, dynamic>;
          final enhancedUser = {
            ...user,
            'name': apiUserData['name'],
            'picture': apiUserData['picture'],
            'apiPictureUrl': apiUserData['picture']?.startsWith('/uploads/') == true
                ? 'http://182.93.94.210:3067${apiUserData['picture']}'
                : apiUserData['picture'],
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

  // Clear all caches
  void clearCache() {
    developer.log('🧹 Clearing all caches');
    _followStatusCache.clear();
    _cacheTimestamps.clear();
    _mutualFollowingsCache = null;
    _mutualFollowingsCacheTime = null;
    loadingStates.clear();
  }

  // Clean up expired cache entries
  void cleanupExpiredCache() {
    final now = DateTime.now();
    final expiredEmails = <String>[];
    
    // Clean individual follow status cache
    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) >= _cacheExpiry) {
        expiredEmails.add(entry.key);
      }
    }
    
    for (final email in expiredEmails) {
      _followStatusCache.remove(email);
      _cacheTimestamps.remove(email);
    }
    
    // Clean mutual followings cache
    if (_mutualFollowingsCacheTime != null && 
        now.difference(_mutualFollowingsCacheTime!) >= _mutualFollowingsCacheExpiry) {
      _mutualFollowingsCache = null;
      _mutualFollowingsCacheTime = null;
    }
    
    if (expiredEmails.isNotEmpty) {
      developer.log('🧹 Cleaned ${expiredEmails.length} expired cache entries');
    }
  }

  // Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'totalCached': _followStatusCache.length,
      'mutualFollowingsCached': _mutualFollowingsCache?.length ?? 0,
      'mutualFollowingsCacheAge': _mutualFollowingsCacheTime != null 
          ? DateTime.now().difference(_mutualFollowingsCacheTime!).inMinutes 
          : 0,
      'oldestCacheAge': _cacheTimestamps.isEmpty 
          ? 0 
          : DateTime.now().difference(_cacheTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b)).inMinutes,
      'pendingRequests': _pendingRequests.length,
      'loadingStates': loadingStates.length,
    };
  }
}