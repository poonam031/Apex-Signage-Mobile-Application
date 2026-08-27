import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';

class VideoRecordingScreen extends StatefulWidget {
  final Function(String videoUrl, int durationSeconds) onVideoRecorded;

  const VideoRecordingScreen({Key? key, required this.onVideoRecorded}) : super(key: key);

  @override
  State<VideoRecordingScreen> createState() => _VideoRecordingScreenState();
}

class _VideoRecordingScreenState extends State<VideoRecordingScreen> {
  bool _isRecording = false;
  int _secondsRemaining = 10;
  Timer? _timer;
  bool _hasRecorded = false;

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _secondsRemaining = 10;
      _hasRecorded = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        _stopRecording();
      }
    });
  }

  void _stopRecording() {
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _hasRecorded = true;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('10-Second Site Video Clip'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Video Viewport Simulator / Camera Preview
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isRecording ? AppColors.error : AppColors.border.withOpacity(0.3),
                    width: _isRecording ? 3 : 1,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _hasRecorded
                            ? Icons.check_circle
                            : (_isRecording ? Icons.videocam : Icons.videocam_outlined),
                        size: 64,
                        color: _isRecording
                            ? AppColors.error
                            : (_hasRecorded ? AppColors.success : Colors.white38),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isRecording
                            ? 'RECORDING: 00:0${10 - _secondsRemaining + 1} / 00:10'
                            : (_hasRecorded
                                ? '10-Second Site Video Recorded!'
                                : 'Press Record to capture 10s Site Overview'),
                        style: TextStyle(
                          color: _isRecording ? AppColors.error : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Shows building facade, electrical hookup & road clearance',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Controls & Timer
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.grey.shade900,
              child: Column(
                children: [
                  if (_isRecording)
                    LinearProgressIndicator(
                      value: (10 - _secondsRemaining) / 10.0,
                      backgroundColor: Colors.grey.shade800,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.error),
                    ),
                  const SizedBox(height: 16),

                  if (!_hasRecorded)
                    ElevatedButton.icon(
                      icon: Icon(_isRecording ? Icons.stop : Icons.fiber_manual_record, color: Colors.white),
                      label: Text(
                        _isRecording ? 'Stop Recording ($_secondsRemaining s)' : 'Start 10s Video Capture',
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
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white38),
                              minimumSize: const Size(0, 48),
                            ),
                            onPressed: _startRecording,
                            child: const Text('Re-record'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            label: 'Save & Upload Clip',
                            icon: Icons.cloud_upload,
                            backgroundColor: AppColors.success,
                            onPressed: () {
                              widget.onVideoRecorded(
                                'https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4',
                                10,
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
