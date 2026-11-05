class_name Spells
extends RefCounted
## Magias (docs/SPEC_v3.md §5): formato, exigência, efeito e uso.
##
## Exigências ("req"), todas checam o valor rolado:
## - any:     N dados quaisquer ("n" = quantidade).
## - max/min: 1 dado de valor ≤ / ≥ "v".
## - exact:   1 dado de valor exatamente "v".
## - odd/even: 1 dado ímpar / par.
## - max_n/min_n: "n" dados, todos ≤ / ≥ "v".
## - low_one: "n" dados, pelo menos um ≤ "v".
## - top:     1 dado na face mais alta que ele tem (dado marcado nunca conta).
## - pair:    2 dados iguais.
## - seq3:    3 dados em sequência (ex.: 3-4-5).
## - trio:    3 dados iguais.
##
## Efeitos ("fx"), resolvidos em Resolver.cast:
## dmg (dano = soma + "plus", × "mult"; "pierce" ignora todas as defesas; "burn";
## "odd_twice"), product (produto × "mult"), lever (maior × menor), multi (um golpe
## por dado, valor × "mult"; o dobro se todos forem iguais), ones (dano = "per" ×
## quantos 1 há na mão), top_x (maior dado × "mult"), encore (Bis!), steal_sticker
## (Plágio), bench (Arrancar das Mãos), spawn_half / spawn_copy (devolvem dados à mão
## na alocação), block ("mult"), block_product, block_hand ("per" × dados na mão),
## riposte, immune, cleanse, recycle, debuff (só "hand_mod"), dodge, mirror, heal,
## maxhp, sacrifice, drain (dano = valor, cura o mesmo), feast (dano = soma, cura o
## menor). "heal" usa "mult".
## Opcionais: "hand_mod" (mexe na próxima mão do inimigo) e "mark" (marca o dado
## para a sua próxima mão: same, six, sum, plus2).
##
## Raridade ("rarity"): common, uncommon, rare (docs/RARIDADE.md).
##
## Uso ("use"): always, once (1× por luta), twice (2× por luta). Sempre no máximo 1×
## por turno.

const S1 := [Vector2i(0, 0)]
const S_V2 := [Vector2i(0, 0), Vector2i(0, 1)] ## 1×2 (em pé).
const S_H2 := [Vector2i(0, 0), Vector2i(1, 0)] ## 2×1.
const S_H3 := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
const S_H4 := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
const S_SQ := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
const S_L3 := [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)]
const S_L4 := [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)]
const S_T4 := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)]
const S_X5 := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)]
const S_D2 := [Vector2i(0, 0), Vector2i(1, 1)] ## Diagonal: as casas não se tocam.
const S_D3 := [Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 2)]

