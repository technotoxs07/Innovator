// // import 'dart:math';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_riverpod/flutter_riverpod.dart';
// // import 'package:innovator/KMS/core/constants/app_style.dart';
// // import 'package:innovator/KMS/core/constants/mediaquery.dart';
// // import 'package:innovator/KMS/screens/constant_screen/custom_scroll.dart';
// // import 'package:innovator/KMS/provider/teacher_provider.dart';

// // class PartnerDashboardScreen extends ConsumerStatefulWidget {
// //   const PartnerDashboardScreen({super.key});

// //   @override
// //   ConsumerState<PartnerDashboardScreen> createState() =>
// //       _PartnerDashboardScreenState();
// // }

// // class _PartnerDashboardScreenState extends ConsumerState<PartnerDashboardScreen>
// //     with SingleTickerProviderStateMixin {
// //   bool _isPaymentFlipped = false;
// //   late AnimationController _flipController;
// //   late Animation<double> _flipAnimation;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _flipController = AnimationController(
// //       vsync: this,
// //       duration: const Duration(milliseconds: 500),
// //     );
// //     _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
// //       CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
// //     );
// //   }

// //   @override
// //   void dispose() {
// //     _flipController.dispose();
// //     super.dispose();
// //   }

// //   void _togglePaymentCard() {
// //     setState(() {
// //       _isPaymentFlipped = !_isPaymentFlipped;
// //       _isPaymentFlipped ? _flipController.forward() : _flipController.reverse();
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final profileAsync = ref.watch(teacherProfileProvider);

// //     return RefreshIndicator(
// //       onRefresh: () {
// //         return ref.refresh(teacherProfileProvider.future);
// //       },
// //       child: CustomScrolling(
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             const SizedBox(height: 10),

 
// //             profileAsync.when(
// //               loading: () => const _SkeletonGrid(),
// //               error: (_, __) => _buildGrid(context, null),  
// //               data: (profile) => _buildGrid(context, profile),
// //             ),

            
// //             // const SizedBox(height: 30),
// //             // Container(
// //             //   width: double.infinity,
// //             //   height: 250,
// //             //   decoration: BoxDecoration(
// //             //     borderRadius: BorderRadius.circular(14),
// //             //     border: Border.all(color: Colors.black),
// //             //   ),
// //             //   child: Padding(
// //             //     padding: const EdgeInsets.only(
// //             //       right: 8,
// //             //       left: 8,
// //             //       top: 10,
// //             //       bottom: 8,
// //             //     ),
// //             //     child: Column(
// //             //       children: [
// //             //         Center(
// //             //           child: Text(
// //             //             'This Week Classes',
// //             //             style: TextStyle(
// //             //               fontSize: 20,
// //             //               fontFamily: AppStyle.fontFamilySecondary,
// //             //             ),
// //             //           ),
// //             //         ),
// //             //         const SizedBox(height: 15),
// //             //         Expanded(
// //             //           child: SingleChildScrollView(
// //             //             scrollDirection: Axis.horizontal,
// //             //             child: _thisWeekClassesTable(),
// //             //           ),
// //             //         ),
// //             //       ],
// //             //     ),
// //             //   ),
// //             // ),

             
// //             // const SizedBox(height: 30),
// //             // Container(
// //             //   width: double.infinity,
// //             //   height: 250,
// //             //   decoration: BoxDecoration(
// //             //     borderRadius: BorderRadius.circular(14),
// //             //     border: Border.all(color: Colors.black),
// //             //   ),
// //             //   child: SingleChildScrollView(
// //             //     child: Padding(
// //             //       padding: const EdgeInsets.only(right: 8, left: 8, top: 10),
// //             //       child: Column(
// //             //         crossAxisAlignment: CrossAxisAlignment.start,
// //             //         children: [
// //             //           const Center(
// //             //             child: Text(
// //             //               'Leaderboard',
// //             //               style: TextStyle(fontSize: 20, fontFamily: 'Inter'),
// //             //             ),
// //             //           ),
// //             //           const SizedBox(height: 8),
// //             //           const Text('You are ranked #4 this week'),
// //             //           const SizedBox(height: 16),
// //             //           leaderboardWidget(),
// //             //         ],
// //             //       ),
// //             //     ),
// //             //   ),
// //             // ),

           
// //             // const SizedBox(height: 30),
// //             // Container(
// //             //   width: double.infinity,
// //             //   height: 250,
// //             //   decoration: BoxDecoration(
// //             //     borderRadius: BorderRadius.circular(14),
// //             //     border: Border.all(color: Colors.black),
// //             //   ),
// //             //   child: Padding(
// //             //     padding: const EdgeInsets.only(
// //             //       right: 8,
// //             //       left: 8,
// //             //       top: 10,
// //             //       bottom: 5,
// //             //     ),
// //             //     child: Column(
// //             //       crossAxisAlignment: CrossAxisAlignment.start,
// //             //       children: [
// //             //         const Text(
// //             //           'Student Monitoring',
// //             //           style: TextStyle(fontSize: 20, fontFamily: 'Inter'),
// //             //         ),
// //             //         const SizedBox(height: 16),
// //             //         Row(
// //             //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //             //           children: [
// //             //             Container(
// //             //               decoration: BoxDecoration(
// //             //                 borderRadius: BorderRadius.circular(5),
// //             //                 border: Border.all(color: Colors.black),
// //             //               ),
// //             //               child: const Padding(
// //             //                 padding: EdgeInsets.symmetric(
// //             //                   horizontal: 8,
// //             //                   vertical: 0,
// //             //                 ),
// //             //                 child: Text('Class 1- Attendance'),
// //             //               ),
// //             //             ),
// //             //             IconButton(
// //             //               onPressed: () {},
// //             //               icon: Icon(
// //             //                 Icons.filter_alt,
// //             //                 color: AppStyle.primaryColor,
// //             //                 size: 30,
// //             //               ),
// //             //             ),
// //             //           ],
// //             //         ),
// //             //         Expanded(
// //             //           child: SingleChildScrollView(
// //             //             scrollDirection: Axis.horizontal,
// //             //             child: _studentMonitoringTable(),
// //             //           ),
// //             //         ),
// //             //       ],
// //             //     ),
// //             //   ),
// //             // ),
// //             // const SizedBox(height: 30),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

 
// //   Widget _buildGrid(BuildContext context, dynamic profile) {
// //     final int schoolCount = profile?.earnings.schools.length ?? 0;
// //     final int totalClasses =
// //         profile == null
// //             ? 0
// //             : (profile.earnings.schools as List).fold<int>(
// //               0,
// //               (sum, s) => sum + (s.classesCount as int),
// //             );
// //     final double totalEarnings = profile?.earnings.totalEarnings ?? 0.0;
// //     final double paid = profile?.earnings.totalPaid ?? 0.0;
// //     final double pending = profile?.earnings.totalPending ?? 0.0;
// //     final double projected = profile?.earnings.projectedEarnings ?? 0.0;
// //     final double paidPct =
// //         totalEarnings > 0 ? (paid / totalEarnings) * 100 : 0.0;
// //     final double pendingPct =
// //         totalEarnings > 0 ? (pending / totalEarnings) * 100 : 0.0;
// //     final bool noData = profile == null;

// //     return GridView(
// //       shrinkWrap: true,
// //       padding: EdgeInsets.zero,
// //       physics: const NeverScrollableScrollPhysics(),
// //       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
// //         crossAxisCount: 2,
// //         childAspectRatio: 1.4,
// //         crossAxisSpacing: 10,
// //         mainAxisSpacing: 10,
// //       ),
// //       children: [
      
