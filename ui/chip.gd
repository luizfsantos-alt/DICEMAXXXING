class_name Chip
extends Control
## Quadradinho de passiva/item (ou medalha redonda) com sigla e cor por categoria.
## Placeholder até haver ícones. Tocar emite `pressed`; `pulse()` pisca quando age.

signal pressed(chip: Chip)

const SIZE := 52

var id := ""
var abbr := ""
var color := Kit.PANEL_HI
var is_round := false
var empty := false
var broken := false


static func make(item_id: String, as_medal := false) -> Chip:
	var c := Chip.new()
	c.id = item_id
	c.is_round = as_medal
	c.empty = item_id == ""
	c.abbr = Texts.abbr(item_id) if not c.empty else ""
	c.color = category_color(item_id)
	c.custom_minimum_size = Vector2(SIZE, SIZE)
	c.size = c.custom_minimum_size
	c.pivot_offset = c.size / 2.0
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE if c.empty else Control.MOUSE_FILTER_STOP
	return c


static func category_color(item_id: String) -> Color:
	if item_id == "":
		return Color(0.25, 0.23, 0.3)
	if item_id == "DEATH_DEFY":
		return Kit.DANGER
	if item_id.begins_with("DF"):
		return Kit.SHIELD
	if item_id.begins_with("DD"):
		return Color(0.95, 0.8, 0.25)
	return Kit.ACCENT.lerp(Color(0.85, 0.6, 0.15), 0.4) ## Personagem e chefe: dourado.


func _gui_input(e: InputEvent) -> void:
	if empty:
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
		pressed.emit(self)
		accept_event()


func pulse() -> void:
	if empty:
		return
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.3, 1.3), 0.12).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(self, "modulate", Color(1.6, 1.6, 1.6), 0.12)
	tw.tween_property(self, "scale", Vector2.ONE, 0.18)
	tw.parallel().tween_property(self, "modulate", Color.WHITE, 0.18)


## Medalha consumida: cresce, racha e apaga.
func break_apart() -> void:
	broken = true
	queue_redraw()
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.6, 1.6), 0.2)
	tw.tween_property(self, "scale", Vector2.ONE, 0.2)
	tw.tween_property(self, "modulate:a", 0.25, 0.4)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var c := size / 2.0
	if empty:
		draw_style_box(Kit.box(Color(0, 0, 0, 0.25), 10, 0), r)
		draw_rect(r.grow(-2), color, false, 2.0)
		return
	if is_round:
		draw_circle(c, size.x / 2.0, color.darkened(0.45))
		draw_arc(c, size.x / 2.0 - 2.0, 0.0, TAU, 32, color, 4.0)
	else:
		draw_style_box(Kit.box(color.darkened(0.55), 10, 0), r)
		draw_rect(r.grow(-2), color, false, 3.0)
	var font := ThemeDB.fallback_font
	var fs := 18 if abbr.length() <= 3 else 15
	draw_string(font, Vector2(0, c.y + fs * 0.35), abbr, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, Kit.TEXT)
	if broken:
		draw_line(Vector2(size.x * 0.3, 4), Vector2(size.x * 0.55, size.y * 0.5), Kit.TEXT, 3.0)
		draw_line(Vector2(size.x * 0.55, size.y * 0.5), Vector2(size.x * 0.4, size.y - 4), Kit.TEXT, 3.0)
