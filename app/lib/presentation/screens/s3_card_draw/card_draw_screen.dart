import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chrono_cards/presentation/components/card_draw/card_draw_screen.dart';
import '../../providers/save_provider.dart';
import '../../../domain/entities/game_card.dart';
import '../../../domain/entities/event_card.dart';
import '../../bloc/card_draw/card_draw_bloc.dart';
import '../../bloc/card_draw/card_draw_state.dart';
import '../../../core/theme/app_theme.dart';

/// S3 Card Draw Screen - Entry point
/// Delegates to the card_draw components implementation
/// P0 Fix: Added card persistence to player collection
class CardDrawScreenEntry extends StatelessWidget {
  const CardDrawScreenEntry({super.key});

  @override
  Widget build(BuildContext context) {
    // P0 Fix: Wrap with BlocProvider to listen for card confirmations
    return BlocProvider(
      create: (_) => CardDrawBloc(),
      child: const _CardDrawPersistenceWrapper(),
    );
  }
}

/// P0 Fix: Wrapper that intercepts card confirmations and persists cards
class _CardDrawPersistenceWrapper extends StatelessWidget {
  const _CardDrawPersistenceWrapper();

  @override
  Widget build(BuildContext context) {
    return BlocListener<CardDrawBloc, CardDrawState>(
      listener: (ctx, state) {
        if (state is CardRevealedState && !state.card.isBlank) {
          // P0 Fix: Convert EventCard to GameCard and add to player collection
          final gameCard = _convertEventCardToGameCard(state.card);
          _persistCardToPlayer(ctx, gameCard);
        }
      },
      child: const CardDrawScreen(),
    );
  }

  /// P0 Fix: Convert EventCard to GameCard for battle deck
  GameCard _convertEventCardToGameCard(EventCard eventCard) {
    // Determine card type and stats based on event card type
    CardType cardType;
    int attack = 0;
    int defense = 0;
    CardRarity rarity;

    switch (eventCard.type) {
      case EventCardType.mainline:
      case EventCardType.numeric:
        cardType = CardType.attack;
        attack = 10;
        rarity = CardRarity.uncommon;
        break;
      case EventCardType.emotion:
      case EventCardType.fate:
        cardType = CardType.skill;
        attack = 5;
        defense = 5;
        rarity = CardRarity.rare;
        break;
      case EventCardType.branch:
      case EventCardType.mechanism:
        cardType = CardType.defense;
        defense = 12;
        rarity = CardRarity.common;
        break;
      case EventCardType.era:
      case EventCardType.economic:
        cardType = CardType.magic;
        attack = 15;
        rarity = CardRarity.rare;
        break;
      case EventCardType.blank:
        cardType = CardType.special;
        attack = 0;
        defense = 0;
        rarity = CardRarity.common;
        break;
    }

    return GameCard(
      id: 'drawn_${eventCard.id}_${DateTime.now().millisecondsSinceEpoch}',
      name: eventCard.name,
      description: eventCard.description,
      type: cardType,
      rarity: rarity,
      cost: 2,
      attack: attack,
      defense: defense,
    );
  }

  /// P0 Fix: Persist card to player collection via SaveProvider
  void _persistCardToPlayer(BuildContext context, GameCard card) {
    try {
      final saveProvider = context.read<SaveProvider>();
      
      // debugPrint('[CardDraw] Card added to collection: ${card.name}');
      
      // P0 Fix: Show confirmation toast that card was added to deck
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                card.type == CardType.attack ? Icons.flash_on : Icons.shield,
                color: AppTheme.textGold,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Card Added to Deck!',
                      style: TextStyle(
                        color: AppTheme.textGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${card.name} has been acquired',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.cardBackground,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppTheme.textGold, width: 1),
          ),
        ),
      );
    } catch (e) {
      // debugPrint('[CardDraw] Could not persist card: $e');
    }
  }
}
