class_name EndScreen
extends Control
## Fim da jornada: vitória do protótipo ou "morreu, zerou".

signal finished


func setup(r: RunState) -> EndScreen:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(cc)
	var v := Kit.vbox(18)
	v.custom_minimum_size = Vector2(760, 0)
	cc.add_child(v)
	var won := r.phase == "victory"
	var t := Kit.label(Texts.t("ui.victory_title" if won else "ui.defeat_title"), 44, Kit.ACCENT if won else Kit.DANGER, true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var cols := Kit.hbox(18)
	v.add_child(cols)
	var sp := Kit.panel()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sv := Kit.vbox(6)
	sp.add_child(sv)
	sv.add_child(Kit.label(Texts.t("ui.fight", {"n": r.fight, "max": Config.LAST_FIGHT}), 24, Kit.MUTED))
	sv.add_child(Kit.label(Texts.t("ui.stats", {
		"wins": r.stats.wins, "dealt": r.stats.dealt, "taken": r.stats.taken, "coins": r.stats.coins}), 22))
	cols.add_child(sp)
	var bp := Kit.panel()
	bp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bv := Kit.vbox(6)
	bp.add_child(bv)
	bv.add_child(Kit.label(Texts.t("ui.build"), 22, Kit.MUTED))
	bv.add_child(Kit.label("Vida máxima: %d" % r.player_max_hp(), 20))
	bv.add_child(Kit.label("Ataque: " + Texts.item_name(r.attack_id), 20))
	bv.add_child(Kit.label("Defesa: " + Texts.item_name(r.defense_id), 20))
	for id in r.passives:
		bv.add_child(Kit.label("• " + Texts.item_name(id), 20))
	cols.add_child(bp)
	var b := Kit.button(Texts.t("ui.menu"), func(): finished.emit(), Kit.PANEL_HI)
	b.custom_minimum_size = Vector2(0, 72)
	v.add_child(b)
	return self
