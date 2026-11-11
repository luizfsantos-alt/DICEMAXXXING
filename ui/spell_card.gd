class_name SpellCard
extends PanelContainer
## Magia na luta: cartão de tamanho padrão no palco (o formato só importa no grimório).
## Ícone do tipo de efeito, nome, efeito curto, uso, um buraco por dado pedido e a prévia do resultado.
##
## Pintada no feltro da mesa (FeltTable), como as áreas de aposta da roleta: contorno
## duplo na cor da família da magia, texto pintado e os buracos como quadros riscados.
## O contorno segue uma perspectiva leve (KEYSTONE): no palco, a borda de cima encolhe
## um pouco para o centro, como a mesa vista de frente. Só o desenho entra em
## perspectiva; textos e buracos ficam retos (leitura e toque continuam iguais).

signal tapped(item: int)

const FX_COLORS := {
	"dmg": Color(0.94, 0.44, 0.37),
	"block": Color(0.44, 0.66, 1.0), "dodge": Color(0.5, 0.83, 0.86), "mirror": Color(0.76, 0.65, 1.0),
	"heal": Color(0.44, 0.82, 0.55), "maxhp": Color(0.44, 0.82, 0.55), "sacrifice": Color(0.76, 0.65, 1.0),
	"mod": Color(0.93, 0.89, 0.8), ## Mexidas: a tinta creme das linhas da roleta.
}
## Tinta das linhas no feltro por família: FX_COLORS mais viva e clara, para ler no vermelho.
const PAINT_LIGHTEN := 0.08
const KEYSTONE := 0.07 ## Quanto a borda de cima do palco encolhe (fração da largura).
const PAINT_FILL := Color(0.0, 0.0, 0.0, 0.14) ## Feltro tingido dentro do contorno.
const TEXT_SHADOW := Color(0.08, 0.0, 0.01, 0.75)
const CARD := Color(0.114, 0.102, 0.141)
const CARD_HI := Color(0.149, 0.125, 0.173)
const LINE := Color(0.227, 0.204, 0.271)
const MUTED_INK := Color(0.72, 0.62, 0.62) ## Tinta apagada (magia usada ou que recusa o dado).
const ICON_DIR := "res://assets/icons/"
static var _icons := {} ## chave -> Texture2D ou null (não existe)

var fighter: Fighter
var item := -1
var id := ""
var compact := false
var holes: Array = []
var name_label: Label
var tag_label: Label
var fx_label: Label
var preview: Label
var count_label: Label ## Forjamento: quantos dados já foram postos (fora do buraco).
var icon_rect: TextureRect
var _line := Color.WHITE ## Tinta do contorno.
var _line_w := 2.5
var _glow := Color.TRANSPARENT ## Halo do contorno (aceita o dado; magia pronta).
var _fill := PAINT_FILL
var _box: StyleBoxEmpty ## Margens do cartão: crescem do lado em que o contorno inclina.
var shown_used = null ## Durante a animação: lista de usadas exibida (null = estado real).


