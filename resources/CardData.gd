class_name CardData
extends Resource

enum CardType { ADVANTAGE, DISADVANTAGE, RAPID, CONTINUOUS }

@export var card_id: String = ""
@export var card_name: String = ""
@export var card_type: CardType = CardType.ADVANTAGE
@export var epoch: int = 1
@export var description: String = ""
@export var effect_key: String = ""
@export var art_path: String = ""
@export var cost: int = 0
