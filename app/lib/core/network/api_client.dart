import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// API Client for ChronoCards backend communication
/// Uses HTTP (not WebSocket) for initial integration
class ApiClient {
  final http.Client _client;
  final String _baseUrl;

  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.apiBaseUrl;

  /// Dispose the client
  void dispose() {
    _client.close();
  }

  /// ============ Player APIs ============

  /// Register device and get playerId
  /// POST /api/v1/players
  Future<ApiResponse<PlayerRegistrationResponse>> registerPlayer(
      String deviceId) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl${ApiConfig.registerPlayer}'),
            headers: ApiConfig.defaultHeaders,
            body: json.encode({'device_id': deviceId}),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return ApiResponse.success(PlayerRegistrationResponse.fromJson(data));
      }
      return ApiResponse.error(
          'Registration failed: ${response.statusCode}', response.statusCode);
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  /// Get player save data
  /// GET /api/v1/players/{playerId}/save
  Future<ApiResponse<Map<String, dynamic>>> getPlayerSave(String playerId,
      {String? saveId}) async {
    try {
      var url = '$_baseUrl${ApiConfig.playerSave(playerId)}';
      if (saveId != null) {
        url += '?save_id=$saveId';
      }

      final response = await _client
          .get(Uri.parse(url), headers: ApiConfig.defaultHeaders)
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data);
      }
      return ApiResponse.error('Failed to get save: ${response.statusCode}',
          response.statusCode);
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  /// Save player data
  /// POST /api/v1/players/{playerId}/save
  Future<ApiResponse<Map<String, dynamic>>> savePlayerData(
    String playerId, {
    required Map<String, dynamic> gameState,
    String? saveName,
  }) async {
    try {
      final body = {
        'game_state': gameState,
        if (saveName != null) 'save_name': saveName,
      };

      final response = await _client
          .post(
            Uri.parse('$_baseUrl${ApiConfig.playerSave(playerId)}'),
            headers: ApiConfig.defaultHeaders,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return ApiResponse.success(data);
      }
      return ApiResponse.error('Failed to save: ${response.statusCode}',
          response.statusCode);
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  /// ============ Battle APIs ============

  /// Report battle action/result
  /// POST /api/v1/battle/action
  Future<ApiResponse<BattleResultResponse>> reportBattleResult({
    required String playerId,
    required String enemyId,
    required String result, // 'victory' | 'defeat'
    required int expGained,
    required int goldGained,
    List<String>? cardRewards,
    Map<String, dynamic>? equipmentRewards,
  }) async {
    try {
      final body = {
        'player_id': playerId,
        'enemy_id': enemyId,
        'result': result,
        'exp_gained': expGained,
        'gold_gained': goldGained,
        if (cardRewards != null) 'card_rewards': cardRewards,
        if (equipmentRewards != null)
          'equipment_rewards': equipmentRewards,
      };

      final response = await _client
          .post(
            Uri.parse('$_baseUrl${ApiConfig.battleAction}'),
            headers: ApiConfig.defaultHeaders,
            body: json.encode(body),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return ApiResponse.success(BattleResultResponse.fromJson(data));
      }
      return ApiResponse.error(
          'Battle report failed: ${response.statusCode}', response.statusCode);
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  /// ============ Card Draw APIs ============

  /// Draw card from deck
  /// GET /api/v1/decks/{deckId}/draw
  Future<ApiResponse<CardDrawResponse>> drawCard(String deckId,
      {int count = 1}) async {
    try {
      final response = await _client
          .get(
            Uri.parse(
                '$_baseUrl${ApiConfig.drawCard(deckId)}?count=$count'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(CardDrawResponse.fromJson(data));
      }
      return ApiResponse.error(
          'Card draw failed: ${response.statusCode}', response.statusCode);
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  /// ============ Inventory APIs ============

  /// Equip item to player
  /// POST /api/v1/players/{playerId}/inventory/equip
  Future<ApiResponse<Map<String, dynamic>>> equipItem(
    String playerId, {
    required String itemId,
    String? slot,
  }) async {
    try {
      final body = {
        'item_id': itemId,
        if (slot != null) 'slot': slot,
      };

      final response = await _client
          .post(
            Uri.parse('$_baseUrl${ApiConfig.equipItem(playerId)}'),
            headers: ApiConfig.defaultHeaders,
            body: json.encode(body),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return ApiResponse.success(data);
      }
      return ApiResponse.error(
          'Equip failed: ${response.statusCode}', response.statusCode);
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  /// ============ Reputation APIs ============

  /// Get player reputation
  /// GET /api/v1/players/{playerId}/reputation
  Future<ApiResponse<Map<String, dynamic>>> getReputation(
      String playerId) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl${ApiConfig.reputation(playerId)}'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data);
      }
      return ApiResponse.error(
          'Get reputation failed: ${response.statusCode}', response.statusCode);
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  /// Update player reputation
  /// POST /api/v1/players/{playerId}/reputation
  Future<ApiResponse<Map<String, dynamic>>> updateReputation(
    String playerId, {
    required Map<String, int> factionReputation,
  }) async {
    try {
      final body = {'faction_reputation': factionReputation};

      final response = await _client
          .post(
            Uri.parse('$_baseUrl${ApiConfig.reputation(playerId)}'),
            headers: ApiConfig.defaultHeaders,
            body: json.encode(body),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return ApiResponse.success(data);
      }
      return ApiResponse.error(
          'Update reputation failed: ${response.statusCode}', response.statusCode);
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }
}

/// Generic API response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;

  ApiResponse._({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
  });

  factory ApiResponse.success(T data) =>
      ApiResponse._(success: true, data: data);

  factory ApiResponse.error(String message, [int? statusCode]) =>
      ApiResponse._(success: false, error: message, statusCode: statusCode);
}

/// Player registration response
class PlayerRegistrationResponse {
  final String playerId;
  final String? name;
  final int? level;
  final Map<String, dynamic>? initialState;

  PlayerRegistrationResponse({
    required this.playerId,
    this.name,
    this.level,
    this.initialState,
  });

  factory PlayerRegistrationResponse.fromJson(Map<String, dynamic> json) {
    return PlayerRegistrationResponse(
      playerId: json['player_id'] ?? json['playerId'] ?? '',
      name: json['name'],
      level: json['level'],
      initialState: json['initial_state'],
    );
  }
}

/// Card draw response
class CardDrawResponse {
  final List<DrawCardData> cards;
  final int remainingCards;
  final String? deckId;

  CardDrawResponse({
    required this.cards,
    required this.remainingCards,
    this.deckId,
  });

  factory CardDrawResponse.fromJson(Map<String, dynamic> json) {
    final cardsList = json['cards'] as List<dynamic>? ?? [];
    return CardDrawResponse(
      cards: cardsList.map((c) => DrawCardData.fromJson(c)).toList(),
      remainingCards: json['remaining_cards'] ?? json['remainingCards'] ?? 0,
      deckId: json['deck_id'] ?? json['deckId'],
    );
  }
}

/// Single drawn card data
class DrawCardData {
  final String id;
  final String name;
  final String description;
  final String type;
  final int? attack;
  final int? defense;
  final int? cost;
  final String? rarity;

  DrawCardData({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.attack,
    this.defense,
    this.cost,
    this.rarity,
  });

  factory DrawCardData.fromJson(Map<String, dynamic> json) {
    return DrawCardData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'attack',
      attack: json['attack'],
      defense: json['defense'],
      cost: json['cost'],
      rarity: json['rarity'],
    );
  }
}

/// Battle result response
class BattleResultResponse {
  final bool success;
  final int? expAwarded;
  final int? goldAwarded;
  final List<String>? cardsAwarded;
  final Map<String, dynamic>? equipmentAwarded;
  final Map<String, dynamic>? updatedPlayerState;

  BattleResultResponse({
    required this.success,
    this.expAwarded,
    this.goldAwarded,
    this.cardsAwarded,
    this.equipmentAwarded,
    this.updatedPlayerState,
  });

  factory BattleResultResponse.fromJson(Map<String, dynamic> json) {
    return BattleResultResponse(
      success: json['success'] ?? true,
      expAwarded: json['exp_awarded'] ?? json['expAwarded'],
      goldAwarded: json['gold_awarded'] ?? json['goldAwarded'],
      cardsAwarded: json['cards_awarded'] != null
          ? List<String>.from(json['cards_awarded'])
          : null,
      equipmentAwarded: json['equipment_awarded'],
      updatedPlayerState: json['updated_player_state'],
    );
  }
}
