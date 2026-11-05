class_name Characters
extends RefCounted
## Arquétipos (docs/SPEC_v3.md §3 e docs/PERSONAGENS.md): inventário (com casas que
## não existem), vida, mão, bolsa inicial e magias iniciais. Jogador e inimigos usam
## os mesmos dados.
##
## bag: elementos dos dados que não são comuns; o resto da bolsa é de dados comuns.
## spells: [id, x, y, rot, nível].

const PLAYABLE := ["minimalist", "vampire", "barbarian"] ## Os 3 menos complexos.
const ALL := ["sorcerer", "assassin", "minimalist", "metallurgist", "copyist", "perfectionist", "vampire", "barbarian"]

const DATA := {
	"sorcerer": {
		"hp": 90, "grid": Vector2i(4, 3), "blocked": [], "hand": 5, "bag_size": 8, "bag": ["Na"],
		"spells": [["faisca", 3, 0, 0, 1], ["bola", 0, 0, 0, 1]],
	},
	"assassin": {
		"hp": 40, "grid": Vector2i(6, 1), "blocked": [], "hand": 6, "bag_size": 8, "bag": ["Hg"],
		"spells": [["estocada", 0, 0, 0, 1], ["corte", 1, 0, 0, 1]],
	},
	"minimalist": {
		"hp": 70, "grid": Vector2i(3, 2), "blocked": [], "hand": 4, "bag_size": 5, "bag": ["H", "H", "H"],
		"spells": [["faisca", 0, 0, 0, 1], ["dardo", 1, 0, 0, 1]],
	},
	"metallurgist": {
		"hp": 100, "grid": Vector2i(5, 2), "blocked": [], "hand": 5, "bag_size": 8, "bag": ["Pb", "Pb", "Pb"],
		"spells": [["peso", 0, 0, 0, 2], ["estocada", 1, 0, 0, 1]],
	},
	"copyist": {
		"hp": 80, "grid": Vector2i(4, 2), "blocked": [], "hand": 5, "bag_size": 8, "bag": ["Hg"],
		"spells": [["faisca", 0, 0, 0, 1], ["imitacao", 0, 1, 0, 1]],
	},
	"perfectionist": {
		"hp": 80, "grid": Vector2i(4, 3), "blocked": [Vector2i(1, 1), Vector2i(2, 1)], "hand": 5, "bag_size": 8, "bag": ["Os"],
		"spells": [["obra", 0, 0, 0, 1], ["dardo", 3, 0, 0, 1]],
	},
	"vampire": {
		"hp": 70, "grid": Vector2i(2, 4), "blocked": [], "hand": 5, "bag_size": 8, "bag": ["Na"],
		"spells": [["mordida", 0, 0, 0, 1], ["banquete", 1, 0, 1, 1]],
	},
	"barbarian": {
		"hp": 110, "grid": Vector2i(3, 3), "blocked": [], "hand": 5, "bag_size": 8, "bag": ["Am", "Am"],
		"spells": [["machadada", 0, 0, 0, 1], ["cerrar", 1, 0, 0, 1]],
	},
}

# Passivas.
const THIRST_CAP := 8 ## Vampiro: vida máxima ganha com a Sede (+1 por cura), por luta.
const FURY_STEP := 10 ## Bárbaro: +1 por golpe para cada 10 de vida perdida.
const KEEP_MAX := 2 ## Perfeccionista: dados guardados no fim do turno (e marcas ao mesmo tempo).


static func get_def(id: String) -> Dictionary:
	return DATA.get(id, DATA.sorcerer)


static func max_hp(id: String) -> int:
	return int(get_def(id).hp)


## Fúria do Bárbaro: com metade da vida ou menos, +1 por golpe a cada 10 de vida perdida.
static func fury(f: Fighter) -> int:
	if f.archetype != "barbarian" or f.hp * 2 > f.max_hp:
		return 0
	@warning_ignore("integer_division")
	return maxi(0, f.max_hp - f.hp) / FURY_STEP
