class_name EnemyAI
extends RefCounted
## Escolha de magias (gulosa) para inimigos e para o bot do simulador.
## Percorre as magias numa ordem de prioridade e dá a cada uma os melhores dados livres.
## As magias que devolvem dados vêm primeiro, para os dados devolvidos servirem às outras.

const PERSONALITIES := ["bruto", "cauteloso", "caotico"]
const SPAWN := ["forca", "imitacao"]
const OFFENSE := ["foto", "matematica", "obra", "sombras", "meteoro", "bola", "expectativa", "anatomia",
	"fisica", "velocidade", "bis", "banquete", "machadada", "peso", "plagio", "arrancar", "impulso", "corte",
	"sacrificio", "mordida", "dardo", "estocada", "faisca"]
const DEBUFF := ["interrupcao", "chave", "meia_verdade", "roubar_cena"]
const DEFENSE := ["esquiva_mais", "esquiva", "recuo", "espelho", "imune", "revide", "armadura", "escudo", "presenca",
	"rasteira", "concentrar", "pose", "suor", "cerrar", "remendo", "transfusao", "improviso"]


static func choose(f: Fighter, foe: Fighter, rng: RandomNumberGenerator) -> TurnChoice:
	var items := range(f.inventory.items.size())
	var prio := {}
	for i in items:
		prio[i] = _priority(f, foe, f.inventory.items[i].id)
	if f.personality == "caotico":
		Fighter._shuffle(items, rng)
		# Mesmo no caos, quem devolve dados vai antes.
		items.sort_custom(func(a, b): return int(f.inventory.items[a].id in SPAWN) > int(f.inventory.items[b].id in SPAWN))
	else:
		items.sort_custom(func(a, b): return prio[a] > prio[b] or (prio[a] == prio[b] and a < b))
	var c := TurnChoice.new()
	for item in items:
		if prio[item] <= 0 or not TurnChoice.can_cast(f, item):
			continue
		var pick := best_dice(f, f.inventory.items[item].id, c.used_dice())
		if pick.is_empty():
			continue
		var ok := true
		for h in pick:
			if not c.place(f, item, h):
				ok = false
				break
		if not ok:
			for h in c.dice_in(item).duplicate():
				c.remove_die(h, f)
	if f.archetype == "perfectionist":
		c.keep = keep_pick(f, c.used_dice())
	return c


## Perfeccionista: guarda as 2 sobras de valor mais repetido (em empate, o maior).
static func keep_pick(f: Fighter, used: Array) -> Array:
	var free := []
	for h in f.hand.size():
		if not (h in used) and int(f.hand[h].bag) != -2:
			free.append(h)
	var count := {}
	for h in free:
		var v := int(f.hand[h].value)
		count[v] = count.get(v, 0) + 1
	free.sort_custom(func(a, b):
		var va := int(f.hand[a].value)
		var vb := int(f.hand[b].value)
		return count[va] > count[vb] or (count[va] == count[vb] and va > vb))
	return free.slice(0, Characters.KEEP_MAX)


static func _priority(f: Fighter, foe: Fighter, id: String) -> int:
	var low := f.hp * 2 < f.max_hp
	var base := 0
	if id in SPAWN:
		base = 200 - SPAWN.find(id) * 5
	elif id in OFFENSE:
		base = 100 - OFFENSE.find(id) * 2
	elif id in DEBUFF:
		base = 70 - DEBUFF.find(id) * 2
	elif id in DEFENSE:
		base = 50 - DEFENSE.find(id) * 2
	match id:
		"remendo", "cerrar":
			# A Sede do Vampiro aproveita a cura com a vida cheia.
			if f.hp >= f.max_hp and f.archetype != "vampire":
				return 0
			# A Fúria do Bárbaro prefere ficar com pouca vida, até ficar perigoso.
			if f.archetype == "barbarian" and f.hp * 4 > f.max_hp:
				return 0
			base += 60 if low else 0
		"suor":
			if f.poison + f.burn <= 0 and f.hand_mods.is_empty():
				return 0
			base += 60
		"imune":
			if f.immune > 0:
				return 0
		"escudo", "esquiva", "esquiva_mais", "espelho", "recuo", "revide", "armadura", "presenca", "rasteira", "concentrar", "pose":
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
		if not (h in taken) and int(f.hand[h].bag) != -2:
			free.append(h)
	# Do maior para o menor.
	free.sort_custom(func(a, b):
		var va := int(f.hand[a].value)
		var vb := int(f.hand[b].value)
		return va > vb or (va == vb and a < b))
	var d := Spells.get_def(id)
	var n := Spells.dice_needed(id)
	match str(d.req):
		"any":
			return free.slice(0, n) if free.size() >= n else []
		"trio":
			for i in free.size():
				var same := [free[i]]
				for j in range(i + 1, free.size()):
					if f.hand[free[j]].value == f.hand[free[i]].value:
						same.append(free[j])
				if same.size() >= 3:
					return same.slice(0, 3)
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
		"low_one":
			var lo := -1
			for h in free:
				if int(f.hand[h].value) <= int(d.v):
					lo = h
					break
			if lo < 0:
				return []
			var out := []
			for h in free:
				if h != lo and out.size() < n - 1:
					out.append(h)
			if out.size() < n - 1:
				return []
			out.append(lo)
			return out
		_:
			# Exigência por dado (max, min, exact, odd, even, top, max_n, min_n).
			var out := []
			for h in free:
				var e: Dictionary = f.hand[h]
				if Spells.accepts_partial(id, [], int(e.value), bool(e.get("top", false))):
					out.append(h)
					if out.size() == n:
						return out
	return []


static func _find(f: Fighter, free: Array, v: int) -> int:
	for h in free:
		if int(f.hand[h].value) == v:
			return h
	return -1
