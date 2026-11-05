class_name DieFace
extends RefCounted
## Face de dado desenhada em 2D (bandeja, cartões, voo). De 1 a 6, pontinhos; os
## demais valores, algarismos. Os dois em baixo relevo: a parede de cima/esquerda do
## buraco fica na sombra e a borda de baixo/direita pega a luz.
## O dado 3D (Dice3D) usa a mesma regra nas texturas.

## Centros dos pontinhos (fração da face), do 1 ao 6.
const PIPS := {
	1: [Vector2(0.5, 0.5)],
	2: [Vector2(0.27, 0.27), Vector2(0.73, 0.73)],
	3: [Vector2(0.27, 0.27), Vector2(0.5, 0.5), Vector2(0.73, 0.73)],
	4: [Vector2(0.27, 0.27), Vector2(0.73, 0.27), Vector2(0.27, 0.73), Vector2(0.73, 0.73)],
	5: [Vector2(0.27, 0.27), Vector2(0.73, 0.27), Vector2(0.5, 0.5), Vector2(0.27, 0.73), Vector2(0.73, 0.73)],
	6: [Vector2(0.27, 0.25), Vector2(0.73, 0.25), Vector2(0.27, 0.5), Vector2(0.73, 0.5), Vector2(0.27, 0.75), Vector2(0.73, 0.75)],
}
const PIP_R := 0.095 ## Raio do pontinho (fração da face).


static func uses_pips(v: int) -> bool:
	return v >= 1 and v <= 6


## Cor da tinta do baixo relevo: escura em dado claro, clara em dado escuro (Chumbo).
static func ink(body: Color) -> Color:
	return Color(0.09, 0.08, 0.11) if body.get_luminance() > 0.45 else Color(0.9, 0.9, 0.93)


static func _sb(bg: Color, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	return sb


## Desenha o dado inteiro em r: corpo com chanfro, valor em baixo relevo e o símbolo
## do elemento pequeno embaixo.
static func draw(ci: CanvasItem, r: Rect2, value: int, element := "", dim := 0.0) -> void:
	var body: Color = Elements.COLORS.get(element, Elements.COLORS[""])
	if dim > 0.0:
		body = body.darkened(dim)
	var s := minf(r.size.x, r.size.y)
	var rad := int(s * 0.18)
	# Chanfro: base mais escura embaixo, topo claro em cima, face no meio.
	ci.draw_style_box(_sb(body.darkened(0.35), rad), r)
	ci.draw_style_box(_sb(body.lightened(0.25), rad), Rect2(r.position, r.size - Vector2(0, s * 0.05)))
	var inset := s * 0.035
	var face := Rect2(r.position + Vector2(inset, inset), r.size - Vector2(inset * 2, inset * 2 + s * 0.03))
	ci.draw_style_box(_sb(body, int(rad * 0.85)), face)
	var col := ink(body)
	if dim > 0.0:
		col = col.lerp(body, 0.35)
	if uses_pips(value):
		var fs := minf(face.size.x, face.size.y)
		var o := face.position + (face.size - Vector2(fs, fs)) * 0.5
		for p in PIPS[value]:
			_engraved_dot(ci, o + p * fs, fs * PIP_R, body, col)
	else:
		_engraved_text(ci, face, str(value), body, col)
	if element != "":
		var es := maxi(9, int(s * 0.15))
		ci.draw_string(ThemeDB.fallback_font, Vector2(face.position.x, face.end.y - es * 0.15), element,
			HORIZONTAL_ALIGNMENT_CENTER, face.size.x, es, Color(col, 0.55))


## Pontinho escavado: borda de luz embaixo/direita, sombra em cima/esquerda, fundo.
static func _engraved_dot(ci: CanvasItem, c: Vector2, rr: float, body: Color, col: Color) -> void:
	var e := maxf(1.0, rr * 0.16)
	ci.draw_circle(c + Vector2(e, e), rr, body.lightened(0.55))
	ci.draw_circle(c, rr, col.darkened(0.25) if col.get_luminance() < 0.5 else body.darkened(0.55))
	ci.draw_circle(c + Vector2(e, e) * 0.55, rr * 0.8, col)


static func _engraved_text(ci: CanvasItem, face: Rect2, txt: String, body: Color, col: Color) -> void:
	var font := ThemeDB.fallback_font
	var w := face.size.x
	var fs := int(minf(face.size.y * 0.62, w * (0.62 if txt.length() <= 1 else 1.05 / txt.length())))
	var base := face.position + Vector2(0, face.size.y * 0.47 + fs * 0.36)
	var e := maxf(1.0, fs * 0.05)
	ci.draw_string(font, base + Vector2(e, e), txt, HORIZONTAL_ALIGNMENT_CENTER, w, fs, body.lightened(0.55))
	ci.draw_string(font, base - Vector2(e, e) * 0.5, txt, HORIZONTAL_ALIGNMENT_CENTER, w, fs, col.darkened(0.3) if col.get_luminance() < 0.5 else body.darkened(0.55))
	ci.draw_string(font, base, txt, HORIZONTAL_ALIGNMENT_CENTER, w, fs, col)
