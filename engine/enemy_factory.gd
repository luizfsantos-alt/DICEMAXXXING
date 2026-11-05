class_name EnemyFactory
extends RefCounted
## Inimigos montados como um jogador (docs/SPEC_v3.md §8): mesmo arquétipo, mesmo
## inventário inicial e um orçamento de melhorias proporcional ao andar e à porta.
## As compras seguem a tabela de raridade do andar (docs/RARIDADE.md).

## Variantes por arquétipo (docs/PERSONAGENS.md §4).
const VARIANTS := {
	"assassin": "lixeiro", "sorcerer": "piromante", "metallurgist": "fundidor", "minimalist": "monge",
}


static func is_master(floor_n: int) -> bool:
	return floor_n in Config.MASTER_FLOORS


static func create(floor_n: int, door: String, rng: RandomNumberGenerator) -> Fighter:
	var mult: float = Config.DOORS.get(door, Config.DOORS.normal)[0]
	var f: Fighter
	if is_master(floor_n):
		f = base("sorcerer")
		f.master_id = "porteiro"
		f.personality = "cauteloso"
		f.name = Texts.master_name("porteiro")
		mult = 1.0
	else:
		f = base(Characters.ALL[rng.randi_range(0, Characters.ALL.size() - 1)])
		var v: String = VARIANTS.get(f.archetype, "")
		if v != "" and rng.randf() < Config.VARIANT_CHANCE and (v != "monge" or floor_n >= Config.MONK_FLOOR):
			f.variant = v
		f.personality = EnemyAI.PERSONALITIES[rng.randi_range(0, EnemyAI.PERSONALITIES.size() - 1)]
		f.name = random_name(rng)
	match f.variant:
		"piromante":
			var n := 0
			for d in f.bag:
				if n < 2 and d.element == "":
					Elements.apply(d, "Na")
					n += 1
		"monge":
			f.bag = []
			for _i in 4:
				f.bag.append(Die.with_element("H"))
	f.max_hp = int(round((Config.ENEMY_HP_BASE + Config.ENEMY_HP_PER_FLOOR * (floor_n - 1)) * mult))
	if f.archetype == "minimalist":
		f.max_hp = int(round(f.max_hp * Config.MINIMALIST_ENEMY_HP_MULT))
	if is_master(floor_n):
		f.max_hp = int(round(f.max_hp * Config.MASTER_HP_MULT))
	var budget := int(round((floor_n - 1) * mult * Config.ENEMY_UPGRADES_PER_FLOOR))
	for _k in budget:
		upgrade(f, rng, floor_n)
	f.hp = f.max_hp
	return f


## Lutador com o kit inicial do arquétipo (o mesmo do jogador).
static func base(archetype: String) -> Fighter:
	var c := Characters.get_def(archetype)
	var f := Fighter.new()
	f.archetype = archetype if Characters.DATA.has(archetype) else "sorcerer"
	var grid: Vector2i = c.grid
	f.inventory = Inventory.make(grid.x, grid.y, c.blocked)
	for s in c.spells:
		f.inventory.items.append({"id": s[0], "level": s[4], "x": s[1], "y": s[2], "rot": s[3]})
	for el in c.bag:
		f.bag.append(Die.with_element(el))
	while f.bag.size() < int(c.bag_size):
		f.bag.append(Die.basic())
	f.hand_size = int(c.hand)
	f.max_hp = int(c.hp)
	f.hp = f.max_hp
	return f


## Uma melhoria aleatória, como uma recompensa de jogador.
static func upgrade(f: Fighter, rng: RandomNumberGenerator, floor_n := 1) -> void:
	match rng.randi_range(0, 4):
		0:
			var id := Shop.pick_spell(rng, Shop.band(floor_n), func(x): return Spells.in_pool(x, f.archetype) and f.inventory.fits(x),
				"" if floor_n >= Config.RARE_ENEMY_FLOOR else "uncommon")
			if id != "":
				f.inventory.add(id)
				return
			_sticker(f, rng)
		1:
			var it: Array = f.inventory.items.filter(func(x): return int(x.level) < Config.MAX_LEVEL)
			if not it.is_empty():
				var x: Dictionary = it[rng.randi_range(0, it.size() - 1)]
				x.level = int(x.level) + 1
				return
			_sticker(f, rng)
		2:
			var plain := f.bag.filter(func(d): return d.element == "")
			if not plain.is_empty():
				var max_r := "" if floor_n >= Config.RARE_ENEMY_FLOOR else "uncommon"
				Elements.apply(plain[rng.randi_range(0, plain.size() - 1)], Shop.pick_element(rng, Shop.band(floor_n), max_r))
			else:
				_sticker(f, rng)
		3:
			f.max_hp += Config.HP_UPGRADE
		_:
			_sticker(f, rng)


static func _sticker(f: Fighter, rng: RandomNumberGenerator) -> void:
	var d: Die = f.bag[rng.randi_range(0, f.bag.size() - 1)]
	d.add_sticker(rng.randi_range(3, 5)) ## Faces altas, como faria um jogador.


static func random_name(rng: RandomNumberGenerator) -> String:
	var titles := Texts.name_list("titles")
	var first := Texts.name_list("first")
	var epithets := Texts.name_list("epithets")
	if first.is_empty():
		return "Inimigo"
	var parts := []
	if not titles.is_empty() and rng.randf() < 0.5:
		parts.append(titles[rng.randi_range(0, titles.size() - 1)])
	parts.append(first[rng.randi_range(0, first.size() - 1)])
	var n := " ".join(parts)
	if not epithets.is_empty():
		var e: String = epithets[rng.randi_range(0, epithets.size() - 1)]
		n += (", " if e.begins_with("o ") else " ") + e
	return n
