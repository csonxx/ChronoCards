import 'package:equatable/equatable.dart';

/// CardDraw events - Chapter 7 design
abstract class CardDrawEvent extends Equatable {
  const CardDrawEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize the card draw scene
class InitializeCardDrawScene extends CardDrawEvent {
  final int deckSize;
  final int maxTurns;
  final int currentTurn;

  const InitializeCardDrawScene({
    this.deckSize = 20,
    this.maxTurns = 10,
    this.currentTurn = 1,
  });

  @override
  List<Object?> get props => [deckSize, maxTurns, currentTurn];
}

/// Player draws a card from the deck
class DrawCard extends CardDrawEvent {
  const DrawCard();
}

/// Animation completed after draw (called by UI)
class DrawCardAnimationComplete extends CardDrawEvent {
  const DrawCardAnimationComplete();
}

/// Player confirms the drawn card
class ConfirmCard extends CardDrawEvent {
  final String? selectedOptionId;

  const ConfirmCard({this.selectedOptionId});

  @override
  List<Object?> get props => [selectedOptionId];
}

/// Player skips drawing (uses blank/freedom card)
class SkipCard extends CardDrawEvent {
  final String? customText;

  const SkipCard({this.customText});

  @override
  List<Object?> get props => [customText];
}

/// Exit condition is triggered
class TriggerExit extends CardDrawEvent {
  final String conditionId;

  const TriggerExit(this.conditionId);

  @override
  List<Object?> get props => [conditionId];
}

/// Reset the scene
class ResetCardDrawScene extends CardDrawEvent {
  const ResetCardDrawScene();
}

/// Blank card custom text input changed
class BlankCardInputChanged extends CardDrawEvent {
  final String value;

  const BlankCardInputChanged(this.value);

  @override
  List<Object?> get props => [value];
}
