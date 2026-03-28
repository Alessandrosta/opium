extends Control

@onready var name_label: Label      = $Panel/VBox/NameLabel
@onready var cult_label: Label      = $Panel/VBox/CultLabel
@onready var favor_bar: ProgressBar = $Panel/VBox/FavorBar
@onready var favor_label: Label     = $Panel/VBox/FavorLabel
@onready var theology_label: Label  = $Panel/VBox/TheologyLabel
@onready var followers_label: Label = $Panel/VBox/FollowersLabel
@onready var money_label: Label     = $Panel/VBox/MoneyLabel
@onready var ap_label: Label        = $Panel/VBox/APLabel
@onready var temples_label: Label   = $Panel/VBox/TemplesLabel
@onready var tier_indicator: Panel  = $Panel/VBox/TierIndicator

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
	var tier_colors := [Color.GREEN, Color.YELLOW, Color.ORANGE, Color.RED]
	tier_indicator.self_modulate = tier_colors[s.get_favor_tier()]

func _on_state_updated(updated_pid: int, _d: Dictionary) -> void:
	if updated_pid == peer_id: _refresh()
