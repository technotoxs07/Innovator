import 'dart:convert';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/Authorization/Login.dart';
import 'package:innovator/screens/Follow/follow_Button.dart';
import 'package:innovator/screens/comment/JWT_Helper.dart';
import 'package:innovator/screens/SHow_Specific_Profile/Show_Specific_Profile.dart';

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
    return 'http://182.93.94.210:3066$picture';
  }
}

// Suggested Users API Service
class SuggestedUsersService {
  static const String baseUrl = 'http://182.93.94.210:3064';

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

// Updated SuggestedUsersWidget with MediaQuery integration
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
        return Colors.amber;
      case 'silver':
        return Colors.grey;
      case 'bronze':
        return Colors.orange.shade800;
      case 'platinum':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 800;

    // Responsive dimensions
    final cardMargin = EdgeInsets.symmetric(
      vertical: screenHeight * 0.008,
      horizontal: screenWidth * 0.027,
    );

    final cardPadding = EdgeInsets.all(screenWidth * 0.04);
    final headerPadding = EdgeInsets.all(screenWidth * 0.04);

    final titleFontSize = isTablet ? 17.0 : 15.0;
    final subtitleFontSize = isTablet ? 15.0 : 13.0;

    final cardWidth = isLargeScreen ? 140.0 : (isTablet ? 130.0 : 120.0);
    final cardHeight = isLargeScreen ? 160.0 : (isTablet ? 150.0 : 140.0);

    final avatarRadius = isTablet ? 25.0 : 20.0;

    if (_isLoading) {
      return Container(
        margin: cardMargin,
        padding: EdgeInsets.all(screenWidth * 0.05),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 20.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: screenWidth * 0.1,
                height: screenWidth * 0.1,
                child: Image.asset(
                  'animation/IdeaBulb.gif',
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: screenHeight * 0.015),
              Text(
                'Loading suggestions...',
                style: TextStyle(
                  fontSize: isTablet ? 16.0 : 14.0,
                  color: Colors.grey,
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
      margin: cardMargin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 20.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with responsive design
          Container(
            padding: headerPadding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromRGBO(240, 155, 52, 1), // Your brand orange
                  Color.fromRGBO(255, 204, 128, 1), // Soft amber
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ), //
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.02),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Icon(
                    Icons.people_alt_outlined,
                    color: Colors.blue.shade700,
                    size: isTablet ? 24 : 20,
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Suggested for you',
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        'People you might want to follow',
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (mounted) {
                      setState(() {
                        _suggestedUsers.clear();
                      });
                    }
                  },
                  icon: Icon(
                    Icons.close,
                    size: isTablet ? 22 : 18,
                    color: Colors.grey.shade600,
                  ),
                  padding: EdgeInsets.all(screenWidth * 0.01),
                  constraints: BoxConstraints(
                    minWidth: screenWidth * 0.08,
                    minHeight: screenWidth * 0.08,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: screenHeight * 0.02),

          // Horizontal scrolling users with responsive sizing
          Container(
            height: cardHeight,
            padding: EdgeInsets.only(bottom: screenHeight * 0.02),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              itemCount: _suggestedUsers.length,
              itemBuilder: (context, index) {
                final user = _suggestedUsers[index];
                return Container(
                  width: cardWidth,
                  margin: EdgeInsets.only(right: screenWidth * 0.03),
                  child: _buildCompactUserCard(
                    user,
                    screenWidth,
                    screenHeight,
                    isTablet,
                    avatarRadius,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactUserCard(
    SuggestedUser user,
    double screenWidth,
    double screenHeight,
    bool isTablet,
    double avatarRadius,
  ) {
    final nameFontSize = isTablet ? 13.0 : 12.0;
    final professionFontSize = isTablet ? 11.0 : 9.0;
    final buttonFontSize = isTablet ? 12.0 : 11.0;
    final buttonHeight = isTablet ? 32.0 : 28.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.02),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Profile Picture with badges
            Stack(
              children: [
                GestureDetector(
                  onTap: () => _navigateToProfile(user),
                  child: _buildUserAvatar(user, radius: avatarRadius),
                ),
                // Level badge with responsive sizing
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: isTablet ? 18 : 16,
                    height: isTablet ? 18 : 16,
                    decoration: BoxDecoration(
                      color: _getLevelColor(user.level),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        user.level[0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 9 : 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                // Verified badge with responsive sizing
                if (user.isVerified)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: isTablet ? 16 : 14,
                      height: isTablet ? 16 : 14,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.verified,
                        color: Colors.white,
                        size: isTablet ? 10 : 8,
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(height: screenHeight * 0.008),

            // Name with responsive font size
            Text(
              user.name,
              style: TextStyle(
                fontSize: nameFontSize,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Profession (if available) with responsive font size
            // if (user.profession.isNotEmpty) ...[
            //   SizedBox(height: screenHeight * 0.003),
            //   Text(
            //     user.profession,
            //     style: TextStyle(
            //       fontSize: professionFontSize,
            //       color: Colors.grey.shade600,
            //     ),
            //     textAlign: TextAlign.center,
            //     maxLines: 1,
            //     overflow: TextOverflow.ellipsis,
            //   ),
            // ],

            SizedBox(height: screenHeight * 0.008),

            // Follow button with responsive sizing
            SizedBox(
              width: double.infinity,
              height: buttonHeight,
              child: FollowButton(
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
                        margin: EdgeInsets.only(
                          bottom: screenHeight * 0.02,
                          left: screenWidth * 0.05,
                          right: screenWidth * 0.05,
                        ),
                      ),
                    );
                  }
                },
                onUnfollowSuccess: () {
                  debugPrint('Unfollowed user: ${user.name}');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(SuggestedUser user, {double radius = 30}) {
    if (user.picture.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white,
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: radius * 0.6,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: user.profilePictureUrl,
      imageBuilder:
          (context, imageProvider) => CircleAvatar(
            radius: radius,
            backgroundColor: Colors.white,
            backgroundImage: imageProvider,
          ),
      placeholder:
          (context, url) => CircleAvatar(
            radius: radius,
            backgroundColor: Colors.white,
            child: Container(
              width: radius * 0.8,
              height: radius * 0.8,
              child: Image.asset('animation/IdeaBulb.gif', fit: BoxFit.contain),
            ),
          ),
      errorWidget:
          (context, url, error) => CircleAvatar(
            radius: radius,
            backgroundColor: Colors.white,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: radius * 0.6,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
    );
  }

  void _navigateToProfile(SuggestedUser user) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                SpecificUserProfilePage(userId: user.id),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
            ),
            child: child,
          );
        },
      ),
    );
  }
}

// Configuration class for suggested users behavior
class SuggestedUsersConfig {
  static const int minPostsBeforeFirstSuggestion = 3;
  static const int maxPostsBeforeFirstSuggestion = 7;
  static const int minIntervalBetweenSuggestions = 8;
  static const int maxIntervalBetweenSuggestions = 15;
  static const int maxSuggestionsPerSession = 3;

  static int getRandomInterval(int min, int max, int seed) {
    return min + (seed % (max - min + 1));
  }
}
