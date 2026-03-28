extends Node

var epoch_decks: Dictionary = {1: [], 2: [], 3: []}
var accident_decks: Dictionary = {1: [], 2: [], 3: []}

func _ready() -> void:
	_load_cards()
	_load_accidents()

func _load_cards() -> void:
	for epoch in [1, 2, 3]:
		var path := "res://resources/cards/epoch%d/" % epoch
		var dir := DirAccess.open(path)
		if not dir: continue
		dir.list_dir_begin()
		var f := dir.get_next()
		while f != "":
			if f.ends_with(".tres"):
				var c: CardData = load(path + f)
				epoch_decks[epoch].append(c)
			f = dir.get_next()
		epoch_decks[epoch].shuffle()

func _load_accidents() -> void:
	for epoch in [1, 2, 3]:
		var path := "res://resources/accidents/epoch%d/" % epoch
		var dir := DirAccess.open(path)
		if not dir: continue
		dir.list_dir_begin()
		var f := dir.get_next()
		while f != "":
			if f.ends_with(".tres"):
				var a: AccidentData = load(path + f)
				accident_decks[epoch].append(a)
			f = dir.get_next()
		accident_decks[epoch].shuffle()

func deal_hand(peer_id: int, count: int, epoch: int) -> void:
	var state := PlayerManager.get_state(peer_id)
	for i in count:
		var deck: Array = epoch_decks[epoch]
		if deck.is_empty(): break
		var card: CardData = deck.pop_front()
		state.hand.append(card.card_id)
		EventBus.card_drawn.emit(peer_id, card.card_id)

func draw_to_choose(peer_id: int, count: int, epoch: int) -> void:
	var drawn: Array[String] = []
	var deck: Array = epoch_decks[epoch]
	for i in count:
		if deck.is_empty(): break
		drawn.append(deck.pop_front().card_id)
	GameManager.rpc_id(peer_id, "_client_choose_card", drawn)

func play_card(peer_id: int, card_id: String, target_id: int) -> void:
	var state := PlayerManager.get_state(peer_id)
	if card_id not in state.hand: return
	state.hand.erase(card_id)
	var card := _get_card(card_id)
	if card == null: return
	# Check the player can afford it
	if state.action_points < card.cost: return
	
	state.hand.erase(card_id)
	state.action_points -= card.cost  # deduct before applying effect
	
	if card.card_type == CardData.CardType.CONTINUOUS:
		state.continuous_cards.append(card_id)
	else:
		_apply_card_effect(card, peer_id, target_id)
	EventBus.card_played.emit(peer_id, card_id, target_id)

func draw_accident(epoch: int) -> AccidentData:
	var deck: Array = accident_decks[epoch]
	if deck.is_empty(): return null
	return deck.pop_front()

func apply_accident(acc: AccidentData, peer_id: int) -> void:
	_apply_effect(acc.effect_key, peer_id, -1)
	EventBus.accident_drawn.emit(peer_id, acc.accident_name)

func _apply_card_effect(card: CardData, caster_id: int, target_id: int) -> void:
	_apply_effect(card.effect_key, caster_id, target_id)

func _apply_effect(effect_key: String, caster_id: int, target_id: int) -> void:
	match effect_key:
		"gain_followers_5":
			PlayerManager.get_state(caster_id).followers += 5
		"lose_followers_3_target":
			var s := PlayerManager.get_state(target_id)
			s.followers = max(0, s.followers - 3)
		"gain_theology_2":
			PlayerManager.get_state(caster_id).theology_points += 2
		"lose_temple_target":
			var s := PlayerManager.get_state(target_id)
			if not s.temples.is_empty(): s.temples.pop_back()
		"gain_money_2000":
			PlayerManager.get_state(caster_id).money += 2000
		"earthquake":
			for pid in PlayerManager.players:
				var s := PlayerManager.get_state(pid)
				if not s.temples.is_empty(): s.temples.pop_back()
		_:
			push_warning("Unknown effect key: " + effect_key)
	for pid in PlayerManager.players:
		GameManager._sync_player_state(pid)

func _get_card(card_id: String) -> CardData:
	for epoch in epoch_decks:
		for c: CardData in epoch_decks[epoch]:
			if c.card_id == card_id: return c
	return null
