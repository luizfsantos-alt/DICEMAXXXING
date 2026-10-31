class_name Config
extends RefCounted
## Valores ajustáveis do jogo (ver docs/SPEC.md, seção 9).

const DICE_COUNT := 6
const MAX_ACTIVE := 3
const HP_SCALE := 2 ## Multiplica todas as vidas (jogador, inimigos e chefes).
const BASE_HP := 30 * HP_SCALE
const GLADIATOR_HP_BONUS := 10 * HP_SCALE
const TURN_LIMIT := 60
const BARRIER_CAP := 20
const PASSIVE_LIMIT := 3
const LAST_FIGHT := 30 ## Protótipo: blocos 1 a 3.

const COINS_WIN := 5
const COINS_BOSS := 15
const FREE_REROLLS := 3

const HP_UPGRADE := 5
const PRICE_HP := 6
const PRICE_HP_STEP := 3
const PRICE_EQUIP := 12
const PRICE_PASSIVE := 15
const PRICE_DEATH_DEFY := 40

const RARITY_COMMON := 0.70
const RARITY_RARE := 0.25 ## O resto (5%) é Desafio à Morte.


## Divisão inteira arredondando para cima (a > = 0, b > 0).
static func ceil_div(a: int, b: int) -> int:
	if a <= 0:
		return 0
	@warning_ignore("integer_division")
	return (a + b - 1) / b
