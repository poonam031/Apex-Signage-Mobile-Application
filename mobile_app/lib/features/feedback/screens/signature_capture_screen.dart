import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/custom_button.dart';

class SignatureCaptureScreen extends StatefulWidget {
  final String jobCode;
  final String customerName;
  final Function(String sigBase64, int starRating, String comment)? onSaved;

  const SignatureCaptureScreen({
    Key? key,
    required this.jobCode,
    required this.customerName,
    this.onSaved,
  }) : super(key: key);

  @override
  State<SignatureCaptureScreen> createState() => _SignatureCaptureScreenState();
}

class _SignatureCaptureScreenState extends State<SignatureCaptureScreen> {
  late SignatureController _signatureController;
  int _starRating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: AppColors.primary,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _signatureController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitSignature() async {
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please ask customer to sign before submitting')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final signatureBytes = await _signatureController.toPngBytes();
    final signatureBase64 = signatureBytes != null ? base64Encode(signatureBytes) : '';

    // Invoke callback or API
    if (widget.onSaved != null) {
      widget.onSaved!(signatureBase64, _starRating, _commentController.text);
    }

    setState(() => _isSaving = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Digital Sign-Off'),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: SafeArea(
          child: CustomButton(
            label: 'Submit Customer Sign-off',
            icon: Icons.verified,
            isLoading: _isSaving,
            backgroundColor: Colors.teal.shade700,
            onPressed: _submitSignature,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sign-off Information Banner
            Card(
              margin: EdgeInsets.zero,
              color: Colors.teal.shade50,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Job Delivery Sign-Off: ${widget.jobCode}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.teal),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Client: ${widget.customerName}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'I confirm that the signage board has been installed, powered on, and delivered in perfect condition.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 1-5 Star Customer Rating
            const Text(
              '1. Customer Star Rating:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starNum = index + 1;
                return IconButton(
                  iconSize: 38,
                  icon: Icon(
                    starNum <= _starRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () => setState(() => _starRating = starNum),
                );
              }),
            ),
            Center(
              child: Text(
                '$_starRating.0 Stars (${_getRatingLabel(_starRating)})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 20),

            // Digital Signature Canvas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '2. Customer Digital Signature:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Clear'),
                  onPressed: () => _signatureController.clear(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Signature(
                  controller: _signatureController,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sign above using your finger or stylus',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: 18),

            // Optional Feedback comments
            TextFormField(
              controller: _commentController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Customer Feedback Comments (Optional)',
                hintText: 'e.g. Excellent finishing, very satisfied with the LED glow',
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  String _getRatingLabel(int stars) {
    switch (stars) {
      case 5:
        return 'Outstanding / Perfect';
      case 4:
        return 'Very Good';
      case 3:
        return 'Satisfactory';
      case 2:
        return 'Needs Improvement';
      default:
        return 'Poor';
    }
  }
}
