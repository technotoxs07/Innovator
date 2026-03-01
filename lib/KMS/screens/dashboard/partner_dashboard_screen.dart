// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:innovator/KMS/core/constants/app_style.dart';
// import 'package:innovator/KMS/core/constants/mediaquery.dart';
// import 'package:innovator/KMS/provider/teacher_provider.dart';
// import 'package:innovator/KMS/screens/constant_screen/custom_scroll.dart';

// class PartnerDashboardScreen extends ConsumerWidget {
//   const PartnerDashboardScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final profile = ref.watch(teacherProfileProvider);
//     return CustomScrolling(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const SizedBox(height: 10),
//           // Grid Content
//           GridView(
//             shrinkWrap: true,
//             padding: EdgeInsets.all(0),
//             physics: const NeverScrollableScrollPhysics(),

//             gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 2,
//               childAspectRatio: 1.4,
//               crossAxisSpacing: 10,

//               mainAxisSpacing: 10,
//             ),

//             children: [
//               //Profile Status
//               Card(
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(25),
//                 ),
//                 color: Colors.white,
//                 elevation: 5,
//                 child: Padding(
//                   padding: EdgeInsets.only(right: 15, left: 15, top: 10),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       FittedBox(
//                         child: Text(
//                           'Profile Status',
//                           style: AppStyle.heading2.copyWith(
//                             fontWeight: FontWeight.bold,
//                             fontFamily: AppStyle.fontFamilySecondary,
//                             fontSize: 15,
//                           ),
//                         ),
//                       ),

