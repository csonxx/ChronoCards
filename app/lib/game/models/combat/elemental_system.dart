/// 六元素反应系统 - 风/火/水/雷/冰/毒
enum ElementType {
  wind,
  fire,
  water,
  thunder,
  ice,
  poison,
}

/// 元素状态附着
class ElementalStatus {
  final ElementType element;
  final int stacks; // 层数（可叠加）
  final double duration; // 剩余持续时间（秒）
  final double damagePerSec; // 每秒伤害

  const ElementalStatus({
    required this.element,
    this.stacks = 1,
    this.duration = 5.0,
    this.damagePerSec = 0,
  });

  ElementalStatus copyWith({
    ElementType? element,
    int? stacks,
    double? duration,
    double? damagePerSec,
  }) {
    return ElementalStatus(
      element: element ?? this.element,
      stacks: stacks ?? this.stacks,
      duration: duration ?? this.duration,
      damagePerSec: damagePerSec ?? this.damagePerSec,
    );
  }

  ElementalStatus addStack() {
    return copyWith(
      stacks: (stacks + 1).clamp(1, 4), // 最多4层
      duration: 5.0, // 重置持续时间
    );
  }
}

/// 元素反应类型
enum ElementalReactionType {
  vaporize,      // 蒸发：火+水
  melt,          // 融化：火+冰
  overload,      // 超载：火+雷
  electroCharged, // 感电：雷+水
  freeze,        // 冻结：冰+水
  superConduct,  // 超导：冰+雷
  burning,       // 燃烧：火+风
  spread,        // 扩散：风+火/水/雷/冰
  bloom,         // 绽放：水+草(毒)
  catalyze,      // 催化：草(毒)+雷
  corrosion,     // 腐蚀：毒+风
}

/// 元素反应计算器
class ElementalReactionCalculator {
  static const Map<String, double> _reactionMultipliers = {
    'vaporize_fire': 2.0,      // 蒸发（火触发）
    'vaporize_water': 1.5,     // 蒸发（水触发）
    'melt_fire': 1.5,          // 融化（火触发）
    'melt_ice': 2.0,           // 融化（冰触发）
    'overload': 1.5,           // 超载
    'electroCharged': 1.2,     // 感电
    'freeze': 1.5,             // 冻结
    'superConduct': 1.0,       // 超导（物理减抗）
    'burning': 0.8,            // 燃烧（持续伤害）
    'spread': 0.5,             // 扩散（范围伤害）
    'bloom': 1.0,              // 绽放
    'catalyze': 1.3,           // 催化
    'corrosion': 0.6,         // 腐蚀（持续减防）
  };

  /// 计算元素反应
  /// 返回: (反应类型, 额外伤害, 特殊效果)
  static (ElementalReactionType?, double, String?) calculateReaction(
    ElementalStatus attacker,
    ElementalStatus defender,
  ) {
    final key = _getReactionKey(attacker.element, defender.element);
    if (key == null) return (null, 0, null);

    final multiplier = _reactionMultipliers[key] ?? 1.0;
    final reaction = _getReactionType(key);
    final extraDamage = (attacker.stacks * 20 * multiplier).roundToDouble();
    final effect = _getReactionEffect(reaction);

    return (reaction, extraDamage, effect);
  }

  static String? _getReactionKey(ElementType a, ElementType b) {
    final combos = {
      (ElementType.fire, ElementType.water): 'vaporize',
      (ElementType.water, ElementType.fire): 'vaporize',
      (ElementType.fire, ElementType.ice): 'melt',
      (ElementType.ice, ElementType.fire): 'melt',
      (ElementType.fire, ElementType.thunder): 'overload',
      (ElementType.thunder, ElementType.fire): 'overload',
      (ElementType.thunder, ElementType.water): 'electroCharged',
      (ElementType.water, ElementType.thunder): 'electroCharged',
      (ElementType.ice, ElementType.water): 'freeze',
      (ElementType.water, ElementType.ice): 'freeze',
      (ElementType.ice, ElementType.thunder): 'superConduct',
      (ElementType.thunder, ElementType.ice): 'superConduct',
      (ElementType.fire, ElementType.wind): 'burning',
      (ElementType.wind, ElementType.fire): 'burning',
      (ElementType.wind, ElementType.water): 'spread',
      (ElementType.wind, ElementType.thunder): 'spread',
      (ElementType.wind, ElementType.ice): 'spread',
      (ElementType.poison, ElementType.thunder): 'catalyze',
      (ElementType.thunder, ElementType.poison): 'catalyze',
      (ElementType.poison, ElementType.wind): 'corrosion',
      (ElementType.wind, ElementType.poison): 'corrosion',
    };

    return combos[(a, b)];
  }

  static ElementalReactionType _getReactionType(String key) {
    switch (key) {
      case 'vaporize': return ElementalReactionType.vaporize;
      case 'melt': return ElementalReactionType.melt;
      case 'overload': return ElementalReactionType.overload;
      case 'electroCharged': return ElementalReactionType.electroCharged;
      case 'freeze': return ElementalReactionType.freeze;
      case 'superConduct': return ElementalReactionType.superConduct;
      case 'burning': return ElementalReactionType.burning;
      case 'spread': return ElementalReactionType.spread;
      case 'bloom': return ElementalReactionType.bloom;
      case 'catalyze': return ElementalReactionType.catalyze;
      case 'corrosion': return ElementalReactionType.corrosion;
      default: return ElementalReactionType.vaporize;
    }
  }

  static String _getReactionEffect(ElementalReactionType reaction) {
    switch (reaction) {
      case ElementalReactionType.vaporize: return '蒸发';
      case ElementalReactionType.melt: return '融化';
      case ElementalReactionType.overload: return '超载';
      case ElementalReactionType.electroCharged: return '感电';
      case ElementalReactionType.freeze: return '冻结';
      case ElementalReactionType.superConduct: return '超导';
      case ElementalReactionType.burning: return '燃烧';
      case ElementalReactionType.spread: return '扩散';
      case ElementalReactionType.bloom: return '绽放';
      case ElementalReactionType.catalyze: return '催化';
      case ElementalReactionType.corrosion: return '腐蚀';
    }
  }
}
