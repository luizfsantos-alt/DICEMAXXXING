class_name HpBar
extends Control
## Barra de vida com números ("47 / 80") e bloqueio em azul. Com assets/ui/hp_frame.png,
## a moldura de ferro vai por cima do preenchimento (9-slice, Kit.NINE).

var max_hp: int = 1
var hp: int = 1
var shield: int = 0
var barrier: int = 0
var color := Kit.OK
static var _frame: StyleBoxTexture
const FRAME_INSET := Vector2(8, 5) ## Vão da moldura (px da tela).


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
	if _frame == null:
		_frame = Kit.nine("hp_frame", 0)
	# Com moldura, vida e bloqueio ficam no vão dela.
	var inner := r.grow_individual(-FRAME_INSET.x, -FRAME_INSET.y, -FRAME_INSET.x, -FRAME_INSET.y) if _frame else r
	var rad := 3 if _frame else 10
	draw_style_box(Kit.box(Color(0.05, 0.05, 0.07), rad, 0), inner)
	var frac := clampf(float(hp) / float(max_hp), 0.0, 1.0)
	if frac > 0.0:
		draw_style_box(Kit.box(color.darkened(0.15), rad, 0), Rect2(inner.position, Vector2(inner.size.x * frac, inner.size.y)))
	if shield + barrier > 0:
		draw_rect(Rect2(Vector2(inner.position.x, inner.end.y - 6), Vector2(inner.size.x, 6)), Kit.SHIELD)
	if _frame:
		draw_style_box(_frame, r)
	var font := ThemeDB.fallback_font
	var fs := 24
	var y := size.y / 2.0 + fs * 0.35
	draw_string(font, Vector2(0, y), "%d / %d" % [maxi(0, hp), max_hp], HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, Kit.TEXT)
	if shield > 0:
		draw_string(font, Vector2(0, y - 2), Texts.t("ui.block", {"n": shield}) + "  ", HORIZONTAL_ALIGNMENT_RIGHT, size.x, 18, Kit.SHIELD.lightened(0.4))
