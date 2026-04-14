import 'package:equatable/equatable.dart';

/// Represents a location (场景/地点) in the world map
/// Can be: city/town/village/wilderness/dungeon/inn/special
class WorldLocation extends Equatable {
  final String id;
  final String name;
  final String description;
  final String type; // city, town, village, wilderness, dungeon, inn, special
  final String regionId;
  final double mapX; // 0-1 normalized position on map
  final double mapY;
  final String iconAsset;
  final bool isUnlocked;
  final int recommendedLevel;
  final int dangerLevel; // 0-5
  final List<String> availableDealers; // tea, bounty, enemy, inn, merchant
  final String? backgroundMusic;
  final int visitCount;
  final List<String> connectedLocationIds;

  const WorldLocation({
    required this.id,
    required this.name,
    this.description = '',
    required this.type,
    required this.regionId,
    required this.mapX,
    required this.mapY,
    this.iconAsset = '',
    this.isUnlocked = false,
    this.recommendedLevel = 1,
    this.dangerLevel = 0,
    this.availableDealers = const [],
    this.backgroundMusic,
    this.visitCount = 0,
    this.connectedLocationIds = const [],
  });

  WorldLocation copyWith({
    String? id,
    String? name,
    String? description,
    String? type,
    String? regionId,
    double? mapX,
    double? mapY,
    String? iconAsset,
    bool? isUnlocked,
    int? recommendedLevel,
    int? dangerLevel,
    List<String>? availableDealers,
    String? backgroundMusic,
    int? visitCount,
    List<String>? connectedLocationIds,
  }) {
    return WorldLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      regionId: regionId ?? this.regionId,
      mapX: mapX ?? this.mapX,
      mapY: mapY ?? this.mapY,
      iconAsset: iconAsset ?? this.iconAsset,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      recommendedLevel: recommendedLevel ?? this.recommendedLevel,
      dangerLevel: dangerLevel ?? this.dangerLevel,
      availableDealers: availableDealers ?? this.availableDealers,
      backgroundMusic: backgroundMusic ?? this.backgroundMusic,
      visitCount: visitCount ?? this.visitCount,
      connectedLocationIds: connectedLocationIds ?? this.connectedLocationIds,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        type,
        regionId,
        mapX,
        mapY,
        iconAsset,
        isUnlocked,
        recommendedLevel,
        dangerLevel,
        availableDealers,
        backgroundMusic,
        visitCount,
        connectedLocationIds,
      ];
}

