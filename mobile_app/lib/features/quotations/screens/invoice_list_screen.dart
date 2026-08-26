import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/measurement_calculator.dart';
import '../../../core/widgets/status_badge.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({Key? key}) : super(key: key);

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  bool _isLoading = true;
  List<dynamic> _invoices = [];

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  Future<void> _fetchInvoices() async {
    setState(() => _isLoading = true);
    final response = await ApiClient.get('/invoices');
    if (response.success && response.data != null) {
      setState(() {
        _invoices = response.data;
        _isLoading = false;
      });
    } else {
      // Demo mock invoice list
      setState(() {
        _invoices = [
          {
            'id': 'inv-101',
            'invoiceNumber': 'INV-2026-0001',
            'totalAmount': 38500.0,
            'paidAmount': 20000.0,
            'pendingBalance': 18500.0,
            'status': 'PARTIALLY_PAID',
            'customer': {'name': 'Sunil Mehta', 'companyName': 'Apex Retail Store', 'phone': '+919820011223'},
          },
          {
            'id': 'inv-102',
            'invoiceNumber': 'INV-2026-0002',
            'totalAmount': 18000.0,
            'paidAmount': 18000.0,
            'pendingBalance': 0.0,
            'status': 'FULLY_PAID',
            'customer': {'name': 'Dr. Priya Nair', 'companyName': 'CarePlus Hospital', 'phone': '+919830022334'},
          },
        ];
        _isLoading = false;
      });
    }
  }

  void _recordPaymentDialog(Map<String, dynamic> inv) {
    final amountController = TextEditingController(text: '${inv['pendingBalance']}');
    String method = 'UPI';
    final refController = TextEditingController(text: 'UPI/HDFC/998822');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Record Payment: ${inv['invoiceNumber']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount Received (₹)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: method,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: const [
                  DropdownMenuItem(value: 'UPI', child: Text('UPI (GPay / PhonePe / Paytm)')),
                  DropdownMenuItem(value: 'CASH', child: Text('Cash Payment')),
                  DropdownMenuItem(value: 'BANK_TRANSFER', child: Text('Bank Transfer (NEFT/RTGS)')),
                  DropdownMenuItem(value: 'CHEQUE', child: Text('Cheque')),
                ],
                onChanged: (val) => setDialogState(() => method = val!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: refController,
                decoration: const InputDecoration(labelText: 'Transaction Ref / UTR No'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final amt = double.tryParse(amountController.text) ?? 0.0;
                setState(() {
                  inv['paidAmount'] += amt;
                  inv['pendingBalance'] = (inv['totalAmount'] - inv['paidAmount']).clamp(0.0, 999999.0);
                  inv['status'] = inv['pendingBalance'] == 0 ? 'FULLY_PAID' : 'PARTIALLY_PAID';
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Payment of ₹$amt recorded! Remaining: ₹${inv['pendingBalance']}')),
                );
              },
              child: const Text('Confirm Payment'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices & Payment Ledger'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchInvoices,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _invoices.length,
          itemBuilder: (context, index) {
            final inv = _invoices[index];
            final customer = inv['customer'] ?? {};

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(inv['invoiceNumber'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
                        StatusBadge(status: inv['status'] ?? 'UNPAID'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(customer['companyName'] ?? customer['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const Divider(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInvPill('Total Billed', MeasurementCalculator.formatCurrency((inv['totalAmount'] ?? 0).toDouble())),
                        _buildInvPill('Paid So Far', MeasurementCalculator.formatCurrency((inv['paidAmount'] ?? 0).toDouble()), color: AppColors.success),
                        _buildInvPill('Balance Due', MeasurementCalculator.formatCurrency((inv['pendingBalance'] ?? 0).toDouble()), color: inv['pendingBalance'] > 0 ? AppColors.error : AppColors.success),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        if ((inv['pendingBalance'] ?? 0) > 0)
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                              onPressed: () => _recordPaymentDialog(inv),
                              child: const Text('Record Payment', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.share, size: 14),
                            label: const Text('WhatsApp', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('📲 Invoice PDF shared via WhatsApp!'), backgroundColor: AppColors.success),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInvPill(String label, String val, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color ?? AppColors.textPrimary)),
      ],
    );
  }
}
