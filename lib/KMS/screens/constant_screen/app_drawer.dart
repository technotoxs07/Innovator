import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/constants/app_style.dart';
import 'package:innovator/KMS/constants/mediaquery.dart';
import 'package:innovator/KMS/screens/auth/login_screen.dart';


 enum ComplaintStatus { complaint, resolved}
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      width: context.screenWidth * 0.7,
      backgroundColor: AppStyle.primaryColor,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(right: 10, left: 10, top: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  'assets/kms/school.png',
                  height: 50,
                  width: 50,
                ),
              ),

              SizedBox(height: 20),
              Card(
                elevation: 10,

                color: AppStyle.primaryColor,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.white),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    right: 10,
                    left: 10,
                    top: 15,
                    bottom: 15,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.home_sharp, color: Colors.white),
                      SizedBox(width: 15),
                      Text(
                        'Dashboard',
                        style: AppStyle.bodyText.copyWith(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xffFEFCE8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
              _drawer(context, 0, 'Tutor',  'assets/kms/drawer/tutor.png'),
              _drawer(context, 1, 'School',  'assets/kms/drawer/school.png'),
              _drawer(context, 2, 'Examination', 'assets/kms/drawer/examination.png'),
              _drawer(context, 3, 'Attendance',  'assets/kms/drawer/attendance.png'),
              _drawer(context, 4, 'Activities',  'assets/kms/drawer/activities.png'),
              _drawer(context, 5, 'Teacher KYC',  'assets/kms/drawer/teacher.png'),
              _drawer(
                context,
                6,
                'Salary + Commission Partner',
                'assets/kms/drawer/salary.png'
              ),
              _drawer(
                context,
                7,
                'Components Delivery',
                'assets/kms/drawer/components.png'
              ),
              _drawer(context, 8, 'Complain Box',  'assets/kms/drawer/complainBox.png'),
              _drawer(context, 9, 'Teacher Learning Material',  'assets/kms/drawer/teaching.png'),
              _drawer(
                context,
                10,
                'Progress Tracking',
              'assets/kms/drawer/progresstracking.png',
              ),
              SizedBox(height: context.screenHeight * 0.1),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(10),
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
                                    // Navigaton for the logout

                                    // this auth service is the one for saving the accesstoken clear that one
                                    //  AuthService().logout();
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
                label: Text('Log Out', style: TextStyle(color: Colors.red)),
                icon: Icon(Icons.logout_outlined, color: Colors.red),
              ),
              SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawer(BuildContext context, int id, String title, String  image) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(image),
              SizedBox(width:20),
            Flexible(
              child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                // fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                // color: Colors.white,
                color: Color(0xffFEFCE8),
              ),
                        ),
            ),
            ],
          ),
        ),
        SizedBox(height: 20,),
        Divider(color: Colors.grey.shade200),
        SizedBox(height: 6,)
      ],
    );
  }
}
