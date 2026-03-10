import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/screens/constant_screen/custom_scroll.dart';
import 'package:innovator/KMS/screens/coordinator/coordinator_attendance_approval_screen.dart';
import 'package:innovator/KMS/screens/coordinator/coordinator_payment_invoice_screen.dart';
import 'package:innovator/KMS/screens/coordinator/coordinator_teacher_progrees_screen.dart';

// ─── Models ─────────────────────────────────────────────────────────────────

class CoordinatorStats {
  final int totalTeachers;
  final int totalSchools;
  final int pendingApprovals;
  final int pendingPayments;
  final double totalPendingAmount;
  const CoordinatorStats({
    required this.totalTeachers,
    required this.totalSchools,
    required this.pendingApprovals,
    required this.pendingPayments,
    required this.totalPendingAmount,
  });
}

class PendingApprovalItem {
  final String id;
  final String teacherName;
  final String schoolName;
  final String checkInTime;
  final String checkOutTime;
  final String date;
  const PendingApprovalItem({
    required this.id,
    required this.teacherName,
    required this.schoolName,
    required this.checkInTime,
    required this.checkOutTime,
    required this.date,
  });
}

// ─── Providers ───────────────────────────────────────────────────────────────

final coordinatorStatsProvider = FutureProvider<CoordinatorStats>((ref) async {
  await Future.delayed(const Duration(milliseconds: 700));
  return const CoordinatorStats(
    totalTeachers: 14,
    totalSchools: 5,
    pendingApprovals: 3,
    pendingPayments: 6,
    totalPendingAmount: 124500,
  );
});

final recentApprovalsProvider = FutureProvider<List<PendingApprovalItem>>((
  ref,
) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return [
    const PendingApprovalItem(
      id: 'a1',
      teacherName: 'Ramesh Thapa',
      schoolName: 'Sunrise Academy',
      checkInTime: '8:45 AM',
      checkOutTime: '1:30 PM',
      date: 'Today',
    ),
    const PendingApprovalItem(
      id: 'a2',
      teacherName: 'Sunita Karki',
      schoolName: 'Green Valley School',
      checkInTime: '9:00 AM',
      checkOutTime: '2:00 PM',
      date: 'Today',
    ),
    const PendingApprovalItem(
      id: 'a3',
      teacherName: 'Bijay Rai',
      schoolName: 'Sunrise Academy',
      checkInTime: '8:30 AM',
      checkOutTime: '1:00 PM',
      date: 'Yesterday',
    ),
  ];
});

// ─── Screen ──────────────────────────────────────────────────────────────────

class CoordinatorDashboardScreen extends ConsumerWidget {
  const CoordinatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(coordinatorStatsProvider);
    final approvalsAsync = ref.watch(recentApprovalsProvider);

    return Scaffold(
      backgroundColor: AppStyle.primaryColor,

      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F7FA),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: CustomScrolling(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ── Stats Grid ──
              statsAsync.when(
                loading: () => _StatsGridSkeleton(),
                error: (_, __) => const SizedBox(),
                data: (stats) => _StatsGrid(stats: stats),
              ),

              const SizedBox(height: 24),

              // ── Quick Actions ──
              const Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Inter',
                    color: Colors.black87,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.how_to_reg_rounded,
                      label: 'Attendance\nApproval',
                      color: const Color(0xFF7C3AED),
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      const CoordinatorAttendanceApprovalScreen(),
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.receipt_rounded,
                      label: 'Payment\nInvoice',
                      color: const Color(0xFF059669),
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      const CoordinatorPaymentInvoiceScreen(),
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.bar_chart_rounded,
                      label: 'Teacher\nProgress',
                      color: const Color(0xFFE85D04),
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      const CoordinatorTeacherProgressScreen(),
                            ),
                          ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Pending Approvals ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pending Approvals',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Inter',
                      color: Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) =>
                                    const CoordinatorAttendanceApprovalScreen(),
                          ),
                        ),
                    child: Text(
                      'See All',
                      style: TextStyle(
                        color: AppStyle.primaryColor,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              approvalsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox(),
                data:
                    (items) =>
                        items.isEmpty
                            ? _EmptyState(
                              icon: Icons.check_circle_rounded,
                              message: 'All approvals up to date!',
                            )
                            : Column(
                              children:
                                  items
                                      .map(
                                        (item) =>
                                            _PendingApprovalTile(item: item),
                                      )
                                      .toList(),
                            ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stats Grid ───────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final CoordinatorStats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      children: [
        _StatCard(
          label: 'Total Teachers',
          value: '${stats.totalTeachers}',
          icon: Icons.person_rounded,
          color: AppStyle.primaryColor,
        ),
        _StatCard(
          label: 'Total Schools',
          value: '${stats.totalSchools}',
          icon: Icons.school_rounded,
          color: const Color(0xFF7C3AED),
        ),
        _StatCard(
          label: 'Pending Approvals',
          value: '${stats.pendingApprovals}',
          icon: Icons.pending_actions_rounded,
          color: const Color(0xFFE85D04),
          hasBadge: stats.pendingApprovals > 0,
        ),
        _StatCard(
          label: 'Pending Payments',
          value: 'Rs. ${(stats.totalPendingAmount / 1000).toStringAsFixed(1)}k',
          icon: Icons.account_balance_wallet_rounded,
          color: const Color(0xFF059669),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool hasBadge;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.hasBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                if (hasBadge)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    fontFamily: 'Inter',
                    color: Colors.black87,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGridSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      children: List.generate(
        4,
        (_) => Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

// ─── Quick Action Card ────────────────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pending Approval Tile ────────────────────────────────────────────────────

class _PendingApprovalTile extends StatefulWidget {
  final PendingApprovalItem item;
  const _PendingApprovalTile({required this.item});
  @override
  State<_PendingApprovalTile> createState() => _PendingApprovalTileState();
}

class _PendingApprovalTileState extends State<_PendingApprovalTile> {
  bool? _decision; // null=pending, true=accepted, false=rejected

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border:
            _decision == null
                ? null
                : Border.all(
                  color:
                      _decision! ? Colors.green.shade300 : Colors.red.shade300,
                  width: 1.5,
                ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppStyle.primaryColor.withValues(
                    alpha: 0.12,
                  ),
                  child: Text(
                    widget.item.teacherName[0],
                    style: TextStyle(
                      color: AppStyle.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.teacherName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          fontFamily: 'Inter',
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        widget.item.schoolName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.item.date,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.blue,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _timeChip(
                  Icons.login_rounded,
                  'In: ${widget.item.checkInTime}',
                  Colors.green,
                ),
                const SizedBox(width: 10),
                _timeChip(
                  Icons.logout_rounded,
                  'Out: ${widget.item.checkOutTime}',
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_decision == null)
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _decision = false),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Center(
                          child: Text(
                            'Reject',
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _decision = true),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Center(
                          child: Text(
                            'Accept',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color:
                      _decision!
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _decision!
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: _decision! ? Colors.green : Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _decision! ? 'Accepted' : 'Rejected',
                        style: TextStyle(
                          color:
                              _decision!
                                  ? Colors.green.shade700
                                  : Colors.red.shade600,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _timeChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}
