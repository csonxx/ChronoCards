import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/martial_arts_provider.dart';
import '../../../domain/combat/martial_arts_system.dart';

/// 武学面板 - 显示和管理角色武学技能
class MartialArtsScreen extends StatelessWidget {
  const MartialArtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MartialArtsProvider(),
      child: const _MartialArtsScreenContent(),
    );
  }
}

class _MartialArtsScreenContent extends StatelessWidget {
  const _MartialArtsScreenContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('武学修炼'),
        backgroundColor: const Color(0xFF1a1a2e),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF16213e),
      body: Consumer<MartialArtsProvider>(
        builder: (context, martialArts, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 当前激活武学
                _buildActiveSkills(context, martialArts),
                const SizedBox(height: 24),
                // 技能树三路线
                _buildSkillTree(context, martialArts),
                const SizedBox(height: 24),
                // 已学武学列表
                _buildLearnedSkills(context, martialArts),
                const SizedBox(height: 24),
                // 学习新武学按钮
                _buildLearnSection(context, martialArts),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveSkills(BuildContext context, MartialArtsProvider martialArts) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0f3460),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚡ 当前激活',
            style: TextStyle(
              color: Colors.purple,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActiveSkillSlot(
                '内功',
                '🧘',
                martialArts.activeInnerGong,
                    () => _showSkillSelectDialog(context, martialArts, MartialArtType.innerGong),
              ),
              _buildActiveSkillSlot(
                '外功',
                '👊',
                martialArts.activeOuterGong,
                    () => _showSkillSelectDialog(context, martialArts, MartialArtType.outerGong),
              ),
              _buildActiveSkillSlot(
                '轻功',
                '💨',
                martialArts.activeLightSkill,
                    () => _showSkillSelectDialog(context, martialArts, MartialArtType.lightSkill),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSkillSlot(
      String label,
      String emoji,
      MartialSkill? skill,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              skill?.name ?? '未选择',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillTree(BuildContext context, MartialArtsProvider martialArts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🌳 技能树',
          style: TextStyle(
            color: Colors.amber,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        // 三路线横向显示
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSkillPath(
                context,
                '内功',
                '🧘',
                Colors.cyan,
                MartialArtType.innerGong,
                martialArts,
              ),
              const SizedBox(width: 12),
              _buildSkillPath(
                context,
                '外功',
                '👊',
                Colors.red,
                MartialArtType.outerGong,
                martialArts,
              ),
              const SizedBox(width: 12),
              _buildSkillPath(
                context,
                '轻功',
                '💨',
                Colors.green,
                MartialArtType.lightSkill,
                martialArts,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkillPath(
      BuildContext context,
      String name,
      String emoji,
      Color color,
      MartialArtType type,
      MartialArtsProvider martialArts,
      ) {
    final nodes = martialArts.getNodesForPath(type);
    final progress = martialArts.skillTreeProgress[type] ?? 0;

    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                name,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '进度: $progress/${nodes.length}',
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
          const SizedBox(height: 12),
          // 技能节点列表
          ...List.generate(nodes.length, (index) {
            final node = nodes[index];
            final isUnlocked = index < progress;
            final isLearned = martialArts.hasLearned(node.skillId);

            return _buildSkillNode(
              node,
              isUnlocked,
              isLearned,
              color,
              martialArts,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSkillNode(
      SkillTreeNode node,
      bool isUnlocked,
      bool isLearned,
      Color color,
      MartialArtsProvider martialArts,
      ) {
    return GestureDetector(
      onTap: isUnlocked && !isLearned
          ? () => martialArts.learnSkill(
        martialArts.availableSkills.firstWhere((s) => s.id == node.skillId),
      )
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isLearned
              ? color.withOpacity(0.2)
              : isUnlocked
              ? const Color(0xFF0f3460)
              : const Color(0xFF2a2a4a),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isLearned
                ? color
                : isUnlocked
                ? color.withOpacity(0.5)
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLearned ? color : isUnlocked ? Colors.grey : Colors.grey.withOpacity(0.3),
              ),
              child: Center(
                child: isLearned
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : isUnlocked
                    ? Text(
                  '${node.levelRequired}',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                )
                    : const Icon(Icons.lock, size: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.name,
                    style: TextStyle(
                      color: isUnlocked ? Colors.white : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Lv.${node.levelRequired}',
                    style: TextStyle(
                      color: isUnlocked ? Colors.grey : Colors.grey.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (isLearned)
              Text(
                '已学',
                style: TextStyle(color: color, fontSize: 10),
              )
            else if (isUnlocked)
              const Text(
                '点击学习',
                style: TextStyle(color: Colors.green, fontSize: 9),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearnedSkills(BuildContext context, MartialArtsProvider martialArts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📜 已学武学',
          style: TextStyle(
            color: Colors.amber,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (martialArts.learnedSkills.isEmpty)
          const Center(
            child: Text(
              '尚未学习任何武学',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ...martialArts.learnedSkills.map((skill) => _buildLearnedSkillCard(skill, martialArts)),
      ],
    );
  }

  Widget _buildLearnedSkillCard(MartialSkill skill, MartialArtsProvider martialArts) {
    final isActive = martialArts.activeInnerGongId == skill.id ||
        martialArts.activeOuterGongId == skill.id ||
        martialArts.activeLightSkillId == skill.id;

    final typeColor = _getTypeColor(skill.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? typeColor : Colors.grey.withOpacity(0.3),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                _getTypeEmoji(skill.type),
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      skill.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (skill.isEskill)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('E', style: TextStyle(color: Colors.blue, fontSize: 10)),
                      ),
                    if (skill.isQskill)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Q', style: TextStyle(color: Colors.purple, fontSize: 10)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  skill.description,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
                const SizedBox(height: 4),
                _buildSkillStats(skill),
              ],
            ),
          ),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '已激活',
                style: TextStyle(color: typeColor, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSkillStats(MartialSkill skill) {
    final stats = <String>[];
    if (skill.damage > 0) stats.add('伤害: ${skill.damage}');
    if (skill.shieldValue > 0) stats.add('护盾: ${skill.shieldValue}');
    if (skill.qiCost > 0) stats.add('消耗: ${skill.qiCost}气');
    if (skill.element != ElementType.none) stats.add('属性: ${_getElementName(skill.element)}');

    return Wrap(
      spacing: 8,
      children: stats.map((s) => Text(
        s,
        style: const TextStyle(color: Colors.amber, fontSize: 10),
      )).toList(),
    );
  }

  Widget _buildLearnSection(BuildContext context, MartialArtsProvider martialArts) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0f3460),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📚 学习新武学',
            style: TextStyle(
              color: Colors.green,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _showLearnDialog(context, martialArts),
            icon: const Icon(Icons.school, color: Colors.white),
            label: const Text('从技能库学习'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showLearnDialog(BuildContext context, MartialArtsProvider martialArts) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('选择武学', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: martialArts.availableSkills.length,
            itemBuilder: (context, index) {
              final skill = martialArts.availableSkills[index];
              final isLearned = martialArts.hasLearned(skill.id);
              final canLearn = martialArts.canLearn(skill);

              return ListTile(
                leading: Text(_getTypeEmoji(skill.type), style: const TextStyle(fontSize: 24)),
                title: Text(
                  skill.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  skill.description,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                trailing: isLearned
                    ? const Text('已学', style: TextStyle(color: Colors.green))
                    : canLearn
                    ? TextButton(
                  onPressed: () {
                    martialArts.learnSkill(skill);
                    Navigator.pop(context);
                  },
                  child: const Text('学习'),
                )
                    : Text(
                  '等级不足',
                  style: TextStyle(color: Colors.red.withOpacity(0.7), fontSize: 12),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showSkillSelectDialog(
      BuildContext context,
      MartialArtsProvider martialArts,
      MartialArtType type,
      ) {
    final skills = martialArts.learnedSkills.where((s) => s.type == type).toList();
    final color = _getTypeColor(type);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Text(
          '选择${_getTypeName(type)}',
          style: TextStyle(color: color),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: skills.isEmpty
              ? const Center(
            child: Text(
              '尚未学习该类型武学',
              style: TextStyle(color: Colors.grey),
            ),
          )
              : ListView.builder(
            shrinkWrap: true,
            itemCount: skills.length,
            itemBuilder: (context, index) {
              final skill = skills[index];
              final isActive = martialArts.activeInnerGongId == skill.id ||
                  martialArts.activeOuterGongId == skill.id ||
                  martialArts.activeLightSkillId == skill.id;

              return ListTile(
                leading: Text(_getTypeEmoji(skill.type), style: const TextStyle(fontSize: 24)),
                title: Text(skill.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text(skill.description, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: isActive
                    ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('已激活', style: TextStyle(color: color, fontSize: 12)),
                )
                    : null,
                onTap: () {
                  switch (type) {
                    case MartialArtType.innerGong:
                      martialArts.setActiveInnerGong(skill.id);
                      break;
                    case MartialArtType.outerGong:
                      martialArts.setActiveOuterGong(skill.id);
                      break;
                    case MartialArtType.lightSkill:
                      martialArts.setActiveLightSkill(skill.id);
                      break;
                  }
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(MartialArtType type) {
    switch (type) {
      case MartialArtType.innerGong:
        return Colors.cyan;
      case MartialArtType.outerGong:
        return Colors.red;
      case MartialArtType.lightSkill:
        return Colors.green;
    }
  }

  String _getTypeEmoji(MartialArtType type) {
    switch (type) {
      case MartialArtType.innerGong:
        return '🧘';
      case MartialArtType.outerGong:
        return '👊';
      case MartialArtType.lightSkill:
        return '💨';
    }
  }

  String _getTypeName(MartialArtType type) {
    switch (type) {
      case MartialArtType.innerGong:
        return '内功';
      case MartialArtType.outerGong:
        return '外功';
      case MartialArtType.lightSkill:
        return '轻功';
    }
  }

  String _getElementName(ElementType element) {
    switch (element) {
      case ElementType.fire:
        return '火';
      case ElementType.water:
        return '水';
      case ElementType.thunder:
        return '雷';
      case ElementType.ice:
        return '冰';
      case ElementType.wind:
        return '风';
      case ElementType.earth:
        return '土';
      case ElementType.light:
        return '光';
      case ElementType.dark:
        return '暗';
      default:
        return '无';
    }
  }
}
