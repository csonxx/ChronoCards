import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/player.dart';
import '../../../domain/entities/world_position.dart';
import 'open_world_event.dart';
import 'open_world_state.dart';

class OpenWorldBloc extends Bloc<OpenWorldEvent, OpenWorldState> {
  OpenWorldBloc() : super(OpenWorldInitial()) {
    on<LoadOpenWorld>(_onLoadOpenWorld);
    on<MoveToLocation>(_onMoveToLocation);
    on<InteractWithLocation>(_onInteractWithLocation);
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
