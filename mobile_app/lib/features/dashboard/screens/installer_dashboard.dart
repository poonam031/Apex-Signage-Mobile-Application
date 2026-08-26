import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/custom_button.dart';
import '../../jobs/screens/job_detail_screen.dart';
import '../../petty_cash/screens/petty_cash_screen.dart';

class InstallerDashboard extends StatefulWidget {
  final Function(int) onTabNavigate;

  const InstallerDashboard({Key? key, required this.onTabNavigate}) : super(key: key);

  @override
  State<InstallerDashboard> createState() => _InstallerDashboardState();
}

class _InstallerDashboardState extends State<InstallerDashboard> {
  bool _isLoading = true;
  List<dynamic> _installJobs = [];

  @override
  void initState() {
    super.initState();
    _loadInstallTasks();
  }

  Future<void> _loadInstallTasks() async {
    setState(() => _isLoading = true);
    final response = await ApiClient.get('/jobs?stage=INSTALLATION');
    if (response.success && response.data != null && (response.data as List).isNotEmpty) {
      setState(() {
        _installJobs = response.data;
        _isLoading = false;
      });
    } else {
      // Demo fallback installation tasks
      setState(() {
        _installJobs = [
          {
            'id': 'job-101',
            'jobCode': 'JB-2026-0001',
            'boardType': 'Acrylic LED 3D Letter ACP Board',
            'currentStage': 'FABRICATION',
            'status': 'ACTIVE',
            'totalSqFt': 78.0,
            'customer': {
              'name': 'Sunil Mehta',
              'companyName': 'Apex Retail Fashion Store',
              'phone': '+919820011223',
              'address': 'Shop 14, Grand Galleria Mall, Link Road, Andheri West, Mumbai',
            },
          },
          {
            'id': 'job-102',
            'jobCode': 'JB-2026-0002',
            'boardType': 'Hospital Emergency Glow Sign 24x7',
            'currentStage': 'DELIVERED',
            'status': 'COMPLETED',
            'totalSqFt': 40.0,
            'customer': {
              'name': 'Dr. Priya Nair',
              'companyName': 'CarePlus Hospital',
              'phone': '+919830022334',
              'address': 'Plot 7, Sector 15, Vashi, Navi Mumbai',
            },
          }
        ];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _loadInstallTasks,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Action Card for Site Petty Cash & Customer Signature
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade900,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.handyman_outlined, color: Colors.white, size: 26),
                      SizedBox(width: 10),
                      Text(
                        'On-Site Installation Toolkit',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Record site screws & transport bills, capture before/after photos, and collect client signature.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          label: 'Add Petty Expense',
                          icon: Icons.receipt_long,
                          backgroundColor: Colors.teal.shade600,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PettyCashScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Assigned Installation Deliveries',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _installJobs.length,
              itemBuilder: (context, index) {
                final job = _installJobs[index];
                final customer = job['customer'] ?? {};

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
                            Text(
                              job['jobCode'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                            ),
                            StatusBadge(status: job['currentStage'] ?? 'INSTALLATION'),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          customer['companyName'] ?? customer['name'] ?? 'Client',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(customer['phone'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.navigation_outlined, size: 16, color: Colors.teal),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                customer['address'] ?? 'Site address',
                                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${job['totalSqFt']} Sq.Ft • ${job['boardType']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.check_circle_outline, size: 16),
                              label: const Text('Complete & Sign', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                minimumSize: const Size(0, 36),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
                                ).then((_) => _loadInstallTasks());
                              },
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
    );
  }
}
