import 'package:equatable/equatable.dart';
import 'game_card.dart';

/// Player entity containing all player data
class Player extends Equatable {
  final String id;
  final String name;
  final int level;
  final int health;
  final int maxHealth;
  final int mana;
  final int maxMana;
  final int energy;
  final int maxEnergy;
  final List<GameCard> deck;
  final List<GameCard> hand;
  final List<GameCard> discardPile;
  final int crystals; // Premium currency
  final int coins; // Basic currency

  const Player({
    required this.id,
    required this.name,
    this.level = 1,
    this.health = 100,
    this.maxHealth = 100,
    this.mana = 20,
    this.maxMana = 20,
    this.energy = 3,
    this.maxEnergy = 3,
    this.deck = const [],
    this.hand = const [],
    this.discardPile = const [],
    this.crystals = 0,
    this.coins = 100,
  });

  Player copyWith({
    String? id,
    String? name,
    int? level,
    int? health,
    int? maxHealth,
    int? mana,
    int? maxMana,
    int? energy,
    int? maxEnergy,
    List<GameCard>? deck,
    List<GameCard>? hand,
    List<GameCard>? discardPile,
    int? crystals,
    int? coins,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      health: health ?? this.health,
      maxHealth: maxHealth ?? this.maxHealth,
      mana: mana ?? this.mana,
      maxMana: maxMana ?? this.maxMana,
      energy: energy ?? this.energy,
      maxEnergy: maxEnergy ?? this.maxEnergy,
      deck: deck ?? this.deck,
      hand: hand ?? this.hand,
      discardPile: discardPile ?? this.discardPile,
      crystals: crystals ?? this.crystals,
      coins: coins ?? this.coins,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        level,
        health,
        maxHealth,
        mana,
        maxMana,
        energy,
        maxEnergy,
        deck,
        hand,
        discardPile,
        crystals,
        coins,
      ];
}
