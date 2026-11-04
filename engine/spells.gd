class_name Spells
extends RefCounted
## Magias (docs/SPEC_v3.md §5): formato, exigência, efeito e uso.
##
## Exigências ("req"):
## - any:  N dados quaisquer ("n" = quantidade).
## - max:  1 dado de valor ≤ "v".
## - exact:1 dado de valor exatamente "v".
## - pair: 2 dados iguais.
## - seq3: 3 dados em sequência (ex.: 3-4-5).
##
## Efeitos ("fx"): dmg (dano = soma + "plus"; × "mult"), block, dodge, mirror,
## heal, maxhp, sacrifice. "burn" opcional; "odd_twice"
## golpeia de novo se todos os dados forem ímpares.

const DATA := {
	"faisca": {"shape": [Vector2i(0, 0)], "req": "any", "n": 1, "fx": "dmg", "use": "always", "pool": "sorcerer"},
	"escudo": {"shape": [Vector2i(0, 0), Vector2i(0, 1)], "req": "max", "v": 3, "fx": "block", "mult": 3, "use": "always", "pool": "sorcerer"},
	"bola": {"shape": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)], "req": "pair", "fx": "dmg", "mult": 2, "burn": 3, "use": "once", "pool": "sorcerer"},
	"meteoro": {"shape": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)], "req": "seq3", "fx": "dmg", "plus": 10, "use": "once", "pool": "sorcerer"},
	"espelho": {"shape": [Vector2i(0, 0)], "req": "exact", "v": 1, "fx": "mirror", "use": "always", "pool": "sorcerer"},
	"sacrificio": {"shape": [Vector2i(0, 0)], "req": "exact", "v": 1, "fx": "sacrifice", "use": "always", "pool": "sorcerer"},
	"remendo": {"shape": [Vector2i(0, 0)], "req": "any", "n": 1, "fx": "heal", "use": "once", "pool": "any"},
	"transfusao": {"shape": [Vector2i(0, 0), Vector2i(1, 0)], "req": "pair", "fx": "maxhp", "use": "once", "pool": "sorcerer"},
	"estocada": {"shape": [Vector2i(0, 0)], "req": "any", "n": 1, "fx": "dmg", "plus": 1, "use": "always", "pool": "assassin"},
	"esquiva": {"shape": [Vector2i(0, 0)], "req": "max", "v": 2, "fx": "dodge", "use": "once", "pool": "assassin"},
	"corte": {"shape": [Vector2i(0, 0), Vector2i(1, 0)], "req": "any", "n": 2, "fx": "dmg", "odd_twice": true, "use": "always", "pool": "assassin"},
}

const STARTING := {
	"sorcerer": ["faisca", "escudo", "bola"],
	"assassin": ["estocada", "esquiva", "corte"],
}
## Arranjo inicial: [x, y, rot] de cada magia inicial. O do Feiticeiro deixa um L livre.
const STARTING_LAYOUT := {
	"sorcerer": [[3, 0, 0], [2, 0, 0], [0, 0, 0]],
	"assassin": [[0, 0, 0], [1, 0, 0], [2, 0, 0]],
}
const ERUDITE_CHOICES := ["espelho", "remendo", "sacrificio", "transfusao", "meteoro"]


static func get_def(id: String) -> Dictionary:
	return DATA.get(id, {})


static func dice_needed(id: String) -> int:
	var d := get_def(id)
	match str(d.get("req", "any")):
		"any":
			return int(d.get("n", 1))
		"pair":
			return 2
		"seq3":
			return 3
	return 1


static func is_once(id: String) -> bool:
	return str(get_def(id).get("use", "always")) == "once"


## Formato girado: rot 0..3 (90° no sentido horário), normalizado para começar em (0,0).
static func shape(id: String, rot: int = 0) -> Array:
	var cells: Array = []
	for c in get_def(id).get("shape", [Vector2i(0, 0)]):
		var p: Vector2i = c
		for _k in posmod(rot, 4):
			p = Vector2i(-p.y, p.x)
		cells.append(p)
	var mn := Vector2i(999, 999)
	for p in cells:
		mn = Vector2i(mini(mn.x, p.x), mini(mn.y, p.y))
	var out: Array = []
	for p in cells:
		out.append(p - mn)
	return out


## O dado de valor v pode entrar ao lado dos valores já postos?
static func accepts_partial(id: String, placed: Array, v: int) -> bool:
	var d := get_def(id)
	if placed.size() >= dice_needed(id):
		return false
	match str(d.get("req", "any")):
		"max":
			return v <= int(d.v)
		"exact":
			return v == int(d.v)
		"pair":
			return placed.is_empty() or int(placed[0]) == v
		"seq3":
			if v in placed:
				return false
			var all := placed.duplicate()
			all.append(v)
			return int(all.max()) - int(all.min()) <= 2
	return true


## A magia está pronta para ser lançada com estes valores?
static func complete(id: String, values: Array) -> bool:
	if values.size() != dice_needed(id):
		return false
	var placed := []
	for v in values:
		if not accepts_partial(id, placed, int(v)):
			return false
		placed.append(v)
	return true


static func sell_price(level: int) -> int:
	return Config.ceil_div(Config.PRICE_SPELL * level, 2)
