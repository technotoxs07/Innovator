// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:innovator/KMS/core/constants/app_style.dart';
// import 'package:innovator/KMS/core/constants/mediaquery.dart';
// import 'package:innovator/KMS/screens/auth/login_screen.dart';
// import 'package:innovator/KMS/screens/constant_screen/under_maintenance_page.dart';
// import 'package:innovator/KMS/screens/dashboard/partner_dashboard_screen.dart';
// import 'package:innovator/KMS/screens/dashboard/school_dashboard_screen.dart';
// import 'package:innovator/KMS/screens/partner/kyc_upload_screen.dart';
// import 'package:innovator/KMS/screens/partner/partner_assigned_school.dart';
// import 'package:innovator/KMS/screens/student/student_examination.dart';

// final drawerSelectedIndexProvider = StateProvider<int>((ref) => 0);

// class AppDrawer extends ConsumerWidget {
//   const AppDrawer({super.key});

//   static const List<DrawerItemData> drawerItems = [

//     DrawerItemData(
//       title: 'Tutor',
//       image: 'assets/kms/drawer/tutor.png',
//       screen: TeacherDashboardScreen(),
//     ),
//     DrawerItemData(
//       title: 'School',
//       image: 'assets/kms/drawer/school.png',
//       screen: SchoolDashboardScreen(),
//     ),
//     DrawerItemData(
//       title: 'Examination',
//       image: 'assets/kms/drawer/examination.png',
//       screen: StudentExaminationScreen(),
//     ),
//     DrawerItemData(
//       title: 'Attendance',
//       image: 'assets/kms/drawer/attendance.png',
//       screen: PartnerAssignedSchoolScreen(),
//     ),
//     DrawerItemData(
//       title: 'Activities',
//       image: 'assets/kms/drawer/activities.png',
//       screen: UnderMaintenanceScreen(),
//     ),
//     DrawerItemData(
//       title: 'Teacher KYC',
//       image: 'assets/kms/drawer/teacher.png',
//       screen: KycUploadScreen(),
//     ),
//     DrawerItemData(
//       title: 'Salary + Commission Partner',
//       image: 'assets/kms/drawer/salary.png',
//       screen: UnderMaintenanceScreen(),
//     ),
//     DrawerItemData(
//       title: 'Components Delivery',
//       image: 'assets/kms/drawer/components.png',
//       screen: UnderMaintenanceScreen(),
//     ),
//     DrawerItemData(
//       title: 'Complain Box',
//       image: 'assets/kms/drawer/complainBox.png',
//       screen: UnderMaintenanceScreen(),
//     ),
//     DrawerItemData(
//       title: 'Teacher Learning Material',
//       image: 'assets/kms/drawer/teaching.png',
//       screen: UnderMaintenanceScreen(),
//     ),
//     DrawerItemData(
//       title: 'Progress Tracking',
//       image: 'assets/kms/drawer/progresstracking.png',
//       screen: UnderMaintenanceScreen(),
//     ),
//   ];

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final selectedIndex = ref.watch(drawerSelectedIndexProvider);

//     return Drawer(
//       width: context.screenWidth * 0.7,
//       backgroundColor: AppStyle.primaryColor,
//       child: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.only(right: 10, left: 10, top: 25),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Center(
//                 child: Image.asset(
//                   'assets/kms/school.png',
//                   height: 60,
//                   width: 60,
//                 ),
//               ),
//               const SizedBox(height: 30),

//               ...List.generate(drawerItems.length, (index) {
//                     final item = drawerItems[index];
//                     final isSelected = selectedIndex == index;

//                     return _buildDrawerItem(
//                       context: context,
//                       ref: ref,
//                       index: index,
//                       title: item.title,
//                       image: item.image,
//                       isSelected: isSelected,
//                       screen: item.screen,
//                     );
//                   })
//                   .expand((widget) => [widget, const SizedBox(height: 8)])
//                   .toList(),

