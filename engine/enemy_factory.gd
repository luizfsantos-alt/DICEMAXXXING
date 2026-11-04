class_name EnemyFactory
extends RefCounted
## Inimigos montados como um jogador (docs/SPEC_v3.md §8): mesmo arquétipo, mesmo
## inventário inicial e um orçamento de melhorias proporcional ao andar e à porta.


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
		f = base("assassin" if rng.randf() < 0.5 else "sorcerer")
		var r := rng.randf()
		if r < 0.2:
			f.variant = "lixeiro" if f.archetype == "assassin" else "piromante"
		f.personality = EnemyAI.PERSONALITIES[rng.randi_range(0, EnemyAI.PERSONALITIES.size() - 1)]
		f.name = random_name(rng)
	if f.variant == "piromante":
		Elements.apply(f.bag[0], "Na")
		Elements.apply(f.bag[1], "Na")
	f.max_hp = int(round((Config.ENEMY_HP_BASE + Config.ENEMY_HP_PER_FLOOR * (floor_n - 1)) * mult))
	if is_master(floor_n):
		f.max_hp = int(round(f.max_hp * Config.MASTER_HP_MULT))
	var budget := int(round((floor_n - 1) * mult * Config.ENEMY_UPGRADES_PER_FLOOR))
	for _k in budget:
		upgrade(f, rng)
	f.hp = f.max_hp
	return f


static func base(archetype: String) -> Fighter:
	var f := Fighter.new()
	f.archetype = archetype
	var grid: Vector2i = Config.SORCERER_GRID if archetype == "sorcerer" else Config.ASSASSIN_GRID
	f.inventory = Inventory.make(grid.x, grid.y)
	var ids: Array = Spells.STARTING[archetype]
	for k in ids.size():
		var pos: Array = Spells.STARTING_LAYOUT[archetype][k]
		f.inventory.items.append({"id": ids[k], "level": 1, "x": pos[0], "y": pos[1], "rot": pos[2]})
	for _i in Config.START_BAG:
		f.bag.append(Die.basic())
	f.hand_size = Config.HAND_SIZE + (Config.ASSASSIN_HAND_BONUS if archetype == "assassin" else 0)
	return f


## Uma melhoria aleatória, como uma recompensa de jogador.
static func upgrade(f: Fighter, rng: RandomNumberGenerator) -> void:
	match rng.randi_range(0, 4):
		0:
			var pool := Spells.DATA.keys().filter(func(id): return Spells.in_pool(id, f.archetype) and f.inventory.fits(id))
			if not pool.is_empty():
				f.inventory.add(pool[rng.randi_range(0, pool.size() - 1)])
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
			var d: Die = f.bag[rng.randi_range(0, f.bag.size() - 1)]
			if d.element == "":
				Elements.apply(d, Elements.SHOP[rng.randi_range(0, Elements.SHOP.size() - 1)])
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
