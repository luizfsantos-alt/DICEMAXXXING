class_name Resolver
extends RefCounted
## Regras de um turno sequencial (docs/SPEC_v3.md §6, docs/CATALOGO_MAGIAS.md). Cada
## função anexa eventos {t, side, ...} à lista recebida; a interface só anima o que
## aconteceu.


## Lutadores cujos status vão anotados em cada evento (Duel liga durante a resolução).
static var watch: Array = []


## Anexa o evento "e" e, com "watch" ligado, o estado dos status dos dois lados naquele
## instante (e.st = {side: Fighter.status_state()}).
static func push(ev: Array, e: Dictionary) -> void:
	if not watch.is_empty():
		var st := {}
		for f in watch:
			st[side(f)] = f.status_state()
		e["st"] = st
	ev.append(e)


static func side(f: Fighter) -> String:
	return "player" if f.is_player else "enemy"


## 1. Início: as proteções deste lado somem; veneno e queima causam dano.
static func start_turn(f: Fighter, ev: Array) -> void:
	f.block = 0
	f.mirror = false
	f.dodge = false
	f.riposte = 0
	f.recycle = false
	if f.poison > 0:
		f.hp -= f.poison
		push(ev, {"t": "poison", "side": side(f), "n": f.poison})
	if f.burn > 0:
		# Vampiro: a queima causa o dobro.
		var n := f.burn * (2 if f.archetype == "vampire" else 1)
		f.hp -= n
		f.burn -= 1
		push(ev, {"t": "burn", "side": side(f), "n": n})


## Efeito negativo vindo do adversário: Imune a Críticas anula o próximo.
## Retorna true se o efeito acontece.
static func negative(target: Fighter, ev: Array) -> bool:
	if target.immune > 0:
		target.immune -= 1
		push(ev, {"t": "immune_block", "side": side(target)})
		return false
	return true


## 2. Mão: tira e rola; regras de Mestre e mexidas do adversário na mão.
static func draw_and_roll(f: Fighter, foe: Fighter, rng: RandomNumberGenerator, ev: Array) -> void:
	f.turn_mods = f.hand_mods
	f.hand_mods = []
	var minus := 0
	for m in f.turn_mods:
		if m == "minus2":
			minus += 2
		elif m == "minus1":
			minus += 1
	var bonus := f.dodge_bonus
	if not Characters.agile_stack:
		f.dodge_bonus = 0
	f.draw_hand(rng, minus, bonus)
	if minus > 0:
		push(ev, {"t": "hand_mod", "side": side(f), "mod": "minus%d" % minus})
	if bonus > 0:
		push(ev, {"t": "hand_mod", "side": side(f), "mod": "plus%d" % mini(bonus, 3)})
	if f.is_player and foe.master_id == "porteiro" and negative(f, ev):
		f.add_temp(Elements.lead())
		push(ev, {"t": "lead_hand", "side": side(f)})
	var pulled := f.roll_hand(rng, foe.last_hand)
	if pulled > 0:
		push(ev, {"t": "dead_weight", "side": side(f), "n": pulled})
	_announce_elements(f, ev)
	apply_hand_mods(f, foe, ev)
	var info := hand_dice(f)
	push(ev, {"t": "hand", "side": side(f), "values": f.hand_values(), "elements": info.elements,
		"faces": info.faces, "face": info.face, "fixed": info.fixed, "heat": info.heat})


## Dados da mão para a interface (rolagem 3D): elemento, as seis faces de cada dado, a
## face que saiu, se estava marcado (não rolou) e o estado do brilho (Elements.heat).
static func hand_dice(f: Fighter) -> Dictionary:
	var out := {"elements": [], "faces": [], "face": [], "fixed": [], "heat": []}
	for e in f.hand:
		var d := f.die_of(e)
		out.elements.append(d.element)
		out.heat.append(Elements.heat(f, d))
		var fs := []
		for k in 6:
			fs.append(d.value(k))
		out.faces.append(fs)
		out.face.append(int(e.face))
		out.fixed.append(bool(e.get("fixed", false)))
	return out


