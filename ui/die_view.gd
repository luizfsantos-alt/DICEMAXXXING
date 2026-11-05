class_name DieView
extends Control
## Dado 2D: face na cor do elemento (DieFace: pontinhos até 6, algarismos acima).
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
	var r := minf(size.x, size.y)
	var rect := Rect2(Vector2(3, 3), Vector2(r - 6, r - 6))
	var dim := 0.6 if state == "used" else (0.35 if state == "placed" else 0.0)
	DieFace.draw(self, rect, value, element, dim)
	if state == "selected":
		draw_rect(rect.grow(1), Kit.ACCENT, false, 5.0)
	elif state == "placed":
		draw_rect(rect.grow(1), Kit.OK, false, 3.0)
	if tag != "":
		draw_string(ThemeDB.fallback_font, Vector2(0, r * 0.9), tag, HORIZONTAL_ALIGNMENT_CENTER, r, int(r * 0.15), Kit.TEXT)
