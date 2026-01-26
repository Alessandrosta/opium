# res://logic/player_state.gd
class_name PlayerState

var id: int
var name: String
var followers: int
var theology: int
var temples: int
var hand: Array = []
var deck: Array = []
var discard: Array = []

func _init(_id: int, _name: String):
	id = _id
	name = _name
	followers = 0
	theology = 0
	temples = 0


func draw_card():
	if deck.is_empty():
		reshuffle_discard_into_deck()
	if not deck.is_empty():
		hand.append(deck.pop_back())
		
		
func reshuffle_discard_into_deck():
	deck = discard
	discard = []
	deck.shuffle()
