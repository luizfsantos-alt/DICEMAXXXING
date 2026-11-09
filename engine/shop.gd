class_name Shop
extends RefCounted
## Ofertas da torre: recompensa pós-luta, Loja, Escola de Magia, Poço de Modificação e
## recompensa do Mestre. Loja: copiar um dado da bolsa e adesivo de ouro; Poço: adesivo
## de ouro. Uma oferta é {kind, id, price, needs}. needs: "" (aplica
## direto), "die" (escolher um dado da bolsa) ou "face" (escolher uma face de um dado).
## Magias e dados seguem a raridade (docs/RARIDADE.md): sorteia a classe, depois o item.

const STOPS := ["shop", "heal", "school", "well"]


static func _pick(a: Array, rng: RandomNumberGenerator):
	return a[rng.randi_range(0, a.size() - 1)]


# ------------------------------------------------------------------ Raridade
## Faixa de andares da tabela de raridade: 0 (1–3), 1 (4–6), 2 (7+).
static func band(floor_n: int) -> int:
	for b in Config.RARITY_BAND_FLOORS.size():
		if floor_n <= int(Config.RARITY_BAND_FLOORS[b]):
			return b
	return Config.RARITY_BAND_FLOORS.size()


## Sorteia a classe. max_r limita por cima (inimigos antes do andar 4); min_r por baixo.
static func roll_rarity(rng: RandomNumberGenerator, b: int, max_r := "", min_r := "") -> String:
	var w: Array = Config.RARITY_WEIGHTS[clampi(b, 0, Config.RARITY_WEIGHTS.size() - 1)]
	var lo: int = Config.RARITIES.find(min_r) if min_r != "" else 0
	var hi: int = Config.RARITIES.find(max_r) if max_r != "" else Config.RARITIES.size() - 1
	var total := 0
	for k in range(lo, hi + 1):
		total += int(w[k])
	var r := rng.randi_range(1, maxi(1, total))
	for k in range(lo, hi + 1):
		r -= int(w[k])
		if r <= 0:
			return Config.RARITIES[k]
	return Config.RARITIES[hi]


## Uma magia pela tabela, entre as que passam no filtro. "" se nenhuma passa.
## Se a classe sorteada não tem nenhuma, tenta as mais comuns e depois as mais raras.
static func pick_spell(rng: RandomNumberGenerator, b: int, filter: Callable = Callable(), max_r := "", min_r := "") -> String:
	var r := roll_rarity(rng, b, max_r, min_r)
	var k: int = Config.RARITIES.find(r)
	var lo: int = Config.RARITIES.find(min_r) if min_r != "" else 0
	var hi: int = Config.RARITIES.find(max_r) if max_r != "" else Config.RARITIES.size() - 1
	var tries := []
	for x in range(k, lo - 1, -1):
		tries.append(x)
	for x in range(k + 1, hi + 1):
		tries.append(x)
	for x in tries:
		var pool := Spells.ids_of_rarity(Config.RARITIES[x])
		if filter.is_valid():
			pool = pool.filter(filter)
		if not pool.is_empty():
			pool.sort()
			return _pick(pool, rng)
	return ""


static func pick_element(rng: RandomNumberGenerator, b: int, max_r := "") -> String:
	var r := roll_rarity(rng, b, max_r)
	return _pick(Elements.RARITY[r], rng)


static func spell_offer(id: String, priced: bool) -> Dictionary:
	return {"kind": "spell", "id": id, "price": Spells.price(id) if priced else 0, "needs": ""}


static func die_offer(el: String, priced: bool) -> Dictionary:
	var p := int(Config.PRICE_DIE_BY_RARITY[Elements.rarity(el)]) if priced else 0
	return {"kind": "die", "id": el, "price": p, "needs": ""}


static func copy_die_offer() -> Dictionary:
	return {"kind": "copy_die", "id": "", "price": Config.PRICE_COPY_DIE, "needs": "die"}


