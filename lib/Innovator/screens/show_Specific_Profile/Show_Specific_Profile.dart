import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/Authorization/Login.dart';
import 'package:innovator/Innovator/controllers/user_controller.dart';
import 'package:innovator/Innovator/screens/Feed/Inner_Homepage.dart';
import 'package:innovator/Innovator/screens/Follow/follow_Button.dart';
import 'package:flutter/services.dart';
import 'package:innovator/Innovator/screens/chatApp/controller/chat_controller.dart';
import 'package:innovator/Innovator/screens/comment/comment_screen.dart';
import 'package:innovator/Innovator/screens/show_Specific_Profile/show_Specific_followers.dart';
import 'package:innovator/Innovator/widget/FloatingMenuwidget.dart';

import '../../controllers/State_Management_Profile.dart';
import '../../models/Feed_Content_Model.dart';

class SpecificUserProfilePage extends StatefulWidget {
  final String userId;
  final String? scrollToPostId;
  final bool? openComments;
  final String? highlightCommentId;

  const SpecificUserProfilePage({
    Key? key, 
    required this.userId, 
    this.scrollToPostId, 
    this.openComments, 
    this.highlightCommentId
  }) : super(key: key);

  @override
  _SpecificUserProfilePageState createState() => _SpecificUserProfilePageState();
}

late Size mq;

