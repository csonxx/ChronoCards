import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/game_card.dart';
import '../../bloc/card_draw_bloc.dart';
import '../../bloc/card_draw_event.dart';
import '../../bloc/card_draw_state.dart';
import '../../widgets/game_card_widget.dart';
import '../../widgets/card_draw_instructions_dialog.dart';

/// S3 - Card Draw Screen (Core Interaction)
/// The gacha/draw screen where players get new cards
class CardDrawScreen extends StatelessWidget {
  const CardDrawScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CardDrawBloc()..add(InitializeCardDraw()),
      child: const CardDrawView(),
    );
  }
}

class CardDrawView extends StatefulWidget {
  const CardDrawView({super.key});

  @override
  State<CardDrawView> createState() => _CardDrawViewState();
}

class _CardDrawViewState extends State<CardDrawView> {
  List<GameCard> _previewCards = [];
  bool _isDrawing = false;
  bool _hasSeenInstructions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasSeenInstructions) {
        _showInstructionsDialog();
      }
    });
  }

  void _showInstructionsDialog() {
    setState(() => _hasSeenInstructions = true);
    CardDrawInstructionsDialog.show(
      context,
      onGotIt: () {
        setState(() => _hasSeenInstructions = true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Card Draw'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showInstructionsDialog,
          ),
        ],
      ),
      body: BlocConsumer<CardDrawBloc, CardDrawState>(
        listener: (context, state) {
          if (state is CardDrawn) {
            setState(() {
              _previewCards = state.drawnCards;
              _isDrawing = false;
            });
          } else if (state is CardDrawing) {
            setState(() => _isDrawing = true);
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // Background effects
              _buildBackgroundEffects(),

              // Main content
              SafeArea(
                child: Column(
                  children: [
                    // Draw info
                    _buildDrawInfo(context, state),

                    const SizedBox(height: 32),

                    // Card display area
                    Expanded(
                      child: _buildCardArea(context, state),
                    ),

                    // Action buttons
                    _buildActionButtons(context, state),
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

  Widget _buildBackgroundEffects() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [
            AppTheme.accentCosmic.withOpacity(0.3),
            AppTheme.primaryDark,
          ],
        ),
      ),
    );
  }

  Widget _buildDrawInfo(BuildContext context, CardDrawState state) {
    int drawsRemaining = 0;
    int deckSize = 0;
    int handSize = 0;

    if (state is CardDrawReady) {
      drawsRemaining = state.drawsRemaining;
      deckSize = state.deck.length;
      handSize = state.hand.length;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(Icons.repeat, 'Draws Left', '$drawsRemaining'),
          _buildInfoItem(Icons.style, 'Deck', '$deckSize'),
          _buildInfoItem(Icons.back_hand, 'Hand', '$handSize'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.accentGold, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCardArea(BuildContext context, CardDrawState state) {
    if (_isDrawing) {
      return _buildDrawingAnimation();
    }

    if (_previewCards.isNotEmpty) {
      return _buildDrawnCards(context);
    }

    return _buildDeckView(context);
  }

  Widget _buildDrawingAnimation() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 120,
            height: 160,
            child: GameCardWidget(
              card: GameCard(
                id: 'back',
                name: '',
                description: '',
                type: CardType.attack,
                rarity: CardRarity.common,
                cost: 0,
                attack: 0,
                defense: 0,
              ),
              isBack: true,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 800.ms, color: AppTheme.accentGold)
              .then()
              .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1))
              .then()
              .scale(begin: const Offset(1.1, 1.1), end: const Offset(1, 1)),
          const SizedBox(height: 32),
          const Text(
            'Drawing cards...',
            style: TextStyle(
              color: AppTheme.accentGold,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ).animate(onPlay: (controller) => controller.repeat()).shimmer(
                duration: 600.ms,
                color: AppTheme.textPrimary.withOpacity(0.5),
              ),
        ],
      ),
    );
  }

  Widget _buildDrawnCards(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '✨ Cards Drawn! ✨',
          style: TextStyle(
            color: AppTheme.textGold,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn().scale(begin: const Offset(0.5, 0.5)),
        const SizedBox(height: 24),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _previewCards.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: GameCardWidget(
                  card: _previewCards[index],
                  showDetails: true,
                )
                    .animate()
                    .fadeIn(delay: (index * 200).ms)
                    .slideX(begin: 0.5, delay: (index * 200).ms),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Tap to add to hand',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDeckView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.accentCosmic,
                  AppTheme.primaryLight,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentCosmic.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.style,
                  size: 64,
                  color: AppTheme.textGold,
                ),
                const SizedBox(height: 16),
                const Text(
                  'CHRONO',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const Text(
                  'CARDS',
                  style: TextStyle(
                    color: AppTheme.accentGold,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 32),
          const Text(
            'Tap Draw to get cards!',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, CardDrawState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (_previewCards.isEmpty) ...[
            // Draw button
            _buildDrawButton(context, state),
          ] else ...[
            // Confirm/Reset buttons
            OutlinedButton(
              onPressed: () {
                context.read<CardDrawBloc>().add(ResetDraw());
                setState(() => _previewCards = []);
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                side: const BorderSide(color: AppTheme.cardBorder),
              ),
              child: const Text(
                'Redraw',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<CardDrawBloc>().add(ConfirmDraw());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGold,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(
                  color: AppTheme.primaryDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDrawButton(BuildContext context, CardDrawState state) {
    int drawsRemaining = 0;
    if (state is CardDrawReady) {
      drawsRemaining = state.drawsRemaining;
    }

    final canDraw = drawsRemaining > 0;

    return GestureDetector(
      onTap: canDraw
          ? () {
              context.read<CardDrawBloc>().add(const DrawCards(3));
            }
          : null,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: canDraw
                ? [AppTheme.accentGold, AppTheme.accentCosmic]
                : [
                    AppTheme.cardBorder,
                    AppTheme.cardBackground,
                  ],
          ),
          boxShadow: canDraw
              ? [
                  BoxShadow(
                    color: AppTheme.accentGold.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 40,
              color: AppTheme.primaryDark,
            ),
            const SizedBox(height: 8),
            Text(
              'DRAW',
              style: TextStyle(
                color: canDraw
                    ? AppTheme.primaryDark
                    : AppTheme.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$drawsRemaining left',
              style: TextStyle(
                color: canDraw
                    ? AppTheme.primaryDark.withOpacity(0.7)
                    : AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
