import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Card stack widget - 3D deck display
/// Shows remaining cards with 3D perspective effect
class CardStackWidget extends StatelessWidget {
  final int remainingCards;
  final int totalCards;
  final VoidCallback? onTap;

  const CardStackWidget({
    super.key,
    required this.remainingCards,
    required this.totalCards,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 3D card stack
          SizedBox(
            width: 180,
            height: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background cards (stack effect)
                for (int i = 0; i < 5; i++)
                  Positioned(
                    top: i * 2.0,
                    left: i * 1.0,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateX(0.05 * i)
                        ..rotateY(-0.03 * i),
                      child: Container(
                        width: 160 - (i * 4),
                        height: 240 - (i * 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Color.lerp(
                            const Color(0xFF1A2A4A),
                            const Color(0xFF0A1525),
                            i / 5,
                          ),
                          border: Border.all(
                            color: Color.lerp(
                              const Color(0xFFD4A843),
                              const Color(0xFF8A7340),
                              i / 5,
                            )!,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3 - (i * 0.05)),
                              blurRadius: 10 - (i * 2),
                              offset: Offset((2 + i).toDouble(), (4 + i).toDouble()),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Top card (drawable)
                _TopCard(
                  onTap: onTap,
                )
                    .animate(onPlay: (c) => c.repeat())
                    .moveY(
                      begin: 0,
                      end: -3,
                      duration: 2000.ms,
                      curve: Curves.easeInOut,
                    )
                    .then()
                    .moveY(
                      begin: -3,
                      end: 0,
                      duration: 2000.ms,
                      curve: Curves.easeInOut,
                    ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Remaining cards indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF252A34),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD4A843), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.style,
                  color: Color(0xFFD4A843),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '$remainingCards',
                  style: const TextStyle(
                    color: Color(0xFFD4A843),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ' / $totalCards',
                  style: const TextStyle(
                    color: Color(0xFFB0B0B0),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Tap hint
          if (onTap != null)
            Text(
              '点击抽卡',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ).animate(onPlay: (c) => c.repeat()).fadeIn().then().fadeOut(),
        ],
      ),
    );
  }
}

class _TopCard extends StatelessWidget {
  final VoidCallback? onTap;

  const _TopCard({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(-0.1)
          ..rotateY(0.05),
        child: Container(
          width: 160,
          height: 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
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
                color: const Color(0xFFD4A843).withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Pattern
              Positioned.fill(
                child: CustomPaint(
                  painter: _StackPatternPainter(),
                ),
              ),
              // Center seal
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD4A843),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '江\n湖',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFD4A843),
                            fontSize: 16,
                            fontFamily: 'serif',
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '抽',
                      style: TextStyle(
                        color: Color(0xFFD4A843),
                        fontSize: 14,
                        fontFamily: 'serif',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StackPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4A843).withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw cloud pattern
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.3, size.height * 0.2),
        width: 50,
        height: 25,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.7, size.height * 0.3),
        width: 40,
        height: 20,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.7),
        width: 45,
        height: 22,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
