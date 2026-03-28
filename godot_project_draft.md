# Godot Project — *Pax Deorum* (working title)
Multiplayer online board game · Godot 4.x · GDScript

---

## File Structure

```
res://
├── project.godot
├── autoloads/
│   ├── EventBus.gd           ← global signal relay
│   ├── GameManager.gd        ← turn/epoch loop, host-authoritative
│   ├── CardManager.gd        ← decks, hands, drawing, playing
│   └── PlayerManager.gd      ← all PlayerState resources, dice
│
├── resources/
│   ├── CityData.gd           ← Resource class definition
│   ├── CardData.gd           ← Resource class definition
│   ├── AccidentData.gd       ← Resource class definition
│   ├── PlayerState.gd        ← Resource class definition
│   ├── cities/
│   │   ├── rome.tres
│   │   ├── alexandria.tres
│   │   └── … (one .tres per city)
│   ├── cards/
│   │   ├── epoch1/
│   │   │   ├── card_001.tres … card_030.tres
│   │   ├── epoch2/
│   │   └── epoch3/
│   └── accidents/
│       ├── epoch1/
│       ├── epoch2/
│       └── epoch3/
│
├── scenes/
│   ├── main/
│   │   ├── Main.tscn          ← root scene, switches between sub-scenes
│   │   └── Main.gd
│   ├── lobby/
│   │   ├── Lobby.tscn
│   │   └── Lobby.gd
│   ├── map/
│   │   ├── MapScene.tscn
│   │   ├── MapScene.gd
│   │   ├── City.tscn          ← individual city node
│   │   ├── City.gd
│   │   ├── Connection.tscn    ← edge between two cities
│   │   └── Connection.gd
│   ├── dashboard/
│   │   ├── Dashboard.tscn     ← one instance per local player
│   │   └── Dashboard.gd
│   ├── cards/
│   │   ├── CardTable.tscn     ← hand + play area overlay
│   │   ├── CardTable.gd
│   │   ├── CardVisual.tscn    ← single card UI node
│   │   └── CardVisual.gd
│   └── ui/
│       ├── DiceRoll.tscn
│       ├── DiceRoll.gd
│       ├── ActionMenu.tscn    ← move / build / play card buttons
│       └── ActionMenu.gd
│
└── assets/
	├── fonts/
	├── textures/
	│   ├── map/
	│   ├── cards/
	│   └── ui/
	└── audio/
```

---

## Resource Class Definitions

### `resources/CityData.gd`
```gdscript
class_name CityData
extends Resource

enum Type { NORMAL, CAPITAL }
enum ConnectionType { LAND, SEA }

@export var city_name: String = ""
@export var type: Type = Type.NORMAL
@export var position: Vector2 = Vector2.ZERO          # map coordinates
@export var connected_to: Array[String] = []          # city_name list
@export var connection_types: Array[int] = []         # parallel to connected_to
@export var starting_cult: String = ""                # e.g. "mithraism" — blank if not a capital
```

### `resources/PlayerState.gd`
```gdscript
class_name PlayerState
extends Resource

const MAX_IMPERIAL_FAVOR: int = 50
const STARTING_MONEY: int = 7000

@export var peer_id: int = 0
@export var player_name: String = ""
@export var cult_name: String = ""
@export var color: Color = Color.WHITE
@export var home_city: String = ""                    # starting capital

# Dashboard counters
@export var imperial_favor: int = 50
@export var theology_points: int = 0
@export var followers: int = 0
@export var money: int = STARTING_MONEY
@export var action_points: int = 4                    # reset each turn

# Position
@export var current_city: String = ""
@export var visited_cities: Array[String] = []

# Temples (stored as city names where temples are built)
@export var temples: Array[String] = []

# Cards
@export var hand: Array[String] = []                  # card resource paths
@export var continuous_cards: Array[String] = []      # active continuous cards

# Status
@export var is_eliminated: bool = false
@export var declared_numbers: Array[int] = []         # for imperial favour dice phase

func get_favor_tier() -> int:
	if imperial_favor >= 41: return 0   # safe
	if imperial_favor >= 21: return 1   # mild persecution
	if imperial_favor >= 1:  return 2   # heavy persecution
	return 3                             # eliminated

func get_action_points_for_epoch(epoch: int) -> int:
	return 3 + epoch                     # epoch 1→4, 2→5, 3→6

func score() -> float:
	return (2.0 * theology_points) + followers + (7.0 * temples.size()) + (money / 2000.0)
```

