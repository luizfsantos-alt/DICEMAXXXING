class_name EndScreen
extends Control
## Fim da jornada: vitória do protótipo ou "morreu, zerou".

signal finished


func setup(r: RunState) -> EndScreen:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var v := Kit.vbox(18)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var m := Kit.margin(v, 32)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	var won := r.phase == "victory"
	var t := Kit.label(Texts.t("ui.victory_title" if won else "ui.defeat_title"), 44, Kit.ACCENT if won else Kit.DANGER, true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	v.add_child(Kit.label(Texts.t("ui.fight", {"n": r.fight, "max": Config.LAST_FIGHT}), 26, Kit.MUTED))
	v.add_child(Kit.label(Texts.t("ui.stats", {
		"wins": r.stats.wins, "dealt": r.stats.dealt, "taken": r.stats.taken, "coins": r.stats.coins}), 26))
	var bp := Kit.panel()
	var bv := Kit.vbox(6)
	bp.add_child(bv)
	bv.add_child(Kit.label(Texts.t("ui.build"), 22, Kit.MUTED))
	bv.add_child(Kit.label("Vida máxima: %d" % r.player_max_hp(), 22))
	bv.add_child(Kit.label("Ataque: " + Texts.item_name(r.attack_id), 22))
	bv.add_child(Kit.label("Defesa: " + Texts.item_name(r.defense_id), 22))
	for id in r.passives:
		bv.add_child(Kit.label("• " + Texts.item_name(id), 22))
	v.add_child(bp)
	v.add_child(Kit.button(Texts.t("ui.menu"), func(): finished.emit(), Kit.PANEL_HI))
	return self
