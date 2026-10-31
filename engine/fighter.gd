class_name Fighter
extends RefCounted
## Estado de um lado do duelo (jogador ou inimigo).

var name: String = ""
var is_player: bool = false
var max_hp: int = 30
var hp: int = 30
var dice_sides: Array = [6, 6, 6, 6, 6, 6]
var dice: Array = [] ## Valores rolados no turno atual.
var attack_id: String = "A1"
var defense_id: String = ""
var passives: Array = []
var boss_id: String = "" ## C1, C2, C3...
var personality: String = "" ## bruto, cauteloso, caotico (oculta na UI).
var death_defy: bool = false

# Estado do duelo.
var barrier: int = 0
var round_shield: int = 0
var placa_shield: int = 0
var chapeu_used: bool = false
var ioio_carry: int = -1
var raspadinha: bool = false
var coins_earned: int = 0
var hp_at_start: int = 0
var full_at_start: bool = false


func has(passive_id: String) -> bool:
	return passive_id in passives


func whey() -> int:
	return 1 if has("DD10") else 0


func heal(n: int) -> int:
	if n <= 0:
		return 0
	var before := hp
	hp = mini(max_hp, hp + n)
	return maxi(0, hp - before)


## Escudo gerado por um efeito de defesa: +1 do Whey antes do +20% do Boné.
func shield_value(base: int, apply_whey: bool = true) -> int:
	var v := base + (whey() if apply_whey else 0)
	if has("DF9"):
		v = Config.ceil_div(v * 12, 10)
	return v


func reset_duel_state() -> void:
	barrier = 0
	round_shield = 0
	placa_shield = 0
	chapeu_used = false
	ioio_carry = -1
	raspadinha = false
	coins_earned = 0


func to_dict() -> Dictionary:
	return {
		"name": name, "is_player": is_player, "max_hp": max_hp, "hp": hp,
		"dice_sides": dice_sides, "dice": dice, "attack_id": attack_id,
		"defense_id": defense_id, "passives": passives, "boss_id": boss_id,
		"personality": personality, "death_defy": death_defy, "barrier": barrier,
		"round_shield": round_shield, "placa_shield": placa_shield,
		"chapeu_used": chapeu_used, "ioio_carry": ioio_carry, "raspadinha": raspadinha,
		"coins_earned": coins_earned, "hp_at_start": hp_at_start, "full_at_start": full_at_start,
	}


static func from_dict(d: Dictionary) -> Fighter:
	var f := Fighter.new()
	f.name = d.get("name", "")
	f.is_player = d.get("is_player", false)
	f.max_hp = int(d.get("max_hp", 30))
	f.hp = int(d.get("hp", 30))
	f.dice_sides = _ints(d.get("dice_sides", [6, 6, 6, 6, 6, 6]))
	f.dice = _ints(d.get("dice", []))
	f.attack_id = d.get("attack_id", "A1")
	f.defense_id = d.get("defense_id", "")
	f.passives = Array(d.get("passives", []))
	f.boss_id = d.get("boss_id", "")
	f.personality = d.get("personality", "")
	f.death_defy = d.get("death_defy", false)
	f.barrier = int(d.get("barrier", 0))
	f.round_shield = int(d.get("round_shield", 0))
	f.placa_shield = int(d.get("placa_shield", 0))
	f.chapeu_used = d.get("chapeu_used", false)
	f.ioio_carry = int(d.get("ioio_carry", -1))
	f.raspadinha = d.get("raspadinha", false)
	f.coins_earned = int(d.get("coins_earned", 0))
	f.hp_at_start = int(d.get("hp_at_start", 0))
	f.full_at_start = d.get("full_at_start", false)
	return f


static func _ints(a: Array) -> Array:
	var out := []
	for v in a:
		out.append(int(v))
	return out
