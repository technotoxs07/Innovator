import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';

// ─── Models ─────────────────────────────────────────────────────────────────

enum ApprovalStatus { pending, accepted, rejected }

class AttendanceRecord {
  final String id;
  final String teacherName;
  final String schoolName;
  final String checkInTime;
  final String checkOutTime;
  final String date;
  final String totalHours;
  ApprovalStatus status;

  AttendanceRecord({
    required this.id,
    required this.teacherName,
    required this.schoolName,
    required this.checkInTime,
    required this.checkOutTime,
    required this.date,
    required this.totalHours,
    this.status = ApprovalStatus.pending,
  });
}

// ─── Provider ────────────────────────────────────────────────────────────────

final attendanceRecordsProvider = StateNotifierProvider<AttendanceRecordsNotifier, List<AttendanceRecord>>((ref) {
  return AttendanceRecordsNotifier();
});

class AttendanceRecordsNotifier extends StateNotifier<List<AttendanceRecord>> {
  AttendanceRecordsNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    await Future.delayed(const Duration(milliseconds: 600));
    state = [
      AttendanceRecord(id: 'r1', teacherName: 'Ramesh Thapa', schoolName: 'Sunrise Academy', checkInTime: '8:45 AM', checkOutTime: '1:30 PM', date: '10 Mar 2026', totalHours: '4h 45m'),
      AttendanceRecord(id: 'r2', teacherName: 'Sunita Karki', schoolName: 'Green Valley School', checkInTime: '9:00 AM', checkOutTime: '2:00 PM', date: '10 Mar 2026', totalHours: '5h 00m'),
      AttendanceRecord(id: 'r3', teacherName: 'Bijay Rai', schoolName: 'Sunrise Academy', checkInTime: '8:30 AM', checkOutTime: '1:00 PM', date: '9 Mar 2026', totalHours: '4h 30m'),
      AttendanceRecord(id: 'r4', teacherName: 'Anita Gurung', schoolName: 'Green Valley School', checkInTime: '8:50 AM', checkOutTime: '1:45 PM', date: '9 Mar 2026', totalHours: '4h 55m'),
      AttendanceRecord(id: 'r5', teacherName: 'Dipak Magar', schoolName: 'Sunrise Academy', checkInTime: '9:10 AM', checkOutTime: '2:15 PM', date: '8 Mar 2026', totalHours: '5h 05m'),
    ];
  }

  void updateStatus(String id, ApprovalStatus status) {
    state = state.map((r) => r.id == id ? (r..status = status) : r).toList();
  }
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class CoordinatorAttendanceApprovalScreen extends ConsumerStatefulWidget {
  const CoordinatorAttendanceApprovalScreen({super.key});

  @override
  ConsumerState<CoordinatorAttendanceApprovalScreen> createState() => _CoordinatorAttendanceApprovalScreenState();
}

class _CoordinatorAttendanceApprovalScreenState extends ConsumerState<CoordinatorAttendanceApprovalScreen> {
  ApprovalStatus _filter = ApprovalStatus.pending;

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(attendanceRecordsProvider);
    final filtered = records.where((r) => r.status == _filter).toList();

    final pendingCount = records.where((r) => r.status == ApprovalStatus.pending).length;
    final acceptedCount = records.where((r) => r.status == ApprovalStatus.accepted).length;
    final rejectedCount = records.where((r) => r.status == ApprovalStatus.rejected).length;

