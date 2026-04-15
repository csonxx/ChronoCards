import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
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
            _showVictoryDialog(context, provider);
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
            ],
          );
        },
      ),
    );
  }

  void _updateBattleLog(String action) {
    setState(() {
      switch (action) {
        case 'attack':
          _battleLog = '⚔️ Player attacks!';
          break;
        case 'skill':
          _battleLog = '✨ Skill used!';
          break;
        case 'enemy_attack':
          _battleLog = '👹 Enemy attacks!';
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

  void _showVictoryDialog(BuildContext context, BattleProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.primaryDark,
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, color: AppTheme.textGold, size: 32),
            SizedBox(width: 8),
            Text('VICTORY!', style: TextStyle(color: AppTheme.textGold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Rewards: 50 coins'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Try again?'),
            const SizedBox(height: 16),
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
      ),
    );
  }
}