const DATA := {
	# Base.
	"faisca": {"shape": S1, "req": "any", "n": 1, "fx": "dmg", "use": "always", "pool": "sorcerer", "rarity": "common"},
	"escudo": {"shape": S_V2, "req": "max", "v": 3, "fx": "block", "mult": 3, "use": "always", "pool": "sorcerer", "rarity": "common"},
	"bola": {"shape": S_SQ, "req": "pair", "fx": "dmg", "mult": 2, "burn": 3, "use": "once", "pool": "sorcerer", "rarity": "uncommon"},
	"meteoro": {"shape": S_L4, "req": "seq3", "fx": "dmg", "plus": 10, "use": "once", "pool": "sorcerer", "rarity": "uncommon"},
	"espelho": {"shape": S1, "req": "exact", "v": 1, "fx": "mirror", "use": "always", "pool": "sorcerer", "rarity": "uncommon"},
	"sacrificio": {"shape": S1, "req": "exact", "v": 1, "fx": "sacrifice", "use": "always", "pool": "sorcerer", "rarity": "rare"},
	"remendo": {"shape": S1, "req": "any", "n": 1, "fx": "heal", "use": "once", "pool": "any", "rarity": "common"},
	"transfusao": {"shape": S_H2, "req": "pair", "fx": "maxhp", "use": "once", "pool": "sorcerer", "rarity": "uncommon"},
	"estocada": {"shape": S1, "req": "any", "n": 1, "fx": "dmg", "plus": 1, "use": "always", "pool": "assassin", "rarity": "common"},
	"esquiva": {"shape": S1, "req": "max", "v": 2, "fx": "dodge", "use": "once", "pool": "assassin", "rarity": "common"},
	"corte": {"shape": S_H2, "req": "any", "n": 2, "fx": "dmg", "odd_twice": true, "use": "always", "pool": "assassin", "rarity": "common"},
	"sombras": {"shape": S_H3, "req": "exact", "v": 6, "fx": "dmg", "pierce": true, "use": "once", "pool": "assassin", "rarity": "uncommon"},
	# Rodada 1 (Feiticeiro).
	"bis": {"shape": S_H3, "req": "top", "fx": "encore", "use": "always", "pool": "sorcerer", "rarity": "rare"},
	"plagio": {"shape": S_V2, "req": "max", "v": 2, "fx": "steal_sticker", "use": "once", "pool": "sorcerer", "rarity": "uncommon"},
	"roubar_cena": {"shape": S1, "req": "exact", "v": 2, "fx": "debuff", "hand_mod": "steal_top", "use": "once", "pool": "sorcerer", "rarity": "uncommon"},
	"imitacao": {"shape": S_H2, "req": "any", "n": 1, "fx": "spawn_copy", "use": "always", "pool": "sorcerer", "rarity": "rare"},
	"expectativa": {"shape": S_T4, "req": "min", "v": 5, "fx": "dmg", "mult": 2, "hand_mod": "idle_dmg", "use": "once", "pool": "sorcerer", "rarity": "uncommon"},
	"matematica": {"shape": S_X5, "req": "max_n", "n": 3, "v": 4, "fx": "product", "use": "once", "pool": "sorcerer", "rarity": "rare"},
	"meia_verdade": {"shape": S1, "req": "exact", "v": 6, "fx": "debuff", "hand_mod": "even_to_one", "use": "once", "pool": "sorcerer", "rarity": "uncommon"},
	"interrupcao": {"shape": S_D2, "req": "max_n", "n": 2, "v": 3, "fx": "debuff", "hand_mod": "minus2", "use": "once", "pool": "sorcerer", "rarity": "uncommon"},
	"pose": {"shape": S_V2, "req": "any", "n": 1, "fx": "block", "mark": "same", "use": "always", "pool": "sorcerer", "rarity": "common"},
	"improviso": {"shape": S_H4, "req": "exact", "v": 1, "fx": "recycle", "use": "always", "pool": "sorcerer", "rarity": "rare"},
	"imune": {"shape": S1, "req": "even", "fx": "immune", "mult": 2, "use": "once", "pool": "sorcerer", "rarity": "common"},
	# Rodada 2 (Assassino, magos de dano físico).
	"forca": {"shape": S1, "req": "min", "v": 4, "fx": "spawn_half", "use": "always", "pool": "assassin", "rarity": "rare"},
	"fisica": {"shape": S_H3, "req": "low_one", "n": 2, "v": 3, "fx": "lever", "use": "always", "pool": "assassin", "rarity": "rare"},
	"arrancar": {"shape": S_V2, "req": "max", "v": 2, "fx": "bench", "use": "once", "pool": "assassin", "rarity": "uncommon"},
	"velocidade": {"shape": S_H3, "req": "max_n", "n": 3, "v": 3, "fx": "multi", "mult": 2, "use": "always", "pool": "assassin", "rarity": "uncommon"},
	"peso": {"shape": S1, "req": "exact", "v": 1, "fx": "ones", "per": 4, "use": "always", "pool": "assassin", "rarity": "common"},
	"impulso": {"shape": S_V2, "req": "any", "n": 1, "fx": "dmg", "mark": "plus2", "use": "always", "pool": "assassin", "rarity": "common"},
	"anatomia": {"shape": S_L3, "req": "pair", "fx": "dmg", "mult": 2, "hand_mod": "top_to_one", "use": "once", "pool": "assassin", "rarity": "uncommon"},
	"foto": {"shape": S_H4, "req": "min_n", "n": 4, "v": 5, "fx": "top_x", "mult": 4, "use": "once", "pool": "assassin", "rarity": "rare"},
	"revide": {"shape": S_H2, "req": "max", "v": 3, "fx": "riposte", "mult": 2, "use": "always", "pool": "assassin", "rarity": "uncommon"},
	"chave": {"shape": S1, "req": "exact", "v": 3, "fx": "debuff", "hand_mod": "halve", "use": "once", "pool": "assassin", "rarity": "rare"},
	"rasteira": {"shape": S_D3, "req": "max_n", "n": 2, "v": 2, "fx": "block", "mult": 2, "hand_mod": "minus1", "use": "always", "pool": "assassin", "rarity": "uncommon"},
	"suor": {"shape": S1, "req": "odd", "fx": "cleanse", "use": "twice", "pool": "assassin", "rarity": "common"},
	"armadura": {"shape": S_H2, "req": "max_n", "n": 2, "v": 3, "fx": "block_product", "mult": 2, "use": "always", "pool": "assassin", "rarity": "common"},
	"recuo": {"shape": S1, "req": "max", "v": 2, "fx": "dodge", "mark": "six", "use": "once", "pool": "assassin", "rarity": "uncommon"},
	"presenca": {"shape": S_V2, "req": "exact", "v": 6, "fx": "block_hand", "per": 3, "use": "always", "pool": "assassin", "rarity": "uncommon"},
	"concentrar": {"shape": S_L3, "req": "pair", "fx": "block", "mark": "sum", "use": "always", "pool": "assassin", "rarity": "uncommon"},
	# Personagens novos (docs/PERSONAGENS.md).
	"dardo": {"shape": S1, "req": "even", "fx": "dmg", "plus": 2, "use": "always", "pool": "any", "rarity": "common"},
	"obra": {"shape": S_L4, "req": "trio", "fx": "dmg", "mult": 2, "use": "always", "pool": "perfectionist", "rarity": "uncommon"},
	"mordida": {"shape": S1, "req": "any", "n": 1, "fx": "drain", "use": "always", "pool": "vampire", "rarity": "common"},
	"banquete": {"shape": S_H3, "req": "any", "n": 3, "fx": "feast", "use": "always", "pool": "vampire", "rarity": "uncommon"},
	"machadada": {"shape": S_V2, "req": "min", "v": 4, "fx": "dmg", "mult": 2, "use": "always", "pool": "barbarian", "rarity": "common"},
	"cerrar": {"shape": S1, "req": "max", "v": 3, "fx": "heal", "mult": 3, "use": "twice", "pool": "barbarian", "rarity": "common"},
}

