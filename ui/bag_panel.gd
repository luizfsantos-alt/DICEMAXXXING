class_name BagPanel
extends RefCounted
## Lista da bolsa: cada dado numa linha com elemento e as 6 faces.
## mode: "view" (só olhar), "die" (tocar escolhe o dado), "face" (tocar escolhe a face).


static func open(parent: Control, bag: Array, mode := "view", on_pick: Callable = Callable()) -> Overlay:
	var title := Texts.t("ui.bag", {"n": bag.size()})
	if mode == "die":
		title = Texts.t("ui.pick_die_title")
	elif mode == "face":
		title = Texts.t("ui.pick_face_title")
	var o := Overlay.open(parent, title, Texts.t("ui.cancel") if mode != "view" else "OK", 900)
	var list := o.add_scroll(440)
	for i in bag.size():
		var d: Die = bag[i]
		var row := Kit.hbox(8)
		var name := Kit.label(Texts.element_name(d.element), 20, Elements.COLORS.get(d.element, Kit.TEXT))
		name.custom_minimum_size = Vector2(170, 0)
		name.tooltip_text = Texts.element_desc(d.element)
		var head := Kit.vbox(0)
		head.custom_minimum_size = Vector2(170, 0)
		head.add_child(name)
		if d.element != "":
			# O efeito escrito na linha: tooltip não abre no toque.
			var desc := Kit.label(Texts.element_desc(d.element), 13, Kit.MUTED, true)
			desc.custom_minimum_size = Vector2(170, 0)
			head.add_child(desc)
		row.add_child(head)
		for f in 6:
			var txt := str(d.value(f))
			if d.stickers[f] > 0:
				txt += " ×" + str(int(pow(2, d.stickers[f])))
			var b := Button.new()
			b.text = txt
			b.custom_minimum_size = Vector2(96, 56)
			b.add_theme_font_size_override("font_size", 22)
			var col := Kit.PANEL
			if d.locked[f]:
				col = Color(0.25, 0.25, 0.3)
			elif d.stickers[f] > 0:
				col = Kit.ACCENT.darkened(0.5)
			for st in ["normal", "hover", "pressed", "disabled"]:
				b.add_theme_stylebox_override(st, Kit.box(col if st != "hover" else col.lightened(0.15), 8, 4))
			if mode == "view":
				b.mouse_filter = Control.MOUSE_FILTER_IGNORE
			else:
				var di := i
				var fi := f
				b.pressed.connect(func():
					o.queue_free()
					on_pick.call(di, fi if mode == "face" else -1))
			row.add_child(b)
		list.add_child(row)
	return o
