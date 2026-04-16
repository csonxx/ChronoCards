/// 敌人数据
/// 来源：memory/arng_enemies_content.md

class EnemyData {
  final String id;
  final String name;
  final int hp;
  final int attack;
  final int defense;
  final double moveSpeed;
  final String attackRange;
  final int attackCd;
  final List<String> skills;
  final int defeatExp;
  final int defeatGold;
  final String? description;
  final bool isElite;
  final bool isBoss;

  const EnemyData({
    required this.id,
    required this.name,
    required this.hp,
    required this.attack,
    this.defense = 0,
    this.moveSpeed = 2.5,
    this.attackRange = '近身',
    this.attackCd = 1000,
    this.skills = const [],
    this.defeatExp = 20,
    this.defeatGold = 15,
    this.description,
    this.isElite = false,
    this.isBoss = false,
  });
}

const ENEMIES = {
  // ==================== 普通敌人 ====================
  'common_bandit': EnemyData(
    id: 'common_bandit',
    name: '山贼喽啰',
    hp: 120,
    attack: 12,
    defense: 3,
    moveSpeed: 2.5,
    attackRange: '近身（1.2m）',
    attackCd: 1200,
    skills: ['普通劈砍', '重砍'],
    defeatExp: 20,
    defeatGold: 15,
    description: '落草黑风寨的底层喽啰，使一把生锈朴刀，欺软怕硬。',
  ),
  'wudang_apprentice': EnemyData(
    id: 'wudang_apprentice',
    name: '武当弃徒',
    hp: 180,
    attack: 16,
    defense: 6,
    moveSpeed: 2.8,
    attackRange: '中距离（1.8m，剑气）',
    attackCd: 1000,
    skills: ['武当长拳', '太极推手'],
    defeatExp: 35,
    defeatGold: 28,
    description: '被逐出武当的落魄弟子，流落苏州城，靠收保护费为生。身法尚存武当余韵。',
  ),
  'beggar_sect_member': EnemyData(
    id: 'beggar_sect_member',
    name: '丐帮污衣弟子',
    hp: 100,
    attack: 10,
    defense: 2,
    moveSpeed: 3.0,
    attackRange: '近身+远程（3.5m暗器）',
    attackCd: 800,
    skills: ['打狗棒法·戳', '飞针'],
    defeatExp: 25,
    defeatGold: 20,
    description: '丐帮底层弟子，虽穷却精通游斗之术。惹上麻烦会呼叫同伴。',
  ),
  'emei_disciple': EnemyData(
    id: 'emei_disciple',
    name: '峨眉俗家弟子',
    hp: 150,
    attack: 14,
    defense: 5,
    moveSpeed: 2.6,
    attackRange: '中距离（2.0m）',
    attackCd: 1100,
    skills: ['峨眉掌法·日见', '金顶柔劲'],
    defeatExp: 30,
    defeatGold: 25,
    description: '峨眉派俗家女弟子，下山历练，与苏州本地势力时有冲突。实战中会优先自保。',
  ),
  'local_thug': EnemyData(
    id: 'local_thug',
    name: '城中地痞',
    hp: 200,
    attack: 18,
    defense: 8,
    moveSpeed: 2.2,
    attackRange: '近身（1.1m）',
    attackCd: 1400,
    skills: ['流氓拳', '石灰粉致盲'],
    defeatExp: 22,
    defeatGold: 35,
    description: '苏州城本地帮派的小喽啰，横行菜市场一带。欺压百姓，但在真正的武林人士面前不堪一击。',
  ),

  // ==================== 精英敌人 ====================
  'elite_iron_palm_chen': EnemyData(
    id: 'elite_iron_palm_chen',
    name: '"铁掌" 陈二',
    hp: 800,
    attack: 28,
    defense: 12,
    moveSpeed: 2.8,
    attackRange: '近身（1.5m）',
    attackCd: 900,
    skills: ['铁掌·开碑手', '铁掌·烈焰印', '裂地脚'],
    defeatExp: 150,
    defeatGold: 120,
    description: '自学成才的铁砂掌练家子，在城郊码头一带收过路费。掌力刚猛，可裂石开碑。性格暴戾，输打赢要。',
    isElite: true,
  ),
  'elite_emei_heretic': EnemyData(
    id: 'elite_emei_heretic',
    name: '峨眉叛徒·静虚师太',
    hp: 650,
    attack: 22,
    defense: 8,
    moveSpeed: 3.0,
    attackRange: '中距离（2.5m）',
    attackCd: 800,
    skills: ['峨眉刺', '清心普善咒', '金顶飞虹', '落叶飘'],
    defeatExp: 180,
    defeatGold: 150,
    description: '原本是峨眉派正经师太，因私修禁功被逐出师门，流落江湖后性情大变。她用峨眉正宗轻功游斗，利用法阵持续回复是最大难点。',
    isElite: true,
  ),

  // ==================== Boss ====================
  'boss_ouyang_xiong': EnemyData(
    id: 'boss_ouyang_xiong',
    name: '"血手人屠" 欧阳雄',
    hp: 5000,
    attack: 35,
    defense: 18,
    moveSpeed: 3.2,
    attackRange: '近身+中距离（3m）',
    attackCd: 700,
    skills: [
      '七星拳', '借力打力', '卸力横移',
      '欧阳剑法·横贯东西', '欧阳剑法·一点寒光', '血刀反噬', '召唤武当弃徒',
      '血手印·开膛', '血手印·裂心', '血影步', '血爆', '血毒领域',
      '血手印·瞬影', '血手印·绝命', '血毒自噬', '最后的咆哮',
    ],
    defeatExp: 500,
    defeatGold: 300,
    description: '欧阳世家昔日家主，武学天才。十年前家族被朝廷以"通敌叛国"罪名满门抄斩，唯独他一人逃脱。此后隐姓埋名，暗中收编苏州城黑道势力，成为地下皇帝。',
    isBoss: true,
  ),
};
