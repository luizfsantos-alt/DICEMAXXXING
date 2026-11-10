class_name Spells
extends RefCounted
## Magias (docs/SPEC_v3.md §5): formato, exigência, efeito e uso.
##
## Exigências ("req"), todas checam o valor rolado:
## - any:     N dados quaisquer ("n" = quantidade).
## - max/min: 1 dado de valor ≤ / ≥ "v".
## - exact:   1 dado (ou "n" dados) de valor exatamente "v".
## - odd/even: 1 dado ímpar / par.
## - max_n/min_n: "n" dados, todos ≤ / ≥ "v".
## - low_one: "n" dados, pelo menos um ≤ "v".
## - top:     1 dado na face mais alta que ele tem (dado marcado nunca conta).
## - pair:    2 dados iguais.
## - seq3:    3 dados em sequência (ex.: 3-4-5).
## - trio:    3 dados iguais.
## - riddle:  um dado de cada valor, de 1 a 6 (Charada Fatal): os dados postos ficam
##            guardados na magia (fora da bolsa) de turno em turno até completar.
##
## Efeitos ("fx"), resolvidos em Resolver.cast:
## dmg (dano = soma + "plus", × "mult"; "pierce" ignora todas as defesas; "burn";
## "odd_twice"), product (produto × "mult"), lever (maior × menor), multi (um golpe
## por dado, valor × "mult"; o dobro se todos forem iguais), ones (dano = "per" ×
## quantos 1 há na mão, até "cap"), pelt (um golpe de 1 por dado), top_x (maior dado × "mult"), encore (Bis!), steal_sticker
## (Plágio), bench (Arrancar das Mãos), spawn_half / spawn_copy (devolvem dados à mão
## na alocação), block ("mult"), block_product, block_hand ("per" × dados na mão),
## block_count ("per" × dados da mão de valor "count"), skin (Revestimento: −1 por golpe
## recebido, acumula até Config.SKIN_CAP + nível − 1), riposte, immune, cleanse, recycle, debuff (só "hand_mod"), dodge, mirror, heal,
## maxhp, sacrifice, drain (dano = valor, cura metade), feast (dano = soma, cura o
## menor). "heal" usa "mult". synth (Síntese: cura valor − 1 e bloqueio valor − 1),
## antithesis (Antítese: dano = valor × "mult" no inimigo; valor de dano em quem usa, antes
## de todas as magias do turno: "self_first").
## mod: mexida (docs/SPEC_v3.1.md §1): resolve na alocação, quando o buraco fica completo
## (TurnChoice), e devolve o dado mexido à mão. "mod" diz qual: reroll_max, nudge, top,
## split3, flip, avg, polar, echo, double, fuse, stairs, gamble, polish, insight (o dado
## volta à bolsa e saem 2 dela, rolados), tide_low (o dado vira dois 6 provisórios) e
## lingot (o dado vira tantos 1 quanto o valor).
## tide_out (Maré Cheia): três dados de valor 1 entram na sua próxima mão.
## Opcionais: "hand_mod" (mexe na próxima mão do inimigo) e "mark" (marca o dado
## para a sua próxima mão: same, six, sum, plus2).
##
## Raridade ("rarity"): common, uncommon, rare (docs/RARIDADE.md).
##
## "flex": a magia aceita quantos dados couberem na exigência (Forjamento): um buraco
## na tela, com contador; completa com qualquer quantidade a partir de 1.
##
## Uso ("use"): always, once (1× por luta), twice (2× por luta). Sempre no máximo 1×
## por turno.

