import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:innovator/Innovator/screens/Eliza_ChatBot/Elizahomescreen.dart';
import 'package:innovator/Innovator/screens/Follow/Follow_status_Manager.dart';
import 'package:innovator/Innovator/screens/chatApp/Add_to_Chat.dart';
import 'package:innovator/Innovator/screens/chatApp/EnhancedUserAvtar.dart';
import 'package:innovator/Innovator/screens/chatApp/controller/chat_controller.dart';
import 'package:lottie/lottie.dart';
import 'dart:developer' as developer;

class OptimizedChatHomePage extends GetView<FireChatController> {
  const OptimizedChatHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handlePageVisible();
    });
    return Scaffold(
    backgroundColor: Get.theme.scaffoldBackgroundColor,
    //appBar: _buildAppBar(),
    body: CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildUserStatus()),
        // SliverToBoxAdapter(child: _buildCurrentUserCard()), // Uncomment if needed
        SliverToBoxAdapter(child: _buildIntegratedSearchBar()),
        SliverFillRemaining(
          child: _buildUsersList(),
        ),
      ],
    ),
  );
  }

  void _handlePageVisible() {
    try {
      developer.log('👁️ Chat home page visible');
      
      // Only load users if the list is empty or if specifically requested
      if (controller.allUsers.isEmpty && !controller.isLoadingUsers.value) {
        developer.log('📱 Users list is empty, loading...');
        controller.loadAllUsers();
      } else {
        developer.log('✅ Users already loaded: ${controller.allUsers.length}');
      }
    } catch (e) {
      developer.log('❌ Error handling page visible: $e');
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'ChatRoom',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 20,
        ),
      ),
      backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
      elevation: 0,
      automaticallyImplyLeading: true,
     actions: [
      IconButton(onPressed: () => controller.refreshUsersAndCache(), icon: Icon(Icons.refresh,color: Colors.white,))
      
     ],
    );
  }

  Widget _buildUserStatus() {
    return Obx(() {
      // Get online users for status row
      final onlineUsers = controller.allUsers.where((user) => user['isOnline'] == true).toList();
      final totalOnline = onlineUsers.length;

      return Container(
        height: 150,
       // margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Get.theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            //   child: Row(
            //     children: [
            //       Icon(
            //         Icons.circle,
            //         color: Colors.green,
            //         size: 12,
            //       ),
            //       const SizedBox(width: 6),
            //       Text(
            //         'Online ($totalOnline)',
            //         style: TextStyle(
            //           fontWeight: FontWeight.w600,
            //           fontSize: 14,
            //           color: Get.theme.textTheme.bodyLarge?.color,
            //         ),
            //       ),
            //      // const Spacer(),
            //       // Add ELIZA ChatBot button
            //       // GestureDetector(
            //       //   onTap: () => Get.to(() => ElizaChatScreen()),
            //       //   child: Container(
            //       //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            //       //     decoration: BoxDecoration(
            //       //       gradient: LinearGradient(
            //       //         colors: [
            //       //           const Color.fromRGBO(244, 135, 6, 1),
            //       //           const Color.fromRGBO(244, 135, 6, 0.8),
            //       //         ],
            //       //       ),
            //       //       borderRadius: BorderRadius.circular(12),
            //       //     ),
            //       //     // child: Row(
            //       //     //   mainAxisSize: MainAxisSize.min,
            //       //     //   children: [
            //       //     //     Icon(
            //       //     //       Icons.smart_toy,
            //       //     //       color: Colors.white,
            //       //     //       size: 16,
            //       //     //     ),
                          
            //       //     //   ],
            //       //     // ),
            //       //   ),
            //       // ),
            //     ],
            //   ),
            // ),
            Expanded(
              child: onlineUsers.isEmpty
                  ? Center(
                      child: Text(
                        'No users online',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: onlineUsers.length,
                      itemBuilder: (context, index) {
                        final user = onlineUsers[index];
                        return _buildStatusUserItem(user, index);
                      },
                    ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatusUserItem(Map<String, dynamic> user, int index) {
    return GestureDetector(
      onTap: () => controller.navigateToChat(user),
      child: Container(
        margin: EdgeInsets.only(right: 12, bottom: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.green,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withAlpha(30),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: EnhancedUserAvatar(
                    user: user,
                    radius: 22,
                    isOnline: true,
                    showOnlineIndicator: false,
                    heroTag: 'status_avatar_${user['id']}_$index',
                  ),
                ),
                // Online indicator
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Get.theme.cardColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 60,
              child: Text(
                user['name']?.toString().split(' ').first ?? 'User',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Get.theme.textTheme.bodyMedium?.color,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentUserCard() {
    return Obx(() {
      final user = controller.currentUser.value;
      if (user == null) return const SizedBox.shrink();

      return InkWell(
        onTap: () {
          Get.to(() => ElizaChatScreen());
        },
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color.fromRGBO(244, 135, 6, 1),
                const Color.fromRGBO(244, 135, 6, 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(244, 135, 6, 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Hero(
                tag: 'current_user_avatar',
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    backgroundImage: AssetImage('animation/AI.gif'),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ELIZA ChatBot',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Online',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified_user,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // NEW: Integrated search bar
  // ...existing code...
Widget _buildIntegratedSearchBar() {
  final TextEditingController searchController = TextEditingController();

  return Obx(() {
    // Update search controller when searchQuery changes
    if (controller.searchQuery.value != searchController.text) {
      searchController.text = controller.searchQuery.value;
      searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.searchQuery.value.length),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Get.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search mutual followers...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: controller.isSearching.value
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: const Color.fromRGBO(244, 135, 6, 1),
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.search,
                        color: Color.fromRGBO(244, 135, 6, 1),
                      ),
                suffixIcon: controller.searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey.shade600),
                        onPressed: () {
                          searchController.clear();
                          controller.searchQuery.value = '';
                          controller.searchResults.clear();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              onChanged: (value) {
                controller.searchQuery.value = value;
                // Implement local search if needed
                _performLocalSearch(value);
              },
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  controller.searchUsers(value.trim());
                }
              },
            ),
          ),
          IconButton(
            onPressed: () => controller.refreshUsersAndCache(),
            icon: Icon(Icons.refresh, color: const Color.fromRGBO(244, 135, 6, 1)),
            tooltip: 'Refresh users',
          ),
        ],
      ),
    );
  });
}
// ...existing code...

  // NEW: Local search through existing users
  void _performLocalSearch(String query) {
    if (query.isEmpty) {
      controller.searchResults.clear();
      return;
    }

    final filteredUsers = controller.allUsers.where((user) {
      final name = (user['name'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      final searchQuery = query.toLowerCase();
      return name.contains(searchQuery) || email.contains(searchQuery);
    }).toList();

    controller.searchResults.value = filteredUsers;
  }

Widget _buildUsersList() {
  return Obx(() {
    developer.log('🔄 UI Rebuild - Users count: ${controller.allUsers.length}');
    
    // Check if we're in search mode
    final isSearchMode = controller.searchQuery.value.isNotEmpty;
    final displayUsers = isSearchMode ? controller.searchResults : controller.allUsers;
    
    // ENHANCED: Better loading state management with follow status
    if (controller.isLoadingFollowStatus.value && controller.allUsers.isEmpty) {
      return _buildFollowStatusLoadingState();
    }
    
    if (controller.isLoadingUsers.value && controller.allUsers.isEmpty) {
      return _buildLoadingState();
    }

    // Search-specific states
    if (isSearchMode) {
      if (controller.isSearching.value && controller.searchResults.isEmpty) {
        return _buildSearchingState();
      }
      
      if (controller.searchResults.isEmpty && !controller.isSearching.value) {
        return _buildNoSearchResultsState();
      }
    // } else {
    //   // Normal mode empty state
    //   if (controller.allUsers.isEmpty && !controller.isLoadingUsers.value) {
    //     return _buildEmptyState();
    //   }
    }

    // Debug log to verify data is available
    developer.log('📱 Building list with ${displayUsers.length} users (search mode: $isSearchMode)');

    return RefreshIndicator(
      onRefresh: () async {
        // ENHANCED: Force refresh with follow status check
        await controller.refreshUsersWithFollowStatus();
      },
      color: const Color.fromRGBO(244, 135, 6, 1),
      child: Column(
        children: [
          // Show search results info or follow status info
          if (isSearchMode)
            _buildSearchResultsInfoBar(displayUsers.length)
          else
            _buildFollowStatusInfoBar(),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: displayUsers.length,
              itemBuilder: (context, index) {
                final user = displayUsers[index];
                developer.log('Building card for user: ${user['name']}');
                return _buildUserCard(user, index);
              },
            ),
          ),
        ],
      ),
    );
  });
}

// NEW: Search results info bar
Widget _buildSearchResultsInfoBar(int resultCount) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.blue.withAlpha(10),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.blue.withAlpha(30),
        width: 1,
      ),
    ),
    child: Row(
      children: [
        Icon(
          Icons.search,
          size: 16,
          color: Colors.blue,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            resultCount > 0
                ? '$resultCount result${resultCount != 1 ? 's' : ''} found'
                : 'No results found',
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (resultCount > 0)
          GestureDetector(
            onTap: () {
              controller.searchQuery.value = '';
              controller.searchResults.clear();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Clear',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

// NEW: Searching state
Widget _buildSearchingState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: const Color.fromRGBO(244, 135, 6, 1),
                backgroundColor: const Color.fromRGBO(244, 135, 6, 0.2),
              ),
            ),
            Icon(
              Icons.search,
              size: 24,
              color: const Color.fromRGBO(244, 135, 6, 1),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Searching users...',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please wait while we find users',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    ),
  );
}

// NEW: No search results state
Widget _buildNoSearchResultsState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey.withAlpha(10),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'No users found',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Try searching with a different name',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () {
            controller.searchQuery.value = '';
            controller.searchResults.clear();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          icon: const Icon(Icons.refresh),
          label: const Text('Clear Search'),
        ),
      ],
    ),
  );
}

Widget _buildFollowStatusInfoBar() {
  return Obx(() {
    if (controller.isLoadingFollowStatus.value || controller.loadingStatusText.value.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(244, 135, 6, 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color.fromRGBO(244, 135, 6, 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            if (controller.isLoadingFollowStatus.value)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: const Color.fromRGBO(244, 135, 6, 1),
                ),
              )
            else
              Icon(
                Icons.verified,
                size: 16,
                color: const Color.fromRGBO(244, 135, 6, 1),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                controller.loadingStatusText.value.isNotEmpty 
                    ? controller.loadingStatusText.value
                    : 'Showing only mutual followers',
                style: const TextStyle(
                  color: Color.fromRGBO(244, 135, 6, 1),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  });
}

Widget _buildFollowStatusLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: const Color.fromRGBO(244, 135, 6, 1),
                  backgroundColor: const Color.fromRGBO(244, 135, 6, 0.2),
                ),
              ),
              Icon(
                Icons.people_outline,
                size: 40,
                color: const Color.fromRGBO(244, 135, 6, 1),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Obx(() => Text(
            controller.loadingStatusText.value.isNotEmpty 
                ? controller.loadingStatusText.value 
                : 'Loading mutual followers...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          )),
          const SizedBox(height: 8),
          Text(
            'Please wait while we filter your contacts',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, int index) {
  final isOnline = user['isOnline'] ?? false;
  final isMutualFollow = user['isMutualFollow'] ?? false;
  
  final userId = user['userId']?.toString() ?? 
                user['_id']?.toString() ?? 
                user['id']?.toString() ?? '';
  
  // Generate chat ID to get badge count
  final chatId = controller.generateChatId(controller.currentUserId.value, userId);
  
  final isRecentUser = controller.recentUsers.any((recentUser) {
    final recentUserId = recentUser['userId']?.toString() ?? 
                        recentUser['_id']?.toString() ?? 
                        recentUser['id']?.toString() ?? '';
    return recentUserId == userId;
  });
  
  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.0, end: 1.0),
    duration: Duration(milliseconds: 300 + (index * 50)),
    curve: Curves.elasticOut,
    builder: (context, value, child) {
      return Transform.scale(
        scale: value,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => controller.navigateToChat(user),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Get.theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: isMutualFollow
                      ? Border.all(
                          color: const Color.fromRGBO(244, 135, 6, 0.3),
                          width: 1,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: isMutualFollow
                          ? const Color.fromRGBO(244, 135, 6, 0.1)
                          : Colors.black.withAlpha(5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar with badge
                    Stack(
                      children: [
                        _buildUserAvatar(user, isOnline),
                        // Unread message badge
                        Obx(() {
                          final badgeCount = controller.getBadgeCountReactive(chatId).value;
                          if (badgeCount > 0) {
                            return Positioned(
                              top: -2,
                              right: -2,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withAlpha(30),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                child: Center(
                                  child: Text(
                                    badgeCount > 99 ? '99+' : badgeCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  user['name'] ?? 'Unknown User',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Get.theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ),
                              // Show badge count in text form
                              Obx(() {
                                final badgeCount = controller.getBadgeCountReactive(chatId).value;
                                if (badgeCount > 0) {
                                  return Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      badgeCount > 99 ? '99+' : badgeCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              }),
                              // Mutual follow indicator
                              if (isMutualFollow) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(244, 135, 6, 1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.verified,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'Mutual',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              // Recent user indicator
                              if (isRecentUser) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Recent',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isOnline
                                ? 'Online'
                                : 'Last seen ${controller.formatLastSeen(user['lastSeen'])}',
                            style: TextStyle(
                              color: isOnline ? Colors.green : Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isMutualFollow
                            ? const Color.fromRGBO(244, 135, 6, 1)
                            : const Color.fromRGBO(244, 135, 6, 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isMutualFollow ? Icons.chat : Icons.chat_bubble_outline,
                        color: isMutualFollow
                            ? Colors.white
                            : const Color.fromRGBO(244, 135, 6, 1),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

  Widget _buildUserAvatar(Map<String, dynamic> user, bool isOnline) {
  return EnhancedUserAvatar(
    user: user,
    radius: 28,
    isOnline: isOnline,
    showOnlineIndicator: true,
    heroTag: 'user_avatar_${user['id']}',
  );
}

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color.fromRGBO(244, 135, 6, 1),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading users...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildEmptyState() {
  //   return Center(
  //     child: Column(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         Container(
  //           padding: const EdgeInsets.all(24),
  //           decoration: BoxDecoration(
  //             color: const Color.fromRGBO(244, 135, 6, 0.1),
  //             shape: BoxShape.circle,
  //           ),
  //           child: const Icon(
  //             Icons.people_outline,
  //             size: 64,
  //             color: Color.fromRGBO(244, 135, 6, 1),
  //           ),
  //         ),
  //         const SizedBox(height: 24),
  //         Text(
  //           'No mutual followers yet',
  //           style: TextStyle(
  //             fontSize: 20,
  //             fontWeight: FontWeight.bold,
  //             color: Colors.grey.shade700,
  //           ),
  //         ),
  //         const SizedBox(height: 8),
  //         Text(
  //           'Start following people to see them here',
  //           style: TextStyle(
  //             fontSize: 14,
  //             color: Colors.grey.shade500,
  //           ),
  //         ),
  //         const SizedBox(height: 24),
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             ElevatedButton.icon(
  //               onPressed: () => controller.refreshUsersAndCache(),
  //               style: ElevatedButton.styleFrom(
  //                 backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
  //                 foregroundColor: Colors.white,
  //                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(25),
  //                 ),
  //               ),
  //               icon: const Icon(Icons.refresh),
  //               label: const Text('Refresh'),
  //             ),
  //             const SizedBox(width: 12),
  //             OutlinedButton.icon(
  //               onPressed: () => Get.to(() => const AddToChatScreen()),
  //               style: OutlinedButton.styleFrom(
  //                 foregroundColor: const Color.fromRGBO(244, 135, 6, 1),
  //                 side: const BorderSide(color: Color.fromRGBO(244, 135, 6, 1)),
  //                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(25),
  //                 ),
  //               ),
  //               icon: const Icon(Icons.person_search),
  //               label: const Text('Find Users'),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // void _showLogoutDialog() {
  //   Get.dialog(
  //     AlertDialog(
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(16),
  //       ),
  //       title: const Row(
  //         children: [
  //           Icon(Icons.logout, color: Colors.red),
  //           SizedBox(width: 8),
  //           Text('Logout'),
  //         ],
  //       ),
  //       content: const Text('Are you sure you want to logout?'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Get.back(),
  //           child: Text(
  //             'Cancel',
  //             style: TextStyle(color: Colors.grey.shade600),
  //           ),
  //         ),
  //         ElevatedButton(
  //           onPressed: () {
  //             Get.back();
  //             controller.updateUserStatus(false);
  //             Get.offAllNamed('/login');
  //           },
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: Colors.red,
  //             foregroundColor: Colors.white,
  //           ),
  //           child: const Text('Logout'),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}