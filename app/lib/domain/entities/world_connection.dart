import 'package:equatable/equatable.dart';

/// Represents a connection (path) between two locations on the world map
/// Path types: road, trekking, teleport, story_locked
class WorldConnection extends Equatable {
  final String id;
  final String fromLocationId;
  final String toLocationId;
  final String pathType; // road, trekking, teleport, story_locked
  final bool isLocked;
  final int travelTimeMinutes;
  final int dangerLevel; // 0-5
  final double encounterChance; // 0.0 - 1.0

  const WorldConnection({
    required this.id,
    required this.fromLocationId,
    required this.toLocationId,
    required this.pathType,
    this.isLocked = false,
    this.travelTimeMinutes = 0,
    this.dangerLevel = 0,
    this.encounterChance = 0.0,
  });

  WorldConnection copyWith({
    String? id,
    String? fromLocationId,
    String? toLocationId,
    String? pathType,
    bool? isLocked,
    int? travelTimeMinutes,
    int? dangerLevel,
    double? encounterChance,
  }) {
    return WorldConnection(
      id: id ?? this.id,
      fromLocationId: fromLocationId ?? this.fromLocationId,
      toLocationId: toLocationId ?? this.toLocationId,
      pathType: pathType ?? this.pathType,
      isLocked: isLocked ?? this.isLocked,
      travelTimeMinutes: travelTimeMinutes ?? this.travelTimeMinutes,
      dangerLevel: dangerLevel ?? this.dangerLevel,
      encounterChance: encounterChance ?? this.encounterChance,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fromLocationId,
        toLocationId,
        pathType,
        isLocked,
        travelTimeMinutes,
        dangerLevel,
        encounterChance,
      ];
}

/// Default connections between world locations
List<WorldConnection> getDefaultWorldConnections() {
  return [
    // Mingjiao connections
    const WorldConnection(
      id: 'conn_mingjiao_hq_to_outpost',
      fromLocationId: 'mingjiao_hq',
      toLocationId: 'mingjiao_outpost',
      pathType: 'road',
      travelTimeMinutes: 10,
      dangerLevel: 1,
      encounterChance: 0.1,
    ),
    const WorldConnection(
      id: 'conn_mingjiao_outpost_to_biaoju',
      fromLocationId: 'mingjiao_outpost',
      toLocationId: 'biaoju_hq',
      pathType: 'trekking',
      travelTimeMinutes: 30,
      dangerLevel: 2,
      encounterChance: 0.3,
    ),

    // Shaolin connections
    const WorldConnection(
      id: 'conn_shaolin_temple_to_village',
      fromLocationId: 'shaolin_temple',
      toLocationId: 'shaolin_village',
      pathType: 'road',
      travelTimeMinutes: 15,
      dangerLevel: 1,
      encounterChance: 0.1,
    ),
    const WorldConnection(
      id: 'conn_shaolin_village_to_biaoju',
      fromLocationId: 'shaolin_village',
      toLocationId: 'biaoju_hq',
      pathType: 'road',
      travelTimeMinutes: 20,
      dangerLevel: 1,
      encounterChance: 0.2,
    ),
    const WorldConnection(
      id: 'conn_shaolin_to_wudang',
      fromLocationId: 'shaolin_temple',
      toLocationId: 'wudang_mountain',
      pathType: 'trekking',
      travelTimeMinutes: 45,
      dangerLevel: 3,
      encounterChance: 0.4,
    ),

    // Wudang connections
    const WorldConnection(
      id: 'conn_wudang_mountain_to_village',
      fromLocationId: 'wudang_mountain',
      toLocationId: 'wudang_village',
      pathType: 'road',
      travelTimeMinutes: 20,
      dangerLevel: 1,
      encounterChance: 0.1,
    ),
    const WorldConnection(
      id: 'conn_wudang_village_to_gaibang',
      fromLocationId: 'wudang_village',
      toLocationId: 'gaibang_den',
      pathType: 'trekking',
      travelTimeMinutes: 35,
      dangerLevel: 2,
      encounterChance: 0.3,
      isLocked: true, // Requires story progress
    ),
    const WorldConnection(
      id: 'conn_wudang_to_shaolin',
      fromLocationId: 'wudang_village',
      toLocationId: 'shaolin_village',
      pathType: 'road',
      travelTimeMinutes: 25,
      dangerLevel: 2,
      encounterChance: 0.25,
    ),

    // Biaoju connections
    const WorldConnection(
      id: 'conn_biaoju_hq_to_station',
      fromLocationId: 'biaoju_hq',
      toLocationId: 'biaoju_station',
      pathType: 'road',
      travelTimeMinutes: 15,
      dangerLevel: 1,
      encounterChance: 0.15,
    ),
    const WorldConnection(
      id: 'conn_biaoju_station_to_yewai',
      fromLocationId: 'biaoju_station',
      toLocationId: 'yewai_forest',
      pathType: 'trekking',
      travelTimeMinutes: 40,
      dangerLevel: 4,
      encounterChance: 0.5,
      isLocked: true, // Requires level
    ),

    // Gaibang connections
    const WorldConnection(
      id: 'conn_gaibang_den_to_outpost',
      fromLocationId: 'gaibang_den',
      toLocationId: 'gaibang_outpost',
      pathType: 'road',
      travelTimeMinutes: 10,
      dangerLevel: 2,
      encounterChance: 0.2,
    ),
    const WorldConnection(
      id: 'conn_gaibang_outpost_to_yewai',
      fromLocationId: 'gaibang_outpost',
      toLocationId: 'yewai_forest',
      pathType: 'trekking',
      travelTimeMinutes: 50,
      dangerLevel: 4,
      encounterChance: 0.5,
      isLocked: true,
    ),

    // Yewai connections
    const WorldConnection(
      id: 'conn_yewai_forest_to_dungeon',
      fromLocationId: 'yewai_forest',
      toLocationId: 'yewai_dungeon',
      pathType: 'trekking',
      travelTimeMinutes: 30,
      dangerLevel: 5,
      encounterChance: 0.7,
      isLocked: true,
    ),

    // Cross-region connections
    const WorldConnection(
      id: 'conn_mingjiao_to_shaolin',
      fromLocationId: 'mingjiao_hq',
      toLocationId: 'shaolin_temple',
      pathType: 'teleport',
      travelTimeMinutes: 5,
      dangerLevel: 0,
      encounterChance: 0.0,
      isLocked: true, // Requires special item
    ),
  ];
}
