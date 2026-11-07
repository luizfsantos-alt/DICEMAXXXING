class_name Overlay
extends Control
## Janela modal genérica: fundo escuro, painel com título, conteúdo e botão de fechar.
## Usada para consultas, bolsa, escolha de dado/face e organização do grimório.

signal closed

var body: VBoxContainer
var footer: HBoxContainer


static func open(parent: Control, title: String, close_text := "", min_w := 760) -> Overlay:
	var o := Overlay.new()
	o.set_anchors_preset(Control.PRESET_FULL_RECT)
	o.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	o.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	o.add_child(cc)
	var p := Kit.panel(Kit.PANEL_HI)
	p.custom_minimum_size = Vector2(min_w, 0)
	cc.add_child(p)
	var v := Kit.vbox(10)
	p.add_child(v)
	if title != "":
		var tl := Kit.title(title, 30, Kit.ACCENT, 0)
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(tl)
	o.body = Kit.vbox(8)
	v.add_child(o.body)
	o.footer = Kit.hbox(12)
	o.footer.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(o.footer)
	o.footer.add_child(Kit.button(close_text if close_text != "" else "OK", o.close, Kit.PANEL, 24))
	o.footer.get_child(0).custom_minimum_size = Vector2(220, 60)
	parent.add_child(o)
	return o


func close() -> void:
	closed.emit()
	queue_free()


func add_text(t: String, fs := 22, col := Kit.TEXT) -> Label:
	var l := Kit.label(t, fs, col, true)
	body.add_child(l)
	return l


## Rolagem para listas longas (bolsa).
func add_scroll(h := 420) -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, h)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := Kit.vbox(6)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	body.add_child(sc)
	return v
