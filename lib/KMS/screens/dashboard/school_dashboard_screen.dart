import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/constants/app_style.dart';
import 'package:innovator/KMS/constants/mediaquery.dart';
import 'package:innovator/KMS/screens/constant_screen/custom_scroll.dart';

class SchoolDashboardScreen extends ConsumerWidget {
  const SchoolDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return   CustomScrolling(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
             
            
          // Grid Content
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.4,
              crossAxisSpacing: 10,
            
              mainAxisSpacing: 10,
            ),
            
            children: [
              //Attendance Rate
              FittedBox(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  color: Colors.white,
                  elevation: 5,
                  child: Padding(
                    padding: EdgeInsets.only(right: 10, left: 10, top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attendance Rate',
                          style: AppStyle.heading2.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: AppStyle.fontFamilySecondary,
                            fontSize: 15,
                          ),
                        ),
                            
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomPaint(
                              painter: AttendanceRate(
                                percentage:
                                    95, //pass the backend value later when it comes from the backends
                              ),
                              size: Size(
                                context.screenWidth * 0.2,
                                context.screenHeight * 0.1,
                              ),
                            ),
                            
                            Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '95%',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  Text(
                                    'This week',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              //Tutor Performance
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                color: Colors.white,
                elevation: 5,
                child: Padding(
                  padding: EdgeInsets.only(
                    right: 17,
                    left: 17,
                    top: 10,
                    bottom: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        child: Text(
                          'Tutor Performance',
                          style: AppStyle.heading2.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: AppStyle.fontFamilySecondary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      SizedBox(height: context.screenHeight * 0.009),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              CupertinoIcons.star_fill,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '4.6/',
                                    style: TextStyle(fontFamily: 'Inter'),
                                  ),
            
                                  Text(
                                    '5'.padLeft(2),
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Avg Rating',
                                style: TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              //Course Progress
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                color: Colors.white,
                elevation: 5,
                child: Padding(
                  padding: EdgeInsets.only(right: 15, left: 15, top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        child: Text(
                          'Course Progress',
                          style: AppStyle.heading2.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: AppStyle.fontFamilySecondary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      SizedBox(height: 13),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            height: 43,
                            width: 7,
                            decoration: BoxDecoration(
                              color: AppStyle.primaryColor,
                            ),
                          ),
                          SizedBox(width: 4),
                          Container(
                            height: 24,
                            width: 7,
                            decoration: BoxDecoration(
                              color: AppStyle.primaryColor,
                            ),
                          ),
                          SizedBox(width: 4),
                          Container(
                            height: 15,
                            width: 7,
                            decoration: BoxDecoration(
                              color: AppStyle.primaryColor,
                            ),
                          ),
                          SizedBox(width: 4),
                          Container(
                            height: 7,
                            width: 7,
                            decoration: BoxDecoration(
                              color: AppStyle.primaryColor,
                            ),
                          ),
                          Spacer(),
                          Column(
                            children: [
                              Text(
                                '8',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: AppStyle.fontFamilySecondary,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Active Courses',
                                style: TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Complaints Pending
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                color: Colors.white,
                elevation: 5,
                child: Padding(
                  padding: EdgeInsets.only(right: 15, left: 15, top: 10),
                  child: Column(
                    children: [
                      FittedBox(
                        child: Text(
                          'Complaints Pending',
                          style: AppStyle.heading2.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: AppStyle.fontFamilySecondary,
                            fontSize: 15,
                          ),
                        ),
                      ),
            
                      SizedBox(height: 22),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '8',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Unresolved',
                            style: TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20,),
         
          // Attendance & Exams Container
          Container(
            width: double.infinity,
            height: 270,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                right: 8,
                left: 8,
                top: 10,
                bottom: 5,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Attendance & Exams',
                      style: TextStyle(fontSize: 20, fontFamily: 'Inter'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.black),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                          child: Text('Class 1- Attendance'),
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.filter_alt,
                          color: AppStyle.primaryColor,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _attendanceExamsTable(),
                    ),
                  ),
                ],
              ),
            ),
          ),
            
          SizedBox(height: 30),
          // Bills & Accounting Container
          Container(
            width: double.infinity,
            height: 270,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  right: 8,
                  left: 8,
                  top: 4,
                  bottom: 5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'Bills & Accounting',
                        style: TextStyle(fontSize: 20, fontFamily: 'Inter'),
                      ),
                    ),
                    SizedBox(height: 15),
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
            
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.9,
                            crossAxisSpacing: 10,
            
                            mainAxisSpacing: 10,
                          ),
                      children: [
                        _billCard(
                          '35000',
                          'assets/kms/money_bag.png',
                          'Paid This Month',
                        ),
                        _billCard(
                          '12000',
                          'assets/kms/money_bag.png',
                          'Pending Dues',
                        ),
                      ],
                    ),
                    FittedBox(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            color: Colors.white,
                            elevation: 5,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 13,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '2 days Ago',
                                    style: TextStyle(
                                      fontFamily:
                                          AppStyle.fontFamilySecondary,
                                      fontSize: 15,
                                    ),
                                  ),
                                  
                                  SizedBox(height: 15),
                                  Text('Paid This Month'),
                                ],
                              ),
                            ),
                          ),
                                  
