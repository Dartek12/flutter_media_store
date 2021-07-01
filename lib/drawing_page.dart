import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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
  Color _color = Colors.black;
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
              )
            ],
          ),
        ),
        Expanded(
          child: Container(
            child: CustomPaint(
              isComplex: true,
              foregroundPainter: _Drawer(_paths),
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
  final Paint _paint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 10.0;

  _Drawer(this._paths);

  @override
  void paint(Canvas canvas, Size size) {
    for (final path in _paths) {
      _paint.color = path.color;
      canvas.drawPath(path.path, _paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ColoredPath {
  final Color color;
  final Path path;

  const _ColoredPath(this.color, this.path);
}
