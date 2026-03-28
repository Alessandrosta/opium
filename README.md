# Opium populi — Godot 4 Multiplayer Board Game

## Setup
1. Open Godot 4.3+ and import this project folder.
2. The autoloads (EventBus, PlayerManager, CardManager, GameManager) register automatically via project.godot.
3. Build your city .tres files in `resources/cities/` using the CityData resource class.
4. Build card .tres files in `resources/cards/epoch1|2|3/` using CardData.
5. Build accident .tres files in `resources/accidents/epoch1|2|3/` using AccidentData.
6. Build scene trees (.tscn files) for Lobby, MapScene, Dashboard, CardTable, CardVisual, DiceRoll — wire up the @onready node paths to match your scene hierarchy.

## Architecture
- **Host-authority**: all game logic runs on the host; clients send intent only.
- **EventBus**: global signal relay — no scene-to-scene dependencies.
- **Effect system**: add new card/accident effects by adding a string key in CardManager._apply_effect().

## Next steps (priority order)
1. Create city .tres resource files
2. Create card .tres files (3 epochs × ~30 cards each)
3. Create accident .tres files (3 epochs × ~8 cards each)
4. Build .tscn scene trees and wire @onready paths
5. Implement temple proximity-to-Rome in GameManager._lose_nearest_temple()
6. Add continuous card tick in _advance_turn()
7. Build win screen scene
8. Add lobby cult selector matching starting_cult values
9. Run two Godot instances to playtestthe 12-turn loop
