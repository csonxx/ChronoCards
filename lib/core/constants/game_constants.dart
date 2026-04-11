/// Game constants for ChronoCards
class GameConstants {
  GameConstants._();

  // Screen identifiers
  static const String s2OpenWorld = 's2_open_world';
  static const String s3CardDraw = 's3_card_draw';
  static const String s5Battle = 's5_battle';

  // Card game constants
  static const int maxHandSize = 10;
  static const int deckSize = 30;
  static const int drawCardCount = 5;
  
  // Battle constants
  static const double battleFieldWidth = 375.0;
  static const double battleFieldHeight = 667.0;
  
  // Animation durations (ms)
  static const int cardDrawDuration = 800;
  static const int cardFlipDuration = 500;
  static const int attackAnimationDuration = 300;
  static const int skillAnimationDuration = 600;
}

/// Asset paths
class AssetPaths {
  AssetPaths._();

  static const String imagesPath = 'assets/images/';
  static const String audioPath = 'assets/audio/';
  
  // Placeholder images (to be replaced with actual assets)
  static const String cardBack = '${imagesPath}card_back.png';
  static const String cardFrame = '${imagesPath}card_frame.png';
  static const String playerAvatar = '${imagesPath}player_avatar.png';
  static const String enemyAvatar = '${imagesPath}enemy_avatar.png';
  static const String mapBackground = '${imagesPath}map_background.png';
}
