import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/constants/app_style.dart';
import 'package:innovator/KMS/screens/constant_screen/custom_scroll.dart';

class PartenerAttendanceScreen extends ConsumerWidget {
  const PartenerAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrolling(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attendance',
                style: AppStyle.bodyText.copyWith(color: Colors.black),
              ),
              Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Icon(
                        Icons.calendar_today_outlined,
                        color: AppStyle.primaryColor, 
                        size: 24,
                      ),
                    ),
                    WidgetSpan(child: SizedBox(width: 10)),
                    TextSpan(
                      text: '11/11/2025',
                      style: TextStyle(
                        color: Color(0xff999999),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
                    SizedBox(height: 20),
          Container(
            clipBehavior: Clip.antiAlias,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              color: Colors.white,
            ),
            child: _teacherAttendance(),
          ),
        ],
      ),
    );
  }
  
  Widget _teacherAttendance() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 25,
        headingRowHeight: 70,
        dataRowMaxHeight: 50,
        showBottomBorder: true,
        border: TableBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        headingRowColor: WidgetStatePropertyAll(Color(0xffDDFFE7)),
        columns: [
          DataColumn(
            label: Text(
              'Complaint By',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
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
              'Contact',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Teacher',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Message',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 12,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Date',
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
        rows:
          [
            
          ]
      ),
    );
  }

  DataRow _teacherAttendanceRow(
    String complaintBy,
    String schoolName,
    String contact,
    String teacher,
    String message,
    String date,
    String status,
  ) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            complaintBy,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
          ),
        ),
        DataCell(
          Text(
            schoolName,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
          ),
        ),
        DataCell(
          Text(
            contact,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
          ),
        ),
        DataCell(
          Text(
            teacher,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
          ),
        ),
        DataCell(
          Text(
            message,

            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
          ),
        ),
        DataCell(
          Text(
            date,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
          ),
        ),
        DataCell(
          Text(
            status,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color:
                  status == 'Pending'
                      ? Color(0xffFB923C)
                      : AppStyle.primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