## Mexidas na próxima mão do inimigo (Resolver.apply_hand_mods).
const HAND_MODS := ["steal_top", "idle_dmg", "even_to_one", "minus2", "minus1", "halve", "top_to_one"]
const IDLE_DMG := 2 ## Expectativa Tóxica: dano por dado parado.
const ENCORE_MAX := 5 ## Bis!: no máximo 5 rolagens extras.

## Kits iniciais: engine/characters.gd.
const ERUDITE_CHOICES := ["espelho", "remendo", "sacrificio", "transfusao", "meteoro"]


static func get_def(id: String) -> Dictionary:
	return DATA.get(id, {})


static func dice_needed(id: String) -> int:
	var d := get_def(id)
	match str(d.get("req", "any")):
		"pair":
			return 2
		"seq3", "trio":
			return 3
	return int(d.get("n", 1))


## Usos por luta: 0 = sem limite.
static func max_uses(id: String) -> int:
	match str(get_def(id).get("use", "always")):
		"once":
			return 1
		"twice":
			return 2
	return 0


## A magia é do grupo do arquétipo (ou de qualquer um)? Os inimigos só compram do
## próprio grupo (docs/PERSONAGENS.md §3.4).
static func in_pool(id: String, archetype: String) -> bool:
	var d := get_def(id)
	var p := str(d.get("pool", "any"))
	if p == "any" or p == archetype:
		return true
	var base := p in ["sorcerer", "assassin"]
	match archetype:
		"minimalist":
			return p == "sorcerer" and dice_needed(id) == 1
		"metallurgist":
			return p == "assassin" or id in ["espelho", "sacrificio", "improviso"]
		"copyist":
			return p == "sorcerer"
		"perfectionist":
			return base and (str(d.req) in ["pair", "trio", "seq3"] or d.has("mark"))
		"vampire":
			return (base and color_family(id) == "dmg") or id == "transfusao"
		"barbarian":
			return p == "assassin"
	return false


