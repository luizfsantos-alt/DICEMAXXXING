class_name Kit
extends RefCounted
## Fábrica de controles placeholder (sem texturas).

const BG := Color(0.08, 0.07, 0.1)
const PANEL := Color(0.15, 0.13, 0.19)
const PANEL_HI := Color(0.22, 0.19, 0.28)
const ACCENT := Color(1.0, 0.78, 0.2)
const DANGER := Color(0.93, 0.3, 0.3)
const OK := Color(0.35, 0.85, 0.45)
const SHIELD := Color(0.4, 0.7, 1.0)
const TEXT := Color(0.95, 0.94, 0.97)
const MUTED := Color(0.65, 0.62, 0.72)
## Raridade (docs/RARIDADE.md §2): cinza, azul, dourada.
const RARITY_COLORS := {
	"common": Color(0.62, 0.62, 0.66), "uncommon": Color(0.35, 0.6, 1.0), "rare": Color(1.0, 0.78, 0.25),
}


static func label(text: String, size := 26, color := TEXT, wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func box(color := PANEL, radius := 14, margin := 14) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	return sb


static func panel(color := PANEL) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(color))
	return p


static func button(text: String, cb: Callable, color := PANEL_HI, size := 28) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 84)
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_stylebox_override("normal", box(color, 14, 10))
	b.add_theme_stylebox_override("hover", box(color.lightened(0.1), 14, 10))
	b.add_theme_stylebox_override("pressed", box(color.darkened(0.2), 14, 10))
	b.add_theme_stylebox_override("disabled", box(color.darkened(0.5), 14, 10))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.pressed.connect(cb)
	return b


static func hp_bar(max_value: int, value: int, color := OK) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 22)
	bar.show_percentage = false
	bar.max_value = max_value
	bar.value = clampi(value, 0, max_value)
	bar.add_theme_stylebox_override("background", box(Color(0.05, 0.05, 0.07), 8, 0))
	bar.add_theme_stylebox_override("fill", box(color, 8, 0))
	return bar


static func vbox(sep := 12) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep := 12) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func margin(child: Control, m := 16) -> MarginContainer:
	var mc := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		mc.add_theme_constant_override("margin_" + side, m)
	mc.add_child(child)
	return mc


static func clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()
