/// API Configuration for ChronoCards backend
class ApiConfig {
  /// Backend base URL - ngrok forwarded server
  /// 8081端口由乃乃确认
  static const String baseUrl = 'http://139.196-140-64-154.cloudapps.ai:8081';

  /// API version prefix
  static const String apiVersion = '/api/v1';

  /// Full API base URL
  static String get apiBaseUrl => '$baseUrl$apiVersion';

  /// Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Headers
  static Map<String, String> get defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ============ ENDPOINTS ============

  /// POST - Register device and get playerId
  static const String registerPlayer = '$apiVersion/players';

  /// GET/POST - Save/Load player data (replace {id} with playerId)
  static String playerSave(String playerId) => '$apiVersion/players/$playerId/save';

  /// POST - Report battle actions/results
  static const String battleAction = '$apiVersion/battle/action';

  /// GET - Draw card from deck (replace {id} with deckId)
  static String drawCard(String deckId) => '$apiVersion/decks/$deckId/draw';

  /// POST - Equip item to player
  static String equipItem(String playerId) =>
      '$apiVersion/players/$playerId/inventory/equip';

  /// GET/POST - Player reputation
  static String reputation(String playerId) =>
      '$apiVersion/players/$playerId/reputation';
}
