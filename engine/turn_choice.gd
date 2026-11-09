class_name TurnChoice
extends RefCounted
## Alocação de um turno: quais dados da mão (índices) vão em qual magia
## (índice no inventário). A magia resolve na ordem do inventário.
##
## Dados devolvidos (Força Desnecessária, Imitação Barata): quando a magia recebe o
## dado, dois dados novos entram no fim da mão, já valendo, e podem ir para outras
## magias neste turno. Tirar o dado da magia recolhe os devolvidos (e solta o que
## dependia deles).
##
## Mexidas (docs/SPEC_v3.1.md §1): quando o buraco fica completo, a mexida resolve na
## hora: muda o valor dos dados (na própria mão) e os devolve livres. A magia sai de
## "casts" e vai para "mods". As determinísticas se desfazem (undo_mod); as aleatórias
## são definitivas. Cada dado da mão mexido guarda "mod" (a última mexida), "mod_hist"
## (cada mexida e o valor de antes, em ordem), "orig" e "cause". Um dado pode receber
## várias mexidas no mesmo turno (cada mexida, uma vez por turno); desfazer uma mexida
## desfaz antes as que vieram depois nos mesmos dados.

var casts: Dictionary = {} ## item -> Array de índices da mão
var spawned: Dictionary = {} ## item -> índices da mão dos dados devolvidos
var keep: Array = [] ## Perfeccionista: sobras a guardar para a próxima mão (até 2).
## Mexidas resolvidas neste turno: item -> {dice, prev, spawn, random, polish}.
var mods: Dictionary = {}
var slots: Dictionary = {} ## item -> buraco escolhido (Ajuste Fino: 0 = +1, 1 = −1).
var rng: RandomNumberGenerator ## Sorteio das mexidas aleatórias (o do duelo).
var expect := false ## IA: mexidas aleatórias valem o valor esperado, sem rolar.
var forced_face := -1 ## IA: a rolagem das mexidas aleatórias sai nesta face (0 a 5).
var seq := 0 ## Ordem das mexidas (mod_hist guarda; o save no meio do turno remonta nela).


## Cópia independente (a IA testa mexidas sem mexer na escolha de verdade).
func clone() -> TurnChoice:
	var t := TurnChoice.new()
	t.casts = casts.duplicate(true)
	t.spawned = spawned.duplicate(true)
	t.mods = mods.duplicate(true)
	t.slots = slots.duplicate()
	t.keep = keep.duplicate()
	t.rng = rng
	t.expect = expect
	t.forced_face = forced_face
	t.seq = seq
	return t


static func make(c: Dictionary = {}) -> TurnChoice:
	var t := TurnChoice.new()
	for k in c:
		t.casts[int(k)] = Die._ints(c[k])
	return t


## Remonta as mexidas a partir da mão (save no meio do turno): os dados guardam o
## histórico ("mod_hist") e as partes guardam a mexida que as criou ("spawn").
static func from_hand(f: Fighter) -> TurnChoice:
	var t := TurnChoice.new()
	var recs := []
	for h in f.hand.size():
		var e: Dictionary = f.hand[h]
		for r in e.get("mod_hist", []):
			recs.append({"h": h, "r": r})
	recs.sort_custom(func(a, b): return int(a.r.seq) < int(b.r.seq))
	for x in recs:
		var it := int(x.r.item)
		if it < 0 or it >= f.inventory.items.size():
			continue
		if not t.mods.has(it):
			t.mods[it] = _empty_mod(f, it)
		t.mods[it].dice.append(int(x.h))
		t.mods[it].prev.append({"h": int(x.h), "value": int(x.r.value), "top": bool(x.r.top),
			"face": int(x.r.face), "spent": false})
		t.seq = maxi(t.seq, int(x.r.seq) + 1)
	for h in f.hand.size():
		var e: Dictionary = f.hand[h]
		var sp := int(e.get("spent", -1))
		if sp >= 0 and sp < f.inventory.items.size():
			if not t.mods.has(sp):
				t.mods[sp] = _empty_mod(f, sp)
			t.mods[sp].dice.append(h)
			t.mods[sp].prev.append({"h": h, "value": int(e.value), "top": bool(e.get("top", false)), "face": int(e.face), "spent": true})
		var src := int(e.get("spawn", -1))
		if src >= 0 and t.mods.has(src):
			t.mods[src].spawn.append(h)
	return t


static func _empty_mod(f: Fighter, it: int) -> Dictionary:
	return {"dice": [], "prev": [], "spawn": [], "random": Spells.is_random_mod(str(f.inventory.items[it].id)), "polish": {}}


