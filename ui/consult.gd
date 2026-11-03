class_name Consult
extends Control
## Janela de consulta: nome e descrição de passivas, itens, medalha e equipamentos.
## Fecha com qualquer toque.

signal closed


## entries: Array de [rótulo, nome, descrição].
static func open(parent: Control, title: String, entries: Array) -> Consult:
	var c := Consult.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(cc)
	var p := Kit.panel(Kit.PANEL_HI)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.custom_minimum_size = Vector2(640, 0)
	cc.add_child(p)
	var v := Kit.vbox(10)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(v)
	if title != "":
		v.add_child(Kit.label(title, 28, Kit.ACCENT, true))
	for e in entries:
		if str(e[0]) != "":
			v.add_child(Kit.label(str(e[0]), 16, Kit.MUTED))
		v.add_child(Kit.label(str(e[1]), 24, Kit.TEXT, true))
		if str(e[2]) != "":
			v.add_child(Kit.label(str(e[2]), 20, Kit.MUTED, true))
	parent.add_child(c)
	return c


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and not e.pressed:
		accept_event()
		closed.emit()
		queue_free()
