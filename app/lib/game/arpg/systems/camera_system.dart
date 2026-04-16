import 'package:flame/components.dart';
import 'package:flame/game.dart';
import '../arpg_game.dart';

/// 越肩视角相机系统
/// 实现角色在屏幕下方1/3的越肩视角效果
class ArpgCameraComponent extends Component {
  final ArpgGame gameRef;
  final Vector2 shoulderOffset; // 角色在屏幕中的偏移（越肩效果）
  
  PositionComponent? _followTarget;
  Vector2 _currentOffset = Vector2.zero();
  Vector2 _targetOffset = Vector2.zero();
  
  // 相机平滑跟随系数
  static const double followSmoothness = 0.1;
  
  // 相机偏移范围（防止过度偏移）
  static const double maxOffsetX = 100;
  static const double maxOffsetY = 100;
  
  ArpgCameraComponent({
    required this.gameRef,
    required this.shoulderOffset,
  }) : super();
  
  void followTarget(PositionComponent target) {
    _followTarget = target;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (_followTarget == null) return;
    
    // 计算目标偏移（基于摇杆/移动方向）
    final targetPos = _followTarget!.position;
    
    // 越肩偏移：角色在屏幕下方1/3
    final screenCenter = gameRef.screenSize / 2;
    _targetOffset = Vector2(
      shoulderOffset.x.clamp(-maxOffsetX, maxOffsetX),
      shoulderOffset.y.clamp(-maxOffsetY, maxOffsetY),
    );
    
    // 平滑插值
    _currentOffset = Vector2(
      _currentOffset.x + (_targetOffset.x - _currentOffset.x) * followSmoothness,
      _currentOffset.y + (_targetOffset.y - _currentOffset.y) * followSmoothness,
    );
  }
  
  /// 获取相机偏移量（用于世界坐标转屏幕坐标）
  Vector2 get cameraOffset => _currentOffset;
  
  /// 世界坐标转屏幕坐标
  Vector2 worldToScreen(Vector2 worldPos) {
    final screenCenter = gameRef.screenSize / 2;
    return worldPos - _followTarget!.position + screenCenter + _currentOffset;
  }
  
  /// 屏幕坐标转世界坐标
  Vector2 screenToWorld(Vector2 screenPos) {
    final screenCenter = gameRef.screenSize / 2;
    return screenPos + _followTarget!.position - screenCenter - _currentOffset;
  }
}
