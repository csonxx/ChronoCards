import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/event_card.dart';
import '../../bloc/card_draw/card_draw_bloc.dart';
import '../../bloc/card_draw/card_draw_event.dart';
import '../../bloc/card_draw/card_draw_state.dart';
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
  String _blankCardText = '';

  // Card result overlay state
  bool _showCardResultOverlay = false;
  EventCard? _resultCard;
  bool _isCardResultConfirmed = false;

  // Animation controller for flying card
  AnimationController? _flyingAnimationController;
  Animation<Offset>? _flyingAnimation;
  Animation<double>? _flyingScaleAnimation;

  @override
  void dispose() {
    _flyingAnimationController?.dispose();
    super.dispose();
  }

  void _startFlyingAnimation(EventCard card) {
    _flyingAnimationController?.dispose();
    _flyingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _flyingAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _flyingAnimationController!,
      curve: Curves.easeOutCubic,
    ));

    _flyingScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flyingAnimationController!,
      curve: Curves.easeOutCubic,
    ));

    _flyingAnimationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Animation complete - dispatch event to bloc
        context.read<CardDrawBloc>().add(const DrawCardAnimationComplete());
      }
    });

    _flyingAnimationController!.forward();
  }

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
            _startFlyingAnimation(state.card);
          } else if (state is CardRevealedState) {
            setState(() {
              _flyingCard = null;
              _isFlying = false;
              _selectedOptionId = null;
              _showCardResultOverlay = true;
              _resultCard = state.card;
              _isCardResultConfirmed = false;
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

              // Card result overlay (full-screen card reveal with glow effects)
              if (_showCardResultOverlay && _resultCard != null)
                _buildCardResultOverlay(),
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
          child: AnimatedBuilder(
            animation: _flyingAnimationController!,
            builder: (context, child) {
              return Transform.translate(
                offset: _flyingAnimation?.value ?? Offset.zero,
                child: Transform.scale(
                  scale: _flyingScaleAnimation?.value ?? 1.0,
                  child: EventCardWidget(
                    card: _flyingCard!,
                    isFlipped: false,
                    showOptions: false,
                  ),
                ),
              );
            },
          ),
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
              blankCardText: _blankCardText,
              onBlankCardTextChanged: (text) {
                setState(() => _blankCardText = text);
              },
              onOptionSelected: (id) {
                setState(() => _selectedOptionId = id);
              },
              onConfirm: () {
                context.read<CardDrawBloc>().add(
                      ConfirmCard(selectedOptionId: _selectedOptionId),
                    );
              },
              onSkip: () {
                context.read<CardDrawBloc>().add(
                      SkipCard(customText: _blankCardText.isNotEmpty ? _blankCardText : null),
                    );
                setState(() => _blankCardText = '');
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

  /// Full-screen card result overlay with glow effects and "加入卡组" button
  Widget _buildCardResultOverlay() {
    if (_resultCard == null) return const SizedBox.shrink();

    final cardType = _resultCard!.type;
    final glowColor = cardType.glowColor;
    final primaryColor = cardType.primaryColor;

    // Determine rarity tier based on card type (for visual distinction)
    final isHighRarity = cardType == EventCardType.fate ||
        cardType == EventCardType.mainline;
    final isEpic = cardType == EventCardType.mechanism ||
        cardType == EventCardType.numeric;
    final isLegendary = cardType == EventCardType.era &&
        _resultCard!.triggerCondition.isNotEmpty;

    Color borderColor;
    Color glowEffectColor;
    double glowIntensity;
    String rarityLabel;

    if (isLegendary) {
      borderColor = const Color(0xFFFF8C00); // Orange
      glowEffectColor = const Color(0xFFFF8C00);
      glowIntensity = 0.8;
      rarityLabel = '传说';
    } else if (isEpic) {
      borderColor = const Color(0xFF9932CC); // Purple
      glowEffectColor = const Color(0xFF9932CC);
      glowIntensity = 0.6;
      rarityLabel = '史诗';
    } else if (isHighRarity) {
      borderColor = const Color(0xFF4169E1); // Blue
      glowEffectColor = const Color(0xFF4169E1);
      glowIntensity = 0.4;
      rarityLabel = '稀有';
    } else {
      borderColor = const Color(0xFF808080); // Gray
      glowEffectColor = const Color(0xFF808080);
      glowIntensity = 0.2;
      rarityLabel = '普通';
    }

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.9),
        child: Stack(
          children: [
            // Background particles
            ...List.generate(20, (i) {
              return Positioned(
                left: (i * 53) % MediaQuery.of(context).size.width,
                top: (i * 67) % MediaQuery.of(context).size.height,
                child: Icon(
                  Icons.star,
                  size: 4 + (i % 3) * 2,
                  color: glowEffectColor.withOpacity(0.3 + (i % 3) * 0.1),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .fadeIn(duration: (400 + i * 100).ms)
                    .then()
                    .fadeOut(duration: (400 + i * 100).ms)
                    .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.2, 1.2)),
              );
            }),

            // Main content centered
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Card frame with glow effect
                  Container(
                    width: 320,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: glowEffectColor.withOpacity(glowIntensity),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                        if (isLegendary || isEpic)
                          BoxShadow(
                            color: glowEffectColor.withOpacity(0.3),
                            blurRadius: 80,
                            spreadRadius: 20,
                          ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor, width: 3),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(17),
                        child: Container(
                          color: const Color(0xFFF5E6C8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Top bar with type and rarity
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(14),
                                    topRight: Radius.circular(14),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Rarity badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: borderColor,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        rarityLabel,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    // Type label
                                    Text(
                                      cardType.label,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      cardType.icon,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),

                              // Card name
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Text(
                                      _resultCard!.name,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 28,
                                        fontFamily: 'serif',
                                        fontWeight: FontWeight.bold,
                                        shadows: const [
                                          Shadow(
                                            color: Color(0x303D2B1F),
                                            blurRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Decorative line
                                    Container(
                                      height: 2,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 40),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0x003D2B1F),
                                            borderColor.withOpacity(0.4),
                                            const Color(0x003D2B1F),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Illustration area (placeholder for character art)
                              Container(
                                height: 180,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: primaryColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        cardType.icon,
                                        size: 64,
                                        color: primaryColor,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '角色立绘',
                                        style: TextStyle(
                                          color: primaryColor.withOpacity(0.6),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Description
                              Container(
                                margin: const EdgeInsets.all(16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5E6C8).withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: primaryColor.withOpacity(0.2)),
                                ),
                                child: Text(
                                  _resultCard!.description,
                                  style: const TextStyle(
                                    color: Color(0xFF3D2B1F),
                                    fontSize: 15,
                                    height: 1.6,
                                    fontFamily: 'serif',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.0, 1.0),
                        duration: 500.ms,
                        curve: Curves.easeOutBack,
                      ),

                  const SizedBox(height: 24),

                  // "加入卡组" button
                  if (!_isCardResultConfirmed)
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isCardResultConfirmed = true;
                        });
                        // Dismiss overlay after confirmation
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (mounted) {
                            setState(() {
                              _showCardResultOverlay = false;
                              _resultCard = null;
                            });
                            // Continue with normal flow
                            context.read<CardDrawBloc>().add(
                                  ConfirmCard(selectedOptionId: _selectedOptionId),
                                );
                          }
                        });
                      },
                      icon: const Icon(Icons.add_to_photos),
                      label: const Text(
                        '加入卡组',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: glowEffectColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 300.ms)
                        .slideY(begin: 0.3, delay: 400.ms),
                ],
              ),
            ),

            // Close button
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _showCardResultOverlay = false;
                    _resultCard = null;
                  });
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground.withOpacity(0.8),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: AppTheme.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
