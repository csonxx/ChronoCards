import 'package:equatable/equatable.dart';

/// Faction/enumeration for game characters
enum CharacterFaction {
  mingjiao('明教', 'Mingjiao'),
  shaolin('少林', 'Shaolin'),
  wudang('武当', 'Wudang'),
  jinyiwei('锦衣卫', 'Jinyiwei'),
  wudu('五毒教', 'Wudu'),
  gaibang('丐帮', 'Gaibang');

  final String cn;
  final String en;
  const CharacterFaction(this.cn, this.en);
}

/// Role/archetype for game characters
enum CharacterRole {
  tank('肉盾', 'Tank'),
  dps('输出', 'DPS'),
  support('辅助', 'Support'),
  healer('治疗', 'Healer'),
  assassin('刺客', 'Assassin'),
  allRounder('全能', 'All-Rounder');

  final String cn;
  final String en;
  const CharacterRole(this.cn, this.en);
}

/// Element type for characters
enum CharacterElement {
  fire('火', 'Fire'),
  water('水', 'Water'),
  wind('风', 'Wind'),
  earth('土', 'Earth'),
  thunder('雷', 'Thunder'),
  dark('暗', 'Dark'),
  light('光', 'Light'),
  neutral('无', 'Neutral');

  final String cn;
  final String en;
  const CharacterElement(this.cn, this.en);
}

/// Game character entity — represents one of the 6 playable martial arts masters
class Character extends Equatable {
  final String id;
  final String name;
  final String title; // e.g. "明教教主"
  final CharacterFaction faction;
  final CharacterRole role;
  final CharacterElement element;
  final String modelPath; // path to GLB asset e.g. "assets/models/沈墨渊.glb"
  final String portraitPath; // path to portrait image (optional)
  final int baseHealth;
  final int baseAttack;
  final int baseDefense;
  final int baseSpeed;
  final String description;
  final List<String> skills; // skill IDs or names

  const Character({
    required this.id,
    required this.name,
    required this.title,
    required this.faction,
    required this.role,
    required this.element,
    required this.modelPath,
    this.portraitPath = '',
    this.baseHealth = 100,
    this.baseAttack = 20,
    this.baseDefense = 10,
    this.baseSpeed = 15,
    this.description = '',
    this.skills = const [],
  });

  Character copyWith({
    String? id,
    String? name,
    String? title,
    CharacterFaction? faction,
    CharacterRole? role,
    CharacterElement? element,
    String? modelPath,
    String? portraitPath,
    int? baseHealth,
    int? baseAttack,
    int? baseDefense,
    int? baseSpeed,
    String? description,
    List<String>? skills,
  }) {
    return Character(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      faction: faction ?? this.faction,
      role: role ?? this.role,
      element: element ?? this.element,
      modelPath: modelPath ?? this.modelPath,
      portraitPath: portraitPath ?? this.portraitPath,
      baseHealth: baseHealth ?? this.baseHealth,
      baseAttack: baseAttack ?? this.baseAttack,
      baseDefense: baseDefense ?? this.baseDefense,
      baseSpeed: baseSpeed ?? this.baseSpeed,
      description: description ?? this.description,
      skills: skills ?? this.skills,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        title,
        faction,
        role,
        element,
        modelPath,
        portraitPath,
        baseHealth,
        baseAttack,
        baseDefense,
        baseSpeed,
        description,
        skills,
      ];
}

/// Repository of all 6 playable characters
class CharacterRepository {
  static const List<Character> allCharacters = [
    Character(
      id: 'char_001',
      name: '沈墨渊',
      title: '明教教主',
      faction: CharacterFaction.mingjiao,
      role: CharacterRole.allRounder,
      element: CharacterElement.fire,
      modelPath: 'assets/models/沈墨渊.glb',
      baseHealth: 120,
      baseAttack: 25,
      baseDefense: 15,
      baseSpeed: 18,
      description: '明教教主，身怀九阳神功，内力深厚，纵横江湖多年未逢敌手。',
      skills: ['九阳神功', '烈火掌', '圣火令'],
    ),
    Character(
      id: 'char_002',
      name: '了尘',
      title: '少林寺主持',
      faction: CharacterFaction.shaolin,
      role: CharacterRole.tank,
      element: CharacterElement.earth,
      modelPath: 'assets/models/了尘.glb',
      baseHealth: 180,
      baseAttack: 18,
      baseDefense: 30,
      baseSpeed: 10,
      description: '少林寺住持，修习金钟罩铁布衫，刀枪不入，万劫不倒。',
      skills: ['金钟罩', '易筋经', '少林七十二绝技'],
    ),
    Character(
      id: 'char_003',
      name: '莫问天',
      title: '武当掌门',
      faction: CharacterFaction.wudang,
      role: CharacterRole.support,
      element: CharacterElement.wind,
      modelPath: 'assets/models/莫问天.glb',
      baseHealth: 90,
      baseAttack: 22,
      baseDefense: 18,
      baseSpeed: 25,
      description: '武当派掌门，太极剑法已臻化境，以柔克刚，后发制人。',
      skills: ['太极拳', '太极剑', '梯云纵'],
    ),
    Character(
      id: 'char_004',
      name: '殷无痕',
      title: '锦衣卫统领',
      faction: CharacterFaction.jinyiwei,
      role: CharacterRole.assassin,
      element: CharacterElement.dark,
      modelPath: 'assets/models/殷无痕.glb',
      baseHealth: 80,
      baseAttack: 30,
      baseDefense: 12,
      baseSpeed: 28,
      description: '锦衣卫统领，来去如风，取人首级于无形，江湖人称"无痕鬼面"。',
      skills: ['绣春刀', '鬼影步', '催心掌'],
    ),
    Character(
      id: 'char_005',
      name: '蓝若蝶',
      title: '五毒仙子',
      faction: CharacterFaction.wudu,
      role: CharacterRole.dps,
      element: CharacterElement.wind,
      modelPath: 'assets/models/蓝若蝶.glb',
      baseHealth: 70,
      baseAttack: 35,
      baseDefense: 8,
      baseSpeed: 22,
      description: '五毒教圣女，擅用毒蛊，翩翩起舞间取人性命，艳若桃李毒如蛇蝎。',
      skills: ['五毒针', '灵蛊术', '蝶舞迷香'],
    ),
    Character(
      id: 'char_006',
      name: '陆承风',
      title: '丐帮帮主',
      faction: CharacterFaction.gaibang,
      role: CharacterRole.allRounder,
      element: CharacterElement.neutral,
      modelPath: 'assets/models/陆承风.glb',
      baseHealth: 110,
      baseAttack: 24,
      baseDefense: 16,
      baseSpeed: 20,
      description: '丐帮帮主，打狗棒法独步天下，降龙十八掌威震武林豪杰。',
      skills: ['降龙十八掌', '打狗棒法', '逍遥游'],
    ),
  ];

  static Character? getById(String id) {
    try {
      return allCharacters.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  static Character? getByName(String name) {
    try {
      return allCharacters.firstWhere(
        (c) => c.name == name || c.name.contains(name),
      );
    } catch (_) {
      return null;
    }
  }
}
