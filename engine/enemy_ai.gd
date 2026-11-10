class_name EnemyAI
extends RefCounted
## Escolha de magias (gulosa) para inimigos e para o bot do simulador.
## Percorre as magias numa ordem de prioridade e dá a cada uma os melhores dados livres.
## As magias que devolvem dados vêm primeiro, para os dados devolvidos servirem às outras.

const PERSONALITIES := ["bruto", "cauteloso", "caotico"]
const SPAWN := ["forca", "imitacao"]
const OFFENSE := ["foto", "matematica", "bigorna", "obra", "sombras", "meteoro", "bola", "expectativa", "anatomia",
	"fisica", "velocidade", "bis", "banquete", "machadada", "peso", "plagio", "arrancar", "impulso", "corte",
	"sacrificio", "mordida", "dardo", "estocada", "faisca"]
const DEBUFF := ["interrupcao", "chave", "meia_verdade", "roubar_cena"]
const DEFENSE := ["esquiva_mais", "esquiva", "recuo", "espelho", "imune", "revide", "armadura", "escudo", "presenca",
	"pele", "rasteira", "muralha", "concentrar", "pose", "suor", "cerrar", "remendo", "transfusao", "improviso"]


static func choose(f: Fighter, foe: Fighter, rng: RandomNumberGenerator) -> TurnChoice:
	var c := TurnChoice.new()
	c.rng = rng
	apply_mods(f, foe, c, rng)
	allocate(f, foe, c, rng)
	if f.archetype == "perfectionist":
		c.keep = keep_pick(f, c.used_dice())
	return c


## Alocação gulosa (sem mexidas): cada magia, na ordem de prioridade, pega os melhores
## dados livres que ela aceita.
static func allocate(f: Fighter, foe: Fighter, c: TurnChoice, rng: RandomNumberGenerator) -> void:
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
	for item in items:
		if prio[item] <= 0 or not c.available(f, item):
			continue
		var pick := best_dice(f, f.inventory.items[item].id, c.used_dice(), item)
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


# ------------------------------------------------------------------ Mexidas
## Mexidas antes da alocação (docs/SPEC_v3.1.md §1.7): busca gulosa. Para cada mexida e
## cada dado (par, trio) que ela aceita, simula a mexida (aleatórias pelo valor esperado),
## aloca o resto e pontua. Fica com a melhor se ela superar não mexer; repete. O Caótico
## usa cada mexida nos dados mais baixos que ela aceite.
static func apply_mods(f: Fighter, foe: Fighter, c: TurnChoice, rng: RandomNumberGenerator) -> void:
	if f.personality == "caotico":
		for item in _mod_items(f, c):
			var free := _free_sorted(f, c, item, true)
			var n := Spells.dice_needed(f.inventory.items[item].id)
			if free.size() >= n:
				_try_place(f, c, item, free.slice(0, n), 0)
		return
	for _round in 3:
		var base := _plan_score(f, foe, c, rng)
		var best: Dictionary = {}
		var best_s := base + 0.5
		for item in _mod_items(f, c):
			# Mexida aleatória: média das 6 faces que podem sair.
			var faces := range(6) if Spells.is_random_mod(f.inventory.items[item].id) else [-1]
			for cand in _candidates(f, c, item):
				var total := 0.0
				var ok := true
				for face in faces:
					var snap: Array = f.hand.duplicate(true)
					var cc := c.clone()
					cc.forced_face = face
					if _try_place(f, cc, item, cand.dice, int(cand.slot)) and cc.mods.has(item):
						total += _plan_score(f, foe, cc, rng)
					else:
						ok = false
					f.hand = snap
				var sc := total / faces.size()
				if ok and sc > best_s:
					best_s = sc
					best = {"item": item, "dice": cand.dice, "slot": cand.slot}
		if best.is_empty():
			return
		if not _try_place(f, c, int(best.item), best.dice, int(best.slot)):
			return


static func _mod_items(f: Fighter, c: TurnChoice) -> Array:
	var out := []
	for item in f.inventory.order():
		if Spells.is_mod(f.inventory.items[item].id) and c.available(f, item):
			out.append(item)
	return out


## Dados livres que a magia aceitaria (regras e valor de cada um sozinho), do menor para o maior.
static func _free_sorted(f: Fighter, c: TurnChoice, item: int, ascending: bool, slot := 0) -> Array:
	var used := c.used_dice()
	var out := []
	for h in f.hand.size():
		if h in used or not TurnChoice.die_allowed(f, item, h, slot):
			continue
		if not Spells.accepts_partial(f.inventory.items[item].id, [], int(f.hand[h].value), bool(f.hand[h].get("top", false))):
			continue
		out.append(h)
	out.sort_custom(func(a, b):
		var va := int(f.hand[a].value)
		var vb := int(f.hand[b].value)
		return (va < vb if ascending else va > vb) or (va == vb and a < b))
	return out


