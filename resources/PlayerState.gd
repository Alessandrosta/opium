class_name PlayerState
extends Resource

const MAX_IMPERIAL_FAVOR: int = 50
const STARTING_MONEY: int = 7000

@export var peer_id: int = 0
@export var player_name: String = ""
@export var cult_name: String = ""
@export var color: Color = Color.WHITE
@export var home_city: String = ""
@export var imperial_favor: int = 50
@export var theology_points: int = 0
@export var followers: int = 0
@export var money: int = STARTING_MONEY
@export var action_points: int = 4
@export var current_city: String = ""
@export var visited_cities: Array[String] = []
@export var temples: Array[String] = []
@export var hand: Array[String] = []
@export var continuous_cards: Array[String] = []
@export var is_eliminated: bool = false
@export var declared_numbers: Array[int] = []

func get_favor_tier() -> int:
	if imperial_favor >= 41: return 0
	if imperial_favor >= 21: return 1
	if imperial_favor >= 1:  return 2
	return 3

func get_action_points_for_epoch(epoch: int) -> int:
	return 3 + epoch

func score() -> float:
	return (2.0 * theology_points) + followers + (7.0 * temples.size()) + (money / 2000.0)
