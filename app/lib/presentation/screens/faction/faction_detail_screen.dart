import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/game_card.dart';
import '../../widgets/faction/reputation_bar.dart';
import '../../widgets/faction/faction_card_widget.dart';
import 'faction_list_screen.dart';

/// 5级声望系统：友善→熟悉→信赖→亲密→莫逆
enum FactionReputationTier {
  friendly,    // 友善
  familiar,    // 熟悉
  trusted,     // 信赖
  intimate,    // 亲密
  inseparable, // 莫逆
}

extension FactionReputationTierExtension on FactionReputationTier {
  String get name {
    switch (this) {
      case FactionReputationTier.friendly:
        return '友善';
      case FactionReputationTier.familiar:
        return '熟悉';
      case FactionReputationTier.trusted:
        return '信赖';
      case FactionReputationTier.intimate:
        return '亲密';
      case FactionReputationTier.inseparable:
        return '莫逆';
    }
  }

  Color get color {
    switch (this) {
      case FactionReputationTier.friendly:
        return Colors.white;
      case FactionReputationTier.familiar:
        return const Color(0xFF32CD32);
      case FactionReputationTier.trusted:
        return const Color(0xFF4169E1);
      case FactionReputationTier.intimate:
        return const Color(0xFF9932CC);
      case FactionReputationTier.inseparable:
        return const Color(0xFFFFD700);
    }
  }

  String get iconText {
    switch (this) {
      case FactionReputationTier.friendly:
        return '友';
      case FactionReputationTier.familiar:
        return '熟';
      case FactionReputationTier.trusted:
        return '信';
      case FactionReputationTier.intimate:
        return '亲';
      case FactionReputationTier.inseparable:
        return '义';
    }
  }

  FactionReputationTier? get nextTier {
    switch (this) {
      case FactionReputationTier.friendly:
        return FactionReputationTier.familiar;
      case FactionReputationTier.familiar:
        return FactionReputationTier.trusted;
      case FactionReputationTier.trusted:
        return FactionReputationTier.intimate;
      case FactionReputationTier.intimate:
        return FactionReputationTier.inseparable;
      case FactionReputationTier.inseparable:
        return null;
    }
  }

  String get privilege {
    switch (this) {
      case FactionReputationTier.friendly:
        return '基础商店九折，购买该势力卡牌';
      case FactionReputationTier.familiar:
        return '商店八折，解锁进阶卡牌池';
      case FactionReputationTier.trusted:
        return '商店七五折，专属抽卡up机会';
      case FactionReputationTier.intimate:
        return '商店七折，限定称号和稀有卡牌';
      case FactionReputationTier.inseparable:
        return '全势力商店六折，终极称号和专属功法';
    }
  }

  static FactionReputationTier fromValue(int reputation) {
    if (reputation < 100) return FactionReputationTier.friendly;
    if (reputation < 200) return FactionReputationTier.familiar;
    if (reputation < 300) return FactionReputationTier.trusted;
    if (reputation < 400) return FactionReputationTier.intimate;
    return FactionReputationTier.inseparable;
  }

  int get minValue {
    switch (this) {
      case FactionReputationTier.friendly:
        return 0;
      case FactionReputationTier.familiar:
        return 100;
      case FactionReputationTier.trusted:
        return 200;
      case FactionReputationTier.intimate:
        return 300;
      case FactionReputationTier.inseparable:
        return 400;
    }
  }

  int get maxValue {
    switch (this) {
      case FactionReputationTier.friendly:
        return 100;
      case FactionReputationTier.familiar:
        return 200;
      case FactionReputationTier.trusted:
        return 300;
      case FactionReputationTier.intimate:
        return 400;
      case FactionReputationTier.inseparable:
        return 500;
    }
  }
}

/// 势力详情页面
class FactionDetailScreen extends StatefulWidget {
  final Faction faction;

  const FactionDetailScreen({
    super.key,
    required this.faction,
  });

  @override
  State<FactionDetailScreen> createState() => _FactionDetailScreenState();
}

