import 'package:flutter/foundation.dart';
import '../../domain/combat/martial_arts_system.dart';

/// MartialArtsProvider - 武学技能系统状态管理
class MartialArtsProvider extends ChangeNotifier {
  // 已学习的技能列表
  final List<MartialSkill> _learnedSkills = [];

  // 当前激活的技能
  String? _activeInnerGongId;
  String? _activeOuterGongId;
  String? _activeLightSkillId;

  // 技能树解锁状态 (路线 -> 等级)
  final Map<MartialArtType, int> _skillTreeProgress = {
    MartialArtType.innerGong: 0,
    MartialArtType.outerGong: 0,
    MartialArtType.lightSkill: 0,
  };

  // 是否加载中
  bool _isLoading = false;

  // 模拟可学习的技能库
  final List<MartialSkill> _availableSkills = [];

  // 模拟技能树节点
  final Map<MartialArtType, List<SkillTreeNode>> _skillTreeNodes = {};

  MartialArtsProvider() {
    _loadMockData();
  }

  // Getters
  List<MartialSkill> get learnedSkills => _learnedSkills;
  String? get activeInnerGongId => _activeInnerGongId;
  String? get activeOuterGongId => _activeOuterGongId;
  String? get activeLightSkillId => _activeLightSkillId;
  Map<MartialArtType, int> get skillTreeProgress => _skillTreeProgress;
  bool get isLoading => _isLoading;
  List<MartialSkill> get availableSkills => _availableSkills;
  Map<MartialArtType, List<SkillTreeNode>> get skillTreeNodes => _skillTreeNodes;

  /// 获取内功技能
  List<MartialSkill> get innerGongSkills =>
      _learnedSkills.where((s) => s.type == MartialArtType.innerGong).toList();

  /// 获取外功技能
  List<MartialSkill> get outerGongSkills =>
      _learnedSkills.where((s) => s.type == MartialArtType.outerGong).toList();

  /// 获取轻功技能
  List<MartialSkill> get lightSkills =>
      _learnedSkills.where((s) => s.type == MartialArtType.lightSkill).toList();

  /// 获取当前激活的内功
  MartialSkill? get activeInnerGong {
    if (_activeInnerGongId == null) return null;
    return _learnedSkills.firstWhere(
      (s) => s.id == _activeInnerGongId,
      orElse: () => const MartialSkill(id: ''),
    );
  }

  /// 获取当前激活的外功
  MartialSkill? get activeOuterGong {
    if (_activeOuterGongId == null) return null;
    return _learnedSkills.firstWhere(
      (s) => s.id == _activeOuterGongId,
      orElse: () => const MartialSkill(id: ''),
    );
  }

  /// 获取当前激活的轻功
  MartialSkill? get activeLightSkill {
    if (_activeLightSkillId == null) return null;
    return _learnedSkills.firstWhere(
      (s) => s.id == _activeLightSkillId,
      orElse: () => const MartialSkill(id: ''),
    );
  }

  /// 设置激活的内功
  void setActiveInnerGong(String? skillId) {
    _activeInnerGongId = skillId;
    notifyListeners();
  }

  /// 设置激活的外功
  void setActiveOuterGong(String? skillId) {
    _activeOuterGongId = skillId;
    notifyListeners();
  }

  /// 设置激活的轻功
  void setActiveLightSkill(String? skillId) {
    _activeLightSkillId = skillId;
    notifyListeners();
  }

  /// 学习新技能
  void learnSkill(MartialSkill skill) {
    if (!_learnedSkills.any((s) => s.id == skill.id)) {
      _learnedSkills.add(skill);
      notifyListeners();
    }
  }

  /// 遗忘技能
  void forgetSkill(String skillId) {
    _learnedSkills.removeWhere((s) => s.id == skillId);
    if (_activeInnerGongId == skillId) _activeInnerGongId = null;
    if (_activeOuterGongId == skillId) _activeOuterGongId = null;
    if (_activeLightSkillId == skillId) _activeLightSkillId = null;
    notifyListeners();
  }

