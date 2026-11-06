class_name Kit
extends RefCounted
## Fábrica de controles. Painel, botão e barra de vida usam as texturas 9-slice de
## assets/ui/ quando existem (painel e botão só nas cores neutras PANEL/PANEL_HI);
## sem elas, ou com outra cor, ficam no StyleBoxFlat.

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

const UI_DIR := "res://assets/ui/"
const COIN := "res://assets/icons/coin.png"
## Textura -> bordas que não esticam (esq., cima, dir., baixo), em pixels da textura.
const NINE := {
	"panel": [20, 20, 20, 20], "button": [14, 12, 14, 12], "hp_frame": [20, 9, 20, 9],
	"card_common": [26, 26, 26, 26], "card_uncommon": [26, 26, 26, 26], "card_rare": [26, 26, 26, 26],
}
## Fundo de tela -> escurecimento (os painéis e textos ficam por cima).
const BG_SHADE := 0.55
static var _tex := {} ## caminho -> Texture2D ou null (não existe)


## Textura carregada uma vez (null se o arquivo não existe).
static func tex(path: String) -> Texture2D:
	if not _tex.has(path):
		_tex[path] = load(path) if ResourceLoader.exists(path) else null
	return _tex[path]


## StyleBox 9-slice de assets/ui/<name>.png, ou null se a textura não existe.
static func nine(name: String, margin := 14, tint := Color.WHITE) -> StyleBoxTexture:
	var t := tex(UI_DIR + name + ".png")
	if t == null:
		return null
	var sb := StyleBoxTexture.new()
	sb.texture = t
	var m: Array = NINE.get(name, [16, 16, 16, 16])
	sb.texture_margin_left = m[0]
	sb.texture_margin_top = m[1]
	sb.texture_margin_right = m[2]
	sb.texture_margin_bottom = m[3]
	sb.set_content_margin_all(margin)
	sb.modulate_color = tint
	return sb


## Fundo de tela cobrindo tudo, escurecido. Vai como primeiro filho de parent (fica atrás).
static func background(parent: Control, path: String, shade := BG_SHADE) -> void:
	var t := tex(path)
	if t == null:
		return
	var bg := TextureRect.new()
	bg.texture = t
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bg)
	parent.move_child(bg, 0)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, shade)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(dim)
	parent.move_child(dim, 1)


## Moeda (assets/icons/coin.png); sem a arte, dois círculos dourados.
static func coin(px := 20) -> Control:
	var t := tex(COIN)
	if t:
		var r := TextureRect.new()
		r.texture = t
		r.custom_minimum_size = Vector2(px, px)
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return r
	var c := Control.new()
	c.custom_minimum_size = Vector2(px, px)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		c.draw_circle(c.size * 0.5, px * 0.45, ACCENT.darkened(0.25))
		c.draw_circle(c.size * 0.5, px * 0.3, ACCENT))
	return c


## Rótulo com a moeda na frente ("● 8 moedas").
static func price_tag(text: String, size := 22, color := ACCENT) -> HBoxContainer:
	var h := hbox(6)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(coin(int(size * 1.1)))
	var l := label(text, size, color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(l)
	return h


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
	var sb: StyleBox = nine("panel", 22) if color in [PANEL, PANEL_HI] else null
	p.add_theme_stylebox_override("panel", sb if sb else box(color))
	return p


static func button(text: String, cb: Callable, color := PANEL_HI, size := 28) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 84)
	b.add_theme_font_size_override("font_size", size)
	if color in [PANEL, PANEL_HI] and tex(UI_DIR + "button.png"):
		b.add_theme_stylebox_override("normal", nine("button", 12))
		b.add_theme_stylebox_override("hover", nine("button", 12, Color(1.25, 1.2, 1.3)))
		b.add_theme_stylebox_override("pressed", nine("button", 12, Color(0.75, 0.72, 0.8)))
		b.add_theme_stylebox_override("disabled", nine("button", 12, Color(0.5, 0.5, 0.55, 0.8)))
	else:
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
