import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 飘字伤害数字组件
/// 显示从红色到黄色渐变的伤害数字
class FloatingDamageText extends PositionComponent {
  final int damage;
  final double lifetime;
  double _elapsed = 0;
  
  // 飘字参数
  static const double floatSpeed = 60.0; // 像素/秒
  static const double fadeStart = 0.5; // 生命周期后半段开始淡出
  
  FloatingDamageText({
    required super.position,
    required this.damage,
    this.lifetime = 1.0,
  }) : super(
    anchor: Anchor.center,
    priority: 100, // 渲染在最上层
  );
  
  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    
    // 向上飘动
    position.y -= floatSpeed * dt;
    
    // 生命周期结束则移除
    if (_elapsed >= lifetime) {
      removeFromParent();
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    final progress = _elapsed / lifetime; // 0.0 → 1.0
    
    // 颜色从红色渐变到黄色
    final red = 255;
    final green = (255 * (1 - progress * 0.6)).clamp(0, 255).toInt();
    final alpha = progress > fadeStart 
        ? ((1 - (progress - fadeStart) / (1 - fadeStart)) * 255).clamp(0, 255).toInt()
        : 255;
    
    final color = Color.fromARGB(alpha, red, green, 0);
    
    // 绘制伤害数字
    final textPainter = TextPainter(
      text: TextSpan(
        text: '-$damage',
        style: TextStyle(
          color: color,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(
              offset: Offset(1, 1),
              blurRadius: 2,
              color: Color(0x88000000),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
  }
}

/// 暴击伤害数字（更大，带感叹号）
class CriticalDamageText extends FloatingDamageText {
  CriticalDamageText({
    required super.position,
    required super.damage,
    super.lifetime = 1.2,
  });
  
  @override
  void render(Canvas canvas) {
    final progress = _elapsed / lifetime;
    
    final red = 255;
    final green = (200 * (1 - progress)).clamp(0, 255).toInt();
    final alpha = progress > fadeStart 
        ? ((1 - (progress - fadeStart) / (1 - fadeStart)) * 255).clamp(0, 255).toInt()
        : 255;
    
    final color = Color.fromARGB(alpha, red, green, 0);
    
    // 更大的字体 + CRIT!
    final textPainter = TextPainter(
      text: TextSpan(
        text: '-$damage CRIT!',
        style: TextStyle(
          color: color,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(
              offset: Offset(2, 2),
              blurRadius: 4,
              color: Color(0x88000000),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
  }
}
