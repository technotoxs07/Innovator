// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:innovator/Innovatorscreens/chatApp/EnhancedUserAvtar.dart';
// import 'package:innovator/Innovatorscreens/chatApp/controller/chat_controller.dart';
// import 'package:lottie/lottie.dart';
// import 'dart:developer' as developer;

// class AddToChatScreen extends GetView<FireChatController> {
//   const AddToChatScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     // Load all users when screen opens
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       controller.loadAllUsers();
//     });

//     return Scaffold(
//       backgroundColor: Get.theme.scaffoldBackgroundColor,
//       appBar: _buildAppBar(),
//       body: Column(
//         children: [
//           _buildHeader(),
//           Expanded(child: _buildUsersList()),
//         ],
//       ),
//     );
//   }

//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//       title: const Text(
//         'Add to Chat',
//         style: TextStyle(
//           fontWeight: FontWeight.bold,
//           color: Colors.white,
//           fontSize: 20,
//         ),
//       ),
//       backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
//       elevation: 0,
//       leading: IconButton(
//         icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//         onPressed: () => Get.back(),
//       ),
//       actions: [
//         IconButton(
//           icon: const Icon(Icons.search, color: Colors.white),
//           onPressed: () => Get.toNamed('/search'),
//           tooltip: 'Search Users',
//         ),
//         IconButton(
//           icon: const Icon(Icons.refresh, color: Colors.white),
//           onPressed: () => controller.refreshUsersAndCache(),
//           tooltip: 'Refresh Users',
//         ),
//       ],
//     );
//   }

