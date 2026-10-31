class_name Resolver
extends RefCounted
## Motor de regras: implementa a ordem oficial de resolução (docs/SPEC.md, seção 3).
## Tudo é estático e determinístico dado o RNG, para testes e simulação.


# ---------------------------------------------------------------- A. Início
static func start_turn(f: Fighter, turn: int, lg: Array) -> void:
	f.round_shield = 0
	f.placa_shield = 0
	if f.has("DF5"):
		var h := f.heal(2)
		if h > 0:
			lg.append(Texts.t("log.bandeide", {"who": f.name, "n": h}))
	if f.boss_id == "C2":
		f.round_shield += 5
		lg.append(Texts.t("log.neide", {"who": f.name, "n": 5}))
	if turn == 1 and f.has("DF4"):
		var s := f.shield_value(3)
		f.round_shield += s
		lg.append(Texts.t("log.pochete", {"who": f.name, "n": s}))
	f.hp_at_start = f.hp
	f.full_at_start = f.hp >= f.max_hp


# ---------------------------------------------------------------- B. Rolagem
static func roll_die(f: Fighter, sides: int, rng: RandomNumberGenerator) -> int:
	var lo := 2 if (f.has("DD9") and sides >= 2) else 1
	return rng.randi_range(lo, sides)


static func roll(f: Fighter, rng: RandomNumberGenerator, turn: int, lg: Array) -> void:
	var values := []
	if f.boss_id == "C1":
		var seven := []
		for i in 7:
			seven.append(roll_die(f, 6, rng))
		var lo_i := argmin(seven)
		lg.append(Texts.t("log.seven_dice", {"who": f.name, "n": seven[lo_i]}))
		seven.remove_at(lo_i)
		values = seven
	else:
		for s in f.dice_sides:
			values.append(roll_die(f, s, rng))
	f.dice = values
	apply_dice_passives(f, rng, turn, lg)


## Passivos de dado: Pé de Coelho → Ioiô → Dado Viciado → Figurinha → checagens.
static func apply_dice_passives(f: Fighter, rng: RandomNumberGenerator, turn: int, lg: Array) -> void:
	if turn == 1 and f.has("DD3"):
		var n := 0
		for i in f.dice.size():
			if f.dice[i] == 1:
				f.dice[i] = roll_die(f, f.dice_sides[i], rng)
				n += 1
		if n > 0:
			lg.append(Texts.t("log.pe_coelho", {"who": f.name, "n": n}))
	if f.has("DD6") and f.ioio_carry >= 0:
		var i := argmin(f.dice)
		lg.append(Texts.t("log.ioio", {"who": f.name, "from": f.dice[i], "to": f.ioio_carry}))
		f.dice[i] = f.ioio_carry
	if f.has("DD1"):
		var i := argmin(f.dice)
		var to := maxi(1, int(f.dice_sides[i]) + 1 - int(f.dice[i]))
		lg.append(Texts.t("log.viciado", {"who": f.name, "from": f.dice[i], "to": to}))
		f.dice[i] = to
	if f.has("DD8"):
		var m := max_of(f.dice)
		var j := -1
		for i in f.dice.size():
			if f.dice[i] != m and (j == -1 or f.dice[i] > f.dice[j]):
				j = i
		if j != -1:
			lg.append(Texts.t("log.figurinha", {"who": f.name, "from": f.dice[j], "to": m}))
			f.dice[j] = m
	if f.has("DD6"):
		f.ioio_carry = max_of(f.dice)
	f.raspadinha = false
	if f.has("DD2"):
		var all_faces := true
		for v in range(1, 7):
			if not (v in f.dice):
				all_faces = false
				break
		f.raspadinha = all_faces
		if all_faces:
			lg.append(Texts.t("log.raspadinha", {"who": f.name}))
	if f.has("DD5"):
		var counts := {}
		for v in f.dice:
			counts[v] = counts.get(v, 0) + 1
		for v in counts:
			if counts[v] >= 3:
				f.coins_earned += 1
				lg.append(Texts.t("log.nota3", {"who": f.name}))
				break


# ---------------------------------------------------------------- C–N. Resolução
## Resolve um turno completo. `a` e `b` já passaram por start_turn e roll.
## Retorna {lg, dmg_to_a, dmg_to_b, self_a, self_b}.
static func resolve(a: Fighter, b: Fighter, ca: TurnChoice, cb: TurnChoice,
		rng: RandomNumberGenerator, turn: int, lg: Array = []) -> Dictionary:
	var pa := placement(a, ca)
	var pb := placement(b, cb)

	# D. Efeitos negativos (decididos sobre as colocações originais).
	var chain_on_b := applies_corrente(a, pa)
	var chain_on_a := applies_corrente(b, pb)
	if chain_on_b:
		corrente(b, pb, lg)
	if chain_on_a:
		corrente(a, pa, lg)

	# E. Travar condições.
	var sa := side_state(a, pa, lg)
	var sb := side_state(b, pb, lg)
	defense_shields(a, sa, lg)
	defense_shields(b, sb, lg)

	# F. Ataques.
	var atk_a := attack(a, sa, b, sb, rng, lg)
	var atk_b := attack(b, sb, a, sa, rng, lg)

	# G. Espelhos (o refletido volta para quem atacou).
	var refl_to_a := mirrors(a, sa, atk_a, b, sb, lg)
	var refl_to_b := mirrors(b, sb, atk_b, a, sa, lg)

	# H. Espinhos.
	var thorns_to_a := thorns(a, atk_a, b, sb, lg)
	var thorns_to_b := thorns(b, atk_b, a, sa, lg)

	# I. Reduções por quem recebe.
	var dmg_a := reduce(a, sa, atk_b.total + refl_to_a + thorns_to_a, lg)
	var dmg_b := reduce(b, sb, atk_a.total + refl_to_b + thorns_to_b, lg)

	# J. Dano direto simultâneo + curas do ataque.
	a.hp -= dmg_a
	b.hp -= dmg_b
	if dmg_a > 0:
		lg.append(Texts.t("log.takes", {"who": a.name, "n": dmg_a}))
	if dmg_b > 0:
		lg.append(Texts.t("log.takes", {"who": b.name, "n": dmg_b}))
	machado(a, sa, lg)
	machado(b, sb, lg)

	# K. Curas antes do autodano.
	fenix(a, sa, lg)
	fenix(b, sb, lg)

	# L. Autodano.
	var self_a := self_damage(a, sa, turn, lg)
	var self_b := self_damage(b, sb, turn, lg)
	a.hp -= self_a
	b.hp -= self_b

	# M. Fim do turno.
	end_turn(a, lg)
	end_turn(b, lg)

	return {"log": lg, "dmg_to_a": dmg_a, "dmg_to_b": dmg_b, "self_a": self_a, "self_b": self_b}


static func placement(f: Fighter, c: TurnChoice) -> Dictionary:
	return {
		"attack": c.attack.duplicate(),
		"defense": c.defense.duplicate(),
		"self": c.self_indices(f.dice.size()),
	}


# ---------------------------------------------------------------- D. Corrente
static func applies_corrente(f: Fighter, pl: Dictionary) -> bool:
	return f.defense_id == "D12" and pl.defense.size() == 1 and f.dice[pl.defense[0]] == 6


## O maior dado ativo do alvo troca de lugar com o menor dado de autodano dele.
static func corrente(t: Fighter, pl: Dictionary, lg: Array) -> void:
	if t.has("DF8") and not t.chapeu_used:
		t.chapeu_used = true
		lg.append(Texts.t("log.chapeu", {"who": t.name, "effect": "a Corrente"}))
		return
	var actives: Array = pl.attack + pl.defense
	if actives.is_empty() or pl.self.is_empty():
		return
	var big: int = actives[0]
	for i in actives:
		if t.dice[i] > t.dice[big]:
			big = i
	var low: int = pl.self[0]
	for i in pl.self:
		if t.dice[i] < t.dice[low]:
			low = i
	if big in pl.attack:
		pl.attack[pl.attack.find(big)] = low
	else:
		pl.defense[pl.defense.find(big)] = low
	pl.self[pl.self.find(low)] = big
	lg.append(Texts.t("log.corrente", {"who": t.name, "from": t.dice[big], "to": t.dice[low]}))


# ---------------------------------------------------------------- E. Condições
static func side_state(f: Fighter, pl: Dictionary, lg: Array) -> Dictionary:
	var vals := []
	for i in pl.attack:
		var v: int = f.dice[i]
		if f.attack_id == "A6" and v <= 2:
			v = 6
		vals.append(v)
	if f.has("DD4") and not vals.is_empty():
		vals[argmin(vals)] += 1
	var s := {
		"pl": pl,
		"vals": vals,
		"pair": has_pair(vals),
		"trio": vals.size() == 3 and vals[0] == vals[1] and vals[1] == vals[2],
		"seq": is_sequence(vals),
		"def_active": false,
		"x": 0,
	}
	if pl.defense.size() == 1 and f.defense_id != "":
		var x: int = f.dice[pl.defense[0]]
		s.x = x
		s.def_active = Items.defense_accepts(f.defense_id, x)
		if not s.def_active:
			lg.append(Texts.t("log.def_invalid", {"who": f.name, "item": Texts.item_name(f.defense_id), "n": x}))
	return s


static func defense_shields(f: Fighter, s: Dictionary, lg: Array) -> void:
	if not s.def_active:
		return
	var x: int = s.x
	match f.defense_id:
		"D1":
			var v := f.shield_value(2 * x)
			f.round_shield += v
			lg.append(Texts.t("log.def_shield", {"who": f.name, "item": Texts.item_name("D1"), "n": v}))
		"D5":
			var v := f.shield_value(x)
			f.barrier = mini(Config.BARRIER_CAP, f.barrier + v)
			lg.append(Texts.t("log.def_barrier", {"who": f.name, "n": f.barrier}))
		"D10":
			var v := f.shield_value(x)
			f.placa_shield += v
			lg.append(Texts.t("log.def_shield", {"who": f.name, "item": Texts.item_name("D10"), "n": v}))


# ---------------------------------------------------------------- F. Ataque
static func attack(f: Fighter, s: Dictionary, o: Fighter, so: Dictionary,
		rng: RandomNumberGenerator, lg: Array) -> Dictionary:
	var pl: Dictionary = s.pl
	var vals: Array = s.vals
	var n: int = vals.size()
	var result := {"eff": [], "annulled": [], "total": 0}
	if n == 0:
		return result

	# F1. Modificadores próprios por dado.
	var eff := vals.duplicate()
	for i in n:
		if f.attack_id == "A5" and i == 0:
			eff[i] *= 2
		if f.attack_id == "A8" and vals[i] % 2 == 1:
			eff[i] += 2
		if f.attack_id == "A7" and vals[i] == 6:
			var sides: int = f.dice_sides[pl.attack[i]]
			for _k in 50:
				var e := roll_die(f, sides, rng)
				eff[i] += e
				if e != 6:
					break

	# F2. Modificadores do oponente por dado.
	var annulled := []
	annulled.resize(n)
	annulled.fill(false)
	if so.def_active:
		match o.defense_id:
			"D7":
				for i in n:
					if vals[i] == so.x:
						annulled[i] = true
						lg.append(Texts.t("log.annul", {"who": o.name, "item": Texts.item_name("D7"), "n": vals[i]}))
			"D8":
				var parity: int = so.x % 2
				for i in n:
					if vals[i] % 2 == parity:
						annulled[i] = true
						lg.append(Texts.t("log.annul", {"who": o.name, "item": Texts.item_name("D8"), "n": vals[i]}))
			"D9":
				var r: int = Config.ceil_div(so.x, 2) + o.whey()
				for i in n:
					eff[i] = maxi(0, eff[i] - r)
				lg.append(Texts.t("log.reduce_die", {"who": o.name, "item": Texts.item_name("D9"), "n": r}))
	for i in n:
		if annulled[i]:
			eff[i] = 0
	if o.has("DF3"):
		var big := -1
		for i in n:
			if not annulled[i] and (big == -1 or eff[i] > eff[big]):
				big = i
		if big != -1 and eff[big] > 0:
			var r := 1 + o.whey()
			eff[big] = maxi(0, eff[big] - r)
			lg.append(Texts.t("log.reduce_die", {"who": o.name, "item": Texts.item_name("DF3"), "n": r}))

	# F3. Fórmula do item.
	var w := sum_of(eff)
	var total := w
	var bonus := ""
	match f.attack_id:
		"A2":
			if s.pair:
				total = Config.ceil_div(w * 13, 10)
				bonus = " (par +30%)"
			else:
				total = Config.ceil_div(w * 8, 10)
				bonus = " (sem par −20%)"
		"A3":
			if s.trio:
				total = w * 2
				bonus = " (trio x2)"
			else:
				total = Config.ceil_div(w * 8, 10)
				bonus = " (sem trio −20%)"
		"A4":
			if s.seq:
				total = w + 10
				bonus = " (sequência +10)"
		"A10":
			var m := 0
			for i in pl.self:
				m = maxi(m, f.dice[i])
			total = w + m
			bonus = " (+%d da Foice)" % m

	# F4. Multiplicadores globais.
	if f.raspadinha:
		total *= 2
		bonus += " (Raspadinha x2)"

	var parts := []
	for v in eff:
		parts.append(str(v))
	lg.append(Texts.t("log.attack", {
		"who": f.name, "item": Texts.item_name(f.attack_id),
		"detail": "+".join(parts) + bonus, "n": total}))
	result.eff = eff
	result.annulled = annulled
	result.total = total
	return result


