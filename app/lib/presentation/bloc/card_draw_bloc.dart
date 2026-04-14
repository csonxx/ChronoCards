import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/game_card.dart';
import 'card_draw_event.dart';
import 'card_draw_state.dart';

class CardDrawBloc extends Bloc<CardDrawEvent, CardDrawState> {
  List<GameCard> _deck = [];
  List<GameCard> _hand = [];
  List<GameCard> _discardPile = [];
  int _drawsRemaining = 3;

  CardDrawBloc() : super(CardDrawInitial()) {
    on<InitializeCardDraw>(_onInitialize);
    on<DrawCards>(_onDrawCards);
    on<SelectCard>(_onSelectCard);
    on<ConfirmDraw>(_onConfirmDraw);
    on<ResetDraw>(_onResetDraw);
  }

  Future<void> _onInitialize(
    InitializeCardDraw event,
    Emitter<CardDrawState> emit,
  ) async {
    emit(CardDrawLoading());
    try {
      _deck = _generateStarterDeck();
      _hand = [];
      _discardPile = [];
      _drawsRemaining = 3;

      emit(CardDrawReady(
        deck: _deck,
        hand: _hand,
        discardPile: _discardPile,
        drawsRemaining: _drawsRemaining,
      ));
    } catch (e) {
      emit(CardDrawError('Failed to initialize: $e'));
    }
  }

  Future<void> _onDrawCards(
    DrawCards event,
    Emitter<CardDrawState> emit,
  ) async {
    if (_deck.isEmpty && _discardPile.isNotEmpty) {
      // Reshuffle discard pile into deck
      _deck = List.from(_discardPile);
      _discardPile = [];
      _deck.shuffle();
    }

    if (_deck.isEmpty) {
      emit(const CardDrawError('No cards left to draw!'));
      return;
    }

    final cardsToDraw = event.count.clamp(1, _deck.length);
    final drawnCards = _deck.take(cardsToDraw).toList();

    emit(CardDrawing(drawnCards));

    // After animation, show the cards
    await Future.delayed(const Duration(milliseconds: 1000));

    emit(CardDrawn(
      drawnCards: drawnCards,
      updatedHand: [..._hand, ...drawnCards],
    ));
  }

  void _onSelectCard(SelectCard event, Emitter<CardDrawState> emit) {
    // Handle card selection for battle
  }

  void _onConfirmDraw(ConfirmDraw event, Emitter<CardDrawState> emit) {
    final currentState = state;
    if (currentState is CardDrawn) {
      _hand = currentState.updatedHand;
      _drawsRemaining--;
      _deck.removeWhere((card) => currentState.drawnCards.contains(card));

      emit(CardDrawReady(
        deck: _deck,
        hand: _hand,
        discardPile: _discardPile,
        drawsRemaining: _drawsRemaining,
      ));
    }
  }

  void _onResetDraw(ResetDraw event, Emitter<CardDrawState> emit) {
    _deck.addAll(_hand);
    _deck.addAll(_discardPile);
    _hand = [];
    _discardPile = [];
    _deck.shuffle();
    _drawsRemaining = 3;

    emit(CardDrawReady(
      deck: _deck,
      hand: _hand,
      discardPile: _discardPile,
      drawsRemaining: _drawsRemaining,
    ));
  }

  List<GameCard> _generateStarterDeck() {
    return [
      const GameCard(
        id: 'card_1',
        name: 'Time Strike',
        description: 'Deal 10 damage',
        type: CardType.attack,
        rarity: CardRarity.common,
        cost: 2,
        attack: 10,
        defense: 0,
      ),
      const GameCard(
        id: 'card_2',
        name: 'Chrono Shield',
        description: 'Gain 8 defense',
        type: CardType.defense,
        rarity: CardRarity.common,
        cost: 1,
        attack: 0,
        defense: 8,
      ),
      const GameCard(
        id: 'card_3',
        name: 'Void Bolt',
        description: 'Deal 15 damage',
        type: CardType.magic,
        rarity: CardRarity.uncommon,
        cost: 3,
        attack: 15,
        defense: 0,
      ),
      const GameCard(
        id: 'card_4',
        name: 'Temporal Warp',
        description: 'Draw 2 cards',
        type: CardType.skill,
        rarity: CardRarity.rare,
        cost: 2,
        attack: 0,
        defense: 0,
      ),
      const GameCard(
        id: 'card_5',
        name: 'Dragon Claw',
        description: 'Deal 25 damage',
        type: CardType.attack,
        rarity: CardRarity.epic,
        cost: 5,
        attack: 25,
        defense: 0,
      ),
      const GameCard(
        id: 'card_6',
        name: 'Mystic Barrier',
        description: 'Gain 20 defense',
        type: CardType.defense,
        rarity: CardRarity.rare,
        cost: 3,
        attack: 0,
        defense: 20,
      ),
    ];
  }
}
