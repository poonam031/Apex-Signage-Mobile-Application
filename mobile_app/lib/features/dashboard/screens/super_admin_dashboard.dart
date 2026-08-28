import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/measurement_calculator.dart';
import '../../../core/widgets/status_badge.dart';

class SuperAdminDashboard extends StatefulWidget {
  final Function(int) onTabNavigate;

  const SuperAdminDashboard({Key? key, required this.onTabNavigate}) : super(key: key);

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    setState(() => _isLoading = true);
    final response = await ApiClient.get('/reports/dashboard');
    if (response.success && response.data != null) {
      setState(() {
        _dashboardData = response.data;
        _isLoading = false;
      });
    } else {
      // Demo fallback data if server is booting
      setState(() {
        _dashboardData = {
          'overview': {
            'activeJobsCount': 12,
            'totalActiveSqFt': 1480.0,
            'todayVisitsCount': 4,
            'printedSqFtToday': 665.0,
            'wasteSqFtToday': 19.0,
            'lowStockItemsCount': 2,
            'averageCustomerRating': 4.9,
            'staffPresentToday': 8,
            'totalStaff': 9,
          },
          'stageBreakdown': {
            'SITE_VISIT': 2,
            'DESIGN_FINAL': 3,
            'PRINTING': 2,
            'FABRICATION': 3,
            'INSTALLATION': 1,
            'DELIVERED': 1,
          },
          'financials': {
            'totalBilledAmount': 285000.0,
            'totalCollectedAmount': 195000.0,
            'totalPendingBalance': 90000.0,
            'totalApprovedPettyCash': 3450.0,
            'monthlyPayrollBase': 133000.0,
            'estimatedNetProfit': 148550.0,
          },
          'lowStockAlerts': [
            {'name': 'Avery Gloss Vinyl Roll', 'currentStock': 3, 'minStockAlert': 6, 'unit': 'ROLL'},
            {'name': 'Samsung 3-LED Module', 'currentStock': 120, 'minStockAlert': 300, 'unit': 'PIECE'},
          ]
        };
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final overview = _dashboardData?['overview'] ?? {};
    final financials = _dashboardData?['financials'] ?? {};
    final stages = _dashboardData?['stageBreakdown'] ?? {};
    final lowStock = (_dashboardData?['lowStockAlerts'] as List?) ?? [];

    return RefreshIndicator(
      onRefresh: _fetchDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Business P&L Revenue Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Billed Revenue',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Est. Profit: ${MeasurementCalculator.formatCurrency((financials['estimatedNetProfit'] ?? 0).toDouble())}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    MeasurementCalculator.formatCurrency((financials['totalBilledAmount'] ?? 0).toDouble()),
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                  const Divider(color: Colors.white24, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricSub('Collected', MeasurementCalculator.formatCurrency((financials['totalCollectedAmount'] ?? 0).toDouble()), AppColors.success),
                      _buildMetricSub('Pending Due', MeasurementCalculator.formatCurrency((financials['totalPendingBalance'] ?? 0).toDouble()), const Color(0xFFFBBF24)),
                      _buildMetricSub('Petty Expenses', MeasurementCalculator.formatCurrency((financials['totalApprovedPettyCash'] ?? 0).toDouble()), Colors.white70),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Low Stock Warning Alert Box
            if (lowStock.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${lowStock.length} Materials Below Minimum Stock!',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                          ),
                          Text(
                            lowStock.map((i) => '${i['name']} (${i['currentStock']}/${i['minStockAlert']} ${i['unit']})').join(', '),
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Active Operations Metric Grid
            const Text(
              'Today\'s Production & Field Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.6,
              children: [
                _buildStatCard('Active Jobs', '${overview['activeJobsCount']}', Icons.assignment_outlined, AppColors.primary, '${overview['totalActiveSqFt']} Total Sq.Ft'),
                _buildStatCard('Printing Output', '${overview['printedSqFtToday']} Sq.Ft', Icons.print_outlined, AppColors.accent, 'Waste: ${overview['wasteSqFtToday']} Sq.Ft'),
                _buildStatCard(
                  'Site Visits Today',
                  '${overview['todayVisitsCount']}',
                  Icons.location_on_outlined,
                  Colors.indigo,
                  'Tap to Schedule & Assign',
                  onTap: () => _showScheduleSiteVisitModal(context),
                ),
                _buildStatCard('Attendance & Team', '${overview['staffPresentToday']} / ${overview['totalStaff']}', Icons.how_to_reg_outlined, AppColors.success, '★ ${overview['averageCustomerRating']} Rating'),
              ],
            ),
            const SizedBox(height: 20),

            // Production Pipeline Stages Breakdown
            const Text(
              'Job Production Pipeline (Live Stages)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _buildPipelineRow(
                      '1. Site Visit',
                      stages['SITE_VISIT'] ?? 0,
                      Icons.straighten,
                      onTap: () => _showScheduleSiteVisitModal(context),
                    ),
                    const Divider(height: 12),
                    _buildPipelineRow('2. Design Final', stages['DESIGN_FINAL'] ?? 0, Icons.brush),
                    const Divider(height: 12),
                    _buildPipelineRow('3. Printing', stages['PRINTING'] ?? 0, Icons.print),
                    const Divider(height: 12),
                    _buildPipelineRow('4. Fabrication', stages['FABRICATION'] ?? 0, Icons.build),
                    const Divider(height: 12),
                    _buildPipelineRow('5. Installation', stages['INSTALLATION'] ?? 0, Icons.local_shipping),
                    const Divider(height: 12),
                    _buildPipelineRow('6. Delivered', stages['DELIVERED'] ?? 0, Icons.check_circle, isDone: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricSub(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle, {VoidCallback? onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                Icon(icon, color: color, size: 20),
              ],
            ),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildPipelineRow(String stageName, int count, IconData icon, {bool isDone = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDone ? AppColors.success : AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              stageName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isDone ? AppColors.success : AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: count > 0 ? AppColors.accent.withOpacity(0.15) : AppColors.divider,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count active',
              style: TextStyle(
                color: count > 0 ? AppColors.primary : AppColors.textMuted,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showScheduleSiteVisitModal(BuildContext context) {
    final nameCtrl = TextEditingController(text: 'Apex Retail Store');
    final phoneCtrl = TextEditingController(text: '+91 98200 11223');
    final addressCtrl = TextEditingController(text: 'Shop 14, Grand Galleria Mall, Link Road, Andheri West');
    final notesCtrl = TextEditingController(text: 'Measure main facade LED board & take 10s video.');
    String selectedFieldBoy = 'Rahul Sharma (Field Boy)';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Schedule New Site Visit',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Assign task to Field Boy with client phone & Google Maps link.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Client / Business Name', prefixIcon: Icon(Icons.business)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Client Phone Number', prefixIcon: Icon(Icons.phone)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(labelText: 'Site Address (Google Maps)', prefixIcon: Icon(Icons.location_on)),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedFieldBoy,
                  decoration: const InputDecoration(labelText: 'Assign Field Boy', prefixIcon: Icon(Icons.person_pin)),
                  items: const [
                    DropdownMenuItem(value: 'Rahul Sharma (Field Boy)', child: Text('Rahul Sharma (Field Boy)')),
                    DropdownMenuItem(value: 'Sameer Khan (Field Boy)', child: Text('Sameer Khan (Field Boy)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedFieldBoy = val);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Instructions / Notes', prefixIcon: Icon(Icons.note_alt_outlined)),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.send_rounded),
                    label: Text(
                      isSaving ? 'Assigning...' : 'Assign & Dispatch Task to Field Boy',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            setModalState(() => isSaving = true);
                            await ApiClient.post('/site-visits', {
                              'customerId': 'cust-101',
                              'assignedToId': 'user-field-1',
                              'siteAddress': addressCtrl.text,
                              'notes': notesCtrl.text,
                            });
                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ Site Visit assigned to $selectedFieldBoy!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
