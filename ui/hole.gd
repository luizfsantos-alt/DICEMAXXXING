class_name Hole
extends Control
## Buraco onde um dado encaixa: fundo escuro e afundado, com a exigência escrita
## no fundo quando vazio. Usado na bandeja da mão e nos cartões de magia.

signal tapped(hole: Hole)

const FLOOR := Color(0.043, 0.039, 0.055)
const FLOOR_LO := Color(0.075, 0.067, 0.09)
const REQ_COLOR := Color(0.6, 0.57, 0.66)

var index: int = -1 ## Na bandeja: índice do dado na mão.
var req: String = "" ## Texto no fundo do buraco vazio ("≤ 3", "1").
var caption: String = "" ## Texto pequeno no buraco vazio (ex.: magia onde o dado foi).
var has_die := false
var value := 0
var element := ""
var lit := false ## Aceita o dado selecionado.
var raised := false ## Dado selecionado: levantado.
var faded := false ## Dado já lançado neste turno.
var interactive := true


func setup(px: int, i := -1) -> Hole:
	index = i
	custom_minimum_size = Vector2(px, px)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	return self


func set_interactive(on: bool) -> Hole:
	interactive = on
	mouse_filter = Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE
	return self


func set_die(v: int, el := "") -> void:
	has_die = true
	value = v
	element = el
	queue_redraw()


func clear_die() -> void:
	has_die = false
	raised = false
	faded = false
	queue_redraw()


func _gui_input(e: InputEvent) -> void:
	if interactive and e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
		tapped.emit(self)
		accept_event()


static func _sb(bg: Color, radius: int, border := 0, border_color := Color.TRANSPARENT) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	if border > 0:
		sb.set_border_width_all(border)
		sb.border_color = border_color
	return sb


func _draw() -> void:
	var s := minf(size.x, size.y)
	var o := Vector2((size.x - s) * 0.5, (size.y - s) * 0.5)
	var r := Rect2(o, Vector2(s, s))
	var rad := int(s * 0.2)
	# Afundado: borda de cima mais escura, fundo um pouco mais claro embaixo.
	draw_style_box(_sb(FLOOR, rad), r)
	var lip := maxf(3.0, s * 0.07)
	draw_style_box(_sb(FLOOR_LO, rad), Rect2(r.position + Vector2(2, lip), r.size - Vector2(4, lip + 2)))
	draw_line(r.position + Vector2(rad, s - 1), r.position + Vector2(s - rad, s - 1), Color(1, 1, 1, 0.07), 1.0)
	if lit:
		draw_style_box(_sb(Color.TRANSPARENT, rad, 3, Kit.ACCENT), r)
	var font := ThemeDB.fallback_font
	if not has_die:
		if req != "":
			var fs := int(s * 0.32)
			draw_string(font, o + Vector2(0, s * 0.5 + fs * 0.35), req, HORIZONTAL_ALIGNMENT_CENTER, s, fs, Kit.ACCENT if lit else REQ_COLOR)
		if caption != "":
			var cs := maxi(12, int(s * 0.15))
			draw_string(font, o + Vector2(2, s * 0.5 + cs * 0.35), caption, HORIZONTAL_ALIGNMENT_CENTER, s - 4, cs, REQ_COLOR)
		return
	# Dado encaixado.
	var pad := s * 0.06
	var d := Rect2(r.position + Vector2(pad, pad), Vector2(s - pad * 2, s - pad * 2))
	if raised:
		d.position.y -= s * 0.14
		draw_style_box(_sb(Color(0, 0, 0, 0.45), rad), Rect2(d.position + Vector2(0, s * 0.12), d.size))
	DieFace.draw(self, d, value, element, 0.6 if faded else 0.0)
	if raised:
		draw_style_box(_sb(Color.TRANSPARENT, int(rad * 0.85) + 2, 4, Kit.ACCENT), d.grow(3))
