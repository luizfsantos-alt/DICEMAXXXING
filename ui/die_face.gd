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


## Tinta automática para um corpo qualquer: escura em corpo claro, clara em corpo escuro.
## Os dados usam a tinta de Elements.LOOKS.
static func ink(body: Color) -> Color:
	return Color(0.09, 0.08, 0.11) if body.get_luminance() > 0.45 else Color(0.9, 0.9, 0.93)


static func _sb(bg: Color, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	return sb


## Desenha o dado inteiro em r: halo (se brilha) e a foto do dado 3D (DieSnapshot). Sem a
## foto (ainda não tirada, ou sem vídeo), a face 2D: corpo com chanfro e acabamento,
## valor em baixo relevo e o símbolo do elemento pequeno embaixo.
## heat: estado do brilho (0 repouso, 1 ativo); t: relógio, em segundos, para o pulso.
static func draw(ci: CanvasItem, r: Rect2, value: int, element := "", dim := 0.0, heat := 0.0, t := 0.0) -> void:
	var l := Elements.look(element)
	var body: Color = l.body
	var body2: Color = l.body2
	var finish := str(l.finish)
	if dim > 0.0:
		body = body.darkened(dim)
		body2 = body2.darkened(dim)
	var s := minf(r.size.x, r.size.y)
	var rad := int(s * 0.18)
	var glow := 0.0
	# Com vídeo, o dado é a foto do dado 3D (DieSnapshot): igual ao que estava na mesa.
	var snap := DieSnapshot.texture(value, element, heat, ci)
	if dim <= 0.0 and str(l.glow) != "":
		glow = Elements.energy(element, heat) * DiceRoll3D.glow_pulse(element, heat, t)
		_halo(ci, r.grow(-s * (1.0 - DieSnapshot.FILL) * 0.5) if snap != null else r, rad, l.emission, glow)
	if snap != null:
		var m := Color(1, 1, 1) if dim <= 0.0 else Color(1.0 - dim, 1.0 - dim, 1.0 - dim)
		ci.draw_texture_rect(snap, DieSnapshot.rect_for(r), false, m)
		return
	# Chanfro: base mais escura embaixo, topo claro em cima, face no meio.
	ci.draw_style_box(_sb(body.darkened(0.35), rad), r)
	ci.draw_style_box(_sb(body.lightened(0.25), rad), Rect2(r.position, r.size - Vector2(0, s * 0.05)))
	var inset := s * 0.035
	var face := Rect2(r.position + Vector2(inset, inset), r.size - Vector2(inset * 2, inset * 2 + s * 0.03))
	ci.draw_style_box(_sb(body, int(rad * 0.85)), face)
	_finish(ci, face, finish, body, body2, int(rad * 0.85), dim)
	var col: Color = l.ink
	if dim > 0.0:
		col = col.lerp(body, 0.35)
	var lit := str(l.glow) == "pips" and glow > 0.0
	if uses_pips(value):
		var fs := minf(face.size.x, face.size.y)
		var o := face.position + (face.size - Vector2(fs, fs)) * 0.5
		for p in PIPS[value]:
			if lit:
				_glow_dot(ci, o + p * fs, fs * PIP_R, l.emission, glow)
			_engraved_dot(ci, o + p * fs, fs * PIP_R, body, col)
	else:
		_engraved_text(ci, face, str(value), body, col)
	if element != "":
		var es := maxi(9, int(s * 0.15))
		ci.draw_string(ThemeDB.fallback_font, Vector2(face.position.x, face.end.y - es * 0.15), element,
			HORIZONTAL_ALIGNMENT_CENTER, face.size.x, es, Color(col, 0.55))


## Selos dos adesivos sobre o dado em r (bolsa, coluna, cartões, voo): bolinha vermelha
## com "+2" (+2 por adesivo) no alto à direita e bolinha dourada (adesivo de ouro; o número
## com mais de um) embaixo à esquerda. dim: dado apagado (já usado).
const STICKER_RED := Color("#d8322c")
const GOLD := Color("#f2c230")


static func marks(ci: CanvasItem, r: Rect2, stickers: int, gold: int, dim := 0.0) -> void:
	var s := minf(r.size.x, r.size.y)
	var k := 1.0 - clampf(dim, 0.0, 0.8)
	var rr := s * 0.2
	if stickers > 0:
		var c := Vector2(r.end.x - rr * 0.95, r.position.y + rr * 0.95)
		_dot(ci, c, rr, STICKER_RED, k)
		var t := "+%d" % (Config.STICKER_PLUS * stickers)
		var fs := int(rr * (0.9 if t.length() <= 2 else 0.7))
		var font := Kit.num_font()
		var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		ci.draw_string(font, c + Vector2(-w * 0.5, fs * 0.36), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, k))
	if gold > 0:
		var c2 := Vector2(r.position.x + rr * 0.95, r.end.y - rr * 0.95)
		_dot(ci, c2, rr * 0.85, GOLD, k)
		if gold > 1:
			var fs2 := int(rr * 0.9)
			var font2 := Kit.num_font()
			var t2 := str(gold)
			var w2 := font2.get_string_size(t2, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2).x
			ci.draw_string(font2, c2 + Vector2(-w2 * 0.5, fs2 * 0.36), t2, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, Color(0.3, 0.18, 0.0, k))