//               const SizedBox(height: 20),

//               // Logout Button
//               ElevatedButton.icon(
//                 style: ElevatedButton.styleFrom(
//                   minimumSize: const Size(double.infinity, 50),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   backgroundColor: Colors.white,
//                 ),
//                 onPressed: () {
//                   showAdaptiveDialog(
//                     context: context,
//                     builder: (context) {
//                       return AlertDialog(
//                         backgroundColor: AppStyle.alertDialogColor,
//                         title: Icon(Icons.logout, size: 50),
//                         content: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             SizedBox(height: 10),
//                             Text('Comeback Soon!', style: AppStyle.heading2),
//                             SizedBox(height: 20),
//                             Text(
//                               'Are you sure you want to Logout?',
//                               style: TextStyle(
//                                 color: Colors.black45,
//                                 fontSize: 16,
//                               ),
//                             ),
//                             SizedBox(height: 10),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 TextButton(
//                                   onPressed: () {
//                                     if (Navigator.canPop(context)) {
//                                       Navigator.pop(context);
//                                     } else {
//                                       return;
//                                     }
//                                   },
//                                   child: Text(
//                                     'Cancel',
//                                     style: AppStyle.errorText,
//                                   ),
//                                 ),
//                                 SizedBox(width: 20),
//                                 ElevatedButton(
//                                   style: ElevatedButton.styleFrom(
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(15),
//                                     ),
//                                     minimumSize: Size(20, 40),
//                                     backgroundColor: AppStyle.buttonColor,
//                                   ),
//                                   onPressed: () {
//                                     Navigator.of(context).pop();
//                                     Navigator.pushAndRemoveUntil(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder:
//                                             (context) => const LoginScreen(),
//                                       ),
//                                       (Route<dynamic> route) => false,
//                                     );
//                                   },
//                                   child: Text(
//                                     'Yes Logout',
//                                     style: TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 16,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   );
//                 },
//                 label: const Text(
//                   'Log Out',
//                   style: TextStyle(
//                     color: Colors.red,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 icon: const Icon(Icons.logout_outlined, color: Colors.red),
//               ),
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDrawerItem({
//     required BuildContext context,
//     required WidgetRef ref,
//     required int index,
//     required String title,
//     required String image,
//     required bool isSelected,
//     required Widget screen,
//   }) {
//     return Column(
//       children: [
//         GestureDetector(
//           onTap: () {
//             Navigator.pop(context);

//             if (!isSelected) {
//               ref.read(drawerSelectedIndexProvider.notifier).state = index;
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => screen),
//               );
//             }
//           },
//           child: Container(
//             padding: EdgeInsets.only(top: 10, bottom: 10, right: 10, left: 10),
//             decoration: BoxDecoration(
//               color: isSelected ? AppStyle.primaryColor : Colors.transparent,
//               borderRadius: BorderRadius.circular(12),
//               border:
//                   isSelected
//                       ? Border.all(color: Colors.white, width: 1.5)
//                       : null,
//             ),
//             child: Row(
//               children: [
//                 Image.asset(
//                   image,
//                   width: 30,
//                   height: 30,
//                   color: isSelected ? Colors.white : null,
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Text(
//                     title,
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       color:
//                           isSelected
//                               ? AppStyle.bodyTextColor
//                               : AppStyle.bodyTextColor,
//                       fontFamily: 'Inter',
//                     ),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         Divider(color: Colors.grey.shade300, height: 20, thickness: 0.5),
//       ],
//     );
//   }
// }

// class DrawerItemData {
//   final String title;
//   final String image;
//   final Widget screen;

//   const DrawerItemData({
//     required this.title,
//     required this.image,
//     required this.screen,
//   });
// }



import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/core/constants/mediaquery.dart';
import 'package:innovator/KMS/provider/user_provider.dart';
import 'package:innovator/KMS/screens/auth/login_screen.dart';
import 'package:innovator/KMS/screens/coordinator/coordinator_attendance_approval_screen.dart';
import 'package:innovator/KMS/screens/coordinator/coordinator_payment_invoice_screen.dart';
import 'package:innovator/KMS/screens/coordinator/coordinator_teacher_progrees_screen.dart';
import 'package:innovator/KMS/screens/dashboard/coordinator_dashboard_screen.dart'; 
import 'package:innovator/KMS/screens/dashboard/partner_dashboard_screen.dart';
import 'package:innovator/KMS/screens/dashboard/school_dashboard_screen.dart';
import 'package:innovator/KMS/screens/constant_screen/under_maintenance_page.dart';
import 'package:innovator/KMS/screens/dashboard/student_dashboard_screen.dart';
import 'package:innovator/KMS/screens/teacher/kyc_upload_screen.dart';
import 'package:innovator/KMS/screens/student/student_examination.dart';
import 'package:innovator/KMS/screens/teacher/teacher_salary_screen.dart';
import 'package:innovator/KMS/screens/teacher/teacher_school_attendance.dart'; 
final drawerSelectedIndexProvider = StateProvider<int>((ref) => 0);

class DrawerItemData {
  final String title;
  final String image;
  final Widget screen;
  const DrawerItemData({
    required this.title,
    required this.image,
    required this.screen,
  });
}

const List<DrawerItemData> _teacherDrawerItems = [
  DrawerItemData(
    title: 'Dashboard',
    image: 'assets/kms/drawer/tutor.png',
    screen: TeacherDashboardScreen(),
  ),
  DrawerItemData(
    title: 'Attendance',
    image: 'assets/kms/drawer/attendance.png',
    screen: TeacherSchoolAttendanceScreen(),
  ),
  DrawerItemData(
    title: 'Salary Slips',
    image: 'assets/kms/drawer/salary.png',
    screen: TeacherSalaryScreen(),
  ),
  DrawerItemData(
    title: 'KYC Verification',
    image: 'assets/kms/drawer/teacher.png',
    screen: KycUploadScreen(),
  ),
  DrawerItemData(
    title: 'Progress Tracking',
    image: 'assets/kms/drawer/progresstracking.png',
    screen: UnderMaintenanceScreen(),
  ),
];

const List<DrawerItemData> _coordinatorDrawerItems = [
  DrawerItemData(
    title: 'Dashboard',
    image: 'assets/kms/drawer/tutor.png',
    screen: CoordinatorDashboardScreen(),
  ),
  DrawerItemData(
    title: 'Teacher Progress',
    image: 'assets/kms/drawer/progresstracking.png',
    screen: CoordinatorTeacherProgressScreen(),
  ),
  DrawerItemData(
    title: 'Attendance Approval',
    image: 'assets/kms/drawer/attendance.png',
    screen: CoordinatorAttendanceApprovalScreen(),
  ),
  DrawerItemData(
    title: 'Payment Invoice',
    image: 'assets/kms/drawer/salary.png',
    screen: CoordinatorPaymentInvoiceScreen(),
  ),
  DrawerItemData(
    title: 'Schools',
    image: 'assets/kms/drawer/school.png',
    screen: SchoolDashboardScreen(),
  ),
  DrawerItemData(
    title: 'Complain Box',
    image: 'assets/kms/drawer/complainBox.png',
    screen: UnderMaintenanceScreen(),
  ),
];

const List<DrawerItemData> _studentDrawerItems = [
  DrawerItemData(
    title: 'Dashboard',
    image: 'assets/kms/drawer/tutor.png',
    screen: StudentDashboardScreen(),
  ),
  DrawerItemData(
    title: 'My Attendance',
    image: 'assets/kms/drawer/attendance.png',
    screen: StudentDashboardScreen(),
  ),
  DrawerItemData(
    title: 'Examination',
    image: 'assets/kms/drawer/examination.png',
    screen: StudentExaminationScreen(),
  ),
  DrawerItemData(
    title: 'Activities',
    image: 'assets/kms/drawer/activities.png',
    screen: UnderMaintenanceScreen(),
  ),
];

// ─── AppDrawer ──────────────────────────────────────────────────────────────

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  List<DrawerItemData> _getItemsForRole(String role) {
    switch (role.toLowerCase()) {
      case 'coordinator':
        return _coordinatorDrawerItems;
      case 'student':
        return _studentDrawerItems;
      case 'teacher':
      default:
        return _teacherDrawerItems;
    }
  }

  String _getRoleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'coordinator':
        return 'Coordinator';
      case 'student':
        return 'Student';
      default:
        return 'Teacher';
    }
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(drawerSelectedIndexProvider);
    final userAsync = ref.watch(userDetailsProvider);

    return userAsync.when(
      loading: () => _buildDrawerShell(
        context: context,
        ref: ref,
        selectedIndex: selectedIndex,
        role: 'teacher',
        username: '',
        email: '',
        items: _teacherDrawerItems,
        isLoading: true,
      ),
      error: (_, __) => _buildDrawerShell(
        context: context,
        ref: ref,
        selectedIndex: selectedIndex,
        role: 'teacher',
        username: 'User',
        email: '',
        items: _teacherDrawerItems,
        isLoading: false,
      ),
      data: (user) => _buildDrawerShell(
        context: context,
        ref: ref,
        selectedIndex: selectedIndex,
        role: user.role,
        username: user.username,
        email: user.email,
        items: _getItemsForRole(user.role),
        isLoading: false,
      ),
    );
  }

  Widget _buildDrawerShell({
    required BuildContext context,
    required WidgetRef ref,
    required int selectedIndex,
    required String role,
    required String username,
    required String email,
    required List<DrawerItemData> items,
    required bool isLoading,
  }) {
    final roleLabel = _getRoleLabel(role);

    return Drawer(
      width: context.screenWidth * 0.72,
      backgroundColor: AppStyle.primaryColor,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(right: 10, left: 10, top: 35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 10),
                    if (isLoading)
                      Container(
                        width: 100,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      )
                    else ...[
                      Text(
                        username.isNotEmpty ? username : 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          roleLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Divider(color: Colors.white.withValues(alpha: 0.2), thickness: 1),
              const SizedBox(height: 12),

              // ── Drawer Items ──
              ...List.generate(items.length, (index) {
                final item = items[index];
                final isSelected = selectedIndex == index;
                return Column(
                  children: [
                    _buildDrawerItem(
                      context: context,
                      ref: ref,
                      index: index,
                      title: item.title,
                      image: item.image,
                      isSelected: isSelected,
                      screen: item.screen,
                    ),
                    const SizedBox(height: 6),
                  ],
                );
              }),

              const SizedBox(height: 20),

              // ── Logout ──
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.white,
                  elevation: 0,
                ),
                onPressed: () => _showLogoutDialog(context),
                label: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                  ),
                ),
                icon: const Icon(Icons.logout_outlined, color: Colors.red),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required WidgetRef ref,
    required int index,
    required String title,
    required String image,
    required bool isSelected,
    required Widget screen,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        if (!isSelected) {
          ref.read(drawerSelectedIndexProvider.notifier).state = index;
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.2)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: Image.asset(image, color: Colors.white),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: Colors.white,
                  fontFamily: 'Inter',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showAdaptiveDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppStyle.alertDialogColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.logout_rounded, size: 50, color: Colors.red),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text('Comeback Soon!', style: AppStyle.heading2),
            const SizedBox(height: 12),
            const Text(
              'Are you sure you want to Logout?',
              style: TextStyle(color: Colors.black45, fontSize: 15, fontFamily: 'Inter'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: AppStyle.errorText),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(110, 44),
                    backgroundColor: AppStyle.buttonColor,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const KmsLoginScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text('Yes, Logout',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Inter')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}