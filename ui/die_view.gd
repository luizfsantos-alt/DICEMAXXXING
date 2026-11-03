class_name DieView
extends Control
## Dado 2D placeholder: forma por tipo (d6 quadrado, d8 losango, d10 pentágono,
## d20 triângulo), valor grande e tipo pequeno. Detecta toque e arraste.

signal tapped(view: DieView)
signal released(view: DieView, global_pos: Vector2, delta: Vector2)

const COLORS := {
	"free": Color(0.93, 0.91, 0.86),
	"selected": Color(1.0, 0.78, 0.2),
	"staged": Color(1.0, 0.6, 0.25),
	"defense": Color(0.4, 0.7, 1.0),
	"launched": Color(0.3, 0.28, 0.33),
	"attack": Color(0.93, 0.35, 0.35),
	"self": Color(0.45, 0.42, 0.5),
	"mirror": Color(0.82, 0.86, 0.92),
}

var index: int = -1
var value: int = 1
var sides: int = 6
var state: String = "free"
var interactive: bool = true
var _pressing := false
var _start := Vector2.ZERO
var _offset := Vector2.ZERO


func setup(i: int, v: int, s: int, px := 104) -> DieView:
	index = i
	value = v
	sides = s
	custom_minimum_size = Vector2(px, px)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	queue_redraw()
	return self


func set_state(s: String) -> void:
	state = s
	queue_redraw()


func _gui_input(e: InputEvent) -> void:
	if not interactive or state == "launched":
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_pressing = true
			_start = e.global_position
			_offset = Vector2.ZERO
		elif _pressing:
			_pressing = false
			var d: Vector2 = e.global_position - _start
			_offset = Vector2.ZERO
			queue_redraw()
			if d.length() < 16.0:
				tapped.emit(self)
			else:
				released.emit(self, e.global_position, d)
		accept_event()
	elif e is InputEventMouseMotion and _pressing:
		_offset = e.global_position - _start
		queue_redraw()
		accept_event()


func _draw() -> void:
	var col: Color = COLORS.get(state, COLORS.free)
	var c := size / 2.0 + _offset
	var r: float = minf(size.x, size.y) / 2.0 - 4.0
	var pts := PackedVector2Array()
	match sides:
		8:
			pts = PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
		10:
			for k in 5:
				var ang := -PI / 2.0 + k * TAU / 5.0
				pts.append(c + Vector2(cos(ang), sin(ang)) * r)
		20:
			pts = PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.95, r * 0.75), c + Vector2(-r * 0.95, r * 0.75)])
	if pts.is_empty():
		var rect := Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0)
		draw_style_box(Kit.box(col, int(r * 0.25), 0), rect)
	else:
		draw_colored_polygon(pts, col)
	var font := ThemeDB.fallback_font
	var fs := int(r * 0.95)
	var dark := Color(0.1, 0.09, 0.12)
	var top_left := c - Vector2(r, r)
	draw_string(font, top_left + Vector2(0, r + fs * 0.35), str(value), HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, fs, dark)
	draw_string(font, top_left + Vector2(0, r * 1.8), "d%d" % sides, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, int(r * 0.3), dark)
