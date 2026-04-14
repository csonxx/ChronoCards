import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/world_connection.dart';
import '../../../domain/entities/world_location.dart';

/// Custom painter for drawing connection lines between locations
class ConnectionLinesPainter extends CustomPainter {
  final List<WorldConnection> connections;
  final List<WorldLocation> locations;
  final String? hoveredConnectionId;
  final ValueChanged<String?>? onHover;

  ConnectionLinesPainter({
    required this.connections,
    required this.locations,
    this.hoveredConnectionId,
    this.onHover,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final connection in connections) {
      // Safe lookup with null fallback
      final fromLocation = locations.where((l) => l.id == connection.fromLocationId).firstOrNull;
      final toLocation = locations.where((l) => l.id == connection.toLocationId).firstOrNull;
      
      // Skip if either location not found
      if (fromLocation == null || toLocation == null) continue;

      final start = Offset(
        fromLocation.mapX * size.width,
        fromLocation.mapY * size.height,
      );
      final end = Offset(
        toLocation.mapX * size.width,
        toLocation.mapY * size.height,
      );

      _drawConnection(canvas, start, end, connection);
    }
  }

  void _drawConnection(
    Canvas canvas,
    Offset start,
    Offset end,
    WorldConnection connection,
  ) {
    final isHovered = connection.id == hoveredConnectionId;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHovered ? 4 : 2
      ..strokeCap = StrokeCap.round;

    // Set color based on path type and locked status
    if (connection.isLocked) {
      paint.color = Colors.grey.withOpacity(0.4);
      paint.strokeWidth = isHovered ? 3 : 1.5;
    } else {
      switch (connection.pathType) {
        case 'road':
          paint.color = isHovered
              ? AppTheme.accentGold
              : const Color(0xFF8B7355).withOpacity(0.6);
          break;
        case 'trekking':
          paint.color = isHovered
              ? AppTheme.manaBlue
              : const Color(0xFF228B22).withOpacity(0.5);
          break;
        case 'teleport':
          paint.color = isHovered
              ? AppTheme.accentMystic
              : AppTheme.accentCosmic.withOpacity(0.6);
          paint.strokeWidth = isHovered ? 4 : 2;
          break;
        case 'story_locked':
          paint.color = AppTheme.healthRed.withOpacity(0.5);
          break;
        default:
          paint.color = Colors.grey.withOpacity(0.4);
      }
    }

    // Draw dashed line for locked paths
    if (connection.isLocked) {
      _drawDashedLine(canvas, start, end, paint);
    } else {
      canvas.drawLine(start, end, paint);
    }

    // Draw arrow or special markers for path type
    if (!connection.isLocked) {
      _drawPathMarkers(canvas, start, end, connection, isHovered);
    }

    // Hover tooltip
    if (isHovered) {
      _drawHoverInfo(canvas, start, end, connection);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 8.0;
    const dashSpace = 6.0;
    final distance = (end - start).distance;
    final direction = (end - start) / distance;

    double currentDistance = 0;
    while (currentDistance < distance) {
      final dashEnd = currentDistance + dashWidth;
      final p1 = start + direction * currentDistance;
      final p2 = start + direction * (dashEnd > distance ? distance : dashEnd);
      canvas.drawLine(p1, p2, paint);
      currentDistance += dashWidth + dashSpace;
    }
  }

  void _drawPathMarkers(
    Canvas canvas,
    Offset start,
    Offset end,
    WorldConnection connection,
    bool isHovered,
  ) {
    final midPoint = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);

    if (connection.pathType == 'teleport') {
      // Draw teleport diamond marker
      final path = Path()
        ..moveTo(midPoint.dx, midPoint.dy - 6)
        ..lineTo(midPoint.dx + 6, midPoint.dy)
        ..lineTo(midPoint.dx, midPoint.dy + 6)
        ..lineTo(midPoint.dx - 6, midPoint.dy)
        ..close();

      final paint = Paint()
        ..color = isHovered ? AppTheme.accentMystic : AppTheme.accentCosmic
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, paint);
    } else if (connection.pathType == 'trekking') {
      // Draw mountain marker
      final iconPaint = Paint()
        ..color = isHovered ? AppTheme.manaBlue : const Color(0xFF228B22)
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(midPoint.dx, midPoint.dy - 5)
        ..lineTo(midPoint.dx + 6, midPoint.dy + 4)
        ..lineTo(midPoint.dx - 6, midPoint.dy + 4)
        ..close();
      canvas.drawPath(path, iconPaint);
    }

    // Duration/time label for hovered
    if (isHovered && connection.travelTimeMinutes > 0) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${connection.travelTimeMinutes}min',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final bgRect = Rect.fromCenter(
        center: midPoint,
        width: textPainter.width + 8,
        height: textPainter.height + 4,
      );
      final bgPaint = Paint()..color = Colors.black54;
      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
        bgPaint,
      );
      textPainter.paint(
        canvas,
        Offset(midPoint.dx - textPainter.width / 2, midPoint.dy - textPainter.height / 2),
      );
    }
  }

  void _drawHoverInfo(
    Canvas canvas,
    Offset start,
    Offset end,
    WorldConnection connection,
  ) {
    final midPoint = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2 - 15);

    final texts = <String>[];
    if (connection.travelTimeMinutes > 0) {
      texts.add('Time: ${connection.travelTimeMinutes}min');
    }
    if (connection.dangerLevel > 0) {
      texts.add('Danger: ${connection.dangerLevel}');
    }
    if (connection.encounterChance > 0) {
      texts.add('Encounter: ${(connection.encounterChance * 100).toInt()}%');
    }

    if (texts.isEmpty) return;

    final textPainter = TextPainter(
      text: TextSpan(
        text: texts.join('\n'),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final bgRect = Rect.fromLTWH(
      midPoint.dx - textPainter.width / 2 - 6,
      midPoint.dy - textPainter.height / 2 - 4,
      textPainter.width + 12,
      textPainter.height + 8,
    );
    final bgPaint = Paint()..color = AppTheme.primaryDark.withOpacity(0.8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(6)),
      bgPaint,
    );

    final borderPaint = Paint()
      ..color = AppTheme.accentGold.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(6)),
      borderPaint,
    );

    textPainter.paint(
      canvas,
      Offset(midPoint.dx - textPainter.width / 2, midPoint.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant ConnectionLinesPainter oldDelegate) {
    return oldDelegate.connections != connections ||
        oldDelegate.hoveredConnectionId != hoveredConnectionId ||
        oldDelegate.locations != locations;
  }
}
