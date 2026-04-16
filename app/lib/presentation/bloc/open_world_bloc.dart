import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/entities/player.dart';
import '../../../domain/entities/world_position.dart';
import '../../../domain/entities/game_card.dart';
import '../../../core/network/network.dart';
import 'open_world_event.dart';
import 'open_world_state.dart';

class OpenWorldBloc extends Bloc<OpenWorldEvent, OpenWorldState> {
  OpenWorldBloc() : super(OpenWorldInitial()) {
    on<LoadOpenWorld>(_onLoadOpenWorld);
    on<MoveToLocation>(_onMoveToLocation);
    on<InteractWithLocation>(_onInteractWithLocation);
    on<BattleCompleted>(_onBattleCompleted);
    on<AddCardToCollection>(_onAddCardToCollection);
    on<SaveGameData>(_onSaveGameData);
  }

  Future<void> _onLoadOpenWorld(
    LoadOpenWorld event,
    Emitter<OpenWorldState> emit,
  ) async {
    emit(OpenWorldLoading());
    try {
      // Try to load player data from backend
      Player player;
      final prefs = await _getSharedPreferences();
      final playerId = prefs.getString('player_id') ?? 'player_1';

      // Try to get saved game state from backend
      final saveResponse = await apiClient.getPlayerSave(playerId);

      if (saveResponse.success && saveResponse.data != null) {
        // Load from backend save
        final gameState = saveResponse.data!['game_state'];
        if (gameState != null) {
          player = _parsePlayerFromGameState(gameState, playerId);
  
        } else {
          player = _createDefaultPlayer(playerId);
        }
      } else {
        // Fallback to default player (offline mode)

        player = _createDefaultPlayer(playerId);
      }

      final locations = _generateInitialLocations();

      emit(OpenWorldLoaded(
        player: player,
        locations: locations,
        currentLocation: locations.firstWhere((l) => l.type == WorldLocationType.town),
      ));
    } catch (e) {

      // Fallback to default on any error
      final prefs = await _getSharedPreferences();
      final playerId = prefs.getString('player_id') ?? 'player_1';

      emit(OpenWorldLoaded(
        player: _createDefaultPlayer(playerId),
        locations: _generateInitialLocations(),
        currentLocation: _generateInitialLocations().firstWhere((l) => l.type == WorldLocationType.town),
      ));
    }
  }

  Future<SharedPreferences> _getSharedPreferences() async {
    return await SharedPreferences.getInstance();
  }

  Player _createDefaultPlayer(String playerId) {
    return Player(
      id: playerId,
      name: 'Chrono Traveler',
      level: 1,
      health: 100,
      maxHealth: 100,
      mana: 20,
      maxMana: 20,
      energy: 3,
      maxEnergy: 3,
    );
  }

  Player _parsePlayerFromGameState(Map<String, dynamic> gameState, String playerId) {
    return Player(
      id: playerId,
      name: gameState['name'] ?? 'Chrono Traveler',
      level: gameState['level'] ?? 1,
      health: gameState['health'] ?? 100,
      maxHealth: gameState['max_health'] ?? gameState['maxHealth'] ?? 100,
      mana: gameState['mana'] ?? 20,
      maxMana: gameState['max_mana'] ?? gameState['maxMana'] ?? 20,
      energy: gameState['energy'] ?? 3,
      maxEnergy: gameState['max_energy'] ?? gameState['maxEnergy'] ?? 3,
      deck: _parseDeck(gameState['deck']),
      hand: [],
      discardPile: [],
      crystals: gameState['crystals'] ?? 0,
      coins: gameState['coins'] ?? 100,
    );
  }

  List<GameCard> _parseDeck(dynamic deckData) {
    if (deckData == null) return [];
    if (deckData is! List) return [];

    return deckData.map((cardData) {
      if (cardData is Map<String, dynamic>) {
        return GameCard(
          id: cardData['id'] ?? '',
          name: cardData['name'] ?? '',
          description: cardData['description'] ?? '',
          type: _parseCardType(cardData['type']),
          rarity: _parseCardRarity(cardData['rarity']),
          cost: cardData['cost'] ?? 0,
          attack: cardData['attack'],
          defense: cardData['defense'],
        );
      }
      return GameCard(
        id: cardData.toString(),
        name: 'Unknown Card',
        description: '',
        type: CardType.attack,
        rarity: CardRarity.common,
        cost: 0,
        attack: 0,
        defense: 0,
      );
    }).toList();
  }

  CardType _parseCardType(String? type) {
    switch (type) {
      case 'attack':
        return CardType.attack;
      case 'defense':
        return CardType.defense;
      case 'magic':
        return CardType.magic;
      case 'skill':
        return CardType.skill;
      default:
        return CardType.special;
    }
  }

  CardRarity _parseCardRarity(String? rarity) {
    switch (rarity) {
      case 'common':
        return CardRarity.common;
      case 'uncommon':
        return CardRarity.uncommon;
      case 'rare':
        return CardRarity.rare;
      case 'epic':
        return CardRarity.epic;
      case 'legendary':
        return CardRarity.legendary;
      default:
        return CardRarity.common;
    }
  }

  void _onMoveToLocation(
    MoveToLocation event,
    Emitter<OpenWorldState> emit,
  ) {
    final currentState = state;
    if (currentState is OpenWorldLoaded) {
      emit(currentState.copyWith(currentLocation: event.location));
    }
  }

  void _onInteractWithLocation(
    InteractWithLocation event,
    Emitter<OpenWorldState> emit,
  ) {
    // Handle location interaction - navigate to appropriate screen
  }

