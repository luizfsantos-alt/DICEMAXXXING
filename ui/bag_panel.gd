class_name BagPanel
extends RefCounted
## Bolsa e escolha de dado/face.
## mode: "view" (só olhar: lista com as 6 faces de cada dado), "die" (tocar escolhe o
## dado) ou "face" (tocar no dado mostra as 6 faces grandes; tocar numa escolhe a face).
## Na escolha, a bolsa inteira cabe na tela sem rolar: uma grade de dados, cada um com
## as 6 faces em miniatura (desenhadas como o dado da luta, DieIcon).

const GRID_W := 900.0 ## Área da grade dentro do painel.
const GRID_H := 470.0
const CELL_MAX := 150.0


static func open(parent: Control, bag: Array, mode := "view", on_pick: Callable = Callable()) -> Overlay:
	if mode == "view":
		return _open_list(parent, bag)
	var o := Overlay.open(parent, Texts.t("ui.pick_die_title"), Texts.t("ui.cancel"), 980)
	_fill_grid(o, bag, mode, on_pick)
	return o


static func _icon(d: Die, f: int, px: int) -> DieIcon:
	return DieIcon.new().setup(d.value(f), d.element, px, int(d.stickers[f]), bool(d.locked[f]), int(d.gold[f]))


## Lado da célula e colunas para n dados caberem em GRID_W × GRID_H.
static func grid_layout(n: int) -> Vector2i:
	var best := Vector2i(1, 1)
	var best_px := 0.0
	for cols in range(1, maxi(1, n) + 1):
		var rows := ceili(float(n) / cols)
		var px := minf(minf(GRID_W / cols, GRID_H / rows / 0.9), CELL_MAX)
		if px > best_px + 0.5:
			best_px = px
			best = Vector2i(cols, int(px))
	return best


## Passo 1: a bolsa em grade. Cada dado: as 6 faces (3 × 2) e o nome do elemento.
static func _fill_grid(o: Overlay, bag: Array, mode: String, on_pick: Callable) -> void:
	Kit.clear(o.body)
	var old := o.footer.get_node_or_null("Back")
	if old:
		old.queue_free()
	_set_title(o, Texts.t("ui.pick_die_title") if mode == "die" else Texts.t("ui.pick_face_die"))
	var lay := grid_layout(bag.size())
	var cell := lay.y
	var grid := GridContainer.new()
	grid.columns = lay.x
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var mini := int((cell - 16) / 3.0)
	for i in bag.size():
		var d: Die = bag[i]
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(cell - 6, cell * 0.9 - 6)
		for st in ["normal", "hover", "pressed", "disabled"]:
			var sb := Kit.box(Color(1, 1, 1, 0.04 if st != "hover" else 0.12), 12, 2)
			b.add_theme_stylebox_override(st, sb)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.tooltip_text = Texts.element_name(d.element)
		var v := Kit.vbox(2)
		v.set_anchors_preset(Control.PRESET_FULL_RECT)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var faces := GridContainer.new()
		faces.columns = 3
		faces.add_theme_constant_override("h_separation", 2)
		faces.add_theme_constant_override("v_separation", 2)
		faces.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		faces.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for f in 6:
			faces.add_child(_icon(d, f, mini))
		v.add_child(faces)
		var nl := Kit.label(Texts.element_name(d.element), clampi(int(cell * 0.13), 13, 18), Elements.COLORS.get(d.element, Kit.TEXT))
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(nl)
		b.add_child(v)
		var di := i
		if mode == "die":
			b.pressed.connect(func():
				o.queue_free()
				on_pick.call(di, -1))
		else:
			b.pressed.connect(func(): _fill_faces(o, bag, di, on_pick))
		grid.add_child(b)
	var cc := CenterContainer.new()
	cc.custom_minimum_size = Vector2(GRID_W, 0)
	cc.add_child(grid)
	o.body.add_child(cc)


## Passo 2 (face): o dado escolhido com as 6 faces grandes; "Voltar" volta para a grade.
static func _fill_faces(o: Overlay, bag: Array, i: int, on_pick: Callable) -> void:
	Kit.clear(o.body)
	_set_title(o, Texts.t("ui.pick_face_title"))
	var d: Die = bag[i]
	var head := Kit.label(Texts.element_name(d.element), 26, Elements.COLORS.get(d.element, Kit.TEXT))
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	o.body.add_child(head)
	if d.element != "":
		var desc := Kit.label(Texts.element_desc(d.element), 18, Kit.MUTED, true)
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		o.body.add_child(desc)
	var row := Kit.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for f in 6:
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(124, 124)
		b.tooltip_text = str(d.value(f))
		for st in ["normal", "hover", "pressed", "disabled"]:
			b.add_theme_stylebox_override(st, Kit.box(Color(1, 1, 1, 0.0 if st != "hover" else 0.1), 12, 2))
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var ic := _icon(d, f, 110)
		ic.set_anchors_preset(Control.PRESET_FULL_RECT)
		b.add_child(ic)
		var fi := f
		b.pressed.connect(func():
			o.queue_free()
			on_pick.call(i, fi))
		row.add_child(b)
	o.body.add_child(row)
	if o.footer.get_node_or_null("Back") == null:
		var back := Kit.button(Texts.t("ui.back"), func(): _fill_grid(o, bag, "face", on_pick), Kit.PANEL, 24)
		back.name = "Back"
		back.custom_minimum_size = Vector2(220, 60)
		o.footer.add_child(back)
		o.footer.move_child(back, 0)


static func _set_title(o: Overlay, t: String) -> void:
	var v := o.body.get_parent()
	if v and v.get_child_count() > 0 and v.get_child(0) is Label and v.get_child(0) != o.body:
		(v.get_child(0) as Label).text = t


## Só olhar: cada dado numa linha com o elemento e as 6 faces (rola se a bolsa crescer).
static func _open_list(parent: Control, bag: Array) -> Overlay:
	var o := Overlay.open(parent, Texts.t("ui.bag", {"n": bag.size()}), "OK", 980)
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
			var ic := _icon(d, f, Kit.TOUCH_MIN)
			ic.custom_minimum_size = Vector2(Kit.TOUCH_MIN + 26, Kit.TOUCH_MIN + 6)
			row.add_child(ic)
		list.add_child(row)
	return o