static func rarity(id: String) -> String:
	return str(get_def(id).get("rarity", "common"))


static func ids_of_rarity(r: String) -> Array:
	return DATA.keys().filter(func(x): return rarity(x) == r)


## Família de cor do efeito na interface: dmg, block, dodge, mirror, heal, maxhp, sacrifice.
static func color_family(id: String) -> String:
	var fx := str(get_def(id).get("fx", "dmg"))
	match fx:
		"product", "lever", "multi", "ones", "top_x", "encore", "steal_sticker", "bench", "spawn_half", "drain", "feast":
			return "dmg"
		"block_product", "block_hand", "riposte", "recycle":
			return "block"
		"immune", "debuff":
			return "mirror"
		"cleanse":
			return "heal"
		"spawn_copy":
			return "sacrifice"
	return fx


## Chave do texto de uso ("1× por luta", "2× por luta") ou "" se não tem limite.
static func use_key(id: String) -> String:
	match max_uses(id):
		1:
			return "ui.once"
		2:
			return "ui.twice"
	return ""


static func is_once(id: String) -> bool:
	return max_uses(id) > 0


## Formato girado: rot 0..3 (90° no sentido horário), normalizado para começar em (0,0).
static func shape(id: String, rot: int = 0) -> Array:
	var cells: Array = []
	for c in get_def(id).get("shape", [Vector2i(0, 0)]):
		var p: Vector2i = c
		for _k in posmod(rot, 4):
			p = Vector2i(-p.y, p.x)
		cells.append(p)
	var mn := Vector2i(999, 999)
	for p in cells:
		mn = Vector2i(mini(mn.x, p.x), mini(mn.y, p.y))
	var out: Array = []
	for p in cells:
		out.append(p - mn)
	return out


## O dado de valor v pode entrar ao lado dos valores já postos? top: o dado está na
## face mais alta que ele tem.
static func accepts_partial(id: String, placed: Array, v: int, top := false) -> bool:
	var d := get_def(id)
	var n := dice_needed(id)
	if placed.size() >= n:
		return false
	match str(d.get("req", "any")):
		"max", "max_n":
			return v <= int(d.v)
		"min", "min_n":
			return v >= int(d.v)
		"exact":
			return v == int(d.v)
		"odd":
			return v % 2 == 1
		"even":
			return v % 2 == 0
		"top":
			return top
		"low_one":
			if placed.size() + 1 < n or v <= int(d.v):
				return true
			for x in placed:
				if int(x) <= int(d.v):
					return true
			return false
		"pair", "trio":
			return placed.is_empty() or int(placed[0]) == v
		"seq3":
			if v in placed:
				return false
			var all := placed.duplicate()
			all.append(v)
			return int(all.max()) - int(all.min()) <= 2
	return true


## A magia está pronta para ser lançada com estes valores? tops: face mais alta, por dado.
static func complete(id: String, values: Array, tops: Array = []) -> bool:
	if values.size() != dice_needed(id):
		return false
	var placed := []
	for k in values.size():
		var t: bool = bool(tops[k]) if k < tops.size() else false
		if not accepts_partial(id, placed, int(values[k]), t):
			return false
		placed.append(values[k])
	return true


## Preço na Loja, pela raridade.
static func price(id: String) -> int:
	return int(Config.PRICE_SPELL_BY_RARITY.get(rarity(id), Config.PRICE_SPELL))


## Venda: metade do preço, vezes o nível.
static func sell_price(id: String, level: int) -> int:
	return Config.ceil_div(price(id) * level, 2)
