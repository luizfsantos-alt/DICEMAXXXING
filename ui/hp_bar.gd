class_name HpBar
extends Control
## Barra de vida com números ("47 / 80") e escudo/barreira em azul.

var max_hp: int = 1
var hp: int = 1
var shield: int = 0
var barrier: int = 0
var color := Kit.OK


func setup(c: Color) -> HpBar:
	color = c
	custom_minimum_size = Vector2(0, 40)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	return self


func set_values(new_max: int, new_hp: int, new_shield: int, new_barrier: int) -> void:
	max_hp = maxi(1, new_max)
	hp = new_hp
	shield = maxi(0, new_shield)
	barrier = maxi(0, new_barrier)
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_style_box(Kit.box(Color(0.05, 0.05, 0.07), 10, 0), r)
	var frac := clampf(float(hp) / float(max_hp), 0.0, 1.0)
	if frac > 0.0:
		draw_style_box(Kit.box(color.darkened(0.15), 10, 0), Rect2(Vector2.ZERO, Vector2(size.x * frac, size.y)))
	if shield + barrier > 0:
		draw_rect(Rect2(Vector2(0, size.y - 6), Vector2(size.x, 6)), Kit.SHIELD)
	var font := ThemeDB.fallback_font
	var fs := 24
	var y := size.y / 2.0 + fs * 0.35
	draw_string(font, Vector2(0, y), "%d / %d" % [maxi(0, hp), max_hp], HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, Kit.TEXT)
	var extra := []
	if shield > 0:
		extra.append(Texts.t("ui.shield", {"n": shield}))
	if barrier > 0:
		extra.append(Texts.t("ui.barrier", {"n": barrier}))
	if not extra.is_empty():
		draw_string(font, Vector2(0, y - 2), "  ".join(extra) + "  ", HORIZONTAL_ALIGNMENT_RIGHT, size.x, 18, Kit.SHIELD.lightened(0.4))