//                       Flexible(
//                         child: CustomPaint(
//                           painter: ProfileStatusCircularPercentage(
//                             percentage:
//                                 75, //pass the backend value later when it comes from the backends
//                           ),
//                           size: Size(
//                             context.screenWidth * 0.2,
//                             context.screenHeight * 0.1,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               //Assigned Schools
//               Card(
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(25),
//                 ),
//                 color: Colors.white,
//                 elevation: 5,
//                 child: Padding(
//                   padding: EdgeInsets.only(
//                     right: 17,
//                     left: 17,
//                     top: 10,
//                     bottom: 10,
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       FittedBox(
//                         child: Text(
//                           'Assigned Schools',
//                           style: AppStyle.heading2.copyWith(
//                             fontWeight: FontWeight.bold,
//                             fontFamily: AppStyle.fontFamilySecondary,
//                             fontSize: 15,
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: context.screenHeight * 0.009),
//                       Center(
//                         child: Text(
//                           '3',
//                           style: AppStyle.bodyText.copyWith(
//                             color: Colors.black,
//                             fontSize: 15,
//                             fontFamily: 'Inter',
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: context.screenHeight * 0.009),
//                       Padding(
//                         padding: EdgeInsets.only(left: 10),
//                         child: Container(
//                           decoration: BoxDecoration(
//                             color: AppStyle.backgroundColor,
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: FittedBox(
//                             child: Padding(
//                               padding: EdgeInsets.only(
//                                 right: 10,
//                                 left: 10,
//                                 bottom: 5,
//                                 top: 5,
//                               ),
//                               child: Row(
//                                 children: [
//                                   Image.asset(
//                                     'assets/kms/school.png',
//                                     height: 15,
//                                     width: 15,
//                                     color: AppStyle.primaryColor,
//                                   ),
//                                   SizedBox(width: 5),
//                                   Text('12 Classes'),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               Card(
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(25),
//                 ),
//                 color: Colors.white,
//                 elevation: 5,
//                 child: Padding(
//                   padding: EdgeInsets.only(right: 15, left: 15, top: 10),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       FittedBox(
//                         child: Text(
//                           'Task Overview',
//                           style: AppStyle.heading2.copyWith(
//                             fontWeight: FontWeight.bold,
//                             fontFamily: AppStyle.fontFamilySecondary,
//                             fontSize: 15,
//                           ),
//                         ),
//                       ),

//                       Padding(
//                         padding: EdgeInsets.only(top: 5, right: 5, left: 5),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               children: [
//                                 Text(
//                                   '3', // Completed value later from the backend

//                                   style: TextStyle(fontFamily: 'Inter'),
//                                 ),
//                                 SizedBox(width: 10),
//                                 Text('Completed'),
//                               ],
//                             ),
//                             Row(
//                               children: [
//                                 Text(
//                                   '3', //Pending value later from the backend
//                                   style: TextStyle(fontFamily: 'Inter'),
//                                 ),
//                                 SizedBox(width: 10),
//                                 Text('Pending'),
//                               ],
//                             ),
//                             SizedBox(height: context.screenHeight * 0.01),
//                             Center(
//                               child: Builder(
//                                 builder: (context) {
//                                   const completed =
//                                       3; // Completed value later from the backend
//                                   const pending =
//                                       3; //Pending value later from the backend
//                                   final total = completed + pending;
//                                   final double completedRatio =
//                                       total == 0 ? 0.0 : completed / total;
//                                   final int completedFlex =
//                                       (completedRatio * 1000).round();
//                                   final int pendingFlex =
//                                       (1000 - completedFlex).round();
//                                   return ClipRRect(
//                                     borderRadius: BorderRadiusGeometry.circular(
//                                       10,
//                                     ),
//                                     child: Container(
//                                       width: 100,
//                                       height: 20,
//                                       decoration: BoxDecoration(
//                                         borderRadius: BorderRadius.circular(10),
//                                         color: AppStyle.primaryColor,
//                                       ),
//                                       child: Row(
//                                         children: [
//                                           Expanded(
//                                             flex: completedFlex,
//                                             child: Container(
//                                               color: AppStyle.primaryColor,
//                                             ),
//                                           ),

//                                           Expanded(
//                                             flex: pendingFlex,
//                                             child: Container(
//                                               color: Colors.grey,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               Card(
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(25),
//                 ),
//                 color: Colors.white,
//                 elevation: 5,
//                 child: Padding(
//                   padding: EdgeInsets.only(right: 15, left: 15, top: 10),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       FittedBox(
//                         child: Text(
//                           'Payment',
//                           style: AppStyle.heading2.copyWith(
//                             fontWeight: FontWeight.bold,
//                             fontFamily: AppStyle.fontFamilySecondary,
//                             fontSize: 15,
//                           ),
//                         ),
//                       ),

//                       FittedBox(
//                         child: Row(
//                           children: [
//                             CustomPaint(
//                               painter: PaymentPieChart(),
//                               size: Size(
//                                 context.screenWidth * 0.2,
//                                 context.screenHeight * 0.1,
//                               ),
//                             ),
//                             SizedBox(width: 10),
//                             Column(
//                               mainAxisAlignment: MainAxisAlignment.end,
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 distributionChart(Color(0xffF8BD00), 'Pending'),
//                                 distributionChart(
//                                   AppStyle.primaryColor,
//                                   'Completed',
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           // This week classes container
//           SizedBox(height: 30),
//           Container(
//             width: double.infinity,
//             height: 250,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(14),
//               border: Border.all(color: Colors.black),
//             ),
//             child: Padding(
//               padding: EdgeInsets.only(right: 8, left: 8, top: 10, bottom: 8),
//               child: Column(
//                 children: [
//                   Center(
//                     child: Text(
//                       'This Week Classes',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontFamily: AppStyle.fontFamilySecondary,
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 15),
//                   Expanded(
//                     child: SingleChildScrollView(
//                       scrollDirection: Axis.horizontal,
//                       child: _thisWeekClassesTable(),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           SizedBox(height: 30),
//           // LeaderBoard Container
//           Container(
//             width: double.infinity,
//             height: 250,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(14),
//               border: Border.all(color: Colors.black),
//             ),
//             child: SingleChildScrollView(
//               child: Padding(
//                 padding: EdgeInsets.only(right: 8, left: 8, top: 10),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Center(
//                       child: Text(
//                         'Leaderboard',
//                         style: TextStyle(fontSize: 20, fontFamily: 'Inter'),
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text('You are ranked #4 this week'),
//                     const SizedBox(height: 16),
//                     leaderboardWidget(),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           SizedBox(height: 30),
//           //  Student Monitoring Container
//           Container(
//             width: double.infinity,
//             height: 250,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(14),
//               border: Border.all(color: Colors.black),
//             ),
//             child: Padding(
//               padding: EdgeInsets.only(right: 8, left: 8, top: 10, bottom: 5),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Student Monitoring',
//                     style: TextStyle(fontSize: 20, fontFamily: 'Inter'),
//                   ),
//                   const SizedBox(height: 16),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Container(
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(5),
//                           border: Border.all(color: Colors.black),
//                         ),
//                         child: Padding(
//                           padding: EdgeInsets.symmetric(
//                             horizontal: 8,
//                             vertical: 0,
//                           ),
//                           child: Text('Class 1- Attendance'),
//                         ),
//                       ),
//                       IconButton(
//                         onPressed: () {},
//                         icon: Icon(
//                           Icons.filter_alt,
//                           color: AppStyle.primaryColor,
//                           size: 30,
//                         ),
//                       ),
//                     ],
//                   ),

//                   Expanded(
//                     child: SingleChildScrollView(
//                       scrollDirection: Axis.horizontal,
//                       child: _studentMonitoringTable(),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget distributionChart(Color? color, String text) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.start,
//       children: [
//         Container(
//           width: 10,
//           height: 5,
//           decoration: BoxDecoration(shape: BoxShape.rectangle, color: color),
//         ),
//         SizedBox(width: 10),
//         Text(text, style: TextStyle(color: Colors.black, fontSize: 14)),
//       ],
//     );
//   }
// }

// // Leaderboard widget
// Widget leaderboardWidget() {
//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       // Table Header
//       Row(
//         children: const [
//           Expanded(
//             flex: 1,
//             child: Text(
//               'S.N.',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontFamily: 'Inter',
//               ),
//             ),
//           ),
//           Expanded(
//             flex: 3,
//             child: Center(
//               child: Text(
//                 'Name',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontFamily: 'Inter',
//                 ),
//               ),
//             ),
//           ),
//           Expanded(
//             flex: 1,
//             child: Text(
//               'Score',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontFamily: 'Inter',
//               ),
//               textAlign: TextAlign.right,
//             ),
//           ),
//         ],
//       ),
//       const Divider(thickness: 1, color: Colors.black),
//       // Table Rows
//       _buildLeaderBoardRow('1.', 'John Doe', '9'),
//       _buildLeaderBoardRow('2.', 'John Doe', '8'),
//       _buildLeaderBoardRow('3.', 'John Doe', '7'),
//       _buildLeaderBoardRow('4.', 'John Doe', '6.5'),
//       _buildLeaderBoardRow('5.', 'John Doe', '6'),
//     ],
//   );
// }

// // LeaderBoard Data Row
// Widget _buildLeaderBoardRow(String sn, String name, String score) {
//   return Padding(
//     padding: const EdgeInsets.symmetric(vertical: 4),
//     child: Column(
//       children: [
//         Row(
//           children: [
//             Expanded(flex: 1, child: Text(sn)),
//             Expanded(
//               flex: 3,
//               child: Center(
//                 child: Text(
//                   name,
//                   style: TextStyle(fontWeight: FontWeight.normal),
//                 ),
//               ),
//             ),
//             Expanded(
//               flex: 1,
//               child: Text(
//                 score,
//                 textAlign: TextAlign.right,
//                 style: TextStyle(fontWeight: FontWeight.normal),
//               ),
//             ),
//           ],
//         ),
//         Divider(color: Colors.grey),
//       ],
//     ),
//   );
// }

// // This Week Classes Table
// Widget _thisWeekClassesTable() {
//   return SingleChildScrollView(
//     child: DataTable(
//       columnSpacing: 30,
//       headingRowHeight: 40,
//       dataRowMaxHeight: 50,

//       columns: const [
//         DataColumn(
//           label: Text(
//             'School Name',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontFamily: 'Inter',
//               fontSize: 12,
//             ),
//           ),
//         ),
//         DataColumn(
//           label: Text(
//             'Chapter',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontFamily: 'Inter',
//               fontSize: 12,
//             ),
//           ),
//         ),
//         DataColumn(
//           label: Text(
//             'Weeks',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontFamily: 'Inter',
//               fontSize: 12,
//             ),
//           ),
//         ),
//         DataColumn(
//           label: Text(
//             'Weeks Completed',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontFamily: 'Inter',
//               fontSize: 12,
//             ),
//           ),
//         ),
//       ],
//       rows: [
//         _thisWeekClassesDataRow('Patan Multiple Campus', '2', '6', '5'),
//         _thisWeekClassesDataRow('Vidya Sadan', '1', '5', '5'),
//         _thisWeekClassesDataRow(
//           'Nepatronix Institute of Science and Technology',
//           '1',
//           '7',
//           '6',
//         ),
//         _thisWeekClassesDataRow('National Info Tech', '2', '6', '4'),
//         _thisWeekClassesDataRow(
//           'Madan Bhandari Memorial School',
//           '2',
//           '6',
//           '5',
//         ),
//       ],
//     ),
//   );
// }

// DataRow _thisWeekClassesDataRow(
//   String schoolName,
//   String chapter,
//   String weeks,
//   String weeksCompleted,
// ) {
//   return DataRow(
//     cells: [
//       DataCell(
//         Container(
//           width: 190,
//           child: Text(schoolName, style: TextStyle(fontSize: 11)),
//         ),
//       ),
//       DataCell(Text(chapter, style: TextStyle(fontSize: 11))),
//       DataCell(Text(weeks, style: TextStyle(fontSize: 11))),
//       DataCell(Text(weeksCompleted, style: TextStyle(fontSize: 11))),
//     ],
//   );
// }

// // Student Monitoring Table
// Widget _studentMonitoringTable() {
//   return SingleChildScrollView(
//     child: DataTable(
//       columnSpacing: 25,
//       headingRowHeight: 40,
//       dataRowMaxHeight: 50,

//       columns: const [
//         DataColumn(
//           label: Text(
//             'Name',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontFamily: 'Inter',
//               fontSize: 12,
//             ),
//           ),
//         ),
//         DataColumn(
//           label: Text(
//             'Total Classes',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontFamily: 'Inter',
//               fontSize: 12,
//             ),
//           ),
//         ),
//         DataColumn(
//           label: Text(
//             'Present',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontFamily: 'Inter',
//               fontSize: 12,
//             ),
//           ),
//         ),
//         DataColumn(
//           label: Text(
//             'Absent',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontFamily: 'Inter',
//               fontSize: 12,
//             ),
//           ),
//         ),
//         DataColumn(
//           label: Text(
//             'Assignment',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontFamily: 'Inter',
//               fontSize: 12,
//             ),
//           ),
//         ),
//         DataColumn(
//           label: Text(
//             'Marks',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontFamily: 'Inter',
//               fontSize: 12,
//             ),
//           ),
//         ),
//       ],
//       rows: [
//         _studentMonitoringDataRow('John Doe', '20', '22', '1', '3/5', '90'),
//         _studentMonitoringDataRow(
//           'Alice Johnson',
//           '45',
//           '24',
//           '0',
//           '3/6',
//           '46',
//         ),
//         _studentMonitoringDataRow(
//           'Raju Shrestha',
//           '56',
//           '21',
//           '7',
//           '9/1',
//           '65',
//         ),
//         _studentMonitoringDataRow(
//           'Ronit Srivastav',
//           '53',
//           '10',
//           '4',
//           '1/8',
//           '78',
//         ),
//       ],
//     ),
//   );
// }

// DataRow _studentMonitoringDataRow(
//   String name,
//   String totalClasses,
//   String present,
//   String absent,
//   String assignment,
//   String marks,
// ) {
//   return DataRow(
//     cells: [
//       DataCell(Text(name, style: TextStyle(fontSize: 11))),
//       DataCell(Text(totalClasses, style: TextStyle(fontSize: 11))),
//       DataCell(Text(present, style: TextStyle(fontSize: 11))),
//       DataCell(Text(absent, style: TextStyle(fontSize: 11))),
//       DataCell(Text(assignment, style: TextStyle(fontSize: 11))),
//       DataCell(Text(marks, style: TextStyle(fontSize: 11))),
//     ],
//   );
// }

// // PieChart for the profile status
// class ProfileStatusCircularPercentage extends CustomPainter {
//   final double percentage;
//   final Color segmentColor;

//   const ProfileStatusCircularPercentage({
//     required this.percentage,
//     this.segmentColor = AppStyle.primaryColor,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = Offset(size.width / 1.4, size.height / 2.5);
//     final radius = min(size.width, size.height) * 0.4;
//     final innerRadius = radius * 0.74;

//     final paint = Paint()..style = PaintingStyle.fill;

//     final double clamped = percentage.clamp(0.0, 100.0);
//     final double filled = clamped;
//     final double empty = 100.0 - clamped;

//     final List<_PieSegment> segments = [
//       if (filled > 0) _PieSegment(filled, segmentColor),
//       if (empty > 0) _PieSegment(empty, Color(0xffDDFFE7)),
//     ];

//     final double total = segments.fold(0.0, (sum, s) => sum + s.value);
//     double startAngle = -pi / -4.8;

//     for (final segment in segments) {
//       final double sweep = (segment.value / total) * 2 * pi;

//       paint.color = segment.color;
//       canvas.drawArc(
//         Rect.fromCircle(center: center, radius: radius),
//         startAngle,
//         sweep,
//         true,
//         paint,
//       );

//       startAngle += sweep;
//     }

//     canvas.drawCircle(center, innerRadius, Paint()..color = Color(0xffDDFFE7));

//     final String text = '${clamped.toInt()}%';
//     final TextPainter textPainter = TextPainter(
//       textDirection: TextDirection.rtl,
//     );
//     textPainter.text = TextSpan(
//       text: text,
//       style: const TextStyle(
//         color: Colors.black,
//         fontSize: 15,
//         fontWeight: FontWeight.bold,
//         fontFamily: 'Inter',
//       ),
//     );
//     textPainter.layout();

//     final Offset textOffset = Offset(
//       center.dx - textPainter.width / 2.3,
//       center.dy - textPainter.height / 2,
//     );

//     textPainter.paint(canvas, textOffset);
//   }

//   @override
//   bool shouldRepaint(ProfileStatusCircularPercentage old) {
//     return old.percentage != percentage || old.segmentColor != segmentColor;
//   }
// }

// class _PieSegment {
//   final double value;
//   final Color color;
//   const _PieSegment(this.value, this.color);
// }

// //Custom Painter for the payement pie chart
// class PaymentPieChart extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = Offset(size.width / 2, size.height / 2);
//     final radius = min(size.width, size.height) * 0.48;
//     final innerRadius = radius * 0;

//     final paint = Paint()..style = PaintingStyle.fill;

