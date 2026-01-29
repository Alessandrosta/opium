extends Node2D

const COLLISION_MASK_CARD = 1

var scree_size 
var card_being_dragged
var is_hovering_on_card

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if card_being_dragged:
		var mouse_pos = get_global_mouse_position()
		card_being_dragged.position = Vector2(clamp(mouse_pos.x, 0, scree_size.x), 
			clamp(mouse_pos.y, 0, scree_size.y))

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	scree_size = get_viewport_rect().size
	

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			var card = raycast_check_for_card()
			if card:
				start_drag(card)
		else:
			finish_drag()
			


func start_drag(card):
	card_being_dragged = card
	card.scale = Vector2(1, 1)
	
func finish_drag():
	card_being_dragged.scale = Vector2(1.05, 1.05)
	card_being_dragged = null
	


func raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	var parameteres = PhysicsPointQueryParameters2D.new()
	parameteres.position = get_global_mouse_position()
	parameteres.collide_with_areas = true
	parameteres.collision_mask = COLLISION_MASK_CARD
	var result = space_state.intersect_point(parameteres)
	if result.size() > 0:
		return return_card_on_top(result)
	else:
		null
		
		
func connect_card_signal(card):
	card.connect("hovered", on_hovered_over_card)
	card.connect("hovered_off", on_hovered_off_card)
	
	
func on_hovered_over_card(card):
	if !is_hovering_on_card:
		is_hovering_on_card = true
		highlight_card(card, true)
		
		
func return_card_on_top(cards):
	var card_on_top = cards[0].collider.get_parent()
	var highest_z_index = card_on_top.z_index
	
	# Loop to find card with highest z_index
	for i in range(1, cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			card_on_top = current_card
			highest_z_index = current_card.z_index
	
	return card_on_top
	
		
	
func on_hovered_off_card(card):
	if !card_being_dragged:
		highlight_card(card, false)
		var new_card_hovered = raycast_check_for_card()
		
		if new_card_hovered:
			highlight_card(new_card_hovered, true)
		else:
			is_hovering_on_card = false
			
		
		
	
func highlight_card(card, hovered):
	if hovered:
		card.scale = Vector2(1.05, 1.05)
		card.z_index = 2
	else:
		card.scale = Vector2(1, 1)
		card.z_index = 1
		
		
		
		
		
		
		
		
		
		
		
		
