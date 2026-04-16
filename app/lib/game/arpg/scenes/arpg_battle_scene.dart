import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../arpg_game.dart';

/// 战斗场景组件
/// 管理竹林背景、地面装饰等视觉元素
class ArpgBattleScene extends Component {
  final ArpgGame gameRef;
  
  ArpgBattleScene({required this.gameRef});
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _renderBackground(canvas);
    _renderGround(canvas);
    _renderDecorations(canvas);
  }
  
  void _renderBackground(Canvas canvas) {
    // 竹林背景渐变
    final bgRect = Rect.fromLTWH(-500, -500, 2000, 2000);
    
    // 天空渐变（从深绿到浅绿）
    final skyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF0D1F0D),
        const Color(0xFF1A3D1A),
        const Color(0xFF2D5A2D),
      ],
    );
    
    final skyPaint = Paint()
      ..shader = skyGradient.createShader(bgRect);
    
    canvas.drawRect(bgRect, skyPaint);
  }
  
  void _renderGround(Canvas canvas) {
    // 地面（深色泥土）
    final groundPaint = Paint()..color = const Color(0xFF2A1F15);
    canvas.drawRect(
      Rect.fromLTWH(-500, 100, 2000, 1000),
      groundPaint,
    );
    
    // 草地边缘
    final grassPaint = Paint()..color = const Color(0xFF3D5A3D);
    canvas.drawRect(
      Rect.fromLTWH(-500, 80, 2000, 30),
      grassPaint,
    );
  }
  
  void _renderDecorations(Canvas canvas) {
    // 竹子装饰（简单线条表示）
    final bambooPaint = Paint()
      ..color = const Color(0xFF4A7A4A)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    // 绘制多排竹子作为背景装饰
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 15; col++) {
        final x = -400 + col * 80 + (row % 2) * 40;
        final y = -200 - row * 100;
        final height = 150.0 + (row * 30);
        
        // 竹竿
        canvas.drawLine(
          Offset(x, y),
          Offset(x + 5, y - height),
          bambooPaint,
        );
        
        // 竹叶（简单三角形）
        final leafPaint = Paint()
          ..color = const Color(0xFF5A9A5A)
          ..style = PaintingStyle.fill;
        
        for (int i = 0; i < 3; i++) {
          final leafY = y - height + 20 + i * 25;
          final path = Path()
            ..moveTo(x + 5, leafY)
            ..lineTo(x + 30, leafY - 10)
            ..lineTo(x + 5, leafY - 15)
            ..close();
          canvas.drawPath(path, leafPaint);
        }
      }
    }
    
    // 地面石头/草丛装饰
    final rockPaint = Paint()..color = const Color(0xFF4A3A2A);
    for (int i = 0; i < 10; i++) {
      final rx = -300 + i * 80.0;
      final ry = 150 + (i % 3) * 20;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(rx, ry), width: 30, height: 15),
        rockPaint,
      );
    }
  }
}