### `resources/CardData.gd`
```gdscript
class_name CardData
extends Resource

enum CardType { ADVANTAGE, DISADVANTAGE, RAPID, CONTINUOUS }

@export var card_id: String = ""
@export var card_name: String = ""
@export var card_type: CardType = CardType.ADVANTAGE
@export var epoch: int = 1
@export var description: String = ""
@export var effect_key: String = ""   # maps to a handler in CardManager
@export var art_path: String = ""
```

### `resources/AccidentData.gd`
```gdscript
class_name AccidentData
extends Resource

@export var accident_name: String = ""
@export var epoch: int = 1
@export var description: String = ""
@export var effect_key: String = ""
```

---

## Autoloads

### `autoloads/EventBus.gd`
```gdscript
extends Node
# All signals live here. Any node emits/connects without coupling.

# Game flow
signal game_started()
signal turn_started(player_id: int, turn_number: int)
signal turn_ended(player_id: int)
signal epoch_ended(epoch: int)
signal game_over(winner_id: int)

# Player actions
signal action_move_requested(from_city: String, to_city: String)
signal action_build_temple_requested(city: String)
signal action_play_card_requested(card_id: String, target_peer_id: int)
signal action_end_turn_requested()

# State changes (server → all clients)
signal player_state_updated(peer_id: int, state_dict: Dictionary)
signal card_drawn(peer_id: int, card_id: String)
signal card_played(peer_id: int, card_id: String, target_peer_id: int)
signal accident_drawn(peer_id: int, accident_id: String)
signal dice_rolled(peer_id: int, die1: int, die2: int)

# UI events
signal city_clicked(city_name: String)
signal card_clicked(card_id: String)
signal declare_numbers_submitted(peer_id: int, numbers: Array[int])
```

### `autoloads/GameManager.gd`
```gdscript
extends Node

const TURNS_PER_EPOCH: int = 4
const EPOCHS: int = 3
const TOTAL_TURNS: int = TURNS_PER_EPOCH * EPOCHS  # 12

var current_turn: int = 0       # 1-indexed, 1..12
var current_epoch: int = 1
var turn_within_epoch: int = 0  # 1..4
var active_player_id: int = -1
var turn_order: Array[int] = []

# Only the host runs game logic
var is_host: bool = false

func _ready() -> void:
	is_host = multiplayer.is_server()
	EventBus.action_move_requested.connect(_on_move_requested)
	EventBus.action_build_temple_requested.connect(_on_build_temple)
	EventBus.action_play_card_requested.connect(_on_card_played)
	EventBus.action_end_turn_requested.connect(_on_end_turn)

# ── Turn flow ────────────────────────────────────────────────
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

	# Check if this is the penultimate turn in an epoch → accident phase after
	var is_accident_turn: bool = (turn_within_epoch == TURNS_PER_EPOCH - 1)

	# Assign active player (round-robin through turn_order)
	active_player_id = turn_order[(current_turn - 1) % turn_order.size()]

	# Hand out followers at start of turn
	_grant_start_of_turn_followers(active_player_id)

	# Reset AP
	var state := PlayerManager.get_state(active_player_id)
	state.action_points = state.get_action_points_for_epoch(current_epoch)
	_sync_player_state(active_player_id)

	# Epoch-first turn: deal 5 cards; otherwise draw 2 and keep 1
	if turn_within_epoch == 1:
		CardManager.deal_hand(active_player_id, 5, current_epoch)
	else:
		CardManager.draw_to_choose(active_player_id, 2, current_epoch)

	# Imperial favour dice phase (before actions)
	_run_imperial_favor_phase(active_player_id)

	rpc("_client_turn_started", active_player_id, current_turn)
	EventBus.turn_started.emit(active_player_id, current_turn)

func _grant_start_of_turn_followers(peer_id: int) -> void:
	var state := PlayerManager.get_state(peer_id)
	var gained := 3 + state.temples.size()
	state.followers += gained
	_sync_player_state(peer_id)

func _run_imperial_favor_phase(peer_id: int) -> void:
	var state := PlayerManager.get_state(peer_id)
	var tier := state.get_favor_tier()
	if tier == 3:
		_eliminate_player(peer_id)
		return
	if tier == 0:
		return  # nothing happens

	# Ask client to declare numbers
	rpc_id(peer_id, "_client_declare_numbers")

func _on_end_turn() -> void:
	if not is_host: return
	# Check accident turn
	var is_accident_turn: bool = (turn_within_epoch == TURNS_PER_EPOCH - 1)
	if is_accident_turn:
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
	if turn_order.is_empty():
		_end_game()

# ── Actions ─────────────────────────────────────────────────
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

# ── Imperial favour dice roll ────────────────────────────────
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
	# Remove the temple geographically closest to Rome
	# Simplified: remove last added (real impl uses CityData distances to "rome")
	if state.temples.is_empty(): return
	state.temples.pop_back()

# ── Helpers ──────────────────────────────────────────────────
func _sync_player_state(peer_id: int) -> void:
	var state := PlayerManager.get_state(peer_id)
	var d := _state_to_dict(state)
	rpc("_client_player_state_updated", peer_id, d)
	EventBus.player_state_updated.emit(peer_id, d)

func _state_to_dict(s: PlayerState) -> Dictionary:
	return {
		"imperial_favor": s.imperial_favor,
		"theology_points": s.theology_points,
		"followers": s.followers,
		"money": s.money,
		"action_points": s.action_points,
		"current_city": s.current_city,
		"visited_cities": s.visited_cities,
		"temples": s.temples,
		"hand": s.hand,
		"continuous_cards": s.continuous_cards,
		"is_eliminated": s.is_eliminated,
	}

func _cities_are_adjacent(a: String, b: String) -> bool:
	var city_a := _get_city(a)
	if city_a == null: return false
	return b in city_a.connected_to

func _get_city(name: String) -> CityData:
	return PlayerManager.city_map.get(name, null)

# ── Remote calls (host → clients) ───────────────────────────
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
	# Client-side UI opens declaration dialog
	get_tree().get_first_node_in_group("ui_declare").show_dialog()

@rpc("authority", "call_local", "reliable")
func _client_game_over(winner_id: int) -> void:
	EventBus.game_over.emit(winner_id)
```

