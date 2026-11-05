class_name MenuScreen
extends Control
## Menu inicial: continuar ou começar uma jornada com um dos personagens jogáveis
## (Characters.PLAYABLE).

signal new_run(char_id: String)

const LOGO := "res://assets/logo.png"
signal continue_run

var picks: Array = [] ## Botões dos personagens (testes).


func setup() -> MenuScreen:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(cc)
	var v := Kit.vbox(16)
	v.custom_minimum_size = Vector2(1100, 0)
	cc.add_child(v)
	# Logo (provisório) ao lado do título.
	var head := Kit.hbox(20)
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(head)
	var logo := TextureRect.new()
	logo.texture = load(LOGO)
	logo.custom_minimum_size = Vector2(140, 140)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	head.add_child(logo)
	var tv := Kit.vbox(2)
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_child(tv)
	var t := Kit.label(Texts.t("ui.title"), 64, Kit.ACCENT)
	tv.add_child(t)
	var sub := Kit.label(Texts.t("ui.subtitle"), 22, Kit.MUTED)
	tv.add_child(sub)
	var c := Kit.button(Texts.t("ui.continue"), func(): continue_run.emit(), Kit.PANEL_HI, 28)
	c.custom_minimum_size = Vector2(0, 64)
	c.disabled = not SaveGame.exists()
	v.add_child(c)
	var nt := Kit.label(Texts.t("ui.pick_character"), 26, Kit.TEXT)
	nt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nt)
	var row := Kit.hbox(16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	for id in Characters.PLAYABLE:
		row.add_child(_card(id))
	return self


func _card(id: String) -> Button:
	var info := Texts.character(id)
	var c := Characters.get_def(id)
	var b := Button.new()
	b.custom_minimum_size = Vector2(350, 330)
	b.focus_mode = Control.FOCUS_NONE
	var col := Portrait.COLORS.get(id, Kit.PANEL_HI) as Color
	for st in ["normal", "hover", "pressed"]:
		var sb := Kit.box(Kit.PANEL if st != "hover" else Kit.PANEL_HI, 16, 14)
		sb.set_border_width_all(3)
		sb.border_color = col
		b.add_theme_stylebox_override(st, sb)
	var v := Kit.vbox(6)
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 16
	v.offset_right = -16
	v.offset_top = 14
	v.offset_bottom = -14
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var spells := []
	for s in c.spells:
		spells.append(Texts.spell_name(s[0]))
	var lines := [
		[str(info[0]), 30, Kit.ACCENT],
		[str(info[3]) if info.size() > 3 else "", 16, Kit.MUTED],
		["%s: %s" % [info[1], info[2]], 17, Kit.TEXT],
		[Texts.t("ui.char_stats", {"hp": c.hp, "hand": c.hand, "bag": c.bag_size}), 17, Kit.MUTED],
		[Texts.t("ui.char_spells", {"list": ", ".join(spells)}), 17, Kit.MUTED],
	]
	for ln in lines:
		var l := Kit.label(ln[0], ln[1], ln[2], true)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(l)
	b.pressed.connect(func(): new_run.emit(id))
	picks.append(b)
	return b