## Elementos que mudaram o valor ao rolar (Hidrogênio ×3, Carbono em cadeia, Mercúrio copiou).
static func _announce_elements(f: Fighter, ev: Array) -> void:
	var chain := Elements.chain_bonus(f)
	for e in f.hand:
		var d := f.die_of(e)
		if d == null or e.get("fixed", false):
			continue
		if Elements.solitary(f, d):
			push(ev, {"t": "element", "side": side(f), "el": "H", "v": int(e.value)})
		elif d.element == "C" and chain > 0:
			push(ev, {"t": "element", "side": side(f), "el": "C", "v": int(e.value)})
		elif d.element == "Hg" and int(e.value) > d.value(int(e.face)):
			push(ev, {"t": "element", "side": side(f), "el": "Hg", "v": int(e.value)})


## Mexidas na mão recém-rolada (ordem fixa, para ficar previsível).
static func apply_hand_mods(f: Fighter, foe: Fighter, ev: Array) -> void:
	for m in ["top_to_one", "even_to_one", "halve", "steal_top"]:
		if not (m in f.turn_mods):
			continue
		match m:
			"top_to_one":
				for e in f.hand:
					if e.get("top", false):
						e.value = 1
						e.top = false
			"even_to_one":
				for e in f.hand:
					if int(e.value) % 2 == 0:
						e.value = 1
						e.top = false
			"halve":
				for e in f.hand:
					e.value = maxi(1, int(floor(int(e.value) / 2.0)))
					e.top = false
			"steal_top":
				var best := -1
				for h in f.hand.size():
					var e: Dictionary = f.hand[h]
					if f.die_of(e).element == "Os":
						continue
					if best < 0 or int(e.value) > int(f.hand[best].value):
						best = h
				if best >= 0:
					var e: Dictionary = f.hand.pop_at(best)
					if int(e.bag) >= 0:
						f.discard.append(int(e.bag))
					foe.extra_next.append({"temp": f.die_of(e).to_dict(), "value": int(e.value)})
					push(ev, {"t": "stolen", "side": side(f), "v": int(e.value)})
				continue
		push(ev, {"t": "hand_mod", "side": side(f), "mod": m})


## Efeitos de quem age no próprio turno que mexem na bolsa do outro (Lixeiro, Fundidor).
static func on_turn_effects(f: Fighter, foe: Fighter, ev: Array) -> void:
	if f.variant == "lixeiro" and f.turns_taken == 0 and negative(foe, ev):
		foe.bag.append(Elements.lead())
		foe.discard.append(foe.bag.size() - 1)
		push(ev, {"t": "lead_bag", "side": side(foe)})
	if f.variant == "fundidor" and f.turns_taken == 0:
		# O dado comum mais forte do outro vira Chumbo até o fim da luta.
		var best := -1
		for i in foe.bag.size():
			if foe.bag[i].element == "" and (best < 0 or foe.bag[i].face_sum() > foe.bag[best].face_sum()):
				best = i
		if best >= 0 and negative(foe, ev):
			foe.restore.append({"bag": best, "die": foe.bag[best].to_dict()})
			Elements.apply(foe.bag[best], "Pb")
			push(ev, {"t": "lead_convert", "side": side(foe)})


## Copista (Inspiração): no início da luta, copia uma magia aleatória do outro que
## caiba nas casas livres, sem mexer nas peças. A cópia some no fim da luta.
static func inspire(f: Fighter, foe: Fighter, rng: RandomNumberGenerator, ev: Array) -> void:
	if f.archetype != "copyist":
		return
	var options := []
	for it in foe.inventory.items:
		if bool(it.get("temp", false)):
			continue
		var spot := f.inventory.find_spot(str(it.id))
		if not spot.is_empty():
			options.append({"id": str(it.id), "level": int(it.level), "spot": spot})
	if options.is_empty():
		push(ev, {"t": "copy", "side": side(f), "spell": ""})
		return
	var o: Dictionary = options[rng.randi_range(0, options.size() - 1)]
	f.inventory.items.append({"id": o.id, "level": o.level, "x": o.spot.x, "y": o.spot.y, "rot": o.spot.rot, "temp": true})
	push(ev, {"t": "copy", "side": side(f), "spell": o.id})


