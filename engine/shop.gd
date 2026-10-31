class_name Shop
extends RefCounted
## Loja: 1 oferta por visita (docs/SPEC.md 9).


static func generate(run: RunState) -> Dictionary:
	var r := run.rng.randf()
	if r < Config.RARITY_COMMON:
		return common_offer(run)
	if r < Config.RARITY_COMMON + Config.RARITY_RARE or run.death_defy:
		var p := passive_offer(run)
		return p if not p.is_empty() else common_offer(run)
	return {"type": "death_defy", "id": "DEATH_DEFY", "price": Config.PRICE_DEATH_DEFY}


static func common_offer(run: RunState) -> Dictionary:
	match run.rng.randi_range(0, 2):
		0:
			return {"type": "hp", "id": "HP", "price": Config.PRICE_HP + run.hp_bought * Config.PRICE_HP_STEP}
		1:
			var pool := Items.ATTACK.filter(func(x): return x != run.attack_id)
			return {"type": "attack", "id": pool[run.rng.randi_range(0, pool.size() - 1)], "price": Config.PRICE_EQUIP}
		_:
			var pool := Items.DEFENSE.filter(func(x): return x != run.defense_id)
			return {"type": "defense", "id": pool[run.rng.randi_range(0, pool.size() - 1)], "price": Config.PRICE_EQUIP}


static func passive_offer(run: RunState) -> Dictionary:
	var pool := Items.PASSIVES.filter(func(x): return not (x in run.passives))
	if pool.is_empty():
		return {}
	return {"type": "passive", "id": pool[run.rng.randi_range(0, pool.size() - 1)], "price": Config.PRICE_PASSIVE}


static func sell_price() -> int:
	return Config.ceil_div(Config.PRICE_PASSIVE, 2)


## Retorna "" se comprou, ou a chave de texto do erro.
static func buy(run: RunState) -> String:
	var o := run.offer
	if o.is_empty():
		return "ui.bought"
	if run.coins < int(o.price):
		return "ui.not_enough"
	if o.type == "passive" and run.passives.size() >= Config.PASSIVE_LIMIT:
		return "ui.passive_full"
	run.coins -= int(o.price)
	match o.type:
		"hp":
			run.hp_bought += 1
		"attack":
			run.attack_id = o.id
		"defense":
			run.defense_id = o.id
		"passive":
			run.passives.append(o.id)
		"death_defy":
			run.death_defy = true
	run.offer = {}
	return ""


static func reroll(run: RunState) -> bool:
	if run.rerolls <= 0:
		return false
	run.rerolls -= 1
	run.offer = generate(run)
	return true


static func sell(run: RunState, passive_id: String) -> bool:
	if not (passive_id in run.passives):
		return false
	run.passives.erase(passive_id)
	run.coins += sell_price()
	if passive_id == "DF1":
		run.chinelo_bonus = 0
	return true