// //         Card(
// //           shape: RoundedRectangleBorder(
// //             borderRadius: BorderRadius.circular(25),
// //           ),
// //           color: Colors.white,
// //           elevation: 5,
// //           child: Padding(
// //             padding: const EdgeInsets.only(right: 15, left: 15, top: 10),
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 FittedBox(
// //                   child: Text(
// //                     'Profile Status',
// //                     style: AppStyle.heading2.copyWith(
// //                       fontWeight: FontWeight.bold,
// //                       fontFamily: AppStyle.fontFamilySecondary,
// //                       fontSize: 15,
// //                     ),
// //                   ),
// //                 ),
// //                 Flexible(
// //                   child: CustomPaint(
                  
// //                     painter: const ProfileStatusCircularPercentage(
// //                       percentage: 75,
// //                     ),
// //                     size: Size(
// //                       context.screenWidth * 0.2,
// //                       context.screenHeight * 0.1,
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
 
// //         Card(
// //           shape: RoundedRectangleBorder(
// //             borderRadius: BorderRadius.circular(25),
// //           ),
// //           color: Colors.white,
// //           elevation: 5,
// //           child: Padding(
// //             padding: const EdgeInsets.only(
// //               right: 17,
// //               left: 17,
// //               top: 10,
// //               bottom: 10,
// //             ),
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 FittedBox(
// //                   child: Text(
// //                     'Assigned Schools',
// //                     style: AppStyle.heading2.copyWith(
// //                       fontWeight: FontWeight.bold,
// //                       fontFamily: AppStyle.fontFamilySecondary,
// //                       fontSize: 15,
// //                     ),
// //                   ),
// //                 ),
// //                 SizedBox(height: context.screenHeight * 0.009),
// //                 Center(
// //                   child: Text(
// //                     noData ? '—' : '$schoolCount',
// //                     style: AppStyle.bodyText.copyWith(
// //                       color: Colors.black,
// //                       fontSize: 15,
// //                       fontFamily: 'Inter',
// //                     ),
// //                   ),
// //                 ),
// //                 SizedBox(height: context.screenHeight * 0.009),
// //                 Padding(
// //                   padding: const EdgeInsets.only(left: 10),
// //                   child: Container(
// //                     decoration: BoxDecoration(
// //                       color: AppStyle.backgroundColor,
// //                       borderRadius: BorderRadius.circular(10),
// //                     ),
// //                     child: FittedBox(
// //                       child: Padding(
// //                         padding: const EdgeInsets.only(
// //                           right: 10,
// //                           left: 10,
// //                           bottom: 5,
// //                           top: 5,
// //                         ),
// //                         child: Row(
// //                           children: [
// //                             Image.asset(
// //                               'assets/kms/school.png',
// //                               height: 15,
// //                               width: 15,
// //                               color: AppStyle.primaryColor,
// //                             ),
// //                             const SizedBox(width: 5),
// //                             Text(
// //                               noData
// //                                   ? 'No Classes Yet'
// //                                   : '$totalClasses Classes',
// //                             ),
// //                           ],
// //                         ),
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),

 
// //         Card(
// //           shape: RoundedRectangleBorder(
// //             borderRadius: BorderRadius.circular(25),
// //           ),
// //           color: Colors.white,
// //           elevation: 5,
// //           child: Padding(
// //             padding: const EdgeInsets.only(right: 15, left: 15, top: 10),
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 FittedBox(
// //                   child: Text(
// //                     'Task Overview',
// //                     style: AppStyle.heading2.copyWith(
// //                       fontWeight: FontWeight.bold,
// //                       fontFamily: AppStyle.fontFamilySecondary,
// //                       fontSize: 15,
// //                     ),
// //                   ),
// //                 ),
// //                 if (noData)
// //                   Expanded(
// //                     child: Center(
// //                       child: Text(
// //                         'No tasks yet',
// //                         style: TextStyle(
// //                           fontSize: 11,
// //                           color: Colors.grey.shade400,
// //                           fontFamily: 'Inter',
// //                         ),
// //                       ),
// //                     ),
// //                   )
// //                 else
// //                   Padding(
// //                     padding: const EdgeInsets.only(top: 5, right: 5, left: 5),
// //                     child: Column(
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       children: [
          
// //                         Row(
// //                           children: const [
// //                             Text('3', style: TextStyle(fontFamily: 'Inter')),
// //                             SizedBox(width: 10),
// //                             Text('Completed'),
// //                           ],
// //                         ),
// //                         Row(
// //                           children: const [
// //                             Text('3', style: TextStyle(fontFamily: 'Inter')),
// //                             SizedBox(width: 10),
// //                             Text('Pending'),
// //                           ],
// //                         ),
// //                         SizedBox(height: context.screenHeight * 0.01),
// //                         Center(
// //                           child: ClipRRect(
// //                             borderRadius: BorderRadiusGeometry.circular(10),
// //                             child: SizedBox(
// //                               width: 100,
// //                               height: 20,
// //                               child: Row(
// //                                 children: [
// //                                   Expanded(
// //                                     flex: 500,
// //                                     child: Container(
// //                                       color: AppStyle.primaryColor,
// //                                     ),
// //                                   ),
// //                                   Expanded(
// //                                     flex: 500,
// //                                     child: Container(color: Colors.grey),
// //                                   ),
// //                                 ],
// //                               ),
// //                             ),
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //               ],
// //             ),
// //           ),
// //         ),

 
// //         GestureDetector(
// //           onTap: _togglePaymentCard,
// //           child: AnimatedBuilder(
// //             animation: _flipAnimation,
// //             builder: (context, _) {
// //               final isFront = _flipAnimation.value < 0.5;
// //               final angle = _flipAnimation.value * pi;
// //               return Transform(
// //                 transform:
// //                     Matrix4.identity()
// //                       ..setEntry(3, 2, 0.001)
// //                       ..rotateY(angle),
// //                 alignment: Alignment.center,
// //                 child:
// //                     isFront
// //                         ? _paymentFront(context, paidPct, pendingPct, noData)
// //                         : Transform(
// //                           transform: Matrix4.identity()..rotateY(pi),
// //                           alignment: Alignment.center,
// //                           child: _paymentBack(
// //                             context,
// //                             total: totalEarnings,
// //                             paid: paid,
// //                             pending: pending,
// //                             projected: projected,
// //                             noData: noData,
// //                           ),
// //                         ),
// //               );
// //             },
// //           ),
// //         ),
// //       ],
// //     );
// //   }

 
// //   Widget _paymentFront(
// //     BuildContext context,
// //     double paidPct,
// //     double pendingPct,
// //     bool noData,
// //   ) {
// //     return Card(
// //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
// //       color: Colors.white,
// //       elevation: 5,
// //       child: Padding(
// //         padding: const EdgeInsets.only(right: 15, left: 15, top: 10),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Row(
// //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //               children: [
// //                 FittedBox(
// //                   child: Text(
// //                     'Payment',
// //                     style: AppStyle.heading2.copyWith(
// //                       fontWeight: FontWeight.bold,
// //                       fontFamily: AppStyle.fontFamilySecondary,
// //                       fontSize: 15,
// //                     ),
// //                   ),
// //                 ),
// //                 const Icon(Icons.touch_app, size: 14, color: Colors.grey),
// //               ],
// //             ),
// //             if (noData)
// //               Expanded(
// //                 child: Center(
// //                   child: Text(
// //                     'No payment\ndata yet',
// //                     textAlign: TextAlign.center,
// //                     style: TextStyle(
// //                       fontSize: 11,
// //                       color: Colors.grey.shade400,
// //                       fontFamily: 'Inter',
// //                     ),
// //                   ),
// //                 ),
// //               )
// //             else
// //               FittedBox(
// //                 child: Row(
// //                   children: [
// //                     CustomPaint(
// //                       painter: PaymentPieChart(
// //                         paidPercentage: paidPct,
// //                         pendingPercentage: pendingPct,
// //                       ),
// //                       size: Size(
// //                         context.screenWidth * 0.2,
// //                         context.screenHeight * 0.1,
// //                       ),
// //                     ),
// //                     const SizedBox(width: 10),
// //                     Column(
// //                       mainAxisAlignment: MainAxisAlignment.end,
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       children: [
// //                         _distributionChart(const Color(0xffF8BD00), 'Pending'),
// //                         _distributionChart(AppStyle.primaryColor, 'Paid'),
// //                       ],
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
 
// //   Widget _paymentBack(
// //     BuildContext context, {
// //     required double total,
// //     required double paid,
// //     required double pending,
// //     required double projected,
// //     required bool noData,
// //   }) {
// //     return Card(
// //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
// //       color: Colors.white,
// //       elevation: 5,
// //       child: Padding(
// //         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Row(
// //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //               children: [
// //                 FittedBox(
// //                   child: Text(
// //                     'Payment',
// //                     style: AppStyle.heading2.copyWith(
// //                       fontWeight: FontWeight.bold,
// //                       fontFamily: AppStyle.fontFamilySecondary,
// //                       fontSize: 15,
// //                     ),
// //                   ),
// //                 ),
// //                 const Icon(Icons.touch_app, size: 14, color: Colors.grey),
// //               ],
// //             ),
// //             const SizedBox(height: 4),
// //             if (noData)
// //               Expanded(
// //                 child: Center(
// //                   child: Text(
// //                     'No payment\ndata yet',
// //                     textAlign: TextAlign.center,
// //                     style: TextStyle(
// //                       fontSize: 11,
// //                       color: Colors.grey.shade400,
// //                       fontFamily: 'Inter',
// //                     ),
// //                   ),
// //                 ),
// //               )
// //             else ...[
// //               _amountRow('Total', total, Colors.black),
// //               _amountRow('Paid', paid, AppStyle.primaryColor),
// //               _amountRow('Pending', pending, const Color(0xffF8BD00)),
// //               _amountRow('Projected', projected, Colors.blueGrey),
// //             ],
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _amountRow(String label, double amount, Color color) {
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(vertical: 2),
// //       child: Row(
// //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //         children: [
// //           Text(
// //             label,
// //             style: const TextStyle(
// //               fontSize: 11,
// //               fontFamily: 'Inter',
// //               color: Colors.black87,
// //             ),
// //           ),
// //           Text(
// //             'Rs. ${amount.toStringAsFixed(1)}',
// //             style: TextStyle(
// //               fontSize: 11,
// //               fontFamily: 'Inter',
// //               fontWeight: FontWeight.bold,
// //               color: color,
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _distributionChart(Color color, String text) {
// //     return Row(
// //       children: [
// //         Container(
// //           width: 10,
// //           height: 5,
// //           decoration: BoxDecoration(shape: BoxShape.rectangle, color: color),
// //         ),
// //         const SizedBox(width: 10),
// //         Text(text, style: const TextStyle(color: Colors.black, fontSize: 14)),
// //       ],
// //     );
// //   }
// // }
 
// // class _SkeletonGrid extends StatefulWidget {
// //   const _SkeletonGrid();

// //   @override
// //   State<_SkeletonGrid> createState() => _SkeletonGridState();
// // }

// // class _SkeletonGridState extends State<_SkeletonGrid>
// //     with SingleTickerProviderStateMixin {
// //   late AnimationController _ctrl;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _ctrl = AnimationController(
// //       vsync: this,
// //       duration: const Duration(milliseconds: 1000),
// //     )..repeat(reverse: true);
// //   }

// //   @override
// //   void dispose() {
// //     _ctrl.dispose();
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return AnimatedBuilder(
// //       animation: _ctrl,
// //       builder:
// //           (context, _) => GridView(
// //             shrinkWrap: true,
// //             padding: EdgeInsets.zero,
// //             physics: const NeverScrollableScrollPhysics(),
// //             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
// //               crossAxisCount: 2,
// //               childAspectRatio: 1.4,
// //               crossAxisSpacing: 10,
// //               mainAxisSpacing: 10,
// //             ),
// //             children: List.generate(4, (i) => _buildSkeletonCard(i)),
// //           ),
// //     );
// //   }

// //   Widget _buildSkeletonCard(int index) { 
// //     final double phase = (_ctrl.value + index * 0.2) % 1.0;
// //     final double opacity = 0.3 + (0.5 * (sin(phase * pi)));

// //     return Card(
// //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
// //       color: Colors.white,
// //       elevation: 5,
// //       child: Padding(
// //         padding: const EdgeInsets.all(14),
// //         child: Opacity(
// //           opacity: opacity,
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [ 
// //               _box(width: 90, height: 11),
// //               const SizedBox(height: 14),
// //               // Card-specific skeleton body
// //               if (index == 0) ...[
// //                 // Profile status → circle
// //                 Center(child: _circle(52)),
// //               ] else if (index == 1) ...[
// //                 // Assigned schools → number + pill
// //                 Center(child: _box(width: 28, height: 18)),
// //                 const SizedBox(height: 8),
// //                 _box(width: 85, height: 22, radius: 11),
// //               ] else if (index == 2) ...[
// //                 // Task overview → two lines + progress bar
// //                 _box(width: double.infinity, height: 10),
// //                 const SizedBox(height: 7),
// //                 _box(width: double.infinity, height: 10),
// //                 const SizedBox(height: 10),
// //                 Center(child: _box(width: 100, height: 18, radius: 9)),
// //               ] else ...[
// //                 // Payment → fake pie + legend
// //                 Row(
// //                   children: [
// //                     _circle(48),
// //                     const SizedBox(width: 12),
// //                     Column(
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       children: [
// //                         _box(width: 52, height: 8),
// //                         const SizedBox(height: 8),
// //                         _box(width: 52, height: 8),
// //                       ],
// //                     ),
// //                   ],
// //                 ),
// //               ],
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _box({required double width, double height = 12, double radius = 6}) =>
// //       Container(
// //         width: width,
// //         height: height,
// //         decoration: BoxDecoration(
// //           color: Colors.grey.shade300,
// //           borderRadius: BorderRadius.circular(radius),
// //         ),
// //       );

// //   Widget _circle(double size) => Container(
// //     width: size,
// //     height: size,
// //     decoration: BoxDecoration(
// //       color: Colors.grey.shade300,
// //       shape: BoxShape.circle,
// //     ),
// //   );
// // }

 
// // Widget leaderboardWidget() {
// //   return Column(
// //     crossAxisAlignment: CrossAxisAlignment.start,
// //     children: [
// //       Row(
// //         children: const [
// //           Expanded(
// //             flex: 1,
// //             child: Text(
// //               'S.N.',
// //               style: TextStyle(
// //                 fontWeight: FontWeight.bold,
// //                 fontFamily: 'Inter',
// //               ),
// //             ),
// //           ),
// //           Expanded(
// //             flex: 3,
// //             child: Center(
// //               child: Text(
// //                 'Name',
// //                 style: TextStyle(
// //                   fontWeight: FontWeight.bold,
// //                   fontFamily: 'Inter',
// //                 ),
// //               ),
// //             ),
// //           ),
// //           Expanded(
// //             flex: 1,
// //             child: Text(
// //               'Score',
// //               style: TextStyle(
// //                 fontWeight: FontWeight.bold,
// //                 fontFamily: 'Inter',
// //               ),
// //               textAlign: TextAlign.right,
// //             ),
// //           ),
// //         ],
// //       ),
// //       const Divider(thickness: 1, color: Colors.black),
// //       _buildLeaderBoardRow('1.', 'John Doe', '9'),
// //       _buildLeaderBoardRow('2.', 'John Doe', '8'),
// //       _buildLeaderBoardRow('3.', 'John Doe', '7'),
// //       _buildLeaderBoardRow('4.', 'John Doe', '6.5'),
// //       _buildLeaderBoardRow('5.', 'John Doe', '6'),
// //     ],
// //   );
// // }

// // Widget _buildLeaderBoardRow(String sn, String name, String score) {
// //   return Padding(
// //     padding: const EdgeInsets.symmetric(vertical: 4),
// //     child: Column(
// //       children: [
// //         Row(
// //           children: [
// //             Expanded(flex: 1, child: Text(sn)),
// //             Expanded(
// //               flex: 3,
// //               child: Center(
// //                 child: Text(
// //                   name,
// //                   style: const TextStyle(fontWeight: FontWeight.normal),
// //                 ),
// //               ),
// //             ),
// //             Expanded(
// //               flex: 1,
// //               child: Text(
// //                 score,
// //                 textAlign: TextAlign.right,
// //                 style: const TextStyle(fontWeight: FontWeight.normal),
// //               ),
// //             ),
// //           ],
// //         ),
// //         const Divider(color: Colors.grey),
// //       ],
// //     ),
// //   );
// // }


// // // Widget _thisWeekClassesTable() {
// // //   return SingleChildScrollView(
// // //     child: DataTable(
// // //       columnSpacing: 30,
// // //       headingRowHeight: 40,
// // //       dataRowMaxHeight: 50,
// // //       columns: const [
// // //         DataColumn(
// // //           label: Text(
// // //             'School Name',
// // //             style: TextStyle(
// // //               fontWeight: FontWeight.bold,
// // //               fontFamily: 'Inter',
// // //               fontSize: 12,
// // //             ),
// // //           ),
// // //         ),
// // //         DataColumn(
// // //           label: Text(
// // //             'Chapter',
// // //             style: TextStyle(
// // //               fontWeight: FontWeight.bold,
// // //               fontFamily: 'Inter',
// // //               fontSize: 12,
// // //             ),
// // //           ),
// // //         ),
// // //         DataColumn(
// // //           label: Text(
// // //             'Weeks',
// // //             style: TextStyle(
// // //               fontWeight: FontWeight.bold,
// // //               fontFamily: 'Inter',
// // //               fontSize: 12,
// // //             ),
// // //           ),
// // //         ),
// // //         DataColumn(
// // //           label: Text(
// // //             'Weeks Completed',
// // //             style: TextStyle(
// // //               fontWeight: FontWeight.bold,
// // //               fontFamily: 'Inter',
// // //               fontSize: 12,
// // //             ),
// // //           ),
// // //         ),
// // //       ],
// // //       rows: [
// // //         _thisWeekClassesDataRow('Patan Multiple Campus', '2', '6', '5'),
// // //         _thisWeekClassesDataRow('Vidya Sadan', '1', '5', '5'),
// // //         _thisWeekClassesDataRow(
// // //           'Nepatronix Institute of Science and Technology',
// // //           '1',
// // //           '7',
// // //           '6',
// // //         ),
// // //         _thisWeekClassesDataRow('National Info Tech', '2', '6', '4'),
// // //         _thisWeekClassesDataRow(
// // //           'Madan Bhandari Memorial School',
// // //           '2',
// // //           '6',
// // //           '5',
// // //         ),
// // //       ],
// // //     ),
// // //   );
// // // }

// // // DataRow _thisWeekClassesDataRow(
// // //   String schoolName,
// // //   String chapter,
// // //   String weeks,
// // //   String weeksCompleted,
// // // ) {
// // //   return DataRow(
// // //     cells: [
// // //       DataCell(
// // //         SizedBox(
// // //           width: 190,
// // //           child: Text(schoolName, style: const TextStyle(fontSize: 11)),
// // //         ),
// // //       ),
// // //       DataCell(Text(chapter, style: const TextStyle(fontSize: 11))),
// // //       DataCell(Text(weeks, style: const TextStyle(fontSize: 11))),
// // //       DataCell(Text(weeksCompleted, style: const TextStyle(fontSize: 11))),
// // //     ],
// // //   );
// // // }


// // // Widget _studentMonitoringTable() {
// // //   return SingleChildScrollView(
// // //     child: DataTable(
// // //       columnSpacing: 25,
// // //       headingRowHeight: 40,
// // //       dataRowMaxHeight: 50,
// // //       columns: const [
// // //         DataColumn(
// // //           label: Text(
// // //             'Name',
// // //             style: TextStyle(
// // //               fontWeight: FontWeight.bold,
// // //               fontFamily: 'Inter',
// // //               fontSize: 12,
// // //             ),
// // //           ),
// // //         ),
// // //         DataColumn(
// // //           label: Text(
// // //             'Total Classes',
// // //             style: TextStyle(
// // //               fontWeight: FontWeight.bold,
// // //               fontFamily: 'Inter',
// // //               fontSize: 12,
// // //             ),
// // //           ),
// // //         ),
// // //         DataColumn(
// // //           label: Text(
// // //             'Present',
// // //             style: TextStyle(
// // //               fontWeight: FontWeight.bold,
// // //               fontFamily: 'Inter',
// // //               fontSize: 12,
// // //             ),
// // //           ),
// // //         ),
// // //         DataColumn(
// // //           label: Text(
// // //             'Absent',
// // //             style: TextStyle(
// // //               fontWeight: FontWeight.bold,
// // //               fontFamily: 'Inter',
// // //               fontSize: 12,
// // //             ),
// // //           ),
// // //         ),
// // //         DataColumn(
// // //           label: Text(
// // //             'Assignment',
// // //             style: TextStyle(
// // //               fontWeight: FontWeight.bold,
// // //               fontFamily: 'Inter',
// // //               fontSize: 12,
// // //             ),
// // //           ),
// // //         ),
// // //         DataColumn(
// // //           label: Text(
// // //             'Marks',
// // //             style: TextStyle(
// // //               fontWeight: FontWeight.bold,
// // //               fontFamily: 'Inter',
// // //               fontSize: 12,
// // //             ),
// // //           ),
// // //         ),
// // //       ],
// // //       rows: [
// // //         _studentMonitoringDataRow('John Doe', '20', '22', '1', '3/5', '90'),
// // //         _studentMonitoringDataRow(
// // //           'Alice Johnson',
// // //           '45',
// // //           '24',
// // //           '0',
// // //           '3/6',
// // //           '46',
// // //         ),
// // //         _studentMonitoringDataRow(
// // //           'Raju Shrestha',
// // //           '56',
// // //           '21',
// // //           '7',
// // //           '9/1',
// // //           '65',
// // //         ),
// // //         _studentMonitoringDataRow(
// // //           'Ronit Srivastav',
// // //           '53',
// // //           '10',
// // //           '4',
// // //           '1/8',
// // //           '78',
// // //         ),
// // //       ],
// // //     ),
// // //   );
// // // }

// // // DataRow _studentMonitoringDataRow(
// // //   String name,
// // //   String totalClasses,
// // //   String present,
// // //   String absent,
// // //   String assignment,
// // //   String marks,
// // // ) {
// // //   return DataRow(
// // //     cells: [
// // //       DataCell(Text(name, style: const TextStyle(fontSize: 11))),
// // //       DataCell(Text(totalClasses, style: const TextStyle(fontSize: 11))),
// // //       DataCell(Text(present, style: const TextStyle(fontSize: 11))),
// // //       DataCell(Text(absent, style: const TextStyle(fontSize: 11))),
// // //       DataCell(Text(assignment, style: const TextStyle(fontSize: 11))),
// // //       DataCell(Text(marks, style: const TextStyle(fontSize: 11))),
// // //     ],
// // //   );
// // // }

 
// // class ProfileStatusCircularPercentage extends CustomPainter {
// //   final double percentage;
// //   final Color segmentColor;

// //   const ProfileStatusCircularPercentage({
// //     required this.percentage,
// //     this.segmentColor = AppStyle.primaryColor,
// //   });

// //   @override
// //   void paint(Canvas canvas, Size size) {
// //     final center = Offset(size.width / 1.4, size.height / 2.5);
// //     final radius = min(size.width, size.height) * 0.4;
// //     final innerRadius = radius * 0.74;
// //     final paint = Paint()..style = PaintingStyle.fill;
// //     final double clamped = percentage.clamp(0.0, 100.0);
// //     final segs = [
// //       if (clamped > 0) _PieSegment(clamped, segmentColor),
// //       if (100.0 - clamped > 0)
// //         _PieSegment(100.0 - clamped, const Color(0xffDDFFE7)),
// //     ];
// //     final total = segs.fold(0.0, (s, e) => s + e.value);
// //     double start = -pi / -4.8;
// //     for (final seg in segs) {
// //       final sweep = (seg.value / total) * 2 * pi;
// //       paint.color = seg.color;
// //       canvas.drawArc(
// //         Rect.fromCircle(center: center, radius: radius),
// //         start,
// //         sweep,
// //         true,
// //         paint,
// //       );
// //       start += sweep;
// //     }
// //     canvas.drawCircle(
// //       center,
// //       innerRadius,
// //       Paint()..color = const Color(0xffDDFFE7),
// //     );
// //     final tp =
// //         TextPainter(textDirection: TextDirection.rtl)
// //           ..text = TextSpan(
// //             text: '${clamped.toInt()}%',
// //             style: const TextStyle(
// //               color: Colors.black,
// //               fontSize: 15,
// //               fontWeight: FontWeight.bold,
// //               fontFamily: 'Inter',
// //             ),
// //           )
// //           ..layout();
// //     tp.paint(
// //       canvas,
// //       Offset(center.dx - tp.width / 2.3, center.dy - tp.height / 2),
// //     );
// //   }

// //   @override
// //   bool shouldRepaint(ProfileStatusCircularPercentage old) =>
// //       old.percentage != percentage;
// // }

// // class _PieSegment {
// //   final double value;
// //   final Color color;
// //   const _PieSegment(this.value, this.color);
// // }

 
// // class PaymentPieChart extends CustomPainter {
// //   final double paidPercentage;
// //   final double pendingPercentage;

// //   const PaymentPieChart({
// //     required this.paidPercentage,
// //     required this.pendingPercentage,
// //   });

// //   @override
// //   void paint(Canvas canvas, Size size) {
// //     final center = Offset(size.width / 2, size.height / 2);
// //     final radius = min(size.width, size.height) * 0.48;
// //     final paint = Paint()..style = PaintingStyle.fill;
// //     final segs = [
// //       _PaySeg(paidPercentage, AppStyle.primaryColor),
// //       _PaySeg(pendingPercentage, const Color(0xffF8BD00)),
// //     ];
// //     final total = segs.fold(0.0, (s, e) => s + e.value);
// //     if (total == 0) {
// //       paint.color = Colors.grey.shade300;
// //       canvas.drawCircle(center, radius, paint);
// //       return;
// //     }
// //     double start = -pi / 2;
// //     for (final seg in segs) {
// //       if (seg.value <= 0) continue;
// //       final sweep = (seg.value / total) * 2.5 * pi;
// //       paint.color = seg.color;
// //       canvas.drawArc(
// //         Rect.fromCircle(center: center, radius: radius),
// //         start,
// //         sweep,
// //         true,
// //         paint,
// //       );
// //       final ta = start + sweep / 2.5;
// //       final tr = radius * 0.66;
// //       final tp =
// //           TextPainter(textDirection: TextDirection.ltr)
// //             ..text = TextSpan(
// //               text: '${seg.value.toInt()}%',
// //               style: const TextStyle(
// //                 color: Colors.black,
// //                 fontSize: 14,
// //                 fontWeight: FontWeight.bold,
// //               ),
// //             )
// //             ..layout();
// //       tp.paint(
// //         canvas,
// //         Offset(
// //           center.dx + tr * cos(ta) - tp.width / 2,
// //           center.dy + tr * sin(ta) - tp.height / 2,
// //         ),
// //       );
// //       start += sweep;
// //     }
// //   }

// //   @override
// //   bool shouldRepaint(PaymentPieChart old) =>
// //       old.paidPercentage != paidPercentage ||
// //       old.pendingPercentage != pendingPercentage;
// // }

// // class _PaySeg {
// //   final double value;
// //   final Color color;
// //   const _PaySeg(this.value, this.color);
// // }

// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:innovator/KMS/core/constants/app_style.dart';
// import 'package:innovator/KMS/core/constants/mediaquery.dart';
// import 'package:innovator/KMS/screens/constant_screen/custom_scroll.dart';
// import 'package:innovator/KMS/provider/teacher_provider.dart';
// import 'package:innovator/KMS/screens/partner/kyc_upload_screen.dart';

// class PartnerDashboardScreen extends ConsumerStatefulWidget {
//   const PartnerDashboardScreen({super.key});

//   @override
//   ConsumerState<PartnerDashboardScreen> createState() =>
//       _PartnerDashboardScreenState();
// }

// class _PartnerDashboardScreenState extends ConsumerState<PartnerDashboardScreen>
//     with SingleTickerProviderStateMixin {
//   bool _isPaymentFlipped = false;
//   late AnimationController _flipController;
//   late Animation<double> _flipAnimation;

//   final Map<String, bool> _checkedInMap = {};
//   final Map<String, bool> _loadingMap = {};

//   @override
//   void initState() {
//     super.initState();
//     _flipController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 500),
//     );
//     _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
//       CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
//     );
//   }

//   @override
//   void dispose() {
//     _flipController.dispose();
//     super.dispose();
//   }

//   void _togglePaymentCard() {
//     setState(() {
//       _isPaymentFlipped = !_isPaymentFlipped;
//       _isPaymentFlipped ? _flipController.forward() : _flipController.reverse();
//     });
//   }

//   Future<void> _handleCheckIn(String schoolId) async {
//     setState(() => _loadingMap[schoolId] = true);
//     try {
//       await ref.read(checkInProvider(schoolId).future);
//       setState(() => _checkedInMap[schoolId] = true);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: const Row(children: [
//               Icon(Icons.check_circle, color: Colors.white, size: 18),
//               SizedBox(width: 8),
//               Text('Checked in successfully!'),
//             ]),
//             backgroundColor: AppStyle.primaryColor,
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Check-in failed: $e'),
//             backgroundColor: Colors.red.shade400,
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           ),
//         );
//       }
//     } finally {
//       setState(() => _loadingMap[schoolId] = false);
//     }
//   }

//   Future<void> _handleCheckOut(String schoolId) async {
//     setState(() => _loadingMap[schoolId] = true);
//     try {
//       await ref.read(checkOutProvider(schoolId).future);
//       setState(() => _checkedInMap[schoolId] = false);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: const Row(children: [
//               Icon(Icons.logout, color: Colors.white, size: 18),
//               SizedBox(width: 8),
//               Text('Checked out successfully!'),
//             ]),
//             backgroundColor: Colors.blueGrey,
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Check-out failed: $e'),
//             backgroundColor: Colors.red.shade400,
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           ),
//         );
//       }
//     } finally {
//       setState(() => _loadingMap[schoolId] = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final profileAsync = ref.watch(teacherProfileProvider);

//     return RefreshIndicator(
//       onRefresh: () => ref.refresh(teacherProfileProvider.future),
//       child: CustomScrolling(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 10),
//             profileAsync.when(
//               loading: () => const _SkeletonGrid(),
//               error: (_, __) => _buildGrid(context, null),
//               data: (profile) => _buildGrid(context, profile),
//             ),
//             const SizedBox(height: 24),
//             profileAsync.when(
//               loading: () => const _CheckInSkeleton(),
//               error: (_, __) => const SizedBox.shrink(),
//               data: (profile) => _buildCheckInSection(profile),
//             ),
//             const SizedBox(height: 20),
//             _buildKycBanner(context),
//             const SizedBox(height: 30),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCheckInSection(dynamic profile) {
//     if (profile == null) return const SizedBox.shrink();
//     final schools = profile.earnings.schools as List;
//     if (schools.isEmpty) return const SizedBox.shrink();

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Attendance',
//           style: AppStyle.heading2.copyWith(
//             fontWeight: FontWeight.bold,
//             fontFamily: AppStyle.fontFamilySecondary,
//             fontSize: 18,
//           ),
//         ),
//         const SizedBox(height: 12),
//         ...schools.map((school) {
//           final schoolId = school.schoolId as String;
//           final schoolName = school.schoolName as String;
//           return _CheckInCard(
//             schoolId: schoolId,
//             schoolName: schoolName,
//             isCheckedIn: _checkedInMap[schoolId] ?? false,
//             isLoading: _loadingMap[schoolId] ?? false,
//             onCheckIn: () => _handleCheckIn(schoolId),
//             onCheckOut: () => _handleCheckOut(schoolId),
//           );
//         }),
//       ],
//     );
//   }

//   Widget _buildKycBanner(BuildContext context) {
//     return GestureDetector(
//       onTap: () => Navigator.push(
//         context,
//         MaterialPageRoute(builder: (_) => const KycUploadScreen()),
//       ),
//       child: Container(
//         width: double.infinity,
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               AppStyle.primaryColor,
//               AppStyle.primaryColor.withValues(alpha: 0.78),
//             ],
//             begin: Alignment.centerLeft,
//             end: Alignment.centerRight,
//           ),
//           borderRadius: BorderRadius.circular(18),
//           boxShadow: [
//             BoxShadow(
//               color: AppStyle.primaryColor.withValues(alpha: 0.28),
//               blurRadius: 12,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//           child: Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withValues(alpha: 0.2),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Icon(Icons.verified_user_rounded,
//                     color: Colors.white, size: 28),
//               ),
//               const SizedBox(width: 16),
//               const Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'KYC Verification',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 15,
//                         fontFamily: 'Inter',
//                       ),
//                     ),
//                     SizedBox(height: 3),
//                     Text(
//                       'Upload your identity document to verify',
//                       style: TextStyle(
//                         color: Colors.white70,
//                         fontSize: 12,
//                         fontFamily: 'Inter',
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const Icon(Icons.arrow_forward_ios_rounded,
//                   color: Colors.white70, size: 16),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildGrid(BuildContext context, dynamic profile) {
//     final int schoolCount = profile?.earnings.schools.length ?? 0;
//     final int totalClasses = profile == null
//         ? 0
//         : (profile.earnings.schools as List)
//             .fold<int>(0, (sum, s) => sum + (s.classesCount as int));
//     final double totalEarnings = profile?.earnings.totalEarnings ?? 0.0;
//     final double paid = profile?.earnings.totalPaid ?? 0.0;
//     final double pending = profile?.earnings.totalPending ?? 0.0;
//     final double projected = profile?.earnings.projectedEarnings ?? 0.0;
//     final double paidPct =
//         totalEarnings > 0 ? (paid / totalEarnings) * 100 : 0.0;
//     final double pendingPct =
//         totalEarnings > 0 ? (pending / totalEarnings) * 100 : 0.0;
//     final bool noData = profile == null;

//     return GridView(
//       shrinkWrap: true,
//       padding: EdgeInsets.zero,
//       physics: const NeverScrollableScrollPhysics(),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         childAspectRatio: 1.4,
//         crossAxisSpacing: 10,
//         mainAxisSpacing: 10,
//       ),
//       children: [
//         Card(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
//           color: Colors.white,
//           elevation: 5,
//           child: Padding(
//             padding: const EdgeInsets.only(right: 15, left: 15, top: 10),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 FittedBox(
//                   child: Text(
//                     'Profile Status',
//                     style: AppStyle.heading2.copyWith(
//                       fontWeight: FontWeight.bold,
//                       fontFamily: AppStyle.fontFamilySecondary,
//                       fontSize: 15,
//                     ),
//                   ),
//                 ),
//                 Flexible(
//                   child: CustomPaint(
//                     painter: const ProfileStatusCircularPercentage(percentage: 75),
//                     size: Size(
//                       context.screenWidth * 0.2,
//                       context.screenHeight * 0.1,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         Card(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
//           color: Colors.white,
//           elevation: 5,
//           child: Padding(
//             padding: const EdgeInsets.only(right: 17, left: 17, top: 10, bottom: 10),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 FittedBox(
//                   child: Text(
//                     'Assigned Schools',
//                     style: AppStyle.heading2.copyWith(
//                       fontWeight: FontWeight.bold,
//                       fontFamily: AppStyle.fontFamilySecondary,
//                       fontSize: 15,
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: context.screenHeight * 0.009),
//                 Center(
//                   child: Text(
//                     noData ? '—' : '$schoolCount',
//                     style: AppStyle.bodyText.copyWith(
//                       color: Colors.black,
//                       fontSize: 15,
//                       fontFamily: 'Inter',
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: context.screenHeight * 0.009),
//                 Padding(
//                   padding: const EdgeInsets.only(left: 10),
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: AppStyle.backgroundColor,
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: FittedBox(
//                       child: Padding(
//                         padding: const EdgeInsets.only(
//                             right: 10, left: 10, bottom: 5, top: 5),
//                         child: Row(children: [
//                           Image.asset('assets/kms/school.png',
//                               height: 15, width: 15, color: AppStyle.primaryColor),
//                           const SizedBox(width: 5),
//                           Text(noData ? 'No Classes Yet' : '$totalClasses Classes'),
//                         ]),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         Card(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
//           color: Colors.white,
//           elevation: 5,
//           child: Padding(
//             padding: const EdgeInsets.only(right: 15, left: 15, top: 10),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 FittedBox(
//                   child: Text(
//                     'Task Overview',
//                     style: AppStyle.heading2.copyWith(
//                       fontWeight: FontWeight.bold,
//                       fontFamily: AppStyle.fontFamilySecondary,
//                       fontSize: 15,
//                     ),
//                   ),
//                 ),
//                 if (noData)
//                   Expanded(
//                     child: Center(
//                       child: Text(
//                         'No tasks yet',
//                         style: TextStyle(
//                           fontSize: 11,
//                           color: Colors.grey.shade400,
//                           fontFamily: 'Inter',
//                         ),
//                       ),
//                     ),
//                   )
//                 else
//                   Padding(
//                     padding: const EdgeInsets.only(top: 5, right: 5, left: 5),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(children: const [
//                           Text('3', style: TextStyle(fontFamily: 'Inter')),
//                           SizedBox(width: 10),
//                           Text('Completed'),
//                         ]),
//                         Row(children: const [
//                           Text('3', style: TextStyle(fontFamily: 'Inter')),
//                           SizedBox(width: 10),
//                           Text('Pending'),
//                         ]),
//                         SizedBox(height: context.screenHeight * 0.01),
//                         Center(
//                           child: ClipRRect(
//                             borderRadius: BorderRadiusGeometry.circular(10),
//                             child: SizedBox(
//                               width: 100,
//                               height: 20,
//                               child: Row(children: [
//                                 Expanded(
//                                     flex: 500,
//                                     child: Container(color: AppStyle.primaryColor)),
//                                 Expanded(
//                                     flex: 500,
//                                     child: Container(color: Colors.grey)),
//                               ]),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ),
//         GestureDetector(
//           onTap: _togglePaymentCard,
//           child: AnimatedBuilder(
//             animation: _flipAnimation,
//             builder: (context, _) {
//               final isFront = _flipAnimation.value < 0.5;
//               final angle = _flipAnimation.value * pi;
//               return Transform(
//                 transform: Matrix4.identity()
//                   ..setEntry(3, 2, 0.001)
//                   ..rotateY(angle),
//                 alignment: Alignment.center,
//                 child: isFront
//                     ? _paymentFront(context, paidPct, pendingPct, noData)
//                     : Transform(
//                         transform: Matrix4.identity()..rotateY(pi),
//                         alignment: Alignment.center,
//                         child: _paymentBack(context,
//                             total: totalEarnings,
//                             paid: paid,
//                             pending: pending,
//                             projected: projected,
//                             noData: noData),
//                       ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _paymentFront(
//       BuildContext context, double paidPct, double pendingPct, bool noData) {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
//       color: Colors.white,
//       elevation: 5,
//       child: Padding(
//         padding: const EdgeInsets.only(right: 15, left: 15, top: 10),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 FittedBox(
//                   child: Text(
//                     'Payment',
//                     style: AppStyle.heading2.copyWith(
//                       fontWeight: FontWeight.bold,
//                       fontFamily: AppStyle.fontFamilySecondary,
//                       fontSize: 15,
//                     ),
//                   ),
//                 ),
//                 const Icon(Icons.touch_app, size: 14, color: Colors.grey),
//               ],
//             ),
//             if (noData)
//               Expanded(
//                 child: Center(
//                   child: Text(
//                     'No payment\ndata yet',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 11,
//                       color: Colors.grey.shade400,
//                       fontFamily: 'Inter',
//                     ),
//                   ),
//                 ),
//               )
//             else
//               FittedBox(
//                 child: Row(children: [
//                   CustomPaint(
//                     painter: PaymentPieChart(
//                         paidPercentage: paidPct, pendingPercentage: pendingPct),
//                     size: Size(
//                         context.screenWidth * 0.2, context.screenHeight * 0.1),
//                   ),
//                   const SizedBox(width: 10),
//                   Column(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _distributionChart(const Color(0xffF8BD00), 'Pending'),
//                       _distributionChart(AppStyle.primaryColor, 'Paid'),
//                     ],
//                   ),
//                 ]),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _paymentBack(
//     BuildContext context, {
//     required double total,
//     required double paid,
//     required double pending,
//     required double projected,
//     required bool noData,
//   }) {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
//       color: Colors.white,
//       elevation: 5,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 FittedBox(
//                   child: Text(
//                     'Payment',
//                     style: AppStyle.heading2.copyWith(
//                       fontWeight: FontWeight.bold,
//                       fontFamily: AppStyle.fontFamilySecondary,
//                       fontSize: 15,
//                     ),
//                   ),
//                 ),
//                 const Icon(Icons.touch_app, size: 14, color: Colors.grey),
//               ],
//             ),
//             const SizedBox(height: 4),
//             if (noData)
//               Expanded(
//                 child: Center(
//                   child: Text(
//                     'No payment\ndata yet',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 11,
//                       color: Colors.grey.shade400,
//                       fontFamily: 'Inter',
//                     ),
//                   ),
//                 ),
//               )
//             else ...[
//               _amountRow('Total', total, Colors.black),
//               _amountRow('Paid', paid, AppStyle.primaryColor),
//               _amountRow('Pending', pending, const Color(0xffF8BD00)),
//               _amountRow('Projected', projected, Colors.blueGrey),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _amountRow(String label, double amount, Color color) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 2),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label,
//               style: const TextStyle(
//                   fontSize: 11, fontFamily: 'Inter', color: Colors.black87)),
//           Text(
//             'Rs. ${amount.toStringAsFixed(1)}',
//             style: TextStyle(
//                 fontSize: 11,
//                 fontFamily: 'Inter',
//                 fontWeight: FontWeight.bold,
//                 color: color),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _distributionChart(Color color, String text) {
//     return Row(children: [
//       Container(
//           width: 10,
//           height: 5,
//           decoration: BoxDecoration(shape: BoxShape.rectangle, color: color)),
//       const SizedBox(width: 10),
//       Text(text, style: const TextStyle(color: Colors.black, fontSize: 14)),
//     ]);
//   }
// }

// class _CheckInCard extends StatelessWidget {
//   final String schoolId;
//   final String schoolName;
//   final bool isCheckedIn;
//   final bool isLoading;
//   final VoidCallback onCheckIn;
//   final VoidCallback onCheckOut;

//   const _CheckInCard({
//     required this.schoolId,
//     required this.schoolName,
//     required this.isCheckedIn,
//     required this.isLoading,
//     required this.onCheckIn,
//     required this.onCheckOut,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final now = DateTime.now();
//     final timeStr =
//         '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
//     final dateStr = '${now.day}/${now.month}/${now.year}';

//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.06),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//         border: Border.all(
//           color: isCheckedIn
//               ? AppStyle.primaryColor.withValues(alpha: 0.4)
//               : Colors.grey.shade200,
//           width: 1.5,
//         ),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           children: [
//             Container(
//               width: 46,
//               height: 46,
//               decoration: BoxDecoration(
//                 color: isCheckedIn
//                     ? AppStyle.primaryColor.withValues(alpha: 0.1)
//                     : Colors.grey.shade100,
//                 borderRadius: BorderRadius.circular(14),
//               ),
//               child: Icon(
//                 Icons.school_rounded,
//                 color: isCheckedIn ? AppStyle.primaryColor : Colors.grey.shade400,
//                 size: 24,
//               ),
//             ),
//             const SizedBox(width: 14),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     schoolName,
//                     style: const TextStyle(
//                       fontWeight: FontWeight.w600,
//                       fontSize: 13,
//                       fontFamily: 'Inter',
//                       color: Colors.black87,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 4),
//                   Row(children: [
//                     Container(
//                       width: 7,
//                       height: 7,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color:
//                             isCheckedIn ? Colors.green : Colors.grey.shade400,
//                       ),
//                     ),
//                     const SizedBox(width: 5),
//                     Text(
//                       isCheckedIn
//                           ? 'Checked in · $timeStr'
//                           : '$dateStr · Not checked in',
//                       style: TextStyle(
//                         fontSize: 11,
//                         fontFamily: 'Inter',
//                         color: isCheckedIn
//                             ? Colors.green.shade700
//                             : Colors.grey.shade500,
//                       ),
//                     ),
//                   ]),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 10),
//             isLoading
//                 ? SizedBox(
//                     width: 36,
//                     height: 36,
//                     child: CircularProgressIndicator(
//                         strokeWidth: 2.5, color: AppStyle.primaryColor),
//                   )
//                 : GestureDetector(
//                     onTap: isCheckedIn ? onCheckOut : onCheckIn,
//                     child: AnimatedContainer(
//                       duration: const Duration(milliseconds: 300),
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 14, vertical: 8),
//                       decoration: BoxDecoration(
//                         color: isCheckedIn
//                             ? Colors.red.shade50
//                             : AppStyle.primaryColor,
//                         borderRadius: BorderRadius.circular(12),
//                         border: isCheckedIn
//                             ? Border.all(color: Colors.red.shade200)
//                             : null,
//                       ),
//                       child: Text(
//                         isCheckedIn ? 'Check Out' : 'Check In',
//                         style: TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.w600,
//                           fontFamily: 'Inter',
//                           color: isCheckedIn
//                               ? Colors.red.shade600
//                               : Colors.white,
//                         ),
//                       ),
//                     ),
//                   ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _CheckInSkeleton extends StatelessWidget {
//   const _CheckInSkeleton();

//   @override
//   Widget build(BuildContext context) {
//     return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//       Container(
//           width: 100,
//           height: 14,
//           decoration: BoxDecoration(
//               color: Colors.grey.shade300,
//               borderRadius: BorderRadius.circular(6))),
//       const SizedBox(height: 12),
//       Container(
//           height: 78,
//           decoration: BoxDecoration(
//               color: Colors.grey.shade200,
//               borderRadius: BorderRadius.circular(20))),
//     ]);
//   }
// }

// class _SkeletonGrid extends StatefulWidget {
//   const _SkeletonGrid();

//   @override
//   State<_SkeletonGrid> createState() => _SkeletonGridState();
// }

// class _SkeletonGridState extends State<_SkeletonGrid>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _ctrl;

//   @override
//   void initState() {
//     super.initState();
//     _ctrl = AnimationController(
//         vsync: this, duration: const Duration(milliseconds: 1000))
//       ..repeat(reverse: true);
//   }

//   @override
//   void dispose() {
//     _ctrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _ctrl,
//       builder: (context, _) => GridView(
//         shrinkWrap: true,
//         padding: EdgeInsets.zero,
//         physics: const NeverScrollableScrollPhysics(),
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: 2,
//             childAspectRatio: 1.4,
//             crossAxisSpacing: 10,
//             mainAxisSpacing: 10),
//         children: List.generate(4, (i) => _buildSkeletonCard(i)),
//       ),
//     );
//   }

//   Widget _buildSkeletonCard(int index) {
//     final double phase = (_ctrl.value + index * 0.2) % 1.0;
//     final double opacity = 0.3 + (0.5 * (sin(phase * pi)));
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
//       color: Colors.white,
//       elevation: 5,
//       child: Padding(
//         padding: const EdgeInsets.all(14),
//         child: Opacity(
//           opacity: opacity,
//           child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//             _box(width: 90, height: 11),
//             const SizedBox(height: 14),
//             if (index == 0) ...[
//               Center(child: _circle(52)),
//             ] else if (index == 1) ...[
//               Center(child: _box(width: 28, height: 18)),
//               const SizedBox(height: 8),
//               _box(width: 85, height: 22, radius: 11),
//             ] else if (index == 2) ...[
//               _box(width: double.infinity, height: 10),
//               const SizedBox(height: 7),
//               _box(width: double.infinity, height: 10),
//               const SizedBox(height: 10),
//               Center(child: _box(width: 100, height: 18, radius: 9)),
//             ] else ...[
//               Row(children: [
//                 _circle(48),
//                 const SizedBox(width: 12),
//                 Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                   _box(width: 52, height: 8),
//                   const SizedBox(height: 8),
//                   _box(width: 52, height: 8),
//                 ]),
//               ]),
//             ],
//           ]),
//         ),
//       ),
//     );
//   }

//   Widget _box({required double width, double height = 12, double radius = 6}) =>
//       Container(
//           width: width,
//           height: height,
//           decoration: BoxDecoration(
//               color: Colors.grey.shade300,
//               borderRadius: BorderRadius.circular(radius)));

//   Widget _circle(double size) => Container(
//       width: size,
//       height: size,
//       decoration:
//           BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle));
// }

// Widget leaderboardWidget() {
//   return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//     Row(children: const [
//       Expanded(
//           flex: 1,
//           child: Text('S.N.',
//               style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter'))),
//       Expanded(
//           flex: 3,
//           child: Center(
//               child: Text('Name',
//                   style: TextStyle(
//                       fontWeight: FontWeight.bold, fontFamily: 'Inter')))),
//       Expanded(
//           flex: 1,
//           child: Text('Score',
//               style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter'),
//               textAlign: TextAlign.right)),
//     ]),
//     const Divider(thickness: 1, color: Colors.black),
//     _buildLeaderBoardRow('1.', 'John Doe', '9'),
//     _buildLeaderBoardRow('2.', 'John Doe', '8'),
//     _buildLeaderBoardRow('3.', 'John Doe', '7'),
//     _buildLeaderBoardRow('4.', 'John Doe', '6.5'),
//     _buildLeaderBoardRow('5.', 'John Doe', '6'),
//   ]);
// }

// Widget _buildLeaderBoardRow(String sn, String name, String score) {
//   return Padding(
//     padding: const EdgeInsets.symmetric(vertical: 4),
//     child: Column(children: [
//       Row(children: [
//         Expanded(flex: 1, child: Text(sn)),
//         Expanded(
//             flex: 3,
//             child: Center(
//                 child: Text(name,
//                     style: const TextStyle(fontWeight: FontWeight.normal)))),
//         Expanded(
//             flex: 1,
//             child: Text(score,
//                 textAlign: TextAlign.right,
//                 style: const TextStyle(fontWeight: FontWeight.normal))),
//       ]),
//       const Divider(color: Colors.grey),
//     ]),
//   );
// }

// class ProfileStatusCircularPercentage extends CustomPainter {
//   final double percentage;
//   final Color segmentColor;

//   const ProfileStatusCircularPercentage(
//       {required this.percentage, this.segmentColor = AppStyle.primaryColor});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = Offset(size.width / 1.4, size.height / 2.5);
//     final radius = min(size.width, size.height) * 0.4;
//     final innerRadius = radius * 0.74;
//     final paint = Paint()..style = PaintingStyle.fill;
//     final double clamped = percentage.clamp(0.0, 100.0);
//     final segs = [
//       if (clamped > 0) _PieSegment(clamped, segmentColor),
//       if (100.0 - clamped > 0)
//         _PieSegment(100.0 - clamped, const Color(0xffDDFFE7)),
//     ];
//     final total = segs.fold(0.0, (s, e) => s + e.value);
//     double start = -pi / -4.8;
//     for (final seg in segs) {
//       final sweep = (seg.value / total) * 2 * pi;
//       paint.color = seg.color;
//       canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start,
//           sweep, true, paint);
//       start += sweep;
//     }
//     canvas.drawCircle(
//         center, innerRadius, Paint()..color = const Color(0xffDDFFE7));
//     final tp = TextPainter(textDirection: TextDirection.rtl)
//       ..text = TextSpan(
//           text: '${clamped.toInt()}%',
//           style: const TextStyle(
//               color: Colors.black,
//               fontSize: 15,
//               fontWeight: FontWeight.bold,
//               fontFamily: 'Inter'))
//       ..layout();
//     tp.paint(canvas,
//         Offset(center.dx - tp.width / 2.3, center.dy - tp.height / 2));
//   }

//   @override
//   bool shouldRepaint(ProfileStatusCircularPercentage old) =>
//       old.percentage != percentage;
// }

// class _PieSegment {
//   final double value;
//   final Color color;
//   const _PieSegment(this.value, this.color);
// }

// class PaymentPieChart extends CustomPainter {
//   final double paidPercentage;
//   final double pendingPercentage;

//   const PaymentPieChart(
//       {required this.paidPercentage, required this.pendingPercentage});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = Offset(size.width / 2, size.height / 2);
//     final radius = min(size.width, size.height) * 0.48;
//     final paint = Paint()..style = PaintingStyle.fill;
//     final segs = [
//       _PaySeg(paidPercentage, AppStyle.primaryColor),
//       _PaySeg(pendingPercentage, const Color(0xffF8BD00)),
//     ];
//     final total = segs.fold(0.0, (s, e) => s + e.value);
//     if (total == 0) {
//       paint.color = Colors.grey.shade300;
//       canvas.drawCircle(center, radius, paint);
//       return;
//     }
//     double start = -pi / 2;
//     for (final seg in segs) {
//       if (seg.value <= 0) continue;
//       final sweep = (seg.value / total) * 2.5 * pi;
//       paint.color = seg.color;
//       canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start,
//           sweep, true, paint);
//       final ta = start + sweep / 2.5;
//       final tr = radius * 0.66;
//       final tp = TextPainter(textDirection: TextDirection.ltr)
//         ..text = TextSpan(
//             text: '${seg.value.toInt()}%',
//             style: const TextStyle(
//                 color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold))
//         ..layout();
//       tp.paint(
//           canvas,
//           Offset(center.dx + tr * cos(ta) - tp.width / 2,
//               center.dy + tr * sin(ta) - tp.height / 2));
//       start += sweep;
//     }
//   }

//   @override
//   bool shouldRepaint(PaymentPieChart old) =>
//       old.paidPercentage != paidPercentage ||
//       old.pendingPercentage != pendingPercentage;
// }

// class _PaySeg {
//   final double value;
//   final Color color;
//   const _PaySeg(this.value, this.color);
// }




import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/core/constants/mediaquery.dart';
import 'package:innovator/KMS/screens/constant_screen/custom_scroll.dart';
import 'package:innovator/KMS/provider/teacher_provider.dart';
import 'package:innovator/KMS/screens/partner/kyc_upload_screen.dart';

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

  final Map<String, bool> _checkedInMap = {};
  final Map<String, bool> _loadingMap = {};

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

  Future<void> _handleCheckIn(String schoolId) async {
    setState(() => _loadingMap[schoolId] = true);
    try {
      await ref.read(checkInProvider(schoolId).future);
      setState(() => _checkedInMap[schoolId] = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Checked in successfully!'),
            ]),
            backgroundColor: AppStyle.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check-in failed: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      setState(() => _loadingMap[schoolId] = false);
    }
  }

  Future<void> _handleCheckOut(String schoolId) async {
    setState(() => _loadingMap[schoolId] = true);
    try {
      await ref.read(checkOutProvider(schoolId).future);
      setState(() => _checkedInMap[schoolId] = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.logout, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Checked out successfully!'),
            ]),
            backgroundColor: Colors.blueGrey,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check-out failed: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      setState(() => _loadingMap[schoolId] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(teacherProfileProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(teacherProfileProvider.future),
      child: CustomScrolling(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            profileAsync.when(
              loading: () => const _SkeletonGrid(),
              error: (_, __) => _buildGrid(context, null),
              data: (profile) => _buildGrid(context, profile),
            ),

            const SizedBox(height: 24),

            profileAsync.when(
              loading: () => const _AttendanceSkeleton(),
              error: (_, __) => _buildAttendanceSection(null),
              data: (profile) => _buildAttendanceSection(profile),
            ),

            const SizedBox(height: 20),

            _buildKycBanner(context),

            // const SizedBox(height: 30),
            // Container(
            //   width: double.infinity,
            //   height: 250,
            //   decoration: BoxDecoration(
            //     borderRadius: BorderRadius.circular(14),
            //     border: Border.all(color: Colors.black),
            //   ),
            //   child: Padding(
            //     padding: const EdgeInsets.only(
            //       right: 8,
            //       left: 8,
            //       top: 10,
            //       bottom: 8,
            //     ),
            //     child: Column(
            //       children: [
            //         Center(
            //           child: Text(
            //             'This Week Classes',
            //             style: TextStyle(
            //               fontSize: 20,
            //               fontFamily: AppStyle.fontFamilySecondary,
            //             ),
            //           ),
            //         ),
            //         const SizedBox(height: 15),
            //         Expanded(
            //           child: SingleChildScrollView(
            //             scrollDirection: Axis.horizontal,
            //             child: _thisWeekClassesTable(),
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),

            // const SizedBox(height: 30),
            // Container(
            //   width: double.infinity,
            //   height: 250,
            //   decoration: BoxDecoration(
            //     borderRadius: BorderRadius.circular(14),
            //     border: Border.all(color: Colors.black),
            //   ),
            //   child: SingleChildScrollView(
            //     child: Padding(
            //       padding: const EdgeInsets.only(right: 8, left: 8, top: 10),
            //       child: Column(
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         children: [
            //           const Center(
            //             child: Text(
            //               'Leaderboard',
            //               style: TextStyle(fontSize: 20, fontFamily: 'Inter'),
            //             ),
            //           ),
            //           const SizedBox(height: 8),
            //           const Text('You are ranked #4 this week'),
            //           const SizedBox(height: 16),
            //           leaderboardWidget(),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),

            // const SizedBox(height: 30),
            // Container(
            //   width: double.infinity,
            //   height: 250,
            //   decoration: BoxDecoration(
            //     borderRadius: BorderRadius.circular(14),
            //     border: Border.all(color: Colors.black),
            //   ),
            //   child: Padding(
            //     padding: const EdgeInsets.only(
            //       right: 8,
            //       left: 8,
            //       top: 10,
            //       bottom: 5,
            //     ),
            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         const Text(
            //           'Student Monitoring',
            //           style: TextStyle(fontSize: 20, fontFamily: 'Inter'),
            //         ),
            //         const SizedBox(height: 16),
            //         Row(
            //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //           children: [
            //             Container(
            //               decoration: BoxDecoration(
            //                 borderRadius: BorderRadius.circular(5),
            //                 border: Border.all(color: Colors.black),
            //               ),
            //               child: const Padding(
            //                 padding: EdgeInsets.symmetric(
            //                   horizontal: 8,
            //                   vertical: 0,
            //                 ),
            //                 child: Text('Class 1- Attendance'),
            //               ),
            //             ),
            //             IconButton(
            //               onPressed: () {},
            //               icon: Icon(
            //                 Icons.filter_alt,
            //                 color: AppStyle.primaryColor,
            //                 size: 30,
            //               ),
            //             ),
            //           ],
            //         ),
            //         Expanded(
            //           child: SingleChildScrollView(
            //             scrollDirection: Axis.horizontal,
            //             child: _studentMonitoringTable(),
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            // const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceSection(dynamic profile) {
    List schools = [];
    if (profile != null) {
      try {
        schools = profile.earnings.schools as List;
      } catch (_) {
        schools = [];
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Attendance',
              style: AppStyle.heading2.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: AppStyle.fontFamilySecondary,
                fontSize: 18,
              ),
            ),
            if (schools.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppStyle.backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${schools.length} School${schools.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Inter',
                    color: AppStyle.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (schools.isEmpty)
          _AttendanceCard(
            schoolId: 'default',
            schoolName: 'Your Assigned School',
            isCheckedIn: _checkedInMap['default'] ?? false,
            isLoading: _loadingMap['default'] ?? false,
            onCheckIn: () => _handleCheckIn('default'),
            onCheckOut: () => _handleCheckOut('default'),
          )
        else
          ...schools.map((school) {
            String schoolId = 'default';
            String schoolName = 'School';
            try {
              schoolId = school.schoolId as String;
              schoolName = school.schoolName as String;
            } catch (_) {
              try {
                schoolId = school.id as String;
                schoolName = school.name as String;
              } catch (_) {}
            }
            final isCheckedIn = _checkedInMap[schoolId] ?? false;
            final isLoading = _loadingMap[schoolId] ?? false;
            return _AttendanceCard(
              schoolId: schoolId,
              schoolName: schoolName,
              isCheckedIn: isCheckedIn,
              isLoading: isLoading,
              onCheckIn: () => _handleCheckIn(schoolId),
              onCheckOut: () => _handleCheckOut(schoolId),
            );
          }),
      ],
    );
  }

  Widget _buildKycBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const KycUploadScreen()),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppStyle.primaryColor,
              AppStyle.primaryColor.withValues(alpha: 0.78),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppStyle.primaryColor.withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.verified_user_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KYC Verification',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        fontFamily: 'Inter',
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Upload your identity document to verify',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white70, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, dynamic profile) {
    final int schoolCount = profile?.earnings.schools.length ?? 0;
    final int totalClasses = profile == null
        ? 0
        : (profile.earnings.schools as List)
            .fold<int>(0, (sum, s) => sum + (s.classesCount as int));
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
        Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25)),
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
                    painter: const ProfileStatusCircularPercentage(
                        percentage: 75),
                    size: Size(context.screenWidth * 0.2,
                        context.screenHeight * 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
        Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25)),
          color: Colors.white,
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.only(
                right: 17, left: 17, top: 10, bottom: 10),
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
                            right: 10, left: 10, bottom: 5, top: 5),
                        child: Row(children: [
                          Image.asset('assets/kms/school.png',
                              height: 15,
                              width: 15,
                              color: AppStyle.primaryColor),
                          const SizedBox(width: 5),
                          Text(noData
                              ? 'No Classes Yet'
                              : '$totalClasses Classes'),
                        ]),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25)),
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
                    padding:
                        const EdgeInsets.only(top: 5, right: 5, left: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: const [
                          Text('3',
                              style: TextStyle(fontFamily: 'Inter')),
                          SizedBox(width: 10),
                          Text('Completed'),
                        ]),
                        Row(children: const [
                          Text('3',
                              style: TextStyle(fontFamily: 'Inter')),
                          SizedBox(width: 10),
                          Text('Pending'),
                        ]),
                        SizedBox(height: context.screenHeight * 0.01),
                        Center(
                          child: ClipRRect(
                            borderRadius:
                                BorderRadiusGeometry.circular(10),
                            child: SizedBox(
                              width: 100,
                              height: 20,
                              child: Row(children: [
                                Expanded(
                                    flex: 500,
                                    child: Container(
                                        color: AppStyle.primaryColor)),
                                Expanded(
                                    flex: 500,
                                    child:
                                        Container(color: Colors.grey)),
                              ]),
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
        GestureDetector(
          onTap: _togglePaymentCard,
          child: AnimatedBuilder(
            animation: _flipAnimation,
            builder: (context, _) {
              final angle = _flipAnimation.value * pi;
              final showFront = angle <= pi / 2;
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                alignment: Alignment.center,
                child: showFront
                    ? _paymentFront(context, paidPct, pendingPct, noData)
                    : Transform(
                        transform: Matrix4.identity()..rotateY(pi),
                        alignment: Alignment.center,
                        child: _paymentBack(context,
                            total: totalEarnings,
                            paid: paid,
                            pending: pending,
                            projected: projected,
                            noData: noData),
                      ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _paymentFront(BuildContext context, double paidPct,
      double pendingPct, bool noData) {
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
                        fontFamily: 'Inter'),
                  ),
                ),
              )
            else
              FittedBox(
                child: Row(children: [
                  CustomPaint(
                    painter: PaymentPieChart(
                        paidPercentage: paidPct,
                        pendingPercentage: pendingPct),
                    size: Size(context.screenWidth * 0.2,
                        context.screenHeight * 0.1),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _distributionChart(
                          const Color(0xffF8BD00), 'Pending'),
                      _distributionChart(AppStyle.primaryColor, 'Paid'),
                    ],
                  ),
                ]),
              ),
          ],
        ),
      ),
    );
  }

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
                        fontFamily: 'Inter'),
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
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'Inter',
                  color: Colors.black87)),
          Text('Rs. ${amount.toStringAsFixed(1)}',
              style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }

  Widget _distributionChart(Color color, String text) {
    return Row(children: [
      Container(
          width: 10,
          height: 5,
          decoration:
              BoxDecoration(shape: BoxShape.rectangle, color: color)),
      const SizedBox(width: 10),
      Text(text,
          style: const TextStyle(color: Colors.black, fontSize: 14)),
    ]);
  }
}

