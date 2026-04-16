import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// 阵营数据模型
class Faction {
  final String id;
  final String name;
  final String description;
  final String icon;
  final Color color;
  final FactionRelationStatus relationStatus;
  final int memberCount;

  const Faction({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.relationStatus = FactionRelationStatus.none,
    this.memberCount = 0,
  });
}

enum FactionRelationStatus {
  none,       // 未加入
  hostile,   // 敌对
  neutral,   // 中立
  friendly,  // 友好
  member,    // 已加入
}

/// 阵营列表页面
class FactionListScreen extends StatefulWidget {
  const FactionListScreen({super.key});

  @override
  State<FactionListScreen> createState() => _FactionListScreenState();
}

class _FactionListScreenState extends State<FactionListScreen> {
  // 6大阵营数据
  final List<Faction> _factions = [
    const Faction(
      id: 'mingjiao',
      name: '明教',
      description: '波斯传入的圣火教派，以火焰为信仰，追求光明与正义',
      icon: '🔥',
      color: Color(0xFFFF6B35),
      memberCount: 1247,
    ),
    const Faction(
      id: 'shaolin',
      name: '少林寺',
      description: '天下武学之源，以棍法闻名，注重禅武合一',
      icon: '🏯',
      color: Color(0xFFFFD700),
      memberCount: 2356,
    ),
    const Faction(
      id: 'wudang',
      name: '武当派',
      description: '以内功见长，剑法无双，道家思想为指导',
      icon: '⚔️',
      color: Color(0xFF4ECDC4),
      memberCount: 1823,
    ),
    const Faction(
      id: 'jinyiwei',
      name: '锦衣卫',
      description: '皇室直属情报机构，武功高强，执法无情',
      icon: '🦅',
      color: Color(0xFF8B0000),
      memberCount: 856,
    ),
    const Faction(
      id: 'wudu',
      name: '五毒教',
      description: '擅长用毒与蛊术，神秘莫测，行事诡谲',
      icon: '🐍',
      color: Color(0xFF9ACD32),
      memberCount: 567,
    ),
    const Faction(
      id: 'gaibang',
      name: '丐帮',
      description: '天下第一大帮，打狗棒法与降龙十八掌名震江湖',
      icon: '🍺',
      color: Color(0xFFCD853F),
      memberCount: 3456,
    ),
  ];

  String? _playerFactionId; // 当前玩家所属阵营

  @override
  void initState() {
    super.initState();
    // Placeholder: faction data loaded from backend // _loadPlayerFaction();
    // _loadPlayerFaction();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text(
          '江湖势力',
          style: TextStyle(
            color: AppTheme.textGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryMid,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
            onPressed: () {
              // Placeholder: refresh faction data
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 势力总览
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryMid,
                  AppTheme.primaryLight.withOpacity(0.5),
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('势力总数', '${_factions.length}', Icons.groups),
                _buildStatItem('江湖总人数', '${_factions.fold(0, (sum, f) => sum + f.memberCount)}', Icons.people),
                _buildStatItem('我的势力', _playerFactionId != null ? '1' : '0', Icons.star),
              ],
            ),
          ),
          // 阵营列表
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _factions.length,
              itemBuilder: (context, index) {
                final faction = _factions[index];
                return _buildFactionCard(faction);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.accentGold, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textGold,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildFactionCard(Faction faction) {
    final isJoined = _playerFactionId == faction.id;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          '/faction_detail',
          arguments: faction,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              faction.color.withOpacity(0.2),
              faction.color.withOpacity(0.05),
              AppTheme.cardBackground,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isJoined ? faction.color : faction.color.withOpacity(0.3),
            width: isJoined ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: faction.color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 阵营图标
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: faction.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: faction.color.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    faction.icon,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 阵营信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          faction.name,
                          style: TextStyle(
                            color: faction.color,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isJoined) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: faction.color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '已加入',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      faction.description,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${faction.memberCount} 人',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 16),
                        _buildRelationBadge(faction, isJoined),
                      ],
                    ),
                  ],
                ),
              ),
              // 箭头
              Icon(
                Icons.chevron_right,
                color: faction.color.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRelationBadge(Faction faction, bool isJoined) {
    if (isJoined) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            '成员',
            style: TextStyle(
              color: Colors.green,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    // 根据关系状态显示不同标签
    final status = faction.relationStatus;
    Color color;
    String text;

    switch (status) {
      case FactionRelationStatus.hostile:
        color = Colors.red;
        text = '敌对';
        break;
      case FactionRelationStatus.neutral:
        color = Colors.grey;
        text = '中立';
        break;
      case FactionRelationStatus.friendly:
        color = Colors.blue;
        text = '友好';
        break;
      default:
        color = AppTheme.textSecondary;
        text = '未接触';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
