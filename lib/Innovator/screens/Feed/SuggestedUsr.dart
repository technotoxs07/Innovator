import 'dart:convert';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/Authorization/Login.dart';
import 'package:innovator/Innovator/screens/Follow/follow_Button.dart';
import 'package:innovator/Innovator/screens/comment/JWT_Helper.dart';
import 'package:innovator/Innovator/screens/SHow_Specific_Profile/Show_Specific_Profile.dart';

class SuggestedUser {
  final String id;
  final String name;
  final String email;
  final String picture;
  final String profession;
  final String location;
  final int followers;
  final int following;
  final bool isVerified;
  final String level;

  SuggestedUser({
    required this.id,
    required this.name,
    required this.email,
    required this.picture,
    this.profession = '',
    this.location = '',
    this.followers = 0,
    this.following = 0,
    this.isVerified = false,
    this.level = 'bronze',
  });

  factory SuggestedUser.fromJson(Map<String, dynamic> json) {
    return SuggestedUser(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      email: json['email'] ?? '',
      picture: json['picture'] ?? '',
      profession: json['profession'] ?? '',
      location: json['location'] ?? '',
      followers: json['followers'] ?? 0,
      following: json['following'] ?? 0,
      isVerified: json['isVerified'] ?? false,
      level: json['level'] ?? 'bronze',
    );
  }

  String get profilePictureUrl {
    if (picture.isEmpty) return '';
    if (picture.startsWith('http')) return picture;
    return 'http://182.93.94.210:3067$picture';
  }
}

// Suggested Users API Service
class SuggestedUsersService {
  static const String baseUrl = 'http://182.93.94.210:3067';

  static Future<List<SuggestedUser>> fetchSuggestedUsers({
    int limit = 10,
    required BuildContext context,
  }) async {
    try {
      final String? authToken = AppData().authToken;
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (authToken != null && authToken.isNotEmpty) {
        headers['authorization'] = 'Bearer $authToken';
      }

      final uri = Uri.parse(
        '$baseUrl/api/v1/users',
      ).replace(queryParameters: {'limit': limit.toString()});

      debugPrint('🌐 Fetching suggested users from: $uri');

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      debugPrint('📡 Suggested users response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = json.decode(response.body);

        if (responseJson['status'] == 200 && responseJson['data'] != null) {
          final List<dynamic> usersData = responseJson['data'] as List<dynamic>;

          // Filter out current user
          final String? currentUserId = _getCurrentUserId();
          final filteredUsers =
              usersData.where((userData) {
                final userId = userData['_id'] as String?;
                return userId != null && userId != currentUserId;
              }).toList();

          return filteredUsers
              .map(
                (userData) =>
                    SuggestedUser.fromJson(userData as Map<String, dynamic>),
              )
              .toList();
        }

        return [];
      } else if (response.statusCode == 401) {
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => LoginPage()),
            (route) => false,
          );
        }
        throw Exception('Authentication required');
      } else {
        throw Exception(
          'Failed to load suggested users: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('❌ SuggestedUsersService.fetchSuggestedUsers error: $e');
      return [];
    }
  }

  static String? _getCurrentUserId() {
    final String? token = AppData().authToken;
    if (token != null && token.isNotEmpty) {
      try {
        return JwtHelper.extractUserId(token);
      } catch (e) {
        debugPrint('Error extracting user ID from token: $e');
      }
    }
    return null;
  }
}

// Enhanced SuggestedUsersWidget with modern UI
class SuggestedUsersWidget extends StatefulWidget {
  final String? instanceId;

  const SuggestedUsersWidget({Key? key, this.instanceId}) : super(key: key);

  @override
  State<SuggestedUsersWidget> createState() => _SuggestedUsersWidgetState();
}

class _SuggestedUsersWidgetState extends State<SuggestedUsersWidget> {
  List<SuggestedUser> _suggestedUsers = [];
  bool _isLoading = false;
  bool _hasError = false;
  bool _hasLoadedData = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestedUsers();
  }

  Future<void> _loadSuggestedUsers() async {
    if (!mounted || _hasLoadedData) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final users = await SuggestedUsersService.fetchSuggestedUsers(
        limit: 8,
        context: context,
      );

      if (mounted) {
        setState(() {
          _suggestedUsers = users;
          _isLoading = false;
          _hasLoadedData = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _hasLoadedData = true;
        });
      }
      debugPrint('Error loading suggested users: $e');
    }
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'gold':
        return const Color(0xFFFFD700);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'platinum':
        return const Color(0xFFE5E4E2);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isTablet = screenWidth > 600;

    if (_isLoading) {
      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                child: Image.asset(
                  'animation/IdeaBulb.gif',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Finding awesome people...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasError || _suggestedUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        // color: Colors.red,
        borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.grey.shade300
      ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clean and minimal header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withAlpha(10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.people_outline,
                      color: Color(0xFF6366F1),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'People May You Know',
                          style: TextStyle(
                            fontSize: isTablet ? 17 : 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Connect with new people',
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (mounted) {
                        setState(() {
                          _suggestedUsers.clear();
                        });
                      }
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        
            // Users horizontal list
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _suggestedUsers.length,
                itemBuilder: (context, index) {
                  final user = _suggestedUsers[index];
                  return Container(
                    width: 150,
                    margin: EdgeInsets.only(
                      right: index == _suggestedUsers.length - 1 ? 0 : 12,
                    ),
                    child: _buildUserCard(user, isTablet),
                  );
                },
              ),
            ),
        
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(SuggestedUser user, bool isTablet) {
    return GestureDetector(
      onTap: () => _navigateToProfile(user),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Profile picture with level indicator
              Stack(
                children: [
                  _buildUserAvatar(user, radius: isTablet ? 24 : 22),
                  // Level badge - cleaner design
                  // Positioned(
                  //   bottom: -2,Hjr 
                  //   right: -2,
                  //   child: Container(
                  //     width: 16,
                  //     height: 16,
                  //     decoration: BoxDecoration(
                  //       color: _getLevelColor(user.level),
                  //       shape: BoxShape.circle,
                  //       border: Border.all(color: Colors.white, width: 2),
                  //     ),
                  //   ),
                  // ),
                  // Verified badge - minimal
                  if (user.isVerified)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1DA1F2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Name - clean typography
              Text(
                user.name,
                style: TextStyle(
                  fontSize: isTablet ? 14 : 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Profession - subtle
              if (user.profession.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  user.profession,
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              //const SizedBox(height: 12),

              // Follow button - modern design
              FollowButton(
                targetUserEmail: user.email,
                initialFollowStatus: false,
                onFollowSuccess: () {
                  debugPrint('Followed user: ${user.name}');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Now following ${user.name}'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF10B981),
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }
                },
                onUnfollowSuccess: () {
                  debugPrint('Unfollowed user: ${user.name}');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(SuggestedUser user, {double radius = 22}) {
    if (user.picture.isEmpty) {
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withAlpha(10),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: TextStyle(
              fontSize: radius * 0.6,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6366F1),
            ),
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: user.profilePictureUrl,
      imageBuilder: (context, imageProvider) => Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: imageProvider,
            fit: BoxFit.cover,
          ),
        ),
      ),
      placeholder: (context, url) => Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SizedBox(
            width: radius * 0.8,
            height: radius * 0.8,
            child: Image.asset('animation/IdeaBulb.gif', fit: BoxFit.contain),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withAlpha(10),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: TextStyle(
              fontSize: radius * 0.6,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6366F1),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToProfile(SuggestedUser user) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SpecificUserProfilePage(userId: user.id),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

// Configuration class for suggested users behavior
class SuggestedUsersConfig {
  static const int minPostsBeforeFirstSuggestion = 5;
  static const int maxPostsBeforeFirstSuggestion = 10;
  static const int minIntervalBetweenSuggestions = 10;
  static const int maxIntervalBetweenSuggestions = 20;
  static const int maxSuggestionsPerSession = 3;

  static int getRandomInterval(int min, int max, int seed) {
    return min + (seed % (max - min + 1));
  }
}