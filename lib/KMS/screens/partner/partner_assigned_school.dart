import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/screens/constant_screen/custom_scroll.dart';

class PartnerAssignedSchoolScreen extends ConsumerWidget {
  const PartnerAssignedSchoolScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrolling(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Assigned Schools',
            style: TextStyle(fontFamily: 'Inter', fontSize: 15),
          ),
          Text(
            'Managing 3 schools • 500 total students',
            style: TextStyle(color: Color(0xff999999), fontSize: 12),
          ),
          SizedBox(height: 10),
          GridView(
            shrinkWrap: true, 
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.6,
              crossAxisSpacing: 30,
              mainAxisSpacing: 20,
            ),
            children: [
              cardContainer(
                'assets/kms/total_schools.png',
                'Total Schools',
                '3',
                color: Color(0xff2C62EE),
              ),
              cardContainer(
                'assets/kms/total_students.png',
                'Total Students',
                '1500',
                color: Color(0xff0CC740),
              ),
              cardContainer(
                'assets/kms/pending_review.png',
                'Weekly hours',
                '37',
                color: Color(0xffFB923C),
              ),
              cardContainer(
                'assets/kms/assignment.png',
                'Pending Task',
                '6',
                color: Color(0xffF93333),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget cardContainer(
    String image,
    String title,
    String numbers, {
    Color? color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      elevation: 3,
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.only(right: 10, left: 10),
        child: FittedBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Image.asset(image, color: color),
                  SizedBox(width: 8),
                  Text(title, style: TextStyle(fontSize: 14, color: color)),
                ],
              ),
              SizedBox(height: 10),
              Text(
                numbers,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
