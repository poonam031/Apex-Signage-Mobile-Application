import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../jobs/screens/qr_scanner_screen.dart';
import '../../jobs/screens/job_detail_screen.dart';

class DesignerDashboard extends StatefulWidget {
  final Function(int) onTabNavigate;

  const DesignerDashboard({Key? key, required this.onTabNavigate}) : super(key: key);

  @override
  State<DesignerDashboard> createState() => _DesignerDashboardState();
}

class _DesignerDashboardState extends State<DesignerDashboard> {
  bool _isLoading = true;
  List<dynamic> _jobs = [];
  Map<String, dynamic>? _dprStats;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final jobsRes = await ApiClient.get('/jobs');
    final dprRes = await ApiClient.get('/dpr/stats');

    setState(() {
      if (jobsRes.success && jobsRes.data != null) {
        _jobs = jobsRes.data;
      } else {
        _jobs = [
          {
            'id': 'job-101',
            'jobCode': 'JB-2026-0001',
            'boardType': 'Acrylic LED 3D Letter ACP Board',
            'currentStage': 'FABRICATION',
            'status': 'ACTIVE',
            'totalSqFt': 78.0,
            'customer': {'name': 'Sunil Mehta', 'companyName': 'Apex Retail Fashion'},
            'qrCodeToken': 'qr-token-101',
          },
          {
            'id': 'job-102',
            'jobCode': 'JB-2026-0002',
            'boardType': 'Hospital Emergency Glow Sign 24x7',
            'currentStage': 'DELIVERED',
            'status': 'COMPLETED',
            'totalSqFt': 40.0,
            'customer': {'name': 'Dr. Priya Nair', 'companyName': 'CarePlus Hospital'},
            'qrCodeToken': 'qr-token-102',
          },
        ];
      }
      _dprStats = dprRes.success ? dprRes.data : {'today': {'totalPrintedSqFt': 665.0, 'wastePercentage': 2.8}};
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final todayPrinted = _dprStats?['today']?['totalPrintedSqFt'] ?? 0;
    final wastePercent = _dprStats?['today']?['wastePercentage'] ?? 0.0;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1-Second Fast QR Scanner Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF0D3B66)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Instant 1-Second QR Stage Updater',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'Scan physical job card QR to update stage immediately',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  CustomButton(
                    label: 'Scan Job QR Code',
                    icon: Icons.camera_alt_outlined,
                    backgroundColor: AppColors.accent,
                    textColor: Colors.white,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                      ).then((_) => _loadData());
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Production & Gamification Points Overview
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    'Today\'s Output',
                    '$todayPrinted Sq.Ft',
                    'Waste: $wastePercent%',
                    Icons.speed,
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    'Monthly Points',
                    '250 Pts',
                    'Rank #1 (Employee of Month)',
                    Icons.military_tech,
                    AppColors.gold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Active Design & Production Queue
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Active Jobs Queue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                TextButton(
                  onPressed: () => widget.onTabNavigate(1), // Navigate to Jobs tab
                  child: const Text('View All', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 4),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _jobs.length,
              itemBuilder: (context, index) {
                final job = _jobs[index];
                final customer = job['customer'] ?? {};

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          job['jobCode'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                        ),
                        StatusBadge(status: job['currentStage'] ?? 'SITE_VISIT'),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(job['boardType'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                        Text('${customer['companyName'] ?? customer['name']} • ${job['totalSqFt']} Sq.Ft', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
                      ).then((_) => _loadData());
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color == AppColors.gold ? const Color(0xFFB45309) : color)),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
