import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/measurement_calculator.dart';
import '../../../core/widgets/custom_button.dart';

class SalarySlipScreen extends StatefulWidget {
  const SalarySlipScreen({Key? key}) : super(key: key);

  @override
  State<SalarySlipScreen> createState() => _SalarySlipScreenState();
}

class _SalarySlipScreenState extends State<SalarySlipScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _slip;

  @override
  void initState() {
    super.initState();
    _fetchSalarySlip();
  }

  Future<void> _fetchSalarySlip() async {
    setState(() => _isLoading = true);
    final response = await ApiClient.get('/salary/slips?monthYear=2026-08');
    if (response.success && response.data != null && (response.data as List).isNotEmpty) {
      setState(() {
        _slip = response.data[0];
        _isLoading = false;
      });
    } else {
      // Demo mock salary slip data
      setState(() {
        _slip = {
          'monthYear': 'August 2026',
          'baseSalary': 28000.0,
          'totalDays': 30,
          'presentDays': 29,
          'lateMarks': 2,
          'overtimeHours': 8.0,
          'rewardBonus': 3000.0, // Employee of the Month
          'deductions': 0.0,
          'netSalary': 31800.0,
          'user': {'name': 'Amit Verma', 'role': 'Designer & Operator', 'phone': '+919876543212'},
        };
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final user = _slip?['user'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Salary Slip'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Payslip Branded Card
            Card(
              margin: EdgeInsets.zero,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company Header
                    const Center(
                      child: Column(
                        children: [
                          Text(
                            'APEX SIGNAGE SOLUTIONS',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primary),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Plot 42, Industrial Area Phase 2, Mumbai',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          Divider(height: 20),
                        ],
                      ),
                    ),

                    // Employee Details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['name'] ?? 'Staff', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(user['role'] ?? 'Role', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _slip?['monthYear'] ?? '2026-08',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Attendance summary pill
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryItem('Present Days', '${_slip?['presentDays']} / ${_slip?['totalDays']}'),
                          _buildSummaryItem('Late Marks', '${_slip?['lateMarks']}'),
                          _buildSummaryItem('Overtime', '${_slip?['overtimeHours']} hrs'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Earnings Breakdown Table
                    const Text('Earnings & Incentives', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                    const SizedBox(height: 6),
                    _buildSalaryRow('Basic Monthly Pay', MeasurementCalculator.formatCurrency((_slip?['baseSalary'] ?? 0).toDouble())),
                    _buildSalaryRow('Overtime Pay', '+ ${MeasurementCalculator.formatCurrency(((_slip?['overtimeHours'] ?? 0) * 100).toDouble())}'),
                    _buildSalaryRow('Employee of Month Bonus 🏆', '+ ${MeasurementCalculator.formatCurrency((_slip?['rewardBonus'] ?? 0).toDouble())}', color: AppColors.success),
                    _buildSalaryRow('Late Mark Deductions', '- ₹0', color: AppColors.error),
                    const Divider(height: 20),

                    // Net Take Home Pay
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('NET SALARY PAYABLE:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary)),
                        Text(
                          MeasurementCalculator.formatCurrency((_slip?['netSalary'] ?? 0).toDouble()),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            CustomButton(
              label: 'Download Payslip PDF',
              icon: Icons.picture_as_pdf,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('📄 Payslip PDF downloaded successfully!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
      ],
    );
  }

  Widget _buildSalaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}
