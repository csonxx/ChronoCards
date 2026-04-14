import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../domain/entities/event_card.dart';

/// Event card widget with 500ms 3D flip animation
/// Chapter 7 design: 5 card type colors, calligraphy font, type icon, description, trigger condition
class EventCardWidget extends StatefulWidget {
  final EventCard card;
  final bool isFlipped;
  final bool showOptions;
  final VoidCallback? onFlipComplete;
  final Function(String optionId)? onOptionSelected;
  final bool isSelected;

  const EventCardWidget({
    super.key,
    required this.card,
    this.isFlipped = false,
    this.showOptions = true,
    this.onFlipComplete,
    this.onOptionSelected,
    this.isSelected = false,
  });

  @override
  State<EventCardWidget> createState() => _EventCardWidgetState();
}

class _EventCardWidgetState extends State<EventCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _showFront = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    _flipController.addListener(() {
      if (_flipController.value >= 0.5 && !_showFront) {
        setState(() => _showFront = true);
      }
    });

    _flipController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFlipComplete?.call();
      }
    });

    if (widget.isFlipped) {
      _flipController.value = 1.0;
      _showFront = true;
    }
  }

  @override
  void didUpdateWidget(EventCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped && !oldWidget.isFlipped) {
      _flipController.forward();
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _triggerFlip() {
    if (!widget.isFlipped) {
      _flipController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Glow effect for selected state
        if (widget.isSelected)
          Container(
            width: 380,
            height: 560,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: widget.card.type.glowColor.withOpacity(0.6),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
          ).animate(onPlay: (c) => c.repeat()).scale(
                begin: const Offset(1, 1),
                end: const Offset(1.02, 1.02),
                duration: 750.ms,
              ).then().scale(
                begin: const Offset(1.02, 1.02),
                end: const Offset(1, 1),
                duration: 750.ms,
              ),

        GestureDetector(
          onTap: _triggerFlip,
          child: AnimatedBuilder(
            animation: _flipAnimation,
            builder: (context, child) {
              final angle = _flipAnimation.value * math.pi;
              final scale = _flipAnimation.value < 0.5
                  ? 1.0 - (_flipAnimation.value * 0.2)
                  : 0.8 + ((_flipAnimation.value - 0.5) * 0.4);

              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle)
                  ..scale(scale),
                child: _showFront ? _buildFrontCard() : _buildBackCard(),
              );
            },
          ),
        ),

        // Options after flip
        if (_showFront && widget.showOptions && !widget.card.isBlank)
          _buildOptions(),
      ],
    );
  }

  Widget _buildBackCard() {
    return Container(
      width: 340,
      height: 500,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A2A4A),
            Color(0xFF0A1A2A),
          ],
        ),
        border: Border.all(color: const Color(0xFFD4A843), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Cloud pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _CardBackPatternPainter(),
            ),
          ),
          // Center seal
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFD4A843), width: 3),
                  ),
                  child: const Center(
                    child: Text(
                      '江\n湖',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFD4A843),
                        fontSize: 28,
                        fontFamily: 'serif',
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '事件卡',
                  style: TextStyle(
                    color: Color(0xFFD4A843),
                    fontSize: 20,
                    fontFamily: 'serif',
                    letterSpacing: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildFrontCard() {
    final type = widget.card.type;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(math.pi),
      child: Container(
        width: 340,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFFF5E6C8),
          border: Border.all(color: type.primaryColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: type.glowColor.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Top bar - type corner + icon
            _buildTopBar(type),

            // Card name
            _buildCardName(),

            // Trigger condition
            if (widget.card.triggerCondition.isNotEmpty)
              _buildTriggerCondition(),

            // Description area
            Expanded(child: _buildDescription(type)),

            // Illustration area
            _buildIllustration(type),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 100.ms)
          .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
    );
  }

  Widget _buildTopBar(EventCardType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: type.primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(13),
          topRight: Radius.circular(13),
        ),
      ),
      child: Row(
        children: [
          // Type corner label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              type.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          // Type icon
          Icon(type.icon, color: Colors.white, size: 32),
        ],
      ),
    );
  }

  Widget _buildCardName() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Text(
            widget.card.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 28,
              fontFamily: 'serif',
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Color(0x203D2B1F),
                  blurRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Decorative lines
          Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0x003D2B1F),
                  const Color(0xFF3D2B1F).withOpacity(0.4),
                  const Color(0x003D2B1F),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriggerCondition() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF4A5A3A),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flash_on, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            widget.card.triggerCondition,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(EventCardType type) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6C8).withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: type.primaryColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Text(
        widget.card.description,
        style: const TextStyle(
          color: Color(0xFF3D2B1F),
          fontSize: 16,
          height: 1.8,
          fontFamily: 'serif',
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }

  Widget _buildIllustration(EventCardType type) {
    return Container(
      height: 80,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: type.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: type.primaryColor.withOpacity(0.3)),
      ),
      child: Center(
        child: Icon(
          type.icon,
          size: 48,
          color: type.primaryColor,
        ),
      ),
    );
  }

  Widget _buildOptions() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: widget.card.options.map((option) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            child: ElevatedButton(
              onPressed: () => widget.onOptionSelected?.call(option.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: option.isPrimary
                    ? const Color(0xFFC4A35A)
                    : const Color(0xFF4A5568),
                foregroundColor: const Color(0xFF1A1A1A),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: option.isPrimary
                        ? const Color(0xFFD4A843)
                        : const Color(0xFF4A5568),
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                option.text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, delay: 300.ms);
        }).toList(),
      ),
    );
  }
}

class _CardBackPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4A843).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw cloud patterns
    for (int i = 0; i < 5; i++) {
      final offsetX = (size.width / 5) * i + 20;
      final offsetY = size.height * 0.3 + (i % 2 == 0 ? 20 : -20);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(offsetX, offsetY),
          width: 60,
          height: 30,
        ),
        paint,
      );
    }

    // Corner bamboo patterns
    _drawBambooCorner(canvas, Offset.zero, size);
    _drawBambooCorner(canvas, Offset(size.width, 0), size, flipX: true);
    _drawBambooCorner(canvas, Offset(0, size.height), size, flipY: true);
    _drawBambooCorner(canvas, Offset(size.width, size.height), size,
        flipX: true, flipY: true);
  }

  void _drawBambooCorner(Canvas canvas, Offset corner, Size size,
      {bool flipX = false, bool flipY = false}) {
    final paint = Paint()
      ..color = const Color(0xFFD4A843).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 3; i++) {
      final startX = flipX ? corner.dx - 30 : corner.dx + 30;
      final startY = flipY ? corner.dy - 20 : corner.dy + 20;
      canvas.drawLine(
        Offset(startX, startY),
        Offset(
          flipX ? startX - 15 : startX + 15,
          flipY ? startY - 10 : startY + 10,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