func used_dice() -> Array:
	var out := []
	for k in casts:
		out.append_array(casts[k])
	out.append_array(spent_dice())
	return out


## Dados gastos por mexidas (o original da Sangria, o segundo do Juntar Cacos).
func spent_dice() -> Array:
	var out := []
	for k in mods:
		for p in mods[k].prev:
			if bool(p.spent):
				out.append(int(p.h))
	return out


func dice_in(item: int) -> Array:
	return casts.get(item, [])


func values_in(f: Fighter, item: int) -> Array:
	var out := []
	for h in dice_in(item):
		out.append(int(f.hand[h].value))
	return out


func tops_in(f: Fighter, item: int) -> Array:
	var out := []
	for h in dice_in(item):
		out.append(bool(f.hand[h].get("top", false)))
	return out


## A magia ainda pode receber dados neste turno (uso por luta e mexida já feita).
func available(f: Fighter, item: int) -> bool:
	return not mods.has(item) and can_cast(f, item)


## Regras do dado h para a magia, fora a exigência de valor (docs/SPEC_v3.1.md §1.2 e §6).
static func die_allowed(f: Fighter, item: int, h: int, slot := 0) -> bool:
	if h < 0 or h >= f.hand.size():
		return false
	var id: String = f.inventory.items[item].id
	var e: Dictionary = f.hand[h]
	if int(e.bag) == -2 or int(e.get("spent", -1)) >= 0:
		return false
	if not Spells.is_mod(id):
		return true
	# Dados devolvidos (partes da Sangria, cópias) e dados já mexidos aceitam outras
	# mexidas. Só o dado marcado da mão anterior (fixo, sem ser devolvido) não rola de novo.
	if Spells.is_random_mod(id) and bool(e.get("fixed", false)) and int(e.get("spawn", -1)) < 0:
		return false
	match str(Spells.get_def(id).get("mod", "")):
		"nudge":
			if slot == 1 and int(e.value) <= 1:
				return false
		"polish":
			var d := f.die_of(e)
			if int(e.bag) < 0 or bool(e.get("fixed", false)) or d == null or d.locked[int(e.face)]:
				return false
	return true


## O dado h pode entrar na magia agora (regras + exigência de valor)?
func accepts(f: Fighter, item: int, h: int, slot := 0) -> bool:
	if h < 0 or h >= f.hand.size() or h in used_dice() or not available(f, item):
		return false
	if not die_allowed(f, item, h, slot):
		return false
	var e: Dictionary = f.hand[h]
	return Spells.accepts_partial(f.inventory.items[item].id, values_in(f, item), int(e.value), bool(e.get("top", false)))


## Tenta pôr o dado h na magia; retorna false se a exigência não aceitar.
## slot: buraco escolhido (Ajuste Fino: 0 = +1, 1 = −1).
func place(f: Fighter, item: int, h: int, slot := 0) -> bool:
	if not accepts(f, item, h, slot):
		return false
	if not casts.has(item):
		casts[item] = []
	casts[item].append(h)
	if Spells.is_mod(f.inventory.items[item].id):
		slots[item] = slot
		_resolve_mod(f, item)
	else:
		_spawn(f, item)
	return true


## Magias que devolvem dados: assim que ficam completas, dois dados entram na mão.
func _spawn(f: Fighter, item: int) -> void:
	var id: String = f.inventory.items[item].id
	var fx := str(Spells.get_def(id).get("fx", ""))
	if not (fx in ["spawn_half", "spawn_copy"]) or spawned.has(item):
		return
	if not Spells.complete(id, values_in(f, item), tops_in(f, item)):
		return
	var src: Dictionary = f.hand[dice_in(item)[0]]
	var v := int(src.value)
	var sd := f.die_of(src)
	var out := []
	for _k in 2:
		# Os devolvidos guardam o dado de origem (elemento, faces, adesivos) e a cadeia
		# do Carbono da rolagem.
		var e := {"bag": -1, "temp": sd.copy() if sd else Die.basic(), "face": int(src.face), "value": v,
			"top": false, "fixed": true, "plus": 0, "spawn": item}
		if src.has("chain"):
			e["chain"] = int(src.chain)
		if fx == "spawn_half":
			e.value = Config.ceil_div(v, 2)
		else:
			# Imitação evoluída: as cópias valem mais (×1,5 no nível 2, ×2 no 3).
			e.value = Config.scale(v, int(f.inventory.items[item].level))
		out.append(f.hand.size())
		f.hand.append(e)
	spawned[item] = out


