import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/sync_status_badge.dart';
import '../../../core/storage/local_storage.dart';
import 'smart_measurement_screen.dart';
import 'photo_annotation_screen.dart';
import 'video_recording_screen.dart';
import 'technical_checklist_screen.dart';

class SiteVisitDetailScreen extends StatefulWidget {
  final Map<String, dynamic> siteVisit;

  const SiteVisitDetailScreen({Key? key, required this.siteVisit}) : super(key: key);

  @override
  State<SiteVisitDetailScreen> createState() => _SiteVisitDetailScreenState();
}

class _SiteVisitDetailScreenState extends State<SiteVisitDetailScreen> {
  late Map<String, dynamic> _visit;
  List<BoardMeasurementItem> _measurements = [];
  TechnicalChecklistData _checklist = TechnicalChecklistData();
  bool _hasAnnotatedPhoto = false;
  bool _hasVideo = false;
  String? _videoUrl;
  SyncStatus _syncStatus = SyncStatus.synced;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _visit = widget.siteVisit;
    final existingMeasurements = (_visit['measurements'] as List?) ?? [];
    if (existingMeasurements.isNotEmpty) {
      _measurements = existingMeasurements.map((m) {
        return BoardMeasurementItem(
          boardName: m['boardName'] ?? 'Main Board',
          lengthFeet: (m['lengthFeet'] ?? 0.0).toDouble(),
          heightFeet: (m['heightFeet'] ?? 0.0).toDouble(),
          materialType: m['materialType'] ?? 'ACP Sheet',
          pipeGauge: m['pipeGauge'] ?? '1" x 1" (18 Gauge)',
        );
      }).toList();
    } else {
      _measurements = [
        BoardMeasurementItem(boardName: 'Board 1: Main Entrance LED Board', lengthFeet: 15.0, heightFeet: 4.0),
      ];
    }
  }

  double get totalSqFt => _measurements.fold(0.0, (sum, b) => sum + b.squareFeet);
  double get totalSqM => _measurements.fold(0.0, (sum, b) => sum + b.squareMeters);

  Future<void> _openGoogleMaps(String address) async {
    final query = Uri.encodeComponent(address);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  String? _annotatedPhotoPath;

  Future<void> _captureOrSelectPhoto() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Capture Site Facade Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.accentLight,
                  child: Icon(Icons.camera_alt, color: AppColors.accent),
                ),
                title: const Text('Take Live Photo with Camera'),
                subtitle: const Text('Capture facade using phone camera'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picker = ImagePicker();
                  final image = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 85,
                  );
                  if (image != null && mounted) {
                    _openAnnotationScreen(imagePath: image.path);
                  }
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blueGrey,
                  child: Icon(Icons.photo_library, color: Colors.white),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select existing photo from phone'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picker = ImagePicker();
                  final image = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                  );
                  if (image != null && mounted) {
                    _openAnnotationScreen(imagePath: image.path);
                  }
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.storefront, color: Colors.white),
                ),
                title: const Text('Use Sample Retail Facade Photo'),
                subtitle: const Text('Pre-loaded building sample for quick demo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openAnnotationScreen(imageUrl: 'https://images.unsplash.com/photo-1541888946425-d0fbb18015f6?w=800');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAnnotationScreen({String? imagePath, String? imageUrl}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoAnnotationScreen(
          imagePath: imagePath,
          imageUrl: imageUrl,
          onSave: (paths, finalPath) {
            setState(() {
              _hasAnnotatedPhoto = true;
              _annotatedPhotoPath = finalPath;
            });
          },
        ),
      ),
    );
  }

  Future<void> _callCustomer(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _submitSiteVisit() async {
    setState(() {
      _isSubmitting = true;
      _syncStatus = SyncStatus.uploading;
    });

    final payload = {
      'measurements': _measurements.map((b) => {
        'boardName': b.boardName,
        'lengthFeet': b.lengthFeet,
        'heightFeet': b.heightFeet,
        'materialType': b.materialType,
        'pipeGauge': b.pipeGauge,
        'framingType': b.framingType,
      }).toList(),
      'technicalChecklist': {
        'boardFloorHeight': _checklist.boardFloorHeight,
        'powerSupplyDistanceFeet': _checklist.powerSupplyDistanceFeet,
        'ladderRequired': _checklist.ladderRequired,
        'craneRequired': _checklist.craneRequired,
        'scaffoldingRequired': _checklist.scaffoldingRequired,
        'obstacles': _checklist.obstacles,
        'notes': _checklist.notes,
      },
      'mediaList': [
        {
          'mediaType': 'ANNOTATED_PHOTO',
          'fileUrl': 'https://images.unsplash.com/photo-1541888946425-d0fbb18015f6?w=800',
          'metadata': '{"annotations": ["15ft Width", "4ft Height"]}',
        },
        if (_hasVideo)
          {
            'mediaType': 'VIDEO',
            'fileUrl': _videoUrl ?? 'https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4',
            'durationSeconds': 10,
          }
      ],
      'notes': 'Site measurements and checklist verified by Field Boy on location.',
    };

    final visitId = _visit['id'] ?? 'sv-101';
    final response = await ApiClient.post('/site-visits/$visitId/submit', payload);

    setState(() => _isSubmitting = false);

    if (response.success) {
      setState(() {
        _syncStatus = SyncStatus.synced;
        _visit['status'] = 'SUBMITTED';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Site Visit submitted successfully! Synced to Office & Designers.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      // Save offline draft
      await LocalStorage.saveOfflineSiteVisit({'visitId': visitId, 'payload': payload});
      setState(() => _syncStatus = SyncStatus.draft);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Network offline. Saved draft locally! Will auto-sync when online.'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = _visit['customer'] ?? {};
    final address = _visit['siteAddress'] ?? customer['address'] ?? 'No address';

    return Scaffold(
      appBar: AppBar(
        title: Text(customer['companyName'] ?? customer['name'] ?? 'Site Visit Details'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: SyncStatusBadge(status: _syncStatus)),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: CustomButton(
            label: _visit['status'] == 'SUBMITTED' ? 'Update & Re-Sync to Designer' : 'Submit & Sync to Designer',
            icon: Icons.cloud_upload_outlined,
            isLoading: _isSubmitting,
            onPressed: _submitSiteVisit,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer & Navigation Card
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          customer['name'] ?? 'Client',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        StatusBadge(status: _visit['status'] ?? 'ASSIGNED'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(address, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.phone, size: 16),
                            label: const Text('Call Client'),
                            onPressed: () => _callCustomer(customer['phone'] ?? '+919820011223'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.directions, size: 16),
                            label: const Text('Navigate Map'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                            onPressed: () => _openGoogleMaps(address),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 1. Smart Measurement Section
            _buildSectionHeader('1. Digital Smart Measurements', Icons.straighten),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                title: Text(
                  '${_measurements.length} Board Section(s) Configured',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  'Total: ${totalSqFt.toStringAsFixed(1)} Sq.Ft (${totalSqM.toStringAsFixed(2)} Sq.Meters)',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SmartMeasurementScreen(
                        initialBoards: _measurements,
                        onSave: (saved) => setState(() => _measurements = saved),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),

            // 2. Photo Annotation Canvas
            _buildSectionHeader('2. Site Photograph & Touch Annotation', Icons.draw_outlined),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _hasAnnotatedPhoto ? AppColors.success.withOpacity(0.15) : AppColors.accentLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _hasAnnotatedPhoto ? Icons.check_circle : Icons.add_a_photo_outlined,
                    color: _hasAnnotatedPhoto ? AppColors.success : AppColors.accent,
                  ),
                ),
                title: Text(
                  _hasAnnotatedPhoto ? 'Annotated Photo Attached' : 'Capture & Annotate Site Photo',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  _hasAnnotatedPhoto ? 'Touch drawing & dimensions added' : 'Draw width/height directly on site photo',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                onTap: _captureOrSelectPhoto,
              ),
            ),
            const SizedBox(height: 18),

            // 3. 10-Second Video Clip
            _buildSectionHeader('3. Site Video Clip (10 Seconds)', Icons.videocam_outlined),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _hasVideo ? AppColors.success.withOpacity(0.15) : Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _hasVideo ? Icons.check_circle : Icons.video_camera_front_outlined,
                    color: _hasVideo ? AppColors.success : Colors.purple,
                  ),
                ),
                title: Text(
                  _hasVideo ? '10-Second Video Attached' : 'Record 10-Second Site Video',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  _hasVideo ? '10s HD MP4 clip ready for upload' : 'Required to assess surrounding trees & road clearance',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VideoRecordingScreen(
                        onVideoRecorded: (url, sec) {
                          setState(() {
                            _hasVideo = true;
                            _videoUrl = url;
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),

            // 4. Technical Checklist
            _buildSectionHeader('4. Technical Checklist', Icons.checklist_outlined),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                title: Text(
                  _checklist.boardFloorHeight,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  'Power: ${_checklist.powerSupplyDistanceFeet}ft • Ladder: ${_checklist.ladderRequired ? 'Yes' : 'No'} • Crane: ${_checklist.craneRequired ? 'Yes' : 'No'}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TechnicalChecklistScreen(
                        initialData: _checklist,
                        onSave: (saved) => setState(() => _checklist = saved),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
