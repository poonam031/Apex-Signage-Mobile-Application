import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';

class TechnicalChecklistData {
  String boardFloorHeight;
  double powerSupplyDistanceFeet;
  bool ladderRequired;
  bool craneRequired;
  bool scaffoldingRequired;
  String obstacles;
  String notes;

  TechnicalChecklistData({
    this.boardFloorHeight = 'Ground Floor Facade (12 ft)',
    this.powerSupplyDistanceFeet = 10.0,
    this.ladderRequired = true,
    this.craneRequired = false,
    this.scaffoldingRequired = false,
    this.obstacles = '',
    this.notes = '',
  });
}

class TechnicalChecklistScreen extends StatefulWidget {
  final TechnicalChecklistData? initialData;
  final Function(TechnicalChecklistData) onSave;

  const TechnicalChecklistScreen({
    Key? key,
    this.initialData,
    required this.onSave,
  }) : super(key: key);

  @override
  State<TechnicalChecklistScreen> createState() => _TechnicalChecklistScreenState();
}

class _TechnicalChecklistScreenState extends State<TechnicalChecklistScreen> {
  late TechnicalChecklistData _data;

  @override
  void initState() {
    super.initState();
    _data = widget.initialData ?? TechnicalChecklistData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Technical Site Checklist'),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: SafeArea(
          child: CustomButton(
            label: 'Save Technical Checklist',
            icon: Icons.check,
            onPressed: () {
              widget.onSave(_data);
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Installation & Safety Assessment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Verify structural access, power supply distance, and crane/scaffold requirements.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // Board Floor / Height
            TextFormField(
              initialValue: _data.boardFloorHeight,
              decoration: const InputDecoration(
                labelText: 'Board Floor / Mounting Height',
                prefixIcon: Icon(Icons.height),
                hintText: 'e.g. 1st Floor Facade (15 ft from ground)',
              ),
              onChanged: (val) => _data.boardFloorHeight = val,
            ),
            const SizedBox(height: 14),

            // Power Supply Distance
            TextFormField(
              initialValue: _data.powerSupplyDistanceFeet.toString(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Power Supply Distance (Feet)',
                prefixIcon: Icon(Icons.electrical_services),
                suffixText: 'ft',
                hintText: 'Distance to nearest 220V power point',
              ),
              onChanged: (val) => _data.powerSupplyDistanceFeet = double.tryParse(val) ?? 0.0,
            ),
            const SizedBox(height: 18),

            const Text(
              'Equipment & Machinery Requirements',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),

            // Checkboxes
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Ladder Required', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Standard aluminium folding ladder (up to 12ft)', style: TextStyle(fontSize: 11)),
                    value: _data.ladderRequired,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _data.ladderRequired = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Scaffolding Required', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Required for heights above 15ft or multi-day installation', style: TextStyle(fontSize: 11)),
                    value: _data.scaffoldingRequired,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _data.scaffoldingRequired = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Hydraulic Crane Required', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Required for rooftop or high-rise facade hoists', style: TextStyle(fontSize: 11)),
                    value: _data.craneRequired,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _data.craneRequired = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Obstacles & Hazard notes
            TextFormField(
              initialValue: _data.obstacles,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Site Obstacles & Physical Hazards',
                prefixIcon: Icon(Icons.report_problem_outlined),
                hintText: 'e.g. Overhanging power cables, tree branches, uneven pavement',
              ),
              onChanged: (val) => _data.obstacles = val,
            ),
            const SizedBox(height: 14),

            TextFormField(
              initialValue: _data.notes,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Additional Technical Notes',
                prefixIcon: Icon(Icons.notes),
                hintText: 'e.g. Main switch located inside basement meter room',
              ),
              onChanged: (val) => _data.notes = val,
            ),
          ],
        ),
      ),
    );
  }
}
