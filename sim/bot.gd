class_name SimBot
extends RefCounted
## Bot "new" do simulador (docs/SPEC_v3.1.md §5.1): heurística de valor nas portas,
## recompensas, paradas, Loja, Escola e Poço. Na luta, usa a IA cautelosa (EnemyAI).
## O bot "old" (o de antes) continua em sim/simulate.gd.

## Usos de cada magia (id) nesta jornada, para a Escola evoluir a mais usada.
var uses := {}


static func hp_frac(h: Fighter) -> float:
	return float(h.hp) / maxi(1, h.max_hp)


static func is_mod_spell(id: String) -> bool:
	return str(Spells.get_def(id).get("fx", "")) == "mod"


static func is_defense(id: String) -> bool:
	return Spells.color_family(id) in ["block", "dodge", "mirror"]


## Pontuação de uma oferta (sem preço). < 0 = não serve.
func score(o: Dictionary, h: Fighter) -> float:
	match str(o.kind):
		"spell":
			var id := str(o.id)
			if id == "" or not h.inventory.fits(id):
				return -1.0
			var s := 8.0
			match Spells.rarity(id):
				"uncommon":
					s += 4.0
				"rare":
					s += 8.0
			var ids := h.inventory.ids()
			if is_mod_spell(id) and not ids.any(func(x): return is_mod_spell(str(x))):
				s += 6.0
			elif is_defense(id) and not ids.any(func(x): return is_defense(str(x))):
				s += 6.0
			return s
		"sticker":
			return 10.0 if sticker_target(h).has("face") else -1.0
		"die":
			return 4.0 - 2.0 * maxi(0, h.bag.size() - 10)
		"maxhp":
			return 6.0 + (6.0 if hp_frac(h) < 0.5 else 0.0)
		"element":
			return 5.0 if plain_die(h) >= 0 else -1.0
		"evolve":
			return 6.0 + float(uses.get(str(o.id), 0))
	return -1.0


## Alvo do adesivo: a face mais alta (não travada) do Ósmio ou do dado de maior soma.
static func sticker_target(h: Fighter) -> Dictionary:
	var best := -1
	for i in h.bag.size():
		var d: Die = h.bag[i]
		if _free_face(d) < 0:
			continue
		if best < 0:
			best = i
			continue
		var b: Die = h.bag[best]
		var d_os := d.element == "Os"
		var b_os := b.element == "Os"
		if (d_os and not b_os) or (d_os == b_os and d.face_sum() > b.face_sum()):
			best = i
	if best < 0:
		return {}
	return {"die": best, "face": _free_face(h.bag[best])}


static func _free_face(d: Die) -> int:
	var f := -1
	for k in 6:
		if d.locked[k]:
			continue
		if f < 0 or d.value(k) > d.value(f):
			f = k
	return f


static func plain_die(h: Fighter) -> int:
	for i in h.bag.size():
		if h.bag[i].element == "":
			return i
	return -1


## Pior dado comum (menor soma), para destruir.
static func worst_plain(h: Fighter) -> int:
	var w := -1
	for i in h.bag.size():
		var d: Die = h.bag[i]
		if d.element != "" and d.element != "Pb":
			continue
		if w < 0 or d.face_sum() < h.bag[w].face_sum():
			w = i
	return w


func target_for(o: Dictionary, h: Fighter) -> Dictionary:
	match str(o.needs):
		"face":
			return sticker_target(h)
		"die":
			if str(o.kind) == "destroy":
				return {"die": worst_plain(h)}
			return {"die": plain_die(h)}
	return {}


func pick_door(run: RunState) -> int:
	var hp := hp_frac(run.hero)
	var want := "facil"
	if hp >= 0.9:
		want = "insana"
	elif hp >= 0.7:
		want = "dificil"
	elif hp >= 0.4:
		want = "normal"
	var order := ["facil", "normal", "dificil", "insana"]
	var w := order.find(want)
	var best := 0
	var best_rank := -1
	for j in run.options.size():
		var r := order.find(str(run.options[j].id))
		if r < 0:
			return j ## Mestre.
		if r <= w and r > best_rank:
			best_rank = r
			best = j
	return best


func pick_stop(run: RunState) -> int:
	var h := run.hero
	var ids := run.options.map(func(o): return str(o.id))
	var want := []
	if hp_frac(h) < 0.5:
		want.append("heal")
	if h.inventory.items.any(func(it): return int(it.level) < Config.MAX_LEVEL):
		want.append("school")
	if run.coins >= 12:
		want.append("shop")
	want.append_array(["well", "shop", "school", "heal"])
	for w in want:
		var j := ids.find(w)
		if j >= 0:
			return j
	return 0


## Recompensa, Loja, Escola, Poço, Erudito e Mestre. Compra enquanto valer; depois sai.
func shop_phase(run: RunState) -> void:
	var phase := run.phase
	if phase == "master_reward":
		for j in run.options.size():
			if str(run.options[j].kind) == "hand":
				run.choose(j)
				return
	if phase == "well":
		_well(run)
		return
	for _k in 6:
		var best := -1
		var best_s := 4.99
		for j in run.options.size():
			var o: Dictionary = run.options[j]
			var s := score(o, run.hero)
			var tgt := target_for(o, run.hero)
			if s <= best_s or Shop.check(o, run.hero, tgt) != "":
				continue
			if Shop.price_of(o, run.hero, tgt, run.destroys_used) > run.coins:
				continue
			best_s = s
			best = j
		if best < 0:
			break
		var o: Dictionary = run.options[best]
		if run.choose(best, target_for(o, run.hero)) != "":
			break
		if run.phase != phase:
			return
	if run.phase == phase:
		run.leave()


func _well(run: RunState) -> void:
	var h := run.hero
	for j in run.options.size():
		var o: Dictionary = run.options[j]
		if str(o.kind) == "sticker":
			var t := sticker_target(h)
			if t.has("face") and Shop.price_of(o, h, t, run.destroys_used) <= run.coins and run.choose(j, t) == "":
				break
	if h.bag.size() > 8:
		for j in run.options.size():
			var o: Dictionary = run.options[j]
			if str(o.kind) == "destroy":
				var t := {"die": worst_plain(h)}
				if int(t.die) >= 0 and Shop.price_of(o, h, t, run.destroys_used) <= run.coins:
					run.choose(j, t)
				break
	if run.phase == "well":
		run.leave()


## Anota os usos das magias do jogador nos eventos de um turno.
func note_events(events: Array) -> void:
	for e in events:
		if str(e.get("side", "")) == "player" and str(e.get("t", "")) in ["cast", "mod"]:
			var id := str(e.get("spell", ""))
			uses[id] = uses.get(id, 0) + 1
