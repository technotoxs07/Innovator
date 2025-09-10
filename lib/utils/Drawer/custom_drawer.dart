import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/Authorization/Login.dart';
import 'package:innovator/Notification/FCM_Services.dart';
import 'package:innovator/controllers/user_controller.dart';
import 'package:innovator/screens/Eliza_ChatBot/Elizahomescreen.dart';
import 'package:innovator/screens/Events/Events.dart';
import 'package:innovator/screens/F&Q/F&Qscreen.dart';
import 'package:innovator/screens/Privacy_Policy/privacy_screen.dart';
import 'package:innovator/screens/Profile/profile_page.dart';
import 'package:innovator/screens/Project_Management/Project_idea.dart';
import 'package:innovator/screens/Report/Report_screen.dart';
import 'package:innovator/screens/Settings/settings.dart';
import 'package:innovator/screens/chatApp/chat_homepage.dart';
import 'package:innovator/screens/chatApp/controller/chat_controller.dart';
import 'package:innovator/services/firebase_services.dart';
import 'package:innovator/utils/Drawer/drawer_cache_manager.dart';
import 'package:lottie/lottie.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Synchronous-only cache for instant access
class InstantCache {
  static Map<String, dynamic>? _data;
  static bool _isInitialized = false;

  // Initialize with current AppData - called once at app start
  static void init() {
    if (!_isInitialized) {
      final appData = AppData().currentUser;
      if (appData != null) {
        _data = Map<String, dynamic>.from(appData);
      }
      _isInitialized = true;
    }
  }

  // Get data synchronously (never null - returns default if empty)
  static Map<String, dynamic> get() {
    init(); // Ensure initialized
    return _data ?? {
      'name': 'User',
      'email': '',
      'picture': null,
    };
  }

  static void update(Map<String, dynamic> newData) {
    _data = Map<String, dynamic>.from(newData);
  }

  static void clear() {
    _data = null;
    _isInitialized = false;
  }
}

// INSTANT drawer service - zero async operations
class InstantDrawerService {
  static void show(BuildContext context) {
    // Pre-initialize cache before showing drawer
    InstantCache.init();
    
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 120), // Even faster
        reverseTransitionDuration: const Duration(milliseconds: 80),
        pageBuilder: (context, animation, _) {
          return _InstantDrawerOverlay(
            animation: animation,
            drawerWidth: math.min(MediaQuery.of(context).size.width * 0.8, 300.0),
          );
        },
      ),
    );
  }
}

class _InstantDrawerOverlay extends StatelessWidget {
  final Animation<double> animation;
  final double drawerWidth;

