import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:innovator/Innovator/models/Course_models.dart';
import 'package:innovator/Innovator/screens/Course/services/api_services.dart';
import 'package:video_player/video_player.dart';
import 'dart:developer' as developer;
import 'dart:async';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  final Map<String, dynamic>? courseData;

  const CourseDetailScreen({
    Key? key,
    required this.courseId,
    this.courseData,
  }) : super(key: key);

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  VideoPlayerController? _videoController;
  
  Map<String, dynamic>? _courseDetail;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  int? _selectedLessonIndex;
  bool _isVideoInitialized = false;
  bool _isFullScreen = false;
  bool _showControls = true;
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchCourseDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _videoController?.dispose();
    _controlsTimer?.cancel();
    
    // Reset orientation when disposing
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual, 
      overlays: SystemUiOverlay.values
    );
    
    super.dispose();
  }

  Future<void> _fetchCourseDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final response = await ApiService.getCourseDetails(widget.courseId);
      
      if (response['status'] == 200 && response['data'] != null) {
        setState(() {
          _courseDetail = response['data'];
          _isLoading = false;
        });

        // Initialize overview video if available
        final course = _courseDetail!['course'];
        if (course['overviewVideo'] != null && 
            course['overviewVideo'].toString().isNotEmpty) {
          _initializeVideo(course['overviewVideo']);
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to load course details');
      }
    } catch (e) {
      developer.log('Error fetching course details: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _initializeVideo(String videoUrl) {
    try {
      _videoController?.dispose();
      setState(() {
        _isVideoInitialized = false;
      });

      final fullVideoUrl = ApiService.getFullMediaUrl(videoUrl);
      developer.log('Initializing video: $fullVideoUrl');
      
      _videoController = VideoPlayerController.networkUrl(Uri.parse(fullVideoUrl))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isVideoInitialized = true;
            });
            _startControlsTimer();
          }
        }).catchError((error) {
          developer.log('Video initialization error: $error');
        });
        
      _videoController!.addListener(() {
        if (mounted) setState(() {});
      });
      
    } catch (e) {
      developer.log('Video controller error: $e');
    }
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _videoController != null && _videoController!.value.isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });
    _startControlsTimer();
  }

  void _togglePlayPause() {
    if (_videoController != null && _isVideoInitialized) {
      setState(() {
        if (_videoController!.value.isPlaying) {
          _videoController!.pause();
        } else {
          _videoController!.play();
        }
      });
      _showControlsTemporarily();
    }
  }

  void _seekVideo(Duration position) {
    if (_videoController != null && _isVideoInitialized) {
      final newPosition = _videoController!.value.position + position;
      final duration = _videoController!.value.duration;
      
      if (newPosition < Duration.zero) {
        _videoController!.seekTo(Duration.zero);
      } else if (newPosition > duration) {
        _videoController!.seekTo(duration);
      } else {
        _videoController!.seekTo(newPosition);
      }
      _showControlsTemporarily();
    }
  }

  void _toggleFullScreen() async {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
    
    if (_isFullScreen) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual, 
        overlays: SystemUiOverlay.values
      );
    }
    
    _showControlsTemporarily();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullScreen) {
      return _buildFullScreenVideo();
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? _buildLoadingWidget()
          : _hasError
              ? _buildErrorWidget()
              : _buildCourseContent(),
    );
  }

  Widget _buildFullScreenVideo() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isVideoInitialized && _videoController != null
          ? Stack(
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
                _buildFullScreenControls(),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color.fromRGBO(244, 135, 6, 1),
                ),
              ),
            ),
    );
  }

  Widget _buildFullScreenControls() {
    return GestureDetector(
      onTap: _showControlsTemporarily,
      child: Container(
        color: Colors.transparent,
        child: AnimatedOpacity(
          opacity: _showControls ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Stack(
            children: [
              // Top bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withAlpha(70),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: SafeArea(
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _toggleFullScreen,
                          icon: const Icon(Icons.fullscreen_exit, 
                            color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _courseDetail?['course']?['title'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Center controls
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () => _seekVideo(const Duration(seconds: -10)),
                      icon: const Icon(Icons.replay_10, 
                        color: Colors.white, size: 40),
                    ),
                    IconButton(
                      onPressed: _togglePlayPause,
                      icon: Icon(
                        _videoController!.value.isPlaying 
                            ? Icons.pause_circle_filled 
                            : Icons.play_circle_filled,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _seekVideo(const Duration(seconds: 10)),
                      icon: const Icon(Icons.forward_10, 
                        color: Colors.white, size: 40),
                    ),
                  ],
                ),
              ),
              // Bottom progress bar
              if (_videoController != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withAlpha(70),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: SafeArea(
                      child: Column(
                        children: [
                          VideoProgressIndicator(
                            _videoController!,
                            allowScrubbing: true,
                            colors: const VideoProgressColors(
                              playedColor: Color.fromRGBO(244, 135, 6, 1),
                              bufferedColor: Color.fromRGBO(244, 135, 6, 0.3),
                              backgroundColor: Colors.white24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(_videoController!.value.position),
                                style: const TextStyle(color: Colors.white),
                              ),
                              Text(
                                _formatDuration(_videoController!.value.duration),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseContent() {
    final course = _courseDetail!['course'];
    
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 250,
          pinned: true,
          backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
          flexibleSpace: FlexibleSpaceBar(
            background: _buildVideoPlayer(),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          // actions: [
          //   IconButton(
          //     icon: const Icon(Icons.share, color: Colors.white),
          //     onPressed: () {
          //       // Implement share functionality
          //     },
          //   ),
          // ],
        ),
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildCourseInfo(course),
              _buildInstructorInfo(course),
              _buildTabSection(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPlayer() {
    final course = _courseDetail!['course'];
    
    if (course['overviewVideo'] == null || 
        course['overviewVideo'].toString().isEmpty) {
      return Container(
        color: Colors.black87,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library, size: 48, color: Colors.white54),
              SizedBox(height: 8),
              Text(
                'No preview available',
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isVideoInitialized || _videoController == null) {
      return Container(
        color: Colors.black87,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _showControlsTemporarily,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: Colors.black,
            child: Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            ),
          ),
          _buildVideoControls(),
        ],
      ),
    );
  }

  // Replace your _buildVideoControls method with this fixed version:

Widget _buildVideoControls() {
  return AnimatedOpacity(
    opacity: _showControls ? 1.0 : 0.0,
    duration: const Duration(milliseconds: 300),
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withAlpha(30),
            Colors.transparent,
            Colors.black.withAlpha(30),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Center play controls
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => _seekVideo(const Duration(seconds: -10)),
                  icon: const Icon(Icons.replay_10, 
                    color: Colors.white, size: 32),
                ),
                const SizedBox(width: 20),
                IconButton(
                  onPressed: _togglePlayPause,
                  icon: Icon(
                    _videoController!.value.isPlaying 
                        ? Icons.pause_circle_filled 
                        : Icons.play_circle_filled,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(width: 20),
                IconButton(
                  onPressed: () => _seekVideo(const Duration(seconds: 10)),
                  icon: const Icon(Icons.forward_10, 
                    color: Colors.white, size: 32),
                ),
              ],
            ),
          ),
          
          // Bottom controls with progress bar and duration
          if (_videoController != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withAlpha(70),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress bar
                    VideoProgressIndicator(
                      _videoController!,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Color.fromRGBO(244, 135, 6, 1),
                        bufferedColor: Color.fromRGBO(244, 135, 6, 0.3),
                        backgroundColor: Colors.white24,
                      ),
                    ),
                  //  const SizedBox(height: 4),
                    // Duration and fullscreen button row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Current time / total duration
                        Text(
                          '${_formatDuration(_videoController!.value.position)} / ${_formatDuration(_videoController!.value.duration)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        // Fullscreen button
                        IconButton(
                          onPressed: _toggleFullScreen,
                          icon: const Icon(Icons.fullscreen, 
                            color: Colors.white, size: 24),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
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

  // Replace the _buildCourseInfo method in your course_details_screen.dart

Widget _buildCourseInfo(Map<String, dynamic> course) {
  final price = course['price'] ?? {};
  final isFree = (price['usd'] ?? 0) == 0;
  
  return Container(
    padding: const EdgeInsets.all(16),
    color: Colors.white,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          course['title'] ?? '',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          course['description'] ?? '',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        // Fix: Use Wrap instead of Row for responsive layout
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          children: [
            _buildInfoChip(
              Icons.signal_cellular_alt,
              course['level'] ?? 'Beginner',
              Colors.blue,
            ),
            _buildInfoChip(
              Icons.language,
              course['language'] ?? 'English',
              Colors.green,
            ),
            _buildInfoChip(
              Icons.access_time,
              course['duration'] ?? '00:00:00',
              Colors.purple,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isFree ? Colors.green : const Color.fromRGBO(244, 135, 6, 1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isFree ? 'FREE' : '\$${price['usd']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Alternative Fix: Use Column for vertical layout on small screens
        LayoutBuilder(
          builder: (context, constraints) {
            // If screen is narrow, stack elements vertically
            if (constraints.maxWidth < 350) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[700], size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${course['rating']?['average'] ?? 0}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '(${course['rating']?['count'] ?? 0} reviews)',
                          style: TextStyle(color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.people, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${course['enrollmentCount'] ?? 0} enrolled',
                          style: TextStyle(color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            } else {
              // Original horizontal layout for wider screens
              return Row(
                children: [
                  Icon(Icons.star, color: Colors.amber[700], size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${course['rating']?['average'] ?? 0}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '(${course['rating']?['count'] ?? 0} reviews)',
                      style: TextStyle(color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.people, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${course['enrollmentCount'] ?? 0} enrolled',
                      style: TextStyle(color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ],
    ),
  );
}

  Widget _buildInfoChip(IconData icon, String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withAlpha(10),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildInstructorInfo(Map<String, dynamic> course) {
    final instructor = course['instructor'] ?? {};
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color.fromRGBO(244, 135, 6, 0.1),
            child: const Icon(
              Icons.person,
              size: 30,
              color: Color.fromRGBO(244, 135, 6, 1),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Instructor',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  instructor['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (instructor['bio'] != null && instructor['bio'].isNotEmpty)
                  Text(
                    instructor['bio'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    return Container(
      margin: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color.fromRGBO(244, 135, 6, 1),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color.fromRGBO(244, 135, 6, 1),
              indicatorWeight: 3,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_lesson, size: 16),
                      const SizedBox(width: 1),
                      Text('Lessons (${_courseDetail?['lessons']?.length ?? 0})'),
                    ],
                  ),
                ),
                const Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.note, size: 18),
                      SizedBox(width: 4),
                      Text('Notes'),
                    ],
                  ),
                ),
                const Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, size: 18),
                      SizedBox(width: 4),
                      Text('About'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLessonsTab(),
                _buildNotesTab(),
                _buildAboutTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsTab() {
    final lessons = _courseDetail?['lessons'] ?? [];
    
    if (lessons.isEmpty) {
      return const Center(
        child: Text('No lessons available'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lessons.length,
      itemBuilder: (context, index) {
        final lesson = lessons[index];
        final isSelected = _selectedLessonIndex == index;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color.fromRGBO(244, 135, 6, 0.1)
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? const Color.fromRGBO(244, 135, 6, 1)
                  : Colors.grey.shade200,
            ),
          ),
          child: ListTile(
            onTap: () {
              setState(() {
                _selectedLessonIndex = isSelected ? null : index;
              });
              
              // Play first video of the lesson if available
              final videos = lesson['videos'] ?? [];
              if (videos.isNotEmpty) {
                _initializeVideo(videos[0]['videoUrl']);
              }
            },
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color.fromRGBO(244, 135, 6, 1)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${lesson['sortOrder'] ?? index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
            ),
            title: Text(
              lesson['title'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  lesson['description'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      lesson['duration'] ?? '00:00',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.video_library, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${(lesson['videos'] ?? []).length} videos',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            // trailing: Icon(
            //   isSelected ? Icons.expand_less : Icons.expand_more,
            //   color: isSelected 
            //       ? const Color.fromRGBO(244, 135, 6, 1)
            //       : Colors.grey,
            // ),
          ),
        );
      },
    );
  }

  Widget _buildNotesTab() {
    final allNotes = [];
    final lessons = _courseDetail?['lessons'] ?? [];
    
    for (var lesson in lessons) {
      allNotes.addAll(lesson['notes'] ?? []);
    }
    
    if (allNotes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_alt_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No notes available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allNotes.length,
      itemBuilder: (context, index) {
        final note = allNotes[index];
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(244, 135, 6, 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.picture_as_pdf,
                  color: Color.fromRGBO(244, 135, 6, 1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note['title'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      note['description'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAboutTab() {
    final course = _courseDetail?['course'] ?? {};
    final prerequisites = List<String>.from(course['prerequisites'] ?? []);
    final learningOutcomes = List<String>.from(course['learningOutcomes'] ?? []);
    final targetAudience = List<String>.from(course['targetAudience'] ?? []);
    final tags = List<String>.from(course['tags'] ?? []);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (prerequisites.isNotEmpty) ...[
            const Text(
              'Prerequisites',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...prerequisites.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 20,
                    color: Color.fromRGBO(244, 135, 6, 1),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
            const SizedBox(height: 20),
          ],
          
          if (learningOutcomes.isNotEmpty) ...[
            const Text(
              'What You\'ll Learn',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...learningOutcomes.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.star,
                    size: 20,
                    color: Color.fromRGBO(244, 135, 6, 1),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
            const SizedBox(height: 20),
          ],
          
          if (targetAudience.isNotEmpty) ...[
            const Text(
              'Target Audience',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...targetAudience.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.people,
                    size: 20,
                    color: Color.fromRGBO(244, 135, 6, 1),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
            const SizedBox(height: 20),
          ],
          
          if (tags.isNotEmpty) ...[
            const Text(
              'Topics Covered',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(244, 135, 6, 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color.fromRGBO(244, 135, 6, 0.3),
                  ),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color.fromRGBO(244, 135, 6, 1),
                  ),
                ),
              )).toList(),
            ),
          ],
          
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(244, 135, 6, 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color.fromRGBO(244, 135, 6, 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color.fromRGBO(244, 135, 6, 1),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Course Settings',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      (course['settings']?['allowDownloads'] ?? false) 
                          ? Icons.check_circle 
                          : Icons.cancel,
                      size: 18,
                      color: (course['settings']?['allowDownloads'] ?? false)
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    const Text('Downloads allowed'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      (course['settings']?['certificateEnabled'] ?? false)
                          ? Icons.check_circle
                          : Icons.cancel,
                      size: 18,
                      color: (course['settings']?['certificateEnabled'] ?? false)
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    const Text('Certificate available'),
                  ],
                ),
              ],
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
            'Loading course details...',
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
              'Failed to load course',
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
              onPressed: _fetchCourseDetails,
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