## Bônus de dano por golpe: Sacrifício + Fúria do Bárbaro.
static func dmg_bonus(f: Fighter) -> int:
	return f.sacrifice_bonus + Characters.fury(f)


## Cura com a Sede do Vampiro (+1 de vida máxima por cura).
static func _heal(f: Fighter, n: int, ev: Array) -> void:
	var r := f.heal_full(n)
	push(ev, {"t": "heal", "side": side(f), "n": int(r.hp)})
	if int(r.max) > 0:
		push(ev, {"t": "maxhp", "side": side(f), "n": int(r.max), "thirst": true})


## 4. Resolução: magias prontas, na ordem do inventário. Para se alguém morrer.
static func cast_all(f: Fighter, foe: Fighter, choice: TurnChoice, ev: Array, rng: RandomNumberGenerator = null) -> Array:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.seed = 1
	var used := []
	for item in choice.ready_items(f):
		if f.hp <= 0 or foe.hp <= 0:
			break
		var dice: Array = choice.dice_in(item)
		used.append_array(dice)
		var start := ev.size()
		cast(f, foe, item, dice, ev, rng)
		# Tudo o que a magia causou (depois do "cast") vem do mesmo item: a tela
		# encurta a pausa entre essas ações para mostrar que andam juntas.
		for k in range(start + 1, ev.size()):
			ev[k]["of_item"] = item
	return used


static func _product(values: Array) -> int:
	var p := 1
	for v in values:
		p *= int(v)
	return p


static func _hand_count(f: Fighter) -> int:
	var n := 0
	for e in f.hand:
		if int(e.bag) != -2:
			n += 1
	return n