### `autoloads/PlayerManager.gd`
```gdscript
extends Node

var players: Dictionary = {}   # peer_id → PlayerState
var city_map: Dictionary = {}  # city_name → CityData

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
	# Set home city from city_map
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
```

### `autoloads/CardManager.gd`
```gdscript
extends Node

# epoch → Array[CardData]
var epoch_decks: Dictionary = {1: [], 2: [], 3: []}
var accident_decks: Dictionary = {1: [], 2: [], 3: []}

func _ready() -> void:
	_load_cards()
	_load_accidents()

func _load_cards() -> void:
	for epoch in [1, 2, 3]:
		var path := "res://resources/cards/epoch%d/" % epoch
		var dir := DirAccess.open(path)
		if not dir: continue
		dir.list_dir_begin()
		var f := dir.get_next()
		while f != "":
			if f.ends_with(".tres"):
				var c: CardData = load(path + f)
				epoch_decks[epoch].append(c)
			f = dir.get_next()
		epoch_decks[epoch].shuffle()

func _load_accidents() -> void:
	for epoch in [1, 2, 3]:
		var path := "res://resources/accidents/epoch%d/" % epoch
		var dir := DirAccess.open(path)
		if not dir: continue
		dir.list_dir_begin()
		var f := dir.get_next()
		while f != "":
			if f.ends_with(".tres"):
				var a: AccidentData = load(path + f)
				accident_decks[epoch].append(a)
			f = dir.get_next()
		accident_decks[epoch].shuffle()

func deal_hand(peer_id: int, count: int, epoch: int) -> void:
	var state := PlayerManager.get_state(peer_id)
	for i in count:
		var deck: Array = epoch_decks[epoch]
		if deck.is_empty(): break
		var card: CardData = deck.pop_front()
		state.hand.append(card.card_id)
		EventBus.card_drawn.emit(peer_id, card.card_id)

func draw_to_choose(peer_id: int, count: int, epoch: int) -> void:
	# Draws 'count' cards; client UI will show them and pick which to keep
	var drawn: Array[String] = []
	var deck: Array = epoch_decks[epoch]
	for i in count:
		if deck.is_empty(): break
		drawn.append(deck.pop_front().card_id)
	# Client picks one to keep via RPC — simplified here
	GameManager.rpc_id(peer_id, "_client_choose_card", drawn)

func play_card(peer_id: int, card_id: String, target_id: int) -> void:
	var state := PlayerManager.get_state(peer_id)
	if card_id not in state.hand: return
	state.hand.erase(card_id)
	var card := _get_card(card_id)
	if card == null: return

	if card.card_type == CardData.CardType.CONTINUOUS:
		state.continuous_cards.append(card_id)
	else:
		_apply_card_effect(card, peer_id, target_id)

	EventBus.card_played.emit(peer_id, card_id, target_id)

func draw_accident(epoch: int) -> AccidentData:
	var deck: Array = accident_decks[epoch]
	if deck.is_empty(): return null
	return deck.pop_front()

func apply_accident(acc: AccidentData, peer_id: int) -> void:
	_apply_effect(acc.effect_key, peer_id, -1)
	EventBus.accident_drawn.emit(peer_id, acc.accident_name)

func _apply_card_effect(card: CardData, caster_id: int, target_id: int) -> void:
	_apply_effect(card.effect_key, caster_id, target_id)

func _apply_effect(effect_key: String, caster_id: int, target_id: int) -> void:
	# Dispatch table — add all card/accident effects here
	match effect_key:
		"gain_followers_5":
			var s := PlayerManager.get_state(caster_id)
			s.followers += 5
		"lose_followers_3_target":
			var s := PlayerManager.get_state(target_id)
			s.followers = max(0, s.followers - 3)
		"gain_theology_2":
			var s := PlayerManager.get_state(caster_id)
			s.theology_points += 2
		"lose_temple_target":
			var s := PlayerManager.get_state(target_id)
			if not s.temples.is_empty():
				s.temples.pop_back()
		"gain_money_2000":
			var s := PlayerManager.get_state(caster_id)
			s.money += 2000
		"earthquake":  # example accident
			for pid in PlayerManager.players:
				var s := PlayerManager.get_state(pid)
				if not s.temples.is_empty():
					s.temples.pop_back()
		_:
			push_warning("Unknown effect key: " + effect_key)
	# Sync all affected players
	for pid in PlayerManager.players:
		GameManager._sync_player_state(pid)

func _get_card(card_id: String) -> CardData:
	for epoch in epoch_decks:
		for c: CardData in epoch_decks[epoch]:
			if c.card_id == card_id: return c
	return null
```

