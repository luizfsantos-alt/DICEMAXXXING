class_name EnemyFactory
extends RefCounted
## Inimigos montados como um jogador (docs/SPEC_v3.md §8): mesmo arquétipo, mesmo
## inventário inicial e uma "jornada fantasma": o inimigo do andar N recebe o que um
## jogador teria juntado até ali pelas mesmas regras (uma recompensa por andar vencido e
## as moedas gastas no mercado: Loja, Escola e Poço). A porta soma ou tira andares dessa
## jornada (Config.DOOR_JOURNEY). Os Mestres têm kit fixo.

## Variantes por arquétipo (docs/PERSONAGENS.md §4).
const VARIANTS := {
	"assassin": "lixeiro", "sorcerer": "piromante", "metallurgist": "fundidor", "minimalist": "monge",
}


static func is_master(floor_n: int) -> bool:
	return Config.MASTERS.has(floor_n)


## Id do Mestre do andar ("" se o andar não tem Mestre).
static func master_of(floor_n: int) -> String:
	return str(Config.MASTERS[floor_n][0]) if is_master(floor_n) else ""


static func create(floor_n: int, door: String, rng: RandomNumberGenerator) -> Fighter:
	var mult: float = Config.DOORS.get(door, Config.DOORS.normal)[0]
	var f: Fighter
	if is_master(floor_n):
		var m: Array = Config.MASTERS[floor_n]
		f = base(str(m[1]))
		f.master_id = str(m[0])
		f.personality = "cauteloso"
		f.name = Texts.master_name(f.master_id)
		mult = 1.0
		_master_kit(f)
	else:
		f = base(Characters.ALL[rng.randi_range(0, Characters.ALL.size() - 1)])
		var v: String = VARIANTS.get(f.archetype, "")
		if v != "" and rng.randf() < Config.VARIANT_CHANCE and (v != "monge" or floor_n >= Config.MONK_FLOOR):
			f.variant = v
		f.personality = EnemyAI.PERSONALITIES[rng.randi_range(0, EnemyAI.PERSONALITIES.size() - 1)]
		f.name = "" ## Só os Mestres têm nome (Texts.fighter_title).
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
	f.max_hp = int(round(floor_hp(floor_n) * mult))
	if f.archetype == "minimalist":
		f.max_hp = int(round(f.max_hp * Config.MINIMALIST_ENEMY_HP_MULT))
	if is_master(floor_n):
		f.max_hp = int(round(f.max_hp * float(Config.MASTER_HP_MULT[floor_n])))
	if not is_master(floor_n):
		journey(f, journey_floor(floor_n, door), rng, floor_n < Config.RARE_ENEMY_FLOOR)
	f.max_hp = maxi(1, int(round(f.max_hp * Config.ENEMY_HP_MULT)))
	f.hp = f.max_hp
	return f


## Kit fixo do Mestre (Config.MASTER_KITS): bolsa e magias que jogam com a regra dele.
static func _master_kit(f: Fighter) -> void:
	var k: Dictionary = Config.MASTER_KITS.get(f.master_id, {})
	if k.is_empty():
		return
	f.bag = []
	for el in k.bag:
		f.bag.append(Die.with_element(str(el)))
	while f.bag.size() < int(k.bag_size):
		f.bag.append(Die.basic())
	f.inventory.items = []
	for sp in k.spells:
		f.inventory.items.append({"id": sp[0], "level": sp[4], "x": sp[1], "y": sp[2], "rot": sp[3]})


## Vida base do inimigo no andar (antes da porta e dos ajustes).
static func floor_hp(floor_n: int) -> float:
	var early := mini(floor_n, Config.LATE_FLOOR) - 1
	var late := maxi(0, floor_n - Config.LATE_FLOOR)
	return Config.ENEMY_HP_BASE + Config.ENEMY_HP_PER_FLOOR * early + Config.ENEMY_HP_PER_FLOOR_LATE * late


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


# ------------------------------------------------------------------ Jornada fantasma
## Andar a que a jornada fantasma chega, pela porta (Config.DOOR_JOURNEY).
static func journey_floor(floor_n: int, door: String) -> int:
	return 1 + int(round((floor_n - 1) * float(Config.DOOR_JOURNEY.get(door, 1.0))))