const FLEX_MAX := 99 ## Teto técnico das magias "flex" (na prática, a mão inteira).
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
	## Só no kit inicial do Assassino (não aparece em ofertas nem nos inimigos que compram).
	"esquiva_mais": {"shape": S1, "req": "exact", "v": 2, "fx": "dodge", "use": "twice", "pool": "assassin", "rarity": "uncommon", "start_only": true},
	"corte": {"shape": S_H2, "req": "any", "n": 2, "fx": "dmg", "odd_twice": true, "use": "always", "pool": "assassin", "rarity": "common"},
	"sombras": {"shape": S_H3, "req": "exact", "v": 6, "fx": "dmg", "pierce": true, "use": "once", "pool": "assassin", "rarity": "uncommon"},
	# Rodada 1 (Feiticeiro).
	# Lendária: um dado de cada valor, guardados de turno em turno até completar.
	"charada": {"shape": S_SQ, "req": "riddle", "n": 6, "fx": "riddle", "use": "always", "pool": "sorcerer", "rarity": "legendary"},
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
	"peso": {"shape": S1, "req": "exact", "v": 1, "fx": "ones", "per": 4, "cap": 3, "use": "twice", "pool": "assassin", "rarity": "common"},
	"forjamento": {"shape": S_H2, "req": "exact", "n": FLEX_MAX, "v": 1, "flex": true, "fx": "pelt", "use": "always", "pool": "metallurgist", "rarity": "common"},
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
	"mare_cheia": {"shape": S_L3, "req": "exact", "v": 6, "fx": "tide_out", "use": "always", "pool": "any", "rarity": "common"},
	"cerrar": {"shape": S1, "req": "max", "v": 3, "fx": "heal", "mult": 3, "use": "twice", "pool": "barbarian", "rarity": "common"},
	# Magias do Ferro (sempre 3): pedem 3 exato e crescem com os 3 da mão.
	"bigorna": {"shape": S_H2, "req": "exact", "n": 2, "v": 3, "fx": "dmg", "mult": 3, "use": "always", "pool": "barbarian", "rarity": "uncommon"},
	"pele": {"shape": S_V2, "req": "exact", "v": 3, "fx": "skin", "use": "always", "pool": "barbarian", "rarity": "uncommon"},
	"muralha": {"shape": S_V2, "req": "exact", "v": 3, "fx": "block_count", "count": 3, "per": 4, "use": "always", "pool": "barbarian", "rarity": "common"},
	# Mexidas (docs/SPEC_v3.1.md §1.3): mudam os próprios dados na alocação.
	# Xamã (docs/XAMA.md): só no kit inicial (fora da Loja e das recompensas).
	"sintese": {"shape": S_V2, "req": "min", "v": 2, "fx": "synth", "use": "always", "pool": "shaman", "rarity": "common", "start_only": true},
	"antitese": {"shape": S_V2, "req": "any", "n": 1, "fx": "antithesis", "mult": 2, "self_first": true, "use": "always", "pool": "shaman", "rarity": "common", "start_only": true},
	"segunda": {"shape": S1, "req": "any", "n": 1, "fx": "mod", "mod": "reroll_max", "random": true, "use": "always", "pool": "sorcerer", "rarity": "common"},
	"ajuste": {"shape": S1, "req": "any", "n": 1, "fx": "mod", "mod": "nudge", "use": "always", "pool": "assassin", "rarity": "common"},
	"pico": {"shape": S1, "req": "any", "n": 1, "fx": "mod", "mod": "top", "use": "once", "pool": "any", "rarity": "common"},
	"sangria": {"shape": S1, "req": "min", "v": 3, "fx": "mod", "mod": "split3", "use": "always", "pool": "any", "rarity": "common"},
	"virar": {"shape": S1, "req": "max", "v": 6, "fx": "mod", "mod": "flip", "use": "always", "pool": "any", "rarity": "common"},
	"nivelar": {"shape": S_H2, "req": "any", "n": 2, "fx": "mod", "mod": "avg", "use": "always", "pool": "assassin", "rarity": "common"},
	"polarizar": {"shape": S1, "req": "any", "n": 1, "fx": "mod", "mod": "polar", "use": "always", "pool": "assassin", "rarity": "common"},
	"eco": {"shape": S_H2, "req": "any", "n": 2, "fx": "mod", "mod": "echo", "use": "always", "pool": "assassin", "rarity": "uncommon"},
	"inflar": {"shape": S1, "req": "max", "v": 3, "fx": "mod", "mod": "double", "use": "always", "pool": "sorcerer", "rarity": "uncommon"},
	"juntar": {"shape": S_H2, "req": "any", "n": 2, "fx": "mod", "mod": "fuse", "use": "always", "pool": "assassin", "rarity": "uncommon"},
	"escada": {"shape": S_L3, "req": "any", "n": 3, "fx": "mod", "mod": "stairs", "use": "always", "pool": "sorcerer", "rarity": "uncommon"},
	"tudo_nada": {"shape": S_V2, "req": "any", "n": 1, "fx": "mod", "mod": "gamble", "random": true, "use": "always", "pool": "sorcerer", "rarity": "rare"},
	"insight": {"shape": S_V2, "req": "any", "n": 1, "fx": "mod", "mod": "insight", "random": true, "use": "always", "pool": "sorcerer", "rarity": "uncommon"},
	"mare_baixa": {"shape": S_V2, "req": "any", "n": 1, "fx": "mod", "mod": "tide_low", "use": "once", "pool": "any", "rarity": "uncommon"},
	"lingotamento": {"shape": S_H2, "req": "max", "v": 6, "fx": "mod", "mod": "lingot", "random": true, "use": "once", "pool": "metallurgist", "rarity": "uncommon"},
	"lapidar": {"shape": S_H3, "req": "exact", "v": 1, "fx": "mod", "mod": "polish", "use": "once", "pool": "any", "rarity": "rare"},
}

## Dados devolvidos (Imitação, Força Desnecessária, Sangria) não entram nestas magias
## (docs/SPEC_v3.1.md §6): sem corrente de cópias, Sacrifício grátis nem vida máxima infinita.

## Mexidas na próxima mão do inimigo (Resolver.apply_hand_mods).
const HAND_MODS := ["steal_top", "idle_dmg", "even_to_one", "minus2", "minus1", "halve", "top_to_one"]
const IDLE_DMG := 2 ## Expectativa Tóxica: dano por dado parado.
const ENCORE_MAX := 5 ## Bis!: no máximo 5 rolagens extras.

## Kits iniciais: engine/characters.gd.
const ERUDITE_CHOICES := ["espelho", "remendo", "sacrificio", "transfusao", "meteoro"]


static func get_def(id: String) -> Dictionary:
	return DATA.get(id, {})


## Mexida: resolve na alocação e devolve o dado mexido (docs/SPEC_v3.1.md §1).
static func is_mod(id: String) -> bool:
	return str(get_def(id).get("fx", "")) == "mod"


## Mexida aleatória (rola o dado de novo): definitiva, não se desfaz.
static func is_flex(id: String) -> bool:
	return bool(get_def(id).get("flex", false))


static func is_random_mod(id: String) -> bool:
	return is_mod(id) and bool(get_def(id).get("random", false))


## Magias que resolvem na alocação (as mexidas, Imitação e Força): o cartão sai do palco.
static func resolves_early(id: String) -> bool:
	return is_mod(id) or str(get_def(id).get("fx", "")) in ["spawn_copy", "spawn_half"]


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
		"shaman":
			# Cura e bloqueio viram ataque (Correspondência).
			return base and color_family(id) in ["heal", "block"]
	return false


static func rarity(id: String) -> String:
	return str(get_def(id).get("rarity", "common"))


static func ids_of_rarity(r: String) -> Array:
	return DATA.keys().filter(func(x): return rarity(x) == r and not DATA[x].get("start_only", false))


## Família de cor do efeito na interface: dmg, block, dodge, mirror, heal, maxhp, sacrifice.
static func color_family(id: String) -> String:
	var fx := str(get_def(id).get("fx", "dmg"))
	match fx:
		"product", "lever", "multi", "ones", "pelt", "riddle", "top_x", "encore", "steal_sticker", "bench", "spawn_half", "drain", "feast", "antithesis":
			return "dmg"
		"synth":
			return "heal"
		"block_product", "block_hand", "block_count", "riposte", "recycle", "skin":
			return "block"
		"immune", "debuff":
			return "mirror"
		"cleanse":
			return "heal"
		"spawn_copy":
			return "sacrifice"
		"tide_out":
			return "mod"
		"mod":
			return "mod"
	return fx


## Ícone do tipo de efeito no cartão: caminho relativo a assets/icons/, sem ".png".
## Bloqueio, esquiva, espelho, revide, imune e mexida na mão reaproveitam os de status.
static func icon_key(id: String) -> String:
	var fx := str(get_def(id).get("fx", "dmg"))
	match fx:
		"heal", "maxhp", "sacrifice", "cleanse", "drain":
			return "fx/" + fx
		"feast":
			return "fx/drain"
		"synth":
			return "fx/heal"
		"encore", "lever", "spawn_half", "spawn_copy", "steal_sticker", "bench", "mod", "tide_out":
			return "fx/dice"
		"block", "block_hand", "block_product", "block_count", "recycle":
			return "status/block"
		"skin":
			return "status/skin"
		"dodge", "mirror", "riposte", "immune":
			return "status/" + fx
		"debuff":
			return "status/hand_mod"
	return "fx/dmg"


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
		"riddle":
			return v >= 1 and v <= 6 and not (v in placed)
		"seq3":
			if v in placed:
				return false
			var all := placed.duplicate()
			all.append(v)
			return int(all.max()) - int(all.min()) <= 2
	return true


## A magia está pronta para ser lançada com estes valores? tops: face mais alta, por dado.
static func complete(id: String, values: Array, tops: Array = []) -> bool:
	var flex := bool(get_def(id).get("flex", false))
	if (values.size() != dice_needed(id) and not flex) or values.is_empty() or values.size() > dice_needed(id):
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
