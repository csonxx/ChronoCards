import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 伤害飘字组件
class FloatingDamageText extends PositionComponent {
  final double damage;
  final Color baseColor;
  final double lifetime;
  final bool isCrit;
  final double fadeStart;

  double _elapsed = 0;
  TextPainter? _textPainter;
  bool _initialized = false;

  FloatingDamageText({
    required super.position,
    required this.damage,
    required this.baseColor,
    this.lifetime = 1.0,
    this.isCrit = false,
    this.fadeStart = 0.7,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final fontSize = isCrit ? 28.0 : 20.0;
    final text = isCrit ? 'CRIT! ${damage.toInt()}' : damage.toInt().toString();
    _textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: baseColor,
          shadows: const [
            Shadow(color: Color(0x88000000), blurRadius: 4),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    _textPainter!.layout();
    _initialized = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= lifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_initialized || _textPainter == null) return;

    final progress = _elapsed / lifetime;

    // 计算透明度
    double alphaValue;
    if (progress > fadeStart) {
      final fadeProgress = (progress - fadeStart) / (1.0 - fadeStart);
      alphaValue = (1.0 - fadeProgress) * 255.0;
    } else {
      alphaValue = 255.0;
    }
    alphaValue = alphaValue.clamp(0.0, 255.0);

    // 上移动画
    final yOffset = -30.0 * progress;

    canvas.save();
    canvas.translate(0.0, yOffset);

    // 渐变消失效果
    final currentColor = Color.fromARGB(
      alphaValue.toInt(),
      baseColor.red,
      baseColor.green,
      0,
    );

    _textPainter!.text = TextSpan(
      text: isCrit ? 'CRIT! ${damage.toInt()}' : damage.toInt().toString(),
      style: TextStyle(
        fontSize: isCrit ? 28.0 : 20.0,
        fontWeight: FontWeight.bold,
        color: currentColor,
        shadows: const [
          Shadow(color: Color(0x88000000), blurRadius: 4),
        ],
      ),
    );
    _textPainter!.layout();

    // 居中显示
    _textPainter!.paint(
      canvas,
      Offset(-_textPainter!.width / 2, -_textPainter!.height / 2),
    );

    canvas.restore();
  }
}