# ------------------------------------------------------------------ Mexidas
## Resolve a mexida quando o buraco fica completo (docs/SPEC_v3.1.md §1.4).
func _resolve_mod(f: Fighter, item: int) -> void:
	var it: Dictionary = f.inventory.items[item]
	var id: String = it.id
	if not Spells.complete(id, values_in(f, item), tops_in(f, item)):
		return
	var def := Spells.get_def(id)
	var lvl := int(it.level)
	var b := lvl - 1 ## Nível: +1 / +2 em cada dado devolvido.
	var dice: Array = casts[item].duplicate()
	var m := {"dice": dice, "prev": [], "spawn": [], "random": bool(def.get("random", false)), "polish": {}, "seq": seq}
	seq += 1
	for h in dice:
		var e: Dictionary = f.hand[h]
		var p := {"h": h, "value": int(e.value), "top": bool(e.get("top", false)), "face": int(e.face), "spent": false}
		for k in ["orig", "orig_top", "cause"]:
			if e.has(k):
				p["was_" + k] = e[k]
		m.prev.append(p)
	var vals := []
	for h in dice:
		vals.append(int(f.hand[h].value))
	match str(def.mod):
		"reroll_max":
			var e: Dictionary = f.hand[dice[0]]
			var r := _reroll(f, e)
			if expect:
				e.value = int(r.ev_max)
			elif int(r.value) > int(e.value):
				e.face = int(r.face)
				e.value = int(r.value)
				e.top = bool(r.top)
			_bump(f, e, b)
		"gamble":
			var e: Dictionary = f.hand[dice[0]]
			var r := _reroll(f, e)
			e.face = int(r.face)
			e.value = int(r.value) * (lvl + 1)
			_set_top(f, e)
		"nudge":
			var step := 1 + b ## Nível: o passo cresce (±1 / ±2 / ±3).
			var e: Dictionary = f.hand[dice[0]]
			_set_val(f, e, maxi(1, int(e.value) + (step if int(slots.get(item, 0)) == 0 else -step)))
		"top":
			var e: Dictionary = f.hand[dice[0]]
			var d := f.die_of(e)
			_set_val(f, e, (d.max_value() if d else int(e.value)) + b)
			e.top = true
		"split3":
			var v := int(vals[0])
			@warning_ignore("integer_division")
			var q := v / 3
			var rest := v % 3
			m.prev[0].spent = true
			# As partes guardam o dado de origem (elemento, faces e adesivos): Sódio queima
			# por parte, Carbono conta na cadeia, rolar de novo usa as faces dele. Como as
			# partes não rolam (fixed), o Mercúrio não copia de novo.
			var se: Dictionary = f.hand[dice[0]]
			var src := f.die_of(se)
			for k in 3:
				var part := {"bag": -1, "temp": src.copy() if src else Die.basic(), "face": int(se.face), "value": q + (1 if k < rest else 0) + b,
					"top": false, "fixed": true, "plus": 0, "spawn": item, "orig": v, "cause": id}
				if se.has("chain"):
					part["chain"] = int(se.chain)
				m.spawn.append(f.hand.size())
				f.hand.append(part)
		"flip":
			_set_val(f, f.hand[dice[0]], 7 - int(vals[0]) + b)
		"avg":
			var a := Config.ceil_div(int(vals[0]) + int(vals[1]), 2)
			for h in dice:
				_set_val(f, f.hand[h], a + b)
		"polar":
			_set_val(f, f.hand[dice[0]], (1 if int(vals[0]) <= 3 else 6) + b)
		"echo":
			_set_val(f, f.hand[dice[0]], int(vals[0]) + b)
			_set_val(f, f.hand[dice[1]], int(vals[0]) + b)
		"double":
			_set_val(f, f.hand[dice[0]], int(vals[0]) * 2 + b)
		"fuse":
			_set_val(f, f.hand[dice[0]], int(vals[0]) + int(vals[1]) + b)
			m.prev[1].spent = true
		"stairs":
			var lo := int(vals.min())
			for k in dice.size():
				_set_val(f, f.hand[dice[k]], lo + k + b)
		"polish":
			var e: Dictionary = f.hand[dice[0]]
			var nv := 5 + lvl ## A face vira 6 / 7 / 8.
			m.polish = {"bag": int(e.bag), "face": int(e.face), "value": nv}
			_set_val(f, e, nv)
	for p in m.prev:
		var e: Dictionary = f.hand[int(p.h)]
		if bool(p.spent):
			e["spent"] = item
			continue
		e["mod"] = item
		var hist: Array = e.get("mod_hist", []).duplicate(true)
		hist.append({"item": item, "seq": int(m.seq), "value": int(p.value), "top": bool(p.top), "face": int(p.face)})
		e["mod_hist"] = hist
		if not e.has("orig") or str(e.get("cause", "")) == "":
			e["orig"] = int(p.value)
		e["orig_top"] = bool(p.top)
		e["cause"] = id
	casts.erase(item)
	mods[item] = m