---

## Scenes

### `scenes/lobby/Lobby.gd`
```gdscript
extends Control

@onready var host_btn: Button = $VBox/HostButton
@onready var join_btn: Button = $VBox/JoinButton
@onready var ip_field: LineEdit = $VBox/IPField
@onready var port_field: LineEdit = $VBox/PortField
@onready var player_name_field: LineEdit = $VBox/NameField
@onready var cult_option: OptionButton = $VBox/CultOption
@onready var start_btn: Button = $VBox/StartButton
@onready var player_list: VBoxContainer = $VBox/PlayerList

const PORT: int = 7777
const MAX_PLAYERS: int = 8

func _ready() -> void:
	host_btn.pressed.connect(_host_game)
	join_btn.pressed.connect(_join_game)
	start_btn.pressed.connect(_start_game)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	start_btn.visible = false

func _host_game() -> void:
	var peer := ENetMultiplayerPeer.new()
	var port: int = int(port_field.text) if port_field.text != "" else PORT
	peer.create_server(port, MAX_PLAYERS)
	multiplayer.multiplayer_peer = peer
	_register_local_player()
	start_btn.visible = true

func _join_game() -> void:
	var peer := ENetMultiplayerPeer.new()
	var ip: String = ip_field.text if ip_field.text != "" else "127.0.0.1"
	var port: int = int(port_field.text) if port_field.text != "" else PORT
	peer.create_client(ip, port)
	multiplayer.multiplayer_peer = peer

func _on_connected_to_server() -> void:
	_register_local_player()

func _register_local_player() -> void:
	var pid := multiplayer.get_unique_id()
	var name_ := player_name_field.text if player_name_field.text != "" else "Player %d" % pid
	var cult := cult_option.get_item_text(cult_option.selected)
	rpc("_server_register_player", pid, name_, cult)

func _on_peer_connected(id: int) -> void:
	_refresh_player_list()

func _on_peer_disconnected(id: int) -> void:
	PlayerManager.players.erase(id)
	_refresh_player_list()

func _start_game() -> void:
	if not multiplayer.is_server(): return
	rpc("_client_load_game")

func _refresh_player_list() -> void:
	for child in player_list.get_children():
		child.queue_free()
	for pid in PlayerManager.players:
		var s := PlayerManager.get_state(pid)
		var lbl := Label.new()
		lbl.text = "%s — %s" % [s.player_name, s.cult_name]
		player_list.add_child(lbl)

@rpc("any_peer", "call_local", "reliable")
func _server_register_player(peer_id: int, player_name: String, cult_name: String) -> void:
	if not multiplayer.is_server(): return
	var colors := [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW,
				   Color.PURPLE, Color.ORANGE, Color.CYAN, Color.PINK]
	var color := colors[PlayerManager.players.size() % colors.size()]
	PlayerManager.register_player(peer_id, player_name, cult_name, color)
	rpc("_client_player_registered", peer_id, player_name, cult_name, color)

@rpc("authority", "call_local", "reliable")
func _client_player_registered(peer_id: int, player_name: String, cult_name: String, color: Color) -> void:
	if not PlayerManager.players.has(peer_id):
		PlayerManager.register_player(peer_id, player_name, cult_name, color)
	_refresh_player_list()

@rpc("authority", "call_local", "reliable")
func _client_load_game() -> void:
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
```

