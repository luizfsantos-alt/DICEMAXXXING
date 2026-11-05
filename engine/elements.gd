class_name Elements
extends RefCounted
## Elementos e substâncias (docs/SPEC_v3.md §4.1, docs/PERSONAGENS.md §3.2 e §5).
## Química é tempero: cada um tem um efeito de uma linha.

const ALL := ["H", "Os", "U", "Na", "Hg", "Pb", "Am", "C"]
const SHOP := ["H", "Os", "U", "Na", "Hg", "Am", "C"] ## Chumbo só vem dos inimigos (e do Metalurgista).
## Raridade (docs/RARIDADE.md §4). O Chumbo fica fora: para o Metalurgista, conta como Comum.
const RARITY := {
	"common": ["Na", "Am", "C"],
	"uncommon": ["U", "Hg"],
	"rare": ["H", "Os"],
}
const COLORS := {
	"": Color(0.93, 0.91, 0.86),
	"H": Color(0.75, 0.9, 1.0),
	"Os": Color(0.55, 0.6, 0.75),
	"U": Color(0.55, 0.95, 0.35),
	"Na": Color(1.0, 0.62, 0.3),
	"Hg": Color(0.82, 0.84, 0.9),
	"Pb": Color(0.42, 0.42, 0.48),
	"Am": Color(0.85, 0.82, 0.62),
	"C": Color(0.24, 0.23, 0.22), ## Grafite.
}
const SOLITARY_BAG := 8 ## Hidrogênio: ×3 com bolsa deste tamanho ou menor.
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
		"Pb":
			d.faces = [1, 1, 1, 2, 2, 3]
			d.stickers = [0, 0, 0, 0, 0, 0]
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
static func chain_bonus(f: Fighter) -> int:
	var n := 0
	for e in f.hand:
		var d := f.die_of(e)
		if d != null and d.element == "C":
			n += 1
	return maxi(0, n - 1) * CHAIN_STEP