//     //Pass the value that comes later from the backend
//     final segments = [
//       _PaymentPieSegment(85, AppStyle.primaryColor),
//       _PaymentPieSegment(15, Color(0xffF8BD00)),
//     ];

//     final total = segments.fold(0.0, (sum, s) => sum + s.value);
//     double startAngle = -pi / 2;

//     for (final segment in segments) {
//       final sweepAngle = (segment.value / total) * 2.5 * pi;

//       // Draw filled arc
//       paint.color = segment.color;
//       canvas.drawArc(
//         Rect.fromCircle(center: center, radius: radius),
//         startAngle,
//         sweepAngle,
//         true,
//         paint,
//       );

//       final textAngle = startAngle + sweepAngle / 2.5;
//       final textRadius = radius * 0.66;
//       final textX = center.dx + textRadius * cos(textAngle);
//       final textY = center.dy + textRadius * sin(textAngle);

//       final textPainter = TextPainter(textDirection: TextDirection.ltr);
//       textPainter.text = TextSpan(
//         text: '${segment.value.toInt()}%',
//         style: const TextStyle(
//           color: Colors.black,
//           fontSize: 14,
//           fontWeight: FontWeight.bold,
//         ),
//       );
//       textPainter.layout();
//       textPainter.paint(
//         canvas,
//         Offset(textX - textPainter.width / 2, textY - textPainter.height / 2),
//       );

//       startAngle += sweepAngle;
//     }

//     canvas.drawCircle(center, innerRadius, Paint()..color = Colors.white);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

// class _PaymentPieSegment {
//   final double value;
//   final Color color;
//   _PaymentPieSegment(this.value, this.color);
// }

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/core/constants/mediaquery.dart';
import 'package:innovator/KMS/screens/constant_screen/custom_scroll.dart';
import 'package:innovator/KMS/provider/teacher_provider.dart';

class PartnerDashboardScreen extends ConsumerStatefulWidget {
  const PartnerDashboardScreen({super.key});

  @override
  ConsumerState<PartnerDashboardScreen> createState() =>
      _PartnerDashboardScreenState();
}

