# res://logic/game_state.gd
class_name GameState

var players: Array[PlayerState] = []
var active_player_id: int = -1
var map: MapData
var active_player_index: int = 0 
var round_number: int = 1   # starts at round 1

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

#func get_active_player() -> PlayerState:
#	return get_player(active_player_id)
	
func get_active_player() -> PlayerState:
	#print("DEBUG players:", players)
	#print("DEBUG players size:", players.size())
	#print("DEBUG active index:", active_player_index)

	if players.is_empty():
		push_error("Players array is EMPTY")
		return null

	if active_player_index < 0 or active_player_index >= players.size():
		push_error("Active player index OUT OF BOUNDS")
		return null

	if players[active_player_index] == null:
		push_error("Player at active index IS NULL")
		return null

	return players[active_player_index]


func next_player():
	active_player_index = (active_player_index + 1) % players.size()
	
	# If we wrapped around to the first player, increment the round
	if active_player_index == 0:
		round_number += 1