  const _InstantDrawerOverlay({
    required this.animation,
    required this.drawerWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        onHorizontalDragUpdate: (details) {
          if (details.delta.dx < -8) Navigator.of(context).pop();
        },
        child: Stack(
          children: [
            // Backdrop
            AnimatedBuilder(
              animation: animation,
              builder: (context, _) => Container(
                color: Colors.black.withOpacity(0.5 * animation.value),
              ),
            ),
            // Drawer
            AnimatedBuilder(
              animation: animation,
              builder: (context, _) => Transform.translate(
                offset: Offset(-drawerWidth * (1 - animation.value), 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: drawerWidth,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const TrueInstantDrawer(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Truly instant drawer - no async operations in initState or build
class TrueInstantDrawer extends StatefulWidget {
  const TrueInstantDrawer({super.key});

  @override
  State<TrueInstantDrawer> createState() => _TrueInstantDrawerState();
}

class _TrueInstantDrawerState extends State<TrueInstantDrawer> {
  // Display data - populated synchronously
  late String _userName;
  late String _userEmail;
  late String? _userPicture;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // CRITICAL: Only synchronous operations here
    _loadDataSynchronously();
    // Start background refresh AFTER drawer is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshInBackground();
    });
  }

  void _loadDataSynchronously() {
    // Get cached data instantly - never blocks
    final data = InstantCache.get();
    _userName = data['name'] ?? 'User';
    _userEmail = data['email'] ?? '';
    _userPicture = data['picture'];
  }

  void _refreshInBackground() async {
    // This runs AFTER the drawer is already open
    try {
      setState(() => _isRefreshing = true);
      
      // Try persistent cache first
      final persistentCache = await DrawerProfileCache.getCachedProfile();
      if (persistentCache != null && mounted) {
        final data = {
          'name': persistentCache.name,
          'email': persistentCache.email,
          'picture': persistentCache.picturePath,
        };
        _updateData(data);
        InstantCache.update(data);
      }
      
      // Then try network
      await _fetchFromNetwork();
    } catch (e) {
      developer.log('Background refresh failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _updateData(Map<String, dynamic> data) {
    if (mounted) {
      setState(() {
        _userName = data['name'] ?? 'User';
        _userEmail = data['email'] ?? '';
        _userPicture = data['picture'];
      });
    }
  }

  Future<void> _fetchFromNetwork() async {
    try {
      final authToken = AppData().authToken;
      if (authToken == null) return;

      final response = await http.get(
        Uri.parse('http://182.93.94.210:3067/api/v1/user-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 && mounted) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 200 && responseData['data'] != null) {
          final userData = responseData['data'];
          
          // Update all storage
          InstantCache.update(userData);
          AppData().setCurrentUser(userData);
          await DrawerProfileCache.cacheProfile(
            userId: userData['_id'] ?? '',
            name: userData['name'] ?? '',
            email: userData['email'] ?? '',
            picturePath: userData['picture'],
          );
          
          _updateData(userData);
        }
      }
    } catch (e) {
      developer.log('Network fetch failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildMenu()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.34,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEB6B46), Color(0xFFFF8A65), Color(0xFFEB6B46)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Profile picture
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: _buildProfileImage(),
                  ),
                  // Refresh indicator
                  if (_isRefreshing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Color(0xFFEB6B46),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Welcome text
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // User name
              Text(
                _userName,
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Email
              if (_userEmail.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    _userEmail,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    const baseUrl = 'http://182.93.94.210:3067';
    
    // NO HERO WIDGET - Simple Container to avoid conflicts
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
        image: _userPicture != null && _userPicture!.isNotEmpty
            ? DecorationImage(
                image: CachedNetworkImageProvider('$baseUrl$_userPicture'),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {
                  // Handle error silently
                },
              )
            : null,
      ),
      child: _userPicture == null || _userPicture!.isEmpty
          ? const Icon(
              Icons.person,
              size: 35,
              color: Colors.white,
            )
          : null,
    );
  }

  Widget _buildMenu() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          _QuickMenuItem(icon: Icons.message_rounded, title: 'Messages', onTap: _goToMessages),
          _QuickMenuItem(icon: Icons.person_rounded, title: 'Profile', onTap: _goToProfile),
          _QuickMenuItem(icon: Icons.psychology_rounded, title: 'Eliza ChatBot', onTap: _goToEliza),
          _QuickMenuItem(icon: Icons.event_available, title: 'Events', onTap: _goToEvents),
          _QuickMenuItem(icon: Icons.report_rounded, title: 'Reports', onTap: _goToReports),
          _QuickMenuItem(icon: Icons.privacy_tip_rounded, title: 'Privacy & Policy', onTap: _goToPrivacy),
          _QuickMenuItem(icon: Icons.settings, title: 'Settings', onTap: _goToSettings),
          _QuickMenuItem(icon: Icons.help_rounded, title: 'FAQ', onTap: _goToFAQ),
          
          const SizedBox(height: 20),
          _buildDivider(),
          
          _QuickMenuItem(
            icon: Icons.logout_rounded, 
            title: 'Logout', 
            onTap: _showLogout,
            isLogout: true,
          ),
          
          const SizedBox(height: 20),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.grey.shade300, Colors.transparent],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEB6B46).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.rocket_launch, color: Color(0xFFEB6B46), size: 20),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Innovator App v:1.0.27', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
              Text('Pvt Ltd', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
            ],
          ),
        ],
      ),
    );
  }

  // Navigation methods - all instant
  void _goToMessages() => _quickNavigate(() => const OptimizedChatHomePage());
  void _goToProfile() => _quickNavigate(() => ProviderScope(child: UserProfileScreen(userId: AppData().currentUserId ?? '')));
  void _goToEliza() => _quickNavigate(() => ElizaChatScreen());
  void _goToEvents() => _quickNavigate(() => EventsHomePage());
  void _goToReports() => _quickNavigate(() => ReportsScreen());
  void _goToPrivacy() => _quickNavigate(() => const ProviderScope(child: PrivacyPolicy()));
  void _goToSettings() => _quickNavigate(() => const SettingsScreen());
  void _goToFAQ() => _quickNavigate(() => const FAQScreen());

  void _quickNavigate(Widget Function() builder) {
    Navigator.of(context).pop(); // Close drawer
    Navigator.push(context, MaterialPageRoute(builder: (_) => builder()));
  }

  void _showLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout Confirmation'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _performQuickLogout(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _performQuickLogout(BuildContext dialogContext) async {
    Navigator.pop(dialogContext);
    Navigator.pop(context);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Logging out...'),
          ],
        ),
      ),
    );

    try {
      // Quick cleanup
      if (Get.isRegistered<FireChatController>()) {
        Get.find<FireChatController>().cancelAllStreamSubscriptionsImmediate();
      }
      
      await Future.wait([
        FirebaseAuth.instance.signOut(),
        GoogleSignIn().signOut(),
        AppData().clearAuthToken(),
      ]);
      
      InstantCache.clear();
      
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }
}

// Ultra-lightweight menu item
class _QuickMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isLogout;

  const _QuickMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: isLogout
                ? LinearGradient(colors: [Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.2)])
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isLogout
                      ? Colors.red.withOpacity(0.1)
                      : const Color(0xFFEB6B46).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isLogout ? Colors.red : const Color(0xFFEB6B46),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isLogout ? Colors.red : Colors.grey.shade800,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

// Public interface
class SmoothDrawerService {
  static void showLeftDrawer(BuildContext context) {
    InstantDrawerService.show(context);
  }
}

// Compatibility classes
class CustomDrawer extends TrueInstantDrawer {
  const CustomDrawer({super.key});
}

class OptimizedCustomDrawer extends TrueInstantDrawer {
  const OptimizedCustomDrawer({super.key});
}

class ZeroLagDrawer extends TrueInstantDrawer {
  const ZeroLagDrawer({super.key});
}