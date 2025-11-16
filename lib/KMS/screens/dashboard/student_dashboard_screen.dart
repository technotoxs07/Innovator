import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/screens/constant_screen/app_drawer.dart';
import 'package:innovator/KMS/constants/app_style.dart';
import 'package:innovator/KMS/constants/mediaquery.dart';
import 'package:innovator/KMS/screens/constant_screen/appbar.dart';
import 'package:innovator/KMS/screens/constant_screen/custom_scroll.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return  CustomScrolling(
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
                      padding: EdgeInsets.only(right: 15, left: 15, top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            child: Text(
                              'Attendance Rate',
                              style: AppStyle.heading2.copyWith(
                                fontWeight: FontWeight.bold,
                                fontFamily: AppStyle.fontFamilySecondary,
                                fontSize: 15,
                              ),
                            ),
                          ),

                          CustomPaint(
                            painter: AttendanceRate(
                              percentage:
                                  75, //pass the backend value later when it comes from the backends
                            ),
                            size: Size(
                              context.screenWidth * 0.2,
                              context.screenHeight * 0.1,
                            ),
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
                          children: [
                            Image.asset(
                              width: 35,
                              height: 35,
                              'assets/kms/add_task.png',
                            ),
                            SizedBox(width: 10),
                            Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '3',
                                    style: TextStyle(fontFamily: 'Inter'),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Total Tasks-5',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontFamily: 'Inter',
                                    ),
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
                //Overall Progress
                FittedBox(
                  child: Card(
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
                              'Overall Progress',
                              style: AppStyle.heading2.copyWith(
                                fontWeight: FontWeight.bold,
                                fontFamily: AppStyle.fontFamilySecondary,
                                fontSize: 15,
                              ),
                            ),
                          ),

                          FittedBox(
                            child: Row(
                              children: [
                                CustomPaint(
                                  painter: OverallProgressPieChart(
                                    progressValue: 75,
                                  ),
                                  size: Size(
                                    context.screenWidth * 0.2,
                                    context.screenHeight * 0.1,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Padding(
                                  padding: EdgeInsets.only(bottom: 40),
                                  child: Text(
                                    '75%', //pass the same value passed in the progress value later that comes from the backend
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // New materials
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  color: Colors.white,
                  elevation: 5,
                  child: Padding(
                    padding: EdgeInsets.only(right: 30, left: 30, top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'New materials added this week',
                          // textAlign: TextAlign.justify,
                          style: AppStyle.heading2.copyWith(fontSize: 13),
                        ),

                        SizedBox(height: 10),
                        Text(
                          '3',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Learning Material
            Container(
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
                          'Learning Materials',
                          style: TextStyle(fontSize: 20, fontFamily: 'Inter'),
                        ),
                      ),
                      SizedBox(height: 15),
                      GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),

                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.6,
                          crossAxisSpacing: 10,

                          mainAxisSpacing: 10,
                        ),
                        children: [
                          learningMaterialCard(
                            image: 'assets/kms/video.png',
                            label: 'Video',
                            value: '2 Lessons',
                            completed: 1,
                            total: 2,
                          ),
                          learningMaterialCard(
                            image: 'assets/kms/notes.png',
                            label: 'NOtes',
                            value: '1 Lessons',
                            completed: 1,
                            total: 3,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
            // Exam Section
            Container(
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
                          'Exam Section',
                          style: TextStyle(fontSize: 20, fontFamily: 'Inter'),
                        ),
                      ),
                      SizedBox(height: 15),
                      GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),

                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.7,
                          crossAxisSpacing: 10,

                          mainAxisSpacing: 10,
                        ),
                        children: [
                          examSectionCard(
                            examStatus: 'Previous Exam',
                            subject: 'Robotics',
                            date: 'November 1',
                          ),
                          examSectionCard(
                            examStatus: 'Upcoming Exam',
                            subject: 'IoT',
                            date: 'November 16',
                          ),
                        ],
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
                padding: EdgeInsets.only(right: 8, left: 8, top: 10, bottom: 5),
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
        ),
    
    );
  }

  // Learning Material Card

  Widget learningMaterialCard({
    required String image,
    required String label,
    required String value,
    required int completed,
    required int total,
  }) {
    final double completedRatio = total == 0 ? 0.0 : completed / total;

    final int completedFlex = (completedRatio * 1000).round();
    final int pendingFlex = (1000 - completedFlex).round();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white,
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.only(right: 15, left: 15, top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(image, width: 46, height: 48),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                        ),
                      ),
                      Text(value),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 15),
            Padding(
              padding: EdgeInsets.only(left: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 65,
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: completedFlex,
                        child: Container(color: AppStyle.primaryColor),
                      ),

                      Expanded(
                        flex: pendingFlex,
                        child: const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //ExamSection Card
  Widget examSectionCard({
    required String examStatus,
    required String subject,
    required String date,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white,
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.only(right: 15, left: 15, top: 10),
        child: FittedBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                examStatus,
                style: TextStyle(fontFamily: 'Inter', fontSize: 15),
              ),
              Center(
                child: Text(
                  subject,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 15),
                ),
              ),
              Text(date, style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
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
              'Task',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Tutor',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Assigned Date',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Due Date',
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
        ],
        rows: [
          _tutorMonitoringRow(
            'Complete Quiz 1',
            'Alice Kumar Rai',
            'Nov 9',
            'Nov 30',
            6, // completed weeks
            10, // total weeks
            'Approved',
            'Pending',
          ),
          _tutorMonitoringRow(
            'Complete Quiz 5',
            'Alice Johnson',
            'Nov 2',
            'Nov 8',
            5, // completed weeks
            10, // total weeks
            'Approved',
            'Pending',
          ),
          _tutorMonitoringRow(
            'Complete Quiz 5',
            'Alice Johnson',
            'Nov 2',
            'Nov 8',
            3, // completed weeks
            10, // total weeks
            'Approved',
            'Pending',
          ),
          _tutorMonitoringRow(
            'Complete Quiz 5',
            'Alice Johnson',
            'Nov 2',
            'Nov 8',
            1, // total weeks
            0, // completed weeks

            'Approved',
            'Pending',
          ),
        ],
      ),
    );
  }

  DataRow _tutorMonitoringRow(
    String task,
    String tutorName,
    String assignedDate,
    String dueDate,
    int totalWeeks,
    int completedWeeks,
    String status1,
    String status2,
  ) {
    final double completedRatio =
        totalWeeks == 0 ? 0.0 : completedWeeks / totalWeeks;
    final int completedFlex = (completedRatio * 1000).round();
    final int pendingFlex = (1000 - completedFlex).round();

    return DataRow(
      cells: [
        DataCell(Text(task, style: TextStyle(fontSize: 11))),
        DataCell(Text(tutorName, style: TextStyle(fontSize: 11))),
        DataCell(Text(assignedDate, style: TextStyle(fontSize: 11))),
        DataCell(Text(dueDate, style: TextStyle(fontSize: 11))),
        DataCell(
          Padding(
            padding: EdgeInsets.only(left: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 65,
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: completedFlex,
                      child: Container(color: AppStyle.primaryColor),
                    ),
                    Expanded(flex: pendingFlex, child: const SizedBox.shrink()),
                  ],
                ),
              ),
            ),
          ),
        ),
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
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  status2,
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ],
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
    final center = Offset(size.width / 1.4, size.height / 2.5);
    final radius = min(size.width, size.height) * 0.4;
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

    final String text = '${clamped.toInt()}%';
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.rtl,
    );
    textPainter.text = TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 15,
        fontWeight: FontWeight.bold,
        fontFamily: 'Inter',
      ),
    );
    textPainter.layout();

    final Offset textOffset = Offset(
      center.dx - textPainter.width / 2.3,
      center.dy - textPainter.height / 2,
    );

    textPainter.paint(canvas, textOffset);
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

class OverallProgressPieChart extends CustomPainter {
  final double progressValue;
  final Color progressColor;

  OverallProgressPieChart({
    required this.progressValue,
    this.progressColor = const Color(0xff0CC740),
  }) : assert(progressValue >= 0 && progressValue <= 100);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.48;

    final progressPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = progressColor;

    final startAngle = pi / -100;
    final sweepAngle = (progressValue / 100) * 2 * pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      true,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
