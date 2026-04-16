import 'package:equatable/equatable.dart';
import '../../../domain/entities/world_position.dart';
import '../../../domain/entities/game_card.dart';

abstract class OpenWorldEvent extends Equatable {
  const OpenWorldEvent();

  @override
  List<Object?> get props => [];
}

class LoadOpenWorld extends OpenWorldEvent {}

class MoveToLocation extends OpenWorldEvent {
  final WorldLocation location;

  const MoveToLocation(this.location);

  @override
  List<Object?> get props => [location];
}

class InteractWithLocation extends OpenWorldEvent {
  final WorldLocation location;

  const InteractWithLocation(this.location);

  @override
  List<Object?> get props => [location];
}

/// P0 Fix: Battle completed - mark location as defeated and grant rewards
class BattleCompleted extends OpenWorldEvent {
  final String locationId;
  final int experienceGained;
  final int goldGained;
  final GameCard? cardDrop;

  const BattleCompleted({
    required this.locationId,
    this.experienceGained = 50,
    this.goldGained = 25,
    this.cardDrop,
  });

  @override
  List<Object?> get props => [locationId, experienceGained, goldGained, cardDrop];
}

/// P0 Fix: Player card collection for persistence
class AddCardToCollection extends OpenWorldEvent {
  final GameCard card;

  const AddCardToCollection(this.card);

  @override
  List<Object?> get props => [card];
}
