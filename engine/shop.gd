class_name Shop
extends RefCounted
## Ofertas da torre: recompensa pós-luta, Loja, Escola de Magia, Poço de Modificação e
## recompensa do Mestre. Uma oferta é {kind, id, price, needs}. needs: "" (aplica
## direto), "die" (escolher um dado da bolsa) ou "face" (escolher uma face de um dado).
## Loja e Escola têm vagas ("slot") com estoque ("stock"); a vaga que esgota ("sold_out")
## fica esgotada até sair do mercado, mesmo trocando as ofertas.
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
	var r := roll_rarity(rng, b, max_r if max_r != "" else "rare") ## Não há elemento Lendário.
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
	if door == "insana" and not out.any(func(o): return o.kind == "spell" and Spells.rarity(o.id) in ["rare", "legendary"]):
		out[0] = spell_offer(pick_spell(rng, b, Callable(), "", "rare"), false)
	if hero.archetype == "minimalist":
		out.append({"kind": "destroy", "id": "", "price": 0, "needs": "die"})
	return out


static func sticker_offer() -> Dictionary:
	return {"kind": "sticker", "id": "", "price": Config.PRICE_STICKER, "needs": "face"}


static func maxhp_offer(hp_bought: int) -> Dictionary:
	return {"kind": "maxhp", "id": "", "price": Config.PRICE_HP + hp_bought * Config.PRICE_HP_STEP, "needs": ""}


static func _stock(rng: RandomNumberGenerator) -> int:
	return rng.randi_range(int(Config.SHOP_STOCK[0]), int(Config.SHOP_STOCK[1]))


## Loja: 1 dado com elemento e 1 adesivo (o +2 ou o de ouro), com estoque de 1 a 3; em
## metade das visitas, também copiar um dado ou +vida máxima (estoque 1). Não vende magias.
## prev: as ofertas de antes da troca (as vagas esgotadas continuam esgotadas).
static func shop(_hero: Fighter, rng: RandomNumberGenerator, hp_bought: int, floor_n := 1, prev: Array = []) -> Array:
	var b := band(floor_n)
	var d := die_offer(pick_element(rng, b), true)
	d.stock = _stock(rng)
	var st := sticker_offer() if rng.randf() < 0.5 else gold_sticker_offer()
	st.stock = _stock(rng)
	var out := [d, st]
	if rng.randf() < Config.SHOP_EXTRA_CHANCE:
		var x := copy_die_offer() if rng.randf() < 0.5 else maxhp_offer(hp_bought)
		x.stock = 1
		out.append(x)
	return _keep_sold_out(out, prev)


## Escola: 2 magias (a 2ª no mínimo Incomum), pelo preço da raridade, e até 2 evoluções
## pagas (Config.PRICE_EVOLVE). Cada oferta tem estoque 1.
static func school(hero: Fighter, rng: RandomNumberGenerator, floor_n := 1, prev: Array = []) -> Array:
	var b := band(floor_n)
	var a := pick_spell(rng, b)
	var c := pick_spell(rng, b, func(x): return x != a, "", "uncommon")
	var out := [spell_offer(a, true), spell_offer(c, true)]
	var evolvable := []
	for i in hero.inventory.items.size():
		if int(hero.inventory.items[i].level) < Config.MAX_LEVEL and not hero.inventory.items[i].get("temp", false):
			evolvable.append(i)
	Fighter._shuffle(evolvable, rng)
	for i in evolvable.slice(0, 2):
		var it: Dictionary = hero.inventory.items[i]
		out.append({"kind": "evolve", "id": it.id, "item": i, "price": evolve_price(str(it.id), int(it.level)), "needs": ""})
	for o in out:
		o.stock = 1
	return _keep_sold_out(out, prev)


## Preço de evoluir a magia que está no nível "level".
static func evolve_price(id: String, level: int) -> int:
	var p := int(Config.PRICE_EVOLVE[clampi(level, 1, Config.PRICE_EVOLVE.size()) - 1])
	if Spells.rarity(id) in ["rare", "legendary"]:
		p += Config.PRICE_EVOLVE_RARE_EXTRA
	return p


## Numera as vagas das ofertas novas e mantém as vagas que esgotaram antes da troca.
static func _keep_sold_out(fresh: Array, prev: Array) -> Array:
	for k in fresh.size():
		fresh[k].slot = k
	var n := fresh.size()
	for o in prev:
		n = maxi(n, int(o.get("slot", 0)) + 1)
	var out := []
	for k in n:
		var old: Array = prev.filter(func(o): return int(o.get("slot", -1)) == k and o.get("sold_out", false))
		if not old.is_empty():
			out.append(old[0])
		elif k < fresh.size():
			out.append(fresh[k])
	return out


## Custo da troca de ofertas número n (0 = a primeira) na Loja ou na Escola.
static func reroll_price(place: String, n: int) -> int:
	if place == "school":
		return Config.SCHOOL_REROLL_BASE + Config.SCHOOL_REROLL_STEP * n
	if n < Config.SHOP_REROLL_FREE:
		return 0
	return Config.SHOP_REROLL_BASE + Config.SHOP_REROLL_STEP * (n - Config.SHOP_REROLL_FREE)


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


## Mercado: 3 das 4 paradas e, sempre, Vender magias (por último).
static func rest_stops(rng: RandomNumberGenerator) -> Array:
	var s := STOPS.duplicate()
	Fighter._shuffle(s, rng)
	var out := []
	for id in s.slice(0, 3):
		out.append({"kind": "stop", "id": id, "price": Config.PRICE_HEAL_STOP if id == "heal" else 0, "needs": ""})
	out.append({"kind": "stop", "id": "sell", "price": 0, "needs": ""})
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
	if o.get("sold_out", false):
		return "ui.sold_out"
	match str(o.kind):
		"spell":
			if target.has("x"):
				if not hero.inventory.can_place(o.id, posmod(int(target.get("rot", 0)), 4), int(target.x), int(target.y)):
					return "ui.no_room"
			elif not hero.inventory.fits(o.id):
				return "ui.no_room"
		"evolve":
			var k := int(o.get("item", -1))
			var items := hero.inventory.items
			if k < 0 or k >= items.size() or str(items[k].id) != str(o.id) or int(items[k].level) >= Config.MAX_LEVEL:
				return "ui.invalid"
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
			if target.has("x"):
				hero.inventory.add_at(o.id, int(target.x), int(target.y), int(target.get("rot", 0)))
			else:
				hero.inventory.add(o.id) ## Sem lugar escolhido (bot, testes): encaixa onde couber.
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
