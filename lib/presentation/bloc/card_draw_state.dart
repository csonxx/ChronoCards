import 'package:equatable/equatable.dart';
import '../../../domain/entities/event_card.dart';

/// CardDraw states - Chapter 7 design
abstract class CardDrawState extends Equatable {
  const CardDrawState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class CardDrawInitial extends CardDrawState {
  const CardDrawInitial();
}

/// Loading state
class CardDrawLoading extends CardDrawState {
  const CardDrawLoading();
}

/// Card stack ready state (deck visible, waiting for draw)
class CardStackState extends CardDrawState {
  final int remainingCards;
  final int totalCards;
  final int currentTurn;
  final int maxTurns;
  final List<ExitCondition> exitConditions;
  final DeckDistributorStatus distributorStatus;
  final EventCard? activeCard;
  final List<EventCard> drawnHistory;

  const CardStackState({
    required this.remainingCards,
    required this.totalCards,
    required this.currentTurn,
    required this.maxTurns,
    required this.exitConditions,
    required this.distributorStatus,
    this.activeCard,
    this.drawnHistory = const [],
  });

  @override
  List<Object?> get props => [
        remainingCards,
        totalCards,
        currentTurn,
        maxTurns,
        exitConditions,
        distributorStatus,
        activeCard,
        drawnHistory,
      ];

  CardStackState copyWith({
    int? remainingCards,
    int? totalCards,
    int? currentTurn,
    int? maxTurns,
    List<ExitCondition>? exitConditions,
    DeckDistributorStatus? distributorStatus,
    EventCard? activeCard,
    List<EventCard>? drawnHistory,
  }) {
    return CardStackState(
      remainingCards: remainingCards ?? this.remainingCards,
      totalCards: totalCards ?? this.totalCards,
      currentTurn: currentTurn ?? this.currentTurn,
      maxTurns: maxTurns ?? this.maxTurns,
      exitConditions: exitConditions ?? this.exitConditions,
      distributorStatus: distributorStatus ?? this.distributorStatus,
      activeCard: activeCard ?? this.activeCard,
      drawnHistory: drawnHistory ?? this.drawnHistory,
    );
  }
}

/// Card is being drawn (flying animation)
class CardDrawingState extends CardDrawState {
  final EventCard card;
  final int remainingCards;

  const CardDrawingState({
    required this.card,
    required this.remainingCards,
  });

  @override
  List<Object?> get props => [card, remainingCards];
}

/// Card is revealed (flip animation completed)
class CardRevealedState extends CardDrawState {
  final EventCard card;
  final List<ExitCondition> exitConditions;
  final DeckDistributorStatus distributorStatus;
  final bool hasConflict;
  final String? conflictMessage;
  final int drawnCount;

  const CardRevealedState({
    required this.card,
    required this.exitConditions,
    required this.distributorStatus,
    this.hasConflict = false,
    this.conflictMessage,
    required this.drawnCount,
  });

  @override
  List<Object?> get props => [
        card,
        exitConditions,
        distributorStatus,
        hasConflict,
        conflictMessage,
        drawnCount,
      ];
}

/// Exit condition triggered state
class ExitTriggeredState extends CardDrawState {
  final ExitCondition condition;
  final String message;

  const ExitTriggeredState({
    required this.condition,
    required this.message,
  });

  @override
  List<Object?> get props => [condition, message];
}

/// Scene completed
class CardDrawCompleted extends CardDrawState {
  final List<EventCard> allDrawnCards;
  final int totalDrawn;

  const CardDrawCompleted({
    required this.allDrawnCards,
    required this.totalDrawn,
  });

  @override
  List<Object?> get props => [allDrawnCards, totalDrawn];
}

/// Error state
class CardDrawError extends CardDrawState {
  final String message;

  const CardDrawError(this.message);

  @override
  List<Object?> get props => [message];
}
