import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/measurement_calculator.dart';
import '../../../core/widgets/custom_button.dart';

class BoardMeasurementItem {
  String boardName;
  double lengthFeet;
  double heightFeet;
  String materialType;
  String pipeGauge;
  String framingType;
  String notes;

  BoardMeasurementItem({
    required this.boardName,
    this.lengthFeet = 0.0,
    this.heightFeet = 0.0,
    this.materialType = 'ACP Sheet',
    this.pipeGauge = '1" x 1" (18 Gauge)',
    this.framingType = 'MS Structure Frame',
    this.notes = '',
  });

  double get squareFeet => MeasurementCalculator.calculate(lengthFeet, heightFeet).squareFeet;
  double get squareMeters => MeasurementCalculator.calculate(lengthFeet, heightFeet).squareMeters;
}

class SmartMeasurementScreen extends StatefulWidget {
  final List<BoardMeasurementItem>? initialBoards;
  final Function(List<BoardMeasurementItem>) onSave;

  const SmartMeasurementScreen({
    Key? key,
    this.initialBoards,
    required this.onSave,
  }) : super(key: key);

  @override
  State<SmartMeasurementScreen> createState() => _SmartMeasurementScreenState();
}

class _SmartMeasurementScreenState extends State<SmartMeasurementScreen> {
  late List<BoardMeasurementItem> _boards;

  @override
  void initState() {
    super.initState();
    if (widget.initialBoards != null && widget.initialBoards!.isNotEmpty) {
      _boards = widget.initialBoards!;
    } else {
      _boards = [
        BoardMeasurementItem(boardName: 'Board 1: Main Facade LED Board', lengthFeet: 15.0, heightFeet: 4.0),
      ];
    }
  }

  double get totalSqFt => _boards.fold(0.0, (sum, b) => sum + b.squareFeet);
  double get totalSqM => _boards.fold(0.0, (sum, b) => sum + b.squareMeters);

  void _addNewBoard() {
    setState(() {
      _boards.add(
        BoardMeasurementItem(
          boardName: 'Board ${_boards.length + 1}: Section Sign',
          lengthFeet: 0.0,
          heightFeet: 0.0,
        ),
      );
    });
  }

  void _removeBoard(int index) {
    if (_boards.length > 1) {
      setState(() {
        _boards.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Measurement Calculator'),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Total Area Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL AREA:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${totalSqFt.toStringAsFixed(2)} Sq.Ft',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary),
                      ),
                      Text(
                        '(${totalSqM.toStringAsFixed(3)} Sq.Meters)',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomButton(
                label: 'Save ${_boards.length} Board Measurements',
                icon: Icons.check,
                onPressed: () {
                  widget.onSave(_boards);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informational Formula Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppColors.accent, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Auto-Calculates: Sq.Ft = Length × Height\nSq.Meter = Sq.Ft × 0.092903',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Boards list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _boards.length,
              itemBuilder: (context, index) {
                return _buildBoardCard(index);
              },
            ),
            const SizedBox(height: 12),

            // Add Another Section Button
            OutlinedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Another Board / Section'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                minimumSize: const Size(double.infinity, 46),
              ),
              onPressed: _addNewBoard,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardCard(int index) {
    final board = _boards[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: board.boardName,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      labelText: 'Board / Section Name',
                    ),
                    onChanged: (val) => board.boardName = val,
                  ),
                ),
                if (_boards.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: () => _removeBoard(index),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Dimensions Row (Length x Height)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: board.lengthFeet > 0 ? board.lengthFeet.toString() : '',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Length (ft)',
                      suffixText: 'ft',
                    ),
                    onChanged: (val) {
                      setState(() {
                        board.lengthFeet = double.tryParse(val) ?? 0.0;
                      });
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('×', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                ),
                Expanded(
                  child: TextFormField(
                    initialValue: board.heightFeet > 0 ? board.heightFeet.toString() : '',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Height (ft)',
                      suffixText: 'ft',
                    ),
                    onChanged: (val) {
                      setState(() {
                        board.heightFeet = double.tryParse(val) ?? 0.0;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Real-Time Calculation Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Area Result:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  Text(
                    '${board.squareFeet.toStringAsFixed(2)} Sq.Ft  |  ${board.squareMeters.toStringAsFixed(3)} Sq.M',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Material Selection Dropdown
            DropdownButtonFormField<String>(
              value: AppConstants.materialTypes.contains(board.materialType) ? board.materialType : AppConstants.materialTypes.first,
              decoration: const InputDecoration(labelText: 'Material Specification'),
              items: AppConstants.materialTypes.map((m) {
                return DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => board.materialType = val);
              },
            ),
            const SizedBox(height: 12),

            // MS Pipe Gauge Selection
            DropdownButtonFormField<String>(
              value: AppConstants.pipeGauges.contains(board.pipeGauge) ? board.pipeGauge : AppConstants.pipeGauges.first,
              decoration: const InputDecoration(labelText: 'MS Pipe Structure Gauge'),
              items: AppConstants.pipeGauges.map((p) {
                return DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13)));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => board.pipeGauge = val);
              },
            ),
          ],
        ),
      ),
    );
  }
}
