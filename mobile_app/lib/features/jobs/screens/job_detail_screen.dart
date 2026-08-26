import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/measurement_calculator.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/custom_button.dart';
import '../../feedback/screens/signature_capture_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final Map<String, dynamic> job;

  const JobDetailScreen({Key? key, required this.job}) : super(key: key);

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late Map<String, dynamic> _job;

  @override
  void initState() {
    super.initState();
    _job = widget.job;
  }

  @override
  Widget build(BuildContext context) {
    final customer = _job['customer'] ?? {};
    final currentStage = _job['currentStage'] ?? 'SITE_VISIT';
    final qrToken = _job['qrCodeToken'] ?? 'mock-qr-token-101';
    final feedback = (_job['feedbacks'] as List?)?.isNotEmpty == true ? _job['feedbacks'][0] : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_job['jobCode'] ?? 'Job Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            tooltip: 'View Printable Job QR Code',
            onPressed: () => _showQrModal(qrToken),
          ),
        ],
      ),
      bottomNavigationBar: currentStage == 'INSTALLATION'
          ? Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: SafeArea(
                child: CustomButton(
                  label: 'Collect Customer Signature & Finish',
                  icon: Icons.draw,
                  backgroundColor: Colors.teal.shade700,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SignatureCaptureScreen(
                          jobCode: _job['jobCode'] ?? 'JB-2026-0001',
                          customerName: customer['name'] ?? 'Client',
                          onSaved: (sigBase64, rating, comment) {
                            setState(() {
                              _job['currentStage'] = 'DELIVERED';
                              _job['status'] = 'COMPLETED';
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🎉 Job Delivered! Digital signature and 5-star rating saved.'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job Header Summary Card
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _job['jobCode'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary),
                        ),
                        StatusBadge(status: currentStage),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _job['boardType'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Customer: ${customer['companyName'] ?? customer['name']} • ${customer['phone']}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatPill('Total Area', '${_job['totalSqFt'] ?? 0} Sq.Ft'),
                        _buildStatPill('Contract Value', MeasurementCalculator.formatCurrency((_job['totalAmount'] ?? 38500).toDouble())),
                        _buildStatPill('Pending Due', MeasurementCalculator.formatCurrency((_job['pendingAmount'] ?? 18500).toDouble())),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Visual Production Timeline (Site Visit -> Delivered)
            const Text(
              'Production Workflow Progress',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  children: [
                    _buildTimelineStep(1, 'Site Visit & Smart Measurement', 'SITE_VISIT', currentStage),
                    _buildTimelineStep(2, 'Design Final & Vector Proof', 'DESIGN_FINAL', currentStage),
                    _buildTimelineStep(3, 'High-Definition Printing (DPR)', 'PRINTING', currentStage),
                    _buildTimelineStep(4, 'Fabrication & 3D Assembly', 'FABRICATION', currentStage),
                    _buildTimelineStep(5, 'Site Installation & Wiring', 'INSTALLATION', currentStage),
                    _buildTimelineStep(6, 'Delivered & Customer Sign-Off', 'DELIVERED', currentStage, isLast: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Customer Digital Signature & Feedback Card (if delivered)
            if (currentStage == 'DELIVERED') ...[
              const Text(
                'Customer Sign-Off & Review',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                color: Colors.teal.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.verified, color: Colors.teal, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Verified Digital Customer Sign-off',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '⭐⭐⭐⭐⭐ 5.0 Stars',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feedback?['feedbackText'] ?? 'Super fast installation! Glow sign looks extremely vibrant and visible from 200m away.',
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildTimelineStep(int stepNum, String title, String stageKey, String currentStage, {bool isLast = false}) {
    final stages = AppConstants.jobStages;
    final currentIndex = stages.indexOf(currentStage);
    final stepIndex = stages.indexOf(stageKey);

    final isCompleted = currentIndex > stepIndex || (currentIndex == stepIndex && currentStage == 'DELIVERED');
    final isCurrent = currentIndex == stepIndex && currentStage != 'DELIVERED';

    Color dotColor = AppColors.border;
    if (isCompleted) dotColor = AppColors.success;
    if (isCurrent) dotColor = AppColors.accent;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.success : (isCurrent ? AppColors.accent : Colors.white),
                shape: BoxShape.circle,
                border: Border.all(color: dotColor, width: 2),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Text(
                        '$stepNum',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isCurrent ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 26,
                color: isCompleted ? AppColors.success : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isCurrent || isCompleted ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted
                        ? AppColors.success
                        : (isCurrent ? AppColors.primary : AppColors.textSecondary),
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('In Progress', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accent)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showQrModal(String qrToken) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Job Card QR: ${_job['jobCode']}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            QrImageView(
              data: qrToken,
              version: QrVersions.auto,
              size: 200.0,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.primary),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Print and attach this QR code to physical job materials.\nOperators can scan in 1 second to update production stage.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
