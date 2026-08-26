import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/status_badge.dart';
import '../../site_visit/screens/site_visit_detail_screen.dart';

class FieldBoyDashboard extends StatefulWidget {
  final Function(int) onTabNavigate;

  const FieldBoyDashboard({Key? key, required this.onTabNavigate}) : super(key: key);

  @override
  State<FieldBoyDashboard> createState() => _FieldBoyDashboardState();
}

class _FieldBoyDashboardState extends State<FieldBoyDashboard> {
  bool _isLoading = true;
  List<dynamic> _siteVisits = [];

  @override
  void initState() {
    super.initState();
    _fetchVisits();
  }

  Future<void> _fetchVisits() async {
    setState(() => _isLoading = true);
    final response = await ApiClient.get('/site-visits');
    if (response.success && response.data != null) {
      setState(() {
        _siteVisits = response.data;
        _isLoading = false;
      });
    } else {
      // Demo fallback tasks for Field Boy
      setState(() {
        _siteVisits = [
          {
            'id': 'sv-101',
            'status': 'ASSIGNED',
            'visitDateTime': DateTime.now().toIso8601String(),
            'siteAddress': 'Shop 14, Grand Galleria Mall, Link Road, Andheri West',
            'notes': 'Store entrance facade measurement and structural inspection.',
            'customer': {
              'name': 'Sunil Mehta',
              'companyName': 'Apex Retail Fashion Store',
              'phone': '+919820011223',
            },
            'measurements': [],
          },
          {
            'id': 'sv-102',
            'status': 'SUBMITTED',
            'visitDateTime': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
            'siteAddress': 'Plot 7, Sector 15, Vashi, Navi Mumbai',
            'notes': 'Emergency 24x7 Glow sign and wayfinding directional signage.',
            'customer': {
              'name': 'Dr. Priya Nair',
              'companyName': 'CarePlus Multispeciality Hospital',
              'phone': '+919830022334',
            },
            'measurements': [
              {'boardName': 'Main Facade', 'squareFeet': 60.0},
            ],
          }
        ];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final assignedCount = _siteVisits.where((v) => v['status'] == 'ASSIGNED').length;
    final inProgressCount = _siteVisits.where((v) => v['status'] == 'IN_PROGRESS').length;
    final submittedCount = _siteVisits.where((v) => v['status'] == 'SUBMITTED' || v['status'] == 'COMPLETED').length;

    return RefreshIndicator(
      onRefresh: _fetchVisits,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Status Counter Banner
            Row(
              children: [
                _buildQuickCard('Pending', '$assignedCount', AppColors.warning, Icons.pending_actions),
                const SizedBox(width: 8),
                _buildQuickCard('In-Progress', '$inProgressCount', AppColors.info, Icons.straighten),
                const SizedBox(width: 8),
                _buildQuickCard('Submitted', '$submittedCount', AppColors.success, Icons.cloud_done),
              ],
            ),
            const SizedBox(height: 18),

            // Field Boy Action Bar
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app, color: AppColors.accent, size: 24),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Ready for site visit? Tap a task to start measurements & photo annotations.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            const Text(
              'My Assigned Site Tasks',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),

            if (_siteVisits.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No site visits assigned yet.', style: TextStyle(color: AppColors.textSecondary)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _siteVisits.length,
                itemBuilder: (context, index) {
                  final visit = _siteVisits[index];
                  final customer = visit['customer'] ?? {};
                  final measurements = (visit['measurements'] as List?) ?? [];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SiteVisitDetailScreen(siteVisit: visit),
                          ),
                        ).then((_) => _fetchVisits());
                      },
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
                                    customer['companyName'] ?? customer['name'] ?? 'Client Site',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ),
                                StatusBadge(status: visit['status'] ?? 'ASSIGNED'),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(customer['name'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                const SizedBox(width: 12),
                                const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(customer['phone'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    visit['siteAddress'] ?? 'No address provided',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  measurements.isEmpty
                                      ? 'No measurements recorded'
                                      : '${measurements.length} Board(s) measured',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: measurements.isNotEmpty ? AppColors.success : AppColors.textMuted,
                                  ),
                                ),
                                const Row(
                                  children: [
                                    Text('Open Form', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                    Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primary),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCard(String label, String count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
