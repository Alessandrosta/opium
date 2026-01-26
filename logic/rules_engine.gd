extends Node
class_name RulesEngine


signal game_state_changed(game_state: GameState)

var game_state := GameState.new()

func _ready() -> void:
	# TEMP setup for testing
	setup_players(["Alice", "Bob", "Charlie"])
	# Fake decks for testing
	for p in game_state.players:
		p.deck = ["Card A", "Card B", "Card C"]

	# Simulate an action
	request_action(0, { "type": "draw" })

	print("Player 0 hand:", game_state.get_player(0).hand)

func setup_players(names: Array[String]) -> void:
	var id := 0
	for name in names:
		game_state.add_player(id, name)
		id += 1

	emit_signal("game_state_changed", game_state)

func request_action(player_id: int, action: Dictionary) -> void:
	if not is_action_valid(player_id, action):
		print("Invalid action:", action)
		return

	apply_action(player_id, action)
	emit_signal("game_state_changed", game_state)

func is_action_valid(player_id: int, action: Dictionary) -> bool:
	# Placeholder – expand later
	return true

func apply_action(player_id: int, action: Dictionary) -> void:
	match action.type:
		"draw":
			var player := game_state.get_player(player_id)
			if player:
				player.draw_card()
		_:
			print("Unknown action:", action)