static func gold_sticker_offer() -> Dictionary:
	return {"kind": "gold_sticker", "id": "", "price": Config.PRICE_GOLD_STICKER, "needs": "face"}


static func element_offer(el: String) -> Dictionary:
	return {"kind": "element", "id": el, "price": int(Config.PRICE_ELEMENT_BY_RARITY[Elements.rarity(el)]), "needs": "die"}


# ------------------------------------------------------------------ Ofertas
## Recompensa pós-luta: 2 a 4 (pela porta) entre magia, dado, adesivo e vida máxima. A porta difícil
## sorteia uma faixa acima; a insana garante uma magia Rara. Minimalista: + destruir.
static func reward(hero: Fighter, rng: RandomNumberGenerator, floor_n := 1, door := "normal") -> Array:
	var b := band(floor_n) + (1 if door == "dificil" else 0)
	var kinds := ["spell", "die", "sticker", "maxhp"]
	Fighter._shuffle(kinds, rng)
	var out := []
	for k in kinds.slice(0, int(Config.REWARD_CHOICES.get(door, 3))):
		out.append(_make(k, rng, b))
	if door == "insana" and not out.any(func(o): return o.kind == "spell" and Spells.rarity(o.id) == "rare"):
		out[0] = spell_offer(pick_spell(rng, b, Callable(), "", "rare"), false)
	if hero.archetype == "minimalist":
		out.append({"kind": "destroy", "id": "", "price": 0, "needs": "die"})
	return out


static func shop(hero: Fighter, rng: RandomNumberGenerator, hp_bought: int, floor_n := 1) -> Array:
	var b := band(floor_n)
	var a := pick_spell(rng, b)
	var c := pick_spell(rng, b, func(x): return x != a)
	var out := [spell_offer(a, true), spell_offer(c, true), die_offer(pick_element(rng, b), true)]
	if hero.archetype == "metallurgist":
		out.append(die_offer("Pb", true))
	out.append(copy_die_offer())
	out.append(gold_sticker_offer())
	out.append({"kind": "maxhp", "id": "", "price": Config.PRICE_HP + hp_bought * Config.PRICE_HP_STEP, "needs": ""})
	return out


## Escola: 2 magias (a 2ª no mínimo Incomum) e até 3 evoluções. Evoluir uma Rara custa.
static func school(hero: Fighter, rng: RandomNumberGenerator, floor_n := 1) -> Array:
	var b := band(floor_n)
	var a := pick_spell(rng, b)
	var c := pick_spell(rng, b, func(x): return x != a, "", "uncommon")
	var out := [spell_offer(a, false), spell_offer(c, false)]
	var evolvable := []
	for i in hero.inventory.items.size():
		if int(hero.inventory.items[i].level) < Config.MAX_LEVEL:
			evolvable.append(i)
	Fighter._shuffle(evolvable, rng)
	for i in evolvable.slice(0, 3):
		var id: String = hero.inventory.items[i].id
		var p := Config.PRICE_EVOLVE_RARE if Spells.rarity(id) == "rare" else 0
		out.append({"kind": "evolve", "id": id, "item": i, "price": p, "needs": ""})
	return out


## Poço: adesivo, 2 elementos pela tabela e destruir (grátis para o Minimalista).
## O Metalurgista também pode aplicar Chumbo.
static func well(rng: RandomNumberGenerator, floor_n := 1, hero: Fighter = null) -> Array:
	var b := band(floor_n)
	var e1 := pick_element(rng, b)
	var e2 := e1
	for _k in 20:
		if e2 != e1:
			break
		e2 = pick_element(rng, b)
	var out := [
		{"kind": "sticker", "id": "", "price": Config.PRICE_STICKER, "needs": "face"},
		gold_sticker_offer(),
		element_offer(e1),
		element_offer(e2),
	]
	if hero and hero.archetype == "metallurgist":
		out.append(element_offer("Pb"))
	var free := hero != null and hero.archetype == "minimalist"
	out.append({"kind": "destroy", "id": "", "price": 0 if free else Config.PRICE_DESTROY, "needs": "die"})
	return out