                        SizedBox(width: 30,),
                          GestureDetector(
                            onTap: (){
                              //  // Use the navigation to show the all invoices
                            },
                            child: Container(
                              height: 50,
                              padding: EdgeInsets.only(right: 10,left: 10),
                              decoration: BoxDecoration(
                                color: AppStyle.primaryColor,
                                borderRadius: BorderRadius.circular(10)
                              ),
                               child: Center(
                                 child: const Text(
                                  'View All Invoices',
                                  style: TextStyle(color: AppStyle.bodyTextColor),
                                                           ),
                               ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
            
          SizedBox(height: 30),
          // Tutor Monitoring Container
          Container(
            width: double.infinity,
            height: 270,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                right: 8,
                left: 8,
                top: 10,
                bottom: 5,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tutor Monitoring',
                    style: TextStyle(fontSize: 20, fontFamily: 'Inter'),
                  ),
                  SizedBox(height: 15),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _tutorMonitoringTable(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ));
  }

  //bill Card
  Widget _billCard(String amount, String image, String label) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white,
      elevation: 5,
      child: Padding(
        padding: EdgeInsets.only(right: 15, left: 15, top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  amount,
                  style: TextStyle(
                    fontFamily: AppStyle.fontFamilySecondary,
                    fontSize: 15,
                  ),
                ),
                Image.asset(image, width: 38, height: 22),
              ],
            ),
            SizedBox(height: 15),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _attendanceExamsTable() {
    return SingleChildScrollView(
      child: DataTable(
        columnSpacing: 25,
        headingRowHeight: 40,
        dataRowMaxHeight: 50,

        columns: const [
          DataColumn(
            label: Text(
              'Student Name',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Total Classes',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Present',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Absent',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Marks',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
        ],
        rows: [
          _attendanceExamsDataRow('John Doe', '20', '22', '1', '90'),
          _attendanceExamsDataRow('Alice Johnson', '45', '24', '0', '46'),
          _attendanceExamsDataRow('Raju Shrestha', '56', '21', '7', '65'),
          _attendanceExamsDataRow('Ronit Srivastav', '53', '10', '4', '78'),
        ],
      ),
    );
  }

  DataRow _attendanceExamsDataRow(
    String studentName,
    String totalClasses,
    String present,
    String absent,
    String marks,
  ) {
    return DataRow(
      cells: [
        DataCell(Text(studentName, style: TextStyle(fontSize: 11))),
        DataCell(Text(totalClasses, style: TextStyle(fontSize: 11))),
        DataCell(Text(present, style: TextStyle(fontSize: 11))),
        DataCell(Text(absent, style: TextStyle(fontSize: 11))),
        DataCell(Text(marks, style: TextStyle(fontSize: 11))),
      ],
    );
  }

  // Tutor Monitoring Table
  Widget _tutorMonitoringTable() {
    return SingleChildScrollView(
      child: DataTable(
        columnSpacing: 20,
        headingRowHeight: 40,
        dataRowMaxHeight: 50,

        columns: const [
          DataColumn(
            label: Text(
              'Tutor Name',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Total Classes',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Chapter',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Total Student',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Week',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Status',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Complain/ Feedback',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
        ],
        rows: [
          _tutorMonitoringRow(
            'Alice Johnson',
            '20',
            '5',
            '200',
            '5',
            'Approved',
            'Pending',
            'Course is difficult and is not easy to understand',
          ),
          _tutorMonitoringRow(
            'Alice Johnson',
            '20',
            '5',
            '200',
            '5',
            'Approved',
            'Pending',
            'Course is difficult and is not easy to understand',
          ),
          _tutorMonitoringRow(
            'Alice Johnson',
            '20',
            '5',
            '200',
            '5',
            'Approved',
            'Pending',
            'Course is difficult and is not easy to understand',
          ),
          _tutorMonitoringRow(
            'Alice Johnson',
            '20',
            '5',
            '200',
            '5',
            'Approved',
            'Pending',
            'Course is difficult and is not easy to understand',
          ),
          _tutorMonitoringRow(
            'Alice Johnson',
            '20',
            '5',
            '200',
            '5',
            'Approved',
            'Pending',
            'Course is difficult and is not easy to understand',
          ),
        ],
      ),
    );
  }

  DataRow _tutorMonitoringRow(
    String tutorName,
    String totalClasses,
    String chapter,
    String totalStudent,
    String week,
    String status1,
    String status2,
    String complaint,
  ) {
    return DataRow(
      cells: [
        DataCell(Text(tutorName, style: TextStyle(fontSize: 11))),
        DataCell(Text(totalClasses, style: TextStyle(fontSize: 11))),
        DataCell(Text(chapter, style: TextStyle(fontSize: 11))),
        DataCell(Text(totalStudent, style: TextStyle(fontSize: 11))),
        DataCell(Text(week, style: TextStyle(fontSize: 11))),
        DataCell(
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppStyle.primaryColor,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  status1,
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
              SizedBox(width: 5),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status2,
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Container(
            width: 150,
            child: Text(
              complaint,
              style: TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ),
      ],
    );
  }
}

// PieChart for the profile status
class AttendanceRate extends CustomPainter {
  final double percentage;
  final Color segmentColor;

  const AttendanceRate({
    required this.percentage,
    this.segmentColor = AppStyle.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2.3, size.height / 2.5);
    final radius = min(size.width, size.height) * 0.36;
    final innerRadius = radius * 0.74;

    final paint = Paint()..style = PaintingStyle.fill;

    final double clamped = percentage.clamp(0.0, 100.0);
    final double filled = clamped;
    final double empty = 100.0 - clamped;

    final List<_PieSegment> segments = [
      if (filled > 0) _PieSegment(filled, segmentColor),
      if (empty > 0) _PieSegment(empty, Color(0xffDDFFE7)),
    ];

    final double total = segments.fold(0.0, (sum, s) => sum + s.value);
    double startAngle = -pi / -4.8;

    for (final segment in segments) {
      final double sweep = (segment.value / total) * 2 * pi;

      paint.color = segment.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        true,
        paint,
      );

      startAngle += sweep;
    }

    canvas.drawCircle(center, innerRadius, Paint()..color = Color(0xffDDFFE7));
  }

  @override
  bool shouldRepaint(AttendanceRate old) {
    return old.percentage != percentage || old.segmentColor != segmentColor;
  }
}

class _PieSegment {
  final double value;
  final Color color;
  const _PieSegment(this.value, this.color);
}
 