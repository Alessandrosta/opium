class_name CityState

var id: String
var name: String
var type: String
var temple_slots: int = 2
var temples: Array = []                  # array of player IDs who built a temple	

func _init(data: Dictionary):
	id = data.id
	name = data.name
	type = data.type

func has_free_temple_slot() -> bool:
	return temples.size() < temple_slots

func build_temple(player_id: int) -> bool:
	if has_free_temple_slot():
		temples.append(player_id)
		return true
	return false

func count_temples_for_player(player_id: int) -> int:
	var n := 0
	for pid in temples:
		if pid == player_id:
			n += 1
	return n