func setup(f: Fighter, i: int, hole_px: int, is_compact := false) -> SpellCard:
	fighter = f
	item = i
	id = str(f.inventory.items[i].id)
	compact = is_compact
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP
	name_label = Kit.label(Texts.spell_name(id), 20 if compact else 24, Kit.TEXT)
	name_label.add_theme_font_override("font", Kit.title_font())
	tag_label = Kit.label("", 16, Kit.ACCENT)
	fx_label = Kit.label(spell_fx(id, int(f.inventory.items[i].level)), 16 if compact else 19, Color(0.85, 0.83, 0.89), true)
	preview = Kit.label("", 19, Kit.TEXT, true)
	icon_rect = TextureRect.new()
	icon_rect.texture = icon(Spells.icon_key(id))
	icon_rect.custom_minimum_size = Vector2.ONE * (26 if compact else 32)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_rect.visible = icon_rect.texture != null
	for l: Label in [name_label, tag_label, fx_label, preview]:
		_paint_text(l)
	item_rect_changed.connect(_on_moved)
	# O cartão tem tamanho padrão no palco (FitGrid): textos longos não o esticam.
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	fx_label.max_lines_visible = 3
	preview.max_lines_visible = 2
	var hrow := Kit.hbox(6)
	hrow.alignment = BoxContainer.ALIGNMENT_BEGIN
	var n := hole_count(id)
	if riddle():
		# Charada Fatal: seis buracos, um para cada valor (1 a 6), em duas fileiras.
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 4)
		grid.add_theme_constant_override("v_separation", 4)
		for k in n:
			var h := Hole.new().set_interactive(false).setup(int(hole_px * 0.72))
			grid.add_child(h)
			holes.append(h)
		hrow.add_child(grid)
	else:
		for k in n:
			if k > 0:
				hrow.add_child(_joiner())
			var h := Hole.new().set_interactive(false).setup(hole_px)
			hrow.add_child(h)
			holes.append(h)
	if Spells.is_flex(id):
		# Forjamento: o buraco fica sempre vazio; o contador, ao lado, conta os dados postos.
		count_label = Kit.label("", 26, Kit.ACCENT)
		count_label.add_theme_font_override("font", Kit.num_font())
		count_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		count_label.add_theme_constant_override("outline_size", 5)
		_paint_text(count_label)
		count_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hrow.add_child(count_label)
	if compact:
		var row := Kit.hbox(8)
		add_child(row)
		var tv := Kit.vbox(0)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var head := Kit.hbox(6)
		head.add_child(icon_rect)
		head.add_child(name_label)
		head.add_child(tag_label)
		tv.add_child(head)
		tv.add_child(fx_label)
		row.add_child(tv)
		hrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(hrow)
	else:
		var v := Kit.vbox(4)
		add_child(v)
		var head := Kit.hbox(8)
		head.alignment = BoxContainer.ALIGNMENT_BEGIN
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(icon_rect)
		head.add_child(name_label)
		v.add_child(head)
		v.add_child(fx_label)
		v.add_child(tag_label)
		var sp := Control.new()
		sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(sp)
		hrow.add_theme_constant_override("separation", 6)
		hrow.alignment = BoxContainer.ALIGNMENT_CENTER # buracos no meio do cartão
		v.add_child(hrow)
		v.add_child(preview)
	refresh([], [], -1)
	return self


## Buracos no cartão: um por dado pedido; o Ajuste Fino tem dois (+1 e −1), para um dado só.
static func hole_count(spell: String) -> int:
	if Spells.is_flex(spell):
		return 1 ## Forjamento: um buraco com contador.
	return 2 if two_slots(spell) else Spells.dice_needed(spell)


## Charada Fatal: um buraco por valor, os dados guardados de turno em turno.
func riddle() -> bool:
	return str(Spells.get_def(id).get("req", "")) == "riddle"


## Dois buracos para um dado só, cada um uma escolha (Ajuste Fino: +1 ou −1).
static func two_slots(spell: String) -> bool:
	return str(Spells.get_def(spell).get("mod", "")) == "nudge"


func _joiner() -> Label:
	var t := "=" if str(Spells.get_def(id).req) in ["pair", "trio"] else "›"
	if two_slots(id):
		t = Texts.t("ui.or")
	var j := Kit.label(t, 20 if t.length() < 2 else 15, Hole.REQ_COLOR)
	j.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_paint_text(j)
	return j


## Texto pintado no feltro: uma sombra curta, escura, para ler sobre o vermelho.
static func _paint_text(l: Label) -> void:
	l.add_theme_color_override("font_shadow_color", TEXT_SHADOW)
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.add_theme_constant_override("shadow_outline_size", 3)


## Tinta da família da magia (contorno, buracos).
static func paint_color(spell: String) -> Color:
	var c: Color = FX_COLORS.get(Spells.color_family(spell), Kit.TEXT)
	return Color.from_hsv(c.h, minf(1.0, c.s * 1.25), maxf(c.v, 0.96)).lightened(PAINT_LIGHTEN)


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
		tapped.emit(item)
		accept_event()


## Textura do ícone (assets/icons/<chave>.png), ou null se ainda não há arte.
static func icon(key: String) -> Texture2D:
	if not _icons.has(key):
		var path := ICON_DIR + key + ".png"
		_icons[key] = load(path) if ResourceLoader.exists(path) else null
	return _icons[key]


static func spell_fx(spell: String, level := 1) -> String:
	return Texts.spell_fx(spell, level)


func used() -> bool:
	var lst: Array = shown_used if shown_used != null else fighter.once_used
	var lim := Spells.max_uses(id)
	return lim > 0 and lst.count(item) >= lim