### `scenes/map/MapScene.gd`
```gdscript
extends Node2D

@export var city_scene: PackedScene
@export var connection_scene: PackedScene

var city_nodes: Dictionary = {}  # city_name → City node

func _ready() -> void:
	_build_map()
	EventBus.player_state_updated.connect(_on_player_state_updated)
	EventBus.city_clicked.connect(_on_city_clicked)

func _build_map() -> void:
	# Connections first (drawn below cities)
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
			conn.setup(city_data.position,
					   PlayerManager.city_map[other].position,
					   city_data.connection_types[i])
			add_child(conn)

	# Cities
	for city_name in PlayerManager.city_map:
		var city_data: CityData = PlayerManager.city_map[city_name]
		var city_node = city_scene.instantiate()
		city_node.setup(city_data)
		city_node.position = city_data.position
		add_child(city_node)
		city_nodes[city_name] = city_node

func _on_player_state_updated(peer_id: int, _d: Dictionary) -> void:
	_update_pawns()
	_update_temples()

func _update_pawns() -> void:
	for pid in PlayerManager.players:
		var s := PlayerManager.get_state(pid)
		# Move pawn visual to current city node
		var city_node = city_nodes.get(s.current_city, null)
		if city_node:
			city_node.set_pawn(pid, s.color)

func _update_temples() -> void:
	# Clear all temple markers then re-place
	for cn in city_nodes.values():
		cn.clear_temples()
	for pid in PlayerManager.players:
		var s := PlayerManager.get_state(pid)
		for temple_city in s.temples:
			var cn = city_nodes.get(temple_city, null)
			if cn: cn.add_temple(s.color)

func _on_city_clicked(city_name: String) -> void:
	# Only react if it's our turn
    var my_id := multiplayer.get_unique_id()
    if GameManager.active_player_id != my_id: return
    var my_state := PlayerManager.get_state(my_id)
    if my_state.action_points < 2: return
    # Highlight valid moves
    _highlight_adjacent(my_state.current_city)

func _highlight_adjacent(from_city: String) -> void:
    var city_data: CityData = PlayerManager.city_map.get(from_city, null)
    if city_data == null: return
    for adj in city_data.connected_to:
        var cn = city_nodes.get(adj, null)
        if cn: cn.set_highlighted(true)
```

### `scenes/map/City.gd`
```gdscript
extends Node2D

signal clicked(city_name: String)

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label
@onready var highlight: Node2D = $Highlight

var city_data: CityData
var pawns: Dictionary = {}     # peer_id → ColorRect
var temples: Array[Node2D] = []

func setup(data: CityData) -> void:
    city_data = data
    label.text = data.city_name
    if data.type == CityData.Type.CAPITAL:
        modulate = Color(1.0, 0.9, 0.2)  # gold tint for capitals

func _input_event(_viewport, event: InputEvent, _shape_idx: int) -> void:
    if event is InputEventMouseButton and event.pressed:
        EventBus.city_clicked.emit(city_data.city_name)

func set_highlighted(on: bool) -> void:
    highlight.visible = on

func set_pawn(peer_id: int, color: Color) -> void:
    if peer_id not in pawns:
        var rect := ColorRect.new()
        rect.size = Vector2(12, 12)
        rect.position = Vector2(pawns.size() * 14, -20)
        add_child(rect)
        pawns[peer_id] = rect
    pawns[peer_id].color = color

func add_temple(color: Color) -> void:
    var t := ColorRect.new()
    t.size = Vector2(8, 8)
    t.color = color
    t.position = Vector2(temples.size() * 10, 10)
    add_child(t)
    temples.append(t)

func clear_temples() -> void:
    for t in temples:
        t.queue_free()
    temples.clear()
```

