class_name PlayerStrip
extends HBoxContainer
## Faixa do jogador nas telas de decisão da torre: vida e moedas em destaque e a bolsa
## resumida (total e quantos de cada elemento). Tocar na bolsa abre a lista completa;
## tocar num elemento abre o que ele faz.

const HEART := "res://assets/icons/offer/maxhp.png"

var hp_label: Label
var coins_label: Label
var bag_button: Button
var chips: HBoxContainer


func _init() -> void:
	add_theme_constant_override("separation", 28)


## Contagem por elemento, na ordem de Elements.LOOKS (comum por último): [[id, n], ...].
static func counts(bag: Array) -> Array:
	var n := {}
	for d: Die in bag:
		n[d.element] = int(n.get(d.element, 0)) + 1
	var out := []
	for id in Elements.LOOKS:
		if id != "" and n.has(id):
			out.append([id, n[id]])
	if n.has(""):
		out.append(["", n[""]])
	return out


## host: onde abrir a bolsa e a explicação do elemento (a tela da torre).
func refresh(run: RunState, host: Control) -> void:
	Kit.clear(self)
	var h := run.hero
	var fl := Kit.label(Texts.t("ui.strip_floor", {"n": run.floor_n, "max": Config.LAST_FLOOR}), 22, Kit.MUTED)
	fl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_child(fl)
	var hp_box := Kit.hbox(8)
	hp_box.add_child(_icon(HEART, 36))
	hp_label = Kit.label("%d/%d" % [h.hp, h.max_hp], 34, Kit.OK if h.hp * 2 > h.max_hp else Kit.DANGER)
	hp_box.add_child(hp_label)
	add_child(hp_box)
	var coin_box := Kit.hbox(8)
	coin_box.add_child(Kit.coin(34))
	coins_label = Kit.label(str(run.coins), 34, Kit.ACCENT)
	coin_box.add_child(coins_label)
	add_child(coin_box)
	var bag_box := Kit.hbox(2)
	bag_button = Kit.button(Texts.t("ui.strip_bag", {"n": h.bag.size()}), func(): BagPanel.open(host, h.bag), Kit.PANEL, 22)
	bag_button.custom_minimum_size = Vector2(0, Kit.TOUCH_MIN)
	bag_box.add_child(bag_button)
	chips = Kit.hbox(6)
	for c in counts(h.bag):
		chips.add_child(_chip(str(c[0]), int(c[1]), host, h.bag))
	bag_box.add_child(chips)
	add_child(bag_box)


## Um dado pequeno do elemento (como na luta) e a quantidade ("×2"). Tocar explica o
## elemento; o comum abre a bolsa.
static func _chip(el: String, n: int, host: Control, bag: Array) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = Texts.element_name(el)
	b.custom_minimum_size = Vector2(96, Kit.TOUCH_MIN)
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, Kit.box(Color(1, 1, 1, 0.08) if st == "hover" else Color(0, 0, 0, 0), 10, 0))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var h := Kit.hbox(4)
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	h.add_child(DieIcon.new().setup(6, el, 46))
	var l := Kit.label("×%d" % n, 24, Elements.COLORS.get(el, Kit.TEXT))
	l.add_theme_font_override("font", Kit.num_font())
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 5)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(l)
	if el != "":
		b.pressed.connect(func(): ElementInfo.open(host, el))
	else:
		b.pressed.connect(func(): BagPanel.open(host, bag))
	return b


static func _icon(path: String, px: int) -> Control:
	var t := Kit.tex(path)
	if t == null:
		return Kit.label("♥", px, Kit.DANGER)
	var r := TextureRect.new()
	r.texture = t
	r.custom_minimum_size = Vector2(px, px)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r
