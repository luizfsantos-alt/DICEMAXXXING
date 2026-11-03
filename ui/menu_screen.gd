class_name MenuScreen
extends Control
## Menu inicial.

signal new_run
signal continue_run


func setup() -> MenuScreen:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(cc)
	var v := Kit.vbox(20)
	v.custom_minimum_size = Vector2(560, 0)
	cc.add_child(v)
	var t := Kit.label(Texts.t("ui.title"), 72, Kit.ACCENT)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var sub := Kit.label("O coliseu de 100 lutas. Morreu, zerou.", 24, Kit.MUTED, true)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 30)
	v.add_child(gap)
	var c := Kit.button(Texts.t("ui.continue"), func(): continue_run.emit(), Kit.PANEL_HI, 30)
	c.custom_minimum_size = Vector2(0, 72)
	c.disabled = not SaveGame.exists()
	v.add_child(c)
	var n := Kit.button(Texts.t("ui.new_run"), func(): new_run.emit(), Kit.ACCENT.darkened(0.55), 30)
	n.custom_minimum_size = Vector2(0, 72)
	v.add_child(n)
	return self
