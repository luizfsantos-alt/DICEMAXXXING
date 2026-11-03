class_name Items
extends RefCounted
## Catálogo de itens. Os textos ficam em data/texts_pt_br.json.

const ATTACK := ["A1", "A2", "A3", "A4", "A5", "A6", "A7", "A8", "A9", "A10"]
const DEFENSE := ["D1", "D2", "D3", "D4", "D5", "D6", "D7", "D8", "D9", "D10", "D11", "D12"]
const PASSIVES := [
	"DF1", "DF2", "DF3", "DF4", "DF5", "DF6", "DF7", "DF8", "DF9", "DF10",
	"DD1", "DD2", "DD3", "DD4", "DD5", "DD6", "DD7", "DD8", "DD9", "DD10",
]

## Requisitos de valor do dado encaixado na defesa.
const DEFENSE_REQUIREMENTS := {
	"D2": [5],
	"D3": [4],
	"D11": [1, 2],
	"D12": [6],
}

## Quantos dados cada tipo de item aceita.
const ATTACK_MAX_DICE := 3
const DEFENSE_MAX_DICE := 1


static func defense_accepts(defense_id: String, value: int) -> bool:
	if defense_id == "":
		return false
	if not DEFENSE_REQUIREMENTS.has(defense_id):
		return true
	return value in DEFENSE_REQUIREMENTS[defense_id]


static func has_requirement(defense_id: String) -> bool:
	return DEFENSE_REQUIREMENTS.has(defense_id)
