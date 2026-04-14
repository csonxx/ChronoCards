import 'package:equatable/equatable.dart';

/// Enemy entity for battles
class Enemy extends Equatable {
  final String id;
  final String name;
  final int health;
  final int maxHealth;
  final int attack;
  final int defense;
  final int level;
  final String spriteAsset;
  final bool isBoss;

  const Enemy({
    required this.id,
    required this.name,
    required this.health,
    required this.maxHealth,
    required this.attack,
    required this.defense,
    required this.level,
    this.spriteAsset = '',
    this.isBoss = false,
  });

  Enemy copyWith({
    String? id,
    String? name,
    int? health,
    int? maxHealth,
    int? attack,
    int? defense,
    int? level,
    String? spriteAsset,
    bool? isBoss,
  }) {
    return Enemy(
      id: id ?? this.id,
      name: name ?? this.name,
      health: health ?? this.health,
      maxHealth: maxHealth ?? this.maxHealth,
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      level: level ?? this.level,
      spriteAsset: spriteAsset ?? this.spriteAsset,
      isBoss: isBoss ?? this.isBoss,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        health,
        maxHealth,
        attack,
        defense,
        level,
        spriteAsset,
        isBoss,
      ];
}