## Dá ao inimigo o que um jogador juntaria vencendo os andares 1 a floor_n - 1: em cada
## andar, as moedas da porta normal (ou do Mestre) e uma recompensa (Shop.reward, ou a do
## Mestre); a cada Config.REST_EVERY andares, um mercado onde gasta as moedas. Escolhe só
## magias do grupo dele; não vende. no_rare: nada Raro (antes de Config.RARE_ENEMY_FLOOR).
static func journey(f: Fighter, floor_n: int, rng: RandomNumberGenerator, no_rare := false) -> void:
	var coins := 0
	var since := 0
	var g := {"hp_bought": 0, "no_rare": no_rare}
	for k in range(1, maxi(1, floor_n)):
		if is_master(k) and k < Config.LAST_FLOOR:
			coins += Config.MASTER_COINS
			_ghost_master(f, rng)
		else:
			coins += int(Config.DOORS.normal[1])
			_ghost_pick(f, rng, Shop.reward(f, rng, k, "normal"), 999, g)
		since += 1
		if since >= Config.REST_EVERY:
			since = 0
			coins = _ghost_market(f, rng, k + 1, coins, g)


## Valor de uma oferta para o inimigo (< 0: não serve). Com um pouco de sorte no meio.
static func _ghost_score(f: Fighter, o: Dictionary, g: Dictionary) -> float:
	match str(o.kind):
		"spell":
			var id := str(o.id)
			if id == "" or not Spells.in_pool(id, f.archetype):
				return -1.0
			var r := Spells.rarity(id)
			if g.no_rare and r in ["rare", "legendary"]:
				return -1.0
			if not f.inventory.fits(id):
				return -1.0
			return 10.0 + {"common": 0.0, "uncommon": 3.0, "rare": 6.0, "legendary": 9.0}.get(r, 0.0)
		"evolve":
			return 8.0 + 2.0 * int(f.inventory.items[int(o.item)].level == 1)
		"sticker", "gold_sticker":
			return 7.0
		"die", "copy_die":
			if f.archetype == "minimalist":
				return -1.0 ## O Hidrogênio quer a bolsa pequena.
			return (5.0 if o.kind == "die" else 6.0) if f.bag.size() < 12 else 1.0
		"element":
			return 6.0 if _plain(f) >= 0 else -1.0
		"maxhp":
			return 5.0
	return -1.0 ## Destruir, Cura: o inimigo não usa.


## Escolhe e aplica as ofertas que valem, dentro das moedas (max_buys = 1 numa recompensa).
## Devolve as moedas que sobraram.
static func _ghost_pick(f: Fighter, rng: RandomNumberGenerator, opts: Array, coins: int, g: Dictionary, max_buys := 1) -> int:
	for _b in max_buys:
		var best := -1
		var best_s := 0.0
		var best_p := 0
		for j in opts.size():
			var o: Dictionary = opts[j]
			if o.get("sold_out", false):
				continue
			var s := _ghost_score(f, o, g)
			if s <= 0.0:
				continue
			var p := _ghost_price(f, o, g)
			if p > coins:
				continue
			s += rng.randf() * 3.0
			if s > best_s:
				best_s = s
				best = j
				best_p = p
		if best < 0:
			break
		var o: Dictionary = opts[best]
		coins -= best_p
		_ghost_apply(f, rng, o, g)
		var st := int(o.get("stock", 1)) - 1
		o.stock = st
		if st <= 0:
			o["sold_out"] = true
	return coins


static func _ghost_price(f: Fighter, o: Dictionary, _g: Dictionary) -> int:
	var p := int(o.price)
	if str(o.kind) == "sticker" and p > 0:
		var t := _sticker_target(f, null)
		p *= 1 + f.bag[t[0]].sticker_count()
	return p


