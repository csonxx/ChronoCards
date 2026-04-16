import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/network.dart';
import '../../../domain/entities/game_card.dart';
import '../../providers/battle_provider.dart';
import '../../widgets/battle_card_widget.dart';
import '../../widgets/battle_player_widget.dart';
import '../../widgets/battle_enemy_widget.dart';

/// S5 - Battle Screen (ARPG Instant Combat)
/// Real-time ARPG style battle interface
/// Migrated from Bloc to Provider architecture
class BattleScreen extends StatelessWidget {
  final String? enemyId;

  const BattleScreen({super.key, this.enemyId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => BattleProvider()..startBattle(enemyId ?? 'enemy_1'),
      child: const BattleView(),
    );
  }
}

class BattleView extends StatefulWidget {
  const BattleView({super.key});

  @override
  State<BattleView> createState() => _BattleViewState();
}

class _BattleViewState extends State<BattleView> with TickerProviderStateMixin {
  String _battleLog = 'Battle Start!';
  bool _showLog = false;

  // Victory overlay state
  bool _showVictoryOverlay = false;
  bool _showRewards = false;
  bool _showContinueButton = false;

  // Mock rewards data
  int _expReward = 150;
  int _goldReward = 80;
  final List<Map<String, dynamic>> _equipmentRewards = [
    {'name': '玄铁剑', 'rarity': CardRarity.legendary, 'icon': Icons.bolt},
    {'name': '金丝甲', 'rarity': CardRarity.epic, 'icon': Icons.shield},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Consumer<BattleProvider>(
        listener: (context, provider, child) {
          if (provider.animationType.isNotEmpty) {
            _updateBattleLog(provider.animationType);
          }
          if (provider.isVictory) {
            _triggerVictorySequence(context, provider);
          } else if (provider.isDefeat) {
            _showDefeatDialog(context, provider);
          }
        },
        builder: (context, provider, child) {
          return Stack(
            children: [
              // Battle background
              _buildBattleBackground(),

              // Main battle UI
              SafeArea(
                child: Column(
                  children: [
                    // Top bar with turn info
                    _buildTopBar(context, provider),

                    // Enemy area
                    Expanded(
                      flex: 3,
                      child: _buildEnemyArea(context, provider),
                    ),

                    // Battle divider
                    _buildBattleDivider(),

                    // Player area
                    Expanded(
                      flex: 2,
                      child: _buildPlayerArea(context, provider),
                    ),

                    // Hand cards
                    _buildHandArea(context, provider),

                    // Action bar
                    _buildActionBar(context, provider),
                  ],
                ),
              ),

              // Battle log
              if (_showLog) _buildBattleLogOverlay(),

              // Victory overlay
              if (_showVictoryOverlay) _buildVictoryOverlay(),
            ],
          );
        },
      ),
    );
  }

  void _triggerVictorySequence(BuildContext context, BattleProvider provider) {
    setState(() {
      _showVictoryOverlay = true;
      _showRewards = false;
      _showContinueButton = false;
    });

    // Show rewards after VICTORY text fades in
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _showRewards = true);
      }
    });

    // Show continue button last
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _showContinueButton = true);
      }
    });
  }

  void _updateBattleLog(String action) {
    setState(() {
      switch (action) {
        case 'attack':
          _battleLog = 'Player attacks!';
          break;
        case 'skill':
          _battleLog = 'Skill used!';
          break;
        case 'enemy_attack':
          _battleLog = 'Enemy attacks!';
          break;
        default:
          _battleLog = '...';
      }
      _showLog = true;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _showLog = false);
      }
    });
  }

  Widget _buildBattleBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1A0A0A),
            AppTheme.primaryDark,
            const Color(0xFF0A1A0A),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Particle effects
          ...List.generate(20, (i) {
            return Positioned(
              left: (i * 47) % MediaQuery.of(context).size.width,
              top: (i * 73) % MediaQuery.of(context).size.height,
              child: Icon(
                Icons.auto_awesome,
                size: 8,
                color: AppTheme.accentGold.withOpacity(0.3),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .fadeIn()
                  .then()
                  .fadeOut()
                  .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.5, 1.5)),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, BattleProvider provider) {
    String turnText = 'Turn ${provider.turn}';
    String phaseText = provider.isPlayerTurn ? 'Your Turn' : 'Enemy Turn';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Text(
              turnText,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showLog = !_showLog),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: phaseText == 'Your Turn'
                    ? AppTheme.accentGold.withOpacity(0.2)
                    : AppTheme.healthRed.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: phaseText == 'Your Turn'
                      ? AppTheme.accentGold
                      : AppTheme.healthRed,
                ),
              ),
              child: Text(
                phaseText,
                style: TextStyle(
                  color: phaseText == 'Your Turn'
                      ? AppTheme.accentGold
                      : AppTheme.healthRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.list, color: AppTheme.textSecondary),
            onPressed: () => setState(() => _showLog = !_showLog),
          ),
        ],
      ),
    );
  }

  Widget _buildEnemyArea(BuildContext context, BattleProvider provider) {
    return BattleEnemyWidget(enemy: provider.enemy);
  }

  Widget _buildBattleDivider() {
    return Container(
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppTheme.accentGold.withOpacity(0.5),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerArea(BuildContext context, BattleProvider provider) {
    return BattlePlayerWidget(player: provider.player);
  }

  Widget _buildHandArea(BuildContext context, BattleProvider provider) {
    final hand = provider.hand;
    final selectedCards = provider.selectedCards;
    final isPlayerTurn = provider.isPlayerTurn;

    if (hand.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: const Text(
          'No cards in hand',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return Container(
      height: 130,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: hand.length,
        itemBuilder: (context, index) {
          final card = hand[index];
          final isSelected = selectedCards.any((c) => c.id == card.id);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: BattleCardWidget(
              card: card,
              isSelected: isSelected,
              isPlayable: isPlayerTurn,
              onTap: isPlayerTurn
                  ? () {
                      if (isSelected) {
                        provider.deselectCard(card.id);
                      } else {
                        provider.selectCard(card);
                      }
                    }
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, BattleProvider provider) {
    final selectedCards = provider.selectedCards;
    final isPlayerTurn = provider.isPlayerTurn;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 8,
      ),
      child: Row(
        children: [
          // Cancel/Deselect
          Expanded(
            child: OutlinedButton(
              onPressed: selectedCards.isNotEmpty && isPlayerTurn
                  ? () => provider.clearSelectedCards()
                  : null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: selectedCards.isNotEmpty && isPlayerTurn
                      ? AppTheme.healthRed
                      : AppTheme.cardBorder,
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: selectedCards.isNotEmpty && isPlayerTurn
                      ? AppTheme.healthRed
                      : AppTheme.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Attack button
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: selectedCards.isNotEmpty && isPlayerTurn
                  ? () => provider.executeAttack()
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGold,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: AppTheme.cardBorder,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sports_martial_arts,
                      color: AppTheme.primaryDark),
                  const SizedBox(width: 8),
                  Text(
                    'ATTACK (${selectedCards.length})',
                    style: const TextStyle(
                      color: AppTheme.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // End turn
          Expanded(
            child: ElevatedButton(
              onPressed: isPlayerTurn
                  ? () => provider.endPlayerTurn()
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.manaBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: AppTheme.cardBorder,
              ),
              child: const Text(
                'End Turn',
                style: TextStyle(
                  color: AppTheme.primaryDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattleLogOverlay() {
    return Positioned(
      top: 100,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryDark.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.accentGold),
        ),
        child: Column(
          children: [
            const Text(
              'Battle Log',
              style: TextStyle(
                color: AppTheme.accentGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(color: AppTheme.cardBorder),
            Text(
              _battleLog,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ).animate().fadeIn().slideY(begin: -0.5),
    );
  }

  /// Victory overlay with full-screen effects
  Widget _buildVictoryOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: Stack(
          children: [
            // Decorative background particles
            ...List.generate(30, (i) {
              return Positioned(
                left: (i * 37) % MediaQuery.of(context).size.width,
                top: (i * 59) % MediaQuery.of(context).size.height,
                child: Icon(
                  Icons.star,
                  size: 6 + (i % 4) * 2,
                  color: AppTheme.accentGold.withOpacity(0.3 + (i % 3) * 0.2),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .fadeIn(duration: (500 + i * 100).ms)
                    .then()
                    .fadeOut(duration: (500 + i * 100).ms)
                    .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.5, 1.5)),
              );
            }),

            // Main content centered
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // VICTORY text with glow
                  Text(
                    'VICTORY',
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentGold,
                      letterSpacing: 16,
                      shadows: [
                        Shadow(
                          color: AppTheme.accentGold.withOpacity(0.8),
                          blurRadius: 30,
                        ),
                        Shadow(
                          color: AppTheme.accentGold.withOpacity(0.5),
                          blurRadius: 60,
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.0, 1.0), duration: 400.ms)
                      .then()
                      .fadeOut(delay: 1200.ms, duration: 300.ms),

                  const SizedBox(height: 40),

                  // Rewards section (slides in from bottom)
                  if (_showRewards) ...[
                    _buildRewardsSection(),
                  ],
                ],
              ),
            ),

            // Continue button
            if (_showContinueButton)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 40,
                left: 40,
                right: 40,
                child: _buildContinueButton(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentGold.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentGold.withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Title
          const Text(
            '战利品',
            style: TextStyle(
              color: AppTheme.accentGold,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Floating rewards
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // EXP reward
              _buildFloatingReward(
                icon: Icons.trending_up,
                value: '+$expReward',
                label: '经验',
                color: const Color(0xFF32CD32),
              ),
              const SizedBox(width: 24),
              // Gold reward
              _buildFloatingReward(
                icon: Icons.monetization_on,
                value: '+$goldReward',
                label: '金币',
                color: const Color(0xFFFFD700),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Equipment rewards
          if (_equipmentRewards.isNotEmpty) ...[
            const Divider(color: AppTheme.cardBorder),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _equipmentRewards.map((equip) {
                return _buildEquipmentReward(
                  name: equip['name'],
                  rarity: equip['rarity'],
                  icon: equip['icon'],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.5, end: 0, duration: 400.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildFloatingReward({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, color: color, size: 32),
        )
            .animate(onPlay: (c) => c.repeat())
            .fadeIn()
            .then()
            .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 800.ms)
            .then()
            .scale(begin: const Offset(1.1, 1.1), end: const Offset(1, 1), duration: 800.ms),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentReward({
    required String name,
    required CardRarity rarity,
    required IconData icon,
  }) {
    Color borderColor;
    Color glowColor;

    switch (rarity) {
      case CardRarity.legendary:
        borderColor = const Color(0xFFFF8C00); // Orange
        glowColor = const Color(0xFFFF8C00);
        break;
      case CardRarity.epic:
        borderColor = const Color(0xFF9932CC); // Purple
        glowColor = const Color(0xFF9932CC);
        break;
      case CardRarity.rare:
        borderColor = const Color(0xFF4169E1); // Blue
        glowColor = const Color(0xFF4169E1);
        break;
      default:
        borderColor = AppTheme.cardBorder;
        glowColor = AppTheme.cardBorder;
    }

    return GestureDetector(
      onTap: () {
        // Show equipment detail
        _showEquipmentDetail(name, rarity);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primaryDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(icon, color: borderColor, size: 36),
                  // Rarity indicator
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: borderColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 80,
              child: Text(
                name,
                style: TextStyle(
                  color: borderColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.8, 0.8), delay: 200.ms);
  }

  void _showEquipmentDetail(String name, CardRarity rarity) {
    Color borderColor;
    String rarityText;

    switch (rarity) {
      case CardRarity.legendary:
        borderColor = const Color(0xFFFF8C00);
        rarityText = '传说';
        break;
      case CardRarity.epic:
        borderColor = const Color(0xFF9932CC);
        rarityText = '史诗';
        break;
      default:
        borderColor = AppTheme.cardBorder;
        rarityText = '稀有';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.primaryMid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor, width: 2),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: borderColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: Icon(
                Icons.bolt,
                color: borderColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: borderColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    rarityText,
                    style: TextStyle(
                      color: borderColor.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(color: AppTheme.cardBorder),
            const SizedBox(height: 8),
            Text(
              '点击查看详情',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return ElevatedButton(
      onPressed: () async {
        // P0 Fix: Report battle result to backend
        await _reportBattleResult();

        // Return battle result to OpenWorldScreen for map progress update
        if (mounted) {
          Navigator.pop(context, {
            'result': 'victory',
            'exp': _expReward,
            'gold': _goldReward,
            'equipment': _equipmentRewards,
          });
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accentGold,
        foregroundColor: AppTheme.primaryDark,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.explore),
          SizedBox(width: 8),
          Text(
            '继续探索',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, delay: 200.ms);
  }

  /// P0 Fix: Report battle result to backend
  Future<void> _reportBattleResult() async {
    try {
      // Get player ID from storage
      final prefs = await SharedPreferences.getInstance();
      final playerId = prefs.getString('player_id') ?? 'unknown';

      // Prepare equipment rewards data
      final equipmentData = <String, dynamic>{};
      for (final equip in _equipmentRewards) {
        equipmentData[equip['name'] as String] = {
          'rarity': (equip['rarity'] as CardRarity).name,
        };
      }

      final response = await apiClient.reportBattleResult(
        playerId: playerId,
        enemyId: enemyId ?? 'enemy_1',
        result: 'victory',
        expGained: _expReward,
        goldGained: _goldReward,
        equipmentRewards: equipmentData.isNotEmpty ? equipmentData : null,
      );

      if (response.success) {
        // debugPrint('[BattleScreen] Battle result reported successfully');
      } else {
        // debugPrint('[BattleScreen] Battle result report failed: ${response.error}');
      }
    } catch (e) {
      // debugPrint('[BattleScreen] Error reporting battle result: $e');
    }
  }

  void _showDefeatDialog(BuildContext context, BattleProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.primaryDark,
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.heart_broken, color: AppTheme.healthRed, size: 32),
            SizedBox(width: 8),
            Text('DEFEAT', style: TextStyle(color: AppTheme.healthRed)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Try again?'),
            SizedBox(height: 16),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              provider.startBattle('enemy_1');
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text('Return'),
          ),
        ],
      ),
    );
  }
}
