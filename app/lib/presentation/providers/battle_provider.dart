import 'package:flutter/foundation.dart';
import '../../../domain/entities/game_card.dart';
import '../../../domain/entities/player.dart';
import '../../../domain/entities/enemy.dart';

/// Battle phase enum
enum BattlePhase {
  playerTurn,
  enemyTurn,
  actionResolution,
  gameOver,
}

/// BattleProvider - ChangeNotifier based state management for battles
/// Migrated from BattleBloc (flutter_bloc) to Provider architecture
class BattleProvider extends ChangeNotifier {
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
  bool _isLoading = false;
  String? _error;
  String _animationType = '';

  // Getters
  Player get player => _player;
  Enemy get enemy => _enemy;
  List<GameCard> get hand => _hand;
  List<GameCard> get selectedCards => _selectedCards;
  int get turn => _turn;
  BattlePhase get phase => _phase;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get animationType => _animationType;

  bool get isPlayerTurn => _phase == BattlePhase.playerTurn;
  bool get hasSelectedCards => _selectedCards.isNotEmpty;

  /// Start a new battle
  Future<void> startBattle(String enemyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _player = Player(
        id: 'player_1',
        name: 'Chrono Traveler',
        health: 100,
        maxHealth: 100,
        mana: 20,
        maxMana: 20,
      );

      _enemy = Enemy(
        id: enemyId,
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
      _animationType = '';

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to start battle: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select a card for attack
  void selectCard(GameCard card) {
    if (_phase != BattlePhase.playerTurn) return;

    if (!_selectedCards.any((c) => c.id == card.id)) {
      _selectedCards = [..._selectedCards, card];
      notifyListeners();
    }
  }

  /// Deselect a card
  void deselectCard(String cardId) {
    _selectedCards = _selectedCards.where((c) => c.id != cardId).toList();
    notifyListeners();
  }

  /// Clear all selected cards
  void clearSelectedCards() {
    _selectedCards = [];
    notifyListeners();
  }

  /// Execute attack with selected cards
  Future<void> executeAttack() async {
    if (_selectedCards.isEmpty) return;

    _animationType = 'attack';
    notifyListeners();

    int totalDamage = 0;
    for (final card in _selectedCards) {
      totalDamage += card.attack;
    }

    final damage = totalDamage - _enemy.defense ~/ 2;
    _enemy = _enemy.copyWith(
      health: (_enemy.health - damage).clamp(0, _enemy.maxHealth),
    );

    _hand = _hand.where((c) => !_selectedCards.contains(c)).toList();
    _selectedCards = [];

    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    _animationType = '';
    _checkBattleEnd();
  }

  /// Execute a skill card
  Future<void> executeSkill(GameCard card) async {
    _animationType = 'skill';
    notifyListeners();

    if (card.type == CardType.defense) {
      _player = _player.copyWith(
        mana: _player.mana + card.defense,
      );
    }

    _hand = _hand.where((c) => c.id != card.id).toList();

    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    _animationType = '';
    notifyListeners();
  }

  /// End player turn
  void endPlayerTurn() {
    _selectedCards = [];
    _phase = BattlePhase.enemyTurn;
    notifyListeners();

    _processEnemyTurn();
  }

  /// Process enemy turn
  Future<void> _processEnemyTurn() async {
    await Future.delayed(const Duration(milliseconds: 800));
    _enemyAttack();
  }

  /// Enemy attacks player
  Future<void> _enemyAttack() async {
    _animationType = 'enemy_attack';
    notifyListeners();

    final damage = _enemy.attack - 2;
    _player = _player.copyWith(
      health: (_player.health - damage).clamp(0, _player.maxHealth),
    );

    await Future.delayed(const Duration(milliseconds: 500));

    _turn++;
    _phase = BattlePhase.playerTurn;
    _animationType = '';

    _checkBattleEnd();
  }

  /// Check if battle has ended
  void _checkBattleEnd() {
    if (_enemy.health <= 0) {
      _phase = BattlePhase.gameOver;
      _animationType = 'victory';
    } else if (_player.health <= 0) {
      _phase = BattlePhase.gameOver;
      _animationType = 'defeat';
    }
    notifyListeners();
  }

  /// Check if player won
  bool get isVictory => _enemy.health <= 0 && _phase == BattlePhase.gameOver;

  /// Check if player lost
  bool get isDefeat => _player.health <= 0 && _phase == BattlePhase.gameOver;

  /// Generate initial battle hand
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
