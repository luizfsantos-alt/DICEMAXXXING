class_name StatusIcon
extends Control
## Ícone de um efeito ativo (bloqueio, veneno, queima…) com selo da quantidade.
## Segurar mostra o nome e a descrição (sinal held); soltar fecha.

signal held(icon: StatusIcon, on: bool)

## id -> [sigla, cor]. Placeholders até haver arte.
const STYLE := {
	"block": ["BL", Color(0.4, 0.7, 1.0)],
	"poison": ["VE", Color(0.55, 0.85, 0.3)],
	"burn": ["QU", Color(1.0, 0.55, 0.2)],
	"mirror": ["ES", Color(0.76, 0.65, 1.0)],
	"dodge": ["EV", Color(0.5, 0.83, 0.86)],
	"riposte": ["RE", Color(0.55, 0.75, 1.0)],
	"immune": ["IM", Color(0.9, 0.9, 0.95)],
	"marked": ["GU", Color(1.0, 0.78, 0.2)],
	"fury": ["FU", Color(0.93, 0.3, 0.3)],
	"thirst": ["SE", Color(0.7, 0.15, 0.25)],
	"hand_mod": ["PM", Color(0.75, 0.45, 0.85)],
}

var id := ""
var count := 0
var title := ""
var desc := ""


func setup(status: Dictionary, px := 40) -> StatusIcon:
	custom_minimum_size = Vector2(px, px)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_status(status)
	return self


func set_status(status: Dictionary) -> void:
	id = str(status.id)
	count = int(status.n)
	title = str(status.get("name", id))
	desc = str(status.get("desc", ""))
	queue_redraw()


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		held.emit(self, e.pressed)
		accept_event()


func _style() -> Array:
	var k := "hand_mod" if id.begins_with("mod_") else id
	return STYLE.get(k, ["?", Kit.PANEL_HI])


func _draw() -> void:
	var st := _style()
	var col: Color = st[1]
	var s := minf(size.x, size.y)
	var r := Rect2(Vector2(1, 1), Vector2(s - 2, s - 2))
	draw_style_box(Kit.box(col.darkened(0.55), int(s * 0.22), 0), r)
	var sb := Kit.box(Color.TRANSPARENT, int(s * 0.22), 0)
	sb.set_border_width_all(2)
	sb.border_color = col
	draw_style_box(sb, r)
	var font := ThemeDB.fallback_font
	var fs := int(s * 0.36)
	draw_string(font, Vector2(0, s * 0.46 + fs * 0.35), str(st[0]), HORIZONTAL_ALIGNMENT_CENTER, s, fs, col.lightened(0.3))
	# Selo com a quantidade, no canto de baixo à direita.
	var txt := str(count)
	var bs := int(s * 0.3)
	var bw := maxf(s * 0.42, bs * 0.62 * txt.length() + 6)
	var br := Rect2(Vector2(s - bw, s - s * 0.42), Vector2(bw, s * 0.42))
	draw_style_box(Kit.box(Color(0.95, 0.94, 0.97), int(s * 0.21), 0), br)
	draw_string(font, br.position + Vector2(0, br.size.y * 0.5 + bs * 0.36), txt, HORIZONTAL_ALIGNMENT_CENTER, br.size.x, bs, Color(0.1, 0.09, 0.12))
