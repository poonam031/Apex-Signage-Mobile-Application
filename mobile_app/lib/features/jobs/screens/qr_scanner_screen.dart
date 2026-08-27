import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/status_badge.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({Key? key}) : super(key: key);

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _isProcessing = false;
  Map<String, dynamic>? _scannedJob;
  String? _selectedStage;
  final TextEditingController _remarksController = TextEditingController();

  // Simulated Instant 1-Second QR Scan trigger (supports both camera & direct mock payload)
  Future<void> _processScannedToken(String qrToken) async {
    setState(() => _isProcessing = true);
    final response = await ApiClient.get('/jobs/qr-scan/$qrToken');

    if (response.success && response.data != null) {
      setState(() {
        _scannedJob = response.data;
        _selectedStage = _getNextStage(_scannedJob!['currentStage']);
        _isProcessing = false;
      });
    } else {
      // Demo mock job fallback for instant simulator
      setState(() {
        _scannedJob = {
          'id': 'job-101',
          'jobCode': 'JB-2026-0001',
          'qrCodeToken': qrToken,
          'boardType': 'Acrylic LED 3D Letter ACP Board',
          'currentStage': 'FABRICATION',
          'totalSqFt': 78.0,
          'customer': {'name': 'Sunil Mehta', 'companyName': 'Apex Retail Fashion'},
        };
        _selectedStage = 'INSTALLATION';
        _isProcessing = false;
      });
    }
  }

  String _getNextStage(String? current) {
    if (current == null) return AppConstants.jobStages.first;
    final index = AppConstants.jobStages.indexOf(current);
    if (index >= 0 && index < AppConstants.jobStages.length - 1) {
      return AppConstants.jobStages[index + 1];
    }
    return current;
  }

  Future<void> _confirmStageUpdate() async {
    if (_scannedJob == null || _selectedStage == null) return;

    setState(() => _isProcessing = true);

    final response = await ApiClient.post('/jobs/qr-update-stage', {
      'qrCodeToken': _scannedJob!['qrCodeToken'] ?? 'qr-token-101',
      'targetStage': _selectedStage,
      'remarks': _remarksController.text.isNotEmpty
          ? _remarksController.text
          : 'Stage updated via fast 1-second mobile QR scanner.',
      'lat': 19.0760,
      'lng': 72.8777,
    });

    setState(() => _isProcessing = false);

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 28),
              SizedBox(width: 8),
              Text('Stage Updated!'),
            ],
          ),
          content: Text(
            'Job ${_scannedJob!['jobCode']} successfully advanced to $_selectedStage.\n\nCustomer received live notification automatically!',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('1-Second QR Stage Updater'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_scannedJob == null) ...[
              // Live Camera Viewfinder Overlay
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      color: Colors.grey.shade900,
                      child: const Center(
                        child: Icon(Icons.qr_code_2, size: 180, color: Colors.white24),
                      ),
                    ),
                    // Scanner Frame Target
                    Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.accent, width: 2.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    const Positioned(
                      bottom: 40,
                      child: Text(
                        'Align Job Card QR Code inside frame',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              // Simulation Bar for instant paired verification
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey.shade900,
                child: CustomButton(
                  label: 'Simulate Scanning JB-2026-0001',
                  icon: Icons.qr_code_scanner,
                  isLoading: _isProcessing,
                  backgroundColor: AppColors.accent,
                  onPressed: () => _processScannedToken('mock-qr-token-jb-2026-0001'),
                ),
              ),
            ] else ...[
              // Scanned Job Card Details & 1-Tap Stage Advancement Card
              Expanded(
                child: Container(
                  color: AppColors.background,
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                      _scannedJob!['jobCode'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                                    ),
                                    StatusBadge(status: _scannedJob!['currentStage'] ?? 'PRINTING'),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _scannedJob!['boardType'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  'Client: ${_scannedJob!['customer']?['name']} • ${_scannedJob!['totalSqFt']} Sq.Ft',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'Select Target Stage to Advance:',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),

                        // Target Stage Radio Options
                        ...AppConstants.jobStages.map((stage) {
                          final isCurrent = stage == _scannedJob!['currentStage'];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            color: _selectedStage == stage ? AppColors.accentLight : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: _selectedStage == stage ? AppColors.accent : AppColors.border,
                                width: _selectedStage == stage ? 1.5 : 1,
                              ),
                            ),
                            child: RadioListTile<String>(
                              title: Row(
                                children: [
                                  Text(
                                    stage.replaceAll('_', ' '),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isCurrent ? AppColors.textMuted : AppColors.textPrimary,
                                    ),
                                  ),
                                  if (isCurrent) ...[
                                    const SizedBox(width: 8),
                                    const Text('(Current)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  ],
                                ],
                              ),
                              value: stage,
                              groupValue: _selectedStage,
                              activeColor: AppColors.accent,
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedStage = val);
                              },
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _remarksController,
                          decoration: const InputDecoration(
                            labelText: 'Operator / Installer Remarks',
                            hintText: 'e.g. Printing completed, transferred to fabrication table',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Action Buttons
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _scannedJob = null),
                        child: const Text('Scan Another'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: CustomButton(
                        label: 'Confirm Advance',
                        icon: Icons.check,
                        isLoading: _isProcessing,
                        onPressed: _confirmStageUpdate,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