## Bolinha com contorno escuro e um brilho no alto, para destacar do dado.
static func _dot(ci: CanvasItem, c: Vector2, rr: float, col: Color, k: float) -> void:
	ci.draw_circle(c + Vector2(0, rr * 0.08), rr * 1.08, Color(0, 0, 0, 0.55 * k))
	ci.draw_circle(c, rr, Color(col.darkened(0.35), k))
	ci.draw_circle(c, rr * 0.86, Color(col, k))
	ci.draw_circle(c - Vector2(rr * 0.3, rr * 0.32), rr * 0.25, Color(1, 1, 1, 0.35 * k))


## Halo em volta do dado aceso: sombra colorida do StyleBox, maior com mais energia.
static func _halo(ci: CanvasItem, r: Rect2, rad: int, col: Color, energy: float) -> void:
	if energy <= 0.0:
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(col, 0.0)
	sb.set_corner_radius_all(rad)
	sb.shadow_color = Color(col, clampf(0.25 + energy * 0.25, 0.0, 0.85))
	sb.shadow_size = int(minf(r.size.x, r.size.y) * (0.06 + energy * 0.05))
	ci.draw_style_box(sb, r)


## Pontinho aceso: brilho em volta do buraco (por baixo da tinta).
static func _glow_dot(ci: CanvasItem, c: Vector2, rr: float, col: Color, energy: float) -> void:
	var a := clampf(energy * 0.35, 0.0, 0.8)
	ci.draw_circle(c, rr * (1.5 + energy * 0.35), Color(col, a * 0.35))
	ci.draw_circle(c, rr * 1.2, Color(col, a))


