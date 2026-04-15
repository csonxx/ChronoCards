import 'package:equatable/equatable.dart';
import '../../../domain/entities/game_card.dart';

abstract class BattleEvent extends Equatable {
  const BattleEvent();

  @override
  List<Object?> get props => [];
}

class StartBattle extends BattleEvent {
  final String enemyId;

  const StartBattle(this.enemyId);

  @override
  List<Object?> get props => [enemyId];
}

class SelectCardForAttack extends BattleEvent {
  final GameCard card;

  const SelectCardForAttack(this.card);

  @override
  List<Object?> get props => [card];
}

class DeselectCard extends BattleEvent {
  final String cardId;

  const DeselectCard(this.cardId);

  @override
  List<Object?> get props => [cardId];
}

class ExecuteAttack extends BattleEvent {}

class ExecuteSkill extends BattleEvent {
  final GameCard card;

  const ExecuteSkill(this.card);

  @override
  List<Object?> get props => [card];
}

class EndPlayerTurn extends BattleEvent {}

class EnemyAttack extends BattleEvent {}

class ProcessEnemyTurn extends BattleEvent {}

class CheckBattleEnd extends BattleEvent {}