  /// 检查是否已学习某技能
  bool hasLearned(String skillId) {
    return _learnedSkills.any((s) => s.id == skillId);
  }

  /// 检查技能是否可学习
  bool canLearn(MartialSkill skill) {
    if (hasLearned(skill.id)) return false;
    if (skill.levelRequired > _getPlayerLevel()) return false;
    return true;
  }

  /// 获取玩家等级 (模拟)
  int _getPlayerLevel() => 5;

  /// 获取指定路线的技能树节点
  List<SkillTreeNode> getNodesForPath(MartialArtType type) {
    return _skillTreeNodes[type] ?? [];
  }

  /// 推进技能树进度
  void unlockSkillTreeNode(MartialArtType type, int nodeIndex) {
    if (_skillTreeProgress[type]! < nodeIndex + 1) {
      _skillTreeProgress[type] = nodeIndex + 1;
      notifyListeners();
    }
  }

  /// 加载Mock数据
  void _loadMockData() {
    // 预设可学习技能
    _availableSkills.addAll([
      // 内功路线
      const MartialSkill(
        id: 'inner_qigong_shield',
        name: '气功罩',
        description: '凝聚内力形成护盾，抵挡伤害',
        type: MartialArtType.innerGong,
        target: SkillTarget.self,
        qiCost: 15,
        shieldValue: 30,
        cooldownMs: 8000,
        isQskill: true,
        element: ElementType.none,
      ),
      const MartialSkill(
        id: 'inner_flame_heart',
        name: '火焰心法',
        description: '提升火属性抗性与伤害',
        type: MartialArtType.innerGong,
        target: SkillTarget.self,
        qiCost: 0,
        cooldownMs: 0,
        isEskill: true,
        element: ElementType.fire,
      ),
      const MartialSkill(
        id: 'inner_ice_will',
        name: '寒冰意志',
        description: '冰属性护体，大幅提升防御',
        type: MartialArtType.innerGong,
        target: SkillTarget.self,
        qiCost: 20,
        shieldValue: 50,
        cooldownMs: 10000,
        isQskill: true,
        element: ElementType.ice,
      ),
      // 外功路线
      const MartialSkill(
        id: 'outer_punch_rush',
        name: '冲拳',
        description: '快速冲刺出拳，造成单体伤害',
        type: MartialArtType.outerGong,
        target: SkillTarget.enemy,
        qiCost: 10,
        damage: 25,
        staggerValue: 10,
        cooldownMs: 1500,
        isEskill: true,
        element: ElementType.none,
      ),
      const MartialSkill(
        id: 'outer_fire_palm',
        name: '烈焰掌',
        description: '注入火元素，造成灼烧伤害',
        type: MartialArtType.outerGong,
        target: SkillTarget.enemy,
        qiCost: 20,
        damage: 40,
        staggerValue: 5,
        cooldownMs: 5000,
        isQskill: true,
        element: ElementType.fire,
        breaksArmor: true,
      ),
      const MartialSkill(
        id: 'outer_thunder_fist',
        name: '雷霆拳',
        description: '雷属性高伤害技能',
        type: MartialArtType.outerGong,
        target: SkillTarget.enemy,
        qiCost: 25,
        damage: 55,
        staggerValue: 15,
        cooldownMs: 6000,
        isQskill: true,
        element: ElementType.thunder,
      ),
      // 轻功路线
      const MartialSkill(
        id: 'light_swallow_step',
        name: '燕回步',
        description: '轻盈闪避，获得短暂无敌帧',
        type: MartialArtType.lightSkill,
        target: SkillTarget.self,
        qiCost: 8,
        staminaCost: 15,
        cooldownMs: 3000,
        isEskill: true,
      ),
      const MartialSkill(
        id: 'light_cloud_walk',
        name: '云中漫步',
        description: '大幅提升移动速度与闪避率',
        type: MartialArtType.lightSkill,
        target: SkillTarget.self,
        qiCost: 12,
        staminaCost: 20,
        cooldownMs: 5000,
        isQskill: true,
      ),
      const MartialSkill(
        id: 'light_ghost_step',
        name: '鬼影步',
        description: '瞬间移动至敌人身后',
        type: MartialArtType.lightSkill,
        target: SkillTarget.enemy,
        qiCost: 18,
        staminaCost: 25,
        damage: 15,
        cooldownMs: 4000,
        isEskill: true,
      ),
    ]);

    // 预设技能树节点
    _skillTreeNodes[MartialArtType.innerGong] = [
      const SkillTreeNode(
        id: 'inner_node_1',
        name: '气功入门',
        description: '学习基础气功',
        type: MartialArtType.innerGong,
        levelRequired: 1,
        skillId: 'inner_qigong_shield',
      ),
      const SkillTreeNode(
        id: 'inner_node_2',
        name: '火焰心法',
        description: '掌握火属性内功',
        type: MartialArtType.innerGong,
        levelRequired: 3,
        skillId: 'inner_flame_heart',
      ),
      const SkillTreeNode(
        id: 'inner_node_3',
        name: '寒冰意志',
        description: '修练寒冰内功',
        type: MartialArtType.innerGong,
        levelRequired: 6,
        skillId: 'inner_ice_will',
      ),
    ];

    _skillTreeNodes[MartialArtType.outerGong] = [
      const SkillTreeNode(
        id: 'outer_node_1',
        name: '冲拳',
        description: '基础外功招式',
        type: MartialArtType.outerGong,
        levelRequired: 1,
        skillId: 'outer_punch_rush',
      ),
      const SkillTreeNode(
        id: 'outer_node_2',
        name: '烈焰掌',
        description: '火属性外功',
        type: MartialArtType.outerGong,
        levelRequired: 4,
        skillId: 'outer_fire_palm',
      ),
      const SkillTreeNode(
        id: 'outer_node_3',
        name: '雷霆拳',
        description: '雷属性绝学',
        type: MartialArtType.outerGong,
        levelRequired: 7,
        skillId: 'outer_thunder_fist',
      ),
    ];

    _skillTreeNodes[MartialArtType.lightSkill] = [
      const SkillTreeNode(
        id: 'light_node_1',
        name: '燕回步',
        description: '基础轻功身法',
        type: MartialArtType.lightSkill,
        levelRequired: 1,
        skillId: 'light_swallow_step',
      ),
      const SkillTreeNode(
        id: 'light_node_2',
        name: '云中漫步',
        description: '进阶轻功',
        type: MartialArtType.lightSkill,
        levelRequired: 3,
        skillId: 'light_cloud_walk',
      ),
      const SkillTreeNode(
        id: 'light_node_3',
        name: '鬼影步',
        description: '高级轻功绝技',
        type: MartialArtType.lightSkill,
        levelRequired: 5,
        skillId: 'light_ghost_step',
      ),
    ];

    // 默认学习几个技能
    learnSkill(_availableSkills.firstWhere((s) => s.id == 'inner_qigong_shield'));
    learnSkill(_availableSkills.firstWhere((s) => s.id == 'outer_punch_rush'));
    learnSkill(_availableSkills.firstWhere((s) => s.id == 'light_swallow_step'));

    // 设置默认激活
    _activeInnerGongId = 'inner_qigong_shield';
    _activeOuterGongId = 'outer_punch_rush';
    _activeLightSkillId = 'light_swallow_step';

    // 解锁第一层技能树
    _skillTreeProgress[MartialArtType.innerGong] = 1;
    _skillTreeProgress[MartialArtType.outerGong] = 1;
    _skillTreeProgress[MartialArtType.lightSkill] = 1;
  }
}

/// 技能树节点
class SkillTreeNode {
  final String id;
  final String name;
  final String description;
  final MartialArtType type;
  final int levelRequired;
  final String skillId;

  const SkillTreeNode({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.levelRequired,
    required this.skillId,
  });
}
