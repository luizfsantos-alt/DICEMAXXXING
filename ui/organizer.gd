class_name Organizer
extends RefCounted
## Organizar o grimório (a mochila de magias). É o único lugar onde o formato das
## magias importa. Toque numa peça para levantá-la (o cartão ao lado mostra o que ela
## faz), "Girar" para girar e toque numa casa para soltar (a casa vira o canto
## superior esquerdo da peça). O número em cada peça é a ordem em que ela acontece
## na luta. Abre sozinho sempre que o jogador ganha uma magia, com ela marcada.


static func open(parent: Control, inv: Inventory, on_done: Callable = Callable(), new_item := -1) -> Overlay:
	var title := Texts.t("ui.grimoire")
	if new_item >= 0:
		title = Texts.t("ui.new_spell_title", {"name": Texts.spell_name(inv.items[new_item].id)})
	var o := Overlay.open(parent, title, Texts.t("ui.done"), 1180)
	var row := Kit.hbox(28)
	o.body.add_child(row)
	var cell := mini(130, int(600.0 / inv.width))
	cell = mini(cell, int(420.0 / inv.height))
	var cc := CenterContainer.new()
	cc.custom_minimum_size = Vector2(600, 420)
	row.add_child(cc)
	var g := GrimoireView.new().setup(inv, cell)
	g.show_order = true
	g.new_item = new_item
	cc.add_child(g)

	var side := Kit.vbox(10)
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(side)
	var hint := Kit.label(Texts.t("ui.organize_hint"), 18, Kit.MUTED, true)
	side.add_child(hint)
	var detail := Kit.panel(Color(0.114, 0.102, 0.141))
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_child(detail)
	var dv := Kit.vbox(8)
	detail.add_child(dv)
	var d_name := Kit.label("", 30, Kit.TEXT, true)
	var d_desc: RichTextLabel = ElementInfo.rich("", 20, Color(0.85, 0.83, 0.89)) ## Elementos citados: tocáveis.
	var d_meta := Kit.label("", 18, Kit.MUTED, true)
	dv.add_child(d_name)
	dv.add_child(d_desc)
	dv.add_child(d_meta)
	var show := func(item: int):
		if item < 0 or item >= inv.items.size():
			d_name.text = Texts.t("ui.pick_piece")
			ElementInfo.set_text(d_desc, "")
			d_meta.text = ""
			return
		var it: Dictionary = inv.items[item]
		var nm := Texts.spell_name(it.id)
		if int(it.level) > 1:
			nm += "  " + Texts.t("ui.level", {"n": it.level})
		d_name.text = nm
		var desc := Texts.spell_desc(it.id)
		if int(it.level) > 1 and Texts.scales_with_level(it.id):
			desc += "\n" + Texts.t("ui.level_fx", {"n": it.level, "fx": Texts.spell_fx(it.id, int(it.level))})
		ElementInfo.set_text(d_desc, desc)
		d_meta.text = Texts.t("ui.piece_meta", {"n": Spells.shape(it.id).size(), "pos": inv.order().find(item) + 1})
	show.call(new_item)

	var state := {"rot": 0}
	var rot_btn := Kit.button(Texts.t("ui.rotate"), func():
		if g.selected_item < 0:
			return
		state.rot = (int(state.rot) + 1) % 4
		_preview(g, inv, state, g.ghost.get("x", 0), g.ghost.get("y", 0)), Kit.PANEL, 24)
	rot_btn.custom_minimum_size = Vector2(180, 60)
	o.footer.add_child(rot_btn)
	g.cell_tapped.connect(func(c: Vector2i, item: int):
		if g.selected_item < 0:
			if item >= 0:
				g.selected_item = item
				state.rot = int(inv.items[item].rot)
				var it: Dictionary = inv.items[item]
				_preview(g, inv, state, int(it.x), int(it.y))
				hint.text = Texts.t("ui.organize_lifted")
				show.call(item)
			return
		var moving := g.selected_item
		if inv.move(g.selected_item, c.x, c.y, int(state.rot)):
			g.selected_item = -1
			g.ghost = {}
			hint.text = Texts.t("ui.organize_hint")
			show.call(moving)
		else:
			_preview(g, inv, state, c.x, c.y)
			hint.text = Texts.t("ui.no_room")
		g.refresh())
	if on_done.is_valid():
		o.closed.connect(on_done)
	return o


static func _preview(g: GrimoireView, inv: Inventory, state: Dictionary, x: int, y: int) -> void:
	var id: String = inv.items[g.selected_item].id
	g.ghost = {"id": id, "rot": int(state.rot), "x": x, "y": y,
		"ok": inv.can_place(id, int(state.rot), x, y, g.selected_item)}
	g.refresh()
