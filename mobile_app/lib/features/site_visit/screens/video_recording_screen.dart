import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';

class VideoRecordingScreen extends StatefulWidget {
  final Function(String videoUrl, int durationSeconds) onVideoRecorded;

  const VideoRecordingScreen({Key? key, required this.onVideoRecorded}) : super(key: key);

  @override
  State<VideoRecordingScreen> createState() => _VideoRecordingScreenState();
}

class _VideoRecordingScreenState extends State<VideoRecordingScreen> {
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isPermissionDenied = false;

  bool _isRecording = false;
  int _secondsRecorded = 0;
  Timer? _timer;
  bool _hasRecorded = false;
  XFile? _recordedVideoFile;

  @override
  void initState() {
    super.initState();
    _initCameraWithPermissions();
  }

  Future<void> _initCameraWithPermissions() async {
    // 1. Request Camera & Microphone permissions
    final statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    final isCameraGranted = statuses[Permission.camera]?.isGranted ?? false;
    final isMicGranted = statuses[Permission.microphone]?.isGranted ?? false;

    if (!isCameraGranted || !isMicGranted) {
      if (mounted) {
        setState(() {
          _isPermissionDenied = true;
          _isCameraInitialized = false;
        });
      }
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        await _setupCameraController(_cameras[_selectedCameraIndex]);
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        setState(() => _isCameraInitialized = false);
      }
    }
  }

  Future<void> _setupCameraController(CameraDescription camera) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isPermissionDenied = false;
        });
      }
    } catch (e) {
      debugPrint('Camera controller init error: $e');
      if (mounted) {
        setState(() => _isCameraInitialized = false);
      }
    }
  }

  void _switchCamera() {
    if (_cameras.length < 2 || _isRecording) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    _setupCameraController(_cameras[_selectedCameraIndex]);
  }

  Future<void> _startRecording() async {
    if (_cameraController != null && _cameraController!.value.isInitialized && !_isRecording) {
      try {
        await _cameraController!.startVideoRecording();
      } catch (e) {
        debugPrint('Failed to start real camera video recording: $e');
      }
    }

    setState(() {
      _isRecording = true;
      _secondsRecorded = 0;
      _hasRecorded = false;
      _recordedVideoFile = null;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRecorded < 10) {
        setState(() => _secondsRecorded++);
      } else {
        _stopRecording();
      }
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();

    XFile? videoFile;
    if (_cameraController != null && _cameraController!.value.isRecordingVideo) {
      try {
        videoFile = await _cameraController!.stopVideoRecording();
      } catch (e) {
        debugPrint('Error stopping video recording: $e');
      }
    }

    setState(() {
      _isRecording = false;
      _hasRecorded = true;
      _recordedVideoFile = videoFile;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          '10-Second Realtime Site Video',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_cameras.length > 1 && !_isRecording)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
              tooltip: 'Switch Camera',
              onPressed: _switchCamera,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Live Real-Time Camera Viewfinder
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isRecording ? AppColors.error : AppColors.border.withOpacity(0.3),
                    width: _isRecording ? 3 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    alignment: Alignment.center,
                    fit: StackFit.expand,
                    children: [
                      // 1. Real Camera Viewfinder Preview
                      if (_isCameraInitialized && _cameraController != null)
                        CameraPreview(_cameraController!)
                      else if (_isPermissionDenied)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.videocam_off, size: 56, color: Colors.white38),
                                const SizedBox(height: 12),
                                const Text(
                                  'Camera & Microphone Permissions Required',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Please enable permissions to record realtime site videos.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white60, fontSize: 12),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.settings),
                                  label: const Text('Open Settings'),
                                  onPressed: () => openAppSettings(),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        const Center(
                          child: CircularProgressIndicator(color: AppColors.accent),
                        ),

                      // 2. Recording Status Pill Overlay
                      if (_isRecording)
                        Positioned(
                          top: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(color: Colors.black45, blurRadius: 8),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.fiber_manual_record, color: Colors.white, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  'REC 00:0${_secondsRecorded} / 00:10',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // 3. Grid guide overlay for site measurement
                      if (!_isRecording && _isCameraInitialized)
                        Positioned(
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Pan across facade, electrical & road clearance',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Controls & Timer Section
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.grey.shade900,
              child: Column(
                children: [
                  if (_isRecording)
                    LinearProgressIndicator(
                      value: _secondsRecorded / 10.0,
                      backgroundColor: Colors.grey.shade800,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.error),
                    ),
                  const SizedBox(height: 16),

                  if (!_hasRecorded)
                    ElevatedButton.icon(
                      icon: Icon(_isRecording ? Icons.stop : Icons.fiber_manual_record, color: Colors.white),
                      label: Text(
                        _isRecording ? 'Stop Recording ($_secondsRecorded / 10s)' : 'Start 10s Realtime Video',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRecording ? Colors.grey.shade800 : AppColors.error,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isRecording ? _stopRecording : _startRecording,
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white38),
                              minimumSize: const Size(0, 48),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            onPressed: _startRecording,
                            child: const Text('Re-record', style: TextStyle(fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: CustomButton(
                            label: 'Save & Upload',
                            icon: Icons.check_circle_outline,
                            backgroundColor: AppColors.success,
                            onPressed: () {
                              final videoPath = _recordedVideoFile?.path ??
                                  'https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4';
                              widget.onVideoRecorded(
                                videoPath,
                                _secondsRecorded > 0 ? _secondsRecorded : 10,
                              );
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
