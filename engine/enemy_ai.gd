class_name EnemyAI
extends RefCounted
## Personalidades (docs/SPEC.md 8.3). A IA sempre usa 3 dados ativos e
## lança do maior para o menor (exceto o Caótico).

const PERSONALITIES := ["bruto", "cauteloso", "caotico"]


static func choose(f: Fighter, rng: RandomNumberGenerator) -> TurnChoice:
	match f.personality:
		"cauteloso":
			return cautious(f)
		"caotico":
			return chaotic(f, rng)
		_:
			return brute(f)


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


static func chaotic(f: Fighter, rng: RandomNumberGenerator) -> TurnChoice:
	var idx := range(f.dice.size())
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


static func shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp
