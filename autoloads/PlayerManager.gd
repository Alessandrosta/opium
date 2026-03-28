extends Node

var players: Dictionary = {}
var city_map: Dictionary = {}

func _ready() -> void:
	_load_cities()

func _load_cities() -> void:
	var dir := DirAccess.open("res://resources/cities/")
	if dir:
		dir.list_dir_begin()
		var f := dir.get_next()
		while f != "":
			if f.ends_with(".tres"):
				var city: CityData = load("res://resources/cities/" + f)
				city_map[city.city_name] = city
			f = dir.get_next()

func register_player(peer_id: int, player_name: String, cult_name: String, color: Color) -> void:
	var state := PlayerState.new()
	state.peer_id = peer_id
	state.player_name = player_name
	state.cult_name = cult_name
	state.color = color
	for city in city_map.values():
		if city.starting_cult == cult_name:
			state.home_city = city.city_name
			state.current_city = city.city_name
			state.visited_cities = [city.city_name]
			break
	players[peer_id] = state

func get_state(peer_id: int) -> PlayerState:
	return players.get(peer_id, null)

func apply_state_dict(peer_id: int, d: Dictionary) -> void:
	var s := get_state(peer_id)
	if s == null: return
	s.imperial_favor   = d.get("imperial_favor",   s.imperial_favor)
	s.theology_points  = d.get("theology_points",  s.theology_points)
	s.followers        = d.get("followers",         s.followers)
	s.money            = d.get("money",             s.money)
	s.action_points    = d.get("action_points",     s.action_points)
	s.current_city     = d.get("current_city",      s.current_city)
	s.visited_cities   = d.get("visited_cities",    s.visited_cities)
	s.temples          = d.get("temples",           s.temples)
	s.hand             = d.get("hand",              s.hand)
	s.continuous_cards = d.get("continuous_cards",  s.continuous_cards)
	s.is_eliminated    = d.get("is_eliminated",     s.is_eliminated)