## Combinações de dados para a mexida: um dado (e cada buraco do Ajuste Fino), pares
## ordenados (Eco, Juntar: a ordem importa) ou não (Nivelar) e trios (Escada).
static func _candidates(f: Fighter, c: TurnChoice, item: int) -> Array:
	var id: String = f.inventory.items[item].id
	var n := Spells.dice_needed(id)
	var out := []
	var slots := [0, 1] if str(Spells.get_def(id).get("mod", "")) == "nudge" else [0]
	for slot in slots:
		var free := _free_sorted(f, c, item, true, slot)
		match n:
			1:
				for h in free:
					out.append({"dice": [h], "slot": slot})
			2:
				var ordered := str(Spells.get_def(id).get("mod", "")) in ["echo", "fuse"]
				for i in free.size():
					for j in free.size():
						if i == j or (not ordered and j < i):
							continue
						out.append({"dice": [free[i], free[j]], "slot": slot})
			3:
				for i in free.size():
					for j in range(i + 1, free.size()):
						for k in range(j + 1, free.size()):
							out.append({"dice": [free[i], free[j], free[k]], "slot": slot})
	return out


static func _try_place(f: Fighter, c: TurnChoice, item: int, dice: Array, slot: int) -> bool:
	for h in dice:
		if not c.place(f, item, int(h), slot):
			for x in c.dice_in(item).duplicate():
				c.remove_die(x, f)
			return false
	return true


## Pontua a alocação que a IA faria agora: dano + bloqueio × 0,7 + cura × 0,5.
static func _plan_score(f: Fighter, foe: Fighter, c: TurnChoice, rng: RandomNumberGenerator) -> float:
	var snap: Array = f.hand.duplicate(true)
	var cc := c.clone()
	cc.expect = true
	allocate(f, foe, cc, rng)
	var sc := 0.0
	for item in cc.ready_items(f):
		sc += estimate(f, item, cc.values_in(f, item))
	f.hand = snap
	return sc


## Valor aproximado de lançar a magia com estes valores (para a busca das mexidas).
static func estimate(f: Fighter, item: int, values: Array) -> float:
	var it: Dictionary = f.inventory.items[item]
	var def := Spells.get_def(str(it.id))
	var lm: float = Config.LEVEL_MULT[clampi(int(it.level), 1, Config.MAX_LEVEL) - 1]
	var total := 0.0
	for v in values:
		total += float(v)
	var mult := float(def.get("mult", 1))
	var hurt := f.hp < f.max_hp
	var lo := float(values.min()) if not values.is_empty() else 0.0
	var hi := float(values.max()) if not values.is_empty() else 0.0
	var s := 0.0
	match str(def.get("fx", "")):
		"dmg":
			s = (total + float(def.get("plus", 0))) * mult
			if def.get("odd_twice", false) and values.all(func(v): return int(v) % 2 == 1):
				s *= 2.0
			s += float(def.get("burn", 0)) * 1.5
		"product":
			s = 1.0
			for v in values:
				s *= float(v)
			s *= mult
		"lever":
			s = hi * lo
		"multi":
			s = total * mult * (2.0 if values.size() > 1 and values.all(func(v): return v == values[0]) else 1.0)
		"ones":
			var ones := 0
			for e in f.hand:
				if int(e.bag) != -2 and int(e.value) == 1:
					ones += 1
			s = float(def.get("per", 1)) * ones
		"top_x":
			s = hi * mult
		"encore":
			s = total * 1.3
		"steal_sticker", "bench", "spawn_half":
			s = total
		"drain":
			s = total + (total * 0.25 if hurt else 0.0)
		"feast":
			s = total + (lo * 0.5 if hurt else 0.0)
		"block", "riposte", "immune":
			s = total * mult * 0.7
		"block_product":
			s = (1.0 if values.is_empty() else lo * hi) * mult * 0.7
		"block_hand":
			s = float(def.get("per", 1)) * f.hand.size() * 0.7
		"skin":
			# Vale mais cedo na luta e enquanto não chegou ao teto.
			s = 0.0 if f.skin >= Config.SKIN_CAP else 6.0 - f.skin
		"block_count":
			s = float(def.get("per", 1)) * Resolver.count_value(f, int(def.get("count", 1))) * 0.7
		"heal":
			s = total * mult * 0.5 if hurt else 0.0
		"maxhp":
			s = lo * 0.8
		"dodge", "mirror":
			s = 5.0
		"debuff", "sacrifice", "recycle", "cleanse", "spawn_copy":
			s = 4.0
	if def.has("mark"):
		s += 2.0
	return s * lm


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
static func best_dice(f: Fighter, id: String, taken: Array, item := -1) -> Array:
	var free := []
	for h in f.hand.size():
		if not (h in taken) and int(f.hand[h].bag) != -2 and int(f.hand[h].get("spent", -1)) < 0 \
				and (item < 0 or TurnChoice.die_allowed(f, item, h)):
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