static func cast(f: Fighter, foe: Fighter, item: int, dice: Array, ev: Array, rng: RandomNumberGenerator = null) -> void:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.seed = 1
	var it: Dictionary = f.inventory.items[item]
	var id: String = it.id
	var def := Spells.get_def(id)
	var lvl := int(it.level)
	var values := []
	var total := 0
	for h in dice:
		values.append(int(f.hand[h].value))
		total += int(f.hand[h].value)
	if Spells.is_once(id):
		f.once_used.append(item)
	push(ev, {"t": "cast", "side": side(f), "spell": id, "item": item, "dice": dice.duplicate(), "values": values})
	var mult := int(def.get("mult", 1))
	match str(def.fx):
		"dmg":
			var raw := Config.scale((total + int(def.get("plus", 0))) * mult, lvl)
			var pierce := bool(def.get("pierce", false))
			hit(foe, f, raw + dmg_bonus(f), ev, false, pierce)
			if def.get("odd_twice", false) and values.all(func(v): return v % 2 == 1) and foe.hp > 0 and f.hp > 0:
				hit(foe, f, raw + dmg_bonus(f), ev)
			if def.has("burn") and foe.hp > 0:
				_burn(foe, int(def.burn), ev)
		"product":
			hit(foe, f, Config.scale(_product(values) * mult, lvl) + dmg_bonus(f), ev)
		"lever":
			hit(foe, f, Config.scale(int(values.max()) * int(values.min()), lvl) + dmg_bonus(f), ev)
		"multi":
			var blows := values.duplicate()
			if values.size() > 1 and values.all(func(v): return v == values[0]):
				blows.append_array(values)
			for v in blows:
				if foe.hp <= 0 or f.hp <= 0:
					break
				hit(foe, f, Config.scale(int(v) * mult, lvl) + dmg_bonus(f), ev)
		"ones":
			var ones := 0
			for e in f.hand:
				if int(e.bag) != -2 and int(e.value) == 1:
					ones += 1
			hit(foe, f, Config.scale(int(def.get("per", 1)) * ones, lvl) + dmg_bonus(f), ev)
		"top_x":
			hit(foe, f, Config.scale(int(values.max()) * mult, lvl) + dmg_bonus(f), ev)
		"encore":
			var d := f.die_of(f.hand[dice[0]])
			var top := d.max_value()
			var sum := total
			for _k in Spells.ENCORE_MAX:
				var v := d.value(rng.randi_range(0, 5))
				sum += v
				push(ev, {"t": "encore", "side": side(f), "v": v, "again": v == top})
				if v != top:
					break
			hit(foe, f, Config.scale(sum, lvl) + dmg_bonus(f), ev)
		"steal_sticker":
			var v := _steal_sticker(f, foe, dice[0], ev)
			hit(foe, f, Config.scale(v, lvl) + dmg_bonus(f), ev)
		"bench":
			hit(foe, f, Config.scale(total, lvl) + dmg_bonus(f), ev)
			_bench_strongest(foe, ev)
		"spawn_half":
			hit(foe, f, Config.scale(total, lvl) + dmg_bonus(f), ev)
		"spawn_copy":
			pass
		"block":
			_block(f, Config.scale(total * mult, lvl), ev)
		"block_product":
			_block(f, Config.scale(_product(values) * mult, lvl), ev)
		"block_hand":
			_block(f, Config.scale(int(def.get("per", 1)) * _hand_count(f), lvl), ev)
		"riposte":
			_block(f, Config.scale(total * mult, lvl), ev)
			f.riposte = maxi(f.riposte, Config.scale(total, lvl))
			push(ev, {"t": "riposte_up", "side": side(f), "n": f.riposte})
		"immune":
			_block(f, Config.scale(total * mult, lvl), ev)
			f.immune = maxi(f.immune, 1)
			push(ev, {"t": "immune_up", "side": side(f)})
		"cleanse":
			f.poison = 0
			f.burn = 0
			f.hand_mods = []
			push(ev, {"t": "cleanse", "side": side(f)})
			_block(f, Config.scale(total, lvl), ev)
		"recycle":
			f.recycle = true
			push(ev, {"t": "recycle_up", "side": side(f)})
		"debuff":
			pass
		"dodge":
			f.dodge = true
			push(ev, {"t": "dodge_up", "side": side(f)})
		"mirror":
			f.mirror = true
			push(ev, {"t": "mirror_up", "side": side(f)})
		"heal":
			_heal(f, Config.scale(total * mult, lvl), ev)
		"drain":
			var raw := Config.scale(total, lvl)
			hit(foe, f, raw + dmg_bonus(f), ev)
			if f.hp > 0:
				_heal(f, Config.ceil_div(raw, 2), ev)
		"feast":
			hit(foe, f, Config.scale(total, lvl) + dmg_bonus(f), ev)
			if f.hp > 0:
				_heal(f, Config.scale(int(values.min()), lvl), ev)
		"maxhp":
			var n := Config.scale(int(values[0]), lvl)
			f.max_hp += n
			f.hp += n
			push(ev, {"t": "maxhp", "side": side(f), "n": n})
		"sacrifice":
			f.sacrifice_bonus += Config.scale(Config.SACRIFICE_BONUS, lvl)
			var h: int = dice[0]
			var b_idx := int(f.hand[h].bag)
			if b_idx >= 0:
				f.destroy_bag_die(b_idx)
			else:
				f.hand[h].temp = null
				f.hand[h].bag = -2
			push(ev, {"t": "sacrifice", "side": side(f), "bonus": f.sacrifice_bonus})
	# Mexida na próxima mão do inimigo.
	if def.has("hand_mod") and foe.hp > 0 and negative(foe, ev):
		foe.hand_mods.append(str(def.hand_mod))
		push(ev, {"t": "hand_mod_up", "side": side(foe), "mod": str(def.hand_mod)})
	# Marca para a sua próxima mão.
	if def.has("mark"):
		_mark(f, dice, str(def.mark), total, ev)
	# Sódio: queima o inimigo ao ser usado. Amianto: machuca quem usa (não é golpe).
	for h in dice:
		var e: Dictionary = f.hand[h]
		if int(e.bag) == -2 or f.die_of(e) == null:
			continue
		var el := f.die_of(e).element
		if el == "Na" and foe.hp > 0:
			_burn(foe, Config.SODIUM_BURN, ev, "Na")
		elif el == "Am" and f.hp > 0:
			f.hp -= Config.ASBESTOS_DMG
			push(ev, {"t": "asbestos", "side": side(f), "n": Config.ASBESTOS_DMG})


