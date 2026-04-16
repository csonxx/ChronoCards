import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/world_position.dart';

/// World location marker widget
class WorldLocationMarker extends StatefulWidget {
  final WorldLocation location;
  final VoidCallback onTap;

  const WorldLocationMarker({
    super.key,
    required this.location,
    required this.onTap,
  });

  @override
  State<WorldLocationMarker> createState() => _WorldLocationMarkerState();
}

class _WorldLocationMarkerState extends State<WorldLocationMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = !widget.location.isUnlocked;
    final isCompleted = widget.location.isCompleted;
    
    // P0 Fix: Completed locations don't pulse, show as explored
    // Non-interactive states don't need animation
    final shouldAnimate = !isLocked && !isCompleted;

    return GestureDetector(
      onTapDown: shouldAnimate ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: shouldAnimate ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: shouldAnimate ? () => setState(() => _isPressed = false) : null,
      onTap: widget.onTap,
      child: shouldAnimate
          ? AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isPressed ? 0.9 : _scaleAnimation.value,
                  child: child,
                );
              },
              child: _buildMarkerContent(isLocked, isCompleted),
            )
          : _buildMarkerContent(isLocked, isCompleted),
    );
  }

  Widget _buildMarkerContent(bool isLocked, bool isCompleted) {
    return Container(
      width: 60,
      height: 70,
      decoration: BoxDecoration(
        color: isLocked
            ? AppTheme.cardBackground.withOpacity(0.5)
            : isCompleted
                ? Colors.green.withOpacity(0.15)  // P0 Fix: Completed locations have green tint
                : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLocked
              ? AppTheme.cardBorder.withOpacity(0.5)
              : isCompleted
                  ? Colors.green.withOpacity(0.6)  // P0 Fix: Green border for completed
                  : _getMarkerColor(),
          width: 2,
        ),
        boxShadow: isLocked || isCompleted
            ? null  // P0 Fix: No glow for locked or completed
            : [
                BoxShadow(
                  color: _getMarkerColor().withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // P0 Fix: Different icon for completed locations
          Icon(
            isCompleted 
                ? Icons.explore  // Explored icon instead of original
                : _getLocationIcon(),
            color: isLocked
                ? AppTheme.textSecondary.withOpacity(0.5)
                : isCompleted
                    ? Colors.green.withOpacity(0.7)
                    : _getMarkerColor(),
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            widget.location.name.split(' ').first,
            style: TextStyle(
              color: isLocked
                  ? AppTheme.textSecondary.withOpacity(0.5)
                  : isCompleted
                      ? Colors.green.withOpacity(0.8)
                      : AppTheme.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (isCompleted)
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 12,
            ),
        ],
      ),
    );
  }

  Color _getMarkerColor() {
    switch (widget.location.type) {
      case WorldLocationType.town:
        return AppTheme.manaBlue;
      case WorldLocationType.dungeon:
        return AppTheme.accentCosmic;
      case WorldLocationType.battle:
        return AppTheme.healthRed;
      case WorldLocationType.cardShop:
        return AppTheme.textGold;
      case WorldLocationType.event:
        return AppTheme.accentMystic;
      case WorldLocationType.boss:
        return AppTheme.accentGold;
    }
  }

  IconData _getLocationIcon() {
    switch (widget.location.type) {
      case WorldLocationType.town:
        return Icons.home;
      case WorldLocationType.dungeon:
        return Icons.castle;
      case WorldLocationType.battle:
        return Icons.sports_kabaddi;
      case WorldLocationType.cardShop:
        return Icons.style;
      case WorldLocationType.event:
        return Icons.celebration;
      case WorldLocationType.boss:
        return Icons.whatshot;
    }
  }
}
