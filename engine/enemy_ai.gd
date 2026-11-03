class_name EnemyAI
extends RefCounted
## Personalidades (docs/SPEC.md 8.3). A IA usa 3 dados ativos e põe o ataque do
## maior para o menor (exceto o Caótico).
##
## `brute`, `cautious` e `chaotic` são as jogadas-base (também usadas pelos bots do
## simulador). `choose` acrescenta a reação ao estado do duelo, a fuga do padrão e o
## Calculista, que simula as jogadas com o próprio motor.

const PERSONALITIES := ["bruto", "cauteloso", "caotico"]
const DEVIATION := 0.15 ## Chance de Bruto/Cauteloso fazerem a jogada do outro.
const CALC_PICK := [0.60, 0.25, 0.15] ## Calculista sorteia entre as 3 melhores jogadas.
const LOW_HP := 0.6 ## Cauteloso defende abaixo desta fração da vida.
const THREAT := 14 ## Cauteloso defende se os 3 maiores dados do oponente somam isso.
const BIG_SHIELD := 6 ## Bruto guarda um dado para a defesa se o oponente tem esse escudo.


## `opp` é o oponente (o jogador), já com os dados rolados. Sem ele, só a jogada-base.
static func choose(f: Fighter, rng: RandomNumberGenerator, opp: Fighter = null) -> TurnChoice:
	var p := f.personality
	if p == "calculista" and opp != null:
		return calculist(f, opp, rng)
	if p in ["bruto", "cauteloso"] and rng.randf() < DEVIATION:
		p = "cauteloso" if p == "bruto" else "bruto"
	match p:
		"cauteloso":
			return reactive_cautious(f, opp)
		"caotico":
			return chaotic(f, rng)
		_:
			return reactive_brute(f, opp)


# ---------------------------------------------------------------- Jogadas-base
static func sorted_desc(f: Fighter) -> Array:
	var idx := range(f.dice.size())
	idx.sort_custom(func(x, y): return f.dice[x] > f.dice[y] or (f.dice[x] == f.dice[y] and x < y))
	return idx


static func brute(f: Fighter) -> TurnChoice:
	var idx := sorted_desc(f)
	return TurnChoice.make(idx.slice(0, Config.MAX_ACTIVE))


static func cautious(f: Fighter) -> TurnChoice:
	var idx := sorted_desc(f)
	var top := idx.slice(0, Config.MAX_ACTIVE)
	if f.defense_id == "":
		return TurnChoice.make(top)
	if not Items.has_requirement(f.defense_id):
		var d: int = top[top.size() - 1]
		return TurnChoice.make(top.slice(0, top.size() - 1), [d])
	# Com requisito de valor: prefere um dado válido dentro do top 3,
	# senão um de fora entra no lugar do menor dos três.
	for i in range(top.size() - 1, -1, -1):
		if Items.defense_accepts(f.defense_id, f.dice[top[i]]):
			var d: int = top[i]
			var atk := top.duplicate()
			atk.remove_at(i)
			return TurnChoice.make(atk, [d])
	for i in idx.slice(Config.MAX_ACTIVE):
		if Items.defense_accepts(f.defense_id, f.dice[i]):
			return TurnChoice.make(top.slice(0, top.size() - 1), [i])
	return TurnChoice.make(top)


## Aleatório, mas sem jogadas absurdas: nunca usa o menor dado e só defende com dado válido.
static func chaotic(f: Fighter, rng: RandomNumberGenerator) -> TurnChoice:
	var idx: Array = sorted_desc(f).slice(0, f.dice.size() - 1)
	shuffle(idx, rng)
	var picked := idx.slice(0, Config.MAX_ACTIVE)
	var defense := []
	if f.defense_id != "" and rng.randf() < 0.5:
		for i in picked.size():
			if Items.defense_accepts(f.defense_id, f.dice[picked[i]]):
				defense.append(picked[i])
				picked.remove_at(i)
				break
	return TurnChoice.make(picked, defense)


# ---------------------------------------------------------------- Reações
static func top_sum(f: Fighter, n := Config.MAX_ACTIVE) -> int:
	var t := 0
	for i in sorted_desc(f).slice(0, n):
		t += int(f.dice[i])
	return t


static func shields_of(f: Fighter) -> int:
	return f.round_shield + f.placa_shield + f.barrier


## O ataque dos 3 maiores já derruba o oponente?
static func lethal(f: Fighter, opp: Fighter) -> bool:
	return opp != null and top_sum(f) >= opp.hp + shields_of(opp)


## Bruto: vai com tudo, mas guarda um dado para a defesa diante de um escudo grande.
static func reactive_brute(f: Fighter, opp: Fighter) -> TurnChoice:
	if opp == null or f.defense_id == "" or lethal(f, opp):
		return brute(f)
	if shields_of(opp) >= BIG_SHIELD:
		return cautious(f)
	return brute(f)


## Cauteloso: só defende com vida baixa ou diante de uma ameaça grande; ataca com tudo se é letal.
static func reactive_cautious(f: Fighter, opp: Fighter) -> TurnChoice:
	if opp == null:
		return cautious(f)
	if lethal(f, opp):
		return brute(f)
	if f.hp < f.max_hp * LOW_HP or top_sum(opp) >= THREAT:
		return cautious(f)
	return brute(f)


# ---------------------------------------------------------------- Calculista
## Todas as jogadas com 3 ativos: 3 no ataque (do maior para o menor) ou 2 + 1 na defesa.
static func candidates(f: Fighter) -> Array:
	var out := []
	var n := f.dice.size()
	for a in n:
		for b in range(a + 1, n):
			for c in range(b + 1, n):
				var trio := [a, b, c]
				trio.sort_custom(func(x, y): return f.dice[x] > f.dice[y] or (f.dice[x] == f.dice[y] and x < y))
				out.append(TurnChoice.make(trio))
				if f.defense_id != "":
					for k in 3:
						var atk := trio.duplicate()
						var d: int = atk[k]
						atk.remove_at(k)
						out.append(TurnChoice.make(atk, [d]))
	return out


## Nota de uma jogada: simula o turno contra a jogada óbvia do oponente (3 maiores no ataque).
static func score(f: Fighter, opp: Fighter, c: TurnChoice) -> float:
	var me := Fighter.from_dict(f.to_dict())
	var op := Fighter.from_dict(opp.to_dict())
	var r := RandomNumberGenerator.new()
	r.seed = 7
	Resolver.resolve(me, op, c, brute(opp), r, 2, [])
	var s := float(opp.hp - op.hp) - float(f.hp - me.hp)
	s += 0.5 * float(me.barrier - f.barrier) ## Barreira acumulada vale para os próximos turnos.
	if op.hp <= 0:
		s += 1000.0
	if me.hp <= 0:
		s -= 1000.0
	return s


## Avalia todas as jogadas e sorteia entre as 3 melhores (60% / 25% / 15%).
static func calculist(f: Fighter, opp: Fighter, rng: RandomNumberGenerator) -> TurnChoice:
	var saved := Resolver.events ## A simulação não pode apagar os eventos do turno real.
	var scored := []
	for c in candidates(f):
		scored.append([score(f, opp, c), scored.size(), c])
	Resolver.events = saved
	scored.sort_custom(func(x, y): return x[0] > y[0] or (x[0] == y[0] and x[1] < y[1]))
	var roll := rng.randf()
	var acc := 0.0
	for k in mini(CALC_PICK.size(), scored.size()):
		acc += CALC_PICK[k]
		if roll < acc:
			return scored[k][2]
	return scored[0][2]


static func shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp
