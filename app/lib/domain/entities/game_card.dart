import 'package:equatable/equatable.dart';

/// Card rarity levels
enum CardRarity { common, uncommon, rare, epic, legendary }

/// Card types
enum CardType { attack, defense, skill, magic, special }

/// Represents a game card in ChronoCards
class GameCard extends Equatable {
  final String id;
  final String name;
  final String description;
  final CardType type;
  final CardRarity rarity;
  final int cost; // Mana/Energy cost
  final int attack;
  final int defense;
  final String imageAsset;
  final bool isFlipped;

  const GameCard({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.rarity,
    required this.cost,
    required this.attack,
    required this.defense,
    this.imageAsset = '',
    this.isFlipped = false,
  });

  GameCard copyWith({
    String? id,
    String? name,
    String? description,
    CardType? type,
    CardRarity? rarity,
    int? cost,
    int? attack,
    int? defense,
    String? imageAsset,
    bool? isFlipped,
  }) {
    return GameCard(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      cost: cost ?? this.cost,
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      imageAsset: imageAsset ?? this.imageAsset,
      isFlipped: isFlipped ?? this.isFlipped,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        type,
        rarity,
        cost,
        attack,
        defense,
        imageAsset,
        isFlipped,
      ];

  /// Convert to JSON for API storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'rarity': rarity.name,
      'cost': cost,
      'attack': attack,
      'defense': defense,
    };
  }

  /// Create from JSON
  factory GameCard.fromJson(Map<String, dynamic> json) {
    return GameCard(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      type: CardType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => CardType.special,
      ),
      rarity: CardRarity.values.firstWhere(
        (r) => r.name == json['rarity'],
        orElse: () => CardRarity.common,
      ),
      cost: json['cost'] ?? 0,
      attack: json['attack'] ?? 0,
      defense: json['defense'] ?? 0,
      imageAsset: json['image_asset'] ?? '',
    );
  }
}