# ---------------------------------------------------------------- G. Espelho
## Contribuição proporcional de um dado ao total do ataque (arredonda para cima).
static func contribution(total: int, eff: Array, i: int) -> int:
	var w := sum_of(eff)
	if w <= 0:
		return Config.ceil_div(total, eff.size())
	return Config.ceil_div(total * int(eff[i]), w)


## Tira do ataque de `f` as contribuições espelhadas por `o`; devolve o dano refletido.
static func mirrors(f: Fighter, s: Dictionary, atk: Dictionary, o: Fighter, so: Dictionary, lg: Array) -> int:
	var eff: Array = atk.eff
	if eff.is_empty() or atk.total <= 0:
		return 0
	var mirrored := []
	if o.boss_id == "C3":
		for i in eff.size():
			if s.vals[i] == 6 and not atk.annulled[i]:
				mirrored.append(i)
	if so.def_active and o.defense_id == "D11":
		var big := -1
		for i in eff.size():
			if not (i in mirrored) and (big == -1 or eff[i] > eff[big]):
				big = i
		if big != -1:
			mirrored.append(big)
	if mirrored.is_empty():
		return 0
	var original_total: int = atk.total
	var reflected := 0
	for i in mirrored:
		var part := contribution(original_total, eff, i)
		reflected += part
		var key := "log.kevin" if (o.boss_id == "C3" and s.vals[i] == 6) else "log.mirror"
		lg.append(Texts.t(key, {"who": o.name, "n": part}))
	reflected = mini(reflected, original_total)
	atk.total = original_total - reflected
	return reflected


# ---------------------------------------------------------------- H. Espinhos
static func thorns(f: Fighter, atk: Dictionary, o: Fighter, so: Dictionary, lg: Array) -> int:
	if not (so.def_active and o.defense_id == "D6"):
		return 0
	var count := 0
	for i in atk.eff.size():
		if not atk.annulled[i]:
			count += 1
	if count == 0:
		return 0
	if f.has("DF8") and not f.chapeu_used:
		f.chapeu_used = true
		lg.append(Texts.t("log.chapeu", {"who": f.name, "effect": "os espinhos"}))
		return 0
	var k: int = Config.ceil_div(so.x, 2) + o.whey()
	var dmg := k * count
	lg.append(Texts.t("log.thorns", {"who": o.name, "n": dmg}))
	return dmg


