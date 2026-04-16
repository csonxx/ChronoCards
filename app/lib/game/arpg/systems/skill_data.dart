/// ARPG技能数据
/// 基于PRD定义的5个门派技能

class SkillData {
  final String name;
  final String description;
  final int damage;
  final double cooldownSec;
  final int qiCost;
  final double range;
  final bool isAoe;
  final String animationName;
  
  const SkillData({
    required this.name,
    required this.description,
    required this.damage,
    required this.cooldownSec,
    required this.qiCost,
    required this.range,
    this.isAoe = false,
    required this.animationName,
  });
  
  // 5个技能配置（基于PRD）
  static const List<SkillData> skills = [
    // K - 少林·金刚拳
    SkillData(
      name: '金刚拳',
      description: '向前冲刺1.5米，施展金刚拳，造成250伤害，最后一击击倒敌人',
      damage: 250,
      cooldownSec: 5,
      qiCost: 20,
      range: 150,
      isAoe: false,
      animationName: 'skill_kung_fu',
    ),
    // L - 武当·太极剑
    SkillData(
      name: '太极剑',
      description: '原地舞剑，形成太极剑气圈，半径2.5米，伤害180×3次',
      damage: 180,
      cooldownSec: 8,
      qiCost: 30,
      range: 200,
      isAoe: true,
      animationName: 'skill_taichi',
    ),
    // U - 峨眉·清风剑
    SkillData(
      name: '清风剑',
      description: '发射一道剑气，直线飞行8米，伤害160，穿透后衰减60%',
      damage: 160,
      cooldownSec: 6,
      qiCost: 25,
      range: 300,
      isAoe: false,
      animationName: 'skill_qingfeng',
    ),
    // I - 华山·破剑式
    SkillData(
      name: '破剑式',
      description: '跃起下刺，伤害400，无视30%防御，落地冲击波额外80伤害',
      damage: 400,
      cooldownSec: 10,
      qiCost: 35,
      range: 150,
      isAoe: false,
      animationName: 'skill_pojian',
    ),
    // O - 丐帮·打狗棒
    SkillData(
      name: '打狗棒',
      description: '棒扫180°，半径2米，伤害130×2次，被击中敌人减速40%持续2秒',
      damage: 130,
      cooldownSec: 7,
      qiCost: 25,
      range: 180,
      isAoe: true,
      animationName: 'skill_dagou',
    ),
  ];
  
  // 普攻连击数据
  static const List<int> comboDamages = [100, 120, 150];
  static const List<double> comboMultipliers = [1.0, 1.2, 1.5];
  
  // 角色基础属性（基于PRD）
  static const int baseHp = 1000;
  static const int baseAttack = 100;
  static const int baseDefense = 20;
  static const int baseQi = 100;
  static const double baseMoveSpeed = 3.5; // m/s
}
