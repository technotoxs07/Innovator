import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/screens/Course/home.dart';
import 'package:innovator/screens/Course/models/api_models.dart';
import 'package:innovator/screens/Course/services/api_services.dart';
import 'package:innovator/screens/Events/Events.dart';
import 'package:innovator/screens/Project_Management/Project_idea.dart';
import 'package:innovator/screens/Shop/CardIconWidget/cart_state_manager.dart';
import 'package:innovator/utils/Drawer/custom_drawer.dart';
import 'package:innovator/Notification/FCM_Services.dart';
import 'package:innovator/innovator_home.dart';
import 'package:innovator/screens/Add_Content/Create_post.dart';
import 'package:innovator/screens/Search/Searchpage.dart';
import 'package:innovator/screens/Shop/Shop_Page.dart';

class FloatingMenuWidget extends StatefulWidget {
  const FloatingMenuWidget({super.key});

  @override
  _FloatingMenuWidgetState createState() => _FloatingMenuWidgetState();
}

class _FloatingMenuWidgetState extends State<FloatingMenuWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  double _buttonX = 0;
  double _buttonY = 0;
  int _unreadNotificationCount = 0;
  bool _isLoadingNotifications = false;

  final List<Map<String, dynamic>> _topIcons = [
    {'icon': Icons.home, 'name': 'FEED', 'action': 'navigate_golf'},
    {'icon': Icons.school, 'name': 'COURSE', 'action': 'open_search'},
    {'icon': Icons.add_a_photo, 'name': 'ADD POST', 'action': 'add_photo'},
    {'icon': Icons.developer_mode, 'name': 'Events', 'action': 'show_events'},
  ];

  final List<Map<String, dynamic>> _bottomIcons = [
    {'icon': Icons.shop, 'name': 'SHOP', 'action': 'open_settings'},
    {'icon': Icons.search, 'name': 'SEARCH', 'action': 'view_profile'},
    {
      'icon': Icons.notifications,
      'name': 'Notification',
      'action': 'notification',
    },
    {'icon': Icons.menu, 'name': 'Drawer', 'action': 'drawer'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final size = MediaQuery.of(context).size;
        setState(() {
          _buttonX = size.width - 60;
          _buttonY = size.height * 0.5;
        });
      }
    });

    // Fetch initial notification count
    _fetchUnreadNotificationCount();
    
    // Set up periodic refresh every 30 seconds
    _setupPeriodicRefresh();
  }

  void _setupPeriodicRefresh() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _fetchUnreadNotificationCount();
        _setupPeriodicRefresh();
      }
    });
  }

  Future<void> _fetchUnreadNotificationCount() async {
    if (_isLoadingNotifications) return;
    
    setState(() => _isLoadingNotifications = true);
    
    try {
      final token = AppData().authToken;
      if (token == null) return;

      final url = Uri.parse('http://182.93.94.210:3067/api/v1/notifications');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200 && mounted) {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> notifications = jsonData['data']['notifications'];
        
        // Count unread notifications
        final unreadCount = notifications.where((n) => n['read'] == false).length;
        
        setState(() {
          _unreadNotificationCount = unreadCount;
        });
      }
    } catch (e) {
      developer.log('Error fetching notification count: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingNotifications = false);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _handleIconPress(String action, BuildContext context) async {
    switch (action) {
      case 'navigate_golf':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Homepage()),
        );
        break;
      case 'open_search':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
        break;
      case 'add_photo':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CreatePostScreen()),
        );
        break;
      case 'show_events':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => Project_HomeScreen()),
        );
        break;
      case 'open_settings':
        if (!Get.isRegistered<CartStateManager>()) {
          Get.put(CartStateManager(), permanent: true);
        }
        final cartManager = Get.find<CartStateManager>();
        cartManager.refreshCartCount();

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ShopPage()),
        );
        break;
      case 'view_profile':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchPage()),
        );
        break;
      case 'notification':
        // Reset unread count when navigating to notifications
        setState(() {
          _unreadNotificationCount = 0;
        });
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationListScreen()),
        );
        // Refresh count when returning from notifications
        _fetchUnreadNotificationCount();
        break;
      case 'drawer':
        SmoothDrawerService.showLeftDrawer(context);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action not implemented: $action')),
        );
    }
  }

  BorderRadius _getButtonBorderRadius() {
    final size = MediaQuery.of(context).size;
    if (_buttonX >= size.width - 70) {
      return const BorderRadius.only(
        topLeft: Radius.circular(30),
        bottomLeft: Radius.circular(30),
      );
    } else if (_buttonX <= 70) {
      return const BorderRadius.only(
        topRight: Radius.circular(30),
        bottomRight: Radius.circular(30),
      );
    }
    return BorderRadius.circular(30);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Main floating button with badge
        Positioned(
          left: _buttonX,
          top: _buttonY - 25,
          child: Stack(
            children: [
              Draggable(
                feedback: Material(
                  color: Colors.orange.withAlpha(80),
                  borderRadius: _getButtonBorderRadius(),
                  child: Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    child: const Icon(Icons.menu, color: Colors.white, size: 24),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: Material(
                    color: Colors.orange,
                    borderRadius: _getButtonBorderRadius(),
                    child: Container(width: 50, height: 50),
                  ),
                ),
                onDragEnd: (details) {
                  setState(() {
                    _buttonX = (details.offset.dx).clamp(0.0, size.width - 50);
                    _buttonY = (details.offset.dy + 25).clamp(
                      50.0,
                      size.height - 50,
                    );
                    if (_isExpanded) {
                      _isExpanded = false;
                      _animationController.reverse();
                    }
                  });
                },
                child: GestureDetector(
                  onTap: _toggleMenu,
                  child: Material(
                    elevation: 4,
                    color: Colors.orange,
                    borderRadius: _getButtonBorderRadius(),
                    child: Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      child: AnimatedIcon(
                        icon: AnimatedIcons.menu_close,
                        progress: _animation,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              // Notification badge on main button
              if (_unreadNotificationCount > 0 && !_isExpanded)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _unreadNotificationCount > 99 
                        ? '99+' 
                        : _unreadNotificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_isExpanded)
          Positioned(
            left: _buttonX,
            top: _buttonY - 25 - (_topIcons.length * 52),
            child: _buildIconsContainer(_topIcons, context),
          ),
        if (_isExpanded)
          Positioned(
            left: _buttonX,
            top: _buttonY + 33,
            child: _buildIconsContainer(_bottomIcons, context),
          ),
      ],
    );
  }

  Widget _buildIconsContainer(
    List<Map<String, dynamic>> iconItems,
    BuildContext context,
  ) {
    final size = MediaQuery.of(context).size;
    BorderRadius borderRadius;
    if (_buttonX >= size.width - 70) {
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(25),
        bottomLeft: Radius.circular(25),
      );
    } else if (_buttonX <= 70) {
      borderRadius = const BorderRadius.only(
        topRight: Radius.circular(25),
        bottomRight: Radius.circular(25),
      );
    } else {
      borderRadius = BorderRadius.circular(25);
    }

    return Container(
      width: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 4,
            offset: const Offset(-1, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: iconItems.map((item) {
          final isNotification = item['action'] == 'notification';
          
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: () => _handleIconPress(item['action'], context),
              child: Tooltip(
                message: item['name'],
                child: Container(
                  height: 50,
                  width: 50,
                  alignment: Alignment.center,
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          item['icon'],
                          color: Colors.orange,
                          size: 22,
                        ),
                      ),
                      // Badge for notification icon in expanded menu
                      if (isNotification && _unreadNotificationCount > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 14,
                              minHeight: 14,
                            ),
                            child: Text(
                              _unreadNotificationCount > 99 
                                ? '99+' 
                                : _unreadNotificationCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}