## Rolagem nova do dado da entrada (mesmas regras da mão: +plus, Hidrogênio, Carbono).
## A cadeia do Carbono é a da rolagem da mão ("chain"), sem recontar; o Mercúrio fica
## com a face, sem copiar. Com expect (IA), devolve o valor esperado.
func _reroll(f: Fighter, e: Dictionary) -> Dictionary:
	var d := f.die_of(e)
	if d == null:
		return {"face": int(e.face), "value": int(e.value), "top": bool(e.top)}
	var chain := int(e.get("chain", 0)) if d.element == "C" else 0
	var mult := Elements.solitary_mult if Elements.solitary(f, d) else 1
	if forced_face >= 0:
		var fr := d.value(forced_face)
		return {"face": forced_face, "value": (fr + int(e.get("plus", 0))) * mult + chain, "top": fr == d.max_value()}
	if expect:
		# A IA estima: Segunda Chance vale a média do maior; Tudo ou Nada, a média da face.
		var best := 0.0
		var sum := 0.0
		for k in 6:
			var v := (d.value(k) + int(e.get("plus", 0))) * mult + chain
			sum += v
			best += maxf(v, float(e.value))
		return {"face": int(e.face), "value": int(round(sum / 6.0)), "top": false, "ev_max": int(round(best / 6.0))}
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var face := rng.randi_range(0, 5)
	var raw := d.value(face)
	return {"face": face, "value": (raw + int(e.get("plus", 0))) * mult + chain, "top": raw == d.max_value()}


func _set_val(f: Fighter, e: Dictionary, v: int) -> void:
	e.value = maxi(1, v)
	_set_top(f, e)


func _set_top(f: Fighter, e: Dictionary) -> void:
	var d := f.die_of(e)
	e.top = d != null and int(e.value) == d.max_value()


func _bump(f: Fighter, e: Dictionary, b: int) -> void:
	if b > 0:
		_set_val(f, e, int(e.value) + b)


## Desfaz uma mexida determinística (e o que dependia dos dados dela). false se não dá.
func undo_mod(f: Fighter, item: int) -> bool:
	if not mods.has(item) or bool(mods[item].random):
		return false
	for it in _later_mods(item):
		if bool(mods[it].random):
			return false ## Uma aleatória veio depois nos mesmos dados: fica.
	_restore_mod(f, item)
	return true


## Mexidas feitas depois de item nos dados dela (ou nas partes que ela criou), em
## qualquer profundidade, da mais nova para a mais antiga.
func _later_mods(item: int) -> Array:
	var out := []
	var touched := {}
	for p in mods[item].prev:
		touched[int(p.h)] = true
	for h in mods[item].spawn:
		touched[int(h)] = true
	var s0 := int(mods[item].get("seq", 0))
	var later := mods.keys().filter(func(k): return int(mods[k].get("seq", 0)) > s0)
	later.sort_custom(func(a, b): return int(mods[a].get("seq", 0)) < int(mods[b].get("seq", 0)))
	for k in later:
		var m: Dictionary = mods[k]
		if m.prev.any(func(p): return touched.has(int(p.h))):
			out.push_front(k)
			for h in m.spawn:
				touched[int(h)] = true
	return out


func _restore_mod(f: Fighter, item: int) -> void:
	if not mods.has(item):
		return
	for it in _later_mods(item):
		_restore_mod(f, it)
	var m: Dictionary = mods[item]
	mods.erase(item)
	slots.erase(item)
	# Os dados mexidos saem das magias onde estavam.
	for p in m.prev:
		_unplace(f, int(p.h))
	if not m.spawn.is_empty():
		for h in m.spawn:
			_unplace(f, int(h))
	for p in m.prev:
		var h := int(p.h)
		if h >= f.hand.size():
			continue
		var e: Dictionary = f.hand[h]
		e.value = int(p.value)
		e.top = bool(p.top)
		e.face = int(p.face)
		e.erase("spent")
		var hist: Array = e.get("mod_hist", []).filter(func(r): return int(r.item) != item)
		if hist.is_empty():
			e.erase("mod")
			e.erase("mod_hist")
		else:
			e["mod_hist"] = hist
			e["mod"] = int(hist.back().item)
		for k in ["orig", "orig_top", "cause"]:
			e.erase(k)
			if p.has("was_" + k):
				e[k] = p["was_" + k]
	if not m.spawn.is_empty():
		_truncate(f, int(m.spawn.min()))


