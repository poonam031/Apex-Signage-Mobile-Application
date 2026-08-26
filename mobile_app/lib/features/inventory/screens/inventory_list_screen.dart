import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/custom_button.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({Key? key}) : super(key: key);

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  bool _isLoading = true;
  List<dynamic> _items = [];
  bool _showOnlyLowStock = false;

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  Future<void> _fetchInventory() async {
    setState(() => _isLoading = true);
    final response = await ApiClient.get('/inventory');
    if (response.success && response.data != null) {
      setState(() {
        _items = response.data;
        _isLoading = false;
      });
    } else {
      // Demo mock inventory dataset
      setState(() {
        _items = [
          {'id': 'inv-1', 'name': 'Star Flex 440 GSM (10ft x 150ft Roll)', 'category': 'ROLL_FEET', 'unit': 'ROLL', 'currentStock': 14.0, 'minStockAlert': 5.0, 'costPrice': 2800.0},
          {'id': 'inv-2', 'name': 'Avery Dennison Gloss Vinyl (4ft x 150ft)', 'category': 'ROLL_FEET', 'unit': 'ROLL', 'currentStock': 3.0, 'minStockAlert': 6.0, 'costPrice': 3400.0},
          {'id': 'inv-3', 'name': 'Aludecor ACP Sheet 3mm (8ft x 4ft Deep Blue)', 'category': 'ACRYLIC_SHEET', 'unit': 'PIECE', 'currentStock': 22.0, 'minStockAlert': 8.0, 'costPrice': 1650.0},
          {'id': 'inv-4', 'name': 'Samsung 3-LED Module 1.2W Cool White', 'category': 'LED_MODULE', 'unit': 'PIECE', 'currentStock': 120.0, 'minStockAlert': 300.0, 'costPrice': 18.0},
          {'id': 'inv-5', 'name': 'MeanWell 12V 33A 400W Rainproof SMPS', 'category': 'SMPS_POWER', 'unit': 'PIECE', 'currentStock': 18.0, 'minStockAlert': 5.0, 'costPrice': 1150.0},
          {'id': 'inv-6', 'name': 'Apollo MS Square Pipe 1" x 1" 18-Gauge (20ft)', 'category': 'MS_PIPE', 'unit': 'PIECE', 'currentStock': 45.0, 'minStockAlert': 15.0, 'costPrice': 320.0},
        ];
        _isLoading = false;
      });
    }
  }

  void _showStockActionDialog(Map<String, dynamic> item) {
    final qtyController = TextEditingController(text: '5');
    String type = 'STOCK_IN';
    final reasonController = TextEditingController(text: 'Restock shipment received from supplier');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Stock Movement: ${item['name']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Transaction Type'),
                items: const [
                  DropdownMenuItem(value: 'STOCK_IN', child: Text('Stock In (Purchase/Restock)')),
                  DropdownMenuItem(value: 'STOCK_OUT', child: Text('Stock Out (Job Usage)')),
                  DropdownMenuItem(value: 'ADJUSTMENT', child: Text('Manual Count Adjustment')),
                ],
                onChanged: (val) => setDialogState(() => type = val!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: qtyController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Quantity (${item['unit']})'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'Reason / Bill No'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final qty = double.tryParse(qtyController.text) ?? 0.0;
                setState(() {
                  if (type == 'STOCK_IN') {
                    item['currentStock'] += qty;
                  } else if (type == 'STOCK_OUT') {
                    item['currentStock'] = (item['currentStock'] - qty).clamp(0.0, 99999.0);
                  } else {
                    item['currentStock'] = qty;
                  }
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Stock updated for ${item['name']}! Current: ${item['currentStock']} ${item['unit']}')),
                );
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final displayedItems = _showOnlyLowStock
        ? _items.where((i) => (i['currentStock'] as num) <= (i['minStockAlert'] as num)).toList()
        : _items;

    final lowStockCount = _items.where((i) => (i['currentStock'] as num) <= (i['minStockAlert'] as num)).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-Time Material Inventory'),
        actions: [
          IconButton(
            icon: Icon(_showOnlyLowStock ? Icons.filter_alt : Icons.filter_alt_outlined),
            tooltip: 'Filter Low Stock',
            onPressed: () => setState(() => _showOnlyLowStock = !_showOnlyLowStock),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchInventory,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Low stock summary chip bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${displayedItems.length} Materials Tracked',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                  ),
                  FilterChip(
                    selected: _showOnlyLowStock,
                    label: Text('⚠️ $lowStockCount Low Stock Alerts', style: TextStyle(fontSize: 11, color: _showOnlyLowStock ? Colors.white : AppColors.warning, fontWeight: FontWeight.bold)),
                    selectedColor: AppColors.warning,
                    backgroundColor: AppColors.warning.withOpacity(0.12),
                    onSelected: (val) => setState(() => _showOnlyLowStock = val),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayedItems.length,
                itemBuilder: (context, index) {
                  final item = displayedItems[index];
                  final isLow = (item['currentStock'] as num) <= (item['minStockAlert'] as num);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item['name'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                ),
                              ),
                              if (isLow)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('LOW STOCK', style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.w800)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Stock: ${item['currentStock']} ${item['unit']} (Min: ${item['minStockAlert']})',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: isLow ? AppColors.error : AppColors.success,
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: const Size(0, 32),
                                ),
                                onPressed: () => _showStockActionDialog(item),
                                child: const Text('Stock In / Out', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