## Estilo do cartão pintado: sem painel (o feltro aparece), só as margens; o contorno,
## o halo e o feltro tingido são desenhados em _draw. line: tinta do contorno; width:
## espessura (1 = apagado); glow: halo em volta (transparente = sem); fill: tingido.
func _style(line: Color, width: float, glow := Color.TRANSPARENT, fill := PAINT_FILL) -> StyleBox:
	_line = line
	_line_w = width
	_glow = glow
	_fill = fill
	queue_redraw()
	if _box == null:
		_box = StyleBoxEmpty.new()
		_box.content_margin_top = 12 if compact else 16
		_box.content_margin_bottom = 10 if compact else 14
		_fit_margins()
	return _box


func _on_moved() -> void:
	queue_redraw()
	_fit_margins.call_deferred()


## Margens laterais: a folga normal mais o quanto o contorno inclinado entra no cartão
## (no alto, longe do centro do palco), para o texto nunca pisar na linha.
func _fit_margins() -> void:
	if _box == null:
		return
	var base := 12.0 if compact else 15.0
	var l := base
	var r := base
	if is_inside_tree() and size.x > 0.0:
		var o := outline(3.0)
		l += maxf(0.0, maxf(o[0].x, o[3].x) - 3.0)
		r += maxf(0.0, size.x - 3.0 - minf(o[1].x, o[2].x))
	if absf(_box.content_margin_left - l) > 0.5 or absf(_box.content_margin_right - r) > 0.5:
		_box.content_margin_left = l
		_box.content_margin_right = r


## Retângulo do palco (coordenadas globais) que define a perspectiva: o pai (a grade).
func _table() -> Rect2:
	var p := get_parent() as Control
	return p.get_global_rect() if p != null else get_global_rect()


## Ponto local levado à mesa em perspectiva leve: quanto mais alto no palco, mais perto
## do centro (a borda de cima encolhe KEYSTONE da largura).
static func keystone(g: Vector2, table: Rect2, k := KEYSTONE) -> Vector2:
	if table.size.y <= 0.0:
		return g
	var t := clampf((g.y - table.position.y) / table.size.y, 0.0, 1.0)
	var cx := table.get_center().x
	return Vector2(cx + (g.x - cx) * (1.0 - k * (1.0 - t)), g.y)


## Contorno do cartão (inset pixels para dentro), em perspectiva, em coordenadas locais.
func outline(inset: float) -> PackedVector2Array:
	var xf := get_global_transform()
	var inv := xf.affine_inverse()
	var t := _table()
	var r := Rect2(Vector2.ZERO, size).grow(-inset)
	var out := PackedVector2Array()
	for c in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		out.append(inv * keystone(xf * c, t))
	return out


func _draw() -> void:
	var outer := outline(3.0)
	draw_colored_polygon(outer, _fill)
	var closed := outer.duplicate()
	closed.append(outer[0])
	if _glow.a > 0.0:
		draw_polyline(closed, _glow, _line_w + 7.0, true)
	draw_polyline(closed, _line, _line_w, true)
	# Segunda linha, fina, por dentro: o filete das áreas da roleta.
	var inner := outline(3.0 + _line_w + 4.0)
	inner.append(inner[0])
	draw_polyline(inner, Color(_line, _line.a * 0.45), 1.0, true)
	_draw_rarity(outer)
	if bool(Spells.get_def(id).get("self_first", false)):
		_draw_priority()


## Losango pintado no meio da borda de cima, na cor da raridade.
func _draw_rarity(outer: PackedVector2Array) -> void:
	var c := (outer[0] + outer[1]) * 0.5
	var r := 6.0 if compact else 7.0
	var col: Color = Kit.RARITY_COLORS.get(Spells.rarity(id), Kit.MUTED)
	var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
	draw_colored_polygon(pts, Color(0.12, 0.0, 0.02))
	var inner := PackedVector2Array()
	for q in pts:
		inner.append(c + (q - c) * 0.62)
	draw_colored_polygon(inner, col)


## Selo de prioridade (Antítese): o dano em quem usa vem antes de todas as magias do turno.
func _draw_priority() -> void:
	var r := 13.0 if compact else 16.0
	var c := Vector2(size.x - r - 5.0, r + 5.0)
	draw_circle(c, r + 2.0, Color(0.05, 0.04, 0.07))
	draw_circle(c, r, Color(1.0, 0.78, 0.2))
	var font := ThemeDB.fallback_font ## A fonte dos números não tem o "º".
	var fs := int(r * 1.0)
	var t := "1º"
	var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, c + Vector2(-w / 2.0, fs * 0.36), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.12, 0.08, 0.04))


