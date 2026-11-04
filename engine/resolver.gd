class_name Resolver
extends RefCounted
## Regras de um turno sequencial (docs/SPEC_v3.md §6, docs/CATALOGO_MAGIAS.md). Cada
## função anexa eventos {t, side, ...} à lista recebida; a interface só anima o que
## aconteceu.


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
		ev.append({"t": "poison", "side": side(f), "n": f.poison})
	if f.burn > 0:
		f.hp -= f.burn
		ev.append({"t": "burn", "side": side(f), "n": f.burn})
		f.burn -= 1


## Efeito negativo vindo do adversário: Imune a Críticas anula o próximo.
## Retorna true se o efeito acontece.
static func negative(target: Fighter, ev: Array) -> bool:
	if target.immune > 0:
		target.immune -= 1
		ev.append({"t": "immune_block", "side": side(target)})
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
	f.draw_hand(rng, minus)
	if minus > 0:
		ev.append({"t": "hand_mod", "side": side(f), "mod": "minus%d" % minus})
	if f.is_player and foe.master_id == "porteiro" and negative(f, ev):
		f.add_temp(Elements.lead())
		ev.append({"t": "lead_hand", "side": side(f)})
	f.roll_hand(rng, foe.last_hand)
	apply_hand_mods(f, foe, ev)
	var els := []
	for e in f.hand:
		els.append(f.die_of(e).element)
	ev.append({"t": "hand", "side": side(f), "values": f.hand_values(), "elements": els})


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
					ev.append({"t": "stolen", "side": side(f), "v": int(e.value)})
				continue
		ev.append({"t": "hand_mod", "side": side(f), "mod": m})


## Efeitos de quem age no próprio turno que mexem na bolsa do outro (Lixeiro).
static func on_turn_effects(f: Fighter, foe: Fighter, ev: Array) -> void:
	if f.variant == "lixeiro" and f.turns_taken == 0 and negative(foe, ev):
		foe.bag.append(Elements.lead())
		foe.discard.append(foe.bag.size() - 1)
		ev.append({"t": "lead_bag", "side": side(foe)})


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
		cast(f, foe, item, dice, ev, rng)
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
	ev.append({"t": "cast", "side": side(f), "spell": id, "item": item, "dice": dice.duplicate(), "values": values})
	var bonus := f.sacrifice_bonus
	var mult := int(def.get("mult", 1))
	match str(def.fx):
		"dmg":
			var n := Config.scale((total + int(def.get("plus", 0))) * mult, lvl) + bonus
			var pierce := bool(def.get("pierce", false))
			hit(foe, f, n, ev, false, pierce)
			if def.get("odd_twice", false) and values.all(func(v): return v % 2 == 1) and foe.hp > 0 and f.hp > 0:
				hit(foe, f, n, ev)
			if def.has("burn") and foe.hp > 0:
				_burn(foe, int(def.burn), ev)
		"product":
			hit(foe, f, Config.scale(_product(values) * mult, lvl) + bonus, ev)
		"lever":
			hit(foe, f, Config.scale(int(values.max()) * int(values.min()), lvl) + bonus, ev)
		"multi":
			var blows := values.duplicate()
			if values.size() > 1 and values.all(func(v): return v == values[0]):
				blows.append_array(values)
			for v in blows:
				if foe.hp <= 0 or f.hp <= 0:
					break
				hit(foe, f, Config.scale(int(v) * mult, lvl) + bonus, ev)
		"ones":
			var ones := 0
			for e in f.hand:
				if int(e.bag) != -2 and int(e.value) == 1:
					ones += 1
			hit(foe, f, Config.scale(int(def.get("per", 1)) * ones, lvl) + bonus, ev)
		"top_x":
			hit(foe, f, Config.scale(int(values.max()) * mult, lvl) + bonus, ev)
		"encore":
			var d := f.die_of(f.hand[dice[0]])
			var top := d.max_value()
			var sum := total
			for _k in Spells.ENCORE_MAX:
				var v := d.value(rng.randi_range(0, 5))
				sum += v
				ev.append({"t": "encore", "side": side(f), "v": v, "again": v == top})
				if v != top:
					break
			hit(foe, f, Config.scale(sum, lvl) + bonus, ev)
		"steal_sticker":
			var v := _steal_sticker(f, foe, dice[0], ev)
			hit(foe, f, Config.scale(v, lvl) + bonus, ev)
		"bench":
			hit(foe, f, Config.scale(total, lvl) + bonus, ev)
			_bench_strongest(foe, ev)
		"spawn_half":
			hit(foe, f, Config.scale(total, lvl) + bonus, ev)
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
			ev.append({"t": "riposte_up", "side": side(f), "n": f.riposte})
		"immune":
			_block(f, Config.scale(total * mult, lvl), ev)
			f.immune = maxi(f.immune, 1)
			ev.append({"t": "immune_up", "side": side(f)})
		"cleanse":
			f.poison = 0
			f.burn = 0
			f.hand_mods = []
			ev.append({"t": "cleanse", "side": side(f)})
			_block(f, Config.scale(total, lvl), ev)
		"recycle":
			f.recycle = true
			ev.append({"t": "recycle_up", "side": side(f)})
		"debuff":
			pass
		"dodge":
			f.dodge = true
			ev.append({"t": "dodge_up", "side": side(f)})
		"mirror":
			f.mirror = true
			ev.append({"t": "mirror_up", "side": side(f)})
		"heal":
			var got := f.heal(Config.scale(total, lvl))
			ev.append({"t": "heal", "side": side(f), "n": got})
		"maxhp":
			var n := Config.scale(int(values[0]), lvl)
			f.max_hp += n
			f.hp += n
			ev.append({"t": "maxhp", "side": side(f), "n": n})
		"sacrifice":
			f.sacrifice_bonus += Config.scale(Config.SACRIFICE_BONUS, lvl)
			var h: int = dice[0]
			var b_idx := int(f.hand[h].bag)
			if b_idx >= 0:
				f.destroy_bag_die(b_idx)
			else:
				f.hand[h].temp = null
				f.hand[h].bag = -2
			ev.append({"t": "sacrifice", "side": side(f), "bonus": f.sacrifice_bonus})
	# Mexida na próxima mão do inimigo.
	if def.has("hand_mod") and foe.hp > 0 and negative(foe, ev):
		foe.hand_mods.append(str(def.hand_mod))
		ev.append({"t": "hand_mod_up", "side": side(foe), "mod": str(def.hand_mod)})
	# Marca para a sua próxima mão.
	if def.has("mark"):
		_mark(f, dice, str(def.mark), total, ev)
	# Sódio: queima o inimigo ao ser usado.
	for h in dice:
		var e: Dictionary = f.hand[h]
		if int(e.bag) != -2 and f.die_of(e) and f.die_of(e).element == "Na" and foe.hp > 0:
			_burn(foe, Config.SODIUM_BURN, ev)


