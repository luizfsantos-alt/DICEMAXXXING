class_name Organizer
extends RefCounted
## Organizar o grimório: toque numa peça para levantá-la, "Girar" para girar,
## toque numa célula para soltar (a célula vira o canto superior esquerdo da peça).


static func open(parent: Control, inv: Inventory, on_done: Callable = Callable()) -> Overlay:
	var o := Overlay.open(parent, Texts.t("ui.grimoire"), Texts.t("ui.done"), 640)
	var hint := o.add_text(Texts.t("ui.organize_hint"), 18, Kit.MUTED)
	var cc := CenterContainer.new()
	o.body.add_child(cc)
	var g := GrimoireView.new().setup(inv, 110)
	cc.add_child(g)
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
			return
		if inv.move(g.selected_item, c.x, c.y, int(state.rot)):
			g.selected_item = -1
			g.ghost = {}
			hint.text = Texts.t("ui.organize_hint")
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
