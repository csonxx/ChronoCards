import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/game_card.dart';
import '../../../domain/entities/player.dart';
import '../../../domain/entities/enemy.dart';
import 'battle_event.dart';
import 'battle_state.dart';

class BattleBloc extends Bloc<BattleEvent, BattleState> {
  Player _player = const Player(id: 'player_1', name: 'Player');
  Enemy _enemy = const Enemy(
    id: 'enemy_1',
    name: 'Shadow Fiend',
    health: 50,
    maxHealth: 50,
    attack: 8,
    defense: 5,
    level: 1,
  );
  List<GameCard> _hand = [];
  List<GameCard> _selectedCards = [];
  int _turn = 1;
  BattlePhase _phase = BattlePhase.playerTurn;

  BattleBloc() : super(BattleInitial()) {
    on<StartBattle>(_onStartBattle);
    on<SelectCardForAttack>(_onSelectCard);
    on<DeselectCard>(_onDeselectCard);
    on<ExecuteAttack>(_onExecuteAttack);
    on<ExecuteSkill>(_onExecuteSkill);
    on<EndPlayerTurn>(_onEndPlayerTurn);
    on<EnemyAttack>(_onEnemyAttack);
    on<ProcessEnemyTurn>(_onProcessEnemyTurn);
    on<CheckBattleEnd>(_onCheckBattleEnd);
  }

  Future<void> _onStartBattle(
    StartBattle event,
    Emitter<BattleState> emit,
  ) async {
    emit(BattleLoading());
    try {
      _player = Player(
        id: 'player_1',
        name: 'Chrono Traveler',
        health: 100,
        maxHealth: 100,
        mana: 20,
        maxMana: 20,
      );

      _enemy = const Enemy(
        id: 'enemy_1',
        name: 'Shadow Fiend',
        health: 80,
        maxHealth: 80,
        attack: 12,
        defense: 5,
        level: 1,
      );

      _hand = _generateBattleHand();
      _selectedCards = [];
      _turn = 1;
      _phase = BattlePhase.playerTurn;

      emit(BattleInProgress(
        player: _player,
        enemy: _enemy,
        hand: _hand,
        selectedCards: _selectedCards,
        turn: _turn,
        phase: _phase,
      ));
    } catch (e) {
      emit(BattleError('Failed to start battle: $e'));
    }
  }

  void _onSelectCard(SelectCardForAttack event, Emitter<BattleState> emit) {
    if (_phase != BattlePhase.playerTurn) return;

    if (!_selectedCards.any((c) => c.id == event.card.id)) {
      _selectedCards = [..._selectedCards, event.card];
    }

    emit(BattleInProgress(
      player: _player,
      enemy: _enemy,
      hand: _hand,
      selectedCards: _selectedCards,
      turn: _turn,
      phase: _phase,
    ));
  }

  void _onDeselectCard(DeselectCard event, Emitter<BattleState> emit) {
    _selectedCards = _selectedCards.where((c) => c.id != event.cardId).toList();

    emit(BattleInProgress(
      player: _player,
      enemy: _enemy,
      hand: _hand,
      selectedCards: _selectedCards,
      turn: _turn,
      phase: _phase,
    ));
  }

  Future<void> _onExecuteAttack(
    ExecuteAttack event,
    Emitter<BattleState> emit,
  ) async {
    if (_selectedCards.isEmpty) return;

    emit(BattleActionInProgress(
      animationType: 'attack',
      player: _player,
      enemy: _enemy,
    ));

    int totalDamage = 0;
    for (final card in _selectedCards) {
      totalDamage += card.attack;
    }

    // Apply damage (simplified - should factor in defense)
    final damage = totalDamage - _enemy.defense ~/ 2;
    _enemy = _enemy.copyWith(
      health: (_enemy.health - damage).clamp(0, _enemy.maxHealth),
    );

    _hand = _hand.where((c) => !_selectedCards.contains(c)).toList();
    _selectedCards = [];

    await Future.delayed(const Duration(milliseconds: 500));

    add(CheckBattleEnd());
  }

  Future<void> _onExecuteSkill(
    ExecuteSkill event,
    Emitter<BattleState> emit,
  ) async {
    emit(BattleActionInProgress(
      animationType: 'skill',
      player: _player,
      enemy: _enemy,
    ));

    // Handle different skill types
    if (event.card.type == CardType.defense) {
      _player = _player.copyWith(
        mana: _player.mana + event.card.defense,
      );
    }

    _hand = _hand.where((c) => c.id != event.card.id).toList();

    await Future.delayed(const Duration(milliseconds: 500));

    emit(BattleInProgress(
      player: _player,
      enemy: _enemy,
      hand: _hand,
      selectedCards: [],
      turn: _turn,
      phase: _phase,
    ));
  }

  void _onEndPlayerTurn(EndPlayerTurn event, Emitter<BattleState> emit) {
    _selectedCards = [];
    _phase = BattlePhase.enemyTurn;

    emit(BattleInProgress(
      player: _player,
      enemy: _enemy,
      hand: _hand,
      selectedCards: [],
      turn: _turn,
      phase: _phase,
    ));

    add(ProcessEnemyTurn());
  }

  Future<void> _onProcessEnemyTurn(
    ProcessEnemyTurn event,
    Emitter<BattleState> emit,
  ) async {
    await Future.delayed(const Duration(milliseconds: 800));

    add(EnemyAttack());
  }

  Future<void> _onEnemyAttack(
    EnemyAttack event,
    Emitter<BattleState> emit,
  ) async {
    emit(BattleActionInProgress(
      animationType: 'enemy_attack',
      player: _player,
      enemy: _enemy,
    ));

    final damage = _enemy.attack - 2; // Simplified defense
    _player = _player.copyWith(
      health: (_player.health - damage).clamp(0, _player.maxHealth),
    );

    await Future.delayed(const Duration(milliseconds: 500));

    _turn++;
    _phase = BattlePhase.playerTurn;

    add(CheckBattleEnd());
  }

  void _onCheckBattleEnd(CheckBattleEnd event, Emitter<BattleState> emit) {
    if (_enemy.health <= 0) {
      emit(BattleVictory(
        player: _player,
        rewards: 50,
      ));
    } else if (_player.health <= 0) {
      emit(BattleDefeat(player: _player));
    } else {
      emit(BattleInProgress(
        player: _player,
        enemy: _enemy,
        hand: _hand,
        selectedCards: _selectedCards,
        turn: _turn,
        phase: _phase,
      ));
    }
  }

  List<GameCard> _generateBattleHand() {
    return [
      const GameCard(
        id: 'battle_card_1',
        name: 'Quick Strike',
        description: 'Fast attack',
        type: CardType.attack,
        rarity: CardRarity.common,
        cost: 1,
        attack: 8,
        defense: 0,
      ),
      const GameCard(
        id: 'battle_card_2',
        name: 'Heavy Blow',
        description: 'Strong attack',
        type: CardType.attack,
        rarity: CardRarity.uncommon,
        cost: 3,
        attack: 15,
        defense: 0,
      ),
      const GameCard(
        id: 'battle_card_3',
        name: 'Stone Wall',
        description: 'Defensive stance',
        type: CardType.defense,
        rarity: CardRarity.common,
        cost: 2,
        attack: 0,
        defense: 10,
      ),
      const GameCard(
        id: 'battle_card_4',
        name: 'Fireball',
        description: 'Magic attack',
        type: CardType.magic,
        rarity: CardRarity.rare,
        cost: 4,
        attack: 20,
        defense: 0,
      ),
    ];
  }
}
