import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';

// ─── Models ─────────────────────────────────────────────────────────────────

class TeacherProgressSummary {
  final String id;
  final String name;
  final String schoolName;
  final int classesCount;
  final int presentDays;
  final int totalDays;
  final int lessonsCompleted;
  final double attendanceRate;
  const TeacherProgressSummary({
    required this.id,
    required this.name,
    required this.schoolName,
    required this.classesCount,
    required this.presentDays,
    required this.totalDays,
    required this.lessonsCompleted,
    required this.attendanceRate,
  });
}

class TeacherSessionLog {
  final String date;
  final String className;
  final String subject;
  final String comment;
  final bool attended;
  const TeacherSessionLog({
    required this.date,
    required this.className,
    required this.subject,
    required this.comment,
    required this.attended,
  });
}

// ─── Providers ───────────────────────────────────────────────────────────────

final teacherProgressProvider = FutureProvider.family<List<TeacherProgressSummary>, String>(
  (ref, schoolId) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return [
      const TeacherProgressSummary(id: 't1', name: 'Ramesh Thapa', schoolName: 'Sunrise Academy', classesCount: 3, presentDays: 18, totalDays: 22, lessonsCompleted: 54, attendanceRate: 81.8),
      const TeacherProgressSummary(id: 't2', name: 'Sunita Karki', schoolName: 'Sunrise Academy', classesCount: 2, presentDays: 21, totalDays: 22, lessonsCompleted: 42, attendanceRate: 95.5),
      const TeacherProgressSummary(id: 't3', name: 'Bijay Rai', schoolName: 'Green Valley', classesCount: 4, presentDays: 20, totalDays: 22, lessonsCompleted: 80, attendanceRate: 90.9),
    ];
  },
);

final sessionLogsProvider = FutureProvider.family<List<TeacherSessionLog>, ({String teacherId, int? classNum})>(
  (ref, params) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      TeacherSessionLog(date: '10 Mar 2026', className: 'Class ${params.classNum ?? 7}', subject: 'Mathematics', comment: 'Completed Chapter 5: Algebra basics. Students practiced 10 problems.', attended: true),
       TeacherSessionLog(date: '9 Mar 2026', className: 'Class ${params.classNum ?? 7}', subject: 'Mathematics', comment: 'Revision of Chapter 4: Geometry. Quiz conducted.', attended: true),
       TeacherSessionLog(date: '8 Mar 2026', className: 'Class ${params.classNum ?? 7}', subject: 'Mathematics', comment: '', attended: false),
       TeacherSessionLog(date: '7 Mar 2026', className: 'Class ${params.classNum ?? 7}', subject: 'Mathematics', comment: 'Started Chapter 5. Introduction to variables.', attended: true),
    ];
  },
);

// ─── Screen 1: School + Teacher List ─────────────────────────────────────────

class CoordinatorTeacherProgressScreen extends ConsumerStatefulWidget {
  const CoordinatorTeacherProgressScreen({super.key});

  @override
  ConsumerState<CoordinatorTeacherProgressScreen> createState() => _CoordinatorTeacherProgressScreenState();
}

class _CoordinatorTeacherProgressScreenState extends ConsumerState<CoordinatorTeacherProgressScreen> {
  String _selectedSchoolId = 'all';

  final _schools = const [
    {'id': 'all', 'name': 'All Schools'},
    {'id': 's1', 'name': 'Sunrise Academy'},
    {'id': 's2', 'name': 'Green Valley'},
  ];

