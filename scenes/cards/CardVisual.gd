extends PanelContainer

signal card_played(card_id: String)

@onready var name_label: Label  = $VBox/NameLabel
@onready var type_label: Label  = $VBox/TypeLabel
@onready var desc_label: Label  = $VBox/DescLabel
@onready var play_btn: Button   = $VBox/PlayButton

var card_id: String = ""
var card_data: CardData
static var _all_cards: Dictionary = {}

func setup(cid: String) -> void:
	card_id = cid
	card_data = _load_card(cid)
	if card_data == null: return
	name_label.text = card_data.card_name
	type_label.text = CardData.CardType.keys()[card_data.card_type]
	desc_label.text = card_data.description
	play_btn.pressed.connect(func(): card_played.emit(card_id))
	var my_turn := (GameManager.active_player_id == multiplayer.get_unique_id())
	play_btn.disabled = (not my_turn and card_data.card_type != CardData.CardType.RAPID)

func _load_card(cid: String) -> CardData:
	if cid in _all_cards: return _all_cards[cid]
	for epoch in [1, 2, 3]:
		var path := "res://resources/cards/epoch%d/%s.tres" % [epoch, cid]
		if ResourceLoader.exists(path):
			var c: CardData = load(path)
			_all_cards[cid] = c
			return c
	return null
