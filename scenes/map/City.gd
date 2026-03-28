extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label
@onready var highlight: Node2D = $Highlight

var city_data: CityData
var pawns: Dictionary = {}
var temples: Array[Node2D] = []

func setup(data: CityData) -> void:
	city_data = data
	label.text = data.city_name
	if data.type == CityData.Type.CAPITAL:
		modulate = Color(1.0, 0.9, 0.2)

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
	for t in temples: t.queue_free()
	temples.clear()
