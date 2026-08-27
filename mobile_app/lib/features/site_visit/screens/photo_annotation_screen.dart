import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AnnotationPath {
  List<Offset> points;
  Color color;
  double strokeWidth;
  String? label;

  AnnotationPath({
    required this.points,
    required this.color,
    this.strokeWidth = 3.5,
    this.label,
  });
}

class PhotoAnnotationScreen extends StatefulWidget {
  final String? imagePath; // Local file path or network URL
  final String? imageUrl;
  final Function(List<AnnotationPath>, String finalImagePath) onSave;

  const PhotoAnnotationScreen({
    Key? key,
    this.imagePath,
    this.imageUrl,
    required this.onSave,
  }) : super(key: key);

  @override
  State<PhotoAnnotationScreen> createState() => _PhotoAnnotationScreenState();
}

class _PhotoAnnotationScreenState extends State<PhotoAnnotationScreen> {
  final List<AnnotationPath> _paths = [];
  Color _selectedColor = Colors.yellow;
  String _selectedTool = 'DRAW'; // DRAW, ARROW, TEXT
  final List<Color> _palette = [Colors.yellow, Colors.red, Colors.cyan, Colors.white, Colors.greenAccent];

  void _addTextCallout(Offset position) {
    final controller = TextEditingController(text: '15.0 ft Width');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Measurement Marker', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. 15.0 ft Width, Height 4ft, Power Point'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _paths.add(
                    AnnotationPath(
                      points: [position],
                      color: _selectedColor,
                      label: controller.text,
                    ),
                  );
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageBackground() {
    final path = widget.imagePath ?? widget.imageUrl;

    if (path != null && !path.startsWith('http') && File(path).existsSync()) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _buildPlaceholder(),
      );
    } else if (path != null && path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _buildPlaceholder(),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade900,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_camera_back_outlined, size: 54, color: Colors.white30),
            SizedBox(height: 10),
            Text('Site Facade Photo Canvas', style: TextStyle(color: Colors.white60, fontSize: 13)),
            SizedBox(height: 4),
            Text('Touch anywhere to draw lines or add width/height notes', style: TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activePath = widget.imagePath ?? widget.imageUrl ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Site Photo Annotation',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo, color: Colors.white),
            tooltip: 'Undo',
            onPressed: _paths.isNotEmpty
                ? () {
                    setState(() => _paths.removeLast());
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white),
            tooltip: 'Clear All',
            onPressed: () => setState(() => _paths.clear()),
          ),
          TextButton(
            onPressed: () {
              widget.onSave(_paths, activePath);
              Navigator.pop(context);
            },
            child: const Text('SAVE', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Toolbar: Tool selector and Palette
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade900,
            child: Row(
              children: [
                // Tool Buttons
                IconButton(
                  icon: Icon(Icons.gesture, color: _selectedTool == 'DRAW' ? AppColors.accent : Colors.white70),
                  onPressed: () => setState(() => _selectedTool = 'DRAW'),
                  tooltip: 'Draw Line / Dimension',
                ),
                IconButton(
                  icon: Icon(Icons.text_fields, color: _selectedTool == 'TEXT' ? AppColors.accent : Colors.white70),
                  onPressed: () => setState(() => _selectedTool = 'TEXT'),
                  tooltip: 'Add Measurement Text',
                ),
                const Spacer(),
                // Color Palette
                ..._palette.map((color) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor == color ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          // Interactive Touch Drawing Surface
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Real Camera Photo or Network Image
                    _buildImageBackground(),

                    // Touch Gesture Detector & Custom Painter
                    GestureDetector(
                      onPanStart: (details) {
                        if (_selectedTool == 'TEXT') {
                          _addTextCallout(details.localPosition);
                        } else {
                          setState(() {
                            _paths.add(
                              AnnotationPath(
                                points: [details.localPosition],
                                color: _selectedColor,
                              ),
                            );
                          });
                        }
                      },
                      onPanUpdate: (details) {
                        if (_selectedTool == 'DRAW' && _paths.isNotEmpty) {
                          setState(() {
                            _paths.last.points.add(details.localPosition);
                          });
                        }
                      },
                      child: CustomPaint(
                        painter: AnnotationPainter(paths: _paths),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tip bar at bottom
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.grey.shade900,
            child: const Row(
              children: [
                Icon(Icons.touch_app, size: 16, color: AppColors.accent),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Draw directly on photo or use 🔤 text tool to place width/height stickers.',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnnotationPainter extends CustomPainter {
  final List<AnnotationPath> paths;

  AnnotationPainter({required this.paths});

  @override
  void paint(Canvas canvas, Size size) {
    for (final item in paths) {
      if (item.label != null && item.points.isNotEmpty) {
        // Render Text Callout Bubble
        final pos = item.points.first;
        final textSpan = TextSpan(
          text: ' 📐 ${item.label!} ',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.yellow,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(pos.dx - (textPainter.width / 2), pos.dy - 10));
      } else if (item.points.length > 1) {
        // Render Stroke Line
        final paint = Paint()
          ..color = item.color
          ..strokeCap = StrokeCap.round
          ..strokeWidth = item.strokeWidth
          ..style = PaintingStyle.stroke;

        final path = Path();
        path.moveTo(item.points.first.dx, item.points.first.dy);
        for (int i = 1; i < item.points.length; i++) {
          path.lineTo(item.points[i].dx, item.points[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
