import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Interaction button (E key style) for mobile
class InteractionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final bool isAvailable;

  const InteractionButton({
    super.key,
    required this.onPressed,
    this.label = 'E',
    this.isAvailable = true,
  });

  @override
  State<InteractionButton> createState() => _InteractionButtonState();
}

class _InteractionButtonState extends State<InteractionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
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
    return GestureDetector(
      onTapDown: widget.isAvailable ? (_) => _onTapDown() : null,
      onTapUp: widget.isAvailable ? (_) => _onTapUp() : null,
      onTapCancel: widget.isAvailable ? _onTapCancel : null,
      onTap: widget.isAvailable ? widget.onPressed : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: widget.isAvailable
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.accentGold,
                      AppTheme.accentCosmic,
                    ],
                  )
                : null,
            color: widget.isAvailable ? null : AppTheme.cardBorder,
            boxShadow: widget.isAvailable
                ? [
                    BoxShadow(
                      color: AppTheme.accentGold.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
            border: Border.all(
              color: widget.isAvailable
                  ? Colors.white.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isAvailable
                      ? AppTheme.primaryDark
                      : AppTheme.textSecondary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  shadows: widget.isAvailable
                      ? [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ]
                      : null,
                ),
              ),
              if (widget.isAvailable)
                Text(
                  'TAP',
                  style: TextStyle(
                    color: AppTheme.primaryDark.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTapDown() {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }
}
