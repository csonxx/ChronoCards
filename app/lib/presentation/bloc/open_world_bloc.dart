import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/player.dart';
import '../../../domain/entities/world_position.dart';
import '../../../domain/entities/game_card.dart';
import 'open_world_event.dart';
import 'open_world_state.dart';

class OpenWorldBloc extends Bloc<OpenWorldEvent, OpenWorldState> {
  OpenWorldBloc() : super(OpenWorldInitial()) {
    on<LoadOpenWorld>(_onLoadOpenWorld);
    on<MoveToLocation>(_onMoveToLocation);
    on<InteractWithLocation>(_onInteractWithLocation);
    on<BattleCompleted>(_onBattleCompleted);
    on<AddCardToCollection>(_onAddCardToCollection);
  }

  Future<void> _onLoadOpenWorld(
    LoadOpenWorld event,
    Emitter<OpenWorldState> emit,
  ) async {
    emit(OpenWorldLoading());
    try {
      // Load player data and world locations
      final player = Player(
        id: 'player_1',
        name: 'Chrono Traveler',
        level: 1,
        health: 100,
        maxHealth: 100,
        mana: 20,
        maxMana: 20,
        energy: 3,
        maxEnergy: 3,
      );

      final locations = _generateInitialLocations();

      emit(OpenWorldLoaded(
        player: player,
        locations: locations,
        currentLocation: locations.firstWhere((l) => l.type == WorldLocationType.town),
      ));
    } catch (e) {
      emit(OpenWorldError('Failed to load open world: $e'));
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
