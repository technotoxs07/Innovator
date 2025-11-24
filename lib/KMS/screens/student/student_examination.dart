import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/screens/constant_screen/custom_scroll.dart';

class StudentExaminationScreen extends ConsumerStatefulWidget {
  const StudentExaminationScreen({super.key});
  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _StudentExaminationScreen();
}

class _StudentExaminationScreen extends ConsumerState<StudentExaminationScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrolling(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Examination',
            style: TextStyle(fontFamily: 'Inter', fontSize: 16),
          ),
          Text('View Upcoming exam, attempt quizzes and check your result.'),
          SizedBox(height: 15),

          listTile('Upcoming Exams', '4', 'assets/kms/upcoming_exams.png'),
          listTile(
            'Completed',
            '1',
            'assets/kms/right.png',
            color: Colors.green,
          ),
          listTile('Current Score', '8/10', 'assets/kms/current_score.png'),
          listTile('Average', '80.0 %', 'assets/kms/average.png'),
          SizedBox(
            height: 20,
          ),
          belowContainer()
        ],
      ),
    );
  }

  Widget listTile(
    String title,
    String subtitle,
    String trailingImage, {
    Color? color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Material(
          borderRadius: BorderRadius.circular(19),
          elevation: 3,
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(19),
            ),
            tileColor: Colors.white,

            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                color: Colors.black,
                fontSize: 14,
              ),
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(top: 10, left: 85, bottom: 5),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.black,
                ),
              ),
            ),
            trailing: Image.asset(trailingImage, color: color),
          ),
        ),
        SizedBox(height: 12),
      ],
    );
  }

  Widget belowContainer() {
    return Container(decoration: BoxDecoration(color: Colors.white));
  }
}