class _AttendanceCard extends StatelessWidget {
  final String schoolId;
  final String schoolName;
  final bool isCheckedIn;
  final bool isLoading;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;

  const _AttendanceCard({
    required this.schoolId,
    required this.schoolName,
    required this.isCheckedIn,
    required this.isLoading,
    required this.onCheckIn,
    required this.onCheckOut,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final dateStr =
        '${now.day} ${_monthName(now.month)} ${now.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isCheckedIn
              ? AppStyle.primaryColor.withValues(alpha: 0.35)
              : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isCheckedIn
                        ? AppStyle.primaryColor.withValues(alpha: 0.12)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    color: isCheckedIn
                        ? AppStyle.primaryColor
                        : Colors.grey.shade400,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schoolName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          fontFamily: 'Inter',
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCheckedIn
                                ? Colors.green
                                : Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isCheckedIn
                              ? 'Active · $timeStr'
                              : '$dateStr',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'Inter',
                            color: isCheckedIn
                                ? Colors.green.shade700
                                : Colors.grey.shade500,
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            isLoading
                ? Center(
                    child: SizedBox(
                      height: 44,
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppStyle.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  )
                : Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: isCheckedIn ? null : onCheckIn,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 44,
                          decoration: BoxDecoration(
                            color: isCheckedIn
                                ? AppStyle.primaryColor
                                : AppStyle.primaryColor,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: isCheckedIn
                                ? []
                                : [
                                    BoxShadow(
                                      color: AppStyle.primaryColor
                                          .withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.login_rounded,
                                color: isCheckedIn
                                    ? Colors.white.withValues(alpha: 0.4)
                                    : Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Check In',
                                style: TextStyle(
                                  color: isCheckedIn
                                      ? Colors.white.withValues(alpha: 0.4)
                                      : Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              if (isCheckedIn) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.check_circle,
                                    color:
                                        Colors.white.withValues(alpha: 0.6),
                                    size: 14),
                              ]
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: isCheckedIn ? onCheckOut : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 44,
                          decoration: BoxDecoration(
                            color: isCheckedIn
                                ? Colors.red.shade500
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                            border: isCheckedIn
                                ? null
                                : Border.all(
                                    color: Colors.grey.shade300),
                            boxShadow: isCheckedIn
                                ? [
                                    BoxShadow(
                                      color: Colors.red
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                color: isCheckedIn
                                    ? Colors.white
                                    : Colors.grey.shade400,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Check Out',
                                style: TextStyle(
                                  color: isCheckedIn
                                      ? Colors.white
                                      : Colors.grey.shade400,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

class _AttendanceSkeleton extends StatelessWidget {
  const _AttendanceSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
          width: 110,
          height: 14,
          decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(6))),
      const SizedBox(height: 14),
      Container(
          height: 120,
          decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(22))),
    ]);
  }
}

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
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
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
      builder: (context, _) => GridView(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10),
        children: List.generate(4, (i) => _buildSkeletonCard(i)),
      ),
    );
  }

