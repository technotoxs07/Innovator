import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';

// ─── Models ─────────────────────────────────────────────────────────────────

class TeacherPaymentSummary {
  final String id;
  final String name;
  final String schoolName;
  final double totalEarned;
  final double totalPaid;
  final double totalPending;
  const TeacherPaymentSummary({
    required this.id,
    required this.name,
    required this.schoolName,
    required this.totalEarned,
    required this.totalPaid,
    required this.totalPending,
  });
}

class GeneratedInvoice {
  final String teacherName;
  final String period;
  final double baseSalary;
  final double commission;
  final double deductions;
  final double netPay;
  final String status;
  const GeneratedInvoice({
    required this.teacherName,
    required this.period,
    required this.baseSalary,
    required this.commission,
    required this.deductions,
    required this.netPay,
    required this.status,
  });
}

enum InvoicePeriod { monthly, quarterly, threeMonths, yearly }

// ─── Provider ────────────────────────────────────────────────────────────────

final teacherPaymentsProvider = FutureProvider<List<TeacherPaymentSummary>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 700));
  return [
    const TeacherPaymentSummary(id: 't1', name: 'Ramesh Thapa', schoolName: 'Sunrise Academy', totalEarned: 62000, totalPaid: 40000, totalPending: 22000),
    const TeacherPaymentSummary(id: 't2', name: 'Sunita Karki', schoolName: 'Green Valley', totalEarned: 58000, totalPaid: 58000, totalPending: 0),
    const TeacherPaymentSummary(id: 't3', name: 'Bijay Rai', schoolName: 'Sunrise Academy', totalEarned: 74000, totalPaid: 50000, totalPending: 24000),
    const TeacherPaymentSummary(id: 't4', name: 'Anita Gurung', schoolName: 'Green Valley', totalEarned: 49000, totalPaid: 30000, totalPending: 19000),
  ];
});

// ─── Screen ──────────────────────────────────────────────────────────────────

class CoordinatorPaymentInvoiceScreen extends ConsumerStatefulWidget {
  const CoordinatorPaymentInvoiceScreen({super.key});

  @override
  ConsumerState<CoordinatorPaymentInvoiceScreen> createState() => _CoordinatorPaymentInvoiceScreenState();
}

class _CoordinatorPaymentInvoiceScreenState extends ConsumerState<CoordinatorPaymentInvoiceScreen> {
  TeacherPaymentSummary? _selectedTeacher;
  InvoicePeriod _selectedPeriod = InvoicePeriod.monthly;
  GeneratedInvoice? _generatedInvoice;
  bool _isGenerating = false;

  String _periodLabel(InvoicePeriod p) {
    switch (p) {
      case InvoicePeriod.monthly: return 'Monthly';
      case InvoicePeriod.quarterly: return 'Quarterly (3 mo)';
      case InvoicePeriod.threeMonths: return 'Last 3 Months';
      case InvoicePeriod.yearly: return 'Yearly';
    }
  }

  double _periodMultiplier(InvoicePeriod p) {
    switch (p) {
      case InvoicePeriod.monthly: return 1;
      case InvoicePeriod.quarterly: return 3;
      case InvoicePeriod.threeMonths: return 3;
      case InvoicePeriod.yearly: return 12;
    }
  }

