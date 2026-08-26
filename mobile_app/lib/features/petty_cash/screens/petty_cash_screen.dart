import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/measurement_calculator.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/status_badge.dart';

class PettyCashScreen extends StatefulWidget {
  const PettyCashScreen({Key? key}) : super(key: key);

  @override
  State<PettyCashScreen> createState() => _PettyCashScreenState();
}

class _PettyCashScreenState extends State<PettyCashScreen> {
  bool _isLoading = true;
  List<dynamic> _expenses = [];

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    setState(() => _isLoading = true);
    final res = await ApiClient.get('/petty-cash');
    if (res.success && res.data != null) {
      setState(() {
        _expenses = res.data;
        _isLoading = false;
      });
    } else {
      // Demo mock expenses
      setState(() {
        _expenses = [
          {
            'id': 'exp-1',
            'category': 'SCREWS',
            'amount': 350.0,
            'description': '3-inch anchor bolts & stainless steel screws',
            'status': 'APPROVED',
            'employee': {'name': 'Vikram Singh', 'role': 'Installation Lead'},
          },
          {
            'id': 'exp-2',
            'category': 'TEMPO_RENTAL',
            'amount': 1200.0,
            'description': 'Mini tempo transport from workshop to Grand Galleria Mall',
            'status': 'PENDING',
            'employee': {'name': 'Vikram Singh', 'role': 'Installation Lead'},
          },
          {
            'id': 'exp-3',
            'category': 'TEA_WATER',
            'amount': 120.0,
            'description': 'Tea & refreshments for 3-member site team',
            'status': 'APPROVED',
            'employee': {'name': 'Rahul Sharma', 'role': 'Field Boy'},
          },
        ];
        _isLoading = false;
      });
    }
  }

  void _showAddExpenseDialog() {
    String category = 'SCREWS';
    final amountController = TextEditingController(text: '450');
    final descController = TextEditingController(text: 'Hardware anchors & Fevicol SH bottle');
    bool hasReceipt = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Daily Site Expense', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Expense Category'),
                  items: const [
                    DropdownMenuItem(value: 'SCREWS', child: Text('Screws / Fasteners / Anchors')),
                    DropdownMenuItem(value: 'ADHESIVE_FEVICOL', child: Text('Adhesive / Fevicol / Silicone')),
                    DropdownMenuItem(value: 'TEMPO_RENTAL', child: Text('Tempo / Rental Transport')),
                    DropdownMenuItem(value: 'TEA_WATER', child: Text('Tea / Water Refreshments')),
                    DropdownMenuItem(value: 'SITE_MISC', child: Text('Other Site Expenses')),
                  ],
                  onChanged: (val) => setDialogState(() => category = val!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount (₹)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description / Item Details'),
                ),
                const SizedBox(height: 14),

                // Attach Bill / Receipt Button
                OutlinedButton.icon(
                  icon: Icon(hasReceipt ? Icons.check_circle : Icons.camera_alt, color: hasReceipt ? AppColors.success : AppColors.primary),
                  label: Text(hasReceipt ? 'Receipt Attached' : 'Attach Bill Photo'),
                  onPressed: () {
                    setDialogState(() => hasReceipt = true);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final amt = double.tryParse(amountController.text) ?? 0.0;
                setState(() {
                  _expenses.insert(0, {
                    'id': 'exp-${DateTime.now().millisecondsSinceEpoch}',
                    'category': category,
                    'amount': amt,
                    'description': descController.text,
                    'status': 'PENDING',
                    'employee': {'name': 'You (Current User)', 'role': 'Field Staff'},
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Expense of ₹$amt submitted for Admin approval!'), backgroundColor: AppColors.success),
                );
              },
              child: const Text('Submit Expense'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final totalSpent = _expenses.where((e) => e['status'] == 'APPROVED').fold(0.0, (sum, e) => sum + (e['amount'] as num));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Petty Cash Site Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Expense',
            onPressed: _showAddExpenseDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.receipt, color: Colors.white),
        label: const Text('Record Expense', style: TextStyle(color: Colors.white)),
        onPressed: _showAddExpenseDialog,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchExpenses,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Approved Total Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Approved Petty Expenses', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        SizedBox(height: 4),
                        Text('Verified On-Site Receipts', style: TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                    Text(
                      MeasurementCalculator.formatCurrency(totalSpent),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              const Text(
                'Expense Transaction Log',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _expenses.length,
                itemBuilder: (context, index) {
                  final exp = _expenses[index];
                  final employee = exp['employee'] ?? {};
                  final isPending = exp['status'] == 'PENDING';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                exp['category']?.toString().replaceAll('_', ' ') ?? 'EXPENSE',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                              ),
                              StatusBadge(status: exp['status'] ?? 'PENDING'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(exp['description'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Text(
                            'Submitted by: ${employee['name']} (${employee['role']})',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const Divider(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                MeasurementCalculator.formatCurrency((exp['amount'] ?? 0).toDouble()),
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary),
                              ),
                              if (isPending)
                                Row(
                                  children: [
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.error,
                                        side: const BorderSide(color: AppColors.error),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: const Size(0, 30),
                                      ),
                                      onPressed: () => setState(() => exp['status'] = 'REJECTED'),
                                      child: const Text('Reject', style: TextStyle(fontSize: 11)),
                                    ),
                                    const SizedBox(width: 6),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: const Size(0, 30),
                                      ),
                                      onPressed: () => setState(() => exp['status'] = 'APPROVED'),
                                      child: const Text('Approve', style: TextStyle(fontSize: 11)),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