  Widget _buildSkeletonCard(int index) {
    final double phase = (_ctrl.value + index * 0.2) % 1.0;
    final double opacity = 0.3 + (0.5 * (sin(phase * pi)));
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      color: Colors.white,
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Opacity(
          opacity: opacity,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(width: 90, height: 11),
                const SizedBox(height: 14),
                if (index == 0) ...[
                  Center(child: _circle(52)),
                ] else if (index == 1) ...[
                  Center(child: _box(width: 28, height: 18)),
                  const SizedBox(height: 8),
                  _box(width: 85, height: 22, radius: 11),
                ] else if (index == 2) ...[
                  _box(width: double.infinity, height: 10),
                  const SizedBox(height: 7),
                  _box(width: double.infinity, height: 10),
                  const SizedBox(height: 10),
                  Center(child: _box(width: 100, height: 18, radius: 9)),
                ] else ...[
                  Row(children: [
                    _circle(48),
                    const SizedBox(width: 12),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _box(width: 52, height: 8),
                          const SizedBox(height: 8),
                          _box(width: 52, height: 8),
                        ]),
                  ]),
                ],
              ]),
        ),
      ),
    );
  }

  Widget _box(
          {required double width,
          double height = 12,
          double radius = 6}) =>
      Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(radius)));

  Widget _circle(double size) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          color: Colors.grey.shade300, shape: BoxShape.circle));
}

