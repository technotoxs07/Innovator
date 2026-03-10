import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/core/constants/mediaquery.dart';
import 'package:innovator/KMS/screens/constant_screen/custom_scroll.dart';

// ─── Models ─────────────────────────────────────────────────────────────────

class AssignedSchool {
  final String id;
  final String name;
  final String address;
  final List<int> classes; // [5, 6, 7, 8, 9, 10]
  const AssignedSchool({required this.id, required this.name, required this.address, required this.classes});
}

class StudentModel {
  final String id;
  final String name;
  final String rollNo;
  bool isPresent;
  StudentModel({required this.id, required this.name, required this.rollNo, this.isPresent = false});
}

// ─── Providers (replace with real API providers) ─────────────────────────────

final assignedSchoolsProvider = FutureProvider<List<AssignedSchool>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 800));
  return [
    const AssignedSchool(id: 's1', name: 'Sunrise Academy', address: 'Kathmandu, Bagmati', classes: [5, 6, 7, 8]),
    const AssignedSchool(id: 's2', name: 'Green Valley School', address: 'Lalitpur, Bagmati', classes: [7, 8, 9, 10]),
  ];
});

final studentsProvider = FutureProvider.family<List<StudentModel>, ({String schoolId, int classNum})>(
  (ref, params) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.generate(
      12,
      (i) => StudentModel(id: 'std_${params.schoolId}_${params.classNum}_$i', name: _demoNames[i % _demoNames.length], rollNo: '${(i + 1).toString().padLeft(2, '0')}'),
    );
  },
);

const _demoNames = ['Aarav Sharma', 'Sita Thapa', 'Ram Karki', 'Priya Basnet', 'Bikash Rai', 'Anita Gurung', 'Suresh Tamang', 'Rekha Shrestha', 'Dipak Magar', 'Sunita Lama', 'Rohit Ale', 'Maya Darlami'];

// ─── Screen 1: School List ───────────────────────────────────────────────────

class TeacherSchoolAttendanceScreen extends ConsumerWidget {
  const TeacherSchoolAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolsAsync = ref.watch(assignedSchoolsProvider);

    return Scaffold(
      backgroundColor: AppStyle.primaryColor,
      appBar: AppBar(
        backgroundColor: AppStyle.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Inter', fontSize: 18)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Select School',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontFamily: 'Inter'),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F7FA),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
              ),
              child: schoolsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (schools) => ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: schools.length,
                  itemBuilder: (context, i) => _SchoolCard(school: schools[i]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SchoolCard extends StatelessWidget {
  final AssignedSchool school;
  const _SchoolCard({required this.school});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ClassSelectionScreen(school: school)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppStyle.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.school_rounded, color: AppStyle.primaryColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(school.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, fontFamily: 'Inter', color: Colors.black87)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.location_on_rounded, size: 13, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(school.address, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontFamily: 'Inter')),
                    ]),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: school.classes.map((c) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppStyle.backgroundColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Class $c', style: TextStyle(fontSize: 11, color: AppStyle.primaryColor, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                      )).toList(),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Screen 2: Class Selection ───────────────────────────────────────────────

class ClassSelectionScreen extends StatelessWidget {
  final AssignedSchool school;
  const ClassSelectionScreen({super.key, required this.school});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateStr = '${today.day} ${_monthName(today.month)} ${today.year}';

    return Scaffold(
      backgroundColor: AppStyle.primaryColor,
      appBar: AppBar(
        backgroundColor: AppStyle.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(school.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Inter', fontSize: 16)),
            Text(dateStr, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontFamily: 'Inter')),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text('Select Class', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontFamily: 'Inter')),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F7FA),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
              ),
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: school.classes.length,
                itemBuilder: (context, i) {
                  final classNum = school.classes[i];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AttendanceMarkingScreen(school: school, classNum: classNum)),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppStyle.primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text('$classNum', style: TextStyle(color: AppStyle.primaryColor, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Class $classNum', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, fontFamily: 'Inter', color: Colors.black87)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int m) => ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m-1];
}

// ─── Screen 3: Attendance Marking ────────────────────────────────────────────

class AttendanceMarkingScreen extends ConsumerStatefulWidget {
  final AssignedSchool school;
  final int classNum;
  const AttendanceMarkingScreen({super.key, required this.school, required this.classNum});

  @override
  ConsumerState<AttendanceMarkingScreen> createState() => _AttendanceMarkingScreenState();
}

class _AttendanceMarkingScreenState extends ConsumerState<AttendanceMarkingScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitAttendance(List<StudentModel> students) async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add a comment about what you taught today.'),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() { _isSubmitting = false; _submitted = true; });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Attendance submitted successfully!'),
          ]),
          backgroundColor: AppStyle.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = (schoolId: widget.school.id, classNum: widget.classNum);
    final studentsAsync = ref.watch(studentsProvider(key));

    return Scaffold(
      backgroundColor: AppStyle.primaryColor,
      appBar: AppBar(
        backgroundColor: AppStyle.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Class ${widget.classNum} Attendance', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Inter', fontSize: 16)),
            Text(widget.school.name, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontFamily: 'Inter')),
          ],
        ),
      ),
      body: studentsAsync.when(
        loading: () => Container(
          decoration: const BoxDecoration(color: Color(0xFFF5F7FA), borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28))),
          child: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
        data: (students) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF5F7FA),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // ── Stats bar ──
              Container(
                margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem('Total', '${students.length}', Colors.black87),
                    _statItem('Present', '${students.where((s) => s.isPresent).length}', Colors.green.shade600),
                    _statItem('Absent', '${students.where((s) => !s.isPresent).length}', Colors.red.shade400),
                  ],
                ),
              ),

              // ── Student list ──
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  itemCount: students.length,
                  itemBuilder: (context, i) {
                    final student = students[i];
                    return _StudentAttendanceTile(
                      student: student,
                      onToggle: (val) => setState(() => student.isPresent = val),
                    );
                  },
                ),
              ),

              // ── Comment box ──
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('What did you teach today?',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, fontFamily: 'Inter', color: Colors.black87)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _commentController,
                      maxLines: 3,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'e.g., Chapter 3: Photosynthesis, Practice problems 1–10...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400, fontFamily: 'Inter'),
                        filled: true,
                        fillColor: const Color(0xFFF5F7FA),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyle.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: _isSubmitting || _submitted ? null : () => _submitAttendance(students),
                        child: _isSubmitting
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                _submitted ? 'Submitted ✓' : 'Submit Attendance',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Inter'),
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
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color, fontFamily: 'Inter')),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontFamily: 'Inter')),
    ]);
  }
}

class _StudentAttendanceTile extends StatelessWidget {
  final StudentModel student;
  final ValueChanged<bool> onToggle;
  const _StudentAttendanceTile({required this.student, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: student.isPresent ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: student.isPresent
                  ? Colors.green.withValues(alpha: 0.12)
                  : Colors.grey.shade100,
              child: Text(
                student.name[0],
                style: TextStyle(color: student.isPresent ? Colors.green.shade700 : Colors.grey.shade500, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Inter', color: Colors.black87)),
                  Text('Roll No: ${student.rollNo}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontFamily: 'Inter')),
                ],
              ),
            ),
            Row(
              children: [
                _AttendanceChip(label: 'P', isSelected: student.isPresent, color: Colors.green, onTap: () => onToggle(true)),
                const SizedBox(width: 8),
                _AttendanceChip(label: 'A', isSelected: !student.isPresent, color: Colors.red, onTap: () => onToggle(false)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  const _AttendanceChip({required this.label, required this.isSelected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color : Colors.grey.shade400,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }
}