class _PartnerDashboardScreenState extends ConsumerState<PartnerDashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isPaymentFlipped = false;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _togglePaymentCard() {
    setState(() {
      _isPaymentFlipped = !_isPaymentFlipped;
      _isPaymentFlipped ? _flipController.forward() : _flipController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(teacherProfileProvider);

    return RefreshIndicator(
      onRefresh: () {
        return ref.refresh(teacherProfileProvider.future);
      },
      child: CustomScrolling(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // ── Grid: skeleton while loading, real data or graceful empty after ──
            profileAsync.when(
              loading: () => const _SkeletonGrid(),
              error: (_, __) => _buildGrid(context, null), // graceful fallback
              data: (profile) => _buildGrid(context, profile),
            ),

            // ── This Week Classes ─────────────────────────────────────────────
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  right: 8,
                  left: 8,
                  top: 10,
                  bottom: 8,
                ),
                child: Column(
                  children: [
                    Center(
                      child: Text(
                        'This Week Classes',
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily: AppStyle.fontFamilySecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: _thisWeekClassesTable(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Leaderboard ───────────────────────────────────────────────────
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, left: 8, top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Leaderboard',
                          style: TextStyle(fontSize: 20, fontFamily: 'Inter'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('You are ranked #4 this week'),
                      const SizedBox(height: 16),
                      leaderboardWidget(),
                    ],
                  ),
                ),
              ),
            ),

            // ── Student Monitoring ────────────────────────────────────────────
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  right: 8,
                  left: 8,
                  top: 10,
                  bottom: 5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Student Monitoring',
                      style: TextStyle(fontSize: 20, fontFamily: 'Inter'),
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
                          child: const Padding(
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
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: _studentMonitoringTable(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── Real grid (called after 20 s; profile may be null on error) ────────────
  Widget _buildGrid(BuildContext context, dynamic profile) {
    final int schoolCount = profile?.earnings.schools.length ?? 0;
    final int totalClasses =
        profile == null
            ? 0
            : (profile.earnings.schools as List).fold<int>(
              0,
              (sum, s) => sum + (s.classesCount as int),
            );
    final double totalEarnings = profile?.earnings.totalEarnings ?? 0.0;
    final double paid = profile?.earnings.totalPaid ?? 0.0;
    final double pending = profile?.earnings.totalPending ?? 0.0;
    final double projected = profile?.earnings.projectedEarnings ?? 0.0;
    final double paidPct =
        totalEarnings > 0 ? (paid / totalEarnings) * 100 : 0.0;
    final double pendingPct =
        totalEarnings > 0 ? (pending / totalEarnings) * 100 : 0.0;
    final bool noData = profile == null;

    return GridView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      children: [
        // ── Profile Status ───────────────────────────────────────────────
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          color: Colors.white,
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.only(right: 15, left: 15, top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  child: Text(
                    'Profile Status',
                    style: AppStyle.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: AppStyle.fontFamilySecondary,
                      fontSize: 15,
                    ),
                  ),
                ),
                Flexible(
                  child: CustomPaint(
                    // TODO: replace 75 with backend field when available
                    painter: const ProfileStatusCircularPercentage(
                      percentage: 75,
                    ),
                    size: Size(
                      context.screenWidth * 0.2,
                      context.screenHeight * 0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Assigned Schools ─────────────────────────────────────────────
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          color: Colors.white,
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.only(
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
                    'Assigned Schools',
                    style: AppStyle.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: AppStyle.fontFamilySecondary,
                      fontSize: 15,
                    ),
                  ),
                ),
                SizedBox(height: context.screenHeight * 0.009),
                Center(
                  child: Text(
                    noData ? '—' : '$schoolCount',
                    style: AppStyle.bodyText.copyWith(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                SizedBox(height: context.screenHeight * 0.009),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppStyle.backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FittedBox(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          right: 10,
                          left: 10,
                          bottom: 5,
                          top: 5,
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/kms/school.png',
                              height: 15,
                              width: 15,
                              color: AppStyle.primaryColor,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              noData
                                  ? 'No Classes Yet'
                                  : '$totalClasses Classes',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Task Overview ────────────────────────────────────────────────
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          color: Colors.white,
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.only(right: 15, left: 15, top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  child: Text(
                    'Task Overview',
                    style: AppStyle.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: AppStyle.fontFamilySecondary,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (noData)
                  Expanded(
                    child: Center(
                      child: Text(
                        'No tasks yet',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 5, right: 5, left: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TODO: replace with real backend task fields
                        Row(
                          children: const [
                            Text('3', style: TextStyle(fontFamily: 'Inter')),
                            SizedBox(width: 10),
                            Text('Completed'),
                          ],
                        ),
                        Row(
                          children: const [
                            Text('3', style: TextStyle(fontFamily: 'Inter')),
                            SizedBox(width: 10),
                            Text('Pending'),
                          ],
                        ),
                        SizedBox(height: context.screenHeight * 0.01),
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadiusGeometry.circular(10),
                            child: SizedBox(
                              width: 100,
                              height: 20,
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 500,
                                    child: Container(
                                      color: AppStyle.primaryColor,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 500,
                                    child: Container(color: Colors.grey),
                                  ),
                                ],
                              ),
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

        // ── Payment Flip Card ────────────────────────────────────────────
        GestureDetector(
          onTap: _togglePaymentCard,
          child: AnimatedBuilder(
            animation: _flipAnimation,
            builder: (context, _) {
              final isFront = _flipAnimation.value < 0.5;
              final angle = _flipAnimation.value * pi;
              return Transform(
                transform:
                    Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                alignment: Alignment.center,
                child:
                    isFront
                        ? _paymentFront(context, paidPct, pendingPct, noData)
                        : Transform(
                          transform: Matrix4.identity()..rotateY(pi),
                          alignment: Alignment.center,
                          child: _paymentBack(
                            context,
                            total: totalEarnings,
                            paid: paid,
                            pending: pending,
                            projected: projected,
                            noData: noData,
                          ),
                        ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Payment front (pie chart %) ────────────────────────────────────────────
  Widget _paymentFront(
    BuildContext context,
    double paidPct,
    double pendingPct,
    bool noData,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      color: Colors.white,
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.only(right: 15, left: 15, top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FittedBox(
                  child: Text(
                    'Payment',
                    style: AppStyle.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: AppStyle.fontFamilySecondary,
                      fontSize: 15,
                    ),
                  ),
                ),
                const Icon(Icons.touch_app, size: 14, color: Colors.grey),
              ],
            ),
            if (noData)
              Expanded(
                child: Center(
                  child: Text(
                    'No payment\ndata yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              )
            else
              FittedBox(
                child: Row(
                  children: [
                    CustomPaint(
                      painter: PaymentPieChart(
                        paidPercentage: paidPct,
                        pendingPercentage: pendingPct,
                      ),
                      size: Size(
                        context.screenWidth * 0.2,
                        context.screenHeight * 0.1,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _distributionChart(const Color(0xffF8BD00), 'Pending'),
                        _distributionChart(AppStyle.primaryColor, 'Paid'),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Payment back (actual Rs amounts) ──────────────────────────────────────
  Widget _paymentBack(
    BuildContext context, {
    required double total,
    required double paid,
    required double pending,
    required double projected,
    required bool noData,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      color: Colors.white,
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FittedBox(
                  child: Text(
                    'Payment',
                    style: AppStyle.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: AppStyle.fontFamilySecondary,
                      fontSize: 15,
                    ),
                  ),
                ),
                const Icon(Icons.touch_app, size: 14, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 4),
            if (noData)
              Expanded(
                child: Center(
                  child: Text(
                    'No payment\ndata yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              )
            else ...[
              _amountRow('Total', total, Colors.black),
              _amountRow('Paid', paid, AppStyle.primaryColor),
              _amountRow('Pending', pending, const Color(0xffF8BD00)),
              _amountRow('Projected', projected, Colors.blueGrey),
            ],
          ],
        ),
      ),
    );
  }

  Widget _amountRow(String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'Inter',
              color: Colors.black87,
            ),
          ),
          Text(
            'Rs. ${amount.toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _distributionChart(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 5,
          decoration: BoxDecoration(shape: BoxShape.rectangle, color: color),
        ),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: Colors.black, fontSize: 14)),
      ],
    );
  }
}

// ── Skeleton grid shown during the 20 second delay ───────────────────────────
class _SkeletonGrid extends StatefulWidget {
  const _SkeletonGrid();

  @override
  State<_SkeletonGrid> createState() => _SkeletonGridState();
}

class _SkeletonGridState extends State<_SkeletonGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder:
          (context, _) => GridView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            children: List.generate(4, (i) => _buildSkeletonCard(i)),
          ),
    );
  }

  Widget _buildSkeletonCard(int index) {
    // Stagger the wave across cards
    final double phase = (_ctrl.value + index * 0.2) % 1.0;
    final double opacity = 0.3 + (0.5 * (sin(phase * pi)));

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      color: Colors.white,
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Opacity(
          opacity: opacity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title bar placeholder
              _box(width: 90, height: 11),
              const SizedBox(height: 14),
              // Card-specific skeleton body
              if (index == 0) ...[
                // Profile status → circle
                Center(child: _circle(52)),
              ] else if (index == 1) ...[
                // Assigned schools → number + pill
                Center(child: _box(width: 28, height: 18)),
                const SizedBox(height: 8),
                _box(width: 85, height: 22, radius: 11),
              ] else if (index == 2) ...[
                // Task overview → two lines + progress bar
                _box(width: double.infinity, height: 10),
                const SizedBox(height: 7),
                _box(width: double.infinity, height: 10),
                const SizedBox(height: 10),
                Center(child: _box(width: 100, height: 18, radius: 9)),
              ] else ...[
                // Payment → fake pie + legend
                Row(
                  children: [
                    _circle(48),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _box(width: 52, height: 8),
                        const SizedBox(height: 8),
                        _box(width: 52, height: 8),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _box({required double width, double height = 12, double radius = 6}) =>
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(radius),
        ),
      );

  Widget _circle(double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.grey.shade300,
      shape: BoxShape.circle,
    ),
  );
}

 
Widget leaderboardWidget() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: const [
          Expanded(
            flex: 1,
            child: Text(
              'S.N.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                'Name',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Score',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
      const Divider(thickness: 1, color: Colors.black),
      _buildLeaderBoardRow('1.', 'John Doe', '9'),
      _buildLeaderBoardRow('2.', 'John Doe', '8'),
      _buildLeaderBoardRow('3.', 'John Doe', '7'),
      _buildLeaderBoardRow('4.', 'John Doe', '6.5'),
      _buildLeaderBoardRow('5.', 'John Doe', '6'),
    ],
  );
}

Widget _buildLeaderBoardRow(String sn, String name, String score) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(flex: 1, child: Text(sn)),
            Expanded(
              flex: 3,
              child: Center(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.normal),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                score,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.normal),
              ),
            ),
          ],
        ),
        const Divider(color: Colors.grey),
      ],
    ),
  );
}


Widget _thisWeekClassesTable() {
  return SingleChildScrollView(
    child: DataTable(
      columnSpacing: 30,
      headingRowHeight: 40,
      dataRowMaxHeight: 50,
      columns: const [
        DataColumn(
          label: Text(
            'School Name',
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
            'Weeks',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
              fontSize: 12,
            ),
          ),
        ),
        DataColumn(
          label: Text(
            'Weeks Completed',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
              fontSize: 12,
            ),
          ),
        ),
      ],
      rows: [
        _thisWeekClassesDataRow('Patan Multiple Campus', '2', '6', '5'),
        _thisWeekClassesDataRow('Vidya Sadan', '1', '5', '5'),
        _thisWeekClassesDataRow(
          'Nepatronix Institute of Science and Technology',
          '1',
          '7',
          '6',
        ),
        _thisWeekClassesDataRow('National Info Tech', '2', '6', '4'),
        _thisWeekClassesDataRow(
          'Madan Bhandari Memorial School',
          '2',
          '6',
          '5',
        ),
      ],
    ),
  );
}

DataRow _thisWeekClassesDataRow(
  String schoolName,
  String chapter,
  String weeks,
  String weeksCompleted,
) {
  return DataRow(
    cells: [
      DataCell(
        SizedBox(
          width: 190,
          child: Text(schoolName, style: const TextStyle(fontSize: 11)),
        ),
      ),
      DataCell(Text(chapter, style: const TextStyle(fontSize: 11))),
      DataCell(Text(weeks, style: const TextStyle(fontSize: 11))),
      DataCell(Text(weeksCompleted, style: const TextStyle(fontSize: 11))),
    ],
  );
}


Widget _studentMonitoringTable() {
  return SingleChildScrollView(
    child: DataTable(
      columnSpacing: 25,
      headingRowHeight: 40,
      dataRowMaxHeight: 50,
      columns: const [
        DataColumn(
          label: Text(
            'Name',
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
            'Assignment',
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
        _studentMonitoringDataRow('John Doe', '20', '22', '1', '3/5', '90'),
        _studentMonitoringDataRow(
          'Alice Johnson',
          '45',
          '24',
          '0',
          '3/6',
          '46',
        ),
        _studentMonitoringDataRow(
          'Raju Shrestha',
          '56',
          '21',
          '7',
          '9/1',
          '65',
        ),
        _studentMonitoringDataRow(
          'Ronit Srivastav',
          '53',
          '10',
          '4',
          '1/8',
          '78',
        ),
      ],
    ),
  );
}

DataRow _studentMonitoringDataRow(
  String name,
  String totalClasses,
  String present,
  String absent,
  String assignment,
  String marks,
) {
  return DataRow(
    cells: [
      DataCell(Text(name, style: const TextStyle(fontSize: 11))),
      DataCell(Text(totalClasses, style: const TextStyle(fontSize: 11))),
      DataCell(Text(present, style: const TextStyle(fontSize: 11))),
      DataCell(Text(absent, style: const TextStyle(fontSize: 11))),
      DataCell(Text(assignment, style: const TextStyle(fontSize: 11))),
      DataCell(Text(marks, style: const TextStyle(fontSize: 11))),
    ],
  );
}

 
class ProfileStatusCircularPercentage extends CustomPainter {
  final double percentage;
  final Color segmentColor;

  const ProfileStatusCircularPercentage({
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
    final segs = [
      if (clamped > 0) _PieSegment(clamped, segmentColor),
      if (100.0 - clamped > 0)
        _PieSegment(100.0 - clamped, const Color(0xffDDFFE7)),
    ];
    final total = segs.fold(0.0, (s, e) => s + e.value);
    double start = -pi / -4.8;
    for (final seg in segs) {
      final sweep = (seg.value / total) * 2 * pi;
      paint.color = seg.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        true,
        paint,
      );
      start += sweep;
    }
    canvas.drawCircle(
      center,
      innerRadius,
      Paint()..color = const Color(0xffDDFFE7),
    );
    final tp =
        TextPainter(textDirection: TextDirection.rtl)
          ..text = TextSpan(
            text: '${clamped.toInt()}%',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          )
          ..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2.3, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(ProfileStatusCircularPercentage old) =>
      old.percentage != percentage;
}

class _PieSegment {
  final double value;
  final Color color;
  const _PieSegment(this.value, this.color);
}

 
class PaymentPieChart extends CustomPainter {
  final double paidPercentage;
  final double pendingPercentage;

  const PaymentPieChart({
    required this.paidPercentage,
    required this.pendingPercentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.48;
    final paint = Paint()..style = PaintingStyle.fill;
    final segs = [
      _PaySeg(paidPercentage, AppStyle.primaryColor),
      _PaySeg(pendingPercentage, const Color(0xffF8BD00)),
    ];
    final total = segs.fold(0.0, (s, e) => s + e.value);
    if (total == 0) {
      paint.color = Colors.grey.shade300;
      canvas.drawCircle(center, radius, paint);
      return;
    }
    double start = -pi / 2;
    for (final seg in segs) {
      if (seg.value <= 0) continue;
      final sweep = (seg.value / total) * 2.5 * pi;
      paint.color = seg.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        true,
        paint,
      );
      final ta = start + sweep / 2.5;
      final tr = radius * 0.66;
      final tp =
          TextPainter(textDirection: TextDirection.ltr)
            ..text = TextSpan(
              text: '${seg.value.toInt()}%',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            )
            ..layout();
      tp.paint(
        canvas,
        Offset(
          center.dx + tr * cos(ta) - tp.width / 2,
          center.dy + tr * sin(ta) - tp.height / 2,
        ),
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(PaymentPieChart old) =>
      old.paidPercentage != paidPercentage ||
      old.pendingPercentage != pendingPercentage;
}

class _PaySeg {
  final double value;
  final Color color;
  const _PaySeg(this.value, this.color);
}