class _SpecificUserProfilePageState extends State<SpecificUserProfilePage>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final UserController _userController = UserController.to;
  late Future<Map<String, dynamic>> _profileFuture;
  final AppData _appData = AppData();
  bool _isRefreshing = false;
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<FeedContent> _contents = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _lastId;
  bool _hasError = false;
  String _errorMessage = '';
  bool _hasMoreData = true;
  static const _loadTriggerThreshold = 500.0;
  bool isExpanded = false;

  // Privacy check methods
  bool _isPrivateAccount(Map<String, dynamic> profileData) {
    return profileData['isPrivate'] == true || profileData['privateAccount'] == true;
  }

  bool _isFollowing(Map<String, dynamic> profileData) {
    return profileData['followed'] == true || profileData['isFollowing'] == true;
  }

  bool _isCurrentUser(Map<String, dynamic> profileData) {
    return widget.userId == _appData.currentUserId || 
           profileData['email'] == _appData.currentUserEmail;
  }

  bool _canViewPrivateContent(Map<String, dynamic> profileData) {
    return _isCurrentUser(profileData) || 
           _isFollowing(profileData) || 
           !_isPrivateAccount(profileData);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _profileFuture = _fetchUserProfile();
    _animationController.forward();
    _initializeFeed();
    _scrollController.addListener(_scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollToPostId != null && _contents.isNotEmpty) {
        _scrollToPost(widget.scrollToPostId!);
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    mq = MediaQuery.of(context).size;
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDarkMode ? const Color(0xFF0A0A0A) : Colors.white,
      extendBodyBehindAppBar: true,

      appBar: AppBar(
     backgroundColor: Colors.transparent,
        // backgroundColor:   Color.fromRGBO(244, 135, 6, 1),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              isDarkMode ? Brightness.light : Brightness.dark,
        ),
        leading: IconButton(
          iconSize: 25,
          icon: Icon(           
            Icons.arrow_back_ios_new,
            color: isDarkMode ? Colors.white : Colors.black,
            // size: 18,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await _refreshProfile();
              await _refreshFeed();
            },
            color: Theme.of(context).primaryColor,
            child: FutureBuilder<Map<String, dynamic>>(
              future: _profileFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !_isRefreshing) {
                  return _buildLoadingView();
                } else if (snapshot.hasError) {
                  return _buildErrorView(snapshot.error.toString());
                } else if (!snapshot.hasData) {
                  return const Center(child: Text('No profile data available'));
                }

                final profileData = snapshot.data!;
                final canViewPrivateContent = _canViewPrivateContent(profileData);

                return AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return FadeTransition(
                    
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: CustomScrollView(
                          
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          slivers: [

                            SliverToBoxAdapter(
                        
                              child: _buildProfileHeader(profileData, context),
                            ),
                            
                            // Show limited info for private accounts
                            if (canViewPrivateContent) ...[
                              SliverToBoxAdapter(
                                child: _buildProfileInfo(profileData, context),
                              ),
                            
                     
                              SliverToBoxAdapter(
                                child: _buildPersonalInfo(profileData, context),
                              ),

                              const SliverToBoxAdapter(
                                child: SizedBox(height: 30),
                              ),
                                          SliverToBoxAdapter(
                                child: 
                                                       Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                         children: [
                                                              Divider(),
                                                           Padding(
                                                                padding: EdgeInsets.only(right: 10,left: 10),
                                                             child: Text('Posts',style: TextStyle(
                                                              fontSize: 20,
                                                                                           fontWeight: FontWeight.bold
                                                                                         ),),
                                                           ),
                                                                                       Divider()
                                                         ],
                                                       ),
                              ),

                              SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    if (index == _contents.length) {
                                      return _buildLoadingIndicator();
                                    }
                                    return _buildContentItem(index);
                                  },
                                  childCount: _contents.length + (_hasMoreData ? 1 : 0),
                                ),
                              ),
                            ] else ...[
                              // Private account view for non-followers
                              SliverToBoxAdapter(
                                child: _buildPrivateAccountView(profileData, context),
                              ),
                            ],
                            
                            if (_hasError && canViewPrivateContent)
                              SliverFillRemaining(child: _buildFeedErrorView()),
                            if (_contents.isEmpty && !_isLoading && !_hasError && canViewPrivateContent)
                              SliverFillRemaining(child: _buildEmptyFeedView()),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 100),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          FloatingMenuWidget(),
        ],
      ),
    );
  }

  Widget _buildPrivateAccountView(Map<String, dynamic> profileData, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withAlpha(30) 
                : Colors.grey.withAlpha(10),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Private account icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor.withAlpha(10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline,
              size: 60,
              color: primaryColor,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Title
          Text(
            'This Account is Private',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          // Description
          Text(
            'Follow ${profileData['name'] ?? 'this user'} to see their photos, videos and activity.',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          

          
          // Limited stats for private accounts
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? Colors.grey[800]?.withAlpha(30) 
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPrivateStatItem(
                  '${profileData['followers']?.toString() ?? '0'}',
                  'Followers',
                  Icons.people_outline,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                ),
                _buildPrivateStatItem(
                  '${profileData['followings']?.toString() ?? '0'}',
                  'Following',
                  Icons.person_add_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivateStatItem(String count, String label, IconData icon) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> profileData, BuildContext context) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final primaryColor = Theme.of(context).primaryColor;
  final headerHeight = MediaQuery.of(context).size.height * 0.55;
  final isCurrentUser = _isCurrentUser(profileData);
  final canViewPrivateContent = _canViewPrivateContent(profileData);

  // Cache user data in UserController immediately
  if (!isCurrentUser) {
    _userController.cacheUserProfilePicture(
      widget.userId,
      profileData['picture'],
      profileData['name'],
    );
  }

  
      // Animated background elements
      // ...List.generate(6, (index) => _buildFloatingElement(index)),
  
      // Main content
  return    SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

// crossAxisAlignment: CrossAxisAlignment.start,         
   children: [
              // Profile picture with verification badge using InstantProfilePicture
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      primaryColor,
                      primaryColor.withAlpha(70),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withAlpha(30),
                      blurRadius: 20,
                      spreadRadius: 5,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: InstantProfilePicture(
                  userId: widget.userId,
                  radius: 70,
                  profileData: profileData,
                  fallbackName: profileData['name'],
                  cacheIfMissing: true,
                  showBorder: false,
                ),
              ),
              if (profileData['isVerified'] == true)
                Positioned(
                  bottom: 1,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              // Private account indicator
              if (_isPrivateAccount(profileData) && !canViewPrivateContent)
                Positioned(
                  bottom: 1,
                  left: 5,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
  
              // Name with greeting
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    profileData['name'] ?? 'No name',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,

                      color: isDarkMode ? Colors.white : Colors.black,
    
                    ),
                  ),
                  const SizedBox(width: 16),
                            Container(

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withAlpha(30),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FollowButton(
              targetUserEmail: profileData['email'],
              initialFollowStatus: profileData['followed'] ?? false,
              onFollowSuccess: () => _refreshProfile(),
              onUnfollowSuccess: () => _refreshProfile(),
            ),
          ),
                
                ],
              ),
  
              const SizedBox(height: 16),
  
              // Level and Status Row - show for everyone
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLevelBadge(profileData['level']),
 
SizedBox(width: 30),
        TextButton.icon(onPressed: (){
          _navigateToChat(profileData);
        }, label:  Text('Message', style: TextStyle(color: Theme.of(context).primaryColor)), icon:  Icon(Icons.message_outlined,color: Theme.of(context).primaryColor),)
                ],
              ),
 
  
       SizedBox(
  height: (profileData['bio'] != null && profileData['bio'].isNotEmpty) ? 2 :12,
),
  
              // Bio preview - only show if not private or if user can view
              if ((profileData['bio'] != null && profileData['bio'].isNotEmpty) && 
                  canViewPrivateContent)
                Text(
                  profileData['bio'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      );

}

  
  Future<Map<String, dynamic>> _fetchUserProfile() async {
  try {
    final response = await http.get(
      Uri.parse('http://182.93.94.210:3067/api/v1/stalk-profile/${widget.userId}'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'authorization': 'Bearer ${_appData.authToken}',
      },
    );

    if (response.statusCode == 200) {
      final profileData = json.decode(response.body)['data'];
      
      // Cache user data in UserController immediately after fetching
      if (profileData['_id'] != _appData.currentUserId) {
        _userController.cacheUserProfilePicture(
          profileData['_id'] ?? widget.userId,
          profileData['picture'],
          profileData['name'],
        );
        
        // Preload the image
        final imageUrl = _userController.getOtherUserFullProfilePicturePath(
          profileData['_id'] ?? widget.userId
        );
        if (imageUrl != null && mounted) {
          _userController.preloadVisibleUsers([profileData['_id'] ?? widget.userId], context);
        }
      }
      
      return profileData;
    } else {
      throw Exception('Failed to load profile: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching profile: $e');
  }
}


  void _scrollToPost(String postId) {
    final index = _contents.indexWhere((content) => content.id == postId);
    if (index != -1 && _scrollController.hasClients) {
      final position = _scrollController.position;
      final itemExtent = 500.0;
      final targetOffset = index * itemExtent;
      
      _scrollController.animateTo(
        targetOffset.clamp(0.0, position.maxScrollExtent),
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      if (widget.openComments == true) {
        Future.delayed(Duration(milliseconds: 600), () {
          _openCommentsForPost(postId, widget.highlightCommentId);
        });
      }
    }
  }

  void _openCommentsForPost(String postId, String? highlightCommentId) {
    final post = _contents.firstWhere(
      (content) => content.id == postId,
    );
    
    if (post != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommentScreen(
            postId: postId,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeFeed() {
    _loadMoreContent();
  }

  void _scrollListener() {
    if (!_isLoading &&
        _hasMoreData &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent -
                _loadTriggerThreshold) {
      _loadMoreContent();
    }
  }

  Future<void> _loadMoreContent() async {
    if (_isLoading || !_hasMoreData) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final String? authToken = _appData.authToken;
      if (authToken == null || authToken.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Authentication required. Please login.';
        });
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
          (route) => false,
        );
        return;
      }

      final url = _lastId == null
          ? 'http://182.93.94.210:3067/api/v1/getUserContent/${widget.userId}?page=0'
          : 'http://182.93.94.210:3067/api/v1/getUserContent/${widget.userId}?page=${(_contents.length / 10).ceil()}';

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'authorization': 'Bearer $authToken',
            },
          )
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 200 && data['data'] != null) {
          final List<dynamic> contentList = data['data']['contents'] ?? [];
          final List<FeedContent> newContents =
              contentList.map((item) => FeedContent.fromJson(item)).toList();
          final pagination = data['data']['pagination'];

          setState(() {
            _contents.addAll(newContents);
            _lastId = newContents.isNotEmpty ? newContents.last.id : _lastId;
            _hasMoreData = pagination['hasMore'] ?? false;
          });
        } else {
          setState(() {
            _hasError = true;
            _errorMessage = 'Invalid response from server.';
          });
        }
      } else if (response.statusCode == 401) {
        await _handleUnauthorizedError();
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleUnauthorizedError() async {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }

  Future<void> _refreshFeed() async {
    setState(() {
      _contents.clear();
      _lastId = null;
      _hasError = false;
      _hasMoreData = true;
    });
    await _loadMoreContent();
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      _profileFuture = _fetchUserProfile();
      await _profileFuture;
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Widget _buildContentItem(int index) {
    final content = _contents[index];
    return RepaintBoundary(
      key: ValueKey(content.id),
      child: FeedItem(
        content: content,
        onLikeToggled: (isLiked) {
          setState(() {
            content.isLiked = isLiked;
            content.likes += isLiked ? 1 : -1;
          });
        },
        onFollowToggled: (isFollowed) {
          setState(() {
            content.isFollowed = isFollowed;
          });
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return _isLoading
        ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          )
        : const SizedBox.shrink();
  }

  Widget _buildFeedErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _refreshFeed, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFeedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No posts available'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _refreshFeed, child: const Text('Refresh')),
        ],
      ),
    );
  }



  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withAlpha(10),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading Profile...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildLevelBadge(String? level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getLevelColor(level),
            _getLevelColor(level).withAlpha(80),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: _getLevelColor(level).withAlpha(30),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getLevelIcon(level), size: 18, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            level?.toUpperCase() ?? 'NO LEVEL',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(Map<String, dynamic> profileData, BuildContext context) {

    return Padding(
      padding:  EdgeInsets.only(right: 20.0,left: 20.0,),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  profileData['followers']?.toString() ?? '0',
                  'Followers',
                  Icons.people_outline,
                  Colors.blue,
                  onTap: () =>
                      showFollowersFollowingDialog(context, widget.userId),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatCard(
                  profileData['followings']?.toString() ?? '0',
                  'Following',
                  Icons.person_add_outlined,
                  Colors.green,
                  onTap: () =>
                      showFollowersFollowingDialog(context, widget.userId),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatCard(
                 profileData['achievements'] != null ? '1' : '0', 
                  'Achievements',
                  Icons.emoji_events_outlined,
                  Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
            color: Colors.white,
        elevation: 0,
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }



void _navigateToChat(Map<String, dynamic> profileData) {
  try {
    // Get the chat controller instance
    final FireChatController chatController = Get.find<FireChatController>();
    
    // Prepare user data for chat navigation
    final Map<String, dynamic> receiverUser = {
      'userId': profileData['_id'] ?? widget.userId,
      '_id': profileData['_id'] ?? widget.userId,
      'uid': profileData['_id'] ?? widget.userId,
      'name': profileData['name'] ?? 'Unknown User',
      'email': profileData['email'] ?? '',
      'photoURL': profileData['picture'] != null && profileData['picture'].isNotEmpty
          ? 'http://182.93.94.210:3067${profileData['picture']}'
          : null,
      'picture': profileData['picture'],
      'isOnline': profileData['isOnline'] ?? false,
      'lastSeen': profileData['lastSeen'],
    };

    // Add user to recent users for better UX
    chatController.addUserToRecent(receiverUser);

    // Navigate to chat screen
    chatController.navigateToChat(receiverUser);
    
    // Optional: Show success feedback
    Get.snackbar(
      'Opening Chat',
      'Starting conversation with ${profileData['name'] ?? 'user'}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
      colorText: Colors.white,
      duration: const Duration(seconds: 1),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
    
  } catch (e) {
    // Handle error if chat controller is not initialized
    print('Error navigating to chat: $e');
    
    // Fallback: Show error message
    Get.snackbar(
      'Error',
      'Unable to open chat. Please try again.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withAlpha(80),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }
}

  

  Widget _buildPersonalInfo(Map<String, dynamic> profileData, BuildContext context) {


    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Padding(
       padding: EdgeInsets.only(right: 20.0,left: 20.0,top: 10.0,bottom: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 15),
                const Text(
                  'Personal Information',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 5),
           
            if (profileData['location'] != null &&
                profileData['location'].isNotEmpty)
              _buildInfoRow(
                Icons.location_on_outlined,
                // 'Location',
                  null,
                profileData['location'],
                Colors.purple,
              ),
if (profileData['gender'] != null)
              _buildInfoRow(
                Icons.person_outline,
                // 'Gender',
                  null,
                profileData['gender'],
                Colors.teal,
              ),
                if (isExpanded)...[
                if (profileData['dob'] != null)
              _buildInfoRow(
                Icons.cake_outlined,
                // 'Birthday',
                  null,
                _formatDate(profileData['dob']),
                Colors.pink,
              ),
 
      if (profileData['profession'] != null &&
            profileData['profession'].isNotEmpty)
          _buildInfoRow(
            Icons.work_outline,
         
              null,
           'Works as ${profileData['profession']}',
            Colors.orange,
          ),
        if (profileData['education'] != null &&
            profileData['education'].isNotEmpty)
          _buildInfoRow(
            Icons.school_outlined,
              null,
           'Studies ${profileData['education']}',
            Colors.indigo,
          ),
        if (profileData['achievements'] != null &&
            profileData['achievements'].isNotEmpty)
          _buildInfoRow(
            Icons.emoji_events_outlined,
            'Achievements',
            profileData['achievements'],
            Colors.amber,
          ),



        //incase needed in future for showing the email and the phone number
          
            // _buildInfoRow(
            //   Icons.email_outlined,
            //   // 'Email',
            //   null,
            //   profileData['email'] ?? 'Not provided',
            //   Colors.red,
            //   onTap: () => _copyToClipboard(profileData['email'], 'Email'),
            // ),
            // if (profileData['phone'] != null && profileData['phone'].isNotEmpty)
            //   _buildInfoRow(
            //     Icons.phone_outlined,
            //     // 'Phone',
            //     null,
            //     profileData['phone'],
            //     Colors.green,
            //     onTap: () => _copyToClipboard(profileData['phone'], 'Phone'),
            //   ),
  ],
  TextButton(onPressed: (){

    setState(() {
      isExpanded = !isExpanded;
    });
  },child:Text( isExpanded?'See Less Information ...':'See More Information ...',style: TextStyle(color: Colors.grey, fontSize: 16),)),

          ],
        ),
      ),
    );
  }


  Widget _buildInfoRow(
    IconData icon,
    String? label,
    String value,
    Color color, {
    VoidCallback? onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    if (label != null) ...[
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      
                      color: isDarkMode ? Colors.white : Colors.black87,
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

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Unable to load profile information',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _refreshProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(String? text, String type) {
    if (text != null && text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$type copied to clipboard'))
      );
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Not provided';
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Color _getLevelColor(String? level) {
    switch (level?.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      case 'expert':
        return Colors.purple;
      default:
        return Colors.brown;
    }
  }

  IconData _getLevelIcon(String? level) {
    switch (level?.toLowerCase()) {
      case 'beginner':
        return Icons.looks_one;
      case 'intermediate':
        return Icons.looks_two;
      case 'advanced':
        return Icons.looks_3;
      case 'expert':
        return Icons.star;
      default:
        return Icons.star;
    }
  }
}