## Acabamento por cima da face (mesmas ideias das texturas do Dice3D).
static func _finish(ci: CanvasItem, face: Rect2, finish: String, body: Color, body2: Color, rad: int, dim: float) -> void:
	var p := face.position
	var w := face.size.x
	var h := face.size.y
	var k := 1.0 - dim
	match finish:
		"marfim":
			ci.draw_circle(p + Vector2(w * 0.28, h * 0.22), w * 0.2, Color(1, 1, 1, 0.12 * k))
		"vidro", "ceroso":
			# Miolo claro (luz presa dentro) e um reflexo pequeno no alto.
			for i in 4:
				ci.draw_circle(p + face.size * 0.5, w * (0.42 - i * 0.09), Color(body2, 0.14 * k))
			if finish == "vidro":
				ci.draw_circle(p + Vector2(w * 0.27, h * 0.17), w * 0.07, Color(1, 1, 1, 0.55 * k))
				ci.draw_style_box(_border(Color(1, 1, 1, 0.35 * k), rad, 1), face)
		"espelho":
			# Faixa de reflexo na diagonal e borda chanfrada clara.
			var band := PackedVector2Array([p + Vector2(w * 0.55, 0), p + Vector2(w * 0.8, 0), p + Vector2(w * 0.25, h), p + Vector2(0, h)])
			_poly(ci, _clip(band, face), Color(body2, 0.35 * k))
			ci.draw_style_box(_border(Color(1, 1, 1, 0.45 * k), rad, 2), face)
		"fosco":
			# Arranhões finos.
			var rng := RandomNumberGenerator.new()
			rng.seed = 11
			for i in 7:
				var a := p + Vector2(rng.randf_range(0.1, 0.9) * w, rng.randf_range(0.1, 0.9) * h)
				var d := Vector2(rng.randf_range(0.08, 0.22) * w, rng.randf_range(-0.06, 0.06) * h)
				ci.draw_line(a, a + d, Color(1, 1, 1, 0.13 * k), maxf(1.0, w * 0.01))
		"fibroso":
			# Fibras quase paralelas.
			var n := 14
			for i in n:
				var y := p.y + h * (i + 0.5) / n
				var off := h * 0.06 * sin(i * 1.7)
				var c := Color(1, 1, 1, 0.12 * k) if i % 2 == 0 else Color(0, 0, 0, 0.1 * k)
				ci.draw_line(Vector2(p.x + w * 0.06, y + off), Vector2(p.x + w * 0.94, y - off * 0.5 - h * 0.04), c, maxf(1.0, h * 0.012))
		"ferrugem":
			# Manchas de ferrugem e arestas gastas mostrando o metal.
			var rng := RandomNumberGenerator.new()
			rng.seed = 5
			for i in 6:
				var c := p + Vector2(rng.randf_range(0.2, 0.8) * w, rng.randf_range(0.2, 0.8) * h)
				var tone := body.lightened(0.18) if i % 2 == 0 else body.darkened(0.25)
				ci.draw_circle(c, w * rng.randf_range(0.08, 0.16), Color(tone, 0.6 * k + 0.2))
			ci.draw_style_box(_border(Color(body2, 0.75 * k + 0.1), rad, maxi(2, int(w * 0.035))), face)
		"anodizado":
			# Faixas furta-cor do titânio anodizado (magenta, azul, dourado).
			var mid := Color("#3d6fe0") ## Azul do meio do furta-cor.
			var cols := [body, mid, body2, mid]
			for i in 4:
				var a0 := 0.18 + i * 0.28
				var poly := PackedVector2Array([p + Vector2(w * (a0 - 0.2), 0), p + Vector2(w * (a0 + 0.08), 0),
					p + Vector2(w * (a0 - 0.32), h), p + Vector2(w * (a0 - 0.6), h)])
				_poly(ci, _clip(poly, face), Color(cols[i], 0.75 * k))
			ci.draw_style_box(_border(Color(1, 1, 1, 0.35 * k), rad, 2), face)
		"grafite":
			var band := PackedVector2Array([p + Vector2(w * 0.35, 0), p + Vector2(w * 0.65, 0), p + Vector2(w * 0.35, h), p + Vector2(w * 0.05, h)])
			_poly(ci, _clip(band, face), Color(body2, 0.55 * k))


static func _poly(ci: CanvasItem, poly: PackedVector2Array, col: Color) -> void:
	if poly.size() >= 3:
		ci.draw_colored_polygon(poly, col)


static func _border(col: Color, radius: int, width: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(width)
	sb.border_color = col
	sb.anti_aliasing = true
	return sb


## Recorta um polígono na face (com uma folga para não passar das bordas arredondadas).
static func _clip(poly: PackedVector2Array, face: Rect2) -> PackedVector2Array:
	var f := face.grow(-face.size.x * 0.06)
	var box := PackedVector2Array([f.position, Vector2(f.end.x, f.position.y), f.end, Vector2(f.position.x, f.end.y)])
	var out := Geometry2D.intersect_polygons(poly, box)
	return out[0] if not out.is_empty() else PackedVector2Array()


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
