import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/constants/app_style.dart';
import 'package:innovator/KMS/screens/constant_screen/custom_scroll.dart';

enum ComplaintStatus { fromStudent, toAdmin }

class SchoolComplaintBoxStudentScreen extends ConsumerStatefulWidget {
  const SchoolComplaintBoxStudentScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SchoolComplaintBoxStudentScreenState();
}

class _SchoolComplaintBoxStudentScreenState
    extends ConsumerState<SchoolComplaintBoxStudentScreen> {
  ComplaintStatus _selected = ComplaintStatus.fromStudent;
  TextEditingController complaintController = TextEditingController();
  String? _selectedStatus = "All Status";
  bool selectedIcon = false;
  @override
  Widget build(BuildContext context) {
    return CustomScrolling(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Complaint Management',
            style: AppStyle.bodyText.copyWith(color: Colors.black),
          ),
          SizedBox(height: 5),
          Text(
            'View, file and track all complaints within your school',
            style: TextStyle(fontSize: 10, color: Colors.black),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              _statusElevatedButton(
                label:
                    'From Student (3)', //Give the actual length of the complaint from the school instead of 3
                thisStatus: ComplaintStatus.fromStudent,
              ),
              SizedBox(width: 40),
              _statusElevatedButton(
                label: 'To Admin',

                thisStatus: ComplaintStatus.toAdmin,
              ),
            ],
          ),

          SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: EdgeInsets.only(right: 4,left: 4),
                decoration: BoxDecoration(
                   border: Border.all(
                  color: Colors.black
                  
                 ),
                  borderRadius: BorderRadius.circular(15),
                 
                ),
                child: DropdownButton(
                       underline: Container(
                 decoration: BoxDecoration(
                  
                  borderRadius: BorderRadius.circular(15),
                 border: Border.all(
                  color: Colors.transparent
                 )
                ),
                       ),
                
                  value: _selectedStatus,
                  items:
                      ["All Status", "Pending", "Solved"]
                          .map(
                            (status) =>
                                DropdownMenuItem(value: status, child: Text(status)),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => _selectedStatus = value),
                ),
              ),
              IconButton(onPressed: (){
             setState(() {
                  selectedIcon = !selectedIcon;
             });
              }, icon: Icon(Icons.history,color: !selectedIcon? AppStyle.primaryColor :Colors.black,))
            ],
          ),

          SizedBox(height: 10),
          if (_selected == ComplaintStatus.fromStudent)
            _complaintFromStudent(
              'assets/kms/tick.png',
              '2025-01-08 14:30', //Time later from the backend
              'Technical Issue with Robotics Module', //title of the complaint later from the backend
              'The robotics simulation software keeps crashing during the programming exercise. I\'ve tried refreshing multiple times but the issue persists.',
              //description of the complaint later from the backend
              'Admin', // message given by position later from the backend
              'Thank you for reporting this issue. Our IT team is looking into the robotics simulation problem.',
              //actual message  given by will come from the backend
            )
          else
            _complaintToAdmin(
              'Describe your Complaint in Details',
              'Please Provide as much detail as possible',
              () {},
            ),
        ],
      ),
    );
  }

  Widget _statusElevatedButton({
    required String label,
    required ComplaintStatus thisStatus,
  }) {
    final bool isSelected = _selected == thisStatus;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 1.5,
          ),
        ),
        backgroundColor: isSelected ? Colors.white : AppStyle.primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        elevation: isSelected ? 10 : 0,
      ),
      onPressed: () => setState(() => _selected = thisStatus),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.black : AppStyle.bodyTextColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _complaintToAdmin(
    String heading,
    String hintText,
    VoidCallback onPressed,
  ) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: AppStyle.backgroundColor,
      child: Padding(
        padding: EdgeInsets.only(top: 20, right: 20, left: 20, bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(heading, style: TextStyle(fontFamily: 'Inter', fontSize: 15)),
            SizedBox(height: 4),
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(20),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: TextFormField(
                controller: complaintController,
                cursorColor: AppStyle.primaryColor,
                maxLines: 15,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.white, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.white, width: 2),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.white, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.white, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.white, width: 2),
                  ),
                  focusColor: Colors.white,

                  hintText: hintText,
                  fillColor: Colors.white,
                  filled: true,

                  hintStyle: TextStyle(
                    // fontFamily: 'Inter',
                    color: Color(0xff6A6A6A),
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  backgroundColor: AppStyle.buttonColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: onPressed,
                child: Text(
                  'Submit',
                  style: TextStyle(
                    color: AppStyle.bodyTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _complaintFromStudent(
    String image,
    String time,
    String title,
    String description,
    String messageBy,
    String message,
  ) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: AppStyle.backgroundColor,
      child: Padding(
        padding: EdgeInsets.only(top: 20, right: 20, left: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(20),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  top: 20,
                  right: 20,
                  left: 20,
                  bottom: 50,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Image.asset(image),
                        Text(
                          time,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      title,
                      style: AppStyle.bodyText.copyWith(
                        color: Colors.black,
                        fontFamily: 'InterThin',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      description,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 13),
                    Text(
                      'Conversation:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Card(
                      shape: RoundedSuperellipseBorder(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(30),
                          topLeft: Radius.elliptical(75, 20),
                          bottomRight: Radius.circular(35),
                          bottomLeft: Radius.circular(20),
                        ),
                      ),
                      margin: EdgeInsets.all(0),
                      color: AppStyle.primaryColor,
                      child: Card(
                        margin: EdgeInsets.only(top: 0, bottom: 10, left: 15),
                        color: Color(0xffDDFFE7),
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: 10,
                            bottom: 10,
                            left: 10,
                            right: 10,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  time,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 8,
                                  ),
                                ),
                              ),
                              Text(
                                messageBy,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: AppStyle.fontFamilySecondary,
                                ),
                              ),
                              Text(message, style: TextStyle(fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 200),
          ],
        ),
      ),
    );
  }
}
