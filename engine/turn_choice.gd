class_name TurnChoice
extends RefCounted
## Alocação de um lado: índices dos dados no ataque (na ordem dos slots)
## e encaixados na defesa. Todo o resto é autodano.

var attack: Array = []
var defense: Array = []


static func make(attack_idx: Array, defense_idx: Array = []) -> TurnChoice:
	var c := TurnChoice.new()
	c.attack = attack_idx.duplicate()
	c.defense = defense_idx.duplicate()
	return c


func active_count() -> int:
	return attack.size() + defense.size()


func self_indices(dice_count: int) -> Array:
	var out := []
	for i in dice_count:
		if not (i in attack) and not (i in defense):
			out.append(i)
	return out


func duplicate_choice() -> TurnChoice:
	return TurnChoice.make(attack, defense)


## Retorna "" se válida, ou a descrição do problema.
func validate(f: Fighter) -> String:
	var seen := {}
	for i in attack + defense:
		if i < 0 or i >= f.dice.size():
			return "índice inválido"
		if seen.has(i):
			return "dado repetido"
		seen[i] = true
	if active_count() > Config.MAX_ACTIVE:
		return "mais de %d dados ativos" % Config.MAX_ACTIVE
	if attack.size() > Items.ATTACK_MAX_DICE:
		return "dados demais no ataque"
	if defense.size() > (Items.DEFENSE_MAX_DICE if f.defense_id != "" else 0):
		return "dados demais na defesa"
	return ""


func to_dict() -> Dictionary:
	return {"attack": attack, "defense": defense}


static func from_dict(d: Dictionary) -> TurnChoice:
	return TurnChoice.make(Fighter._ints(d.get("attack", [])), Fighter._ints(d.get("defense", [])))
