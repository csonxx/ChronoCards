import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/world_region.dart';
import '../../../domain/entities/world_location.dart';
import '../../../domain/entities/world_connection.dart';
import 'region_block.dart';
import 'location_marker_widget.dart';
import 'connection_line_painter.dart';

/// Main world map view widget
/// Renders: region color blocks + location markers + connection lines
class WorldMapView extends StatefulWidget {
  final List<WorldRegion> regions;
  final List<WorldLocation> locations;
  final List<WorldConnection> connections;
  final String? currentLocationId;
  final String currentPlayerRegionId;
  final ValueChanged<WorldLocation> onLocationTap;
  final ValueChanged<String> onNavigate;

  const WorldMapView({
    super.key,
    required this.regions,
    required this.locations,
    required this.connections,
    this.currentLocationId,
    required this.currentPlayerRegionId,
    required this.onLocationTap,
    required this.onNavigate,
  });

  @override
  State<WorldMapView> createState() => _WorldMapViewState();
}

class _WorldMapViewState extends State<WorldMapView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  String? _hoveredLocationId;
  String? _hoveredConnectionId;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Map background
            _buildMapBackground(constraints),

            // Region blocks layer
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: RegionBlocksPainter(
                regions: widget.regions,
                currentRegionId: widget.currentPlayerRegionId,
              ),
            ),

            // Connection lines layer
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: ConnectionLinesPainter(
                connections: widget.connections,
                locations: widget.locations,
                hoveredConnectionId: _hoveredConnectionId,
                onHover: (id) => setState(() => _hoveredConnectionId = id),
              ),
            ),

            // Location markers layer
            ..._buildLocationMarkers(constraints),

            // Player position indicator (current location)
            if (widget.currentLocationId != null)
              _buildCurrentLocationIndicator(constraints),
          ],
        );
      },
    );
  }

  Widget _buildMapBackground(BoxConstraints constraints) {
    return Container(
      width: constraints.maxWidth,
      height: constraints.maxHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1A1A2E).withOpacity(1.0),
            const Color(0xFF16213E).withOpacity(1.0),
          ],
        ),
      ),
      child: CustomPaint(
        painter: WorldMapBackgroundPainter(),
      ),
    );
  }

  List<Widget> _buildLocationMarkers(BoxConstraints constraints) {
    return widget.locations.map((location) {
      // Safe lookup with null fallback
      final region = widget.regions.where((r) => r.id == location.regionId).firstOrNull;

      return Positioned(
        left: location.mapX * constraints.maxWidth - 30,
        top: location.mapY * constraints.maxHeight - 30,
        child: LocationMarkerWidget(
          location: location,
          region: region,
          isCurrentLocation: location.id == widget.currentLocationId,
          isHovered: location.id == _hoveredLocationId,
          onTap: () => widget.onLocationTap(location),
          onLongPress: () => _showLocationTooltip(context, location),
        ),
      );
    }).toList();
  }

  Widget _buildCurrentLocationIndicator(BoxConstraints constraints) {
    // Safe lookup - use firstOrNull instead of first to avoid throw
    final currentLocation = widget.locations.where((l) => l.id == widget.currentLocationId).firstOrNull;
    if (currentLocation == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Positioned(
          left: currentLocation.mapX * constraints.maxWidth - 50,
          top: currentLocation.mapY * constraints.maxHeight - 50,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.accentGold.withOpacity(0.5 + 0.5 * _pulseController.value),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentGold.withOpacity(0.3 * _pulseController.value),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLocationTooltip(BuildContext context, WorldLocation location) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final size = MediaQuery.of(context).size;

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => Stack(
        children: [
          Positioned(
            left: location.mapX * size.width - 100,
            top: location.mapY * size.height - 120,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getLocationTypeIcon(location.type),
                          color: AppTheme.textGold,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            location.name,
                            style: const TextStyle(
                              color: AppTheme.textGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: AppTheme.getDangerColor(location.dangerLevel),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Danger: ${location.dangerLevel}',
                          style: TextStyle(
                            color: AppTheme.getDangerColor(location.dangerLevel),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (location.availableDealers.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Dealers: ${location.availableDealers.join(", ")}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getLocationTypeIcon(String type) {
    switch (type) {
      case 'city':
        return Icons.location_city;
      case 'town':
        return Icons.home;
      case 'village':
        return Icons.house;
      case 'wilderness':
        return Icons.park;
      case 'dungeon':
        return Icons.castle;
      case 'inn':
        return Icons.hotel;
      case 'special':
        return Icons.star;
      default:
        return Icons.place;
    }
  }
}

/// Background decorative painter for the world map
class WorldMapBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Subtle grid lines
    paint.color = AppTheme.cardBorder.withOpacity(0.1);
    paint.strokeWidth = 1;

    const gridSize = 50.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Decorative corner elements
    _drawCornerDecoration(canvas, size, paint);
  }

  void _drawCornerDecoration(Canvas canvas, Size size, Paint paint) {
    paint.color = AppTheme.accentGold.withOpacity(0.05);

    // Top-left
    final path1 = Path()
      ..moveTo(0, 0)
      ..lineTo(80, 0)
      ..lineTo(0, 80)
      ..close();
    canvas.drawPath(path1, paint);

    // Top-right
    final path2 = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width - 80, 0)
      ..lineTo(size.width, 80)
      ..close();
    canvas.drawPath(path2, paint);

    // Bottom-left
    final path3 = Path()
      ..moveTo(0, size.height)
      ..lineTo(80, size.height)
      ..lineTo(0, size.height - 80)
      ..close();
    canvas.drawPath(path3, paint);

    // Bottom-right
    final path4 = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(size.width - 80, size.height)
      ..lineTo(size.width, size.height - 80)
      ..close();
    canvas.drawPath(path4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
