// Updated SubcategoryScreen with HomeScreen UI style
import 'package:flutter/material.dart';
import 'package:innovator/App_DATA/App_data.dart';
import 'package:innovator/screens/Course/course_details_screen.dart';
import 'package:innovator/screens/Course/models/api_models.dart';
import 'package:innovator/screens/Course/services/api_services.dart';
import 'package:innovator/widget/FloatingMenuwidget.dart';
import 'dart:developer' as developer;

class SubcategoryScreen extends StatefulWidget {
  final ParentCategory parentCategory;

  const SubcategoryScreen({
    Key? key,
    required this.parentCategory,
  }) : super(key: key);

  factory SubcategoryScreen.forSearch() {
    return SubcategoryScreen(
      parentCategory: ParentCategory(
        id: 'search',
        name: 'Search Courses',
        description: 'Discover courses across all categories',
        slug: 'search-courses',
        icon: 'search',
        color: '#F48706',
        isActive: true,
        sortOrder: 0,
        keywords: ['search', 'discover', 'find'],
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
      ),
    );
  }

  // Factory constructor for browsing all courses
  factory SubcategoryScreen.forBrowseAll() {
    return SubcategoryScreen(
      parentCategory: ParentCategory(
        id: 'all',
        name: 'All Courses',
        description: 'Browse all available courses',
        slug: 'all-courses',
        icon: 'school',
        color: '#F48706',
        isActive: true,
        sortOrder: 0,
        keywords: ['all', 'browse', 'courses'],
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
      ),
    );
  }

  // Factory constructor for featured courses
  factory SubcategoryScreen.forFeatured() {
    return SubcategoryScreen(
      parentCategory: ParentCategory(
        id: 'featured',
        name: 'Featured Courses',
        description: 'Handpicked courses for you',
        slug: 'featured-courses',
        icon: 'star',
        color: '#F48706',
        isActive: true,
        sortOrder: 0,
        keywords: ['featured', 'popular', 'recommended'],
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
      ),
    );
  }

  @override
  State<SubcategoryScreen> createState() => _SubcategoryScreenState();
}

class _SubcategoryScreenState extends State<SubcategoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<Course> _courses = [];
  List<Course> _filteredCourses = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _searchQuery = "";
  String _selectedFilter = "All";
  List<String> _filterTypes = [
    "All",
    "Beginner",
    "Intermediate",
    "Advanced",
    "Free",
    "Paid",
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchCourses();
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
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchCourses() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final response = await ApiService.getCategoryCourses(widget.parentCategory.id);
      
      if (response['status'] == 200 && response['data'] != null) {
        final categoryCoursesResponse = CategoryCoursesResponse.fromJson(response);
        
        setState(() {
          _courses = categoryCoursesResponse.data.courses;
          _filteredCourses = [..._courses];
          _isLoading = false;
        });

        developer.log('Loaded ${_courses.length} courses for category: ${widget.parentCategory.name}');
      } else {
        throw Exception(response['message'] ?? 'Failed to load courses');
      }
    } catch (e) {
      developer.log('Error fetching courses: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
      
      // Handle authentication errors
      if (e.toString().contains('Authentication required')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please login to view courses'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Login',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login', 
                    (route) => false,
                  );
                },
              ),
            ),
          );
        }
      }
    }
  }

  // Filter courses based on search query and selected filter
  void _filterCourses() {
    setState(() {
      _filteredCourses = _courses.where((course) {
        final matchesSearch = course.title.toLowerCase().contains(
          _searchQuery.toLowerCase(),
        );
        final matchesFilter = _selectedFilter == "All" || _getCourseType(course) == _selectedFilter;
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  // Get course type based on course properties
  String _getCourseType(Course course) {
    if (_selectedFilter == "Free" && course.price.usd == 0) {
      return "Free";
    } else if (_selectedFilter == "Paid" && course.price.usd > 0) {
      return "Paid";
    } else if (course.level.toLowerCase() == _selectedFilter.toLowerCase()) {
      return _selectedFilter;
    }
    return "All";
  }

  void _navigateToCourseDetail(Course course) {
    try {
      developer.log('Navigating to course: ${course.title}');
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CourseDetailScreen(course: course),
        ),
      );
    } 
    catch (e) {
      developer.log('Navigation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening ${course.title}: $e'),
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
      appBar: AppBar(
        title: Text(
          'Course',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.grey[50],
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
                      : SingleChildScrollView(child: _buildCoursesSection()),
            ),
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
                'Hello',
                style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
               AppData().currentUserName ?? 'Welcome  ',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
            ],
          ),
          
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
                  hintText: 'Search courses',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _filterCourses();
                  });
                },
              ),
            ),
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
                  _filterCourses();
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
            'Loading courses...',
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
                onPressed: _fetchCourses,
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

  Widget _buildCoursesSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available Courses',
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
        _filteredCourses.isEmpty
            ? _buildEmptyState()
            : RefreshIndicator(
                onRefresh: _fetchCourses,
                color: const Color.fromRGBO(244, 135, 6, 1),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _filteredCourses.length,
                  itemBuilder: (context, index) {
                    return _buildCourseCard(_filteredCourses[index]);
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
          'No courses match your search',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
  return GestureDetector(
    onTap: () => _navigateToCourseDetail(course),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course thumbnail
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                color: Colors.grey[200],
              ),
              child: course.thumbnail.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        ApiService.getFullMediaUrl(course.thumbnail),
                        fit: BoxFit.fill,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color.fromRGBO(244, 135, 6, 0.1),
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_outline,
                                color: Color.fromRGBO(244, 135, 6, 1),
                                size: 40,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        color: Color.fromRGBO(244, 135, 6, 0.1),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_outline,
                          color: Color.fromRGBO(244, 135, 6, 1),
                          size: 40,
                        ),
                      ),
                    ),
            ),
          ),
          // Course details - Fixed overflow issue
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8), // Reduced padding from 12 to 8
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Added this
                children: [
                  Flexible( // Wrapped title in Flexible
                    child: Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 13, // Reduced from 14 to 13
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2), // Reduced from 4 to 2
                  Flexible( // Wrapped in Flexible
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(244, 135, 6, 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            course.level.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Color.fromRGBO(244, 135, 6, 1),
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (course.price.usd == 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'FREE',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          )
                        else
                          Text(
                            '\$${course.price.usd}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color.fromRGBO(244, 135, 6, 1),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2), // Reduced from 4 to 2
                  Flexible( // Wrapped in Flexible
                    child: Row(
                      children: [
                        Icon(Icons.schedule, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded( // Added Expanded to prevent overflow
                          child: Text(
                            '${course.contentStatistics?.totalLessons ?? 0} lessons',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                            overflow: TextOverflow.ellipsis, // Added overflow handling
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
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