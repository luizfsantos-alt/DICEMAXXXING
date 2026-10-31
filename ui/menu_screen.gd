class_name MenuScreen
extends Control
## Menu inicial.

signal new_run
signal continue_run


func setup() -> MenuScreen:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var v := Kit.vbox(24)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var m := Kit.margin(v, 48)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	var t := Kit.label(Texts.t("ui.title"), 64, Kit.ACCENT)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var sub := Kit.label("O coliseu de 100 lutas. Morreu, zerou.", 24, Kit.MUTED, true)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 60)
	v.add_child(gap)
	var c := Kit.button(Texts.t("ui.continue"), func(): continue_run.emit(), Kit.PANEL_HI, 32)
	c.disabled = not SaveGame.exists()
	v.add_child(c)
	v.add_child(Kit.button(Texts.t("ui.new_run"), func(): new_run.emit(), Kit.ACCENT.darkened(0.55), 32))
	return self
