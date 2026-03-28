class_name CityData
extends Resource

enum Type { NORMAL, CAPITAL }
enum ConnectionType { LAND, SEA }

@export var city_name: String = ""
@export var type: Type = Type.NORMAL
@export var position: Vector2 = Vector2.ZERO
@export var connected_to: Array[String] = []
@export var connection_types: Array[int] = []
@export var starting_cult: String = ""
