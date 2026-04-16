import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../arpg_game.dart';

/// ARPG游戏页面
/// 作为Flutter Widget嵌入到应用中
class ArpgGameWidget extends StatefulWidget {
  const ArpgGameWidget({super.key});

  @override
  State<ArpgGameWidget> createState() => _ArpgGameWidgetState();
}

class _ArpgGameWidgetState extends State<ArpgGameWidget> {
  late ArpgGame game;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    game = ArpgGame();
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A3D1A),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A3D1A),
      body: GameWidget(
        game: game,
        overlayBuilderMap: {
          'gameOver': (context, game) => _GameOverOverlay(game: game as ArpgGame),
          'pause': (context, game) => _PauseOverlay(game: game as ArpgGame),
        },
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  final ArpgGame game;
  
  const _GameOverOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '游戏结束',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '你被击败了',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => game.restartGame(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                backgroundColor: const Color(0xFF4A90D9),
              ),
              child: const Text(
                '重新开始',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  final ArpgGame game;
  
  const _PauseOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '暂停',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => game.isPaused = false,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                backgroundColor: const Color(0xFF4A90D9),
              ),
              child: const Text(
                '继续游戏',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ARPG战斗UI覆盖层（移动端/网页端）
/// 显示在游戏画面上的HUD
class ArpgBattleHUD extends StatelessWidget {
  final int currentHp;
  final int maxHp;
  final int currentQi;
  final int maxQi;
  final List<double> skillCooldowns; // 0-1表示冷却进度
  final double dodgeCooldown; // 0-1表示冷却进度
  final int level;
  final String faction;
  
  const ArpgBattleHUD({
    super.key,
    required this.currentHp,
    required this.maxHp,
    required this.currentQi,
    required this.maxQi,
    required this.skillCooldowns,
    required this.dodgeCooldown,
    this.level = 1,
    this.faction = '少林',
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 左上角：角色状态
        Positioned(
          top: 20,
          left: 20,
          child: _PlayerStatusWidget(
            currentHp: currentHp,
            maxHp: maxHp,
            currentQi: currentQi,
            maxQi: maxQi,
            level: level,
            faction: faction,
          ),
        ),
        
        // 右下角：技能栏
        Positioned(
          bottom: 20,
          right: 20,
          child: _SkillBarWidget(skillCooldowns: skillCooldowns),
        ),
        
        // 底部中央：闪避/格挡
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: _ActionButtonsWidget(dodgeCooldown: dodgeCooldown),
        ),
      ],
    );
  }
}

class _PlayerStatusWidget extends StatelessWidget {
  final int currentHp;
  final int maxHp;
  final int currentQi;
  final int maxQi;
  final int level;
  final String faction;
  
  const _PlayerStatusWidget({
    required this.currentHp,
    required this.maxHp,
    required this.currentQi,
    required this.maxQi,
    required this.level,
    required this.faction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 门派和等级
          Row(
            children: [
              Text(
                faction,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(width: 8),
              Text(
                'LV.$level',
                style: const TextStyle(color: Colors.amber, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // 血条
          _ResourceBar(
            current: currentHp,
            max: maxHp,
            color: const Color(0xFF44FF44),
            label: 'HP',
          ),
          const SizedBox(height: 4),
          
          // 气力条
          _ResourceBar(
            current: currentQi,
            max: maxQi,
            color: const Color(0xFF4488FF),
            label: '气力',
          ),
        ],
      ),
    );
  }
}

class _ResourceBar extends StatelessWidget {
  final int current;
  final int max;
  final Color color;
  final String label;
  
  const _ResourceBar({
    required this.current,
    required this.max,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = max > 0 ? current / max : 0.0;
    
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label $current/$max',
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          const SizedBox(height: 2),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: ratio,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillBarWidget extends StatelessWidget {
  final List<double> skillCooldowns;
  
  const _SkillBarWidget({required this.skillCooldowns});

  @override
  Widget build(BuildContext context) {
    const skillKeys = ['K', 'L', 'U', 'I', 'O'];
    const skillNames = ['金刚拳', '太极剑', '清风剑', '破剑式', '打狗棒'];
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final cooldown = i < skillCooldowns.length ? skillCooldowns[i] : 0.0;
        return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: _SkillButton(
            keyName: skillKeys[i],
            skillName: skillNames[i],
            cooldownProgress: cooldown,
          ),
        );
      }),
    );
  }
}

class _SkillButton extends StatelessWidget {
  final String keyName;
  final String skillName;
  final double cooldownProgress; // 0 = 就绪, >0 = 冷却中
  
  const _SkillButton({
    required this.keyName,
    required this.skillName,
    required this.cooldownProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: cooldownProgress > 0 ? Colors.grey : const Color(0xFF4A90D9),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // 冷却遮罩
          if (cooldownProgress > 0)
            Positioned.fill(
              child: CircularProgressIndicator(
                value: 1 - cooldownProgress,
                backgroundColor: Colors.black45,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF4A90D9)),
                strokeWidth: 3,
              ),
            ),
          
          // 按键提示
          Center(
            child: Text(
              keyName,
              style: TextStyle(
                color: cooldownProgress > 0 ? Colors.grey : Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // 底部技能名
          Positioned(
            bottom: 2,
            left: 0,
            right: 0,
            child: Text(
              skillName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtonsWidget extends StatelessWidget {
  final double dodgeCooldown;
  
  const _ActionButtonsWidget({required this.dodgeCooldown});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 闪避按钮
        Container(
          width: 70,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: dodgeCooldown > 0 ? Colors.grey : const Color(0xFF44AAFF),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              dodgeCooldown > 0 ? '${(dodgeCooldown * 1.2).toStringAsFixed(1)}s' : '闪避',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 20),
        
        // 格挡按钮
        Container(
          width: 70,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFAA44FF), width: 2),
          ),
          child: const Center(
            child: Text(
              '格挡',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