  /// P0 Fix: Handle battle completion - mark location defeated and grant rewards
  void _onBattleCompleted(
    BattleCompleted event,
    Emitter<OpenWorldState> emit,
  ) {
    final currentState = state;
    if (currentState is OpenWorldLoaded) {
      // Mark the location as completed
      final updatedLocations = currentState.locations.map((loc) {
        if (loc.id == event.locationId) {
          return WorldLocation(
            id: loc.id,
            name: loc.name,
            description: loc.description,
            x: loc.x,
            y: loc.y,
            iconAsset: loc.iconAsset,
            isUnlocked: true,
            isCompleted: true, // Mark as defeated
            recommendedLevel: loc.recommendedLevel,
            type: loc.type,
          );
        }
        return loc;
      }).toList();

      // Calculate new player stats
      final newExp = currentState.player.level * 50 + event.experienceGained;
      int newLevel = currentState.player.level;
      int expForNextLevel = newLevel * 100;

      // Level up if enough exp
      if (newExp >= expForNextLevel) {
        newLevel++;
      }

      final updatedPlayer = Player(
        id: currentState.player.id,
        name: currentState.player.name,
        level: newLevel,
        health: currentState.player.health,
        maxHealth: currentState.player.maxHealth + (newLevel > currentState.player.level ? 10 : 0),
        mana: currentState.player.mana,
        maxMana: currentState.player.maxMana,
        energy: currentState.player.energy,
        maxEnergy: currentState.player.maxEnergy,
      );

      emit(currentState.copyWith(
        locations: updatedLocations,
        player: updatedPlayer,
        totalGold: currentState.totalGold + event.goldGained,
        battlesWon: currentState.battlesWon + 1,
      ));

      // Report battle result to backend
      _reportBattleResult(
        playerId: currentState.player.id,
        enemyId: event.locationId,
        result: 'victory',
        expGained: event.experienceGained,
        goldGained: event.goldGained,
      );

      // Auto-save game state
      add(SaveGameData());
    }
  }

  Future<void> _reportBattleResult({
    required String playerId,
    required String enemyId,
    required String result,
    required int expGained,
    required int goldGained,
  }) async {
    try {
      final response = await apiClient.reportBattleResult(
        playerId: playerId,
        enemyId: enemyId,
        result: result,
        expGained: expGained,
        goldGained: goldGained,
      );

      if (response.success) {

      } else {

      }
    } catch (e) {

    }
  }

  /// Save game state to backend
  Future<void> _onSaveGameData(
    SaveGameData event,
    Emitter<OpenWorldState> emit,
  ) async {
    final currentState = state;
    if (currentState is! OpenWorldLoaded) return;

    try {
      final prefs = await _getSharedPreferences();
      final playerId = prefs.getString('player_id') ?? currentState.player.id;

      final gameState = {
        'name': currentState.player.name,
        'level': currentState.player.level,
        'health': currentState.player.health,
        'max_health': currentState.player.maxHealth,
        'mana': currentState.player.mana,
        'max_mana': currentState.player.maxMana,
        'energy': currentState.player.energy,
        'max_energy': currentState.player.maxEnergy,
        'crystals': currentState.player.crystals,
        'coins': currentState.totalGold,
        'deck': currentState.player.deck.map((c) => c.toJson()).toList(),
        'locations': currentState.locations.map((l) => {
          'id': l.id,
          'is_completed': l.isCompleted,
          'is_unlocked': l.isUnlocked,
        }).toList(),
        'battles_won': currentState.battlesWon,
      };

      final response = await apiClient.savePlayerData(
        playerId,
        gameState: gameState,
        saveName: 'autosave_${DateTime.now().toIso8601String()}',
      );

      if (response.success) {

      } else {

      }
    } catch (e) {

    }
  }

  /// P0 Fix: Add card to player collection
  void _onAddCardToCollection(
    AddCardToCollection event,
    Emitter<OpenWorldState> emit,
  ) {
    final currentState = state;
    if (currentState is OpenWorldLoaded) {
      final updatedCards = [...currentState.playerCards, event.card];
      emit(currentState.copyWith(playerCards: updatedCards));

      // Trigger auto-save after adding card
      add(SaveGameData());
    }
  }

  List<WorldLocation> _generateInitialLocations() {
    return [
      const WorldLocation(
        id: 'town_1',
        name: 'Chrono Village',
        description: 'Safe haven for travelers',
        x: 0.5,
        y: 0.8,
        isUnlocked: true,
        type: WorldLocationType.town,
        recommendedLevel: 1,
      ),
      const WorldLocation(
        id: 'battle_1',
        name: 'Time Rift',
        description: 'Weak temporal entities roam here',
        x: 0.3,
        y: 0.4,
        isUnlocked: true,
        type: WorldLocationType.battle,
        recommendedLevel: 1,
      ),
      const WorldLocation(
        id: 'dungeon_1',
        name: 'Ancient Ruins',
        description: 'Hidden treasures await',
        x: 0.7,
        y: 0.3,
        isUnlocked: false,
        type: WorldLocationType.dungeon,
        recommendedLevel: 3,
      ),
      const WorldLocation(
        id: 'shop_1',
        name: 'Card Emporium',
        description: 'Buy and sell cards',
        x: 0.6,
        y: 0.7,
        isUnlocked: true,
        type: WorldLocationType.cardShop,
        recommendedLevel: 1,
      ),
      const WorldLocation(
        id: 'boss_1',
        name: 'Void Sanctum',
        description: 'The Time Keeper resides here',
        x: 0.2,
        y: 0.2,
        isUnlocked: false,
        type: WorldLocationType.boss,
        recommendedLevel: 5,
      ),
    ];
  }
}
