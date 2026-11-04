class_name Fighter
extends RefCounted
## Um lado do duelo (jogador ou inimigo): bolsa, inventário de magias e estado da luta.

var name: String = ""
var is_player: bool = false
var archetype: String = "sorcerer" ## sorcerer, assassin
var variant: String = "" ## "", lixeiro, piromante
var master_id: String = "" ## Mestre de Andar (ex.: porteiro).
var personality: String = "" ## bruto, cauteloso, caotico (oculta na UI).
var max_hp: int = 50
var hp: int = 50
var hand_size: int = Config.HAND_SIZE
var bag: Array = [] ## Array[Die]
var inventory: Inventory = Inventory.make(4, 3)

# Estado da luta.
var draw_pile: Array = [] ## Índices da bolsa.
var discard: Array = []
var hand: Array = [] ## [{bag: int (-1 = temporário), temp: Die|null, face: int, value: int}]
var last_hand: Array = [] ## Valores da última mão (visível ao adversário).
var block: int = 0
var mirror: bool = false
var dodge: bool = false
var poison: int = 0
var burn: int = 0
var sacrifice_bonus: int = 0
var once_used: Array = [] ## Índices do inventário já usados nesta luta.
var turns_taken: int = 0


func die_of(entry: Dictionary) -> Die:
	if int(entry.bag) >= 0:
		return bag[int(entry.bag)]
	return entry.temp


func hand_values() -> Array:
	var out := []
	for e in hand:
		out.append(int(e.value))
	return out


func heal(n: int) -> int:
	if n <= 0:
		return 0
	var before := hp
	hp = mini(max_hp, hp + n)
	return hp - before


func reset_fight_state() -> void:
	draw_pile = range(bag.size())
	discard = []
	hand = []
	last_hand = []
	block = 0
	mirror = false
	dodge = false
	poison = 0
	burn = 0
	sacrifice_bonus = 0
	once_used = []
	turns_taken = 0


## Tira a mão da bolsa. Na primeira mão, o Ósmio sai sempre.
func draw_hand(rng: RandomNumberGenerator) -> void:
	hand = []
	if turns_taken == 0:
		for i in draw_pile.duplicate():
			if hand.size() < hand_size and bag[i].element == "Os":
				draw_pile.erase(i)
				hand.append(_entry(i))
	while hand.size() < hand_size:
		if draw_pile.is_empty():
			if discard.is_empty():
				break
			draw_pile = discard
			discard = []
			_shuffle(draw_pile, rng)
		var k := rng.randi_range(0, draw_pile.size() - 1)
		hand.append(_entry(int(draw_pile.pop_at(k))))


func add_temp(d: Die) -> void:
	hand.append({"bag": -1, "temp": d, "face": 0, "value": 0})


func _entry(i: int) -> Dictionary:
	return {"bag": i, "temp": null, "face": 0, "value": 0}


## Rola a mão. foe_last: últimos valores do adversário (Mercúrio).
func roll_hand(rng: RandomNumberGenerator, foe_last: Array) -> void:
	for e in hand:
		var d := die_of(e)
		e.face = rng.randi_range(0, 5)
		e.value = d.value(e.face)
		if d.element == "H" and bag.size() <= Elements.SOLITARY_BAG:
			e.value *= 3
	var top := 0
	for e in hand:
		if die_of(e).element != "Hg":
			top = maxi(top, int(e.value))
	for v in foe_last:
		top = maxi(top, int(v))
	for e in hand:
		if die_of(e).element == "Hg":
			e.value = maxi(int(e.value), top)


## Remove um dado da bolsa para sempre (Sacrifício, Fornalha) e corrige os índices.
func destroy_bag_die(i: int) -> void:
	bag.remove_at(i)
	for arr in [draw_pile, discard]:
		arr.erase(i)
		for k in arr.size():
			if arr[k] > i:
				arr[k] -= 1
	for e in hand:
		if int(e.bag) == i:
			e.bag = -2 ## Destruído: some no descarte.
		elif int(e.bag) > i:
			e.bag = int(e.bag) - 1


func discard_hand() -> void:
	last_hand = hand_values()
	for e in hand:
		if int(e.bag) >= 0:
			discard.append(int(e.bag))
	hand = []


static func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp


func to_dict() -> Dictionary:
	var bag_d := []
	for d in bag:
		bag_d.append(d.to_dict())
	var hand_d := []
	for e in hand:
		hand_d.append({"bag": e.bag, "temp": e.temp.to_dict() if e.temp else {}, "face": e.face, "value": e.value})
	return {
		"name": name, "is_player": is_player, "archetype": archetype, "variant": variant,
		"master_id": master_id, "personality": personality, "max_hp": max_hp, "hp": hp,
		"hand_size": hand_size, "bag": bag_d, "inventory": inventory.to_dict(),
		"draw_pile": draw_pile, "discard": discard, "hand": hand_d, "last_hand": last_hand,
		"block": block, "mirror": mirror, "dodge": dodge, "poison": poison, "burn": burn,
		"sacrifice_bonus": sacrifice_bonus, "once_used": once_used, "turns_taken": turns_taken,
	}


static func from_dict(d: Dictionary) -> Fighter:
	var f := Fighter.new()
	f.name = str(d.get("name", ""))
	f.is_player = bool(d.get("is_player", false))
	f.archetype = str(d.get("archetype", "sorcerer"))
	f.variant = str(d.get("variant", ""))
	f.master_id = str(d.get("master_id", ""))
	f.personality = str(d.get("personality", ""))
	f.max_hp = int(d.get("max_hp", 50))
	f.hp = int(d.get("hp", 50))
	f.hand_size = int(d.get("hand_size", Config.HAND_SIZE))
	for x in d.get("bag", []):
		f.bag.append(Die.from_dict(x))
	f.inventory = Inventory.from_dict(d.get("inventory", {}))
	f.draw_pile = Die._ints(d.get("draw_pile", []))
	f.discard = Die._ints(d.get("discard", []))
	for e in d.get("hand", []):
		var t: Dictionary = e.get("temp", {})
		f.hand.append({"bag": int(e.bag), "temp": Die.from_dict(t) if not t.is_empty() else null,
			"face": int(e.face), "value": int(e.value)})
	f.last_hand = Die._ints(d.get("last_hand", []))
	f.block = int(d.get("block", 0))
	f.mirror = bool(d.get("mirror", false))
	f.dodge = bool(d.get("dodge", false))
	f.poison = int(d.get("poison", 0))
	f.burn = int(d.get("burn", 0))
	f.sacrifice_bonus = int(d.get("sacrifice_bonus", 0))
	f.once_used = Die._ints(d.get("once_used", []))
	f.turns_taken = int(d.get("turns_taken", 0))
	return f
