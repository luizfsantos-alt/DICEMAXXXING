class_name Config
extends RefCounted
## Valores ajustáveis do jogo (docs/SPEC_v3.md). Todos são iniciais: o simulador ajusta.

# Torre: masmorra 1, 30 andares, Mestre nos andares 10, 20 e 30.
const LAST_FLOOR := 30
## Mestre de cada andar: [id, arquétipo]. A recompensa do Mestre vem depois do 10 e do 20.
const MASTERS := {10: ["porteiro", "sorcerer"], 20: ["alquimista", "copyist"], 30: ["reator", "barbarian"]}
## Kit fixo de cada Mestre (docs/SPEC_v3.1.md §4): elementos da bolsa (o resto é comum)
## e magias [id, x, y, rot, nível], no inventário do arquétipo dele. Sem orçamento aleatório.
const MASTER_KITS := {
	"porteiro": {"bag": ["Pb", "Pb", "Pb"], "bag_size": 8,
		"spells": [["peso", 0, 0, 0, 2], ["escudo", 1, 0, 0, 1], ["interrupcao", 2, 0, 0, 1], ["faisca", 0, 1, 0, 2]]},
	"alquimista": {"bag": ["Hg", "Hg", "Hg", "Hg"], "bag_size": 8,
		"spells": [["imitacao", 0, 0, 0, 1], ["bola", 2, 0, 0, 2], ["faisca", 0, 1, 0, 2]]},
	"reator": {"bag": ["U", "U", "U", "U", "U", "U", "U", "U"], "bag_size": 8,
		"spells": [["expectativa", 0, 0, 0, 1], ["machadada", 0, 1, 0, 3], ["mordida", 2, 1, 0, 2], ["suor", 1, 2, 0, 1]]},
}
const MASTER_FLOORS := [10, 20, 30]
const REST_EVERY := 3 ## Trifurcação sem luta depois de cada 3 lutas.
const INSANE_DOOR_CHANCE := 0.25

# Bolsa e mão.
const START_BAG := 8
const HAND_SIZE := 4
const TURN_LIMIT := 60 ## Turnos somados dos dois lados.

# Personagens: engine/characters.gd.

# Efeitos.
const LEVEL_MULT := [1.0, 1.5, 2.0] ## Evolução da magia: multiplicador do efeito (níveis 1 a 3).
const MAX_LEVEL := 3
const SACRIFICE_BONUS := 5
const URANIUM_POISON := 2
const SODIUM_BURN := 2
const ASBESTOS_DMG := 3 ## Amianto: dano em quem usa.
const HEAL_STOP_FRACTION := 0.35
const WIN_HEAL_FRACTION := 0.1 ## Vitória fora dos Mestres recupera esta fração da vida máxima (sem a Sede).

# Portas: [id, multiplicador do orçamento do inimigo, moedas].
const DOORS := {
	"facil": [0.8, 3],
	"normal": [1.0, 7],
	"dificil": [1.3, 12],
	"insana": [1.7, 20],
}
## Opções da recompensa pós-luta por porta (docs/SPEC_v3.1.md §2.2).
const REWARD_CHOICES := {"facil": 2, "normal": 3, "dificil": 3, "insana": 4}

# Inimigos.
const ENEMY_HP_BASE := 31
const ENEMY_HP_PER_FLOOR := 5
const ENEMY_HP_MULT := 0.9 ## Compensa a mão de 4 (lutas mais longas desgastam o herói).
const MASTER_HP_MULT := 2.0
const MASTER_COINS := 20
const REACTOR_POISON := 1 ## O Reator: cada dado parado no fim do turno envenena quem o rolou.
const MINIMALIST_ENEMY_HP_MULT := 0.8 ## Compensa o Hidrogênio.
const MONK_FLOOR := 5 ## Monge do Silêncio: a partir deste andar.
const VARIANT_CHANCE := 0.2
const RARE_ENEMY_FLOOR := 4 ## Nada Raro nos inimigos antes deste andar.
const ENEMY_UPGRADES_PER_FLOOR := 0.4 ## Melhorias do inimigo por andar (orçamento).
## Depois do primeiro Mestre, os inimigos crescem mais devagar (o herói já tem a recompensa dele).
const LATE_FLOOR := 10
const ENEMY_HP_PER_FLOOR_LATE := 3
const ENEMY_UPGRADES_PER_FLOOR_LATE := 0.35
const ENEMY_STICKER_STACK := 0.5 ## Chance do adesivo do inimigo ir na face que já tem mais adesivos.
const MASTER_HEAL_FRACTION := 0.3 ## Vencer um Mestre recupera esta fração da vida máxima.

# Economia.
const SKIP_REWARD_COINS := 3
const PRICE_SPELL := 10 ## Referência (sem raridade).
const PRICE_DIE := 6

# Raridade (docs/RARIDADE.md).
const RARITIES := ["common", "uncommon", "rare"]
## Chance de cada classe por faixa de andares: 1–3, 4–6, 7+.
const RARITY_WEIGHTS := [[70, 25, 5], [55, 32, 13], [45, 35, 20]]
const RARITY_BAND_FLOORS := [3, 6] ## Último andar das faixas 0 e 1.
const PRICE_SPELL_BY_RARITY := {"common": 8, "uncommon": 12, "rare": 18}
const PRICE_DIE_BY_RARITY := {"common": 8, "uncommon": 11, "rare": 15}
const PRICE_ELEMENT_BY_RARITY := {"common": 6, "uncommon": 9, "rare": 13}
const PRICE_EVOLVE_RARE := 18 ## Escola: evoluir uma magia Rara.
const PRICE_HP := 7
const PRICE_HP_STEP := 3
const HP_UPGRADE := 5
const PRICE_STICKER := 6 ## × (1 + adesivos já no dado).
const PRICE_DESTROY := 10 ## + 10 por uso na jornada.
const PRICE_DESTROY_STEP := 10


static func ceil_div(a: int, b: int) -> int:
	@warning_ignore("integer_division")
	return (a + b - 1) / b if a >= 0 else -((-a) / b)


static func scale(v: int, level: int) -> int:
	return int(ceil(v * LEVEL_MULT[clampi(level, 1, MAX_LEVEL) - 1] - 0.0001))
