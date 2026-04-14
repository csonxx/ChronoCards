import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/event_card.dart';
import '../../bloc/card_draw_bloc.dart';
import '../../bloc/card_draw_event.dart';
import '../../bloc/card_draw_state.dart';
import 'event_card_widget.dart';
import 'card_stack_widget.dart';
import 'exit_condition_hud.dart';
import 'deck_distributor_hud.dart';
import 'card_effect_panel.dart';

/// CardDrawScreen - Main draw scene with three-layer layout
/// Layer 1: Deck layer (3D card stack)
/// Layer 2: Flying card layer (card fly-in animation)
/// Layer 3: Flip layer (card flip and reveal)
class CardDrawScreen extends StatelessWidget {
  const CardDrawScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CardDrawBloc()
        ..add(const InitializeCardDrawScene(
          deckSize: 20,
          maxTurns: 10,
          currentTurn: 1,
        )),
      child: const _CardDrawView(),
    );
  }
}

class _CardDrawView extends StatefulWidget {
  const _CardDrawView();

  @override
  State<_CardDrawView> createState() => _CardDrawViewState();
}

class _CardDrawViewState extends State<_CardDrawView>
    with TickerProviderStateMixin {
  String? _selectedOptionId;
  EventCard? _flyingCard;
  bool _isFlying = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: BlocConsumer<CardDrawBloc, CardDrawState>(
        listener: (context, state) {
          if (state is CardDrawingState) {
            setState(() {
              _flyingCard = state.card;
              _isFlying = true;
            });
          } else if (state is CardRevealedState) {
            setState(() {
              _flyingCard = null;
              _isFlying = false;
              _selectedOptionId = null;
            });
          } else if (state is ExitTriggeredState) {
            // Show exit dialog
            _showExitDialog(context, state);
          } else if (state is CardDrawCompleted) {
            _showCompletionDialog(context, state);
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // Background gradient
              _buildBackground(),

              // Main content
              SafeArea(
                child: Column(
                  children: [
                    // Layer 0: Top HUD - Exit conditions
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildTopHUD(state),
                    ),

                    // Layer 1: Deck layer (card stack)
                    Expanded(
                      child: _buildDeckLayer(state),
                    ),

                    // Layer 2: Flying card layer (overlay)
                    if (_isFlying)
                      _buildFlyingLayer(),

                    // Layer 3: Flip/reveal layer
                    _buildFlipLayer(state),

                    // Bottom: Distributor HUD
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildBottomHUD(state),
                    ),
                  ],
                ),
              ),

              // Loading overlay
              if (state is CardDrawLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.accentGold,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [
            AppTheme.accentCosmic.withOpacity(0.2),
            AppTheme.primaryDark,
          ],
        ),
      ),
    );
  }

  Widget _buildTopHUD(CardDrawState state) {
    List<ExitCondition> conditions = [];
    int drawnCount = 0;
    DeckDistributorStatus distributor = const DeckDistributorStatus(
      busyCount: 1,
      totalCount: 3,
    );

    if (state is CardStackState) {
      conditions = state.exitConditions;
      drawnCount = state.drawnHistory.length;
      distributor = state.distributorStatus;
    } else if (state is CardRevealedState) {
      conditions = state.exitConditions;
      drawnCount = state.drawnCount;
      distributor = state.distributorStatus;
    }

    return ExitConditionHUD(
      conditions: conditions,
      drawnCount: drawnCount,
      onBannerTap: () {
        // Could show detailed condition info
      },
    );
  }

  Widget _buildDeckLayer(CardDrawState state) {
    int remaining = 0;
    int total = 20;

    if (state is CardStackState) {
      remaining = state.remainingCards;
      total = state.totalCards;
    } else if (state is CardDrawingState) {
      remaining = state.remainingCards;
    }

    // Only show deck when waiting for draw
    final showDeck = state is CardStackState;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Spotlight effect behind deck
          Container(
            width: 300,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.accentCosmic.withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Card stack
          if (showDeck)
            CardStackWidget(
              remainingCards: remaining,
              totalCards: total,
              onTap: () {
                context.read<CardDrawBloc>().add(const DrawCard());
              },
            ),

          // "Draw" prompt when deck visible
          if (showDeck && remaining > 0)
            Positioned(
              bottom: 80,
              child: Text(
                '点击卡堆抽卡',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ).animate(onPlay: (c) => c.repeat()).fadeIn().then().fadeOut(),
        ],
      ),
    );
  }

  Widget _buildFlyingLayer() {
    if (_flyingCard == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: EventCardWidget(
            card: _flyingCard!,
            isFlipped: false,
            showOptions: false,
          )
              .animate(curve: Curves.easeOutCubic)
              .moveY(begin: -100, end: 0, duration: 600.ms)
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
        ),
      ),
    );
  }

  Widget _buildFlipLayer(CardDrawState state) {
    if (state is CardRevealedState) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Card with flip animation
            EventCardWidget(
              card: state.card,
              isFlipped: true,
              showOptions: false,
              onFlipComplete: () {
                // Animation complete, options will appear via CardEffectPanel
              },
            ),

            const SizedBox(height: 8),

            // Effect panel with options
            CardEffectPanel(
              card: state.card,
              hasConflict: state.hasConflict,
              conflictMessage: state.conflictMessage,
              selectedOptionId: _selectedOptionId,
              onOptionSelected: (id) {
                setState(() => _selectedOptionId = id);
              },
              onConfirm: () {
                context.read<CardDrawBloc>().add(
                      ConfirmCard(selectedOptionId: _selectedOptionId),
                    );
              },
              onSkip: () {
                context.read<CardDrawBloc>().add(const SkipCard());
              },
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBottomHUD(CardDrawState state) {
    DeckDistributorStatus distributor = const DeckDistributorStatus(
      busyCount: 1,
      totalCount: 3,
    );

    if (state is CardStackState) {
      distributor = state.distributorStatus;
    } else if (state is CardRevealedState) {
      distributor = state.distributorStatus;
    }

    return DeckDistributorHUD(status: distributor);
  }

  void _showExitDialog(BuildContext context, ExitTriggeredState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF252A34),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF8B2020), width: 2),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber, color: Color(0xFFC94A4A)),
            const SizedBox(width: 8),
            const Text(
              '退出条件触发',
              style: TextStyle(color: Color(0xFFE0E0E0)),
            ),
          ],
        ),
        content: Text(
          state.message,
          style: const TextStyle(color: Color(0xFFB0B0B0)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('结束本章'),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog(BuildContext context, CardDrawCompleted state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF252A34),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFD4A843), width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Color(0xFFD4A843)),
            SizedBox(width: 8),
            Text(
              '本章结束',
              style: TextStyle(color: Color(0xFFE0E0E0)),
            ),
          ],
        ),
        content: Text(
          '共抽卡 ${state.totalDrawn} 张',
          style: const TextStyle(color: Color(0xFFB0B0B0)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<CardDrawBloc>().add(const ResetCardDrawScene());
            },
            child: const Text('重新开始'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4A843),
            ),
            child: const Text('返回'),
          ),
        ],
      ),
    );
  }
}
