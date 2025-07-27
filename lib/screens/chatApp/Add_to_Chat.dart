import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:innovator/screens/chatApp/controller/chat_controller.dart';
import 'package:lottie/lottie.dart';
import 'dart:developer' as developer;

class AddToChatScreen extends GetView<FireChatController> {
  const AddToChatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Load all users when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadAllUsers();
    });

    return Scaffold(
      backgroundColor: Get.theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildUsersList()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Add to Chat',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 20,
        ),
      ),
      backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Get.back(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () => Get.toNamed('/search'),
          tooltip: 'Search Users',
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () => controller.refreshUsersAndCache(),
          tooltip: 'Refresh Users',
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromRGBO(244, 135, 6, 0.1),
            const Color.fromRGBO(244, 135, 6, 0.05),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(244, 135, 6, 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.group_add,
                  color: Color.fromRGBO(244, 135, 6, 1),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Start New Conversation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Select a user to add them to your chat list',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard(
                    'Total Users',
                    '${controller.allUsers.length}',
                    Icons.people,
                    Colors.blue,
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.grey.shade300,
                  ),
                  _buildStatCard(
                    'Online',
                    '${controller.allUsers.where((user) => user['isOnline'] == true).length}',
                    Icons.circle,
                    Colors.green,
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.grey.shade300,
                  ),
                  _buildStatCard(
                    'Active Chats',
                    '${controller.chatList.length}',
                    Icons.chat_bubble,
                    const Color.fromRGBO(244, 135, 6, 1),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Column(
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
    );
  }

  Widget _buildUsersList() {
    return Obx(() {
      if (controller.isLoadingUsers.value && controller.allUsers.isEmpty) {
        return _buildLoadingState();
      }

      if (controller.allUsers.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: () async {
          await controller.refreshUsersAndCache();
        },
        color: const Color.fromRGBO(244, 135, 6, 1),
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: controller.allUsers.length,
          itemBuilder: (context, index) {
            final user = controller.allUsers[index];
            return _buildUserCard(user, index);
          },
        ),
      );
    });
  }

  Widget _buildUserCard(Map<String, dynamic> user, int index) {
    final isOnline = user['isOnline'] ?? false;
    final lastSeen = user['lastSeen'];
    final userName = user['name']?.toString() ?? 'Unknown User';
    final userEmail = user['email']?.toString() ?? '';
    final userPhoto = user['photoURL']?.toString();
    
    // Check if user is already in chat list
    final isInChatList = controller.chatList.any((chat) {
      final otherUser = chat['otherUser'] as Map<String, dynamic>?;
      return otherUser?['userId'] == user['userId'] || 
             otherUser?['_id'] == user['_id'] || 
             otherUser?['id'] == user['id'];
    });

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _handleUserSelection(user, isInChatList),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isInChatList 
                        ? const Color.fromRGBO(244, 135, 6, 0.1)
                        : Get.theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: isInChatList
                        ? Border.all(
                            color: const Color.fromRGBO(244, 135, 6, 0.3),
                            width: 2,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: isInChatList
                            ? const Color.fromRGBO(244, 135, 6, 0.1)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildUserAvatar(user, isOnline),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    userName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Get.theme.textTheme.bodyLarge?.color,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isInChatList)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color.fromRGBO(244, 135, 6, 1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'In Chat',
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
                              userEmail,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isOnline ? Colors.green : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    isOnline
                                        ? 'Online'
                                        : 'Last seen ${controller.formatLastSeen(lastSeen)}',
                                    style: TextStyle(
                                      color: isOnline ? Colors.green : Colors.grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildActionButton(user, isInChatList),
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
    final userName = user['name']?.toString() ?? 'Unknown User';
    final userPhoto = user['photoURL']?.toString();

    return Stack(
      children: [
        Hero(
          tag: 'add_chat_avatar_${user['id'] ?? user['userId'] ?? 'unknown'}',
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isOnline ? Colors.green : Colors.grey.shade300,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isOnline 
                      ? Colors.green.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: isOnline ? 10 : 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
              backgroundImage: userPhoto != null && userPhoto.isNotEmpty
                  ? NetworkImage(userPhoto)
                  : null,
              child: userPhoto == null || userPhoto.isEmpty
                  ? Text(
                      userName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    )
                  : null,
            ),
          ),
        ),
        Positioned(
          bottom: 2,
          right: 2,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: isOnline
                  ? [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.6),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(Map<String, dynamic> user, bool isInChatList) {
    if (isInChatList) {
      return Container(
        decoration: BoxDecoration(
          color: const Color.fromRGBO(244, 135, 6, 1),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(244, 135, 6, 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openExistingChat(user),
            borderRadius: BorderRadius.circular(25),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(
                Icons.chat,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _addToChat(user),
          borderRadius: BorderRadius.circular(25),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Icon(
              Icons.add,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
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
          const SizedBox(height: 8),
          Text(
            'Please wait while we fetch all users',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
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
            'No users found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There are no users available to add to chat',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => controller.refreshUsersAndCache(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 4,
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  void _handleUserSelection(Map<String, dynamic> user, bool isInChatList) {
    if (isInChatList) {
      _openExistingChat(user);
    } else {
      _addToChat(user);
    }
  }

  void _addToChat(Map<String, dynamic> user) {
    final userName = user['name']?.toString() ?? 'Unknown User';
    
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
              backgroundImage: user['photoURL'] != null && user['photoURL'].toString().isNotEmpty
                  ? NetworkImage(user['photoURL'].toString())
                  : null,
              child: user['photoURL'] == null || user['photoURL'].toString().isEmpty
                  ? Text(
                      userName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add to Chat',
                    style: TextStyle(fontSize: 18),
                  ),
                  Text(
                    userName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Text(
          'Do you want to start a conversation with $userName? This will add them to your chat list.',
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
              _startConversation(user);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Add to Chat'),
          ),
        ],
      ),
    );
  }

  void _startConversation(Map<String, dynamic> user) {
    final userName = user['name']?.toString() ?? 'Unknown User';
    
    // Show success feedback
    Get.snackbar(
      'Added to Chat',
      '$userName has been added to your chat list',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      icon: const Icon(
        Icons.check_circle,
        color: Colors.white,
      ),
    );

    // Navigate to chat with the user
    controller.navigateToChat(user);
  }

  void _openExistingChat(Map<String, dynamic> user) {
    final userName = user['name']?.toString() ?? 'Unknown User';
    
    Get.snackbar(
      'Opening Chat',
      'Opening conversation with $userName',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
      colorText: Colors.white,
      duration: const Duration(seconds: 1),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );

    // Navigate to existing chat
    controller.navigateToChat(user);
  }
}