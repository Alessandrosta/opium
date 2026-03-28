extends CanvasLayer

@onready var confirm_btn: Button  = $Panel/VBox/ConfirmButton
@onready var result_label: Label  = $Panel/VBox/ResultLabel

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
		if selected.size() < 2: selected.append(n)
	else:
		selected.erase(n)
	confirm_btn.disabled = (selected.size() != 2)

func _confirm() -> void:
	hide()
	GameManager.resolve_imperial_favor_roll.rpc_id(1, multiplayer.get_unique_id(), selected)

func _on_dice_rolled(peer_id: int, d1: int, d2: int) -> void:
	if peer_id != multiplayer.get_unique_id(): return
	result_label.text = "Rolled: %d and %d" % [d1, d2]
	show()
	await get_tree().create_timer(3.0).timeout
	hide()
