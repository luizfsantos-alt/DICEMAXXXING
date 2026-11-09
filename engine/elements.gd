class_name Elements
extends RefCounted
## Elementos e substâncias (docs/SPEC_v3.md §4.1, docs/PERSONAGENS.md §3.2 e §5).
## Química é tempero: cada um tem um efeito de uma linha.

const ALL := ["H", "Os", "U", "Na", "Hg", "Pb", "Am", "C", "Fe", "Cs", "Au"]
const SHOP := ["H", "Os", "U", "Na", "Hg", "Am", "C", "Cs", "Au"] ## Chumbo só vem dos inimigos (e do Metalurgista); Ferro, só do Bárbaro.
## Raridade (docs/RARIDADE.md §4). Chumbo e Ferro ficam fora (não são sorteados): contam como Comum.
const RARITY := {
	"common": ["Na", "Am", "C", "Au"],
	"uncommon": ["U", "Hg", "Cs"],
	"rare": ["H", "Os"],
}
## Visual de cada dado (docs/DADOS_VISUAL.md). Três camadas:
## - cor: body (corpo), body2 (miolo do vidro / reflexo do espelho), ink (pontinhos e
##   algarismos) e accent (texto do elemento sobre o fundo escuro da interface);
## - acabamento: finish (marfim, vidro, espelho, fosco, fibroso, ferrugem, grafite,
##   ceroso), rough, metal, coat (clearcoat), alpha, rim;
## - brilho: glow ("" nenhum, "pips" só os pontinhos, "body" o corpo, "rim" as
##   arestas), emission e energy (em repouso). O brilho cresce com o estado (heat).
const LOOKS := {
	"": {"body": Color("#efe6d2"), "body2": Color("#fbf6ea"), "ink": Color("#2a2230"), "accent": Color("#efe6d2"),
		"finish": "marfim", "rough": 0.5, "metal": 0.0, "coat": 0.3, "alpha": 1.0, "rim": 0.0,
		"glow": "", "emission": Color.BLACK, "energy": 0.0},
	"H": {"body": Color("#5b2fb0"), "body2": Color("#8f62dc"), "ink": Color("#ffffff"), "accent": Color("#d9a6ff"),
		"finish": "vidro", "rough": 0.12, "metal": 0.0, "coat": 1.0, "alpha": 0.95, "rim": 0.25,
		"glow": "pips", "emission": Color("#d58cff"), "energy": 0.2},
	"Os": {"body": Color("#2f3d63"), "body2": Color("#6d84c4"), "ink": Color("#cfd8f0"), "accent": Color("#8fa8ff"),
		"finish": "espelho", "rough": 0.16, "metal": 0.8, "coat": 0.0, "alpha": 1.0, "rim": 0.3,
		"glow": "", "emission": Color.BLACK, "energy": 0.0},
	"U": {"body": Color("#5fcf2a"), "body2": Color("#93e25f"), "ink": Color("#0f2a06"), "accent": Color("#8cf259"),
		"finish": "vidro", "rough": 0.25, "metal": 0.0, "coat": 0.6, "alpha": 0.95, "rim": 0.3,
		"glow": "body", "emission": Color("#7cff3a"), "energy": 0.15},
	"Na": {"body": Color("#e8780f"), "body2": Color("#ffb35c"), "ink": Color("#3a1600"), "accent": Color("#ff9e4d"),
		"finish": "ceroso", "rough": 0.55, "metal": 0.0, "coat": 0.0, "alpha": 1.0, "rim": 0.6,
		"glow": "rim", "emission": Color("#ff6a00"), "energy": 0.5},
	"Hg": {"body": Color("#dfe5ee"), "body2": Color("#ffffff"), "ink": Color("#1a1f2a"), "accent": Color("#d1d6e6"),
		"finish": "espelho", "rough": 0.14, "metal": 0.7, "coat": 0.4, "alpha": 1.0, "rim": 0.2,
		"glow": "", "emission": Color.BLACK, "energy": 0.0},
	"Pb": {"body": Color("#555a60"), "body2": Color("#555a60"), "ink": Color("#c4c9cf"), "accent": Color("#9aa0a8"),
		"finish": "fosco", "rough": 0.85, "metal": 0.3, "coat": 0.0, "alpha": 1.0, "rim": 0.0,
		"glow": "", "emission": Color.BLACK, "energy": 0.0},
	"Am": {"body": Color("#d9b44a"), "body2": Color("#e8c96a"), "ink": Color("#2b2410"), "accent": Color("#e3c25e"),
		"finish": "fibroso", "rough": 0.9, "metal": 0.0, "coat": 0.0, "alpha": 1.0, "rim": 0.0,
		"glow": "", "emission": Color.BLACK, "energy": 0.0},
	"C": {"body": Color("#18181c"), "body2": Color("#34343c"), "ink": Color("#f4f8ff"), "accent": Color("#b8c4d6"),
		"finish": "grafite", "rough": 0.3, "metal": 0.5, "coat": 0.5, "alpha": 1.0, "rim": 0.0,
		"glow": "pips", "emission": Color("#9fd8ff"), "energy": 0.3},
	"Fe": {"body": Color("#7a4128"), "body2": Color("#8f8f96"), "ink": Color("#f0c8a8"), "accent": Color("#c7764e"),
		"finish": "ferrugem", "rough": 0.85, "metal": 0.2, "coat": 0.0, "alpha": 1.0, "rim": 0.0,
		"glow": "", "emission": Color.BLACK, "energy": 0.0},
	# Césio: o brilho azul do cloreto de césio (o pó de Goiânia).
	"Cs": {"body": Color("#1d4fc4"), "body2": Color("#4f8dff"), "ink": Color("#eaf3ff"), "accent": Color("#6fb4ff"),
		"finish": "vidro", "rough": 0.2, "metal": 0.0, "coat": 0.7, "alpha": 0.95, "rim": 0.35,
		"glow": "body", "emission": Color("#3d9bff"), "energy": 0.3},
	# Ouro: metal polido, dourado quente (bem mais saturado que o Amianto).
	"Au": {"body": Color("#e0a514"), "body2": Color("#ffe27a"), "ink": Color("#3a2604"), "accent": Color("#ffcf3f"),
		"finish": "espelho", "rough": 0.18, "metal": 0.85, "coat": 0.5, "alpha": 1.0, "rim": 0.2,
		"glow": "", "emission": Color.BLACK, "energy": 0.0},
}
## Energia máxima do brilho com o estado ativo (heat = 1).
## Contidos de propósito: forte demais, o brilho estoura e o valor deixa de ser lido.
const ENERGY_ACTIVE := {"H": 0.7, "U": 0.5, "Na": 1.0, "C": 0.9, "Cs": 0.9}
## Cor do elemento em texto e rótulos (o accent de LOOKS: legível sobre o fundo escuro).
const COLORS := {
	"": Color("#efe6d2"),
	"H": Color("#d9a6ff"),
	"Os": Color("#8fa8ff"),
	"U": Color("#8cf259"),
	"Na": Color("#ff9e4d"),
	"Hg": Color("#d1d6e6"),
	"Pb": Color("#9aa0a8"),
	"Am": Color("#e3c25e"),
	"C": Color("#b8c4d6"),
	"Fe": Color("#c7764e"),
	"Cs": Color("#6fb4ff"),
	"Au": Color("#ffcf3f"),
}
const SOLITARY_BAG := 6 ## Hidrogênio: ×3 com bolsa deste tamanho ou menor (a inicial tem 8).
const SOLITARY_MULT := 3
## Valores em uso (o simulador troca para testar; o jogo usa os de cima).
static var solitary_bag := SOLITARY_BAG
static var solitary_mult := SOLITARY_MULT
const ASBESTOS_PLUS := 3 ## Amianto: +3 em todas as faces.
const CHAIN_STEP := 2 ## Carbono: + isto para cada outro Carbono na mão.


