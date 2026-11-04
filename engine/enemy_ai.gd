class_name EnemyAI
extends RefCounted
## Escolha de magias (gulosa) para inimigos e para o bot do simulador.
## Percorre as magias numa ordem de prioridade e dá a cada uma os melhores dados livres.

const PERSONALITIES := ["bruto", "cauteloso", "caotico"]
const OFFENSE := ["meteoro", "bola", "corte", "sacrificio", "faisca", "estocada"]
const DEFENSE := ["esquiva", "espelho", "escudo", "remendo", "transfusao"]


static func choose(f: Fighter, foe: Fighter, rng: RandomNumberGenerator) -> TurnChoice:
	var items := range(f.inventory.items.size())
	var prio := {}
	for i in items:
		prio[i] = _priority(f, foe, f.inventory.items[i].id)
	if f.personality == "caotico":
		Fighter._shuffle(items, rng)
	else:
		items.sort_custom(func(a, b): return prio[a] > prio[b] or (prio[a] == prio[b] and a < b))
	var c := TurnChoice.new()
	for item in items:
		if prio[item] <= 0 or not TurnChoice.can_cast(f, item):
			continue
		var pick := best_dice(f, f.inventory.items[item].id, c.used_dice())
		if not pick.is_empty():
			c.casts[item] = pick
	return c


static func _priority(f: Fighter, foe: Fighter, id: String) -> int:
	var low := f.hp * 2 < f.max_hp
	var base := 0
	if id in OFFENSE:
		base = 100 - OFFENSE.find(id) * 10
	elif id in DEFENSE:
		base = 50 - DEFENSE.find(id) * 5
	match id:
		"remendo":
			if f.hp >= f.max_hp:
				return 0
			base += 60 if low else 0
		"escudo", "esquiva", "espelho":
			if f.personality == "bruto":
				return 0
			if low or f.personality == "cauteloso":
				base += 60
		"sacrificio":
			if foe.hp <= 10:
				return 0
	return base


## Melhores dados livres para a exigência, ou [] se não há.
static func best_dice(f: Fighter, id: String, taken: Array) -> Array:
	var free := []
	for h in f.hand.size():
		if not (h in taken):
			free.append(h)
	# Do maior para o menor; Urânio primeiro em empate (parado envenena).
	free.sort_custom(func(a, b):
		var va := int(f.hand[a].value)
		var vb := int(f.hand[b].value)
		return va > vb or (va == vb and a < b))
	var d := Spells.get_def(id)
	match str(d.req):
		"any":
			var n := int(d.get("n", 1))
			return free.slice(0, n) if free.size() >= n else []
		"max", "exact":
			for h in free:
				if Spells.accepts_partial(id, [], int(f.hand[h].value)):
					return [h]
		"pair":
			for i in free.size():
				for j in range(i + 1, free.size()):
					if f.hand[free[i]].value == f.hand[free[j]].value:
						return [free[i], free[j]]
		"seq3":
			for i in free.size():
				var v := int(f.hand[free[i]].value)
				var a := _find(f, free, v - 1)
				var b := _find(f, free, v - 2)
				if a >= 0 and b >= 0:
					return [free[i], a, b]
	return []


static func _find(f: Fighter, free: Array, v: int) -> int:
	for h in free:
		if int(f.hand[h].value) == v:
			return h
	return -1
