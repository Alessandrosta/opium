extends Node2D

@export var city_scene: PackedScene
@export var connection_scene: PackedScene

var city_nodes: Dictionary = {}

func _ready() -> void:
	_build_map()
	EventBus.player_state_updated.connect(_on_player_state_updated)
	EventBus.city_clicked.connect(_on_city_clicked)

func _build_map() -> void:
	var drawn_edges: Dictionary = {}
	for city_name in PlayerManager.city_map:
		var city_data: CityData = PlayerManager.city_map[city_name]
		for i in city_data.connected_to.size():
			var other := city_data.connected_to[i]
			var edge_key := [city_name, other]
			edge_key.sort()
			var edge_str := "%s|%s" % [edge_key[0], edge_key[1]]
			if edge_str in drawn_edges: continue
			drawn_edges[edge_str] = true
			var conn = connection_scene.instantiate()
			conn.setup(city_data.position, PlayerManager.city_map[other].position, city_data.connection_types[i])
			add_child(conn)
	for city_name in PlayerManager.city_map:
		var city_data: CityData = PlayerManager.city_map[city_name]
		var city_node = city_scene.instantiate()
		city_node.setup(city_data)
		city_node.position = city_data.position
		add_child(city_node)
		city_nodes[city_name] = city_node

func _on_player_state_updated(_peer_id: int, _d: Dictionary) -> void:
	_update_pawns()
	_update_temples()

func _update_pawns() -> void:
	for pid in PlayerManager.players:
		var s := PlayerManager.get_state(pid)
		var city_node = city_nodes.get(s.current_city, null)
		if city_node: city_node.set_pawn(pid, s.color)

func _update_temples() -> void:
	for cn in city_nodes.values(): cn.clear_temples()
	for pid in PlayerManager.players:
		var s := PlayerManager.get_state(pid)
		for temple_city in s.temples:
			var cn = city_nodes.get(temple_city, null)
			if cn: cn.add_temple(s.color)

func _on_city_clicked(city_name: String) -> void:
	var my_id := multiplayer.get_unique_id()
	if GameManager.active_player_id != my_id: return
	var my_state := PlayerManager.get_state(my_id)
	if my_state.action_points < 2: return
	_highlight_adjacent(my_state.current_city)

func _highlight_adjacent(from_city: String) -> void:
	var city_data: CityData = PlayerManager.city_map.get(from_city, null)
	if city_data == null: return
	for adj in city_data.connected_to:
		var cn = city_nodes.get(adj, null)
		if cn: cn.set_highlighted(true)
