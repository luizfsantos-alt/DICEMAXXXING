class_name MenuScreen
extends Control
## Menu inicial: continuar ou começar uma jornada com um dos personagens jogáveis
## (Characters.PLAYABLE).

signal new_run(char_id: String)

const LOGO := "res://assets/logo.png"
const TITLE_LOGO := "res://assets/title_logo.png" ## Logo com o nome (640×479, fundo recortado).
const TITLE_H := 330.0
const BACKGROUND := "res://assets/backgrounds/menu.jpg"
signal continue_run

var picks: Array = [] ## Botões dos personagens (testes).
var header: VBoxContainer ## Título e subtítulo; o aviso de versão nova entra embaixo.
var update_bar: Control ## Aviso de versão nova (null até haver uma).
var update_url := ""


func setup() -> MenuScreen:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(cc)
	var v := Kit.vbox(-6) # os cartões encostam na franja de baixo do logo
	v.custom_minimum_size = Vector2(1100, 0)
	cc.add_child(v)
	# Logo do título à esquerda; Continuar, aviso de versão e "escolha o personagem" à direita.
	# Sem a arte do título, volta ao dado com chapéu e o nome em texto.
	var head := Kit.hbox(28)
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(head)
	var title_art := Kit.tex(TITLE_LOGO)
	var logo := TextureRect.new()
	logo.texture = title_art if title_art else load(LOGO)
	logo.custom_minimum_size = Vector2(TITLE_H * 640.0 / 479.0, TITLE_H) if title_art else Vector2(140, 140)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(logo)
	var tv := Kit.vbox(12)
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	tv.custom_minimum_size = Vector2(520, 0)
	head.add_child(tv)
	header = tv
	if title_art == null:
		tv.add_child(Kit.label(Texts.t("ui.title"), 64, Kit.ACCENT))
	var c := Kit.button(Texts.t("ui.continue"), func(): continue_run.emit(), Kit.PANEL_HI, 28)
	c.custom_minimum_size = Vector2(0, 64)
	c.disabled = not SaveGame.exists()
	tv.add_child(c)
	var nt := Kit.label(Texts.t("ui.pick_character"), 26, Kit.TEXT)
	nt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Com o logo grande, o convite vai na coluna da direita para os cartões caberem na tela.
	(tv if title_art else v).add_child(nt)
	var row := Kit.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	for id in Characters.PLAYABLE:
		row.add_child(_card(id))
	add_child(_version_label())
	Kit.background(self, BACKGROUND)
	return self


## Versão instalada no canto de cima à direita ("debug" nos APKs de branch), para saber
## se o aviso de versão nova deveria aparecer.
func _version_label() -> Label:
	var txt := version_text(AppVersion.current(), OS.is_debug_build())
	var l := Kit.label(txt, 16, Kit.MUTED)
	l.name = "Version"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	l.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func version_text(version: String, debug: bool) -> String:
	if version == "":
		return ""
	var t := Texts.t("ui.version", {"version": version})
	return t + " · debug" if debug else t


## Cartão compacto do personagem: retrato (variação 1) em cima, nome, passiva e números.
const CARD := Vector2(232, 360)
const CARD_PORTRAIT_H := 160


func _card(id: String) -> Button:
	var info := Texts.character(id)
	var c := Characters.get_def(id)
	var b := Button.new()
	b.custom_minimum_size = CARD
	b.focus_mode = Control.FOCUS_NONE
	b.clip_contents = true
	var col := Portrait.COLORS.get(id, Kit.PANEL_HI) as Color
	for st in ["normal", "hover", "pressed"]:
		var sb := Kit.box(Kit.PANEL if st != "hover" else Kit.PANEL_HI, 14, 8)
		sb.set_border_width_all(3)
		sb.border_color = col
		b.add_theme_stylebox_override(st, sb)
	var v := Kit.vbox(1)
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 8
	v.offset_right = -8
	v.offset_top = 8
	v.offset_bottom = -8
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var f := Fighter.new()
	f.archetype = id
	f.portrait = 0
	f.is_player = true
	v.add_child(Portrait.new().setup(f, CARD_PORTRAIT_H, true))
	var spells := []
	for s in c.spells:
		spells.append(Texts.spell_name(s[0]))
	var lines := [
		[str(info[0]), 22, Kit.ACCENT],
		["%s: %s" % [info[1], info[2]], 13, Kit.TEXT],
		[Texts.t("ui.char_stats", {"hp": c.hp, "hand": c.hand, "bag": c.bag_size}), 13, Kit.MUTED],
		[Texts.t("ui.char_spells", {"list": ", ".join(spells)}), 13, Kit.MUTED],
	]
	for ln in lines:
		var l := Kit.label(ln[0], ln[1], ln[2], true)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(l)
	b.pressed.connect(func(): new_run.emit(id))
	picks.append(b)
	return b


## Aviso de versão nova embaixo do subtítulo (cabe na altura do logo, não empurra o menu).
## O botão abre o download do APK; a instalação fica com o Android.
func show_update(info: Dictionary) -> void:
	update_url = str(info.get("url", ""))
	if update_url == "":
		return
	if update_bar:
		update_bar.queue_free()
	var h := Kit.hbox(12)
	header.add_child(h)
	var tv := Kit.vbox(0)
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(tv)
	tv.add_child(Kit.label(Texts.t("ui.update_available", {"version": info.get("version", "")}), 18, Kit.OK))
	tv.add_child(Kit.label(Texts.t("ui.update_note"), 14, Kit.MUTED))
	var b := Kit.button(Texts.t("ui.update_download"), func(): OS.shell_open(update_url), Kit.PANEL_HI, 18)
	b.custom_minimum_size = Vector2(110, 40)
	h.add_child(b)
	update_bar = h