### `scenes/dashboard/Dashboard.gd`
```gdscript
extends Control

@onready var name_label: Label          = $Panel/VBox/NameLabel
@onready var cult_label: Label          = $Panel/VBox/CultLabel
@onready var favor_bar: ProgressBar     = $Panel/VBox/FavorBar
@onready var favor_label: Label         = $Panel/VBox/FavorLabel
@onready var theology_label: Label      = $Panel/VBox/TheologyLabel
@onready var followers_label: Label     = $Panel/VBox/FollowersLabel
@onready var money_label: Label         = $Panel/VBox/MoneyLabel
@onready var ap_label: Label            = $Panel/VBox/APLabel
@onready var temples_label: Label       = $Panel/VBox/TemplesLabel
@onready var tier_indicator: Panel      = $Panel/VBox/TierIndicator

var peer_id: int = -1

func setup(pid: int) -> void:
    peer_id = pid
    EventBus.player_state_updated.connect(_on_state_updated)
    _refresh()

func _refresh() -> void:
    var s := PlayerManager.get_state(peer_id)
    if s == null: return

    name_label.text = s.player_name
    cult_label.text = s.cult_name
    favor_bar.max_value = 50
    favor_bar.value = s.imperial_favor
    favor_label.text = "Imperial Favour: %d" % s.imperial_favor
    theology_label.text = "Theology: %d" % s.theology_points
    followers_label.text = "Followers: %d" % s.followers
    money_label.text = "Money: %dk" % (s.money / 1000)
    ap_label.text = "AP: %d" % s.action_points
    temples_label.text = "Temples: %d/10" % s.temples.size()

    # Colour the tier indicator
    var tier_colors := [Color.GREEN, Color.YELLOW, Color.ORANGE, Color.RED]
    tier_indicator.self_modulate = tier_colors[s.get_favor_tier()]

func _on_state_updated(updated_pid: int, _d: Dictionary) -> void:
    if updated_pid == peer_id:
        _refresh()
```

### `scenes/cards/CardTable.gd`
```gdscript
extends Control

@onready var hand_container: HBoxContainer = $Panel/VBox/HandContainer
@onready var play_area: Panel              = $Panel/VBox/PlayArea
@onready var end_turn_btn: Button          = $Panel/VBox/EndTurnButton

@export var card_visual_scene: PackedScene

func _ready() -> void:
    end_turn_btn.pressed.connect(_on_end_turn)
    EventBus.player_state_updated.connect(_on_state_updated)
    EventBus.turn_started.connect(_on_turn_started)

func _on_turn_started(player_id: int, _turn: int) -> void:
    var my_id := multiplayer.get_unique_id()
    end_turn_btn.disabled = (player_id != my_id)
    _refresh_hand()

func _on_state_updated(pid: int, _d: Dictionary) -> void:
    if pid == multiplayer.get_unique_id():
        _refresh_hand()

func _refresh_hand() -> void:
    for child in hand_container.get_children():
        child.queue_free()
    var s := PlayerManager.get_state(multiplayer.get_unique_id())
    if s == null: return
    for card_id in s.hand:
        var cv = card_visual_scene.instantiate()
        cv.setup(card_id)
        cv.card_played.connect(_on_card_played)
        hand_container.add_child(cv)

func _on_card_played(card_id: String) -> void:
    # For disadvantage cards, player picks target; simplified here
    EventBus.action_play_card_requested.emit(card_id, -1)

func _on_end_turn() -> void:
    EventBus.action_end_turn_requested.emit()
```

