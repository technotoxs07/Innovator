// home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/controllers/user_controller.dart';
import 'package:innovator/screens/Course/course_details_screen.dart';
import 'package:innovator/models/Course_models.dart';
import 'package:innovator/screens/Course/services/api_services.dart';
import 'package:innovator/utils/Drawer/custom_drawer.dart';
import 'package:innovator/widget/FloatingMenuwidget.dart';
import 'dart:developer' as developer;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _selectedIndex = 0;
  String _greeting = "Good Morning";
  String _searchQuery = "";
  String _selectedFilter = "All";
  Timer? _timer;

  // Course data
  List<Course> _courses = [];
  List<Course> _filteredCourses = [];
  List<Course> _enrolledCourses = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentPage = 0;
  bool _hasMoreCourses = true;
  final ScrollController _scrollController = ScrollController();

  // Filter categories
  final List<String> _filterTypes = [
    "All",
    "Free",
    "Paid",
    "IOT",
    "Programming",
    "Become A Steam Tutor",
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _updateGreeting();
    _fetchCourses();
    _setupScrollListener();

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

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreCourses();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Fetch courses from API
  Future<void> _fetchCourses() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Fetch all courses
      final response = await ApiService.getCourses(page: 0, limit: 10);
      
      if (response['status'] == 200 && response['data'] != null) {
        final courseData = CourseData.fromJson(response['data']);
        
        setState(() {
          _courses = courseData.courses;
          _filteredCourses = [..._courses];
          _hasMoreCourses = courseData.pagination.hasMore;
          _isLoading = false;
        });

        developer.log('Loaded ${_courses.length} courses');
        
        // Fetch enrolled courses if authenticated
        if (AppData().isAuthenticated) {
          _fetchEnrolledCourses();
        }
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
    }
  }

  // Load more courses (pagination)
  Future<void> _loadMoreCourses() async {
    if (_isLoading || !_hasMoreCourses) return;

    try {
      setState(() {
        _isLoading = true;
      });

      _currentPage++;
      final response = await ApiService.getCourses(
        page: _currentPage, 
        limit: 10
      );
      
      if (response['status'] == 200 && response['data'] != null) {
        final courseData = CourseData.fromJson(response['data']);
        
        setState(() {
          _courses.addAll(courseData.courses);
          _filterCourses();
          _hasMoreCourses = courseData.pagination.hasMore;
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Error loading more courses: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch enrolled courses
  Future<void> _fetchEnrolledCourses() async {
    try {
      final response = await ApiService.getEnrolledCourses();
      
      if (response['status'] == 200 && response['data'] != null) {
        final courseData = CourseData.fromJson(response['data']);
        setState(() {
          _enrolledCourses = courseData.courses;
        });
        developer.log('Loaded ${_enrolledCourses.length} enrolled courses');
      }
    } catch (e) {
      developer.log('Error fetching enrolled courses: $e');
    }
  }

  // Update greeting based on time of day
  void _updateGreeting() {
    final hour = DateTime.now().hour;
    final appData = AppData();
    final userName = appData.currentUserName ?? 'Learner';
    
    setState(() {
      if (hour < 12) {
        _greeting = "Good Morning, $userName";
      } else if (hour < 17) {
        _greeting = "Good Afternoon, $userName";
      } else {
        _greeting = "Good Evening, $userName";
      }
    });
  }

  // Filter courses
  void _filterCourses() {
    setState(() {
      _filteredCourses = _courses.where((course) {
        // Search filter
        final matchesSearch = course.title.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            course.description.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );

        // Category filter
        bool matchesFilter = true;
        switch (_selectedFilter) {
          case "Free":
            matchesFilter = course.price.usd == 0;
            break;
          case "Paid":
            matchesFilter = course.price.usd > 0;
            break;
          case "IOT":
            matchesFilter = course.level.toLowerCase() == "iot";
            break;
          case "Programming":
            matchesFilter = course.level.toLowerCase() == "programming";
            break;
          case "Become A Steam Tutor":
            matchesFilter = course.level.toLowerCase() == "become a steam tutor";
            break;
          default:
            matchesFilter = true;
        }

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  // Navigate to course detail
  void _navigateToCourseDetail(Course course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseDetailScreen(
          courseId: course.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilterChips(),
            Expanded(
              child: _isLoading && _courses.isEmpty
                  ? _buildLoadingWidget()
                  : _hasError
                      ? _buildErrorWidget()
                      : RefreshIndicator(
                          onRefresh: _fetchCourses,
                          color: const Color.fromRGBO(244, 135, 6, 1),
                          child: CustomScrollView(
                            controller: _scrollController,
                            slivers: [
                              if (_selectedIndex == 1 && _enrolledCourses.isNotEmpty)
                                _buildEnrolledCoursesSection(),
                              _buildCoursesSection(),
                              if (_isLoading && _courses.isNotEmpty)
                                const SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Color.fromRGBO(244, 135, 6, 1),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
            ),
           // _buildBottomNavBar(),
          ],
        ),
      ),
      floatingActionButton: const FloatingMenuWidget(),
    );
  }

  Widget _buildHeader() {
  final appData = AppData();
  
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back!',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              _greeting,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        // Fixed CircleAvatar implementation
        _buildProfileAvatar(appData),
      ],
    ),
  );
}


Widget _buildProfileAvatar(AppData appData) {
  final profilePictureUrl = appData.currentUserProfilePicture;
  const String baseUrl = 'http://182.93.94.210:3067';
  
  if (profilePictureUrl != null && profilePictureUrl.isNotEmpty) {
    // Build the full URL if it's a relative path
    final fullUrl = profilePictureUrl.startsWith('http') 
        ? profilePictureUrl 
        : '$baseUrl$profilePictureUrl';
    
    return CircleAvatar(
      radius: 28,
      backgroundColor: const Color.fromRGBO(244, 135, 6, 0.1),
      backgroundImage: NetworkImage(fullUrl),
      onBackgroundImageError: (exception, stackTrace) {
        // Handle image loading errors
        print('Error loading profile picture: $exception');
      },
      child: null, // Will show the image if loaded successfully
    );
  } else {
    // Fallback when no profile picture is available
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(244, 135, 6, 0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color.fromRGBO(244, 135, 6, 0.3),
          width: 2.8,
        ),
      ),
      child: const Icon(
        Icons.person,
        color: Color.fromRGBO(244, 135, 6, 1),
        size: 24,
      ),
    );
  }
}

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.search, color: Color.fromRGBO(244, 135, 6, 1)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search courses...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey[500]),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _filterCourses();
                  });
                },
              ),
            ),
            if (_searchQuery.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _filterCourses();
                  });
                },
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
                  _selectedFilter = selected ? type : "All";
                  _filterCourses();
                });
              },
              backgroundColor: Colors.white,
              selectedColor: const Color.fromRGBO(244, 135, 6, 0.2),
              labelStyle: TextStyle(
                color: isSelected ? const Color.fromRGBO(244, 135, 6, 1) : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected 
                      ? const Color.fromRGBO(244, 135, 6, 1)
                      : Colors.grey[300]!,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnrolledCoursesSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Continue Learning',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _enrolledCourses.length,
              itemBuilder: (context, index) {
                final course = _enrolledCourses[index];
                return _buildEnrolledCourseCard(course);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrolledCourseCard(Course course) {
    return GestureDetector(
      onTap: () => _navigateToCourseDetail(course),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                gradient: LinearGradient(
                  colors: [
                    const Color.fromRGBO(244, 135, 6, 0.8),
                    const Color.fromRGBO(244, 135, 6, 0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.play_circle_filled,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Continue from where you left',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: 0.3, // You can calculate actual progress
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color.fromRGBO(244, 135, 6, 1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesSection() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index < _filteredCourses.length) {
              return _buildCourseCard(_filteredCourses[index]);
            }
            return null;
          },
          childCount: _filteredCourses.length,
        ),
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    final bool isFree = course.price.usd == 0;
    
    return GestureDetector(
      onTap: () => _navigateToCourseDetail(course),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail or placeholder
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                gradient: LinearGradient(
                  colors: [
                    Color((0xFF000000 + (course.title.hashCode * 0x10101) % 0x1000000) | 0xFF000000),
                    Color((0xFF000000 + (course.title.hashCode * 0x10101) % 0x1000000) | 0xFF000000).withAlpha(60),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  if (course.thumbnail != null)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        ApiService.getFullMediaUrl(course.thumbnail!),

                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.fill,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.play_lesson,
                              size: 40,
                              color: Colors.white.withAlpha(80),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Center(
                      child: Icon(
                        Icons.play_lesson,
                        size: 40,
                        color: Colors.white.withAlpha(80),
                      ),
                    ),
                  // Price badge
                  Positioned(
                    bottom: 2,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isFree ? Colors.green : const Color.fromRGBO(244, 135, 6, 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isFree ? 'FREE' : '\$${course.price.usd.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Course info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course.instructor.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.star, size: 14, color: Colors.amber[700]),
                            const SizedBox(width: 2),
                            Text(
                              course.rating.average.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${course.rating.count})',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getLevelColor(course.level).withAlpha(10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            course.level.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getLevelColor(course.level),
                            ),
                          ),
                        ),
                      ],
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

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.blue;
      case 'advanced':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  //

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        if (index == 1 && AppData().isAuthenticated) {
          _fetchEnrolledCourses();
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color.fromRGBO(244, 135, 6, 1) : Colors.grey,
            size: 26,
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

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
          children: [
            Container(
              width: 80,
              height: 80,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(10),
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
            Text(
              _errorMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
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
          ],
        ),
      ),
    );
  }
}