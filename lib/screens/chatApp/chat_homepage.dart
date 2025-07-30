import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:innovator/screens/Eliza_ChatBot/Elizahomescreen.dart';
import 'package:innovator/screens/Follow/Follow_status_Manager.dart';
import 'package:innovator/screens/chatApp/Add_to_Chat.dart';
import 'package:innovator/screens/chatApp/EnhancedUserAvtar.dart';
import 'package:innovator/screens/chatApp/controller/chat_controller.dart';
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
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildCurrentUserCard(),
          _buildQuickActions(), // NEW: Quick action buttons
          Expanded(child: _buildUsersList()),
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
      automaticallyImplyLeading: false,
      // actions: [
      //   IconButton(
      //     icon: const Icon(Icons.search, color: Colors.white, size: 24),
      //     onPressed: () => Get.toNamed('/search'),
      //     tooltip: 'Search Users',
      //   ),
      //   PopupMenuButton<String>(
      //     icon: const Icon(Icons.more_vert, color: Colors.white),
      //     onSelected: (value) {
      //       if (value == 'logout') {
      //         _showLogoutDialog();
      //       } else if (value == 'refresh') {
      //         controller.refreshUsersAndCache();
      //       }
      //     },
      //     itemBuilder: (context) => [
      //       const PopupMenuItem(
      //         value: 'refresh',
      //         child: Row(
      //           children: [
      //             Icon(Icons.refresh, color: Colors.blue, size: 20),
      //             SizedBox(width: 12),
      //             Text('Refresh', style: TextStyle(fontSize: 14)),
      //           ],
      //         ),
      //       ),
      //       const PopupMenuItem(
      //         value: 'logout',
      //         child: Row(
      //           children: [
      //             Icon(Icons.logout, color: Colors.red, size: 20),
      //             SizedBox(width: 12),
      //             Text('Logout', style: TextStyle(fontSize: 14)),
      //           ],
      //         ),
      //       ),
      //     ],
      //   ),
      // ],
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
                        color: Colors.black.withOpacity(0.1),
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
                  color: Colors.white.withOpacity(0.2),
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

  // NEW: Quick action buttons
  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.person_add,
              label: 'Add to Chat',
              color: Colors.green,
              onTap: () {
                Get.to(() => const AddToChatScreen());
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.chat_bubble_outline,
              label: 'My Chats',
              color: const Color.fromRGBO(244, 135, 6, 1),
              onTap: () {
                // Navigate to chat list or switch to chat tab
                controller.changeBottomIndex(1);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.search,
              label: 'Search',
              color: Colors.blue,
              onTap: () {
                Get.toNamed('/search');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

 Widget _buildUsersList() {
    return Obx(() {
      // ENHANCED: Better loading state management
      if (controller.isLoadingFollowStatus.value && controller.allUsers.isEmpty) {
        return _buildFollowStatusLoadingState();
      }
      
      if (controller.isLoadingUsers.value && controller.allUsers.isEmpty) {
        return _buildLoadingState();
      }

      if (controller.allUsers.isEmpty && !controller.isLoadingUsers.value) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: () async {
          // ENHANCED: Force refresh when user pulls down
          await controller.refreshUsersAndCache();
        },
        color: const Color.fromRGBO(244, 135, 6, 1),
        child: Column(
          children: [
            _buildAddToChatStatusBar(),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: controller.allUsers.length,
                itemBuilder: (context, index) {
                  final user = controller.allUsers[index];
                  return _buildUserCard(user, index);
                },
              ),
            ),
          ],
        ),
      );
    });
  }



// NEW: Status bar for Add to Chat screen
Widget _buildAddToChatStatusBar() {
  return Obx(() {
    final totalUsers = controller.allUsers.length;
    final onlineUsers = controller.allUsers.where((user) => user['isOnline'] == true).length;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildMiniStatCard('Total', '$totalUsers', Icons.people, Colors.blue),
          const SizedBox(width: 16),
          _buildMiniStatCard('Online', '$onlineUsers', Icons.circle, Colors.green),
          const SizedBox(width: 16),
          _buildMiniStatCard('Mutual', '$totalUsers', Icons.people_outline, const Color.fromRGBO(244, 135, 6, 1)),
        ],
      ),
    );
  });
}


Widget _buildMiniStatCard(String label, String value, IconData icon, Color color) {
  return Expanded(
    child: Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    ),
  );
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

// NEW: Status bar showing cache and mutual followers info
// Widget _buildStatusBar() {
//   return Obx(() {
//     final followStatusManager = FollowStatusManager.instance;
//     final stats = followStatusManager.getCacheStats();
//     final mutualCount = controller.allUsers.length;
    
//     if (mutualCount == 0 && !controller.isLoadingUsers.value) {
//       return const SizedBox.shrink();
//     }
    
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: const Color.fromRGBO(244, 135, 6, 0.1),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(
//           color: const Color.fromRGBO(244, 135, 6, 0.3),
//           width: 1,
//         ),
//       ),
//       child: Row(
//         children: [
//           Icon(
//             Icons.people,
//             size: 16,
//             color: const Color.fromRGBO(244, 135, 6, 1),
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               '$mutualCount mutual followers',
//               style: const TextStyle(
//                 color: Color.fromRGBO(244, 135, 6, 1),
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//           if (stats['totalCached'] > 0)
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//               decoration: BoxDecoration(
//                 color: Colors.green.withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Text(
//                 '${stats['totalCached']} cached',
//                 style: const TextStyle(
//                   color: Colors.green,
//                   fontSize: 10,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   });
// }

Widget _buildSearchLoadingState() {
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
          'Searching mutual followers...',
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

// NEW: Initial search state with tips
Widget _buildInitialSearchState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(244, 135, 6, 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.search,
            size: 64,
            color: Color.fromRGBO(244, 135, 6, 1),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Find mutual followers',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Search among users you mutually follow',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Only mutual followers can chat',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
  Widget _buildUserCard(Map<String, dynamic> user, int index) {
  final isOnline = user['isOnline'] ?? false;
  
  // NEW: Check if user is in recent users
  final userId = user['userId']?.toString() ?? 
                user['_id']?.toString() ?? 
                user['id']?.toString() ?? '';
  
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
                  // NEW: Special border for recent users
                  border: isRecentUser
                      ? Border.all(
                          color: const Color.fromRGBO(244, 135, 6, 0.3),
                          width: 1,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: isRecentUser
                          ? const Color.fromRGBO(244, 135, 6, 0.1)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildUserAvatar(user, isOnline),
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
                              // NEW: Recent user indicator
                              if (isRecentUser)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(244, 135, 6, 1),
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
                        color: isRecentUser
                            ? const Color.fromRGBO(244, 135, 6, 1)
                            : const Color.fromRGBO(244, 135, 6, 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline,
                        color: isRecentUser
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(244, 135, 6, 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline,
              size: 64,
              color: Color.fromRGBO(244, 135, 6, 1),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No mutual followers yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start following people to see them here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => controller.refreshUsersAndCache(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => Get.to(() => const AddToChatScreen()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color.fromRGBO(244, 135, 6, 1),
                  side: const BorderSide(color: Color.fromRGBO(244, 135, 6, 1)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                icon: const Icon(Icons.person_search),
                label: const Text('Find Users'),
              ),
            ],
          ),
        ],
      ),
    );
  }


  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.updateUserStatus(false);
              Get.offAllNamed('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}