## Charada Fatal: o buraco k é o do valor k + 1. Mostra o dado posto agora (aceso) ou o
## guardado de turnos anteriores (apagado); vazio, acende se o selecionado for esse valor.
func _refresh_riddle(values: Array, elements: Array, heats: Array, marks: Array, stored: Array, sel: int, accepts: bool) -> void:
	var kept := {}
	for x in stored:
		kept[int(x.value)] = str(x.get("element", ""))
	for k in holes.size():
		var h: Hole = holes[k]
		var v := k + 1
		var j := values.find(v)
		h.clear_die()
		h.req = str(v)
		if j >= 0:
			h.set_die(v, elements[j] if j < elements.size() else "", float(heats[j]) if j < heats.size() else 0.0)
			var mk: Array = marks[j] if j < marks.size() else [0, 0]
			h.set_marks(int(mk[0]), int(mk[1]))
		elif kept.has(v):
			h.set_die(v, kept[v])
			h.kept = true ## Guardado: fica na magia até completar.
		h.lit = accepts and sel == v and j < 0 and not kept.has(v)
		h.queue_redraw()


## Texto no fundo do buraco k.
func _req_text(placed: Array, k: int) -> String:
	var d := Spells.get_def(id)
	match str(d.get("mod", "")):
		"nudge":
			return "+1" if k == 0 else "−1"
		"echo", "fuse":
			return "%dº" % (k + 1)
	match str(d.req):
		"max", "max_n":
			return "≤ %d" % int(d.v)
		"min", "min_n":
			return "≥ %d" % int(d.v)
		"exact":
			return str(int(d.v))
		"odd":
			return "ímpar"
		"even":
			return "par"
		"top":
			return "MÁX"
		"low_one":
			return "≤ %d" % int(d.v) if k == holes.size() - 1 else ""
		"pair", "trio":
			return str(placed[0]) if not placed.is_empty() else ""
	return ""


