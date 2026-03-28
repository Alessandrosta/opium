extends Node

const TURNS_PER_EPOCH: int = 4
const EPOCHS: int = 3
const TOTAL_TURNS: int = TURNS_PER_EPOCH * EPOCHS

var current_turn: int = 0
var current_epoch: int = 1
var turn_within_epoch: int = 0
var active_player_id: int = -1
var turn_order: Array[int] = []
var is_host: bool = false

func _ready() -> void:
	is_host = multiplayer.is_server()
	EventBus.action_move_requested.connect(_on_move_requested)
	EventBus.action_build_temple_requested.connect(_on_build_temple)
	EventBus.action_play_card_requested.connect(_on_card_played)
	EventBus.action_end_turn_requested.connect(_on_end_turn)

func start_game(player_ids: Array[int]) -> void:
	if not is_host: return
	turn_order = player_ids.duplicate()
	turn_order.shuffle()
	current_turn = 0
	_advance_turn()

func _advance_turn() -> void:
	current_turn += 1
	if current_turn > TOTAL_TURNS:
		_end_game()
		return
	current_epoch = ceili(float(current_turn) / TURNS_PER_EPOCH)
	turn_within_epoch = ((current_turn - 1) % TURNS_PER_EPOCH) + 1
	active_player_id = turn_order[(current_turn - 1) % turn_order.size()]
	_grant_start_of_turn_followers(active_player_id)
	var state := PlayerManager.get_state(active_player_id)
	state.action_points = state.get_action_points_for_epoch(current_epoch)
	_sync_player_state(active_player_id)
	if turn_within_epoch == 1:
		CardManager.deal_hand(active_player_id, 5, current_epoch)
	else:
		CardManager.draw_to_choose(active_player_id, 2, current_epoch)
	_run_imperial_favor_phase(active_player_id)
	rpc("_client_turn_started", active_player_id, current_turn)
	EventBus.turn_started.emit(active_player_id, current_turn)

func _grant_start_of_turn_followers(peer_id: int) -> void:
	var state := PlayerManager.get_state(peer_id)
	state.followers += 3 + state.temples.size()
	_sync_player_state(peer_id)

func _run_imperial_favor_phase(peer_id: int) -> void:
	var state := PlayerManager.get_state(peer_id)
	var tier := state.get_favor_tier()
	if tier == 3:
		_eliminate_player(peer_id)
		return
	if tier == 0: return
	rpc_id(peer_id, "_client_declare_numbers")

func _on_end_turn() -> void:
	if not is_host: return
	if turn_within_epoch == TURNS_PER_EPOCH - 1:
		_run_accident_phase()
	_advance_turn()

func _run_accident_phase() -> void:
	for peer_id in turn_order:
		var acc := CardManager.draw_accident(current_epoch)
		if acc:
			CardManager.apply_accident(acc, peer_id)
			rpc("_client_accident_drawn", peer_id, acc.accident_name)

func _end_game() -> void:
	var scores: Dictionary = {}
	for pid in turn_order:
		var s := PlayerManager.get_state(pid)
		if not s.is_eliminated:
			scores[pid] = s.score()
	var winner := scores.keys().reduce(func(a, b): return a if scores[a] >= scores[b] else b)
	rpc("_client_game_over", winner)
	EventBus.game_over.emit(winner)

func _eliminate_player(peer_id: int) -> void:
	var state := PlayerManager.get_state(peer_id)
	state.is_eliminated = true
	_sync_player_state(peer_id)
	turn_order.erase(peer_id)
	if turn_order.is_empty(): _end_game()

func _on_move_requested(from_city: String, to_city: String) -> void:
	if not is_host: return
	var state := PlayerManager.get_state(active_player_id)
	if state.action_points < 2: return
	if not _cities_are_adjacent(from_city, to_city): return
	state.action_points -= 2
	state.current_city = to_city
	if to_city not in state.visited_cities:
		state.visited_cities.append(to_city)
		var city := _get_city(to_city)
		if city and city.type == CityData.Type.CAPITAL:
			state.theology_points += 5
		else:
			state.followers += 3
		state.imperial_favor = max(0, state.imperial_favor - 2)
	_sync_player_state(active_player_id)

