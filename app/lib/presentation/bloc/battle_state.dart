import 'package:equatable/equatable.dart';
import '../../../domain/entities/game_card.dart';
import '../../../domain/entities/player.dart';
import '../../../domain/entities/enemy.dart';

abstract class BattleState extends Equatable {
  const BattleState();

  @override
  List<Object?> get props => [];
}

class BattleInitial extends BattleState {}

class BattleLoading extends BattleState {}

class BattleReady extends BattleState {
  final Player player;
  final Enemy enemy;
  final List<GameCard> hand;
  final int turn;
  final BattlePhase phase;

  const BattleReady({
    required this.player,
    required this.enemy,
    required this.hand,
    required this.turn,
    required this.phase,
  });

  @override
  List<Object?> get props => [player, enemy, hand, turn, phase];
}

class BattleInProgress extends BattleState {
  final Player player;
  final Enemy enemy;
  final List<GameCard> hand;
  final List<GameCard> selectedCards;
  final int turn;
  final BattlePhase phase;

  const BattleInProgress({
    required this.player,
    required this.enemy,
    required this.hand,
    required this.selectedCards,
    required this.turn,
    required this.phase,
  });

  @override
  List<Object?> get props => [
        player,
        enemy,
        hand,
        selectedCards,
        turn,
        phase,
      ];
}

class BattleActionInProgress extends BattleState {
  final String animationType;
  final Player player;
  final Enemy enemy;

  const BattleActionInProgress({
    required this.animationType,
    required this.player,
    required this.enemy,
  });

  @override
  List<Object?> get props => [animationType, player, enemy];
}

class BattleVictory extends BattleState {
  final Player player;
  final int rewards;

  const BattleVictory({required this.player, required this.rewards});

  @override
  List<Object?> get props => [player, rewards];
}

class BattleDefeat extends BattleState {
  final Player player;

  const BattleDefeat({required this.player});

  @override
  List<Object?> get props => [player];
}

class BattleError extends BattleState {
  final String message;

  const BattleError(this.message);

  @override
  List<Object?> get props => [message];
}

enum BattlePhase {
  playerTurn,
  enemyTurn,
  actionResolution,
  gameOver,
}
