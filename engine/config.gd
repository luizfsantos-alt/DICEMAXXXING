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
const HAND_SIZE := 5
const TURN_LIMIT := 60 ## Turnos somados dos dois lados.

# Personagem (fatia: só o Feiticeiro).
const SORCERER_HP := 90
const SORCERER_GRID := Vector2i(4, 3)
const ASSASSIN_HP := 40
const ASSASSIN_GRID := Vector2i(6, 1)
const ASSASSIN_HAND_BONUS := 1

# Efeitos.
const LEVEL_MULT := [1.0, 1.5, 2.0] ## Evolução da magia: multiplicador do efeito (níveis 1 a 3).
const MAX_LEVEL := 3
const SACRIFICE_BONUS := 5
const URANIUM_POISON := 2
const SODIUM_BURN := 2
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
const MASTER_HP_MULT := 1.6
const ENEMY_UPGRADES_PER_FLOOR := 0.4 ## Melhorias do inimigo por andar (orçamento).

# Economia.
const SKIP_REWARD_COINS := 3
const PRICE_SPELL := 10
const PRICE_DIE := 6
const PRICE_ELEMENT := 8
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