  Future<void> _generateInvoice() async {
    if (_selectedTeacher == null) return;
    setState(() { _isGenerating = true; _generatedInvoice = null; });
    await Future.delayed(const Duration(milliseconds: 900));
    final mult = _periodMultiplier(_selectedPeriod);
    final base = 18000 * mult;
    final commission = (_selectedTeacher!.totalEarned - _selectedTeacher!.totalPaid) * 0.1 * mult;
    final deductions = 900 * mult;
    setState(() {
      _isGenerating = false;
      _generatedInvoice = GeneratedInvoice(
        teacherName: _selectedTeacher!.name,
        period: _periodLabel(_selectedPeriod),
        baseSalary: base,
        commission: commission,
        deductions: deductions,
        netPay: base + commission - deductions,
        status: _selectedTeacher!.totalPending > 0 ? 'Pending' : 'Paid',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final teachersAsync = ref.watch(teacherPaymentsProvider);

    return Scaffold(
      backgroundColor: AppStyle.primaryColor,
      appBar: AppBar(
        backgroundColor: AppStyle.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Payment Invoice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Inter', fontSize: 18)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F7FA),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Teacher Selection ──
            const Text('Select Teacher', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Inter', color: Colors.black87)),
            const SizedBox(height: 12),
            teachersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (teachers) => Column(
                children: teachers.map((t) => _TeacherSelectTile(
                  teacher: t,
                  isSelected: _selectedTeacher?.id == t.id,
                  onTap: () => setState(() { _selectedTeacher = t; _generatedInvoice = null; }),
                )).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // ── Period Selection ──
            const Text('Invoice Period', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Inter', color: Colors.black87)),
            const SizedBox(height: 12),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3.2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              children: InvoicePeriod.values.map((p) {
                final isSelected = _selectedPeriod == p;
                return GestureDetector(
                  onTap: () => setState(() { _selectedPeriod = p; _generatedInvoice = null; }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? AppStyle.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppStyle.primaryColor : Colors.grey.shade200,
                        width: 1.5,
                      ),
                      boxShadow: isSelected ? [BoxShadow(color: AppStyle.primaryColor.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))] : [],
                    ),
                    child: Center(
                      child: Text(
                        _periodLabel(p),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // ── Generate Button ──
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyle.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _selectedTeacher == null || _isGenerating ? null : _generateInvoice,
                icon: _isGenerating
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.receipt_long_rounded, color: Colors.white),
                label: Text(
                  _isGenerating ? 'Generating...' : 'Generate Invoice',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Inter'),
                ),
              ),
            ),

            // ── Generated Invoice ──
            if (_generatedInvoice != null) ...[
              const SizedBox(height: 28),
              _InvoiceCard(invoice: _generatedInvoice!),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _TeacherSelectTile extends StatelessWidget {
  final TeacherPaymentSummary teacher;
  final bool isSelected;
  final VoidCallback onTap;
  const _TeacherSelectTile({required this.teacher, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppStyle.primaryColor : Colors.grey.shade200, width: isSelected ? 2 : 1),
          boxShadow: isSelected ? [BoxShadow(color: AppStyle.primaryColor.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 3))] : [],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppStyle.primaryColor.withValues(alpha: 0.12),
              child: Text(teacher.name[0], style: TextStyle(color: AppStyle.primaryColor, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(teacher.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, fontFamily: 'Inter', color: Colors.black87)),
                  Text(teacher.schoolName, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontFamily: 'Inter')),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Rs. ${teacher.totalPending.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: teacher.totalPending > 0 ? Colors.orange.shade700 : Colors.green.shade600, fontFamily: 'Inter')),
                Text(teacher.totalPending > 0 ? 'Pending' : 'Cleared', style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontFamily: 'Inter')),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 10),
              Icon(Icons.check_circle_rounded, color: AppStyle.primaryColor, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final GeneratedInvoice invoice;
  const _InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: AppStyle.primaryColor.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          // ── Invoice Header ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppStyle.primaryColor, AppStyle.primaryColor.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(22), topRight: Radius.circular(22)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(invoice.teacherName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Inter')),
                      Text('${invoice.period} Invoice', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12, fontFamily: 'Inter')),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: invoice.status == 'Paid' ? Colors.green.withValues(alpha: 0.3) : const Color(0xffF8BD00).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(invoice.status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Inter', fontSize: 12)),
                ),
              ],
            ),
          ),

          // ── Invoice Body ──
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _invoiceRow('Base Salary', 'Rs. ${invoice.baseSalary.toStringAsFixed(0)}', Colors.black87),
                const SizedBox(height: 8),
                _invoiceRow('Commission', '+ Rs. ${invoice.commission.toStringAsFixed(0)}', Colors.green.shade600),
                const SizedBox(height: 8),
                _invoiceRow('Deductions', '- Rs. ${invoice.deductions.toStringAsFixed(0)}', Colors.red.shade400),
                const Divider(height: 28),
                _invoiceRow('Net Payable', 'Rs. ${invoice.netPay.toStringAsFixed(0)}', AppStyle.primaryColor, isBold: true),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: AppStyle.primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {},
                        icon: Icon(Icons.share_rounded, color: AppStyle.primaryColor, size: 18),
                        label: Text('Share', style: TextStyle(color: AppStyle.primaryColor, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyle.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        onPressed: () {},
                        icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                        label: const Text('Download', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _invoiceRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontFamily: 'Inter')),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color, fontFamily: 'Inter')),
      ],
    );
  }
}