func _on_build_temple(city: String) -> void:
	if not is_host: return
	var state := PlayerManager.get_state(active_player_id)
	if state.action_points < 3: return
	if state.money < 3000: return
	if city not in state.visited_cities: return
	if state.temples.size() >= 10: return
	state.action_points -= 3
	state.money -= 3000
	state.temples.append(city)
	_sync_player_state(active_player_id)

func _on_card_played(card_id: String, target_peer_id: int) -> void:
	if not is_host: return
	CardManager.play_card(active_player_id, card_id, target_peer_id)

func resolve_imperial_favor_roll(peer_id: int, declared: Array[int]) -> void:
	if not is_host: return
	var state := PlayerManager.get_state(peer_id)
	var tier := state.get_favor_tier()
	if tier == 0: return
	var d1 := randi_range(1, 6)
	var d2 := randi_range(1, 6)
	rpc("_client_dice_rolled", peer_id, d1, d2)
	var hit := (d1 in declared) or (d2 in declared)
	var doubles := (d1 == d2)
	if tier == 1:
		if hit: state.followers = max(0, state.followers - 3)
		if doubles: _lose_nearest_temple(state)
	elif tier == 2:
		if hit:
			state.followers = max(0, state.followers - 5)
			state.theology_points = max(0, state.theology_points - 1)
		if doubles: _lose_nearest_temple(state)
	_sync_player_state(peer_id)

func _lose_nearest_temple(state: PlayerState) -> void:
	if state.temples.is_empty(): return
	state.temples.pop_back()

func _sync_player_state(peer_id: int) -> void:
	var state := PlayerManager.get_state(peer_id)
	var d := _state_to_dict(state)
	rpc("_client_player_state_updated", peer_id, d)
	EventBus.player_state_updated.emit(peer_id, d)

func _state_to_dict(s: PlayerState) -> Dictionary:
	return {
		"imperial_favor": s.imperial_favor, "theology_points": s.theology_points,
		"followers": s.followers, "money": s.money, "action_points": s.action_points,
		"current_city": s.current_city, "visited_cities": s.visited_cities,
		"temples": s.temples, "hand": s.hand, "continuous_cards": s.continuous_cards,
		"is_eliminated": s.is_eliminated,
	}

func _cities_are_adjacent(a: String, b: String) -> bool:
	var city_a := _get_city(a)
	if city_a == null: return false
	return b in city_a.connected_to

func _get_city(name: String) -> CityData:
	return PlayerManager.city_map.get(name, null)

@rpc("authority", "call_local", "reliable")
func _client_turn_started(player_id: int, turn_num: int) -> void:
	EventBus.turn_started.emit(player_id, turn_num)

@rpc("authority", "call_local", "reliable")
func _client_player_state_updated(peer_id: int, d: Dictionary) -> void:
	PlayerManager.apply_state_dict(peer_id, d)
	EventBus.player_state_updated.emit(peer_id, d)

@rpc("authority", "call_local", "reliable")
func _client_dice_rolled(peer_id: int, d1: int, d2: int) -> void:
	EventBus.dice_rolled.emit(peer_id, d1, d2)

@rpc("authority", "call_local", "reliable")
func _client_accident_drawn(peer_id: int, accident_name: String) -> void:
	EventBus.accident_drawn.emit(peer_id, accident_name)

@rpc("authority", "call_remote", "reliable")
func _client_declare_numbers() -> void:
	get_tree().get_first_node_in_group("ui_declare").show_dialog()

@rpc("authority", "call_local", "reliable")
func _client_game_over(winner_id: int) -> void:
	EventBus.game_over.emit(winner_id)
