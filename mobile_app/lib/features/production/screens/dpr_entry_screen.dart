import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/custom_button.dart';

class DprEntryScreen extends StatefulWidget {
  const DprEntryScreen({Key? key}) : super(key: key);

  @override
  State<DprEntryScreen> createState() => _DprEntryScreenState();
}

class _DprEntryScreenState extends State<DprEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedMachine = 'Roland TrueVIS SG2-640 (Eco-Solvent)';
  String _selectedMaterial = 'Avery Dennison Gloss Vinyl';
  final TextEditingController _printedSqFtController = TextEditingController(text: '150');
  final TextEditingController _wasteSqFtController = TextEditingController(text: '4');
  final TextEditingController _remarksController = TextEditingController();
  bool _isSaving = false;

  final List<String> _machineOptions = [
    'Roland TrueVIS SG2-640 (Eco-Solvent)',
    'Apex UV Flatbed 2513 (UV Direct)',
    'StarFire 3200 Solvent (Outdoor Flex)',
    'Omni CNC Router 1325 (3D Letters)',
  ];

  double get printedSqFt => double.tryParse(_printedSqFtController.text) ?? 0.0;
  double get wasteSqFt => double.tryParse(_wasteSqFtController.text) ?? 0.0;
  double get wastePercent => printedSqFt > 0 ? (wasteSqFt / printedSqFt) * 100 : 0.0;
  int get estimatedPoints => (printedSqFt / 100).floor() * 50 + (wastePercent < 2 && printedSqFt >= 50 ? 100 : 0);

  Future<void> _submitDpr() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final payload = {
      'machineId': 'mock-machine-101',
      'printedSqFt': printedSqFt,
      'materialUsed': _selectedMaterial,
      'wasteSqFt': wasteSqFt,
      'remarks': _remarksController.text,
    };

    final response = await ApiClient.post('/dpr', payload);
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 DPR Recorded! +$estimatedPoints Gamification Points awarded!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New DPR Production Entry'),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: SafeArea(
          child: CustomButton(
            label: 'Submit Daily Production Report',
            icon: Icons.check,
            isLoading: _isSaving,
            onPressed: _submitDpr,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Machine Selector
              DropdownButtonFormField<String>(
                value: _selectedMachine,
                decoration: const InputDecoration(labelText: 'Production Machine / CNC Router', prefixIcon: Icon(Icons.print)),
                items: _machineOptions.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedMachine = val);
                },
              ),
              const SizedBox(height: 14),

              // Material Selector
              DropdownButtonFormField<String>(
                value: AppConstants.materialTypes.contains(_selectedMaterial) ? _selectedMaterial : AppConstants.materialTypes.first,
                decoration: const InputDecoration(labelText: 'Material Consumed', prefixIcon: Icon(Icons.layers)),
                items: AppConstants.materialTypes.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedMaterial = val);
                },
              ),
              const SizedBox(height: 14),

              // Printed Sq.Ft & Waste Sq.Ft
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _printedSqFtController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Printed Sq.Ft', suffixText: 'Sq.Ft'),
                      onChanged: (val) => setState(() {}),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _wasteSqFtController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Waste Sq.Ft', suffixText: 'Sq.Ft'),
                      onChanged: (val) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Live Production & Gamification Points Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Waste Percentage:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        Text(
                          '${wastePercent.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: wastePercent < 3 ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Estimated Reward Points:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        Text(
                          '+$estimatedPoints Points',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _remarksController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Production Notes / Batch Code',
                  hintText: 'e.g. Roland head cleaned, high print density mode',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
