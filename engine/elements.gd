class_name Elements
extends RefCounted
## Elementos e substâncias (docs/SPEC_v3.md §4.1, docs/PERSONAGENS.md §3.2 e §5).
## Química é tempero: cada um tem um efeito de uma linha.

const ALL := ["H", "Os", "U", "Na", "Hg", "Pb", "Am"]
const SHOP := ["H", "Os", "U", "Na", "Hg", "Am"] ## Chumbo só vem dos inimigos (e do Metalurgista).
## Raridade (docs/RARIDADE.md §4). O Chumbo fica fora: para o Metalurgista, conta como Comum.
const RARITY := {
	"common": ["Na", "Am"],
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
}
const SOLITARY_BAG := 8 ## Hidrogênio: ×3 com bolsa deste tamanho ou menor.
const ASBESTOS_PLUS := 3 ## Amianto: +3 em todas as faces.


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
