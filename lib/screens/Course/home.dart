// Updated HomeScreen for new API structure - NO UI CHANGES
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/screens/Course/models/api_models.dart';
import 'package:innovator/screens/Course/services/api_services.dart';
import 'package:innovator/screens/Course/sub_category_screen.dart';
import 'package:innovator/widget/FloatingMenuwidget.dart';
import 'dart:developer' as developer;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

 // Intialization It ronnf  jbisd sdf nj hjdsv sdn chjbd vfd ronit shri
class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  // Initilia ronit shrivastav ronit db r jbhf ro

  int _selectedIndex = 0;
  String _greeting = "Good Morning";
  String _searchQuery = "";
  String _selectedFilter = "All";
  List<String> _filterTypes = 
  [
    "All",
    "Electronics",
    "Programming",
    "Design",
    "Business",
    "Others",
  ];
  Timer? _timer;

  List<ParentCategory> _categories = [];
  List<ParentCategory> _filteredCategories = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _updateGreeting();
    _fetchCategories();

    // Update greeting every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateGreeting();
    });
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // Updated fetch categories for new API
  Future<void> _fetchCategories() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final response = await ApiService.getParentCategories();
      
      if (response['status'] == 200 && response['data'] != null) {
        final List<dynamic> categoriesJson = response['data'];
        final categories = categoriesJson
            .map((json) => ParentCategory.fromJson(json))
            .toList();

        setState(() {
          _categories = categories;
          _filteredCategories = [...categories];
          _isLoading = false;
        });

        developer.log('Loaded ${categories.length} categories');
      } else {
        throw Exception(response['message'] ?? 'Failed to load categories');
      }
    } catch (e) {
      developer.log('Error fetching categories: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  // Update greeting based on time of day
  void _updateGreeting() {
    final hour = DateTime.now().hour;
    setState(() {
      if (hour < 12) {
        _greeting = "Good Morning";
      } else if (hour < 17) {
        _greeting = "Good Afternoon";
      } else {
        _greeting = "Good Evening";
      }
    });
  }

  // Filter categories based on search query and selected filter
  void _filterCategories() {
    setState(() {
      _filteredCategories = _categories.where((category) {
        final matchesSearch = category.name.toLowerCase().contains(
          _searchQuery.toLowerCase(),
        );
        final matchesFilter =
            _selectedFilter == "All" || _getCategoryType(category.name) == _selectedFilter;
        return matchesSearch && matchesFilter;
      }).toList(); 
    });
  }

  // Get category type based on category name
  String _getCategoryType(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('electronic') || name.contains('circuit')) {
      return 'Electronics';
    } else if (name.contains('programming') || name.contains('code')) {
      return 'Programming';
    } else if (name.contains('design') || name.contains('ui')) {
      return 'Design';
    } else if (name.contains('business') || name.contains('marketing')) {
      return 'Business';// ronit shrivastav  jdhsv ronit shribvastav ronit shj
    } else {
      return 'Others';
    }
  }

  // Navigate to subcategory screen (now shows courses)
  void _navigateToSubcategory(ParentCategory category) {
    try {
      developer.log('Navigating to category courses: ${category.name}');
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubcategoryScreen(parentCategory: category),
        ),
      );
    } catch (e) {
      developer.log('Navigation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error navigating to ${category.name}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilterChips(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingWidget()
                  : _hasError
                      ? _buildErrorWidget()
                      : SingleChildScrollView(child: _buildCategoriesSection()),
            ),
           // _buildBottomNavBar(),
          ],
        ),
      ),
      floatingActionButton: const FloatingMenuWidget(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello,',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                _greeting,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
                    Text(
                      AppData().currentUserName ?? 'Welcome!',
                      style: const TextStyle(
                        fontSize: 20 ,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
            ],
          ),
          // Commented out notification icon as in original
          // IconButton(
          //   ic on: const Icon(Icons.notifications_outlined),
          //   onPressed: () {}, 
          //   iconSize: 28,
          // ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey.shade600),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search your topic',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _filterCategories();
                  });
                },
              ),
            ),
            // Commented out mic icon as in original
            // Icon(Icons.mic, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.only(left: 16.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterTypes.length,
        itemBuilder: (context, index) {
          final type = _filterTypes[index];
          final isSelected = _selectedFilter == type;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = type;
                  _filterCategories();
                });
              },
              backgroundColor: Colors.grey.shade200,
              selectedColor: const Color.fromRGBO(244, 135, 6, 1).withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? const Color.fromRGBO(244, 135, 6, 1) : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Color.fromRGBO(244, 135, 6, 1),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Loading categories...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 150,
              child: ElevatedButton(
                onPressed: _fetchCategories,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Explore Categories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'See All',
                  style: TextStyle(
                    color: Color.fromRGBO(244, 135, 6, 1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        _filteredCategories.isEmpty
            ? _buildEmptyState()
            : RefreshIndicator(
                onRefresh: _fetchCategories,
                color: const Color.fromRGBO(244, 135, 6, 1),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _filteredCategories.length,
                  itemBuilder: (context, index) {
                    return _buildCategoryCard(_filteredCategories[index]);
                  },
                ),
              ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Text(
          'No categories match your search',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(ParentCategory category) {
    return GestureDetector(
      onTap: () {
        developer.log('Category card tapped: ${category.name}');
        _navigateToSubcategory(category);
      },
      child: Container(
        decoration: BoxDecoration(
          color: _parseColor(category.color).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Category icon with a circular background
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconData(category.icon),
                size: 32,
                color: const Color.fromRGBO(244, 135, 6, 1),
              ),
            ),
            const SizedBox(height: 12),
            // Category title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                category.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            // Number of courses
            Text(
              '${category.statistics.courses} courses',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildBottomNavBar() {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(vertical: 10),
  //     color: Colors.white,
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //       children: [
  //         _buildNavItem(0, Icons.star, 'Featured'),
  //         _buildNavItem(1, Icons.play_circle_outline, 'My Learning'),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color.fromRGBO(244, 135, 6, 1) : Colors.grey,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? const Color.fromRGBO(244, 135, 6, 1) : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return const Color.fromRGBO(244, 135, 6, 1);
    } catch (e) {
      return const Color.fromRGBO(244, 135, 6, 1);
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'code':
        return Icons.code;
      case 'js':
        return Icons.javascript;
      case 'design':
        return Icons.design_services;
      case 'data':
        return Icons.analytics;
      case 'business':
        return Icons.business;
      case 'marketing':
        return Icons.campaign;
      case 'music':
        return Icons.music_note;
      case 'photo':
        return Icons.photo_camera;
      default:
        return Icons.category;
    }
  }
}