class_name EnemyFactory
extends RefCounted
## Gera a ficha de cada luta (docs/SPEC.md 8.2 e 8.5).

## Bloco 1: ataques simples de entender; metade dos inimigos com Escudo de Madeira.
const BLOCK1_ATTACKS := ["A1", "A5", "A6", "A8"]
const BLOCK1_SHIELD_CHANCE := 0.5
## Chance de o inimigo comum ser Calculista, por bloco.
const CALCULIST_CHANCE := {2: 0.25, 3: 0.33}


static func block_of(fight: int) -> int:
	@warning_ignore("integer_division")
	return (fight - 1) / 10 + 1


static func is_boss(fight: int) -> bool:
	return fight % 10 == 0


static func create(fight: int, rng: RandomNumberGenerator) -> Fighter:
	if is_boss(fight):
		return boss(fight)
	var b := block_of(fight)
	var f := Fighter.new()
	var lo := 18 + 4 * (b - 1) - (1 if b >= 2 else 0) ## Calibrado para a IA reativa (v2.2).
	f.max_hp = rng.randi_range(lo, lo + 6) * Config.HP_SCALE
	f.hp = f.max_hp
	f.dice_sides = [6, 6, 6, 6, 6, 6]
	f.attack_id = BLOCK1_ATTACKS[rng.randi_range(0, BLOCK1_ATTACKS.size() - 1)]
	f.defense_id = "D1" if rng.randf() < BLOCK1_SHIELD_CHANCE else ""
	if b >= 2:
		f.attack_id = Items.ATTACK[rng.randi_range(0, Items.ATTACK.size() - 1)]
		var pool := Items.DEFENSE.slice(0, 10) if b == 2 else Items.DEFENSE
		f.defense_id = pool[rng.randi_range(0, pool.size() - 1)]
	if rng.randf() < CALCULIST_CHANCE.get(b, 0.0):
		f.personality = "calculista"
	else:
		f.personality = EnemyAI.PERSONALITIES[rng.randi_range(0, EnemyAI.PERSONALITIES.size() - 1)]
	f.name = random_name(rng)
	return f


static func boss(fight: int) -> Fighter:
	var f := Fighter.new()
	f.dice_sides = [6, 6, 6, 6, 6, 6]
	match fight:
		10:
			f.boss_id = "C1"
			f.max_hp = 35 * Config.HP_SCALE
			f.attack_id = "A1"
			f.personality = "bruto"
		20:
			f.boss_id = "C2"
			f.max_hp = 40 * Config.HP_SCALE
			f.attack_id = "A1"
			f.defense_id = "D1"
			f.personality = "cauteloso"
		_:
			f.boss_id = "C3"
			f.max_hp = 45 * Config.HP_SCALE
			f.attack_id = "A2"
			f.defense_id = "D9"
			f.personality = "cauteloso"
	f.hp = f.max_hp
	f.name = Texts.boss_name(f.boss_id)
	return f


static func random_name(rng: RandomNumberGenerator) -> String:
	var titles := Texts.name_list("titles")
	var first := Texts.name_list("first")
	var epithets := Texts.name_list("epithets")
	if first.is_empty():
		return "Inimigo"
	var parts := []
	if not titles.is_empty() and rng.randf() < 0.5:
		parts.append(titles[rng.randi_range(0, titles.size() - 1)])
	parts.append(first[rng.randi_range(0, first.size() - 1)])
	var n := " ".join(parts)
	if not epithets.is_empty():
		var e: String = epithets[rng.randi_range(0, epithets.size() - 1)]
		n += (", " if e.begins_with("o ") else " ") + e
	return n
