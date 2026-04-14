import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

/// Landscape lock overlay - prompts user to rotate device
class LandscapeLockOverlay extends StatefulWidget {
  final Widget child;

  const LandscapeLockOverlay({
    super.key,
    required this.child,
  });

  @override
  State<LandscapeLockOverlay> createState() => _LandscapeLockOverlayState();
}

class _LandscapeLockOverlayState extends State<LandscapeLockOverlay>
    with WidgetsBindingObserver {
  bool _showPortraitWarning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkOrientation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _checkOrientation() {
    final orientation = MediaQuery.of(context).orientation;
    setState(() {
      _showPortraitWarning = orientation == Orientation.portrait;
    });
  }

  @override
  void didChangeMetrics() {
    _checkOrientation();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showPortraitWarning) _buildRotatePrompt(),
      ],
    );
  }

  Widget _buildRotatePrompt() {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildRotateIcon(),
            const SizedBox(height: 32),
            const Text(
              '🔄 Please Rotate Your Device',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This game is best played in landscape mode.\nPlease rotate your device to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone_android, color: Colors.white38, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Tip: Enable rotation lock in your device settings',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRotateIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(seconds: 2),
      builder: (context, value, child) {
        return Transform.rotate(
          angle: sin(value * pi * 2) * 0.3,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.accentGold.withOpacity(0.5),
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.screen_rotation,
              size: 64,
              color: AppTheme.accentGold,
            ),
          ),
        );
      },
    );
  }
}

/// Helper to force landscape orientation for the game
class ForceLandscape extends StatelessWidget {
  final Widget child;

  const ForceLandscape({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LandscapeLockOverlay(
      child: child,
    );
  }
}
