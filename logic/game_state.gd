# res://logic/game_state.gd
class_name GameState

var players: Array[PlayerState] = []
var active_player_id: int = -1

func add_player(id: int, name: String) -> void:
	var player := PlayerState.new(id, name)
	players.append(player)
	if active_player_id == -1:
		active_player_id = id

func get_player(id: int) -> PlayerState:
	for p in players:
		if p.id == id:
			return p
	return null

func get_active_player() -> PlayerState:
	return get_player(active_player_id)
