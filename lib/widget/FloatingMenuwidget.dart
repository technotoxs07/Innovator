import 'dart:developer' as developer;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:innovator/screens/Course/home.dart';
import 'package:innovator/screens/Course/models/api_models.dart';
import 'package:innovator/screens/Course/services/api_services.dart';
import 'package:innovator/screens/Course/sub_category_screen.dart';
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
        // Fetch the first category and navigate to it
        try {
          final categoriesResponse = await ApiService.getParentCategories();
          if (categoriesResponse['status'] == 200 &&
              categoriesResponse['data'] != null &&
              (categoriesResponse['data'] as List).isNotEmpty) {
            final firstCategory = ParentCategory.fromJson(
              categoriesResponse['data'][0],
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => ProviderScope(
                      child: SubcategoryScreen(parentCategory: firstCategory),
                    ),
              ),
            );
          } else {
            // Fallback: Create a special search category
            final searchCategory = ParentCategory(
              id: 'search',
              name: 'Search Courses',
              description: 'Find the perfect course for you',
              slug: 'search-courses',
              icon: 'search',
              color: '#F48706',
              isActive: true,
              sortOrder: 0,
              keywords: ['search', 'find', 'browse'],
              createdBy: CreatedBy(
                id: 'system',
                email: 'system@app.com',
                name: 'System',
              ),
              statistics: Statistics(
                courses: 0,
                lessons: 0,
                notes: 0,
                videos: 0,
              ),
              createdAt: DateTime.now().toIso8601String(),
              updatedAt: DateTime.now().toIso8601String(),
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => ProviderScope(
                      child: SubcategoryScreen(parentCategory: searchCategory),
                    ),
              ),
            );
          }
        } catch (e) {
          developer.log('Error fetching categories for navigation: $e');

          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unable to load courses. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
        // Ensure cart controller is available before navigating
        if (!Get.isRegistered<CartStateManager>()) {
          Get.put(CartStateManager(), permanent: true);
        }
        // Also refresh cart count when navigating to shop
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
      case 'notification':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationListScreen()),
        );
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
        Positioned(
          left: _buttonX,
          top: _buttonY - 25,
          child: Draggable(
            feedback: Material(
              color: Colors.orange.withOpacity(0.8),
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
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(-1, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children:
            iconItems
                .map(
                  (item) => Material(
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
                          child: Icon(
                            item['icon'],
                            color: Colors.orange,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }
}
