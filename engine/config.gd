class_name Config
extends RefCounted
## Valores ajustáveis do jogo (docs/SPEC_v3.md). Todos são iniciais: o simulador ajusta.

# Torre (fatia vertical: 10 andares, Mestre no 10).
const LAST_FLOOR := 10
const MASTER_FLOORS := [10]
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
const HEAL_STOP_FRACTION := 0.5

# Portas: [id, multiplicador do orçamento do inimigo, moedas].
const DOORS := {
	"facil": [0.8, 4],
	"normal": [1.0, 6],
	"dificil": [1.3, 9],
	"insana": [1.7, 15],
}

# Inimigos.
const ENEMY_HP_BASE := 31
const ENEMY_HP_PER_FLOOR := 5
const ENEMY_HP_MULT := 0.9 ## Compensa a mão de 4 (lutas mais longas desgastam o herói).
const MASTER_HP_MULT := 1.6
const MINIMALIST_ENEMY_HP_MULT := 0.8 ## Compensa o Hidrogênio.
const MONK_FLOOR := 5 ## Monge do Silêncio: a partir deste andar.
const VARIANT_CHANCE := 0.2
const RARE_ENEMY_FLOOR := 4 ## Nada Raro nos inimigos antes deste andar.
const ENEMY_UPGRADES_PER_FLOOR := 0.4 ## Melhorias do inimigo por andar (orçamento).

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
