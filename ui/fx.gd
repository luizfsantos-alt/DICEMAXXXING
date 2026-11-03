class_name Fx
extends Control
## Efeitos visuais desenhados por código (sem arte): elos de corrente, X de anulado,
## espinhos, anel de brilho. Vivem na camada de efeitos da tela de duelo.

var kind := "ring"
var color := Color.WHITE
var a := Vector2.ZERO ## Para "chain": pontos em coordenadas locais.
var b := Vector2.ZERO
var broken := false
var ring_r := 52.0


static func make(k: String, rect: Rect2, c: Color) -> Fx:
	var f := Fx.new()
	f.kind = k
	f.color = c
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f.position = rect.position
	f.size = rect.size
	return f


## Corrente entre dois pontos globais (a camada de efeitos ocupa a tela toda).
static func chain(from: Vector2, to: Vector2, radius: float, is_broken := false) -> Fx:
	var pad := Vector2(radius + 8.0, radius + 8.0)
	var lo := Vector2(minf(from.x, to.x), minf(from.y, to.y)) - pad
	var hi := Vector2(maxf(from.x, to.x), maxf(from.y, to.y)) + pad
	var f := make("chain", Rect2(lo, hi - lo), Color(0.78, 0.78, 0.82))
	f.ring_r = radius
	f.a = from - lo
	f.b = to - lo
	f.broken = is_broken
	return f


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0
	match kind:
		"ring":
			draw_arc(c, r - 3.0, 0.0, TAU, 40, color, 6.0)
		"cross":
			var m := r * 0.75
			draw_line(c + Vector2(-m, -m), c + Vector2(m, m), color, 8.0)
			draw_line(c + Vector2(m, -m), c + Vector2(-m, m), color, 8.0)
		"spikes":
			var n := 12
			for k in n:
				var ang := k * TAU / n
				var d := Vector2(cos(ang), sin(ang))
				var side := Vector2(-d.y, d.x) * 9.0
				var base := c + d * (r - 14.0)
				draw_colored_polygon(PackedVector2Array([base + side, base - side, c + d * (r + 6.0)]), color)
		"chain":
			_draw_links(a, b)
			draw_arc(a, ring_r, 0.0, TAU, 32, color, 5.0)
			draw_arc(b, ring_r, 0.0, TAU, 32, color, 5.0)


func _draw_links(p: Vector2, q: Vector2) -> void:
	var dist := p.distance_to(q)
	if dist < 1.0:
		return
	var dir := (q - p) / dist
	var step := 26.0
	var k := 0
	var t := 0.0
	while t < dist:
		var center := p + dir * (t + step / 2.0)
		var gap := broken and absf(t + step / 2.0 - dist / 2.0) < step
		if not gap:
			var rot := dir.angle() + (PI / 2.0 if k % 2 == 1 else 0.0)
			var pts := PackedVector2Array()
			for s in 14:
				var ang := s * TAU / 14.0
				pts.append(center + Vector2(cos(ang) * 13.0, sin(ang) * 7.0).rotated(rot))
			pts.append(pts[0])
			draw_polyline(pts, color, 4.0)
		t += step
		k += 1
