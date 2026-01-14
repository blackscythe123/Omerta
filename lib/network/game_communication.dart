// Abstract communication layer interface (The Cable)

import '../models/game_state.dart';

abstract class GameCommunication {
  // Send game state to peers (host -> clients)
  Future<void> sendGameState(GameState state);

  // Send an action to the host (client -> host)
  Future<void> sendAction(Map<String, dynamic> action);

  // Register a callback for incoming game state updates (clients)
  void onGameStateReceived(Function(GameState) callback);

  // Register a callback for incoming actions (host)
  void onActionReceived(Function(Map<String, dynamic>) callback);
}
