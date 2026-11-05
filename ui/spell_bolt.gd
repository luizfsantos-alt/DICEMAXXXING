class_name SpellBolt
extends Control
## Efeito de magia: uma bola de luz que sai do cartão e voa em arco até a foto do alvo,
## deixando um rastro, e estoura num anel ao chegar. A cor diz o tipo: verde cura,
## vermelho dano, azul outros efeitos (DuelScreen.FX_COLORS).

signal arrived

const TRAIL := 14

var from := Vector2.ZERO
var to := Vector2.ZERO
var color := Color.WHITE
var duration := 0.34
var t := 0.0
var _ctrl := Vector2.ZERO ## Ponto de controle do arco.
var _trail: Array[Vector2] = []
var _burst := -1.0 ## Tempo do estouro (−1: ainda voando).
var _sparks: Array = [] ## [{p, v}] faíscas do estouro.


func setup(a: Vector2, b: Vector2, col: Color, dur := 0.34) -> SpellBolt:
	from = a
	to = b
	color = col
	duration = dur
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mid := (a + b) * 0.5
	var d := b - a
	var n := Vector2(-d.y, d.x).normalized()
	# Arco para cima, mais alto em viagens longas.
	if n.y > 0.0:
		n = -n
	_ctrl = mid + n * clampf(d.length() * 0.28, 30.0, 160.0)
	return self


static func bezier(a: Vector2, c: Vector2, b: Vector2, k: float) -> Vector2:
	var u := 1.0 - k
	return a * u * u + c * 2.0 * u * k + b * k * k


func head() -> Vector2:
	return bezier(from, _ctrl, to, ease(clampf(t / duration, 0.0, 1.0), 1.6))


func _process(delta: float) -> void:
	if _burst < 0.0:
		t += delta
		_trail.push_front(head())
		if _trail.size() > TRAIL:
			_trail.pop_back()
		if t >= duration:
			_burst = 0.0
			for k in 10:
				var a := TAU * k / 10.0 + randf() * 0.3
				_sparks.append({"p": to, "v": Vector2(cos(a), sin(a)) * randf_range(120.0, 220.0)})
			arrived.emit.call_deferred() ## Fora do _process: quem espera pode liberar a tela.
	else:
		_burst += delta
		if _trail.size() > 0:
			_trail.pop_back()
		for s in _sparks:
			s.p += s.v * delta
			s.v *= 0.9
		if _burst > 0.35:
			queue_free()
	queue_redraw()


func _draw() -> void:
	var n := _trail.size()
	for k in n:
		var f := 1.0 - float(k) / TRAIL
		draw_circle(_trail[k], 4.0 + 11.0 * f, Color(color.r, color.g, color.b, 0.35 * f))
	if _burst < 0.0:
		var p := head()
		draw_circle(p, 24.0, Color(color.r, color.g, color.b, 0.25))
		draw_circle(p, 15.0, Color(color.r, color.g, color.b, 0.7))
		draw_circle(p, 7.0, color.lightened(0.7))
	else:
		var k := _burst / 0.35
		var a := 1.0 - k
		draw_arc(to, 14.0 + 60.0 * k, 0.0, TAU, 32, Color(color.r, color.g, color.b, a), 4.0 * a + 1.0)
		draw_circle(to, 26.0 * a, Color(color.r, color.g, color.b, 0.5 * a))
		for s in _sparks:
			draw_circle(s.p, 3.0 * a + 0.5, Color(color.lightened(0.4).r, color.lightened(0.4).g, color.lightened(0.4).b, a))
