# res://logic/player_state.gd
class_name PlayerState

var id: int
var name: String
var followers: int
var theology: int
var temples: int
var favor: int
var pa: int
var hand: Array = []
var deck: Array = []
var discard: Array = []
var location: String
var visited_cities: Dictionary = {}  # city_id -> bool


func _init(_id: int, _name: String):
	id = _id
	name = _name
	followers = 0
	theology = 0
	temples = 0
	pa = 3
	favor = 100


func draw_card():
	if deck.is_empty():
		reshuffle_discard_into_deck()
	if not deck.is_empty():
		hand.append(deck.pop_back())
		
		
func reshuffle_discard_into_deck():
	deck = discard
	discard = []
	deck.shuffle()
	
func start_in_city(city_id: String):
	location = city_id
	visited_cities[city_id] = true

func visit_city(city_id: String):
	location = city_id
	visited_cities[city_id] = true
	followers += 3
