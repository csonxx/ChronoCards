import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ARPG战斗界面
/// 位置：右下角技能栏 + 左上角HP/气力条 + 中央连击计数
class ArpgBattleScreen extends StatefulWidget {
  const ArpgBattleScreen({super.key});
  @override
  State<ArpgBattleScreen> createState() => _ArpgBattleScreenState();
}

class _ArpgBattleScreenState extends State<ArpgBattleScreen> {
  // 示例数据，后续从Provider获取
  int hp = 1000;
  int maxHp = 1000;
  int qi = 80;
  int maxQi = 100;
  int combo = 7;
  
  // 技能CD状态（示例）
  Map<String, double> skillCooldowns = {
    'K': 0, // 0=可用, >0=冷却中(秒数)
    'L': 0,
    'U': 0,
    'I': 0,
    'O': 0,
  };
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 左上：HP条+气力条
        Positioned(top: 20, left: 20, child: _buildStatusBars()),
        // 中央偏上：连击计数
        if (combo >= 3) Positioned(top: 100, left: 0, right: 0, child: _buildComboCounter()),
        // 右下：技能栏
        Positioned(bottom: 20, right: 20, child: _buildSkillBar()),
        // 底部中央：闪避+格挡
        Positioned(bottom: 100, left: 0, right: 0, child: _buildDodgeBlock()),
      ],
    );
  }
  
  Widget _buildStatusBars() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HP条
        Row(children: [
          const Text('HP ', style: TextStyle(color: Color(0xFFc9a227), fontSize: 14)),
          Container(
            width: 150, height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFF8b1a1a),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: const Color(0xFFc9a227), width: 1),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: hp / maxHp,
              child: Container(color: const Color(0xFFc9a227)),
            ),
          ),
          Text(' $hp/$maxHp', style: const TextStyle(color: Colors.white, fontSize: 12)),
        ]),
        const SizedBox(height: 4),
        // 气力条
        Row(children: [
          const Text('气力 ', style: TextStyle(color: Color(0xFF4169E1), fontSize: 14)),
          Container(
            width: 120, height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFF1a3a5c),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: qi / maxQi,
              child: Container(color: const Color(0xFF4169E1)),
            ),
          ),
          Text(' $qi/$maxQi', style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ]),
      ],
    );
  }
  Widget _buildComboCounter() {
    return Center(
      child: Text(
        '$combo',
        style: const TextStyle(
          fontSize: 48,
          color: Color(0xFFc9a227),
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 8)],
        ),
      ),
    );
  }
  
  Widget _buildSkillBar() {
    // 6个技能按钮: J(普攻) K L U I O
    final keys = ['J', 'K', 'L', 'U', 'I', 'O'];
    return Row(mainAxisSize: MainAxisSize.min, children: keys.map((k) => _buildSkillButton(k)).toList());
  }
  
  Widget _buildSkillButton(String key) {
    final cd = skillCooldowns[key] ?? 0;
    final isReady = cd <= 0;
    final isJ = key == 'J';
    final color = isJ ? const Color(0xFF8b1a1a) : const Color(0xFF2d5a2d);
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Stack(alignment: Alignment.center, children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color: isReady ? color : color.withOpacity(0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFc9a227), width: 2),
          ),
          child: Center(child: Text(key, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
        ),
        if (!isReady)
          SizedBox(width: 50, height: 50,
            child: CircularProgressIndicator(
              value: 1 - (cd / 10), // 假设最大CD=10秒
              strokeWidth: 3,
              color: Colors.white54,
              backgroundColor: Colors.transparent,
            )),
      ]),
    );
  }
  
  Widget _buildDodgeBlock() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _buildActionButton('闪避', const Color(0xFF1a4a8a)),
      const SizedBox(width: 20),
      _buildActionButton('格挡', const Color(0xFF4a1a8a)),
    ]);
  }
  
  Widget _buildActionButton(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white30)),
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}
