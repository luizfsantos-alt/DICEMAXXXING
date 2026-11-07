class_name BagPanel
extends RefCounted
## Lista da bolsa: cada dado numa linha com elemento e as 6 faces, desenhadas como o
## dado da luta (DieIcon).
## mode: "view" (só olhar), "die" (tocar escolhe o dado), "face" (tocar escolhe a face).


static func open(parent: Control, bag: Array, mode := "view", on_pick: Callable = Callable()) -> Overlay:
	var title := Texts.t("ui.bag", {"n": bag.size()})
	if mode == "die":
		title = Texts.t("ui.pick_die_title")
	elif mode == "face":
		title = Texts.t("ui.pick_face_title")
	var o := Overlay.open(parent, title, Texts.t("ui.cancel") if mode != "view" else "OK", 980)
	var list := o.add_scroll(440)
	for i in bag.size():
		var d: Die = bag[i]
		var row := Kit.hbox(8)
		var name := Kit.label(Texts.element_name(d.element), 22, Elements.COLORS.get(d.element, Kit.TEXT))
		name.custom_minimum_size = Vector2(200, 0)
		name.tooltip_text = Texts.element_desc(d.element)
		var head := Kit.vbox(0)
		head.custom_minimum_size = Vector2(200, 0)
		head.add_child(name)
		if d.element != "":
			# O efeito escrito na linha: tooltip não abre no toque.
			var desc := Kit.label(Texts.element_desc(d.element), 16, Kit.MUTED, true)
			desc.custom_minimum_size = Vector2(200, 0)
			head.add_child(desc)
		row.add_child(head)
		for f in 6:
			# Cada face é o próprio dado (cor e acabamento do elemento), com o selo ×2 e o
			# cadeado da face travada desenhados por cima.
			var b := Button.new()
			b.custom_minimum_size = Vector2(Kit.TOUCH_MIN + 26, Kit.TOUCH_MIN + 6)
			b.focus_mode = Control.FOCUS_NONE
			b.tooltip_text = str(d.value(f))
			var col := Color(0, 0, 0, 0)
			for st in ["normal", "hover", "pressed", "disabled"]:
				var sb := Kit.box(col if st != "hover" else Color(1, 1, 1, 0.08), 10, 2)
				b.add_theme_stylebox_override(st, sb)
			b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
			var ic := DieIcon.new().setup(d.value(f), d.element, Kit.TOUCH_MIN, int(d.stickers[f]), bool(d.locked[f]))
			ic.set_anchors_preset(Control.PRESET_FULL_RECT)
			b.add_child(ic)
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
