import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';

// ─── Models ─────────────────────────────────────────────────────────────────

class SalarySlip {
  final String id;
  final String month;
  final int year;
  final double baseSalary;
  final double commission;
  final double deductions;
  final double netPay;
  final String status; // 'paid', 'pending'
  final String paidDate;
  const SalarySlip({
    required this.id,
    required this.month,
    required this.year,
    required this.baseSalary,
    required this.commission,
    required this.deductions,
    required this.netPay,
    required this.status,
    required this.paidDate,
  });
}

// ─── Provider (replace with real API) ────────────────────────────────────────

final salarySlipsProvider = FutureProvider<List<SalarySlip>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 700));
  return [
    const SalarySlip(id: '1', month: 'February', year: 2026, baseSalary: 18000, commission: 3200, deductions: 900, netPay: 20300, status: 'paid', paidDate: '28 Feb 2026'),
    const SalarySlip(id: '2', month: 'January', year: 2026, baseSalary: 18000, commission: 2800, deductions: 900, netPay: 19900, status: 'paid', paidDate: '31 Jan 2026'),
    const SalarySlip(id: '3', month: 'December', year: 2025, baseSalary: 18000, commission: 4100, deductions: 900, netPay: 21200, status: 'paid', paidDate: '31 Dec 2025'),
    const SalarySlip(id: '4', month: 'November', year: 2025, baseSalary: 18000, commission: 2500, deductions: 900, netPay: 19600, status: 'paid', paidDate: '30 Nov 2025'),
    const SalarySlip(id: '5', month: 'March', year: 2026, baseSalary: 18000, commission: 1500, deductions: 900, netPay: 18600, status: 'pending', paidDate: '—'),
  ];
});

// ─── Screen ──────────────────────────────────────────────────────────────────

class TeacherSalaryScreen extends ConsumerWidget {
  const TeacherSalaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slipsAsync = ref.watch(salarySlipsProvider);

    return Scaffold(
      backgroundColor: AppStyle.primaryColor,
      appBar: AppBar(
        backgroundColor: AppStyle.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Salary Slips', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Inter', fontSize: 18)),
      ),
      body: slipsAsync.when(
        loading: () => Container(
          decoration: const BoxDecoration(color: Color(0xFFF5F7FA), borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28))),
          child: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
        data: (slips) {
          final totalPaid = slips.where((s) => s.status == 'paid').fold(0.0, (sum, s) => sum + s.netPay);
          final pending = slips.where((s) => s.status == 'pending').fold(0.0, (sum, s) => sum + s.netPay);

          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF5F7FA),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
            ),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Summary Card ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppStyle.primaryColor, AppStyle.primaryColor.withValues(alpha: 0.78)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: AppStyle.primaryColor.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Earnings Overview', style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Inter')),
                      const SizedBox(height: 6),
                      Text('Rs. ${totalPaid.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                      const Text('Total Received', style: TextStyle(color: Colors.white60, fontSize: 12, fontFamily: 'Inter')),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(child: _summaryChip('Pending', 'Rs. ${pending.toStringAsFixed(0)}', const Color(0xffF8BD00))),
                          const SizedBox(width: 12),
                          Expanded(child: _summaryChip('Slips', '${slips.length}', Colors.white)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Payment History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Inter', color: Colors.black87)),
                const SizedBox(height: 14),

                ...slips.map((slip) => _SalarySlipCard(slip: slip)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Inter')),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11, fontFamily: 'Inter')),
        ],
      ),
    );
  }
}

class _SalarySlipCard extends StatelessWidget {
  final SalarySlip slip;
  const _SalarySlipCard({required this.slip});

  @override
  Widget build(BuildContext context) {
    final isPaid = slip.status == 'paid';
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _SalarySlipDetail(slip: slip),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isPaid ? Colors.green.withValues(alpha: 0.1) : const Color(0xffF8BD00).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isPaid ? Icons.receipt_long_rounded : Icons.pending_actions_rounded,
                  color: isPaid ? Colors.green.shade600 : const Color(0xffF8BD00),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${slip.month} ${slip.year}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, fontFamily: 'Inter', color: Colors.black87)),
                    const SizedBox(height: 3),
                    Text(isPaid ? 'Paid on ${slip.paidDate}' : 'Payment Pending', style: TextStyle(fontSize: 12, color: isPaid ? Colors.green.shade600 : Colors.orange.shade700, fontFamily: 'Inter')),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Rs. ${slip.netPay.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Inter', color: Colors.black87)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isPaid ? Colors.green.withValues(alpha: 0.1) : const Color(0xffF8BD00).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isPaid ? 'Paid' : 'Pending',
                      style: TextStyle(fontSize: 11, color: isPaid ? Colors.green.shade700 : Colors.orange.shade800, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SalarySlipDetail extends StatelessWidget {
  final SalarySlip slip;
  const _SalarySlipDetail({required this.slip});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${slip.month} ${slip.year}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Inter')),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: slip.status == 'paid' ? Colors.green.withValues(alpha: 0.1) : const Color(0xffF8BD00).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(slip.status == 'paid' ? 'Paid' : 'Pending',
                    style: TextStyle(color: slip.status == 'paid' ? Colors.green.shade700 : Colors.orange.shade800, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _detailRow('Base Salary', 'Rs. ${slip.baseSalary.toStringAsFixed(0)}', Colors.black87),
          _detailRow('Commission', '+ Rs. ${slip.commission.toStringAsFixed(0)}', Colors.green.shade600),
          _detailRow('Deductions', '- Rs. ${slip.deductions.toStringAsFixed(0)}', Colors.red.shade400),
          const Divider(height: 28),
          _detailRow('Net Pay', 'Rs. ${slip.netPay.toStringAsFixed(0)}', AppStyle.primaryColor, isBold: true),
          if (slip.status == 'paid') ...[
            const SizedBox(height: 8),
            _detailRow('Paid On', slip.paidDate, Colors.grey.shade600),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, Color valueColor, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontFamily: 'Inter')),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: valueColor, fontFamily: 'Inter')),
        ],
      ),
    );
  }
}