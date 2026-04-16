import 'package:equatable/equatable.dart';
import '../../../domain/entities/player.dart';
import '../../../domain/entities/world_position.dart';
import '../../../domain/entities/game_card.dart';

abstract class OpenWorldState extends Equatable {
  const OpenWorldState();

  @override
  List<Object?> get props => [];
}

class OpenWorldInitial extends OpenWorldState {}

class OpenWorldLoading extends OpenWorldState {}

class OpenWorldLoaded extends OpenWorldState {
  final Player player;
  final List<WorldLocation> locations;
  final WorldLocation? currentLocation;
  final List<GameCard> playerCards; // P0 Fix: Track player card collection
  final int totalGold;
  final int battlesWon;

  const OpenWorldLoaded({
    required this.player,
    required this.locations,
    this.currentLocation,
    this.playerCards = const [],
    this.totalGold = 0,
    this.battlesWon = 0,
  });

  @override
  List<Object?> get props => [player, locations, currentLocation, playerCards, totalGold, battlesWon];

  OpenWorldLoaded copyWith({
    Player? player,
    List<WorldLocation>? locations,
    WorldLocation? currentLocation,
    List<GameCard>? playerCards,
    int? totalGold,
    int? battlesWon,
  }) {
    return OpenWorldLoaded(
      player: player ?? this.player,
      locations: locations ?? this.locations,
      currentLocation: currentLocation ?? this.currentLocation,
      playerCards: playerCards ?? this.playerCards,
      totalGold: totalGold ?? this.totalGold,
      battlesWon: battlesWon ?? this.battlesWon,
    );
  }
}

class OpenWorldError extends OpenWorldState {
  final String message;

  const OpenWorldError(this.message);

  @override
  List<Object?> get props => [message];
}