static func _block(f: Fighter, b: int, ev: Array) -> void:
	f.block += b
	push(ev, {"t": "block", "side": side(f), "n": b, "total": f.block})


static func _burn(f: Fighter, n: int, ev: Array, src := "") -> void:
	if not negative(f, ev):
		return
	f.burn += n
	push(ev, {"t": "burn_up", "side": side(f), "n": n, "total": f.burn, "src": src})


## Plágio: rouba 1 adesivo ×2 do dado mais adesivado do inimigo e cola na face usada,
## até o fim da luta. Retorna o valor do dado depois disso.
static func _steal_sticker(f: Fighter, foe: Fighter, h: int, ev: Array) -> int:
	var e: Dictionary = f.hand[h]
	var v := int(e.value)
	var mine := f.die_of(e)
	if mine == null or e.get("fixed", false) or mine.locked[int(e.face)]:
		return v
	var best := -1
	for i in foe.bag.size():
		if foe.bag[i].element == "Os":
			continue
		if foe.bag[i].sticker_count() > 0 and (best < 0 or foe.bag[i].sticker_count() > foe.bag[best].sticker_count()):
			best = i
	if best < 0 or not negative(foe, ev):
		return v
	var src: Die = foe.bag[best]
	var face := 0
	for k in 6:
		if int(src.stickers[k]) > int(src.stickers[face]) or (int(src.stickers[k]) == int(src.stickers[face]) and src.value(k) > src.value(face)):
			face = k
	src.stickers[face] = int(src.stickers[face]) - 1
	foe.fight_mods.append({"bag": best, "face": face, "d": -1})
	mine.stickers[int(e.face)] = int(mine.stickers[int(e.face)]) + 1
	if int(e.bag) >= 0:
		f.fight_mods.append({"bag": int(e.bag), "face": int(e.face), "d": 1})
	v *= 2
	e.value = v
	push(ev, {"t": "steal_sticker", "side": side(f), "v": v})
	return v


## Arrancar das Mãos: o dado de maior soma de faces da bolsa do inimigo fica fora
## da luta. Ósmio não sai.
static func _bench_strongest(foe: Fighter, ev: Array) -> void:
	if foe.hp <= 0:
		return
	var best := -1
	for i in foe.draw_pile + foe.discard:
		var b := int(i)
		if foe.bag[b].element == "Os":
			continue
		if best < 0 or foe.bag[b].face_sum() > foe.bag[best].face_sum():
			best = b
	if best < 0 or not negative(foe, ev):
		return
	foe.bench(best)
	push(ev, {"t": "bench", "side": side(foe), "sum": foe.bag[best].face_sum()})