//   Widget _buildHeader() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             const Color.fromRGBO(244, 135, 6, 0.1),
//             const Color.fromRGBO(244, 135, 6, 0.05),
//           ],
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//         ),
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: const Color.fromRGBO(244, 135, 6, 0.1),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Icon(
//                   Icons.group_add,
//                   color: Color.fromRGBO(244, 135, 6, 1),
//                   size: 24,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Start New Conversation',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     Text(
//                       'Select a user to add them to your chat list',
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey.shade600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Obx(() {
//             return Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(20),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withAlpha(5),
//                     blurRadius: 8,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   _buildStatCard(
//                     'Total Users',
//                     '${controller.allUsers.length}',
//                     Icons.people,
//                     Colors.blue,
//                   ),
//                   Container(
//                     width: 1,
//                     height: 30,
//                     color: Colors.grey.shade300,
//                   ),
//                   _buildStatCard(
//                     'Online',
//                     '${controller.allUsers.where((user) => user['isOnline'] == true).length}',
//                     Icons.circle,
//                     Colors.green,
//                   ),
//                   Container(
//                     width: 1,
//                     height: 30,
//                     color: Colors.grey.shade300,
//                   ),
//                   _buildStatCard(
//                     'Active Chats',
//                     '${controller.chatList.length}',
//                     Icons.chat_bubble,
//                     const Color.fromRGBO(244, 135, 6, 1),
//                   ),
//                 ],
//               ),
//             );
//           }),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatCard(String label, String value, IconData icon, Color color) {
//     return Column(
//       children: [
//         Icon(icon, color: color, size: 20),
//         const SizedBox(height: 4),
//         Text(
//           value,
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 12,
//             color: Colors.grey.shade600,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildUsersList() {
//     return Obx(() {
//       if (controller.isLoadingUsers.value && controller.allUsers.isEmpty) {
//         return _buildLoadingState();
//       }

//       if (controller.allUsers.isEmpty) {
//         return _buildEmptyState();
//       }

//       return RefreshIndicator(
//         onRefresh: () async {
//           await controller.refreshUsersAndCache();
//         },
//         color: const Color.fromRGBO(244, 135, 6, 1),
//         child: ListView.builder(
//           physics: const BouncingScrollPhysics(),
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           itemCount: controller.allUsers.length,
//           itemBuilder: (context, index) {
//             final user = controller.allUsers[index];
//             return _buildUserCard(user, index);
//           },
//         ),
//       );
//     });
//   }

//  Widget _buildUserCard(Map<String, dynamic> user, int index) {
//   final isOnline = user['isOnline'] ?? false;
//   final isMutualFollow = user['isMutualFollow'] ?? false;
  
//   final userId = user['userId']?.toString() ?? 
//                 user['_id']?.toString() ?? 
//                 user['id']?.toString() ?? '';
  
//   final isRecentUser = controller.recentUsers.any((recentUser) {
//     final recentUserId = recentUser['userId']?.toString() ?? 
//                         recentUser['_id']?.toString() ?? 
//                         recentUser['id']?.toString() ?? '';
//     return recentUserId == userId;
//   });
  
//   return TweenAnimationBuilder<double>(
//     tween: Tween(begin: 0.0, end: 1.0),
//     duration: Duration(milliseconds: 300 + (index * 50)),
//     curve: Curves.elasticOut,
//     builder: (context, value, child) {
//       return Transform.scale(
//         scale: value,
//         child: Container(
//           margin: const EdgeInsets.symmetric(vertical: 4),
//           child: Material(
//             color: Colors.transparent,
//             child: InkWell(
//               onTap: () => controller.navigateToChat(user),
//               borderRadius: BorderRadius.circular(16),
//               child: Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Get.theme.cardColor,
//                   borderRadius: BorderRadius.circular(16),
//                   // Enhanced border for mutual followers
//                   border: isMutualFollow
//                       ? Border.all(
//                           color: const Color.fromRGBO(244, 135, 6, 0.3),
//                           width: 1,
//                         )
//                       : null,
//                   boxShadow: [
//                     BoxShadow(
//                       color: isMutualFollow
//                           ? const Color.fromRGBO(244, 135, 6, 0.1)
//                           : Colors.black.withAlpha(5),
//                       blurRadius: 8,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: Row(
//                   children: [
//                     _buildUserAvatar(user, isOnline),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: Text(
//                                   user['name'] ?? 'Unknown User',
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.w600,
//                                     fontSize: 16,
//                                     color: Get.theme.textTheme.bodyLarge?.color,
//                                   ),
//                                 ),
//                               ),
//                               // Mutual follow indicator
//                               if (isMutualFollow)
//                                 Container(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 6,
//                                     vertical: 2,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: const Color.fromRGBO(244, 135, 6, 1),
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   child: Row(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       Icon(
//                                         Icons.verified,
//                                         color: Colors.white,
//                                         size: 12,
//                                       ),
//                                       const SizedBox(width: 2),
//                                       Text(
//                                         'Mutual',
//                                         style: TextStyle(
//                                           color: Colors.white,
//                                           fontSize: 10,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               // Recent user indicator
//                               if (isRecentUser)
//                                 Container(
//                                   margin: EdgeInsets.only(left: isMutualFollow ? 4 : 0),
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 6,
//                                     vertical: 2,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: Colors.blue,
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   child: const Text(
//                                     'Recent',
//                                     style: TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 10,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ),
//                             ],
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             isOnline
//                                 ? 'Online'
//                                 : 'Last seen ${controller.formatLastSeen(user['lastSeen'])}',
//                             style: TextStyle(
//                               color: isOnline ? Colors.green : Colors.grey,
//                               fontSize: 12,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: isMutualFollow
//                             ? const Color.fromRGBO(244, 135, 6, 1)
//                             : const Color.fromRGBO(244, 135, 6, 0.1),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Icon(
//                         isMutualFollow ? Icons.chat : Icons.chat_bubble_outline,
//                         color: isMutualFollow
//                             ? Colors.white
//                             : const Color.fromRGBO(244, 135, 6, 1),
//                         size: 20,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       );
//     },
//   );
// }

//   Widget _buildUserAvatar(Map<String, dynamic> user, bool isOnline) {
//   return EnhancedUserAvatar(
//     user: user,
//     radius: 30,
//     isOnline: isOnline,
//     showOnlineIndicator: true,
//     heroTag: 'add_chat_avatar_${user['id'] ?? user['userId'] ?? 'unknown'}',
//   );
// }

//   Widget _buildActionButton(Map<String, dynamic> user, bool isInChatList) {
//   if (isInChatList) {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             const Color.fromRGBO(244, 135, 6, 1),
//             const Color.fromRGBO(255, 152, 0, 1),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(25),
//         boxShadow: [
//           BoxShadow(
//             color: const Color.fromRGBO(244, 135, 6, 0.3),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: () => _openExistingChat(user),
//           borderRadius: BorderRadius.circular(25),
//           child: Container(
//             padding: const EdgeInsets.all(12),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: const [
//                 Icon(
//                   Icons.chat,
//                   color: Colors.white,
//                   size: 16,
//                 ),
//                 SizedBox(width: 4),
//                 Text(
//                   'Chat',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 12,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//      return Container(
//     decoration: BoxDecoration(
//       gradient: LinearGradient(
//         colors: [
//           Colors.green,
//           Colors.green.shade600,
//         ],
//       ),
//       borderRadius: BorderRadius.circular(25),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.green.withAlpha(30),
//           blurRadius: 8,
//           offset: const Offset(0, 2),
//         ),
//       ],
//     ),
//     child: Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: () => _addToChat(user),
//         borderRadius: BorderRadius.circular(25),
//         child: Container(
//           padding: const EdgeInsets.all(12),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: const [
//               Icon(
//                 Icons.add,
//                 color: Colors.white,
//                 size: 16,
//               ),
//               SizedBox(width: 4),
//               Text(
//                 'Add',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 12,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     ),
//   );
//   }

//   Widget _buildLoadingState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const CircularProgressIndicator(
//             color: Color.fromRGBO(244, 135, 6, 1),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'Loading users...',
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.grey.shade600,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Please wait while we fetch all users',
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey.shade500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(24),
//             decoration: BoxDecoration(
//               color: const Color.fromRGBO(244, 135, 6, 0.1),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(
//               Icons.people_outline,
//               size: 64,
//               color: Color.fromRGBO(244, 135, 6, 1),
//             ),
//           ),
//           const SizedBox(height: 24),
//           Text(
//             'No users found',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey.shade700,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'There are no users available to add to chat',
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey.shade500,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 24),
//           ElevatedButton.icon(
//             onPressed: () => controller.refreshUsersAndCache(),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(25),
//               ),
//               elevation: 4,
//             ),
//             icon: const Icon(Icons.refresh),
//             label: const Text('Refresh'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _handleUserSelection(Map<String, dynamic> user, bool isInChatList) {
//     if (isInChatList) {
//       _openExistingChat(user);
//     } else {
//       _addToChat(user);
//     }
//   }

//   void _addToChat(Map<String, dynamic> user) {
//     final userName = user['name']?.toString() ?? 'Unknown User';
    
//     Get.dialog(
//       AlertDialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         title: Row(
//           children: [
//             CircleAvatar(
//               radius: 20,
//               backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
//               backgroundImage: user['photoURL'] != null && user['photoURL'].toString().isNotEmpty
//                   ? NetworkImage(user['photoURL'].toString())
//                   : null,
//               child: user['photoURL'] == null || user['photoURL'].toString().isEmpty
//                   ? Text(
//                       userName.substring(0, 1).toUpperCase(),
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     )
//                   : null,
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Add to Chat',
//                     style: TextStyle(fontSize: 18),
//                   ),
//                   Text(
//                     userName,
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey.shade600,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         content: Text(
//           'Do you want to start a conversation with $userName? This will add them to your chat list.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(),
//             child: Text(
//               'Cancel',
//               style: TextStyle(color: Colors.grey.shade600),
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Get.back();
//               _startConversation(user);
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             child: const Text('Add to Chat'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _startConversation(Map<String, dynamic> user) async {
//   final userName = user['name']?.toString() ?? 'Unknown User';
  
//   try {
//     // Add user to chat (this will now also add to recent users)
//     await controller.addUserToChat(user);
    
//     // Show success feedback
//     // Get.snackbar(
//     //   'Added to Chat',
//     //   '$userName has been added to your chat list and recent users',
//     //   snackPosition: SnackPosition.BOTTOM,
//     //   backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
//     //   colorText: Colors.white,
//     //   duration: const Duration(seconds: 2),
//     //   margin: const EdgeInsets.all(16),
//     //   borderRadius: 8,
//     //   icon: const Icon(
//     //     Icons.check_circle,
//     //     color: Colors.white,
//     //   ),
//     // );

//     // Navigate to chat with the user
//     controller.navigateToChat(user);
    
//   } catch (e) {
//     // Show error if something goes wrong
//     Get.snackbar(
//       'Error',
//       'Failed to add $userName to chat. Please try again.',
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: Colors.red.withAlpha(80),
//       colorText: Colors.white,
//       duration: const Duration(seconds: 3),
//       margin: const EdgeInsets.all(16),
//       borderRadius: 8,
//       icon: const Icon(
//         Icons.error,
//         color: Colors.white,
//       ),
//     );
//   }
// }

//   void _openExistingChat(Map<String, dynamic> user) {
//   final userName = user['name']?.toString() ?? 'Unknown User';
  
//   // Add to recent users even when opening existing chat
//   controller.addUserToRecent(user);
  
//   Get.snackbar(
//     'Opening Chat',
//     'Opening conversation with $userName',
//     snackPosition: SnackPosition.BOTTOM,
//     backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
//     colorText: Colors.white,
//     duration: const Duration(seconds: 1),
//     margin: const EdgeInsets.all(16),
//     borderRadius: 8,
//   );

//   // Navigate to existing chat
//   controller.navigateToChat(user);
// }
// }