class _FactionDetailScreenState extends State<FactionDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String? _playerFactionId;
  int _playerReputation = 320;

  final List<GameCard> _factionCards = [
    GameCard(
      id: '${''}_card_1',
      name: '圣火令',
      type: CardType.special,
      rarity: CardRarity.legendary,
      cost: 5,
      attack: 8,
      defense: 0,
      description: '明教至高神兵',
    ),
    GameCard(
      id: '${''}_card_2',
      name: '烈火掌',
      type: CardType.attack,
      rarity: CardRarity.rare,
      cost: 3,
      attack: 5,
      defense: 2,
      description: '阳刚霸道的掌法',
    ),
    GameCard(
      id: '${''}_card_3',
      name: '乾坤大挪移',
      type: CardType.skill,
      rarity: CardRarity.epic,
      cost: 4,
      attack: 0,
      defense: 6,
      description: '转移敌人攻击',
    ),
    GameCard(
      id: '${''}_card_4',
      name: '波斯剑法',
      type: CardType.attack,
      rarity: CardRarity.uncommon,
      cost: 2,
      attack: 4,
      defense: 1,
      description: '来自波斯的奇特剑法',
    ),
    GameCard(
      id: '${''}_card_5',
      name: '圣火心法',
      type: CardType.magic,
      rarity: CardRarity.rare,
      cost: 3,
      attack: 3,
      defense: 4,
      description: '明教基础内功',
    ),
    GameCard(
      id: '${''}_card_6',
      name: '烈火旗令',
      type: CardType.defense,
      rarity: CardRarity.uncommon,
      cost: 2,
      attack: 1,
      defense: 5,
      description: '烈火旗的战斗号令',
    ),
  ];

  List<String> _ownedCardIds = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isMember => _playerFactionId == widget.faction.id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeader(),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              tabController: _tabController,
              factionColor: widget.faction.color,
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCardsTab(),
                _buildInfoTab(),
                _buildRelationsTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader() {
    final tier = FactionReputationTierExtension.fromValue(_playerReputation);
    final progress = _calculateTierProgress(_playerReputation, tier);
    final nextTier = tier.nextTier;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            widget.faction.color.withOpacity(0.3),
            widget.faction.color.withOpacity(0.1),
            AppTheme.primaryDark,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 顶部导航
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  const Text(
                    '势力详情',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share, color: AppTheme.textSecondary),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // 势力图标 + 名称 + 等级标签
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 势力大图标 (64x64)
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: widget.faction.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.faction.color,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.faction.color.withOpacity(0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.faction.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.faction.name,
                      style: TextStyle(
                        color: widget.faction.color,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 等级标签
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: tier.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: tier.color, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: tier.color,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                tier.iconText,
                                style: const TextStyle(
                                  color: AppTheme.primaryDark,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tier.name,
                            style: TextStyle(
                              color: tier.color,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 声望进度条
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // 进度条
                  Container(
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: tier.color.withOpacity(0.5), width: 1),
                    ),
                    child: Stack(
                      children: [
                        // 背景渐变
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(13),
                            gradient: LinearGradient(
                              colors: [
                                tier.color.withOpacity(0.1),
                                tier.color.withOpacity(0.05),
                              ],
                            ),
                          ),
                        ),
                        // 进度填充
                        FractionallySizedBox(
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(13),
                              gradient: LinearGradient(
                                colors: [
                                  tier.color.withOpacity(0.4),
                                  tier.color,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: tier.color.withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // 等级刻度
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: FactionReputationTier.values.map((t) {
                            final isReached = _playerReputation >= t.minValue;
                            return Container(
                              width: 2,
                              height: 14,
                              decoration: BoxDecoration(
                                color: isReached
                                    ? t.color.withOpacity(0.8)
                                    : AppTheme.cardBorder.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            );
                          }).toList(),
                        ),
                        // 进度文字
                        Center(
                          child: Text(
                            '${_playerReputation % 100}/100',
                            style: TextStyle(
                              color: progress > 0.5
                                  ? AppTheme.primaryDark
                                  : tier.color,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              shadows: const [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 等级标签行
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: FactionReputationTier.values.map((t) {
                      final isCurrent = t == tier;
                      return Text(
                        t.name,
                        style: TextStyle(
                          color: isCurrent ? t.color : AppTheme.textSecondary,
                          fontSize: 10,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 下一级奖励预览
            if (nextTier != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: nextTier.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: nextTier.color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: nextTier.color,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '达到 ${nextTier.name} 解锁：',
                      style: TextStyle(
                        color: nextTier.color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        nextTier.privilege,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // 势力特权列表
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.star_outline,
                        color: widget.faction.color,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '势力特权',
                        style: TextStyle(
                          color: widget.faction.color,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...FactionReputationTier.values.map((t) {
                    final isUnlocked = _playerReputation >= t.minValue;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isUnlocked
                                  ? t.color.withOpacity(0.2)
                                  : AppTheme.cardBorder.withOpacity(0.3),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isUnlocked ? t.color : AppTheme.cardBorder,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: isUnlocked
                                  ? Icon(
                                      Icons.check,
                                      color: t.color,
                                      size: 14,
                                    )
                                  : Icon(
                                      Icons.lock,
                                      color: AppTheme.textSecondary.withOpacity(0.5),
                                      size: 12,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            t.name,
                            style: TextStyle(
                              color: isUnlocked ? t.color : AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t.privilege,
                              style: TextStyle(
                                color: isUnlocked
                                    ? AppTheme.textPrimary
                                    : AppTheme.textSecondary.withOpacity(0.6),
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  double _calculateTierProgress(int reputation, FactionReputationTier tier) {
    if (tier == FactionReputationTier.inseparable) {
      return reputation >= 500 ? 1.0 : (reputation - 400) / 100;
    }
    final levelProgress = reputation - tier.minValue;
    final levelRange = tier.maxValue - tier.minValue;
    return levelProgress / levelRange;
  }

  Widget _buildCardsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.style,
                color: widget.faction.color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '阵营专属卡牌',
                style: TextStyle(
                  color: widget.faction.color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${_ownedCardIds.length}/${_factionCards.length}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FactionCardGrid(
            cards: _factionCards,
            factionId: widget.faction.id,
            ownedCardIds: _ownedCardIds,
            onCardTap: (card) {
              _showCardDetail(card);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection(
            '势力简介',
            Icons.info_outline,
            widget.faction.description,
          ),
          const SizedBox(height: 24),
          _buildInfoSection(
            '势力特色',
            Icons.star_outline,
            _getFactionFeature(),
          ),
          const SizedBox(height: 24),
          _buildInfoSection(
            '加入条件',
            Icons.check_circle_outline,
            _getJoinRequirement(),
          ),
          const SizedBox(height: 24),
          _buildInfoSection(
            '等级奖励',
            Icons.card_giftcard,
            _getLevelReward(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, IconData icon, String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: widget.faction.color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: widget.faction.color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '江湖关系',
            style: TextStyle(
              color: widget.faction.color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildRelationItem('少林寺', '武林正宗，互不干涉', RelationType.neutral),
          _buildRelationItem('武当派', '道佛之争，竞争关系', RelationType.competitive),
          _buildRelationItem('丐帮', '正邪不两立，敌对关系', RelationType.hostile),
          _buildRelationItem('锦衣卫', '官府与江湖，对立关系', RelationType.hostile),
        ],
      ),
    );
  }

  Widget _buildRelationItem(String name, String desc, RelationType type) {
    Color color;
    IconData icon;

    switch (type) {
      case RelationType.friendly:
        color = Colors.green;
        icon = Icons.handshake;
        break;
      case RelationType.neutral:
        color = Colors.grey;
        icon = Icons.remove;
        break;
      case RelationType.competitive:
        color = Colors.orange;
        icon = Icons.sports_kabaddi;
        break;
      case RelationType.hostile:
        color = Colors.red;
        icon = Icons.gpp_bad;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _getRelationText(type),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRelationText(RelationType type) {
    switch (type) {
      case RelationType.friendly:
        return '友好';
      case RelationType.neutral:
        return '中立';
      case RelationType.competitive:
        return '竞争';
      case RelationType.hostile:
        return '敌对';
    }
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.primaryMid,
        border: Border(
          top: BorderSide(color: AppTheme.cardBorder),
        ),
      ),
      child: SafeArea(
        child: _isMember ? _buildMemberButtons() : _buildJoinButton(),
      ),
    );
  }

  Widget _buildMemberButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              _showLeaveConfirm();
            },
            icon: const Icon(Icons.exit_to_app),
            label: const Text('离开势力'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.healthRed.withOpacity(0.8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.volunteer_activism),
            label: const Text('捐献提升声望'),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.faction.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJoinButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          _showJoinConfirm();
        },
        icon: const Icon(Icons.group_add),
        label: Text(_playerFactionId != null ? '转入该势力' : '申请加入'),
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.faction.color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  void _showCardDetail(GameCard card) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.primaryMid,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: widget.faction.color),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            FactionCardWidget(
              card: card,
              factionColor: widget.faction.color,
              isOwned: _ownedCardIds.contains(card.id),
            ),
            const SizedBox(height: 16),
            Text(
              card.name,
              style: TextStyle(
                color: widget.faction.color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              card.description,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCardStat(Icons.bolt, '消耗', '${card.cost}', AppTheme.manaBlue),
                const SizedBox(width: 24),
                if (card.attack > 0)
                  _buildCardStat(Icons.sports_martial_arts, '攻击', '${card.attack}', AppTheme.healthRed),
                if (card.defense > 0)
                  _buildCardStat(Icons.shield, '防御', '${card.defense}', AppTheme.manaBlue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardStat(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showJoinConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryMid,
        title: Text(
          '确认加入 ${widget.faction.name}？',
          style: TextStyle(color: widget.faction.color),
        ),
        content: const Text(
          '加入后将获得该势力专属卡牌，并可通过捐献提升声望。\n\n注意：转入新势力将清空当前势力声望！',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已成功加入 ${widget.faction.name}！'),
                  backgroundColor: widget.faction.color,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.faction.color,
            ),
            child: const Text('确认加入'),
          ),
        ],
      ),
    );
  }

  void _showLeaveConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryMid,
        title: const Text(
          '确认离开势力？',
          style: TextStyle(color: AppTheme.healthRed),
        ),
        content: const Text(
          '离开后将失去该势力成员身份，声望也将清零。',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('已离开势力'),
                  backgroundColor: AppTheme.healthRed,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.healthRed,
            ),
            child: const Text('确认离开'),
          ),
        ],
      ),
    );
  }

  String _getFactionFeature() {
    switch (widget.faction.id) {
      case 'mingjiao':
        return '以火焰为主题，擅长火属性攻击和灼烧效果。卡牌多以高攻击、高爆发为主。';
      case 'shaolin':
        return '以棍法和禅功为主，攻守平衡。卡牌注重防御和持久战能力。';
      case 'wudang':
        return '以内功和剑法见长，擅长控制和卸力。卡牌多带有控制效果。';
      case 'jinyiwei':
        return '皇室直属，擅长暗杀和情报。卡牌多带有debuff和爆发伤害。';
      case 'wudu':
        return '以毒术和蛊术为主，擅长持续伤害。卡牌多带有中毒和虚弱效果。';
      case 'gaibang':
        return '天下第一大帮，弟子众多。卡牌灵活多变，以辅助和协同为主。';
      default:
        return '各具特色的江湖势力。';
    }
  }

  String _getJoinRequirement() {
    switch (widget.faction.id) {
      case 'mingjiao':
        return '声望达到「友善」即可申请加入。';
      case 'shaolin':
        return '需通过少林十八铜人阵考验。';
      case 'wudang':
        return '需有武当弟子引荐。';
      case 'jinyiwei':
        return '仅限朝廷官员或立下大功者。';
      case 'wudu':
        return '需服用三尸脑神丹以示忠诚。';
      case 'gaibang':
        return '需有帮中弟子推荐，无需声望要求。';
      default:
        return '联系该势力掌门即可加入。';
    }
  }

  String _getLevelReward() {
    return '友善：基础卡牌\n熟悉：进阶卡牌\n信赖：高级卡牌\n亲密：稀有卡牌\n莫逆：终极卡牌和专属称号';
  }
}

enum RelationType {
  friendly,
  neutral,
  competitive,
  hostile,
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final Color factionColor;

  _TabBarDelegate({
    required this.tabController,
    required this.factionColor,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.primaryMid,
      child: TabBar(
        controller: tabController,
        indicatorColor: factionColor,
        labelColor: factionColor,
        unselectedLabelColor: AppTheme.textSecondary,
        tabs: const [
          Tab(text: '专属卡牌', icon: Icon(Icons.style, size: 18)),
          Tab(text: '势力详情', icon: Icon(Icons.info_outline, size: 18)),
          Tab(text: '江湖关系', icon: Icon(Icons.people, size: 18)),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 72;

  @override
  double get minExtent => 72;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}