static func apply(d: Die, el: String) -> void:
	d.element = el
	match el:
		"U":
			# Valor alto: as faces começam em 3.
			for i in 6:
				d.faces[i] = maxi(int(d.faces[i]), i + 3)
		"Am":
			# Fibroso: +3 em todas as faces (4 a 9).
			for i in 6:
				d.faces[i] = int(d.faces[i]) + ASBESTOS_PLUS
		"Fe":
			# Maciço: sempre 3 (as faces podem ser editadas e receber adesivos).
			d.faces = [3, 3, 3, 3, 3, 3]
		"Pb":
			d.faces = [1, 1, 1, 2, 2, 3]
			d.stickers = [0, 0, 0, 0, 0, 0]
			d.gold = [0, 0, 0, 0, 0, 0]
			d.locked = [true, true, true, false, false, false]


static func lead() -> Die:
	return Die.with_element("Pb")


static func rarity(el: String) -> String:
	for r in RARITY:
		if el in RARITY[r]:
			return r
	return "common"


## Hidrogênio ligado: vale ×solitary_mult com a bolsa de solitary_bag dados ou menos.
static func solitary(f: Fighter, d: Die) -> bool:
	return d != null and d.element == "H" and f.bag.size() <= solitary_bag


## Carbono (Cadeia): bônus de cada Carbono da mão, + CHAIN_STEP por outro Carbono nela.
## Conta só os dados rolados: partes da Sangria, cópias e dados gastos não são elos (a
## cadeia fica fixa na rolagem; rolar de novo usa a que o dado guardou em "chain").
static func chain_bonus(f: Fighter) -> int:
	var n := 0
	for e in f.hand:
		var d := f.die_of(e)
		if int(e.get("spawn", -1)) >= 0 or int(e.get("spent", -1)) >= 0:
			continue
		if d != null and d.element == "C":
			n += 1
	return maxi(0, n - 1) * CHAIN_STEP


static func look(el: String) -> Dictionary:
	return LOOKS.get(el, LOOKS[""])


## Energia do brilho para um estado (heat de 0, repouso, a 1, ativo). 0 se não brilha.
static func energy(el: String, heat := 0.0) -> float:
	var l := look(el)
	if str(l.glow) == "":
		return 0.0
	return lerpf(float(l.energy), float(ENERGY_ACTIVE.get(el, l.energy)), clampf(heat, 0.0, 1.0))


## Estado do dado d na mão de f, de 0 a 1 (docs/DADOS_VISUAL.md, "Brilho como estado"):
## Hidrogênio com o Solitário valendo, Carbono pelo tamanho da cadeia, Urânio parado
## na mão (vai envenenar se não for usado; idle = ainda não foi posto numa magia) e
## Césio posto numa magia (vai irradiar o inimigo).
static func heat(f: Fighter, d: Die, idle := true) -> float:
	if d == null:
		return 0.0
	match d.element:
		"H":
			return 1.0 if solitary(f, d) else 0.0
		"C":
			return clampf(float(chain_bonus(f)) / CHAIN_STEP / 3.0, 0.0, 1.0)
		"U":
			return 1.0 if idle else 0.0
		"Cs":
			return 0.0 if idle else 1.0 ## Posto numa magia: vai irradiar.
	return 0.0
