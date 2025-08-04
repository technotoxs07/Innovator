// course_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for SystemChrome
import 'package:innovator/App_data/App_data.dart';
import 'package:innovator/screens/Course/models/api_models.dart';
import 'package:innovator/screens/Course/services/api_services.dart';
import 'package:innovator/screens/Course/notes_tab.dart';
import 'package:video_player/video_player.dart';
import 'dart:developer' as developer;
import 'dart:async';

// Add your custom video progress bar widget
class FixedCustomVideoProgressBar extends StatefulWidget {
  final VideoPlayerController controller;
  final VoidCallback? onSeekStart;
  final VoidCallback? onSeekEnd;
  final Color playedColor;
  final Color bufferedColor;
  final Color backgroundColor;
  final Color handleColor;
  final double barHeight;
  final double handleRadius;
  final bool allowScrubbing;

  const FixedCustomVideoProgressBar({
    Key? key,
    required this.controller,
    this.onSeekStart,
    this.onSeekEnd,
    this.playedColor = const Color.fromRGBO(244, 135, 6, 1),
    this.bufferedColor = Colors.grey,
    this.backgroundColor = Colors.white24,
    this.handleColor = Colors.white,
    this.barHeight = 4.0,
    this.handleRadius = 8.0,
    this.allowScrubbing = true,
  }) : super(key: key);

  @override
  State<FixedCustomVideoProgressBar> createState() => _FixedCustomVideoProgressBarState();
}

