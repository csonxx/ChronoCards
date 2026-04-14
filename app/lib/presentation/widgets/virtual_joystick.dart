import 'dart:math';
import 'package:flutter/material.dart';

/// Virtual joystick widget for mobile character movement control
class VirtualJoystick extends StatefulWidget {
  final ValueChanged<Offset> onDirectionChanged;
  final VoidCallback? onReleased;

  const VirtualJoystick({
    super.key,
    required this.onDirectionChanged,
    this.onReleased,
  });

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  Offset _knobPosition = Offset.zero;
  Offset _basePosition = Offset.zero;
  bool _isDragging = false;

  static const double _baseRadius = 50.0;
  static const double _knobRadius = 20.0;
  static const double _maxDistance = 35.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: SizedBox(
        width: _baseRadius * 2,
        height: _baseRadius * 2,
        child: CustomPaint(
          painter: JoystickPainter(
            knobPosition: _knobPosition,
            isActive: _isDragging,
          ),
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _basePosition = details.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final center = Offset(_baseRadius, _baseRadius);
    final rawOffset = details.localPosition - center;
    final distance = rawOffset.distance;

    setState(() {
      if (distance <= _maxDistance) {
        _knobPosition = rawOffset;
      } else {
        _knobPosition = rawOffset / distance * _maxDistance;
      }
    });

    // Normalize direction to -1.0 to 1.0
    final normalizedX = (_knobPosition.dx / _maxDistance).clamp(-1.0, 1.0);
    final normalizedY = (_knobPosition.dy / _maxDistance).clamp(-1.0, 1.0);
    widget.onDirectionChanged(Offset(normalizedX, normalizedY));
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _knobPosition = Offset.zero;
    });
    widget.onReleased?.call();
  }
}

class JoystickPainter extends CustomPainter {
  final Offset knobPosition;
  final bool isActive;

  JoystickPainter({
    required this.knobPosition,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const baseRadius = 50.0;
    const knobRadius = 20.0;

    // Draw base circle
    final basePaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final baseBorderPaint = Paint()
      ..color = Colors.white.withOpacity(isActive ? 0.5 : 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, baseRadius, basePaint);
    canvas.drawCircle(center, baseRadius, baseBorderPaint);

    // Draw direction indicators
    final indicatorPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(center.dx - 30, center.dy),
      Offset(center.dx + 30, center.dy),
      indicatorPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 30),
      Offset(center.dx, center.dy + 30),
      indicatorPaint,
    );

    // Draw knob
    final knobPaint = Paint()
      ..color = isActive ? Colors.white.withOpacity(0.8) : Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final knobShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final knobCenter = center + knobPosition;
    canvas.drawCircle(knobCenter + const Offset(2, 2), knobRadius, knobShadowPaint);
    canvas.drawCircle(knobCenter, knobRadius, knobPaint);

    // Inner knob highlight
    final innerKnobPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(knobCenter - const Offset(5, 5), 6, innerKnobPaint);
  }

  @override
  bool shouldRepaint(covariant JoystickPainter oldDelegate) {
    return oldDelegate.knobPosition != knobPosition ||
           oldDelegate.isActive != isActive;
  }
}