    return Scaffold(
      backgroundColor: AppStyle.primaryColor,
      appBar: AppBar(
        backgroundColor: AppStyle.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Attendance Approval', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Inter', fontSize: 18)),
      ),
      body: Column(
        children: [
          // ── Summary Row ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Row(
              children: [
                Expanded(child: _SummaryChip(label: 'Pending', count: pendingCount, color: Colors.orange, isSelected: _filter == ApprovalStatus.pending, onTap: () => setState(() => _filter = ApprovalStatus.pending))),
                const SizedBox(width: 10),
                Expanded(child: _SummaryChip(label: 'Accepted', count: acceptedCount, color: Colors.green, isSelected: _filter == ApprovalStatus.accepted, onTap: () => setState(() => _filter = ApprovalStatus.accepted))),
                const SizedBox(width: 10),
                Expanded(child: _SummaryChip(label: 'Rejected', count: rejectedCount, color: Colors.red, isSelected: _filter == ApprovalStatus.rejected, onTap: () => setState(() => _filter = ApprovalStatus.rejected))),
              ],
            ),
          ),

          // ── List ──
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F7FA),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
              ),
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_rounded, size: 56, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('No ${_filter.name} records', style: TextStyle(color: Colors.grey.shade400, fontSize: 15, fontFamily: 'Inter')),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) => _AttendanceApprovalCard(
                        record: filtered[i],
                        onAccept: () => ref.read(attendanceRecordsProvider.notifier).updateStatus(filtered[i].id, ApprovalStatus.accepted),
                        onReject: () => ref.read(attendanceRecordsProvider.notifier).updateStatus(filtered[i].id, ApprovalStatus.rejected),
                        onUndo: () => ref.read(attendanceRecordsProvider.notifier).updateStatus(filtered[i].id, ApprovalStatus.pending),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  const _SummaryChip({required this.label, required this.count, required this.color, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text('$count', style: TextStyle(color: isSelected ? color : Colors.white, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Inter')),
            Text(label, style: TextStyle(color: isSelected ? Colors.black54 : Colors.white70, fontSize: 11, fontFamily: 'Inter')),
          ],
        ),
      ),
    );
  }
}

class _AttendanceApprovalCard extends StatelessWidget {
  final AttendanceRecord record;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onUndo;
  const _AttendanceApprovalCard({required this.record, required this.onAccept, required this.onReject, required this.onUndo});

  @override
  Widget build(BuildContext context) {
    final isPending = record.status == ApprovalStatus.pending;
    final isAccepted = record.status == ApprovalStatus.accepted;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: !isPending ? Border.all(
          color: isAccepted ? Colors.green.shade300 : Colors.red.shade300,
          width: 1.5,
        ) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppStyle.primaryColor.withValues(alpha: 0.12),
                  child: Text(record.teacherName[0], style: TextStyle(color: AppStyle.primaryColor, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Inter')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(record.teacherName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, fontFamily: 'Inter', color: Colors.black87)),
                      Text(record.schoolName, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontFamily: 'Inter')),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(record.date, style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Time Info ──
            Row(
              children: [
                _timeBox(Icons.login_rounded, 'Check In', record.checkInTime, Colors.green),
                const SizedBox(width: 10),
                _timeBox(Icons.logout_rounded, 'Check Out', record.checkOutTime, Colors.red),
                const SizedBox(width: 10),
                _timeBox(Icons.timer_rounded, 'Duration', record.totalHours, Colors.blue),
              ],
            ),

            const SizedBox(height: 14),

            // ── Action Buttons ──
            if (isPending)
              Row(
                children: [
                  Expanded(
                    child: _actionBtn('Reject', Colors.red, Icons.close_rounded, onReject, filled: false),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionBtn('Accept', Colors.green, Icons.check_rounded, onAccept, filled: true),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: isAccepted ? Colors.green.withValues(alpha: 0.08) : Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isAccepted ? Icons.check_circle_rounded : Icons.cancel_rounded, color: isAccepted ? Colors.green : Colors.red, size: 18),
                            const SizedBox(width: 6),
                            Text(isAccepted ? 'Accepted' : 'Rejected', style: TextStyle(color: isAccepted ? Colors.green.shade700 : Colors.red.shade600, fontWeight: FontWeight.w700, fontFamily: 'Inter', fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onUndo,
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.undo_rounded, color: Colors.grey.shade600, size: 18),
                          const SizedBox(width: 4),
                          Text('Undo', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600, fontFamily: 'Inter', fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _timeBox(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontFamily: 'Inter')),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(String label, Color color, IconData icon, VoidCallback onTap, {required bool filled}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: filled ? Colors.white : color, size: 16),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: filled ? Colors.white : color, fontWeight: FontWeight.w700, fontFamily: 'Inter', fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}