# ---------------------------------------------------------------- I. Reduções
static func reduce(f: Fighter, s: Dictionary, amount: int, lg: Array) -> int:
	if amount <= 0:
		return 0
	if f.has("DF6") and f.full_at_start:
		var cut := mini(amount, 2 + f.whey())
		amount -= cut
		lg.append(Texts.t("log.meia", {"who": f.name, "n": cut}))
	if s.def_active and f.defense_id == "D3" and amount > 0:
		var blocked := mini(amount, Config.ceil_div(amount, 2) + f.whey())
		amount -= blocked
		lg.append(Texts.t("log.muralha", {"who": f.name, "n": blocked}))
	var absorbed := 0
	var take := mini(amount, f.round_shield)
	f.round_shield -= take
	amount -= take
	absorbed += take
	take = mini(amount, f.placa_shield)
	f.placa_shield -= take
	amount -= take
	absorbed += take
	take = mini(amount, f.barrier)
	f.barrier -= take
	amount -= take
	absorbed += take
	if absorbed > 0:
		lg.append(Texts.t("log.shield_absorb", {"who": f.name, "n": absorbed}))
	return amount


# ---------------------------------------------------------------- J/K. Curas
static func machado(f: Fighter, s: Dictionary, lg: Array) -> void:
	if f.attack_id != "A9":
		return
	var n := 0
	for v in s.vals:
		if v >= 5:
			n += 2
	if n > 0:
		var h := f.heal(n)
		if h > 0:
			lg.append(Texts.t("log.machado", {"who": f.name, "n": h}))


static func fenix(f: Fighter, s: Dictionary, lg: Array) -> void:
	if s.def_active and f.defense_id == "D4":
		var h := f.heal(2 * int(s.x) + f.whey())
		lg.append(Texts.t("log.fenix", {"who": f.name, "n": h}))


# ---------------------------------------------------------------- L. Autodano
static func self_damage(f: Fighter, s: Dictionary, turn: int, lg: Array) -> int:
	var pl: Dictionary = s.pl
	if turn == 1 and f.has("DF2"):
		lg.append(Texts.t("log.capacete", {"who": f.name}))
		return 0
	var values := []
	for i in pl.self:
		values.append(f.dice[i])
	if s.def_active and f.defense_id == "D7":
		values = values.filter(func(v): return v != s.x)
	if f.has("DD7"):
		var counts := {}
		for v in values:
			counts[v] = counts.get(v, 0) + 1
		values = values.filter(func(v): return counts[v] == 1)
	var total := sum_of(values)
	var parts := []
	for v in values:
		parts.append(str(v))
	lg.append(Texts.t("log.self", {"who": f.name, "n": total, "dice": "+".join(parts) if not parts.is_empty() else "—"}))
	if s.def_active and f.defense_id == "D2":
		total = maxi(0, Config.ceil_div(total, 2) - f.whey())
		lg.append(Texts.t("log.balsamo", {"who": f.name, "n": total}))
	if f.has("DF7") and f.hp_at_start <= 10:
		total = Config.ceil_div(total, 2)
		lg.append(Texts.t("log.garrafa", {"who": f.name, "n": total}))
	if f.has("DF10") and total > 10:
		total = 10
		lg.append(Texts.t("log.cadeado", {"who": f.name, "n": total}))
	return total


# ---------------------------------------------------------------- M. Fim
static func end_turn(f: Fighter, lg: Array) -> void:
	if f.placa_shield > 0:
		var h := f.heal(f.placa_shield)
		if h > 0:
			lg.append(Texts.t("log.placa", {"who": f.name, "n": h}))
	f.placa_shield = 0
	f.round_shield = 0
	f.barrier = mini(f.barrier, Config.BARRIER_CAP)


# ---------------------------------------------------------------- Utilidades
static func argmin(a: Array) -> int:
	var j := 0
	for i in a.size():
		if a[i] < a[j]:
			j = i
	return j


static func max_of(a: Array) -> int:
	var m := 0
	for v in a:
		m = maxi(m, v)
	return m


static func sum_of(a: Array) -> int:
	var t := 0
	for v in a:
		t += int(v)
	return t


static func has_pair(vals: Array) -> bool:
	for i in vals.size():
		for j in range(i + 1, vals.size()):
			if vals[i] == vals[j]:
				return true
	return false


static func is_sequence(vals: Array) -> bool:
	if vals.size() != 3:
		return false
	var s := vals.duplicate()
	s.sort()
	return s[1] == s[0] + 1 and s[2] == s[1] + 1