class _FixedCustomVideoProgressBarState extends State<FixedCustomVideoProgressBar>
    with SingleTickerProviderStateMixin {
  bool _isDragging = false;
  bool _isHovering = false;
  double? _dragValue;
  late AnimationController _animationController;
  late Animation<double> _handleAnimation;
  late Animation<double> _barAnimation;
  
  // Add these for proper progress tracking
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupVideoListener();
    _startProgressTimer();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _handleAnimation = Tween<double>(
      begin: widget.handleRadius,
      end: widget.handleRadius * 1.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _barAnimation = Tween<double>(
      begin: widget.barHeight,
      end: widget.barHeight * 1.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _setupVideoListener() {
    widget.controller.addListener(_updateVideoState);
    
    // Get initial duration if video is already initialized
    if (widget.controller.value.isInitialized) {
      _totalDuration = widget.controller.value.duration;
      _currentPosition = widget.controller.value.position;
    }
  }

  void _startProgressTimer() {
    // Timer to update progress every 100ms for smooth updates
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (widget.controller.value.isInitialized && !_isDragging) {
        _updateVideoState();
      }
    });
  }

  void _updateVideoState() {
    if (mounted && widget.controller.value.isInitialized) {
      final newPosition = widget.controller.value.position;
      final newDuration = widget.controller.value.duration;
      
      if (newPosition != _currentPosition || newDuration != _totalDuration) {
        setState(() {
          _currentPosition = newPosition;
          _totalDuration = newDuration;
        });
      }
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    widget.controller.removeListener(_updateVideoState);
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details, double width) {
    if (!widget.allowScrubbing) return;
    
    setState(() {
      _isDragging = true;
    });
    
    _animationController.forward();
    widget.onSeekStart?.call();
    
    final position = details.localPosition.dx / width;
    _seekToPosition(position.clamp(0.0, 1.0));
  }

  void _onPanUpdate(DragUpdateDetails details, double width) {
    if (!widget.allowScrubbing || !_isDragging) return;
    
    final position = details.localPosition.dx / width;
    _seekToPosition(position.clamp(0.0, 1.0));
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.allowScrubbing) return;
    
    setState(() {
      _isDragging = false;
      _dragValue = null;
    });
    
    _animationController.reverse();
    widget.onSeekEnd?.call();
  }

  void _seekToPosition(double position) {
    if (_totalDuration == Duration.zero) return;

    final newPosition = _totalDuration * position;
    setState(() {
      _dragValue = position;
      _currentPosition = newPosition; // Update immediately for responsive UI
    });
    
    widget.controller.seekTo(newPosition);
  }

  double _getProgressValue() {
    if (_isDragging && _dragValue != null) {
      return _dragValue!;
    }
    
    if (_totalDuration == Duration.zero) return 0.0;
    return (_currentPosition.inMilliseconds / _totalDuration.inMilliseconds).clamp(0.0, 1.0);
  }

  double _getBufferedValue() {
    final buffered = widget.controller.value.buffered;
    
    if (_totalDuration == Duration.zero || buffered.isEmpty) return 0.0;
    
    final bufferedEnd = buffered.last.end;
    return (bufferedEnd.inMilliseconds / _totalDuration.inMilliseconds).clamp(0.0, 1.0);
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
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovering = true;
        });
        _animationController.forward();
      },
      onExit: (_) {
        setState(() {
          _isHovering = false;
        });
        if (!_isDragging) {
          _animationController.reverse();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            SizedBox(
              height: 30,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final progressValue = _getProgressValue();
                  final bufferedValue = _getBufferedValue();

                  return GestureDetector(
                    onPanStart: (details) => _onPanStart(details, width),
                    onPanUpdate: (details) => _onPanUpdate(details, width),
                    onPanEnd: _onPanEnd,
                    onTapDown: widget.allowScrubbing
                        ? (details) {
                            final position = details.localPosition.dx / width;
                            _seekToPosition(position.clamp(0.0, 1.0));
                          }
                        : null,
                    child: Container(
                      width: width,
                      height: 30,
                      color: Colors.transparent,
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _barAnimation,
                          builder: (context, child) {
                            return Stack(
                              children: [
                                // Background bar
                                Container(
                                  height: _barAnimation.value,
                                  decoration: BoxDecoration(
                                    color: widget.backgroundColor,
                                    borderRadius: BorderRadius.circular(_barAnimation.value / 2),
                                  ),
                                ),
                                // Buffered bar
                                FractionallySizedBox(
                                  widthFactor: bufferedValue,
                                  child: Container(
                                    height: _barAnimation.value,
                                    decoration: BoxDecoration(
                                      color: widget.bufferedColor.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(_barAnimation.value / 2),
                                    ),
                                  ),
                                ),
                                // Played bar
                                AnimatedContainer(
                                  duration: _isDragging 
                                      ? Duration.zero 
                                      : const Duration(milliseconds: 100),
                                  curve: Curves.easeOut,
                                  width: width * progressValue,
                                  height: _barAnimation.value,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        widget.playedColor,
                                        widget.playedColor.withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(_barAnimation.value / 2),
                                    boxShadow: _isDragging || _isHovering
                                        ? [
                                            BoxShadow(
                                              color: widget.playedColor.withOpacity(0.3),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                                // Handle
                                if (_isDragging || _isHovering || widget.allowScrubbing)
                                  Positioned(
                                    left: (width * progressValue) - widget.handleRadius,
                                    top: (_barAnimation.value - (widget.handleRadius * 2)) / 2,
                                    child: AnimatedBuilder(
                                      animation: _handleAnimation,
                                      builder: (context, child) {
                                        return Container(
                                          width: _handleAnimation.value * 2,
                                          height: _handleAnimation.value * 2,
                                          decoration: BoxDecoration(
                                            color: widget.handleColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: widget.playedColor,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.3),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Time display
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_currentPosition),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDuration(_totalDuration),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CourseDetailScreen extends StatefulWidget {
  final Course course;

  const CourseDetailScreen({
    Key? key,
    required this.course,
  }) : super(key: key);

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  VideoPlayerController? _videoController;
  
  CourseDetailData? _courseDetailData;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  Lesson? _selectedLesson;
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
    
    // Reset orientation and system UI when disposing
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    
    super.dispose();
  }

  Future<void> _fetchCourseDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Check if user is authenticated before making API call
      final appData = AppData();
      if (!appData.isAuthenticated || appData.authToken == null) {
        throw Exception('Please login to access course details');
      }

      final response = await ApiService.getCourseDetails(widget.course.id);
      
      developer.log('Raw API Response: ${response.toString()}');
      
      if (response['status'] == 200 && response['data'] != null) {
        try {
          final courseDetailResponse = CourseDetailResponse.fromJson(response);
          
          setState(() {
            _courseDetailData = courseDetailResponse.data;
            _selectedLesson = courseDetailResponse.data.selectedLesson ?? 
                            (courseDetailResponse.data.lessons.isNotEmpty 
                              ? courseDetailResponse.data.lessons.first 
                              : null);
            _isLoading = false;
          });

          // Initialize overview video if available
          if (widget.course.overviewVideo != null && widget.course.overviewVideo!.isNotEmpty) {
            developer.log('Initializing overview video: ${widget.course.overviewVideo}');
            _initializeVideo(widget.course.overviewVideo!);
          } else {
            developer.log('No overview video available for this course');
          }

        } catch (parseError) {
          developer.log('JSON parsing error: $parseError');
          throw Exception('Failed to parse course details: $parseError');
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
      
      // Show authentication error specifically
      if (e.toString().contains('Authentication required') || 
          e.toString().contains('Please login')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please login to access this course'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Login',
                textColor: Colors.white,
                onPressed: () {
                  // Navigate to login screen
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

  void _initializeVideo(String videoUrl) {
    try {
      // Dispose of previous controller if exists
      _videoController?.dispose();
      setState(() {
        _isVideoInitialized = false;
      });

      final fullVideoUrl = ApiService.getFullMediaUrl(videoUrl);
      developer.log('Full video URL: $fullVideoUrl');
      
      _videoController = VideoPlayerController.networkUrl(Uri.parse(fullVideoUrl))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isVideoInitialized = true;
            });
            developer.log('Video initialized successfully');
            _startControlsTimer();
          }
        }).catchError((error) {
          developer.log('Video initialization error: $error');
          if (mounted) {
            setState(() {
              _isVideoInitialized = false;
              _hasError = true;
              _errorMessage = 'Failed to load video: $error';
            });
          }
        });
        
      // Add listener for video state changes
      _videoController!.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
      
    } catch (e) {
      developer.log('Video controller creation error: $e');
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
          _hasError = true;
          _errorMessage = 'Failed to create video player: $e';
        });
      }
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
      // Entering fullscreen - set landscape and hide system UI
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      // Exiting fullscreen - allow all orientations and show system UI
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    }
    
    _showControlsTemporarily();
  }

  Widget _buildVideoControls() {
    return Stack(
      children: [
        // Double Tap Areas for Seek
        Positioned.fill(
          child: Row(
            children: [
              // Left side - Seek backward 10s
              Expanded(
                child: GestureDetector(
                  onDoubleTap: () => _seekVideo(const Duration(seconds: -10)),
                  onTap: _showControlsTemporarily,
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
              // Right side - Seek forward 10s
              Expanded(
                child: GestureDetector(
                  onDoubleTap: () => _seekVideo(const Duration(seconds: 10)),
                  onTap: _showControlsTemporarily,
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Center Play/Pause Button
        if (_showControls)
          Center(
            child: GestureDetector(
              onTap: _togglePlayPause,
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _videoController!.value.isPlaying 
                        ? Icons.pause 
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        // Fullscreen button (bottom right) - only in portrait mode
        if (_showControls && !_isFullScreen)
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: _toggleFullScreen,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fullscreen,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFullscreenVideoControls() {
    return Stack(
      children: [
        // Double Tap Areas for Seek
        Positioned.fill(
          child: Row(
            children: [
              // Left side - Seek backward 10s
              Expanded(
                child: GestureDetector(
                  onDoubleTap: () => _seekVideo(const Duration(seconds: -10)),
                  onTap: _showControlsTemporarily,
                  child: Container(
                    color: Colors.transparent,
                    child: _showControls
                        ? Center(
                            child: AnimatedOpacity(
                              opacity: 0.7,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.replay_10,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              // Right side - Seek forward 10s
              Expanded(
                child: GestureDetector(
                  onDoubleTap: () => _seekVideo(const Duration(seconds: 10)),
                  onTap: _showControlsTemporarily,
                  child: Container(
                    color: Colors.transparent,
                    child: _showControls
                        ? Center(
                            child: AnimatedOpacity(
                              opacity: 0.7,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.forward_10,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Center Play/Pause Button
        if (_showControls)
          Center(
            child: GestureDetector(
              onTap: _togglePlayPause,
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _videoController != null && _videoController!.value.isPlaying 
                        ? Icons.pause 
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        // Top Controls (Title and Close for fullscreen)
        if (_showControls && _isFullScreen)
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
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _toggleFullScreen,
                      icon: const Icon(Icons.fullscreen_exit, color: Colors.white, size: 28),
                    ),
                    Expanded(
                      child: Text(
                        widget.course.title,
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
        // Bottom Progress Bar in Fullscreen
        if (_showControls && _isFullScreen && _videoController != null)
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
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: FixedCustomVideoProgressBar(
                  controller: _videoController!,
                  playedColor: const Color.fromRGBO(244, 135, 6, 1),
                  bufferedColor: Colors.grey,
                  backgroundColor: Colors.white24,
                  handleColor: Colors.white,
                  barHeight: 4.0,
                  handleRadius: 8.0,
                  allowScrubbing: true,
                ),
              ),
            ),
          ),
        // Bottom Controls (Fullscreen button)
        if (_showControls && !_isFullScreen)
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: _toggleFullScreen,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fullscreen,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _selectLesson(Lesson lesson) {
    setState(() {
      _selectedLesson = lesson;
    });
    
    // Play the first video of the selected lesson if available
    if (lesson.videos.isNotEmpty) {
      final firstVideo = lesson.videos.first;
      developer.log('Playing lesson video: ${firstVideo.videoUrl}');
      _initializeVideo(firstVideo.videoUrl);
    }
    
    // Optionally fetch lesson-specific details
    _fetchLessonDetails(lesson.id);
  }

  Future<void> _fetchLessonDetails(String lessonId) async {
    try {
      final response = await ApiService.getCourseDetails(widget.course.id, lessonId: lessonId);
      
      if (response['status'] == 200 && response['data'] != null) {
        final courseDetailResponse = CourseDetailResponse.fromJson(response);
        
        setState(() {
          _courseDetailData = courseDetailResponse.data;
        });
      }
    } catch (e) {
      developer.log('Error fetching lesson details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // If in fullscreen mode, show only the video player (landscape)
    if (_isFullScreen) {
      return WillPopScope(
        onWillPop: () async {
          // Handle back button press in fullscreen
          _toggleFullScreen();
          return false;
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: _isVideoInitialized && _videoController != null
              ? Stack(
                  children: [
                    // Full screen video player
                    Positioned.fill(
                      child: Container(
                        color: Colors.black,
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio > 0 
                                ? _videoController!.value.aspectRatio 
                                : 16/9,
                            child: VideoPlayer(_videoController!),
                          ),
                        ),
                      ),
                    ),
                    // Fullscreen video controls
                    _buildFullscreenVideoControls(),
                  ],
                )
              : const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color.fromRGBO(244, 135, 6, 1),
                    ),
                  ),
                ),
        ),
      );
    }

    // Normal portrait mode - video at top, content below
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? _buildLoadingWidget()
          : _hasError
              ? _buildErrorWidget()
              : CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _buildOverviewVideo(),
                          _buildCourseInfo(),
                          _buildTabBarSection(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 60,
      floating: false,
      pinned: true,
      backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
      iconTheme: const IconThemeData(color: Colors.white),
      title: Text(
        widget.course.title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildOverviewVideo() {
    if (widget.course.overviewVideo == null || widget.course.overviewVideo!.isEmpty) {
      return Container(
        height: 220,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'No overview video available',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return _isVideoInitialized && _videoController != null
        ? Column(
            children: [
              // Video Player Container with proper aspect ratio handling
              _buildVideoPlayerContainer(),
              // Custom Progress Bar (only show in portrait mode)
              if (!_isFullScreen)
                Container(
                  color: Colors.black,
                  child: FixedCustomVideoProgressBar(
                    controller: _videoController!,
                    playedColor: const Color.fromRGBO(244, 135, 6, 1),
                    bufferedColor: Colors.grey,
                    backgroundColor: Colors.white24,
                    handleColor: Colors.white,
                    barHeight: 4.0,
                    handleRadius: 8.0,
                    allowScrubbing: true,
                    onSeekStart: () {
                      developer.log('Seek started');
                    },
                    onSeekEnd: () {
                      developer.log('Seek ended');
                    },
                  ),
                ),
            ],
          )
        : _buildVideoLoadingContainer();
  }

  Widget _buildVideoPlayerContainer() {
    // Get the actual video dimensions
    final videoValue = _videoController!.value;
    final videoAspectRatio = videoValue.aspectRatio;
    
    // Get full screen width
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Determine the best aspect ratio to use
    double containerAspectRatio;
    
    if (videoAspectRatio > 0) {
      // Use video's natural aspect ratio, but constrain it
      if (videoAspectRatio > 2.0) {
        // Very wide video, cap at 2:1
        containerAspectRatio = 2.0;
      } else if (videoAspectRatio < 1.2) {
        // Very tall video, use 4:3 minimum
        containerAspectRatio = 16/9;
      } else {
        // Use natural aspect ratio
        containerAspectRatio = videoAspectRatio;
      }
    } else {
      // Default to 16:9 if we can't determine video aspect ratio
      containerAspectRatio = 16/9;
    }

    return SizedBox(
      width: screenWidth,
      child: AspectRatio(
        aspectRatio: containerAspectRatio,
        child: Stack(
          children: [
            // Video Player positioned to fill container properly
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: videoAspectRatio > 0 ? videoAspectRatio : 16/9,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
              ),
            ),
            // Video Controls Overlay
            _buildVideoControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoLoadingContainer() {
    return SizedBox(
      width: double.infinity,
      child: AspectRatio(
        aspectRatio: 16 / 9, // Default aspect ratio for loading state
        child: Container(
          color: Colors.grey[800],
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Color.fromRGBO(244, 135, 6, 1),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.course.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.course.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // Use Wrap instead of Row to prevent overflow
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                Icons.school,
                '${widget.course.contentStatistics?.totalLessons ?? 0} Lessons',
              ),
              _buildInfoChip(
                Icons.note,
                '${widget.course.contentStatistics?.totalPDFs ?? 0} Notes',
              ),
              _buildInfoChip(
                Icons.video_library,
                '${widget.course.contentStatistics?.totalVideos ?? 0} Videos',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(244, 135, 6, 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.course.level.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(244, 135, 6, 1),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.course.language,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const Spacer(),
              if (widget.course.price.usd == 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'FREE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                Text(
                  '\$${widget.course.price.usd}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(244, 135, 6, 1),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBarSection() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
            border: Border.all(
              color: Colors.grey.withOpacity(0.1),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(6),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color.fromRGBO(244, 135, 6, 1),
                  Color.fromRGBO(255, 165, 40, 1),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(244, 135, 6, 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[600],
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              letterSpacing: 0.3,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              letterSpacing: 0.2,
            ),
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            dividerColor: Colors.transparent,
            tabs: [
              Tab(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_lesson, size: 16),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Lessons',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Tab(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sticky_note_2, size: 16),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Notes',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Tab(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, size: 16),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'About',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
            border: Border.all(
              color: Colors.grey.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLessonsTab(),
                _buildNotesTab(),
                _buildAboutTab(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLessonsTab() {
    if (_courseDetailData == null || _courseDetailData!.lessons.isEmpty) {
      return const Center(
        child: Text(
          'No lessons available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _courseDetailData!.lessons.length,
      itemBuilder: (context, index) {
        final lesson = _courseDetailData!.lessons[index];
        final isSelected = _selectedLesson?.id == lesson.id;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color.fromRGBO(244, 135, 6, 0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: isSelected 
                ? Border.all(color: const Color.fromRGBO(244, 135, 6, 1))
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color.fromRGBO(244, 135, 6, 1)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${lesson.sortOrder}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
            ),
            title: Text(
              lesson.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected 
                    ? const Color.fromRGBO(244, 135, 6, 1)
                    : Colors.black87,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(lesson.description),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _buildLessonInfoItem(Icons.schedule, lesson.duration),
                    _buildLessonInfoItem(Icons.note, '${lesson.notes.length} notes'),
                    _buildLessonInfoItem(Icons.video_library, '${lesson.videos.length} videos'),
                  ],
                ),
              ],
            ),
            trailing: Icon(
              isSelected ? Icons.expand_less : Icons.expand_more,
              color: isSelected 
                  ? const Color.fromRGBO(244, 135, 6, 1)
                  : Colors.grey[400],
            ),
            onTap: () => _selectLesson(lesson),
          ),
        );
      },
    );
  }

  Widget _buildLessonInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesTab() {
    List<Note> allNotes = [];
    
    if (_courseDetailData != null) {
      // Collect all notes from all lessons
      for (var lesson in _courseDetailData!.lessons) {
        allNotes.addAll(lesson.notes);
      }
    }

    return NotesTab(
      courseId: widget.course.id,
      notes: allNotes,
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAboutSection('Description', widget.course.description),
          const SizedBox(height: 20),
          _buildAboutSection('Instructor', widget.course.instructor.name),
          if (widget.course.instructor.bio.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.course.instructor.bio,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
          const SizedBox(height: 20),
          _buildAboutSection('Prerequisites', ''),
          const SizedBox(height: 8),
          ...widget.course.prerequisites.map((prerequisite) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      prerequisite,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).toList(),
          const SizedBox(height: 20),
          _buildAboutSection('Learning Outcomes', ''),
          const SizedBox(height: 8),
          ...widget.course.learningOutcomes.map((outcome) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      outcome,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).toList(),
          const SizedBox(height: 20),
          _buildAboutSection('Target Audience', ''),
          const SizedBox(height: 8),
          ...widget.course.targetAudience.map((audience) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      audience,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).toList(),
          const SizedBox(height: 20),
          _buildAboutSection('Tags', ''),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.course.tags.map((tag) => 
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(244, 135, 6, 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color.fromRGBO(244, 135, 6, 1),
                  ),
                ),
              ),
            ).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        if (content.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ],
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
              'Failed to load course details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
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