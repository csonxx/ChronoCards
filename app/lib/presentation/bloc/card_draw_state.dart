import 'package:equatable/equatable.dart';
import '../../../domain/entities/game_card.dart';

abstract class CardDrawState extends Equatable {
  const CardDrawState();

  @override
  List<Object?> get props => [];
}

class CardDrawInitial extends CardDrawState {}

class CardDrawLoading extends CardDrawState {}

class CardDrawReady extends CardDrawState {
  final List<GameCard> deck;
  final List<GameCard> hand;
  final List<GameCard> discardPile;
  final int drawsRemaining;

  const CardDrawReady({
    required this.deck,
    required this.hand,
    required this.discardPile,
    required this.drawsRemaining,
  });

  @override
  List<Object?> get props => [deck, hand, discardPile, drawsRemaining];
}

class CardDrawing extends CardDrawState {
  final List<GameCard> currentCards;

  const CardDrawing(this.currentCards);

  @override
  List<Object?> get props => [currentCards];
}

class CardDrawn extends CardDrawState {
  final List<GameCard> drawnCards;
  final List<GameCard> updatedHand;

  const CardDrawn({
    required this.drawnCards,
    required this.updatedHand,
  });

  @override
  List<Object?> get props => [drawnCards, updatedHand];
}

class CardDrawError extends CardDrawState {
  final String message;

  const CardDrawError(this.message);

  @override
  List<Object?> get props => [message];
}
