import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/character.dart';
import '../../widgets/character_model_viewer.dart';

/// Character detail screen — shows character portrait, 3D model, and stats.
class CharacterDetailsScreen extends StatelessWidget {
  final Character character;

  const CharacterDetailsScreen({
    super.key,
    required this.character,
  });

  /// Navigate to character detail from a character object.
  static void navigateTo(BuildContext context, Character character) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CharacterDetailsScreen(character: character),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 80,
            pinned: true,
            backgroundColor: AppTheme.primaryDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                character.name,
                style: const TextStyle(
                  color: AppTheme.textGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              centerTitle: true,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline, color: AppTheme.textSecondary),
                onPressed: () => _showDescriptionDialog(context),
              ),
            ],
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Faction + Role + Element badges
                _buildBadgesRow(),
                const SizedBox(height: 20),

                // 3D Model Viewer
                CharacterModelViewer(
                  character: character,
                  height: 360,
                  autoRotate: true,
                  showControls: true,
                ),
                const SizedBox(height: 24),

                // Stats card
                _buildStatsCard(),
                const SizedBox(height: 16),

                // Skills card
                _buildSkillsCard(),
                const SizedBox(height: 24),

                // Description card
                _buildDescriptionCard(),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildBadge(
          label: character.faction.cn,
          icon: Icons.shield,
          color: _getFactionColor(character.faction),
        ),
        _buildBadge(
          label: character.role.cn,
          icon: _getRoleIcon(character.role),
          color: _getRoleColor(character.role),
        ),
        _buildBadge(
          label: character.element.cn,
          icon: _getElementIcon(character.element),
          color: _getElementColor(character.element),
        ),
      ],
    );
  }

  Widget _buildBadge({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: AppTheme.accentGold, size: 20),
              SizedBox(width: 8),
              Text(
                '基础属性',
                style: TextStyle(
                  color: AppTheme.textGold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatRow('生命', character.baseHealth, AppTheme.healthRed,
              Icons.favorite),
          const SizedBox(height: 12),
          _buildStatRow('攻击', character.baseAttack, AppTheme.accentCosmic,
              Icons.bolt),
          const SizedBox(height: 12),
          _buildStatRow('防御', character.baseDefense, Colors.blueGrey,
              Icons.shield),
          const SizedBox(height: 12),
          _buildStatRow(
              '速度', character.baseSpeed, Colors.green, Icons.speed),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int value, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (value / 200).clamp(0.05, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 36,
          child: Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: AppTheme.accentGold, size: 20),
              SizedBox(width: 8),
              Text(
                '武学技能',
                style: TextStyle(
                  color: AppTheme.textGold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: character.skills.map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentCosmic.withOpacity(0.3),
                      AppTheme.accentGold.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accentGold.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  skill,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.menu_book, color: AppTheme.accentGold, size: 20),
              SizedBox(width: 8),
              Text(
                '人物简介',
                style: TextStyle(
                  color: AppTheme.textGold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            character.description.isNotEmpty
                ? character.description
                : '暂无描述',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  void _showDescriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.cardBorder),
        ),
        title: Text(
          character.title,
          style: const TextStyle(
            color: AppTheme.textGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          character.description,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '关闭',
              style: TextStyle(color: AppTheme.accentGold),
            ),
          ),
        ],
      ),
    );
  }

  // Color helpers
  Color _getFactionColor(CharacterFaction f) {
    switch (f) {
      case CharacterFaction.mingjiao:
        return Colors.orange;
      case CharacterFaction.shaolin:
        return Colors.amber;
      case CharacterFaction.wudang:
        return Colors.blue;
      case CharacterFaction.jinyiwei:
        return Colors.deepPurple;
      case CharacterFaction.wudu:
        return Colors.green;
      case CharacterFaction.gaibang:
        return Colors.brown;
    }
  }

  Color _getRoleColor(CharacterRole r) {
    switch (r) {
      case CharacterRole.tank:
        return Colors.blueGrey;
      case CharacterRole.dps:
        return Colors.red;
      case CharacterRole.support:
        return Colors.blue;
      case CharacterRole.healer:
        return Colors.green;
      case CharacterRole.assassin:
        return Colors.deepPurple;
      case CharacterRole.allRounder:
        return AppTheme.accentGold;
    }
  }

  Color _getElementColor(CharacterElement e) {
    switch (e) {
      case CharacterElement.fire:
        return Colors.orange;
      case CharacterElement.water:
        return Colors.blue;
      case CharacterElement.wind:
        return Colors.teal;
      case CharacterElement.earth:
        return Colors.brown;
      case CharacterElement.thunder:
        return Colors.purple;
      case CharacterElement.dark:
        return Colors.deepPurple;
      case CharacterElement.light:
        return Colors.amber;
      case CharacterElement.neutral:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(CharacterRole r) {
    switch (r) {
      case CharacterRole.tank:
        return Icons.shield;
      case CharacterRole.dps:
        return Icons.bolt;
      case CharacterRole.support:
        return Icons.support;
      case CharacterRole.healer:
        return Icons.healing;
      case CharacterRole.assassin:
        return Icons.flash_on;
      case CharacterRole.allRounder:
        return Icons.star;
    }
  }

  IconData _getElementIcon(CharacterElement e) {
    switch (e) {
      case CharacterElement.fire:
        return Icons.local_fire_department;
      case CharacterElement.water:
        return Icons.water_drop;
      case CharacterElement.wind:
        return Icons.air;
      case CharacterElement.earth:
        return Icons.terrain;
      case CharacterElement.thunder:
        return Icons.flash_on;
      case CharacterElement.dark:
        return Icons.dark_mode;
      case CharacterElement.light:
        return Icons.wb_sunny;
      case CharacterElement.neutral:
        return Icons.circle;
    }
  }
}
