import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:innovator/Innovator/screens/chatApp/EnhancedUserAvtar.dart';
import 'package:innovator/Innovator/screens/chatApp/controller/chat_controller.dart';
import 'package:lottie/lottie.dart';

class OptimizedChatListPage extends GetView<FireChatController> {
  const OptimizedChatListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Get.theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: _buildChatList(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
  return AppBar(
    title: const Text(
      'Chats',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontSize: 20,
      ),
    ),
    backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
    elevation: 0,
    automaticallyImplyLeading: false,
    actions: [
      // ENHANCED: Global badge indicator with total count
      Obx(() {
        final totalUnread = controller.getTotalUnreadCountFromMutualFollowers();
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () => Get.toNamed('/search'),
              tooltip: 'Search Users',
            ),
            if (totalUnread > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade400, Colors.red.shade600],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withAlpha(40),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    totalUnread > 99 ? '99+' : '$totalUnread',
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
        );
      }),
      IconButton(
        icon: const Icon(Icons.more_vert, color: Colors.white),
        onPressed: _showMoreOptions,
      ),
    ],
  );
}

  Widget _buildChatList() {
    return Obx(() {
      if (controller.isLoadingChats.value && controller.chatList.isEmpty) {
        return _buildLoadingState();
      }

      if (controller.chatList.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: () async {
          await controller.loadUserChats();
        },
        color: const Color.fromRGBO(244, 135, 6, 1),
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          itemCount: controller.chatList.length,
          itemBuilder: (context, index) {
            final chat = controller.chatList[index];
            return _buildChatCard(chat, index);
          },
        ),
      );
    });
  }

  Widget _buildChatCard(Map<String, dynamic> chat, int index) {
  final otherUser = chat['otherUser'] as Map<String, dynamic>?;
  if (otherUser == null) return const SizedBox.shrink();

  final lastMessage = chat['lastMessage']?.toString() ?? '';
  final lastMessageTime = chat['lastMessageTime'];
  final lastMessageSender = chat['lastMessageSender']?.toString() ?? '';
  final isMyLastMessage = lastMessageSender == controller.currentUserId.value;
  final chatId = chat['chatId']?.toString() ?? '';
  final isOnline = otherUser['isOnline'] ?? false;

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
              onTap: () {
                // Clear badge when opening chat
                final chatId = chat['chatId']?.toString() ?? '';
                controller.markMessagesAsRead(chatId);
                controller.navigateToChat(otherUser);
              },
              onLongPress: () => _showChatOptions(chat),
              borderRadius: BorderRadius.circular(16),
              child: Obx(() {
                // ENHANCED: Use reactive badge system
                final badgeCount = controller.getBadgeCountReactive(chatId).value;
                final hasUnread = badgeCount > 0;
                
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasUnread 
                        ? const Color.fromRGBO(244, 135, 6, 0.05) // Subtle highlight for unread
                        : Get.theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: hasUnread
                        ? Border.all(
                            color: const Color.fromRGBO(244, 135, 6, 0.2),
                            width: 1,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: hasUnread
                            ? const Color.fromRGBO(244, 135, 6, 0.1)
                            : Colors.black.withAlpha(4),
                        blurRadius: hasUnread ? 12 : 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Enhanced Avatar with unread indication
                      Stack(
                        children: [
                          _buildChatAvatar(otherUser, isOnline),
                          // Unread indicator ring around avatar
                          if (hasUnread)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.red.withAlpha(60),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
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
                                    otherUser['name']?.toString() ?? 'Unknown User',
                                    style: TextStyle(
                                      fontWeight: hasUnread
                                          ? FontWeight.w800 // Extra bold for unread
                                          : FontWeight.w600,
                                      fontSize: 16,
                                      color: hasUnread
                                          ? Get.theme.textTheme.bodyLarge?.color
                                          : Get.theme.textTheme.bodyLarge?.color?.withAlpha(90),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Enhanced time display
                                Container(
                                  padding: hasUnread 
                                      ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
                                      : EdgeInsets.zero,
                                  decoration: hasUnread
                                      ? BoxDecoration(
                                          color: const Color.fromRGBO(244, 135, 6, 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        )
                                      : null,
                                  child: Text(
                                    controller.formatChatTime(lastMessageTime),
                                    style: TextStyle(
                                      color: hasUnread
                                          ? const Color.fromRGBO(244, 135, 6, 1)
                                          : Colors.grey.shade600,
                                      fontSize: 12,
                                      fontWeight: hasUnread
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                // Message status icon for my messages
                                if (isMyLastMessage)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: _buildMessageStatusIcon(chat),
                                  ),
                                Expanded(
                                  child: Text(
                                    controller.truncateMessage(lastMessage, 35),
                                    style: TextStyle(
                                      color: hasUnread
                                          ? Get.theme.textTheme.bodyMedium?.color
                                          : Colors.grey.shade600,
                                      fontSize: 14,
                                      fontWeight: hasUnread
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // ENHANCED: Red Badge with better animation
                                if (hasUnread)
                                  Container(
                                    margin:  EdgeInsets.only(left: 8),
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      duration: const Duration(milliseconds: 600),
                                      curve: Curves.elasticOut,
                                      builder: (context, scale, child) {
                                        return Transform.scale(
                                          scale: scale,
                                          child: Container(
                                            padding:  EdgeInsets.symmetric(
                                              horizontal: badgeCount > 99 ? 6 : 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.red.shade500,
                                                  Colors.red.shade600,
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.red.withAlpha(40),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                                BoxShadow(
                                                  color: Colors.red.withAlpha(20),
                                                  blurRadius: 16,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 20,
                                              minHeight: 20,
                                            ),
                                            child: Text(
                                              badgeCount > 999 ? '999+' : '$badgeCount',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      );
    },
  );
}

  // NEW: Build message status icon with blue tick animation
  Widget _buildMessageStatusIcon(Map<String, dynamic> chat) {
    final lastMessageId = chat['lastMessageId']?.toString() ?? '';
    final lastMessageSender = chat['lastMessageSender']?.toString() ?? '';
    
    // Only show status for my messages
    if (lastMessageSender != controller.currentUserId.value) {
      return const SizedBox.shrink();
    }
    
    return Obx(() {
      final status = controller.getMessageStatus(lastMessageId);
      
      switch (status) {
        case 'sending':
          return SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Colors.grey.shade600,
            ),
          );
        case 'delivered':
          return Icon(
            Icons.done,
            size: 16,
            color: Colors.grey.shade600,
          );
        case 'read':
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Icon(
                  Icons.done_all,
                  size: 16,
                  color: Color.lerp(
                    Colors.grey.shade600,
                    Colors.blue,
                    value,
                  ),
                ),
              );
            },
          );
        default:
          return Icon(
            Icons.schedule,
            size: 16,
            color: Colors.grey.shade600,
          );
      }
    });
  }

  Widget _buildChatAvatar(Map<String, dynamic> user, bool isOnline) {
  return EnhancedUserAvatar(
    user: user,
    radius: 28,
    isOnline: isOnline,
    showOnlineIndicator: true,
    heroTag: 'chat_avatar_${user['id']}',
  );
}

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lottie.asset(
          //   'animation/chat_loading.json',
          //   width: 120,
          //   height: 120,
          //   fit: BoxFit.contain,
          // ),
          const SizedBox(height: 16),
          Text(
            'Loading your chats...',
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
          // Lottie.asset(
          //   'animation/empty_chat_list.json',
          //   width: 150,
          //   height: 150,
          //   fit: BoxFit.contain,
          // ),
          const SizedBox(height: 24),
          Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with someone',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed('/search'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 4,
            ),
            icon: const Icon(Icons.person_search),
            label: const Text('Find Users'),
          ),
        ],
      ),
    );
  }

 Widget _buildFloatingActionButton() {
  return Obx(() {
    final totalUnread = controller.getTotalUnreadCountFromMutualFollowers();
    
    return Stack(
      children: [
        AnimatedScale(
          scale: controller.fabScale.value,
          duration: const Duration(milliseconds: 150),
          child: FloatingActionButton(
            onPressed: () {
              controller.animateFab();
              Get.toNamed('/search');
            },
            backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
            elevation: 8,
            child: const Icon(
              Icons.edit,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        // ENHANCED: Red badge on FAB for total unread messages
        if (totalUnread > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade400, Colors.red.shade600],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withAlpha(40),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
              child: Text(
                totalUnread > 99 ? '99+' : '$totalUnread',
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
    );
  });
}

  void _showChatOptions(Map<String, dynamic> chat) {
    final otherUser = chat['otherUser'] as Map<String, dynamic>?;
    if (otherUser == null) return;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
                backgroundImage: otherUser['photoURL'] != null
                    ? NetworkImage(otherUser['photoURL'].toString())
                    : null,
                child: otherUser['photoURL'] == null
                    ? Text(
                        (otherUser['name']?.toString() ?? 'U').substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),
              title: Text(
                otherUser['name']?.toString() ?? 'Unknown User',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(otherUser['email']?.toString() ?? ''),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.mark_chat_read),
              title: const Text('Mark as Read'),
              onTap: () {
                Get.back();
                final chatId = chat['chatId']?.toString() ?? '';
                controller.markMessagesAsRead(chatId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.push_pin),
              title: const Text('Pin Chat'),
              onTap: () {
                Get.back();
                Get.snackbar('Pinned', 'Chat pinned to top');
              },
            ),
            ListTile(
              leading: const Icon(Icons.volume_off),
              title: const Text('Mute Notifications'),
              onTap: () {
                Get.back();
                Get.snackbar('Muted', 'Chat notifications muted');
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Archive Chat'),
              onTap: () {
                Get.back();
                Get.snackbar('Archived', 'Chat archived');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Chat', style: TextStyle(color: Colors.red)),
              onTap: () {
                Get.back();
                _showDeleteChatDialog(chat);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showDeleteChatDialog(Map<String, dynamic> chat) {
    final otherUser = chat['otherUser'] as Map<String, dynamic>?;
    
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Chat'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete your conversation with ${otherUser?['name']?.toString() ?? 'this user'}? This action cannot be undone.',
        ),
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
              final chatId = chat['chatId']?.toString() ?? '';
              controller.clearBadge(chatId);
              Get.snackbar(
                'Deleted',
                'Chat deleted successfully',
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions() {
  Get.bottomSheet(
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Get.theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // ENHANCED: Mark All as Read with badge count
          Obx(() {
            final totalUnread = controller.getTotalUnreadCountFromMutualFollowers();
            return ListTile(
              leading: Stack(
                children: [
                  const Icon(Icons.mark_chat_read),
                  if (totalUnread > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              title: Text('Mark All as Read${totalUnread > 0 ? ' ($totalUnread)' : ''}'),
              onTap: () {
                Get.back();
                _markAllAsRead();
              },
            );
          }),
          ListTile(
            leading: const Icon(Icons.archive),
            title: const Text('Archived Chats'),
            onTap: () {
              Get.back();
              Get.snackbar('Info', 'Archived chats feature coming soon');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Chat Settings'),
            onTap: () {
              Get.back();
              Get.snackbar('Info', 'Chat settings feature coming soon');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}
void _markAllAsRead() async {
  try {
    final totalUnread = controller.getTotalUnreadCountFromMutualFollowers();
    if (totalUnread == 0) {
      Get.snackbar('Info', 'No unread messages');
      return;
    }

    // Show loading
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(
          color: Color.fromRGBO(244, 135, 6, 1),
        ),
      ),
      barrierDismissible: false,
    );

    // Mark all chats as read
    final futures = <Future>[];
    for (final chat in controller.chatList) {
      final chatId = chat['chatId']?.toString() ?? '';
      if (chatId.isNotEmpty && controller.hasUnreadMessages(chatId)) {
        futures.add(controller.markMessagesAsRead(chatId));
      }
    }

    await Future.wait(futures);

    // Clear all badges
    controller.clearAllBadges();

    Get.back(); // Close loading dialog

    Get.snackbar(
      'Success',
      'All messages marked as read',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  } catch (e) {
    Get.back(); // Close loading dialog
    Get.snackbar(
      'Error',
      'Failed to mark all as read',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}
}