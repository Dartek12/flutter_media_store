import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_media_store/media_store.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class DrawingPage extends StatefulWidget {
  const DrawingPage({Key? key}) : super(key: key);

  @override
  _DrawingPageState createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _DrawingCanvas(),
      ),
    );
  }
}

class _DrawingCanvas extends StatefulWidget {
  _DrawingCanvas({Key? key}) : super(key: key);

  @override
  __DrawingCanvasState createState() => __DrawingCanvasState();
}

class __DrawingCanvasState extends State<_DrawingCanvas> {
  GlobalKey _containerKey = GlobalKey();
  Color _color = Colors.black;
  final Paint _paint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 10.0;
  List<_ColoredPath> _paths = [];
  _ColoredPath? _currentPath;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          color: Theme.of(context).canvasColor,
          child: Row(
            children: [
              OutlinedButtonTheme(
                  data: OutlinedButtonThemeData(
                      style: ButtonStyle(
                    foregroundColor: MaterialStateColor.resolveWith((states) => _color),
                    overlayColor: MaterialStateColor.resolveWith((states) => _color.withAlpha(25)),
                  )),
                  child: OutlinedButton.icon(
                      onPressed: _pickColor, icon: Icon(Icons.color_lens), label: Text('Pick a color'))),
              Spacer(),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _paths = [];
                    _currentPath = null;
                  });
                },
                child: Text('Clear'),
              ),
              const SizedBox(
                width: 8,
              ),
              OutlinedButton(onPressed: _saveImage, child: Icon(Icons.save)),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: Colors.white,
            key: _containerKey,
            child: CustomPaint(
              isComplex: true,
              foregroundPainter: _Drawer(_paths, _paint),
              child: GestureDetector(
                onPanDown: (details) {
                  final newPath =
                      _ColoredPath(_color, Path()..moveTo(details.localPosition.dx, details.localPosition.dy));
                  _currentPath = newPath;
                  setState(() {
                    _paths.add(newPath);
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    _currentPath!.path.relativeLineTo(details.delta.dx, details.delta.dy);
                  });
                },
                onPanCancel: () {
                  _currentPath = null;
                },
                onPanEnd: (details) {
                  _currentPath = null;
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _saveImage() async {
    File tempFile = await _saveCanvasToTemporaryFile();
    await _saveFileToMediaStore(tempFile);
    await tempFile.delete();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File saved!')));
  }

  Future<File> _saveCanvasToTemporaryFile() async {
    final recorder = PictureRecorder();
    final RenderBox box = _containerKey.currentContext!.findRenderObject() as RenderBox;
    final size = box.size;
    final rect = Rect.fromLTRB(0, 0, size.width, size.height);
    final canvas = Canvas(recorder, rect);
    canvas.drawRect(rect, Paint()..color = Colors.white);
    _drawOnCanvas(canvas, size: size, paint: _paint, paths: _paths);
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final bytes = await image.toByteData(format: ImageByteFormat.png);

    final identifier = Uuid().v4();
    final fileName = '$identifier.png';
    final directory = await path_provider.getTemporaryDirectory();
    final filePath = path.join(directory.path, fileName);
    return await File(filePath).writeAsBytes(bytes!.buffer.asUint8List());
  }

  Future<void> _saveFileToMediaStore(File file) async {
    final mediaStore = MediaStore();
    await mediaStore.addItem(file: file, name: 'Drawing.png');
  }

  void _pickColor() async {
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              content: SingleChildScrollView(
                child: ColorPicker(
                    pickerColor: _color,
                    onColorChanged: (color) {
                      setState(() {
                        _color = color;
                      });
                    }),
              ),
              actions: [
                OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK'))
              ],
            ));
  }
}

class _Drawer extends CustomPainter {
  final List<_ColoredPath> _paths;
  final Paint _paint;

  _Drawer(this._paths, this._paint);

  @override
  void paint(Canvas canvas, Size size) {
    _drawOnCanvas(canvas, size: size, paint: _paint, paths: _paths);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ColoredPath {
  final Color color;
  final Path path;

  const _ColoredPath(this.color, this.path);
}

void _drawOnCanvas(Canvas canvas, {required Size size, required Paint paint, required List<_ColoredPath> paths}) {
  for (final path in paths) {
    paint.color = path.color;
    canvas.drawPath(path.path, paint);
  }
}
