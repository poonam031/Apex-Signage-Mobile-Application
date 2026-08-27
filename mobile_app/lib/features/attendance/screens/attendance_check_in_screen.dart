import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/status_badge.dart';

class AttendanceCheckInScreen extends StatefulWidget {
  const AttendanceCheckInScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceCheckInScreen> createState() => _AttendanceCheckInScreenState();
}

class _AttendanceCheckInScreenState extends State<AttendanceCheckInScreen> {
  bool _isLoading = false;
  bool _isCheckedIn = false;
  String? _checkInTime;
  String? _checkOutTime;
  String _status = 'PRESENT';
  double _distanceFromShopMeters = 35.0; // Simulated inside 200m radius
  bool _isWithin200m = true;
  String _selectedMethod = 'GEOFENCE_GPS'; // GEOFENCE_GPS, QR_SCAN, SELFIE

  @override
  void initState() {
    super.initState();
    _fetchTodayStatus();
  }

  Future<void> _fetchTodayStatus() async {
    final res = await ApiClient.get('/attendance/today-status');
    if (res.success && res.data != null) {
      final data = res.data;
      if (data['isCheckedIn'] == true) {
        final att = data['attendance'];
        setState(() {
          _isCheckedIn = true;
          _checkInTime = att['checkInTime'] != null ? DateTime.parse(att['checkInTime']).toLocal().toString().substring(11, 16) : '09:15 AM';
          _checkOutTime = att['checkOutTime'] != null ? DateTime.parse(att['checkOutTime']).toLocal().toString().substring(11, 16) : null;
          _status = att['status'] ?? 'PRESENT';
        });
      }
    }
  }

  Future<void> _handleCheckIn() async {
    String? selfiePath;
    if (_selectedMethod == 'SELFIE') {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
      );
      if (image == null) return; // User cancelled selfie capture
      selfiePath = image.path;
    }

    setState(() => _isLoading = true);

    final payload = {
      'method': _selectedMethod,
      'latitude': 19.0761,
      'longitude': 72.8778,
      'selfieUrl': selfiePath ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300',
      'notes': 'Verified via mobile app check-in screen',
    };

    final response = await ApiClient.post('/attendance/check-in', payload);
    setState(() => _isLoading = false);

    if (response.success) {
      final now = DateTime.now();
      setState(() {
        _isCheckedIn = true;
        _checkInTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        _status = response.data?['isLate'] == true ? 'LATE' : 'PRESENT';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Checked in successfully as $_status (${_distanceFromShopMeters.toInt()}m from workshop)'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'Check-in failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleCheckOut() async {
    setState(() => _isLoading = true);
    final response = await ApiClient.post('/attendance/check-out', {});
    setState(() => _isLoading = false);

    final now = DateTime.now();
    setState(() {
      _checkOutTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('👋 Punch out / Check-out recorded! Have a great evening.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Attendance & Geofencing'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Geofence 200m Status Badge Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isWithin200m ? AppColors.success.withOpacity(0.12) : AppColors.error.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _isWithin200m ? AppColors.success : AppColors.error),
              ),
              child: Row(
                children: [
                  Icon(
                    _isWithin200m ? Icons.location_on : Icons.location_off,
                    color: _isWithin200m ? AppColors.success : AppColors.error,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isWithin200m ? 'Inside Factory Geofence (200m)' : 'Outside Factory Area',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _isWithin200m ? AppColors.success : AppColors.error,
                          ),
                        ),
                        Text(
                          'Current distance: ${_distanceFromShopMeters.toInt()} meters from Main Workshop',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Today's Check-in Record Card
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Today\'s Punch Status:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        if (_isCheckedIn) StatusBadge(status: _status),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Punch In', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text(
                              _checkInTime ?? '--:--',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                        Container(width: 1, height: 36, color: AppColors.border),
                        Column(
                          children: [
                            const Text('Punch Out', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text(
                              _checkOutTime ?? '--:--',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (!_isCheckedIn) ...[
              const Text(
                'Select Attendance Verification Method:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),

              // Mode 1: Geofence GPS
              _buildMethodRadio(
                'GEOFENCE_GPS',
                '200m Geofence GPS Verification',
                'Instantly verifies your GPS coordinates within 200m radius',
                Icons.gps_fixed,
              ),

              // Mode 2: QR Scanner
              _buildMethodRadio(
                'QR_SCAN',
                'Scan Workshop QR Code',
                'Scan the physical QR poster located at factory entrance gate',
                Icons.qr_code_scanner,
              ),

              // Mode 3: Selfie Verification
              _buildMethodRadio(
                'SELFIE',
                'Selfie Camera Punch In',
                'Capture photo timestamp for on-site verification',
                Icons.camera_front,
              ),
              const SizedBox(height: 20),

              CustomButton(
                label: 'Punch In Attendance Now',
                icon: Icons.how_to_reg,
                isLoading: _isLoading,
                onPressed: _handleCheckIn,
              ),
            ] else if (_checkOutTime == null) ...[
              CustomButton(
                label: 'Punch Out for the Day',
                icon: Icons.exit_to_app,
                backgroundColor: AppColors.warning,
                isLoading: _isLoading,
                onPressed: _handleCheckOut,
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    '🎉 You have completed your shift today! See you tomorrow.',
                    style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMethodRadio(String value, String title, String subtitle, IconData icon) {
    final isSelected = _selectedMethod == value;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isSelected ? AppColors.accentLight : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? AppColors.accent : AppColors.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: _selectedMethod,
        activeColor: AppColors.accent,
        title: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? AppColors.accent : AppColors.primary),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        onChanged: (val) {
          if (val != null) setState(() => _selectedMethod = val);
        },
      ),
    );
  }
}