static func _block(f: Fighter, b: int, ev: Array) -> void:
	f.block += b
	ev.append({"t": "block", "side": side(f), "n": b, "total": f.block})


static func _burn(f: Fighter, n: int, ev: Array) -> void:
	if not negative(f, ev):
		return
	f.burn += n
	ev.append({"t": "burn_up", "side": side(f), "n": n, "total": f.burn})


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
	ev.append({"t": "steal_sticker", "side": side(f), "v": v})
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
	ev.append({"t": "bench", "side": side(foe), "sum": foe.bag[best].face_sum()})


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
	ev.append({"t": "mark", "side": side(f), "kind": kind, "v": int(m.value)})


## Um golpe: Esquiva anula; Espelho devolve (reflexo nunca volta); bloqueio absorve;
## Revide devolve dano enquanto houver bloqueio. pierce: ignora todas as defesas.
static func hit(target: Fighter, attacker: Fighter, n: int, ev: Array, reflected := false, pierce := false) -> void:
	if not pierce:
		if target.dodge:
			target.dodge = false
			ev.append({"t": "dodged", "side": side(target), "n": n})
			return
		if target.mirror and not reflected:
			target.mirror = false
			ev.append({"t": "mirrored", "side": side(target), "n": n})
			hit(attacker, target, n, ev, true)
			return
	var had_block := target.block > 0
	var absorbed := 0 if pierce else mini(target.block, n)
	target.block -= absorbed
	var dmg := n - absorbed
	target.hp -= dmg
	ev.append({"t": "hit", "side": side(target), "n": n, "absorbed": absorbed, "dmg": dmg, "reflected": reflected, "pierce": pierce})
	if not pierce and not reflected and had_block and target.riposte > 0 and target.hp > 0 and attacker.hp > 0:
		ev.append({"t": "riposte", "side": side(target), "n": target.riposte})
		hit(attacker, target, target.riposte, ev, true)


## 5. Fim: dados parados (Expectativa Tóxica, Improviso Brilhante, Urânio); a mão vai
## para o descarte.
static func end_turn(f: Fighter, used: Array, ev: Array) -> void:
	var idle := "idle_dmg" in f.turn_mods
	for h in f.hand.size():
		var e: Dictionary = f.hand[h]
		if h in used or int(e.bag) == -2:
			continue
		if idle:
			f.hp -= Spells.IDLE_DMG
			ev.append({"t": "idle_dmg", "side": side(f), "n": Spells.IDLE_DMG})
		if f.recycle:
			f.block += int(e.value)
			ev.append({"t": "block", "side": side(f), "n": int(e.value), "total": f.block, "recycled": true})
			continue
		if f.die_of(e).element == "U":
			f.poison += Config.URANIUM_POISON
			ev.append({"t": "poison_up", "side": side(f), "n": Config.URANIUM_POISON, "total": f.poison})
	f.turn_mods = []
	f.discard_hand()
	f.turns_taken += 1