/// Default locations for the world map
List<WorldLocation> getDefaultWorldLocations() {
  return [
    // Mingjiao region
    const WorldLocation(
      id: 'mingjiao_hq',
      name: '明教总坛',
      description: '圣火熊熊，驱散黑暗。明教圣地，气势恢宏。',
      type: 'special',
      regionId: 'mingjiao',
      mapX: 0.82,
      mapY: 0.22,
      isUnlocked: true,
      recommendedLevel: 10,
      dangerLevel: 4,
      availableDealers: ['tea', 'merchant'],
      backgroundMusic: 'mingjiao_theme',
    ),
    const WorldLocation(
      id: 'mingjiao_outpost',
      name: '火焰寨',
      description: '明教外围据点，常有巡逻弟子。',
      type: 'town',
      regionId: 'mingjiao',
      mapX: 0.75,
      mapY: 0.28,
      isUnlocked: true,
      recommendedLevel: 5,
      dangerLevel: 2,
      availableDealers: ['tea'],
    ),

    // Shaolin region
    const WorldLocation(
      id: 'shaolin_temple',
      name: '少林寺',
      description: '天下武功出少林，禅武合一之地。',
      type: 'special',
      regionId: 'shaolin',
      mapX: 0.42,
      mapY: 0.18,
      isUnlocked: true,
      recommendedLevel: 8,
      dangerLevel: 3,
      availableDealers: ['inn', 'bounty'],
      backgroundMusic: 'shaolin_theme',
    ),
    const WorldLocation(
      id: 'shaolin_village',
      name: '少林脚',
      description: '少林寺山脚小镇，武者云集。',
      type: 'town',
      regionId: 'shaolin',
      mapX: 0.38,
      mapY: 0.25,
      isUnlocked: true,
      recommendedLevel: 3,
      dangerLevel: 1,
      availableDealers: ['tea', 'merchant', 'inn'],
    ),

    // Wudang region
    const WorldLocation(
      id: 'wudang_mountain',
      name: '武当山',
      description: '道骨仙风，剑法无双。',
      type: 'special',
      regionId: 'wudang',
      mapX: 0.17,
      mapY: 0.38,
      isUnlocked: true,
      recommendedLevel: 8,
      dangerLevel: 3,
      availableDealers: ['inn', 'tea'],
      backgroundMusic: 'wudang_theme',
    ),
    const WorldLocation(
      id: 'wudang_village',
      name: '武当镇',
      description: '道教圣地脚下，游客往来不绝。',
      type: 'town',
      regionId: 'wudang',
      mapX: 0.12,
      mapY: 0.48,
      isUnlocked: true,
      recommendedLevel: 3,
      dangerLevel: 1,
      availableDealers: ['tea', 'merchant'],
    ),

    // Biaoju region
    const WorldLocation(
      id: 'biaoju_hq',
      name: '镖局总局',
      description: '天下镖局，保驾护航。',
      type: 'special',
      regionId: 'biaoju',
      mapX: 0.50,
      mapY: 0.50,
      isUnlocked: true,
      recommendedLevel: 5,
      dangerLevel: 2,
      availableDealers: ['bounty', 'merchant'],
      backgroundMusic: 'biaoju_theme',
    ),
    const WorldLocation(
      id: 'biaoju_station',
      name: '平安驿站',
      description: '镖局分支，提供护送服务。',
      type: 'inn',
      regionId: 'biaoju',
      mapX: 0.60,
      mapY: 0.58,
      isUnlocked: true,
      recommendedLevel: 2,
      dangerLevel: 1,
      availableDealers: ['inn', 'tea'],
    ),

    // Gaibang region (locked)
    const WorldLocation(
      id: 'gaibang_den',
      name: '丐帮总舵',
      description: '天下第一大帮，弟子遍布天下。',
      type: 'special',
      regionId: 'gaibang',
      mapX: 0.20,
      mapY: 0.72,
      isUnlocked: false,
      recommendedLevel: 12,
      dangerLevel: 5,
      availableDealers: ['bounty', 'enemy'],
      backgroundMusic: 'gaibang_theme',
    ),
    const WorldLocation(
      id: 'gaibang_outpost',
      name: '丐帮分舵',
      description: '隐藏在市井中的丐帮据点。',
      type: 'village',
      regionId: 'gaibang',
      mapX: 0.28,
      mapY: 0.82,
      isUnlocked: false,
      recommendedLevel: 6,
      dangerLevel: 3,
      availableDealers: ['tea'],
    ),

    // Yewai (wilderness) region (locked)
    const WorldLocation(
      id: 'yewai_forest',
      name: '幽冥林',
      description: '迷雾笼罩的古林，危险与机遇并存。',
      type: 'wilderness',
      regionId: 'yewai',
      mapX: 0.65,
      mapY: 0.78,
      isUnlocked: false,
      recommendedLevel: 15,
      dangerLevel: 5,
      availableDealers: ['enemy'],
      backgroundMusic: 'wilderness_theme',
    ),
    const WorldLocation(
      id: 'yewai_dungeon',
      name: '古墓派',
      description: '神秘古墓，埋藏无数宝藏与机关。',
      type: 'dungeon',
      regionId: 'yewai',
      mapX: 0.78,
      mapY: 0.88,
      isUnlocked: false,
      recommendedLevel: 18,
      dangerLevel: 5,
      availableDealers: ['enemy', 'merchant'],
      backgroundMusic: 'dungeon_theme',
    ),
  ];
}