  @override
  Widget build(BuildContext context) {
    final progressAsync = ref.watch(teacherProgressProvider(_selectedSchoolId));

    return Scaffold(
      backgroundColor: AppStyle.primaryColor,
      appBar: AppBar(
        backgroundColor: AppStyle.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Teacher Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Inter', fontSize: 18)),
      ),
      body: Column(
        children: [
          // ── School filter ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _schools.map((school) {
                  final isSelected = _selectedSchoolId == school['id'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSchoolId = school['id']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        school['name']!,
                        style: TextStyle(
                          color: isSelected ? AppStyle.primaryColor : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F7FA),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
              ),
              child: progressAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (teachers) => ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: teachers.length,
                  itemBuilder: (context, i) => _TeacherProgressCard(teacher: teachers[i]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherProgressCard extends StatelessWidget {
  final TeacherProgressSummary teacher;
  const _TeacherProgressCard({required this.teacher});

  @override
  Widget build(BuildContext context) {
    final color = teacher.attendanceRate >= 90
        ? Colors.green.shade600
        : teacher.attendanceRate >= 75
            ? Colors.orange.shade600
            : Colors.red.shade500;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TeacherDetailProgressScreen(teacher: teacher)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppStyle.primaryColor.withValues(alpha: 0.12),
                    child: Text(teacher.name[0], style: TextStyle(color: AppStyle.primaryColor, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Inter')),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(teacher.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, fontFamily: 'Inter', color: Colors.black87)),
                        Text(teacher.schoolName, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontFamily: 'Inter')),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${teacher.attendanceRate.toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color, fontFamily: 'Inter')),
                      Text('Attendance', style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontFamily: 'Inter')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: teacher.attendanceRate / 100,
                  minHeight: 7,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _infoChip(Icons.school_rounded, '${teacher.classesCount} Classes', AppStyle.primaryColor),
                  const SizedBox(width: 10),
                  _infoChip(Icons.calendar_today_rounded, '${teacher.presentDays}/${teacher.totalDays} Days', Colors.blue.shade600),
                  const SizedBox(width: 10),
                  _infoChip(Icons.book_rounded, '${teacher.lessonsCompleted} Lessons', Colors.orange.shade600),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
      ]),
    );
  }
}

// ─── Screen 2: Teacher Detail + Session Logs ──────────────────────────────────

class TeacherDetailProgressScreen extends ConsumerStatefulWidget {
  final TeacherProgressSummary teacher;
  const TeacherDetailProgressScreen({super.key, required this.teacher});

  @override
  ConsumerState<TeacherDetailProgressScreen> createState() => _TeacherDetailProgressScreenState();
}

class _TeacherDetailProgressScreenState extends ConsumerState<TeacherDetailProgressScreen> {
  int? _selectedClass;
  final _classes = [5, 6, 7, 8, 9, 10];

  @override
  Widget build(BuildContext context) {
    final key = (teacherId: widget.teacher.id, classNum: _selectedClass);
    final logsAsync = ref.watch(sessionLogsProvider(key));

    return Scaffold(
      backgroundColor: AppStyle.primaryColor,
      appBar: AppBar(
        backgroundColor: AppStyle.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.teacher.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Inter', fontSize: 16)),
      ),
      body: Column(
        children: [
          // Class filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _classChip(null, 'All'),
                  ..._classes.map((c) => _classChip(c, 'Class $c')),
                ],
              ),
            ),
          ),

          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F7FA),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
              ),
              child: logsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (logs) => ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: logs.length,
                  itemBuilder: (context, i) => _SessionLogTile(log: logs[i]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _classChip(int? classNum, String label) {
    final isSelected = _selectedClass == classNum;
    return GestureDetector(
      onTap: () => setState(() => _selectedClass = classNum),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppStyle.primaryColor : Colors.white,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _SessionLogTile extends StatelessWidget {
  final TeacherSessionLog log;
  const _SessionLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: log.attended ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.15),
          width: 1.2,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 4, right: 12),
              decoration: BoxDecoration(
                color: log.attended ? Colors.green : Colors.red.shade400,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(log.className, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Inter', color: Colors.black87)),
                      Text(log.date, style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontFamily: 'Inter')),
                    ],
                  ),
                  if (log.attended && log.comment.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(log.comment, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontFamily: 'Inter')),
                  ],
                  if (!log.attended) ...[
                    const SizedBox(height: 6),
                    Text('Absent', style: TextStyle(fontSize: 12, color: Colors.red.shade400, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}