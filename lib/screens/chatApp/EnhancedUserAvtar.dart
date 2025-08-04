import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EnhancedUserAvatar extends StatelessWidget {
  final Map<String, dynamic>? user;
  final double radius;
  final bool isOnline;
  final bool showOnlineIndicator;
  final Color? backgroundColor;
  final String? heroTag;
  final VoidCallback? onTap;

  const EnhancedUserAvatar({
    Key? key,
    required this.user,
    this.radius = 30,
    this.isOnline = false,
    this.showOnlineIndicator = true,
    this.backgroundColor,
    this.heroTag,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userName = user?['name']?.toString() ?? 'Unknown User';
    final profilePictureUrl = _getProfilePictureUrl();
    final avatarBackgroundColor = backgroundColor ?? const Color.fromRGBO(244, 135, 6, 1);

    Widget avatarWidget = Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: showOnlineIndicator && isOnline 
                  ? Colors.green 
                  : Colors.grey.shade300,
              width: 2,
            ),
            boxShadow: showOnlineIndicator && isOnline
                ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: avatarBackgroundColor,
            child: _buildAvatarContent(profilePictureUrl, userName),
          ),
        ),
        if (showOnlineIndicator)
          Positioned(
            bottom: 2,
            right: 2,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: radius * 0.4,
              height: radius * 0.4,
              decoration: BoxDecoration(
                color: isOnline ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: isOnline
                    ? [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.6),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
      ],
    );

    // Wrap with Hero if heroTag is provided
    if (heroTag != null) {
      avatarWidget = Hero(
        tag: heroTag!,
        child: avatarWidget,
      );
    }

    // Wrap with GestureDetector if onTap is provided
    if (onTap != null) {
      avatarWidget = GestureDetector(
        onTap: onTap,
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }

  Widget _buildAvatarContent(String? profilePictureUrl, String userName) {
    if (profilePictureUrl != null && profilePictureUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CachedNetworkImage(
          imageUrl: profilePictureUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: backgroundColor ?? const Color.fromRGBO(244, 135, 6, 1),
            child: Center(
              child: SizedBox(
                width: radius * 0.6,
                height: radius * 0.6,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: backgroundColor ?? const Color.fromRGBO(244, 135, 6, 1),
            child: Center(
              child: Text(
                _getUserInitials(userName),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: radius * 0.8,
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      return Text(
        _getUserInitials(userName),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      );
    }
  }

  String? _getProfilePictureUrl() {
    if (user == null) return null;
    
    // First try API picture URL
    final apiPictureUrl = user!['apiPictureUrl']?.toString();
    if (apiPictureUrl != null && apiPictureUrl.isNotEmpty) {
      return apiPictureUrl;
    }
    
    // Fallback to picture field with base URL
    final picture = user!['picture']?.toString();
    if (picture != null && picture.isNotEmpty) {
      if (picture.startsWith('http')) {
        return picture;
      } else {
        return 'http://182.93.94.210:3066$picture';
      }
    }
    
    // Fallback to photoURL (existing Firestore field)
    final photoURL = user!['photoURL']?.toString();
    if (photoURL != null && photoURL.isNotEmpty) {
      return photoURL;
    }
    
    return null;
  }

  String _getUserInitials(String userName) {
    if (userName.isEmpty) return 'U';
    
    final words = userName.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else {
      return userName.substring(0, 1).toUpperCase();
    }
  }
}