Widget leaderboardWidget() {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: const [
      Expanded(
          flex: 1,
          child: Text('S.N.',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontFamily: 'Inter'))),
      Expanded(
          flex: 3,
          child: Center(
              child: Text('Name',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontFamily: 'Inter')))),
      Expanded(
          flex: 1,
          child: Text('Score',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontFamily: 'Inter'),
              textAlign: TextAlign.right)),
    ]),
    const Divider(thickness: 1, color: Colors.black),
    _buildLeaderBoardRow('1.', 'John Doe', '9'),
    _buildLeaderBoardRow('2.', 'John Doe', '8'),
    _buildLeaderBoardRow('3.', 'John Doe', '7'),
    _buildLeaderBoardRow('4.', 'John Doe', '6.5'),
    _buildLeaderBoardRow('5.', 'John Doe', '6'),
  ]);
}

Widget _buildLeaderBoardRow(String sn, String name, String score) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(children: [
      Row(children: [
        Expanded(flex: 1, child: Text(sn)),
        Expanded(
            flex: 3,
            child: Center(
                child: Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.normal)))),
        Expanded(
            flex: 1,
            child: Text(score,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontWeight: FontWeight.normal))),
      ]),
      const Divider(color: Colors.grey),
    ]),
  );
}

class ProfileStatusCircularPercentage extends CustomPainter {
  final double percentage;
  final Color segmentColor;

  const ProfileStatusCircularPercentage(
      {required this.percentage,
      this.segmentColor = AppStyle.primaryColor});

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
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          start, sweep, true, paint);
      start += sweep;
    }
    canvas.drawCircle(center, innerRadius,
        Paint()..color = const Color(0xffDDFFE7));
    final tp = TextPainter(textDirection: TextDirection.rtl)
      ..text = TextSpan(
          text: '${clamped.toInt()}%',
          style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter'))
      ..layout();
    tp.paint(canvas,
        Offset(center.dx - tp.width / 2.3, center.dy - tp.height / 2));
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

  const PaymentPieChart(
      {required this.paidPercentage, required this.pendingPercentage});

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
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          start, sweep, true, paint);
      final ta = start + sweep / 2.5;
      final tr = radius * 0.66;
      final tp = TextPainter(textDirection: TextDirection.ltr)
        ..text = TextSpan(
            text: '${seg.value.toInt()}%',
            style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold))
        ..layout();
      tp.paint(
          canvas,
          Offset(center.dx + tr * cos(ta) - tp.width / 2,
              center.dy + tr * sin(ta) - tp.height / 2));
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