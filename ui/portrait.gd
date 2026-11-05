class_name Portrait
extends Control
## Espaço do personagem (placeholder até haver arte): silhueta simples na cor do arquétipo.

const COLORS := {
	"sorcerer": Color(0.45, 0.4, 0.85), "assassin": Color(0.75, 0.3, 0.35),
	"minimalist": Color(0.85, 0.85, 0.9), "metallurgist": Color(0.5, 0.52, 0.58), "copyist": Color(0.75, 0.6, 0.3),
	"perfectionist": Color(0.35, 0.7, 0.65), "vampire": Color(0.6, 0.12, 0.2), "barbarian": Color(0.75, 0.45, 0.2),
}

var archetype := "sorcerer"
var back := false ## Jogador de costas.


func setup(arch: String, h: int, is_back := false) -> Portrait:
	archetype = arch
	back = is_back
	custom_minimum_size = Vector2(0, h)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	return self


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_style_box(Kit.box(Color(0.09, 0.08, 0.11), 10, 0), r)
	var col: Color = COLORS.get(archetype, Kit.PANEL_HI)
	var cx := size.x * 0.5
	var floor_y := size.y * 0.94
	# Plataforma.
	draw_set_transform(Vector2(cx, floor_y), 0.0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, size.y * 0.5, Color(0.16, 0.145, 0.2))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Corpo e cabeça.
	var head := size.y * 0.16
	var body := Rect2(Vector2(cx - size.y * 0.22, size.y * 0.42), Vector2(size.y * 0.44, floor_y - size.y * 0.42))
	draw_style_box(Kit.box(col.darkened(0.2), int(size.y * 0.18), 0), body)
	draw_circle(Vector2(cx, size.y * 0.27), head, col if not back else col.darkened(0.35))
	if not back:
		draw_circle(Vector2(cx - head * 0.4, size.y * 0.26), head * 0.13, Kit.TEXT)
		draw_circle(Vector2(cx + head * 0.4, size.y * 0.26), head * 0.13, Kit.TEXT)
