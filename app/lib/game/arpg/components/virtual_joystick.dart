import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 虚拟摇杆组件
/// 用于移动端触控操作
class VirtualJoystickComponent extends PositionComponent {
  final double radius; // 摇杆底座半径
  final Color color;   // 底座颜色
  final Color knobColor; // 摇杆球颜色
  
  bool _isPressed = false;
  Vector2 _knobPosition = Vector2.zero(); // 相对于中心的偏移
  Vector2 _delta = Vector2.zero(); // 输出方向
  
  double _currentRadius = 0;
  
  VirtualJoystickComponent({
    required FlameGame gameRef,
    this.radius = 50,
    this.color = const Color(0x44FFFFFF),
    this.knobColor = const Color(0xCCFFFFFF),
  }) : super(
    position: Vector2(120, gameRef.size.y - 180),
    size: Vector2(radius * 2, radius * 2),
    anchor: Anchor.center,
  );
  
  bool get isPressed => _isPressed;
  Vector2 get delta => _delta;
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // 限制摇杆球在半径内
    if (_knobPosition.length > radius) {
      _knobPosition = _knobPosition..normalize()..scale(radius);
    }
    
    // 计算输出方向（归一化）
    if (_knobPosition.length > 5) {
      _delta = _knobPosition.clone()..normalize();
    } else {
      _delta = Vector2.zero();
    }
  }
  
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // 重新定位到左下角
    position = Vector2(120, size.y - 180);
  }
  
  @override
  bool onDragStart(DragStartEvent event) {
    _isPressed = true;
    _currentRadius = radius;
    _updateKnob(event.localStartPosition);
    return true;
  }
  
  @override
  bool onDragUpdate(DragUpdateEvent event) {
    _updateKnob(event.localPosition);
    return true;
  }
  
  @override
  bool onDragEnd(DragEndEvent event) {
    _isPressed = false;
    _knobPosition = Vector2.zero();
    _delta = Vector2.zero();
    return true;
  }
  
  void _updateKnob(Vector2 localPos) {
    // 将触摸位置转换为相对于摇杆中心的坐标
    final center = Vector2(radius, radius);
    _knobPosition = localPos - center;
    
    // 限制在半径内
    if (_knobPosition.length > radius) {
      _knobPosition = _knobPosition..normalize()..scale(radius);
    }
  }
  
  @override
  void render(Canvas canvas) {
    // 绘制底座（半透明圆圈）
    final basePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(radius, radius),
      radius,
      basePaint,
    );
    
    // 绘制底座边框
    final borderPaint = Paint()
      ..color = const Color(0x66FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(
      Offset(radius, radius),
      radius,
      borderPaint,
    );
    
    // 绘制摇杆球
    if (_isPressed || _knobPosition.length > 1) {
      final knobPaint = Paint()
        ..color = knobColor
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(radius + _knobPosition.x, radius + _knobPosition.y),
        radius * 0.4,
        knobPaint,
      );
    }
  }
}
