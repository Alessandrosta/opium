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
	var color: Color = colors[PlayerManager.players.size() % colors.size()]
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
