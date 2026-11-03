class_name Resolver
extends RefCounted
## Regras de um turno sequencial (docs/SPEC_v3.md §6). Cada função anexa eventos
## {t, side, ...} à lista recebida; a interface só anima o que aconteceu.


static func side(f: Fighter) -> String:
	return "player" if f.is_player else "enemy"


## 1. Início: as proteções deste lado somem; veneno e queima causam dano.
static func start_turn(f: Fighter, ev: Array) -> void:
	f.block = 0
	f.mirror = false
	f.dodge = false
	if f.poison > 0:
		f.hp -= f.poison
		ev.append({"t": "poison", "side": side(f), "n": f.poison})
	if f.burn > 0:
		f.hp -= f.burn
		ev.append({"t": "burn", "side": side(f), "n": f.burn})
		f.burn -= 1


## 2. Mão: tira e rola; regras de Mestre e variantes que mexem na mão ou na bolsa.
static func draw_and_roll(f: Fighter, foe: Fighter, rng: RandomNumberGenerator, ev: Array) -> void:
	f.draw_hand(rng)
	if f.is_player and foe.master_id == "porteiro":
		f.add_temp(Elements.lead())
		ev.append({"t": "lead_hand", "side": side(f)})
	f.roll_hand(rng, foe.last_hand)
	ev.append({"t": "hand", "side": side(f), "values": f.hand_values()})


## Efeitos de quem age no próprio turno que mexem na bolsa do outro (Lixeiro).
static func on_turn_effects(f: Fighter, foe: Fighter, ev: Array) -> void:
	if f.variant == "lixeiro" and f.turns_taken == 0:
		foe.bag.append(Elements.lead())
		foe.discard.append(foe.bag.size() - 1)
		ev.append({"t": "lead_bag", "side": side(foe)})


## 4. Resolução: magias prontas, na ordem do inventário. Para se alguém morrer.
static func cast_all(f: Fighter, foe: Fighter, choice: TurnChoice, ev: Array) -> Array:
	var used := []
	for item in choice.ready_items(f):
		if f.hp <= 0 or foe.hp <= 0:
			break
		var dice: Array = choice.dice_in(item)
		used.append_array(dice)
		cast(f, foe, item, dice, ev)
	return used


static func cast(f: Fighter, foe: Fighter, item: int, dice: Array, ev: Array) -> void:
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
	match str(def.fx):
		"dmg":
			var n := Config.scale((total + int(def.get("plus", 0))) * int(def.get("mult", 1)), lvl) + f.sacrifice_bonus
			hit(foe, f, n, ev)
			if def.get("odd_twice", false) and values.all(func(v): return v % 2 == 1) and foe.hp > 0 and f.hp > 0:
				hit(foe, f, n, ev)
			if def.has("burn") and foe.hp > 0:
				_burn(foe, int(def.burn), ev)
		"meteor":
			hit(foe, f, Config.scale(int(def.base), lvl) + f.sacrifice_bonus, ev)
		"block":
			var b := Config.scale(total * int(def.get("mult", 1)), lvl)
			f.block += b
			ev.append({"t": "block", "side": side(f), "n": b, "total": f.block})
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
	# Sódio: queima o inimigo ao ser usado.
	for h in dice:
		var e: Dictionary = f.hand[h]
		if int(e.bag) != -2 and f.die_of(e) and f.die_of(e).element == "Na" and foe.hp > 0:
			_burn(foe, Config.SODIUM_BURN, ev)


static func _burn(f: Fighter, n: int, ev: Array) -> void:
	f.burn += n
	ev.append({"t": "burn_up", "side": side(f), "n": n, "total": f.burn})


## Um golpe: Esquiva anula; Espelho devolve (reflexo nunca volta); bloqueio absorve.
static func hit(target: Fighter, attacker: Fighter, n: int, ev: Array, reflected := false) -> void:
	if target.dodge:
		target.dodge = false
		ev.append({"t": "dodged", "side": side(target), "n": n})
		return
	if target.mirror and not reflected:
		target.mirror = false
		ev.append({"t": "mirrored", "side": side(target), "n": n})
		hit(attacker, target, n, ev, true)
		return
	var absorbed := mini(target.block, n)
	target.block -= absorbed
	var dmg := n - absorbed
	target.hp -= dmg
	ev.append({"t": "hit", "side": side(target), "n": n, "absorbed": absorbed, "dmg": dmg, "reflected": reflected})


## 5. Fim: Urânio parado envenena; a mão vai para o descarte.
static func end_turn(f: Fighter, used: Array, ev: Array) -> void:
	for h in f.hand.size():
		var e: Dictionary = f.hand[h]
		if h in used or int(e.bag) == -2:
			continue
		if f.die_of(e).element == "U":
			f.poison += Config.URANIUM_POISON
			ev.append({"t": "poison_up", "side": side(f), "n": Config.URANIUM_POISON, "total": f.poison})
	f.discard_hand()
	f.turns_taken += 1
