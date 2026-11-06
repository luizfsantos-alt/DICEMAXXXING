class_name EndScreen
extends Control
## Fim da jornada: vitória da fatia vertical ou "perdeu, morreu".

signal finished

const BACKGROUNDS := {true: "res://assets/backgrounds/victory.jpg", false: "res://assets/backgrounds/defeat.jpg"}


func setup(r: RunState) -> EndScreen:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(cc)
	var v := Kit.vbox(18)
	v.custom_minimum_size = Vector2(900, 0)
	cc.add_child(v)
	var won := r.phase == "victory"
	Kit.background(self, BACKGROUNDS[won])
	var t := Kit.label(Texts.t("ui.victory_title" if won else "ui.defeat_title"), 44, Kit.ACCENT if won else Kit.DANGER, true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var cols := Kit.hbox(18)
	v.add_child(cols)
	var sp := Kit.panel()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sv := Kit.vbox(6)
	sp.add_child(sv)
	sv.add_child(Kit.label(Texts.t("ui.stats", {"floor": r.floor_n,
		"wins": r.stats.wins, "dealt": r.stats.dealt, "taken": r.stats.taken, "coins": r.stats.coins}), 22))
	cols.add_child(sp)
	var bp := Kit.panel()
	bp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bv := Kit.vbox(6)
	bp.add_child(bv)
	bv.add_child(Kit.label(Texts.t("ui.build"), 22, Kit.MUTED))
	bv.add_child(Kit.label(Texts.t("ui.consult_hp", {"hp": maxi(0, r.hero.hp), "max": r.hero.max_hp}), 20))
	var g := GrimoireView.new().setup(r.hero.inventory, 64, null)
	g.compact = true
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bv.add_child(g)
	var stick := 0
	var els := []
	for d in r.hero.bag:
		stick += d.sticker_count()
		if d.element != "":
			els.append(Texts.element_name(d.element))
	bv.add_child(Kit.label(Texts.t("ui.bag", {"n": r.hero.bag.size()}) + "  ·  " + Texts.t("ui.consult_stickers", {"n": stick}), 18, Kit.MUTED, true))
	if not els.is_empty():
		bv.add_child(Kit.label(", ".join(els), 18, Kit.MUTED, true))
	cols.add_child(bp)
	var b := Kit.button(Texts.t("ui.menu"), func(): finished.emit(), Kit.PANEL_HI)
	b.custom_minimum_size = Vector2(0, 72)
	v.add_child(b)
	return self
