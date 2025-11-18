import 'package:flutter/material.dart';
import 'package:innovator/KMS/screens/constant_screen/custom_scroll.dart';

class AdminComplaintScreen extends StatefulWidget {
  const AdminComplaintScreen({super.key});

  @override
  State<AdminComplaintScreen> createState() => _AdminComplaintScreenState();
}

class _AdminComplaintScreenState extends State<AdminComplaintScreen> {
  @override
  Widget build(BuildContext context) {
    return CustomScrolling(child: Column(
      children: [
Text('Complaint Management',style: TextStyle(
  fontFamily: 'Inter',
  fontSize: 14
),)
      ],
    ));
  }
}