## Tira o dado h de qualquer magia (sem desfazer mexidas), recolhendo devolvidos.
func _unplace(f: Fighter, h: int) -> void:
	var src_item := -1
	for k in casts.keys():
		if h in casts[k]:
			src_item = k
			casts[k].erase(h)
			if casts[k].is_empty():
				casts.erase(k)
	if src_item >= 0 and spawned.has(src_item):
		_truncate(f, int(spawned[src_item].min()))


## Devolve o dado h para a mão. Se ele estava numa magia que devolveu dados, esses
## dados saem da mão (e de onde tinham sido postos). Sem f, só tira o dado.
func remove_die(h: int, f: Fighter = null) -> void:
	var src_item := -1
	for k in casts.keys():
		if h in casts[k]:
			src_item = k
		casts[k].erase(h)
		if casts[k].is_empty():
			casts.erase(k)
	if f != null and src_item >= 0 and spawned.has(src_item):
		var outs: Array = spawned[src_item]
		_truncate(f, int(outs.min()))


## Corta a mão no índice first (os dados devolvidos ficam sempre no fim).
func _truncate(f: Fighter, first: int) -> void:
	# Mexidas que criaram dados cortados (Sangria) ou que mexeram neles voltam atrás.
	for it in mods.keys():
		if not mods.has(it):
			continue
		var m: Dictionary = mods[it]
		if m.spawn.any(func(x): return int(x) >= first) or m.prev.any(func(p): return int(p.h) >= first):
			_restore_mod(f, it)
	if first < f.hand.size():
		f.hand.resize(first)
	for it in spawned.keys():
		var outs: Array = spawned[it]
		if outs.any(func(x): return int(x) >= first):
			spawned.erase(it)
			casts.erase(it)
	for k in casts.keys():
		casts[k] = casts[k].filter(func(x): return int(x) < first)
		if casts[k].is_empty():
			casts.erase(k)


static func can_cast(f: Fighter, item: int) -> bool:
	var id: String = f.inventory.items[item].id
	var lim := Spells.max_uses(id)
	return lim == 0 or f.uses_of(item) < lim


## Magias com exigência completa (as incompletas não são lançadas).
func ready_items(f: Fighter) -> Array:
	var out := []
	for item in f.inventory.order():
		if casts.has(item) and Spells.complete(f.inventory.items[item].id, values_in(f, item), tops_in(f, item)):
			out.append(item)
	return out


## Mexidas resolvidas, na ordem do inventário.
func mod_items(f: Fighter) -> Array:
	var out := []
	for item in f.inventory.order():
		if mods.has(item):
			out.append(item)
	return out


## Magias com dado posto mas exigência incompleta (só as de mais de um dado:
## as de um dado só aceitam o dado se ele já completa). Vazias não contam.
## O jogador não pode terminar o turno com alguma assim.
func incomplete_items(f: Fighter) -> Array:
	var out := []
	for item in f.inventory.order():
		if casts.has(item) and not casts[item].is_empty() and Spells.dice_needed(f.inventory.items[item].id) > 1 \
				and not Spells.complete(f.inventory.items[item].id, values_in(f, item), tops_in(f, item)):
			out.append(item)
	return out


## "" se válida, ou a descrição do problema.
func validate(f: Fighter) -> String:
	var seen := {}
	for h in spent_dice():
		seen[h] = true
	for item in casts:
		if item < 0 or item >= f.inventory.items.size():
			return "magia inválida"
		if not can_cast(f, item) or mods.has(item):
			return "magia já usada nesta luta"
		for h in casts[item]:
			if h < 0 or h >= f.hand.size() or seen.has(h):
				return "dado inválido"
			seen[h] = true
	for item in mods:
		if item < 0 or item >= f.inventory.items.size() or not can_cast(f, item):
			return "magia já usada nesta luta"
	if keep.size() > Characters.KEEP_MAX:
		return "dados guardados demais"
	for h in keep:
		if f.archetype != "perfectionist" or h < 0 or h >= f.hand.size() or seen.has(h):
			return "dado guardado inválido"
	return ""


func to_dict() -> Dictionary:
	var d := {}
	for k in casts:
		d[str(k)] = casts[k]
	if not keep.is_empty():
		d["keep"] = keep
	return d


static func from_dict(d: Dictionary) -> TurnChoice:
	var c := d.duplicate()
	c.erase("keep")
	var t := TurnChoice.make(c)
	t.keep = Die._ints(d.get("keep", []))
	return t