## values: dados postos (valores); sel: valor do dado selecionado (-1 = nenhum).
## tops: face mais alta, por dado posto; sel_top: o dado selecionado está na face mais alta.
## sel_ok: o dado selecionado passa nas regras fora do valor (mexido, cópia); sel_die e
## sel_plus: o dado selecionado, para a prévia das mexidas (chance de subir). marks: [+2, ouro]
## da face de cada dado posto (selos dos adesivos).
func refresh(values: Array, elements: Array, sel: int, tops: Array = [], sel_top := false, heats: Array = [],
		sel_ok := true, sel_die: Die = null, sel_plus := 0, marks: Array = [], stored: Array = []) -> void:
	var is_used := used()
	var lvl := int(fighter.inventory.items[item].level)
	fx_label.text = spell_fx(id, lvl) ## O efeito acompanha o nível (evoluir muda o texto).
	var tags := []
	if bool(fighter.inventory.items[item].get("temp", false)):
		tags.append(Texts.t("ui.copy_tag"))
	if lvl > 1:
		tags.append(Texts.t("ui.level", {"n": lvl}))
	if is_used:
		tags.append(Texts.t("ui.used").to_upper())
	elif Spells.is_once(id):
		tags.append(Texts.t(Spells.use_key(id)).to_upper())
	tag_label.text = "  ".join(tags)
	tag_label.add_theme_color_override("font_color", Kit.MUTED if is_used else Kit.ACCENT)
	var accepts := sel >= 0 and sel_ok and not is_used and Spells.accepts_partial(id, values, sel, sel_top)
	var two := two_slots(id) ## Ajuste Fino: os dois buracos acendem.
	var flex := Spells.is_flex(id)
	if riddle():
		_refresh_riddle(values, elements, heats, marks, stored, sel, accepts)
	for k in holes.size():
		if riddle():
			break
		var h: Hole = holes[k]
		var j := -1 if flex else k ## Forjamento: o buraco fica vazio para o próximo dado.
		if j >= 0 and j < values.size():
			h.set_die(int(values[j]), elements[j] if j < elements.size() else "", float(heats[j]) if j < heats.size() else 0.0)
			var mk: Array = marks[j] if j < marks.size() else [0, 0]
			h.set_marks(int(mk[0]), int(mk[1]))
		else:
			h.clear_die()
		h.req = _req_text(values, k) if not flex else str(int(Spells.get_def(id).v))
		h.lit = accepts and (k == values.size() or two or flex) and not (two and k == 1 and sel <= 1)
		h.queue_redraw()
	if count_label != null:
		count_label.text = "×%d" % values.size() if not values.is_empty() else ""
	var col: Color = FX_COLORS.get(Spells.color_family(id), Kit.TEXT)
	var ready := Spells.complete(id, values, tops)
	modulate.a = 1.0
	preview.text = ""
	var paint := paint_color(id)
	var hole_ink := paint
	if is_used:
		hole_ink = Color(MUTED_INK, 0.7)
		add_theme_stylebox_override("panel", _style(Color(MUTED_INK, 0.6), 1.5, Color.TRANSPARENT, Color(0, 0, 0, 0.1)))
		modulate.a = 0.6
	elif sel >= 0 and not accepts and values.size() < holes.size():
		hole_ink = Color(MUTED_INK, 0.7)
		add_theme_stylebox_override("panel", _style(Color(MUTED_INK, 0.7), 1.5, Color.TRANSPARENT, Color(0, 0, 0, 0.1)))
		modulate.a = 0.5
		if not compact:
			preview.text = Texts.t("ui.no_accept", {"v": sel})
			preview.add_theme_color_override("font_color", Kit.MUTED)
	elif accepts:
		add_theme_stylebox_override("panel", _style(Kit.ACCENT, 3.5, Color(Kit.ACCENT, 0.28), Color(0.1, 0.06, 0.0, 0.3)))
	elif ready:
		add_theme_stylebox_override("panel", _style(paint, 3.5, Color(paint, 0.3), Color(paint.darkened(0.6), 0.32)))
	else:
		add_theme_stylebox_override("panel", _style(paint, 3.0))
	for h: Hole in holes:
		h.painted = true
		h.ink = hole_ink
	if ready and not compact:
		preview.text = preview_text(fighter, item, values)
		preview.add_theme_color_override("font_color", col.lightened(0.15))
	elif accepts and not compact and Spells.is_mod(id):
		var all := values.duplicate()
		all.append(sel)
		preview.text = mod_preview(fighter, item, all, sel_die, sel_plus)
		preview.add_theme_color_override("font_color", Kit.ACCENT)


## Prévia da mexida com estes valores (o último é o dado selecionado): o resultado nas
## determinísticas ("→ 6", "→ 2 · 2 · 2") e a chance nas aleatórias (docs/SPEC_v3.1.md §1.5).
static func mod_preview(f: Fighter, i: int, values: Array, sel_die: Die = null, sel_plus := 0) -> String:
	var it: Dictionary = f.inventory.items[i]
	var d := Spells.get_def(str(it.id))
	var lvl := int(it.level)
	var b := lvl - 1
	if values.is_empty():
		return ""
	var v := int(values.back())
	match str(d.get("mod", "")):
		"reroll_max", "gamble":
			if sel_die == null:
				return ""
			var good := 0
			for k in 6:
				var fv := sel_die.value(k) + sel_plus
				if str(d.mod) == "gamble":
					fv *= lvl + 1
				if fv > v:
					good += 1
			var key := "ui.pv_chance_up" if str(d.mod) == "reroll_max" else "ui.pv_chance_better"
			return Texts.t(key, {"p": int(round(100.0 * good / 6.0))})
		"nudge":
			return "→ %d / %d" % [v + 1 + b, maxi(1, v - 1 - b)]
		"top":
			return "→ %d" % ((sel_die.max_value() if sel_die else v) + b)
		"split3":
			@warning_ignore("integer_division")
			var q := v / 3
			var parts := []
			for k in 3:
				parts.append(str(q + (1 if k < v % 3 else 0) + b))
			return "→ " + " · ".join(PackedStringArray(parts))
		"flip":
			return "→ %d" % (7 - v + b)
		"polar":
			return "→ %d" % ((1 if v <= 3 else 6) + b)
		"double":
			return "→ %d" % (v * 2 + b)
		"polish":
			return "→ %d" % (5 + lvl)
		"tide_low":
			return "→ %d · %d" % [Config.TIDE_LOW_VALUE + b, Config.TIDE_LOW_VALUE + b]
		"lingot":
			return "→ %d × 1" % (v + b)
		"insight":
			return Texts.t("ui.pv_insight")
		"avg":
			if values.size() == 2:
				var a := Config.ceil_div(int(values[0]) + int(values[1]), 2) + b
				return "→ %d · %d" % [a, a]
		"echo":
			if values.size() == 2:
				return "→ %d · %d" % [int(values[0]) + b, int(values[0]) + b]
		"fuse":
			if values.size() == 2:
				return "→ %d" % (int(values[0]) + int(values[1]) + b)
		"stairs":
			if values.size() == 3:
				var lo := int(values.min())
				return "→ %d · %d · %d" % [lo + b, lo + 1 + b, lo + 2 + b]
	return ""


