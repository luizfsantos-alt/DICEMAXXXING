class_name Shop
extends RefCounted
## Ofertas da torre: recompensa pós-luta, Loja, Escola de Magia e Poço de Modificação.
## Uma oferta é {kind, id, price, needs}. needs: "" (aplica direto), "die" (escolher
## um dado da bolsa) ou "face" (escolher uma face de um dado).

const STOPS := ["shop", "heal", "school", "well"]


static func spell_pool(_hero: Fighter) -> Array:
	return Spells.DATA.keys()


static func _pick(a: Array, rng: RandomNumberGenerator):
	return a[rng.randi_range(0, a.size() - 1)]


static func reward(hero: Fighter, rng: RandomNumberGenerator) -> Array:
	var kinds := ["spell", "die", "sticker", "maxhp"]
	Fighter._shuffle(kinds, rng)
	var out := []
	for k in kinds.slice(0, 3):
		out.append(_make(k, hero, rng, 0))
	return out


static func shop(hero: Fighter, rng: RandomNumberGenerator, hp_bought: int) -> Array:
	var pool := spell_pool(hero)
	Fighter._shuffle(pool, rng)
	var out := [
		{"kind": "spell", "id": pool[0], "price": Config.PRICE_SPELL, "needs": ""},
		{"kind": "spell", "id": pool[1], "price": Config.PRICE_SPELL, "needs": ""},
	]
	var d := _make("die", hero, rng, 0)
	d.price = Config.PRICE_DIE + (Config.PRICE_ELEMENT if d.id != "" else 0)
	out.append(d)
	out.append({"kind": "maxhp", "id": "", "price": Config.PRICE_HP + hp_bought * Config.PRICE_HP_STEP, "needs": ""})
	return out


static func school(hero: Fighter, rng: RandomNumberGenerator) -> Array:
	var pool := spell_pool(hero)
	Fighter._shuffle(pool, rng)
	var out := [
		{"kind": "spell", "id": pool[0], "price": 0, "needs": ""},
		{"kind": "spell", "id": pool[1], "price": 0, "needs": ""},
	]
	var evolvable := []
	for i in hero.inventory.items.size():
		if int(hero.inventory.items[i].level) < Config.MAX_LEVEL:
			evolvable.append(i)
	Fighter._shuffle(evolvable, rng)
	for i in evolvable.slice(0, 3):
		out.append({"kind": "evolve", "id": hero.inventory.items[i].id, "item": i, "price": 0, "needs": ""})
	return out


static func well(rng: RandomNumberGenerator) -> Array:
	var els := Elements.SHOP.duplicate()
	Fighter._shuffle(els, rng)
	return [
		{"kind": "sticker", "id": "", "price": Config.PRICE_STICKER, "needs": "face"},
		{"kind": "element", "id": els[0], "price": Config.PRICE_ELEMENT, "needs": "die"},
		{"kind": "element", "id": els[1], "price": Config.PRICE_ELEMENT, "needs": "die"},
		{"kind": "destroy", "id": "", "price": Config.PRICE_DESTROY, "needs": "die"},
	]


static func rest_stops(rng: RandomNumberGenerator) -> Array:
	var s := STOPS.duplicate()
	Fighter._shuffle(s, rng)
	var out := []
	for id in s.slice(0, 3):
		out.append({"kind": "stop", "id": id, "price": 0, "needs": ""})
	return out


static func _make(kind: String, hero: Fighter, rng: RandomNumberGenerator, price: int) -> Dictionary:
	match kind:
		"spell":
			return {"kind": "spell", "id": _pick(spell_pool(hero), rng), "price": price, "needs": ""}
		"die":
			var el: String = "" if rng.randf() < 0.5 else _pick(Elements.SHOP, rng)
			return {"kind": "die", "id": el, "price": price, "needs": ""}
		"sticker":
			return {"kind": "sticker", "id": "", "price": price, "needs": "face"}
	return {"kind": "maxhp", "id": "", "price": price, "needs": ""}


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
		"sticker":
			if not target.has("face"):
				return "ui.pick_face"
			if hero.bag[int(target.die)].locked[int(target.face)]:
				return "ui.locked_face"
		"element", "destroy":
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
