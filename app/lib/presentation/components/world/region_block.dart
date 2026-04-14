import 'package:flutter/material.dart';
import '../../../domain/entities/world_region.dart';

/// Custom painter for drawing region color blocks on the world map
class RegionBlocksPainter extends CustomPainter {
  final List<WorldRegion> regions;
  final String currentRegionId;

  RegionBlocksPainter({
    required this.regions,
    required this.currentRegionId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final region in regions) {
      _drawRegionBlock(canvas, size, region);
    }

    // Draw region labels
    _drawRegionLabels(canvas, size);
  }

  void _drawRegionBlock(Canvas canvas, Size size, WorldRegion region) {
    final rect = _getRegionRect(region, size);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));

    // Fill color
    final fillPaint = Paint()
      ..color = region.color.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, fillPaint);

    // Border
    final isCurrentRegion = region.id == currentRegionId;
    final borderPaint = Paint()
      ..color = isCurrentRegion
          ? AppTheme.accentGold
          : region.color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isCurrentRegion ? 3 : 2;
    canvas.drawRRect(rrect, borderPaint);

    // Current region glow effect
    if (isCurrentRegion) {
      final glowPaint = Paint()
        ..color = AppTheme.accentGold.withOpacity(0.15)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawRRect(rrect, glowPaint);
    }

    // Region name watermark
    final textPainter = TextPainter(
      text: TextSpan(
        text: region.displayName,
        style: TextStyle(
          color: region.color.withOpacity(0.15),
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final textOffset = Offset(
      rect.left + (rect.width - textPainter.width) / 2,
      rect.top + (rect.height - textPainter.height) / 2,
    );
    textPainter.paint(canvas, textOffset);
  }

  Rect _getRegionRect(WorldRegion region, Size size) {
    // Normalize coordinates (0-1 range) to actual size
    final x = region.mapBounds['left']! * size.width;
    final y = region.mapBounds['top']! * size.height;
    final w = (region.mapBounds['right']! - region.mapBounds['left']!) * size.width;
    final h = (region.mapBounds['bottom']! - region.mapBounds['top']!) * size.height;
    return Rect.fromLTWH(x, y, w, h);
  }

  void _drawRegionLabels(Canvas canvas, Size size) {
    for (final region in regions) {
      final rect = _getRegionRect(region, size);
      final labelOffset = Offset(
        rect.left + 16,
        rect.top + 16,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: region.displayName,
          style: const TextStyle(
            color: AppTheme.textGold,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black,
                offset: Offset(1, 1),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.paint(canvas, labelOffset);
    }
  }

  @override
  bool shouldRepaint(covariant RegionBlocksPainter oldDelegate) {
    return oldDelegate.regions != regions ||
        oldDelegate.currentRegionId != currentRegionId;
  }
}

/// Helper to get region color by name
Color getRegionColor(String regionName) {
  switch (regionName.toLowerCase()) {
    case 'mingjiao':
    case '明教':
      return const Color(0xFFFF6B35); // Orange-red
    case 'shaolin':
    case '少林':
      return const Color(0xFFFFD700); // Gold
    case 'wudang':
    case '武当':
      return const Color(0xFF4ECDC4); // Teal
    case 'biaoju':
    case '镖局':
      return const Color(0xFF8B4513); // Brown
    case 'gaibang':
    case '丐帮':
      return const Color(0xFF9ACD32); // Yellow-green
    case 'yewai':
    case '野外':
      return const Color(0xFF228B22); // Forest green
    default:
      return const Color(0xFF666666); // Gray
  }
}

// Re-export theme colors
class AppTheme {
  static const Color accentGold = Color(0xFFFFD700);
  static const Color textGold = Color(0xFFFFD700);
  static const Color cardBorder = Color(0xFF393E46);
}
