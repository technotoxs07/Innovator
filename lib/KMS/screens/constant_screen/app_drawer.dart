import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/constants/app_style.dart';
import 'package:innovator/KMS/constants/mediaquery.dart';
import 'package:innovator/KMS/screens/auth/login_screen.dart';
import 'package:innovator/KMS/screens/constant_screen/under_maintenance_page.dart';
import 'package:innovator/KMS/screens/dashboard/partner_dashboard_screen.dart';
import 'package:innovator/KMS/screens/dashboard/school_dashboard_screen.dart';
import 'package:innovator/KMS/screens/partner/partner_assigned_school.dart';
import 'package:innovator/KMS/screens/student/student_examination.dart';

final drawerSelectedIndexProvider = StateProvider<int>((ref) => 0);

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  static const List<DrawerItemData> drawerItems = [

    DrawerItemData(
      title: 'Tutor',
      image: 'assets/kms/drawer/tutor.png',
      screen: PartnerDashboardScreen(),
    ),
    DrawerItemData(
      title: 'School',
      image: 'assets/kms/drawer/school.png',
      screen: SchoolDashboardScreen(),
    ),
    DrawerItemData(
      title: 'Examination',
      image: 'assets/kms/drawer/examination.png',
      screen: StudentExaminationScreen(),
    ),
    DrawerItemData(
      title: 'Attendance',
      image: 'assets/kms/drawer/attendance.png',
      screen: PartnerAssignedSchoolScreen(),
    ),
    DrawerItemData(
      title: 'Activities',
      image: 'assets/kms/drawer/activities.png',
      screen: UnderMaintenanceScreen(),
    ),
    DrawerItemData(
      title: 'Teacher KYC',
      image: 'assets/kms/drawer/teacher.png',
      screen: UnderMaintenanceScreen(),
    ),
    DrawerItemData(
      title: 'Salary + Commission Partner',
      image: 'assets/kms/drawer/salary.png',
      screen: UnderMaintenanceScreen(),
    ),
    DrawerItemData(
      title: 'Components Delivery',
      image: 'assets/kms/drawer/components.png',
      screen: UnderMaintenanceScreen(),
    ),
    DrawerItemData(
      title: 'Complain Box',
      image: 'assets/kms/drawer/complainBox.png',
      screen: UnderMaintenanceScreen(),
    ),
    DrawerItemData(
      title: 'Teacher Learning Material',
      image: 'assets/kms/drawer/teaching.png',
      screen: UnderMaintenanceScreen(),
    ),
    DrawerItemData(
      title: 'Progress Tracking',
      image: 'assets/kms/drawer/progresstracking.png',
      screen: UnderMaintenanceScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(drawerSelectedIndexProvider);

    return Drawer(
      width: context.screenWidth * 0.7,
      backgroundColor: AppStyle.primaryColor,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(right: 10, left: 10, top: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  'assets/kms/school.png',
                  height: 60,
                  width: 60,
                ),
              ),
              const SizedBox(height: 30),

              ...List.generate(drawerItems.length, (index) {
                    final item = drawerItems[index];
                    final isSelected = selectedIndex == index;

                    return _buildDrawerItem(
                      context: context,
                      ref: ref,
                      index: index,
                      title: item.title,
                      image: item.image,
                      isSelected: isSelected,
                      screen: item.screen,
                    );
                  })
                  .expand((widget) => [widget, const SizedBox(height: 8)])
                  .toList(),

              const SizedBox(height: 20),

              // Logout Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.white,
                ),
                onPressed: () {
                  showAdaptiveDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        backgroundColor: AppStyle.alertDialogColor,
                        title: Icon(Icons.logout, size: 50),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: 10),
                            Text('Comeback Soon!', style: AppStyle.heading2),
                            SizedBox(height: 20),
                            Text(
                              'Are you sure you want to Logout?',
                              style: TextStyle(
                                color: Colors.black45,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    if (Navigator.canPop(context)) {
                                      Navigator.pop(context);
                                    } else {
                                      return;
                                    }
                                  },
                                  child: Text(
                                    'Cancel',
                                    style: AppStyle.errorText,
                                  ),
                                ),
                                SizedBox(width: 20),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    minimumSize: Size(20, 40),
                                    backgroundColor: AppStyle.buttonColor,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => const LoginScreen(),
                                      ),
                                      (Route<dynamic> route) => false,
                                    );
                                  },
                                  child: Text(
                                    'Yes Logout',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                label: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                icon: const Icon(Icons.logout_outlined, color: Colors.red),
              ),
              const SizedBox(height: 20),
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
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.pop(context);

            if (!isSelected) {
              ref.read(drawerSelectedIndexProvider.notifier).state = index;
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => screen),
              );
            }
          },
          child: Container(
            padding: EdgeInsets.only(top: 10, bottom: 10, right: 10, left: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppStyle.primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border:
                  isSelected
                      ? Border.all(color: Colors.white, width: 1.5)
                      : null,
            ),
            child: Row(
              children: [
                Image.asset(
                  image,
                  width: 30,
                  height: 30,
                  color: isSelected ? Colors.white : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected
                              ? AppStyle.bodyTextColor
                              : AppStyle.bodyTextColor,
                      fontFamily: 'Inter',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(color: Colors.grey.shade300, height: 20, thickness: 0.5),
      ],
    );
  }
}

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