## Mostra os dados que o inimigo usou (resolução).
func show_cast(values: Array) -> void:
	refresh(values, [], -1)
	flash()


## Brilho rápido (sem mexer na escala, que o palco usa para encolher os cartões).
func flash() -> void:
	var m0 := modulate
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1.45, 1.35, 1.1, m0.a), 0.1)
	tw.tween_property(self, "modulate", m0, 0.2)


## "→ 6 de dano", "→ 9 bloq"… com os valores postos (exigência completa).
static func preview_text(f: Fighter, i: int, values: Array) -> String:
	var it: Dictionary = f.inventory.items[i]
	var spell := str(it.id)
	var d := Spells.get_def(spell)
	var lvl := int(it.level)
	var mult := int(d.get("mult", 1))
	var bonus := Resolver.dmg_bonus(f)
	var total := 0
	var prod := 1
	for v in values:
		total += int(v)
		prod *= int(v)
	var hi := 0
	var lo := 999
	for v in values:
		hi = maxi(hi, int(v))
		lo = mini(lo, int(v))
	var s := ""
	match str(d.fx):
		"dmg":
			s = Texts.t("ui.pv_dmg", {"n": Config.scale((total + int(d.get("plus", 0))) * mult, lvl) + bonus})
			if d.get("odd_twice", false) and values.all(func(x): return int(x) % 2 == 1):
				s += " ×2"
			if d.has("burn"):
				s += " · " + Texts.t("ui.burn", {"n": d.burn}).to_lower()
			if d.get("pierce", false):
				s += " · " + Texts.t("ui.pv_pierce")
		"product":
			s = Texts.t("ui.pv_dmg", {"n": Config.scale(prod * mult, lvl) + bonus})
		"lever":
			s = Texts.t("ui.pv_dmg", {"n": Config.scale(hi * lo, lvl) + bonus})
		"top_x":
			s = Texts.t("ui.pv_dmg", {"n": Config.scale(hi * mult, lvl) + bonus})
		"multi":
			var blows := []
			for v in values:
				blows.append(str(Config.scale(int(v) * mult, lvl) + bonus))
			if values.size() > 1 and values.all(func(x): return int(x) == int(values[0])):
				blows.append_array(blows.duplicate())
			s = Texts.t("ui.pv_multi", {"list": " + ".join(PackedStringArray(blows))})
		"ones":
			var ones := 0
			for e in f.hand:
				if int(e.bag) != -2 and int(e.value) == 1:
					ones += 1
			if d.has("cap"):
				ones = mini(ones, int(d.cap))
			s = Texts.t("ui.pv_dmg", {"n": Config.scale(int(d.get("per", 1)) * ones, lvl) + bonus})
		"riddle":
			var have: Array = f.riddle_values(i) + values
			var miss := []
			for v in range(1, 7):
				if not (v in have):
					miss.append(str(v))
			if miss.is_empty():
				s = Texts.t("ui.pv_dmg", {"n": Config.scale(Config.RIDDLE_DMG, lvl) + bonus}) + " · " + Texts.t("ui.pv_pierce")
			else:
				s = Texts.t("ui.pv_riddle", {"list": " · ".join(PackedStringArray(miss))})
		"pelt":
			var each := lvl + bonus
			s = Texts.t("ui.pv_multi", {"list": " + ".join(PackedStringArray(values.map(func(_x): return str(each))))})
		"encore":
			s = Texts.t("ui.pv_encore", {"n": Config.scale(total, lvl) + bonus})
		"steal_sticker":
			s = Texts.t("ui.pv_steal", {"n": Config.scale(total, lvl) + bonus})
		"bench":
			s = Texts.t("ui.pv_dmg", {"n": Config.scale(total, lvl) + bonus}) + " · " + Texts.t("ui.pv_bench")
		"spawn_half":
			s = Texts.t("ui.pv_dmg", {"n": Config.scale(total, lvl) + bonus}) + " · " + Texts.t("ui.pv_spawn", {"v": Config.ceil_div(total, 2)})
		"spawn_copy":
			s = "→ " + Texts.t("ui.pv_spawn", {"v": Config.scale(total, lvl)})
		"debuff":
			if lvl > 1:
				s = Texts.t("ui.pv_dmg", {"n": total * (lvl - 1) + bonus})
		"block":
			s = Texts.t("ui.pv_block", {"n": Config.scale(total * mult, lvl)})
		"block_product":
			s = Texts.t("ui.pv_block", {"n": Config.scale(prod * mult, lvl)})
		"block_hand":
			s = Texts.t("ui.pv_block", {"n": Config.scale(int(d.get("per", 1)) * Resolver._hand_count(f), lvl)})
		"skin":
			s = Texts.t("ui.pv_skin", {"n": mini(f.skin + 1, Config.SKIN_CAP + lvl - 1)})
		"tide_out":
			s = Texts.t("ui.pv_tide_out", {"n": Config.TIDE_ONES + lvl - 1})
		"block_count":
			s = Texts.t("ui.pv_block", {"n": Config.scale(int(d.get("per", 1)) * Resolver.count_value(f, int(d.get("count", 1))), lvl)})
		"riposte":
			s = Texts.t("ui.pv_block", {"n": Config.scale(total * mult, lvl)}) + " · " + Texts.t("ui.pv_riposte", {"n": Config.scale(total, lvl)})
		"immune":
			s = Texts.t("ui.pv_block", {"n": Config.scale(total * mult, lvl)}) + " · " + Texts.t("ui.pv_immune")
		"cleanse":
			s = Texts.t("ui.pv_cleanse") + " · " + Texts.t("ui.pv_block", {"n": Config.scale(total, lvl)}).trim_prefix("→ ")
		"recycle":
			s = Texts.t("ui.pv_recycle")
		"dodge":
			s = Texts.t("ui.pv_dodge")
		"mirror":
			s = Texts.t("ui.pv_mirror")
		"heal":
			s = Texts.t("ui.pv_heal", {"n": Config.scale(total * mult, lvl)})
		"synth":
			var sv := Config.scale(maxi(0, total - 1), lvl)
			s = Texts.t("ui.pv_heal", {"n": sv}) + " · " + Texts.t("ui.pv_block", {"n": sv}).trim_prefix("→ ")
			if f.archetype == "shaman":
				# Correspondência: só a cura efetiva (o que falta de vida agora) vira dano.
				s += " · " + Texts.t("ui.pv_dmg", {"n": mini(sv, f.max_hp - f.hp)}).trim_prefix("→ ")
		"antithesis":
			s = Texts.t("ui.pv_dmg", {"n": Config.scale(total * mult, lvl) + bonus}) + " · " + Texts.t("ui.pv_self", {"n": mini(total * Spells.ANTITHESIS_SELF, f.hp - 1)})
		"drain":
			s = Texts.t("ui.pv_dmg", {"n": Config.scale(total, lvl) + bonus}) + " · " + Texts.t("ui.pv_heal", {"n": Config.ceil_div(Config.scale(total, lvl), 2)}).trim_prefix("→ ")
		"feast":
			s = Texts.t("ui.pv_dmg", {"n": Config.scale(total, lvl) + bonus}) + " · " + Texts.t("ui.pv_heal", {"n": Config.scale(lo, lvl)}).trim_prefix("→ ")
		"maxhp":
			s = Texts.t("ui.pv_maxhp", {"n": Config.scale(int(values[0]), lvl)})
		"sacrifice":
			s = Texts.t("ui.pv_sacrifice", {"n": Config.scale(Config.SACRIFICE_BONUS, lvl)})
	if d.has("hand_mod"):
		var m := Texts.t("ui.mod_" + str(d.hand_mod))
		s = (s + " · " + m) if s != "" else "→ " + m
	if d.has("mark"):
		s += " · " + Texts.t("ui.pv_mark")
	return s
