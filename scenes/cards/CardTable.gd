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
	end_turn_btn.disabled = (player_id != multiplayer.get_unique_id())
	_refresh_hand()

func _on_state_updated(pid: int, _d: Dictionary) -> void:
	if pid == multiplayer.get_unique_id(): _refresh_hand()

func _refresh_hand() -> void:
	for child in hand_container.get_children(): child.queue_free()
	var s := PlayerManager.get_state(multiplayer.get_unique_id())
	if s == null: return
	for card_id in s.hand:
		var cv = card_visual_scene.instantiate()
		cv.setup(card_id)
		cv.card_played.connect(_on_card_played)
		hand_container.add_child(cv)

func _on_card_played(card_id: String) -> void:
	EventBus.action_play_card_requested.emit(card_id, -1)

func _on_end_turn() -> void:
	EventBus.action_end_turn_requested.emit()
