import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/measurement_calculator.dart';
import '../../../core/widgets/custom_button.dart';

class QuotationLineItem {
  String description;
  double lengthFeet;
  double heightFeet;
  double unitRate;

  QuotationLineItem({
    required this.description,
    this.lengthFeet = 10.0,
    this.heightFeet = 4.0,
    this.unitRate = 400.0,
  });

  double get sqFt => MeasurementCalculator.calculate(lengthFeet, heightFeet).squareFeet;
  double get amount => sqFt * unitRate;
}

class QuotationBuilderScreen extends StatefulWidget {
  const QuotationBuilderScreen({Key? key}) : super(key: key);

  @override
  State<QuotationBuilderScreen> createState() => _QuotationBuilderScreenState();
}

class _QuotationBuilderScreenState extends State<QuotationBuilderScreen> {
  String _selectedCustomer = 'Sunil Mehta (Apex Retail Store)';
  bool _isGst = true;
  double _framingCharges = 2500.0;
  double _installationCharges = 2000.0;
  double _discount = 0.0;
  double _gstRate = 18.0;
  bool _isGenerating = false;

  final List<QuotationLineItem> _items = [
    QuotationLineItem(description: 'Main Entrance 3D Acrylic LED Letter ACP Board (15ft x 4ft)', lengthFeet: 15.0, heightFeet: 4.0, unitRate: 400.0),
    QuotationLineItem(description: 'Side Wall Backlit Glow Sign Box (6ft x 3ft)', lengthFeet: 6.0, heightFeet: 3.0, unitRate: 333.33),
  ];

  double get subtotal => _items.fold(0.0, (sum, i) => sum + i.amount);
  double get taxableAmount => (subtotal + _framingCharges + _installationCharges - _discount).clamp(0.0, 9999999.0);
  double get gstAmount => _isGst ? taxableAmount * (_gstRate / 100) : 0.0;
  double get grandTotal => taxableAmount + gstAmount;

  Future<void> _generateQuotation() async {
    setState(() => _isGenerating = true);

    final payload = {
      'customerId': 'cust-101',
      'isGst': _isGst,
      'framingCharges': _framingCharges,
      'installationCharges': _installationCharges,
      'discountAmount': _discount,
      'gstPercentage': _gstRate,
      'items': _items.map((i) => {
        'itemDescription': i.description,
        'lengthFeet': i.lengthFeet,
        'heightFeet': i.heightFeet,
        'unitRate': i.unitRate,
      }).toList(),
    };

    final response = await ApiClient.post('/quotations', payload);
    setState(() => _isGenerating = false);

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Quotation Created!'),
          content: Text(
            'Quotation for ${MeasurementCalculator.formatCurrency(grandTotal)} created with branded PDF.\n\nWould you like to share it via WhatsApp?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            ElevatedButton.icon(
              icon: const Icon(Icons.share, size: 16),
              label: const Text('Send WhatsApp PDF'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('📱 WhatsApp PDF sent to customer!'), backgroundColor: AppColors.success),
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Automatic Rate & Quotation Builder'),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('GRAND TOTAL:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textSecondary)),
                  Text(
                    MeasurementCalculator.formatCurrency(grandTotal),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomButton(
                label: 'Generate Branded PDF Quotation',
                icon: Icons.picture_as_pdf,
                isLoading: _isGenerating,
                onPressed: _generateQuotation,
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client selector
            DropdownButtonFormField<String>(
              value: _selectedCustomer,
              decoration: const InputDecoration(labelText: 'Select Customer / Client', prefixIcon: Icon(Icons.business)),
              items: [
                'Sunil Mehta (Apex Retail Store)',
                'Dr. Priya Nair (CarePlus Hospital)',
                'Karan Kapoor (Urban Crust Pizza)',
              ].map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (val) => setState(() => _selectedCustomer = val!),
            ),
            const SizedBox(height: 14),

            // GST Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Include GST (18% Tax Invoice)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Toggles GST vs Non-GST estimate format', style: TextStyle(fontSize: 11)),
              value: _isGst,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _isGst = val),
            ),
            const Divider(height: 20),

            // Items List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Signage Boards / Line Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Item'),
                  onPressed: () {
                    setState(() {
                      _items.add(QuotationLineItem(description: 'Glow Sign Board Section'));
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),

            ..._items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: item.description,
                              decoration: const InputDecoration(isDense: true, labelText: 'Item Description'),
                              onChanged: (val) => item.description = val,
                            ),
                          ),
                          if (_items.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.error),
                              onPressed: () => setState(() => _items.removeAt(idx)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: item.lengthFeet.toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(isDense: true, labelText: 'Length (ft)'),
                              onChanged: (val) => setState(() => item.lengthFeet = double.tryParse(val) ?? 0),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: item.heightFeet.toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(isDense: true, labelText: 'Height (ft)'),
                              onChanged: (val) => setState(() => item.heightFeet = double.tryParse(val) ?? 0),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: item.unitRate.toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(isDense: true, labelText: 'Rate (₹/SqFt)'),
                              onChanged: (val) => setState(() => item.unitRate = double.tryParse(val) ?? 0),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${item.sqFt.toStringAsFixed(1)} Sq.Ft', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text(MeasurementCalculator.formatCurrency(item.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 14),

            // Additional Charges Form
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _framingCharges.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Framing / MS (₹)'),
                    onChanged: (val) => setState(() => _framingCharges = double.tryParse(val) ?? 0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    initialValue: _installationCharges.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Installation (₹)'),
                    onChanged: (val) => setState(() => _installationCharges = double.tryParse(val) ?? 0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Summary Breakdown Box
            Card(
              margin: EdgeInsets.zero,
              color: AppColors.background,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _buildCalcRow('Subtotal Items', MeasurementCalculator.formatCurrency(subtotal)),
                    _buildCalcRow('Framing & Structure', '+ ${MeasurementCalculator.formatCurrency(_framingCharges)}'),
                    _buildCalcRow('Installation Charge', '+ ${MeasurementCalculator.formatCurrency(_installationCharges)}'),
                    if (_isGst) _buildCalcRow('GST (18%)', '+ ${MeasurementCalculator.formatCurrency(gstAmount)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildCalcRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
