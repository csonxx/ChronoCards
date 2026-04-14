import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/world_location.dart';
import '../../../domain/entities/world_region.dart';

/// Location marker widget for the world map
/// Shows location icon with state: unlocked/locked/current
class LocationMarkerWidget extends StatefulWidget {
  final WorldLocation location;
  final WorldRegion? region; // nullable for safety
  final bool isCurrentLocation;
  final bool isHovered;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const LocationMarkerWidget({
    super.key,
    required this.location,
    this.region,
    this.isCurrentLocation = false,
    this.isHovered = false,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<LocationMarkerWidget> createState() => _LocationMarkerWidgetState();
}

class _LocationMarkerWidgetState extends State<LocationMarkerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _bounceAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    if (widget.isCurrentLocation) {
      _bounceController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(LocationMarkerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrentLocation && !_bounceController.isAnimating) {
      _bounceController.repeat(reverse: true);
    } else if (!widget.isCurrentLocation && _bounceController.isAnimating) {
      _bounceController.stop();
      _bounceController.reset();
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = !widget.location.isUnlocked;
    // Use region color if available, otherwise derive from location type
    final color = widget.region?.color ?? AppTheme.getLocationTypeColor(widget.location.type);

    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, widget.isCurrentLocation ? _bounceAnimation.value : 0),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: MouseRegion(
          onEnter: (_) => setState(() {}),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Location icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLocked
                        ? Colors.grey.withOpacity(0.3)
                        : color.withOpacity(0.3),
                    border: Border.all(
                      color: widget.isCurrentLocation
                          ? AppTheme.accentGold
                          : (isLocked ? Colors.grey : color),
                      width: widget.isCurrentLocation ? 3 : 2,
                    ),
                    boxShadow: [
                      if (!isLocked)
                        BoxShadow(
                          color: color.withOpacity(widget.isHovered ? 0.6 : 0.3),
                          blurRadius: widget.isHovered ? 12 : 6,
                          spreadRadius: widget.isHovered ? 2 : 0,
                        ),
                      if (widget.isCurrentLocation)
                        BoxShadow(
                          color: AppTheme.accentGold.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        _getLocationTypeIcon(widget.location.type),
                        color: isLocked ? Colors.grey : color,
                        size: 24,
                      ),
                      if (isLocked)
                        const Positioned(
                          right: 0,
                          bottom: 0,
                          child: Icon(
                            Icons.lock,
                            color: Colors.grey,
                            size: 14,
                          ),
                        ),
                      if (widget.isCurrentLocation)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.accentGold,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.black,
                              size: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Location name label
                if (!isLocked || widget.isHovered)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.location.name,
                      style: TextStyle(
                        color: isLocked ? Colors.grey : AppTheme.textGold,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getLocationTypeIcon(String type) {
    switch (type.toLowerCase()) {
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
