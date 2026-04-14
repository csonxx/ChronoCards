import 'package:equatable/equatable.dart';

/// Represents a location in the open world
class WorldLocation extends Equatable {
  final String id;
  final String name;
  final String description;
  final double x;
  final double y;
  final String iconAsset;
  final bool isUnlocked;
  final bool isCompleted;
  final int recommendedLevel;
  final WorldLocationType type;

  const WorldLocation({
    required this.id,
    required this.name,
    required this.description,
    required this.x,
    required this.y,
    this.iconAsset = '',
    this.isUnlocked = false,
    this.isCompleted = false,
    this.recommendedLevel = 1,
    required this.type,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        x,
        y,
        iconAsset,
        isUnlocked,
        isCompleted,
        recommendedLevel,
        type,
      ];
}

enum WorldLocationType {
  town,
  dungeon,
  battle,
  cardShop,
  event,
  boss,
}
