class_name Elements
extends RefCounted
## Elementos da fatia vertical (docs/SPEC_v3.md §4.1). Química é tempero:
## cada um tem um efeito de uma linha.

const ALL := ["H", "Os", "U", "Na", "Hg", "Pb"]
const SHOP := ["H", "Os", "U", "Na", "Hg"] ## Chumbo só vem dos inimigos.
const COLORS := {
	"": Color(0.93, 0.91, 0.86),
	"H": Color(0.75, 0.9, 1.0),
	"Os": Color(0.55, 0.6, 0.75),
	"U": Color(0.55, 0.95, 0.35),
	"Na": Color(1.0, 0.62, 0.3),
	"Hg": Color(0.82, 0.84, 0.9),
	"Pb": Color(0.42, 0.42, 0.48),
}
const SOLITARY_BAG := 8 ## Hidrogênio: ×3 com bolsa deste tamanho ou menor.


static func apply(d: Die, el: String) -> void:
	d.element = el
	match el:
		"U":
			# Valor alto: as faces começam em 3.
			for i in 6:
				d.faces[i] = maxi(int(d.faces[i]), i + 3)
		"Pb":
			d.faces = [1, 1, 1, 2, 2, 3]
			d.stickers = [0, 0, 0, 0, 0, 0]
			d.locked = [true, true, true, false, false, false]


static func lead() -> Die:
	return Die.with_element("Pb")