static func rest_stops(rng: RandomNumberGenerator) -> Array:
	var s := STOPS.duplicate()
	Fighter._shuffle(s, rng)
	var out := []
	for id in s.slice(0, 3):
		out.append({"kind": "stop", "id": id, "price": 0, "needs": ""})
	return out


## Recompensa do Mestre de Andar: +casas, +1 dado na mão ou uma magia Rara (entre 3).
static func master_reward() -> Array:
	return [
		{"kind": "slots", "id": "", "price": 0, "needs": ""},
		{"kind": "hand", "id": "", "price": 0, "needs": ""},
		{"kind": "rare_pick", "id": "", "price": 0, "needs": ""},
	]


static func rare_choices(rng: RandomNumberGenerator) -> Array:
	var pool := Spells.ids_of_rarity("rare")
	pool.sort()
	Fighter._shuffle(pool, rng)
	var out := []
	for id in pool.slice(0, 3):
		out.append(spell_offer(id, false))
	return out


static func _make(kind: String, rng: RandomNumberGenerator, b: int) -> Dictionary:
	match kind:
		"spell":
			return spell_offer(pick_spell(rng, b), false)
		"die":
			return die_offer(pick_element(rng, b), false)
		"sticker":
			return {"kind": "sticker", "id": "", "price": 0, "needs": "face"}
	return {"kind": "maxhp", "id": "", "price": 0, "needs": ""}


## Preço real de uma oferta (o adesivo encarece com os adesivos já no dado).
static func price_of(o: Dictionary, hero: Fighter, target: Dictionary, destroys_used: int) -> int:
	var p := int(o.price)
	if p == 0:
		return 0
	match str(o.kind):
		"sticker":
			if target.has("die"):
				return p * (1 + hero.bag[int(target.die)].sticker_count())
		"destroy":
			return p + destroys_used * Config.PRICE_DESTROY_STEP
	return p


## Pode aplicar? "" se sim, ou a chave do texto do erro.
static func check(o: Dictionary, hero: Fighter, target: Dictionary) -> String:
	match str(o.kind):
		"spell":
			if not hero.inventory.fits(o.id):
				return "ui.no_room"
		"sticker", "gold_sticker":
			if not target.has("face"):
				return "ui.pick_face"
			if hero.bag[int(target.die)].locked[int(target.face)]:
				return "ui.locked_face"
		"element", "destroy", "copy_die":
			if not target.has("die"):
				return "ui.pick_die"
			if o.kind == "destroy" and hero.bag.size() <= 2:
				return "ui.bag_min"
	return ""


static func apply(o: Dictionary, hero: Fighter, target: Dictionary) -> void:
	match str(o.kind):
		"spell":
			hero.inventory.add(o.id)
		"die":
			hero.bag.append(Die.with_element(o.id) if o.id != "" else Die.basic())
		"sticker":
			hero.bag[int(target.die)].add_sticker(int(target.face))
		"gold_sticker":
			hero.bag[int(target.die)].add_gold(int(target.face))
		"copy_die":
			hero.bag.append(hero.bag[int(target.die)].copy())
		"element":
			Elements.apply(hero.bag[int(target.die)], o.id)
		"destroy":
			hero.bag.remove_at(int(target.die))
		"maxhp":
			hero.max_hp += Config.HP_UPGRADE
			hero.hp += Config.HP_UPGRADE
		"evolve":
			var it: Dictionary = hero.inventory.items[int(o.item)]
			it.level = mini(Config.MAX_LEVEL, int(it.level) + 1)
		"slots":
			hero.inventory.grow()
		"hand":
			hero.hand_size += 1
