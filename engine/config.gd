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
const SODIUM_BURN := 3
const GOLD_COINS := 1 ## Ouro: cada dado usado dá 1 moeda (e cada adesivo de ouro na face usada, 1).
const CESIUM_POISON := 2 ## Césio: cada golpe que acerta põe 2 de veneno (radiação) no inimigo.
const ASBESTOS_DMG := 3 ## Amianto: dano em quem usa.
const LITHIUM_STEP := 2 ## Lítio: carga ganha a cada turno parado na mão.
const LITHIUM_CAP := 6 ## Lítio: carga máxima (somada na rolagem; zera ao ser usado).
const TITANIUM_BLOCK := 2 ## Titânio: bloqueio ao ser usado numa magia.
const COPPER_HEAL := 2 ## Cobre: cura ao ser usado numa magia.
const RIDDLE_DMG := 40 ## Charada Fatal: dano ao completar (ignora as defesas).
const LINGOT_INHERIT := [0.33, 0.5, 0.66] ## Lingotamento: chance de cada lingote herdar o elemento, por nível.
const TIDE_ONES := 3 ## Maré Cheia: dados de valor 1 na próxima mão (+1 por nível).
const TIDE_LOW_VALUE := 6 ## Maré Baixa: valor dos dois dados provisórios.
const SKIN_CAP := 3 ## Revestimento (Pele de Ferro): redução máxima por golpe no nível 1 (+1 por nível).
const HEAL_STOP_FRACTION := 0.35
const WIN_HEAL_FRACTION := 0.1 ## Vitória fora dos Mestres recupera esta fração da vida máxima (sem a Sede).

# Portas: [id, multiplicador da vida do inimigo, moedas].
const DOORS := {
	"facil": [0.8, 3],
	"normal": [1.0, 7],
	"dificil": [1.3, 12],
	"insana": [1.7, 20],
}
## Andares a mais (ou a menos) na jornada fantasma do inimigo, pela porta (EnemyFactory.journey).
const DOOR_JOURNEY := {"facil": -1, "normal": 0, "dificil": 2, "insana": 4}
## Opções da recompensa pós-luta por porta (docs/SPEC_v3.1.md §2.2).
const REWARD_CHOICES := {"facil": 2, "normal": 3, "dificil": 3, "insana": 4}

# Inimigos.
const ENEMY_HP_BASE := 31
const ENEMY_HP_PER_FLOOR := 5
const ENEMY_HP_MULT := 1.035 ## Calibrado com o bot novo e as mexidas (spec v3.1 §10): era 0,9.
const MASTER_HP_MULT := 2.6 ## Calibrado: o Mestre é a luta mais difícil do ato.
const MASTER_COINS := 20
const REACTOR_POISON := 1 ## O Reator: cada dado parado no fim do turno envenena quem o rolou.
const MINIMALIST_ENEMY_HP_MULT := 0.8 ## Compensa o Hidrogênio.
const MONK_FLOOR := 5 ## Monge do Silêncio: a partir deste andar.
const VARIANT_CHANCE := 0.2
const RARE_ENEMY_FLOOR := 4 ## Nada Raro nos inimigos antes deste andar.
## Depois do primeiro Mestre, os inimigos crescem mais devagar (o herói já tem a recompensa dele).
const LATE_FLOOR := 10
const ENEMY_HP_PER_FLOOR_LATE := 3
const ENEMY_STICKER_STACK := 0.5 ## Chance do adesivo do inimigo ir na face que já tem mais adesivos.
const MASTER_HEAL_FRACTION := 0.3 ## Vencer um Mestre recupera esta fração da vida máxima.

# Economia.
const SKIP_REWARD_COINS := 3
const PRICE_SPELL := 10 ## Referência (sem raridade).
const PRICE_DIE := 6

# Raridade (docs/RARIDADE.md).
const RARITIES := ["common", "uncommon", "rare", "legendary"]
## Chance de cada classe por faixa de andares: 1–3, 4–6, 7+.
## A Lendária (só magias) sai em 1 a 2% das ofertas.
const RARITY_WEIGHTS := [[69, 25, 5, 1], [54, 32, 12, 2], [43, 35, 20, 2]]
const RARITY_BAND_FLOORS := [3, 6] ## Último andar das faixas 0 e 1.
const PRICE_SPELL_BY_RARITY := {"common": 8, "uncommon": 12, "rare": 18, "legendary": 28}
const PRICE_DIE_BY_RARITY := {"common": 8, "uncommon": 11, "rare": 15}
const PRICE_ELEMENT_BY_RARITY := {"common": 6, "uncommon": 9, "rare": 13}
## Escola: evoluir do nível 1 para o 2 e do 2 para o 3; Rara e Lendária custam mais.
const PRICE_EVOLVE := [8, 14]
const PRICE_EVOLVE_RARE_EXTRA := 6
const PRICE_HP := 7
const PRICE_HEAL_STOP := 8 ## Parada de Cura (35% da vida máxima), uma vez por parada.
const VAMPIRE_HEAL_STOP_MULT := 0.5 ## Vampiro: a Cura da parada vale metade (ele já cura com a Sede).
const PRICE_HP_STEP := 3
const HP_UPGRADE := 5
const STICKER_PLUS := 2 ## Adesivo: +2 na face (somam; antes era ×2 e acumulava em potências).
const PRICE_STICKER := 6 ## × (1 + adesivos já no dado).
const PRICE_GOLD_STICKER := 8 ## Adesivo de ouro (Loja e Poço).
const PRICE_COPY_DIE := 12 ## Loja: copiar um dado da bolsa.
const PRICE_DESTROY := 10 ## + 10 por uso na jornada.
const PRICE_DESTROY_STEP := 10

# Loja e Escola (estoque e troca de ofertas).
const SHOP_STOCK := [1, 3] ## Estoque sorteado do dado e do adesivo da Loja.
const SHOP_EXTRA_CHANCE := 0.5 ## Chance da Loja ter também cópia de dado ou +vida máxima (estoque 1).
## Troca de ofertas: a 1ª da Loja é grátis, depois 3, 5, 7...; a da Escola, 5, 8, 11...
## O custo volta ao início a cada parada.
const SHOP_REROLL_FREE := 1
const SHOP_REROLL_BASE := 3
const SHOP_REROLL_STEP := 2
const SCHOOL_REROLL_BASE := 5
const SCHOOL_REROLL_STEP := 3


static func ceil_div(a: int, b: int) -> int:
	@warning_ignore("integer_division")
	return (a + b - 1) / b if a >= 0 else -((-a) / b)


static func scale(v: int, level: int) -> int:
	return int(ceil(v * LEVEL_MULT[clampi(level, 1, MAX_LEVEL) - 1] - 0.0001))
