import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Represents a region (大区) in the world map
/// 6 major regions: 明教(Mingjiao), 少林(Shaolin), 武当(Wudang), 镖局(Biaoju), 丐帮(Gaibang), 野外(Yewai)
class WorldRegion extends Equatable {
  final String id;
  final String name;
  final String displayName;
  final Color color;
  final Map<String, double> mapBounds; // left, top, right, bottom (0-1 normalized)
  final List<String> locationIds;
  final bool isUnlocked;

  const WorldRegion({
    required this.id,
    required this.name,
    required this.displayName,
    required this.color,
    required this.mapBounds,
    this.locationIds = const [],
    this.isUnlocked = false,
  });

  @override
  List<Object?> get props => [id, name, displayName, color, mapBounds, locationIds, isUnlocked];
}

/// Default world regions with their positions
List<WorldRegion> getDefaultWorldRegions() {
  return [
    WorldRegion(
      id: 'mingjiao',
      name: 'Mingjiao',
      displayName: '明教',
      color: const Color(0xFFFF6B35),
      mapBounds: {'left': 0.7, 'top': 0.1, 'right': 0.95, 'bottom': 0.35},
      isUnlocked: true,
    ),
    WorldRegion(
      id: 'shaolin',
      name: 'Shaolin',
      displayName: '少林',
      color: const Color(0xFFFFD700),
      mapBounds: {'left': 0.3, 'top': 0.1, 'right': 0.55, 'bottom': 0.3},
      isUnlocked: true,
    ),
    WorldRegion(
      id: 'wudang',
      name: 'Wudang',
      displayName: '武当',
      color: const Color(0xFF4ECDC4),
      mapBounds: {'left': 0.05, 'top': 0.25, 'right': 0.3, 'bottom': 0.55},
      isUnlocked: true,
    ),
    WorldRegion(
      id: 'biaoju',
      name: 'Biaoju',
      displayName: '镖局',
      color: const Color(0xFF8B4513),
      mapBounds: {'left': 0.35, 'top': 0.4, 'right': 0.65, 'bottom': 0.65},
      isUnlocked: true,
    ),
    WorldRegion(
      id: 'gaibang',
      name: 'Gaibang',
      displayName: '丐帮',
      color: const Color(0xFF9ACD32),
      mapBounds: {'left': 0.05, 'top': 0.6, 'right': 0.35, 'bottom': 0.9},
      isUnlocked: false,
    ),
    WorldRegion(
      id: 'yewai',
      name: 'Yewai',
      displayName: '野外',
      color: const Color(0xFF228B22),
      mapBounds: {'left': 0.4, 'top': 0.7, 'right': 0.9, 'bottom': 0.95},
      isUnlocked: false,
    ),
  ];
}
