class_name MapData

var cities: Dictionary = {}        # id -> CityState
var adjacency: Dictionary = {}     # id -> Array[String]

func load_from_json(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	var raw: Dictionary = JSON.parse_string(file.get_as_text())

	# Load cities
	for node in raw.nodes:
		var city := CityState.new(node)
		cities[city.id] = city
		adjacency[city.id] = []

	# Load undirected edges
	for edge in raw.edges:
		var a: String
		a = edge[0]
		var b: String
		b = edge[1]
		adjacency[a].append(b)
		adjacency[b].append(a)

func can_move(from_id: String, to_id: String) -> bool:
	return to_id in adjacency.get(from_id, [])