## Marca o dado para a sua próxima mão (uma marca por vez: a nova substitui).
static func _mark(f: Fighter, dice: Array, kind: String, total: int, ev: Array) -> void:
	var e: Dictionary = f.hand[dice[0]]
	if int(e.bag) == -2:
		return
	var d := f.die_of(e)
	var m := {"bag": int(e.bag), "temp": {}, "value": int(e.value), "fixed": true, "plus": 0}
	if int(e.bag) < 0:
		m.temp = d.to_dict() if d else Die.basic().to_dict()
	match kind:
		"six":
			m.value = 6
		"sum":
			m.bag = -1
			m.temp = Die.basic().to_dict()
			m.value = total
		"plus2":
			m.fixed = false
			m.plus = 2
			m.value = 0
	f.marked = m
	push(ev, {"t": "mark", "side": side(f), "kind": kind, "v": int(m.value)})


## Um golpe: Esquiva anula; Espelho devolve (reflexo nunca volta); bloqueio absorve;
## Revide devolve dano enquanto houver bloqueio. pierce: ignora todas as defesas.
static func hit(target: Fighter, attacker: Fighter, n: int, ev: Array, reflected := false, pierce := false) -> void:
	if not pierce:
		if target.dodge:
			target.dodge = false
			push(ev, {"t": "dodged", "side": side(target), "n": n})
			if target.archetype == "assassin":
				target.dodge_bonus += Characters.AGILE_DICE
			return
		if target.mirror and not reflected:
			target.mirror = false
			push(ev, {"t": "mirrored", "side": side(target), "n": n})
			hit(attacker, target, n, ev, true)
			return
	var had_block := target.block > 0
	var absorbed := 0 if pierce else mini(target.block, n)
	target.block -= absorbed
	var dmg := n - absorbed
	target.hp -= dmg
	push(ev, {"t": "hit", "side": side(target), "n": n, "absorbed": absorbed, "dmg": dmg, "reflected": reflected, "pierce": pierce})
	if not pierce and not reflected and had_block and target.riposte > 0 and target.hp > 0 and attacker.hp > 0:
		push(ev, {"t": "riposte", "side": side(target), "n": target.riposte})
		hit(attacker, target, target.riposte, ev, true)


## 5. Fim: dados parados (Expectativa Tóxica, Improviso Brilhante, Urânio); o
## Perfeccionista guarda até 2 sobras (keep); a mão vai para o descarte.
static func end_turn(f: Fighter, used: Array, ev: Array, keep: Array = []) -> void:
	if f.archetype == "perfectionist":
		_keep(f, used, keep, ev)
	var idle := "idle_dmg" in f.turn_mods
	for h in f.hand.size():
		var e: Dictionary = f.hand[h]
		if h in used or int(e.bag) == -2:
			continue
		if idle:
			f.hp -= Spells.IDLE_DMG
			push(ev, {"t": "idle_dmg", "side": side(f), "n": Spells.IDLE_DMG})
		if f.recycle:
			f.block += int(e.value)
			push(ev, {"t": "block", "side": side(f), "n": int(e.value), "total": f.block, "recycled": true})
			continue
		if f.die_of(e).element == "U":
			f.poison += Config.URANIUM_POISON
			push(ev, {"t": "poison_up", "side": side(f), "n": Config.URANIUM_POISON, "total": f.poison})
	f.turn_mods = []
	f.discard_hand()
	f.turns_taken += 1


## Perfeccionista (Ainda Não Está Bom): as sobras escolhidas entram na próxima mão
## com o mesmo valor. No máximo 2 marcas ao mesmo tempo (contando a das magias).
static func _keep(f: Fighter, used: Array, keep: Array, ev: Array) -> void:
	var room := Characters.KEEP_MAX - (0 if f.marked.is_empty() else 1)
	var n := 0
	for h in keep:
		if n >= room or h < 0 or h >= f.hand.size() or h in used:
			continue
		var e: Dictionary = f.hand[h]
		if int(e.bag) == -2:
			continue
		var k := {"bag": int(e.bag), "temp": {}, "value": int(e.value)}
		if int(e.bag) < 0:
			var d := f.die_of(e)
			k.temp = d.to_dict() if d else Die.basic().to_dict()
		f.keeps.append(k)
		n += 1
	if n > 0:
		push(ev, {"t": "keep", "side": side(f), "n": n})
