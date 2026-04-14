import 'package:flutter/material.dart';
import 'deck_distributor_colors.dart';

/// 缺角土黄宣纸风对话气泡
/// 复用 Char006 同款气泡样式
/// - 气泡底色：土黄 #E8D5A3
/// - 气泡边框：暗青灰 #3D4A5C
/// - 左下角缺角（8px 直角缺，丐帮风格标识）
/// - 豪爽/激活状态：边框变为暖金 #D4A843
/// - 冷却/警告状态：边框变为暗红 #8B2020
class DeckDistributorBubble extends StatelessWidget {
  final String text;
  final String? speakerName;
  final DeckDistributorBubbleState bubbleState;

  const DeckDistributorBubble({
    super.key,
    required this.text,
    this.speakerName,
    this.bubbleState = DeckDistributorBubbleState.normal,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    switch (bubbleState) {
      case DeckDistributorBubbleState.active:
        borderColor = DeckDistributorColors.gold;
        break;
      case DeckDistributorBubbleState.warning:
        borderColor = DeckDistributorColors.vermillionDeep;
        break;
      case DeckDistributorBubbleState.normal:
        borderColor = DeckDistributorColors.darkCyanDeep;
        break;
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 气泡主体
          CustomPaint(
            painter: _NotchBubblePainter(
              bgColor: DeckDistributorColors.earthYellowLight,
              borderColor: borderColor,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 人名标签
                  if (speakerName != null) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: DeckDistributorColors.gold,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          speakerName!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: DeckDistributorColors.gold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  // 台词
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: bubbleState == DeckDistributorBubbleState.warning
                          ? DeckDistributorColors.vermillionDeep
                          : const Color(0xFF3D2B1F),
                      fontWeight: bubbleState == DeckDistributorBubbleState.active
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum DeckDistributorBubbleState {
  normal,
  active,
  warning,
}

/// 缺角气泡绘制器
/// 左下角缺角效果（8px 直角缺）
class _NotchBubblePainter extends CustomPainter {
  final Color bgColor;
  final Color borderColor;

  _NotchBubblePainter({
    required this.bgColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const notchSize = 10.0;
    const borderWidth = 2.0;

    // 气泡主体路径（右下右上左上，左下缺角）
    final path = Path()
      ..moveTo(notchSize, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - notchSize)
      ..lineTo(size.width - notchSize, size.height)
      ..lineTo(notchSize, size.height)
      ..lineTo(0, size.height - notchSize)
      ..lineTo(0, notchSize)
      ..close();

    // 填充
    final fillPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 边框（除左下缺角边外）
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final borderPath = Path()
      ..moveTo(notchSize, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - notchSize)
      ..lineTo(size.width - notchSize, size.height)
      ..lineTo(notchSize, size.height)
      ..lineTo(0, size.height - notchSize);

    canvas.drawPath(borderPath, borderPaint);

    // 左下角三角缺角（边框尾端）
    final notchPath = Path()
      ..moveTo(0, size.height - notchSize)
      ..lineTo(notchSize, size.height);

    canvas.drawPath(notchPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _NotchBubblePainter oldDelegate) {
    return oldDelegate.bgColor != bgColor || oldDelegate.borderColor != borderColor;
  }
}
