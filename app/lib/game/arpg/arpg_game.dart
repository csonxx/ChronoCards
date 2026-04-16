import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'entities/player_character.dart';
import 'entities/enemy_entity.dart';
import 'scenes/arpg_battle_scene.dart';
import 'components/virtual_joystick.dart';
import 'systems/camera_system.dart';
import 'dart:math' as math;

/// ARPG游戏主类 - FlameGame
/// 负责游戏循环、输入处理、实体管理
class ArpgGame extends FlameGame with HasKeyboardHandlerComponents {
  
  // 游戏场景
  late ArpgBattleScene battleScene;
  
  // 玩家角色
  late PlayerCharacter player;
  
  // 敌人列表
  final List<EnemyEntity> enemies = [];
  
  // 虚拟摇杆
  VirtualJoystickComponent? joystick;
  
  // 键盘输入状态
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  
  // Camera越肩配置
  final Vector2 shoulderOffset = Vector2(0, 150); // 角色在屏幕下方1/3
  late ArpgCameraComponent cameraComponent;
  
  // 屏幕尺寸
  Vector2 screenSize = Vector2.zero();
  
  // 游戏状态
  bool isGameOver = false;
  bool _isPaused = false;
  bool get isPaused => _isPaused;
  set isPaused(bool v) => _isPaused = v;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // 设置背景色（竹林场景）
    camera.backdrop = BackdropBridge();
    
    // 初始化越肩相机
    cameraComponent = ArpgCameraComponent(
      gameRef: this,
      shoulderOffset: shoulderOffset,
    );
    await add(cameraComponent);
    
    // 创建战斗场景
    battleScene = ArpgBattleScene(gameRef: this);
    await add(battleScene);
    
    // 创建玩家角色
    player = PlayerCharacter(gameRef: this);
    await add(player);
    
    // 设置相机跟随玩家
    cameraComponent.followTarget(player);
    
    // 添加虚拟摇杆（移动端）
    _setupJoystick();
    
    // 添加敌人（测试用）
    _spawnTestEnemies();
    
    // 添加键盘监听
    // 键盘监听已通过HasKeyboardHandlerComponents自动处理
    
    print('[ArpgGame] 游戏加载完成');
  }
  
  void _setupJoystick() {
    joystick = VirtualJoystickComponent(
      initialY: size.y - 180,
      radius: 50,
      color: const Color(0x44FFFFFF),
      knobColor: const Color(0xCCFFFFFF),
    );
    add(joystick!);
  }
  
  void _spawnTestEnemies() {
    // 生成山贼杂兵测试
    final bandit1 = EnemyEntity(
      gameRef: this,
      enemyType: EnemyType.bandit,
      position: Vector2(200, 0),
    );
    enemies.add(bandit1);
    add(bandit1);
    
    // 山贼头目
    final boss = EnemyEntity(
      gameRef: this,
      enemyType: EnemyType.banditLeader,
      position: Vector2(300, 100),
    );
    enemies.add(boss);
    add(boss);
  }
  
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    screenSize = size;
  }
  
  @override
  void update(double dt) {
    if (isPaused || isGameOver) return;
    super.update(dt);
    
    // 更新玩家移动输入
    _updatePlayerMovement();
    
    // 更新相机
    cameraComponent.update(dt);
    
    // 更新敌人AI
    for (final enemy in enemies) {
      enemy.update(dt);
    }
  }
  
  void _updatePlayerMovement() {
    Vector2 inputDir = Vector2.zero();
    
    // 虚拟摇杆输入
    if (joystick != null && joystick!.isPressed) {
      inputDir = joystick!.delta;
    }
    
    // WASD键盘输入（网页端）
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      inputDir.y = -1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      inputDir.y = 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      inputDir.x = -1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) || 
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      inputDir.x = 1;
    }
    
    // 标准化方向向量
    if (inputDir.length > 0) {
      inputDir = inputDir..normalize();
    }
    
    player.setMoveDirection(inputDir);
  }
  
  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) {
      _pressedKeys.add(event.logicalKey);
      
      // 普攻 - J键
      if (event.logicalKey == LogicalKeyboardKey.keyJ) {
        player.performAttack(AttackType.light);
      }
      
      // 技能键 - K/L/U/I/O
      if (event.logicalKey == LogicalKeyboardKey.keyK) {
        player.useSkill(0); // 金刚拳
      }
      if (event.logicalKey == LogicalKeyboardKey.keyL) {
        player.useSkill(1); // 太极剑
      }
      if (event.logicalKey == LogicalKeyboardKey.keyU) {
        player.useSkill(2); // 清风剑
      }
      if (event.logicalKey == LogicalKeyboardKey.keyI) {
        player.useSkill(3); // 破剑式
      }
      if (event.logicalKey == LogicalKeyboardKey.keyO) {
        player.useSkill(4); // 打狗棒
      }
      
      // 闪避 - 空格
      if (event.logicalKey == LogicalKeyboardKey.space) {
        player.tryDodge();
      }
      
      // 格挡 - SHIFT（按住）
      if (event.logicalKey == LogicalKeyboardKey.shiftLeft || 
          event.logicalKey == LogicalKeyboardKey.shiftRight) {
        player.startBlock();
      }
      
      // 暂停 - ESC
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        isPaused = !isPaused;
        if (isPaused) {
          overlays.add('pause');
        } else {
          overlays.remove('pause');
        }
      }
    }
    
    if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
      
      // 释放格挡
      if (event.logicalKey == LogicalKeyboardKey.shiftLeft || 
          event.logicalKey == LogicalKeyboardKey.shiftRight) {
        player.endBlock();
      }
    }
    
    return KeyEventResult.ignored;
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
  }
  
  void triggerGameOver() {
    isGameOver = true;
    overlays.add('gameOver');
  }
  
  void restartGame() {
    isGameOver = false;
    _isPaused = false;
    // 重置玩家
    player.reset();
    // 重置敌人
    for (final enemy in enemies) {
      enemy.reset();
    }
    overlays.remove('gameOver');
    overlays.remove('pause');
  }
}

/// 背景组件
class BackdropBridge extends Component {
  @override
  void render(Canvas canvas) {
    // 竹林背景色
    final bgPaint = Paint()..color = const Color(0xFF1A3D1A);
    canvas.drawRect(Rect.fromLTWH(0, 0, 2000, 2000), bgPaint);
    
    // 绘制简单竹林装饰（后续替换为sprite）
    final bambooPaint = Paint()
      ..color = const Color(0xFF2D5A2D)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i < 20; i++) {
      final x = i * 100.0;
      final startPt = Offset(x, 0);
      final endPt = Offset(x + 20, -300);
      canvas.drawLine(startPt, endPt, bambooPaint);
    }
  }
}
