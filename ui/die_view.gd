class_name DieView
extends Control
## Dado 2D placeholder: quadrado na cor do elemento, valor grande e símbolo pequeno.
## Estados: free, selected, placed, used, enemy.

signal tapped(view: DieView)

var index: int = -1
var value: int = 1
var element: String = ""
var state: String = "free"
var interactive: bool = true
var tag: String = "" ## Texto pequeno extra (ex.: magia onde está posto).


func setup(i: int, v: int, el: String, px := 92) -> DieView:
	index = i
	value = v
	element = el
	custom_minimum_size = Vector2(px, px)
	size = custom_minimum_size
	pivot_offset = size / 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	queue_redraw()
	return self


func set_state(s: String, t := "") -> void:
	state = s
	tag = t
	queue_redraw()


func _gui_input(e: InputEvent) -> void:
	if not interactive:
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
		tapped.emit(self)
		accept_event()


func pulse() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tw.tween_property(self, "scale", Vector2.ONE, 0.15)


func _draw() -> void:
	var col: Color = Elements.COLORS.get(element, Elements.COLORS[""])
	var r := minf(size.x, size.y)
	var rect := Rect2(Vector2(3, 3), Vector2(r - 6, r - 6))
	if state == "used":
		col = col.darkened(0.6)
	elif state == "placed":
		col = col.darkened(0.35)
	draw_style_box(Kit.box(col, int(r * 0.18), 0), rect)
	if state == "selected":
		draw_rect(rect.grow(1), Kit.ACCENT, false, 5.0)
	elif state == "placed":
		draw_rect(rect.grow(1), Kit.OK, false, 3.0)
	var font := ThemeDB.fallback_font
	var dark := Color(0.1, 0.09, 0.12)
	var txt := str(value)
	var fs := int(r * (0.5 if txt.length() <= 2 else 0.36))
	draw_string(font, Vector2(0, r * 0.5 + fs * 0.35), txt, HORIZONTAL_ALIGNMENT_CENTER, r, fs, dark)
	if element != "":
		draw_string(font, Vector2(r * 0.1, r * 0.26), element, HORIZONTAL_ALIGNMENT_LEFT, -1, int(r * 0.2), dark)
	if tag != "":
		draw_string(font, Vector2(0, r * 0.9), tag, HORIZONTAL_ALIGNMENT_CENTER, r, int(r * 0.15), dark)
