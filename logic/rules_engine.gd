extends Node
class_name RulesEngine


signal game_state_changed(game_state: GameState)

var state := GameState.new()

func _ready():
	print("=== DEMO START ===")

	# Load map
	var map := MapData.new()
	map.load_from_json("res://data/map/cities_graph.json")
	state.map = map

	# Create players
	var p1 := PlayerState.new(0, "sdraiatè")
	print(p1)
	print(p1.name)
	var p2 := PlayerState.new(1, "viandantè")
	print(p2)
	
	p1.start_in_city("pompei")
	p2.start_in_city("panormus")

	state.players.append(p1)
	state.players.append(p2)


	# Dummy decks
	for p in state.players:
		p.deck = ["DummyCard", "DummyCard", "DummyCard"]

	# Play 2 rounds
	for round in range(3):
		print("\n--- ROUND", round + 1, "---")
		for _i in state.players.size():
			play_turn()
			state.next_player()

	print("\n=== DEMO END ===")



func play_turn():
	var p := state.get_active_player()
	# refresh pa
	p.pa = 3
	var startcity: CityState = state.map.cities.get(p.location)
	var startcity_name: String = startcity.name if startcity != null else p.location
	print("\nRound:", state.round_number, " - ", p.name, " inizia il turno a ", startcity_name, " con ", p.followers)

		



	# Start of turn: temples give followers
	var total_followers_from_owned_temples = 0
	var city_counter = 0
	
	for city in state.map.cities.values():
		city_counter += city.count_temples_for_player(p.id)
		
	total_followers_from_owned_temples = city_counter * 2
	p.followers += total_followers_from_owned_temples
	print(p.name, " ha ", p.followers, " seguaci")

	print("Seguaci dai templi: ", total_followers_from_owned_temples)

	# Draw card
	if p.deck.size() > 0:
		var card = p.deck.pop_back()
		p.hand.append(card)
		print(p.name, " pesca una carta")

	# Move if possible
	var neighbors = state.map.adjacency[p.location]
	if neighbors.size() > 0 and p.pa >= 2 and state.round_number % 2 == 1:
		var destination = neighbors[0]
		p.pa -= 2
		p.visit_city(destination)
		var totcity: CityState = state.map.cities.get(destination)
		var tocity_name: String = totcity.name if totcity != null else destination
		print(p.name, " va a ", tocity_name, " (PA:", p.pa, ")")

	# Build temple if possible
	var city: CityState = state.map.cities[p.location]
	if state.round_number % 2 == 0:
		if p.pa >= 3 and city.has_free_temple_slot():
			if city.build_temple(p.id):
				p.pa -= 3
				print(p.name, " built a temple in ", city.name, " (PA:", p.pa, ")")


	print(p.name, " finisce il turno con ", p.followers, " seguaci")




# potentially useless stuff
func setup_players(names: Array[String]) -> void:
	var id := 0
	for name in names:
		state.add_player(id, name)
		id += 1

	emit_signal("game_state_changed", state)

func request_action(player_id: int, action: Dictionary) -> void:
	if not is_action_valid(player_id, action):
		print("Invalid action:", action)
		return

	apply_action(player_id, action)
	emit_signal("game_state_changed", state)

func is_action_valid(player_id: int, action: Dictionary) -> bool:
	# Placeholder – expand later
	return true

func apply_action(player_id: int, action: Dictionary) -> void:
	match action.type:
		"draw":
			var player := state.get_player(player_id)
			if player:
				player.draw_card()
		_:
			print("Unknown action:", action)
