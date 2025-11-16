import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/screens/constant_screen/custom_scroll.dart';

class StudentComplainBoxScreen extends ConsumerStatefulWidget {
  const StudentComplainBoxScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _StudentComplainBoxScreenState();
}

class _StudentComplainBoxScreenState extends ConsumerState<StudentComplainBoxScreen> {
  @override
  Widget build(BuildContext context) {
    return CustomScrolling(
      child: Column(
        children: [
          Text('Submit a complaint'),
        ],
      )
      );
  }
}
