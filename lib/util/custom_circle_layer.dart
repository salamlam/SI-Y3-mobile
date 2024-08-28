import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/map/state.dart';
import 'package:latlong2/latlong.dart' hide Path;

class CustomCircleMarker {
  final Key? key;
  final LatLng point;
  final double radius;
  final Color color;
  final double borderStrokeWidth;
  final Color borderColor;
  final bool useRadiusInMeter;
  Offset offset = Offset.zero;
  double realRadius = 0;
  final String title;
  CustomCircleMarker(
    this.title, {
    required this.point,
    required this.radius,
    this.key,
    this.useRadiusInMeter = false,
    this.color = const Color(0xFF00FF00),
    this.borderStrokeWidth = 0.0,
    this.borderColor = const Color(0xFFFFFF00),
  });
}

class CustomCircleLayer extends StatelessWidget {
  final List<CustomCircleMarker> circles;
  const CustomCircleLayer({
    super.key,
    this.circles = const [],
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints bc) {
        final size = Size(bc.maxWidth, bc.maxHeight);
        final map = FlutterMapState.of(context);
        final circleWidgets = <Widget>[];
        for (final circle in circles) {
          circle.offset = map.getOffsetFromOrigin(circle.point);

          final r = const Distance().offset(circle.point, circle.radius, 180);
          final delta = circle.offset - map.getOffsetFromOrigin(r);
          circle.realRadius = delta.distance;

          circleWidgets.add(
            Stack(
              children: [
                CustomPaint(
                  key: circle.key,
                  painter: CustomCirclePainter(circle),
                  size: size,
                  //child: Center(child: Text(circle.title)),
                ),
                Positioned(
                  left: circle.offset.dx - 30, // Ajusta según sea necesario
                  top: circle.offset.dy - 10, // Ajusta según sea necesario
                  child: Text(circle.title),
                )
              ],
            ),
          );
        }

        return Stack(
          children: circleWidgets,
        );
      },
    );
  }
}

class CustomCirclePainter extends CustomPainter {
  final CustomCircleMarker circle;
  CustomCirclePainter(this.circle);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.clipRect(rect);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = circle.color;

    _paintCircle(canvas, circle.offset, circle.useRadiusInMeter ? circle.realRadius : circle.radius, paint);

    if (circle.borderStrokeWidth > 0) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..color = circle.borderColor
        ..strokeWidth = circle.borderStrokeWidth;

      _paintCircle(canvas, circle.offset, circle.useRadiusInMeter ? circle.realRadius : circle.radius, paint);
    }
  }

  void _paintCircle(Canvas canvas, Offset offset, double radius, Paint paint) {
    canvas.drawCircle(offset, radius, paint);
  }

  @override
  bool shouldRepaint(CustomCirclePainter oldDelegate) => false;
}