static func _ghost_apply(f: Fighter, rng: RandomNumberGenerator, o: Dictionary, g: Dictionary) -> void:
	match str(o.kind):
		"spell":
			f.inventory.add(str(o.id))
		"evolve":
			var it: Dictionary = f.inventory.items[int(o.item)]
			it.level = mini(Config.MAX_LEVEL, int(it.level) + 1)
		"sticker", "gold_sticker":
			_sticker(f, rng) ## O de ouro só daria moedas: vira um adesivo comum.
		"die":
			f.bag.append(Die.with_element(_ghost_element(str(o.id), rng, g)))
		"element":
			var k := _plain(f)
			if k >= 0:
				Elements.apply(f.bag[k], _ghost_element(str(o.id), rng, g))
		"copy_die":
			var best := 0
			for i in f.bag.size():
				if f.bag[i].face_sum() > f.bag[best].face_sum():
					best = i
			f.bag.append(f.bag[best].copy())
		"maxhp":
			f.max_hp += Config.HP_UPGRADE
			g.hp_bought = int(g.hp_bought) + 1


## Ouro só dá moedas a quem tem jornada: o inimigo sorteia outro (Sódio se não sair).
## Antes do andar 4, nada Raro.
static func _ghost_element(el: String, rng: RandomNumberGenerator, g: Dictionary) -> String:
	var max_r := "uncommon" if g.no_rare else ""
	if el != "Au" and not (g.no_rare and Elements.rarity(el) == "rare"):
		return el
	for _t in 20:
		var e := Shop.pick_element(rng, 0, max_r)
		if e != "Au":
			return e
	return "Na"


static func _plain(f: Fighter) -> int:
	for i in f.bag.size():
		if f.bag[i].element == "":
			return i
	return -1


## Mestre vencido na jornada: uma Rara do grupo entre as 3 oferecidas; senão, +1 coluna.
static func _ghost_master(f: Fighter, rng: RandomNumberGenerator) -> void:
	for o in Shop.rare_choices(rng):
		if Spells.in_pool(str(o.id), f.archetype) and f.inventory.fits(str(o.id)):
			f.inventory.add(str(o.id))
			return
	f.inventory.grow()


## Mercado: entra nas paradas sorteadas (Loja, Escola, Poço; a Cura não serve) em ordem
## aleatória e compra o que vale, com os preços e estoques do jogador.
static func _ghost_market(f: Fighter, rng: RandomNumberGenerator, floor_n: int, coins: int, g: Dictionary) -> int:
	var ids := Shop.rest_stops(rng).map(func(o): return str(o.id)).filter(func(x): return x in ["shop", "school", "well"])
	Fighter._shuffle(ids, rng)
	for id in ids:
		match id:
			"shop":
				coins = _ghost_pick(f, rng, Shop.shop(f, rng, int(g.hp_bought), floor_n), coins, g, 8)
			"school":
				coins = _ghost_pick(f, rng, Shop.school(f, rng, floor_n), coins, g, 4)
			"well":
				var w := Shop.well(rng, floor_n, f).filter(func(o): return str(o.kind) != "destroy")
				for o in w:
					o.stock = 1 if str(o.kind) == "element" else 3
				coins = _ghost_pick(f, rng, w, coins, g, 4)
	return coins


## Face que recebe o adesivo do inimigo: metade das vezes a que já tem mais adesivos (os
## números explodem também do lado dele; docs/SPEC_v3.1.md §7), senão uma face alta.
## Sem rng: a face com mais adesivos ou a 6 do primeiro dado (só para o preço).
static func _sticker_target(f: Fighter, rng: RandomNumberGenerator) -> Array:
	if rng == null or rng.randf() < Config.ENEMY_STICKER_STACK:
		var best := -1
		var face := 0
		for i in f.bag.size():
			var bd: Die = f.bag[i]
			for k in 6:
				if bd.locked[k] or int(bd.stickers[k]) <= 0:
					continue
				if best < 0 or int(bd.stickers[k]) > int(f.bag[best].stickers[face]):
					best = i
					face = k
		if best >= 0:
			return [best, face]
	if rng == null:
		return [0, 5]
	return [rng.randi_range(0, f.bag.size() - 1), rng.randi_range(3, 5)] ## Faces altas, como faria um jogador.


static func _sticker(f: Fighter, rng: RandomNumberGenerator) -> void:
	var t := _sticker_target(f, rng)
	f.bag[t[0]].add_sticker(t[1])