### `scenes/cards/CardVisual.gd`
```gdscript
extends PanelContainer

signal card_played(card_id: String)

@onready var name_label: Label       = $VBox/NameLabel
@onready var type_label: Label       = $VBox/TypeLabel
@onready var desc_label: Label       = $VBox/DescLabel
@onready var play_btn: Button        = $VBox/PlayButton

var card_id: String = ""
var card_data: CardData

# Preloaded card data lookup
static var _all_cards: Dictionary = {}

func setup(cid: String) -> void:
    card_id = cid
    card_data = _load_card(cid)
    if card_data == null: return
    name_label.text = card_data.card_name
    type_label.text = CardData.CardType.keys()[card_data.card_type]
    desc_label.text = card_data.description
    play_btn.pressed.connect(func(): card_played.emit(card_id))

    # Rapid cards can be played anytime
    var my_turn := (GameManager.active_player_id == multiplayer.get_unique_id())
    play_btn.disabled = (not my_turn and card_data.card_type != CardData.CardType.RAPID)

func _load_card(cid: String) -> CardData:
    if cid in _all_cards: return _all_cards[cid]
    for epoch in [1, 2, 3]:
        var path := "res://resources/cards/epoch%d/%s.tres" % [epoch, cid]
        if ResourceLoader.exists(path):
            var c: CardData = load(path)
            _all_cards[cid] = c
            return c
    return null
```

### `scenes/ui/DiceRoll.gd`
```gdscript
extends CanvasLayer
## Shown during imperial favour dice phase

@onready var num1_btn: Button  = $Panel/VBox/Num1
@onready var num2_btn: Button  = $Panel/VBox/Num2
@onready var confirm_btn: Button = $Panel/VBox/ConfirmButton
@onready var result_label: Label = $Panel/VBox/ResultLabel

var selected: Array[int] = []

func _ready() -> void:
    add_to_group("ui_declare")
    hide()
    for i in range(1, 7):
        var btn := Button.new()
        btn.text = str(i)
        btn.toggle_mode = true
        btn.toggled.connect(func(pressed: bool): _toggle_number(i, pressed))
        $Panel/VBox/NumberGrid.add_child(btn)
    confirm_btn.pressed.connect(_confirm)
    EventBus.dice_rolled.connect(_on_dice_rolled)

func show_dialog() -> void:
    selected.clear()
    result_label.text = ""
    show()

func _toggle_number(n: int, pressed: bool) -> void:
    if pressed:
        if selected.size() < 2:
            selected.append(n)
    else:
        selected.erase(n)
    confirm_btn.disabled = (selected.size() != 2)

func _confirm() -> void:
    hide()
    # Send declared numbers back to host
    GameManager.resolve_imperial_favor_roll.rpc_id(1,
        multiplayer.get_unique_id(), selected)

func _on_dice_rolled(peer_id: int, d1: int, d2: int) -> void:
    if peer_id != multiplayer.get_unique_id(): return
    result_label.text = "Rolled: %d and %d" % [d1, d2]
    show()
    await get_tree().create_timer(3.0).timeout
    hide()
```

---

## project.godot — Autoload registration

Add these entries to your `project.godot` under `[autoload]`:

```ini
[autoload]
EventBus="*res://autoloads/EventBus.gd"
PlayerManager="*res://autoloads/PlayerManager.gd"
CardManager="*res://autoloads/CardManager.gd"
GameManager="*res://autoloads/GameManager.gd"
```

---

## Next Steps

1. **Create city .tres files** — instantiate `CityData`, fill `city_name`, `type`, `position`, `connected_to`, `connection_types`, and for capitals `starting_cult`. Save each as `res://resources/cities/<name>.tres`.

2. **Create card .tres files** — instantiate `CardData` for every card in each epoch deck. Map each card's effect to an `effect_key` string handled in `CardManager._apply_effect()`.

3. **Create accident .tres files** — same pattern as cards, one per epoch sub-folder.

4. **Build the Map scene** — in `MapScene.tscn`, add a `Camera2D` and use the `city.position` values from your `.tres` files to lay out the Mediterranean map. Draw connections as `Line2D` nodes.

5. **Polish Dashboard.tscn** — lay out the ProgressBar for imperial favour, labels for all counters, and a coloured tier indicator panel.

6. **Add continuous card logic** — at the start of every turn call `CardManager._apply_effect()` for each card in `state.continuous_cards`.

7. **Temple proximity to Rome** — implement `_lose_nearest_temple()` using actual `CityData.position` distances to Rome's coordinates rather than the placeholder `pop_back()`.

8. **Lobby UX** — add cult selection (matching `starting_cult` values in your city data) and a "ready" check before `start_game()` is callable.

9. **Win screen** — build a scene that receives `game_over(winner_id)` from `EventBus` and shows final scores.

10. **Playtesting** — run two Godot instances (`--headless` for the second) and test the full 12-turn loop before adding art assets.
```
