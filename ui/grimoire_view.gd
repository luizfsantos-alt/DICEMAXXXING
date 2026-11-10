class_name GrimoireView
extends Control
## Inventário de magias desenhado em grade. Peças coloridas pelo tipo de efeito,
## com nome, exigência e os dados postos. Toque numa célula emite cell_tapped.

signal cell_tapped(cell: Vector2i, item: int)

const FX_COLORS := {
	# Dano escuro e cura clara: além do matiz, a luminosidade separa os dois (daltonismo).
	"dmg": Color(0.7, 0.2, 0.2),
	"block": Color(0.25, 0.45, 0.8), "dodge": Color(0.3, 0.6, 0.7), "mirror": Color(0.55, 0.6, 0.75),
	"heal": Color(0.32, 0.72, 0.55), "maxhp": Color(0.4, 0.76, 0.62), "sacrifice": Color(0.55, 0.3, 0.65),
}

var inv: Inventory
var fighter: Fighter ## Para "usada" e dados postos (opcional).
var choice: TurnChoice
var cell := 96
var selected_item := -1 ## Edição: peça levantada.
var ghost := {} ## Edição: {id, rot, x, y, ok} prévia de onde a peça vai.
var compact := false ## Miniatura (sem textos longos).
var flash := {} ## item -> tempo restante do brilho.
var show_order := false ## Organizar: número da ordem de resolução em cada peça.
var new_item := -1 ## Organizar: peça recém-adquirida (marca "NOVA").


func setup(i: Inventory, cell_px := 96, f: Fighter = null) -> GrimoireView:
	inv = i
	fighter = f
	cell = cell_px
	custom_minimum_size = Vector2(inv.width * cell, inv.height * cell)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	return self


static func req_label(id: String) -> String:
	var d := Spells.get_def(id)
	match str(d.req):
		"any":
			return "%d dado%s" % [int(d.get("n", 1)), "s" if int(d.get("n", 1)) > 1 else ""]
		"max":
			return "≤ %d" % int(d.v)
		"min":
			return "≥ %d" % int(d.v)
		"exact":
			if bool(d.get("flex", false)):
				return "quantos quiser = %d" % int(d.v)
			if int(d.get("n", 1)) > 1:
				return "%d dados = %d" % [int(d.n), int(d.v)]
			return "= %d" % int(d.v)
		"odd":
			return "ímpar"
		"even":
			return "par"
		"top":
			return "face máx."
		"max_n":
			return "%d dados ≤ %d" % [int(d.n), int(d.v)]
		"min_n":
			return "%d dados ≥ %d" % [int(d.n), int(d.v)]
		"low_one":
			return "%d dados, um ≤ %d" % [int(d.n), int(d.v)]
		"pair":
			return "dois iguais"
		"trio":
			return "três iguais"
		"seq3":
			return "sequência"
	return ""


func refresh() -> void:
	queue_redraw()


func pulse_item(item: int) -> void:
	flash[item] = 1.0
	set_process(true)


func _process(delta: float) -> void:
	var done := true
	for k in flash.keys():
		flash[k] -= delta * 2.5
		if flash[k] <= 0.0:
			flash.erase(k)
		else:
			done = false
	queue_redraw()
	if done:
		set_process(false)


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
		var c := Vector2i(int(e.position.x / cell), int(e.position.y / cell))
		if c.x >= 0 and c.y >= 0 and c.x < inv.width and c.y < inv.height:
			cell_tapped.emit(c, inv.item_at(c))
		accept_event()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	for y in inv.height:
		for x in inv.width:
			if not inv.is_cell(Vector2i(x, y)):
				continue ## Casa que não existe (ex.: o meio da Moldura).
			var r := Rect2(Vector2(x, y) * cell, Vector2(cell, cell)).grow(-2)
			draw_style_box(Kit.box(Color(0.1, 0.09, 0.13), 8, 0), r)
	for i in inv.items.size():
		if i == selected_item and not ghost.is_empty():
			continue
		_draw_piece(i, inv.items[i], font)
	if not ghost.is_empty():
		var col := Kit.OK if ghost.ok else Kit.DANGER
		for c in Spells.shape(ghost.id, ghost.rot):
			var p: Vector2i = Vector2i(ghost.x, ghost.y) + c
			var r := Rect2(Vector2(p) * cell, Vector2(cell, cell)).grow(-4)
			draw_rect(r, Color(col, 0.35))
			draw_rect(r, col, false, 3.0)


## Peça como uma forma só: cada casa se estende até a vizinha da mesma peça, e só os
## cantos de fora são arredondados (sem emendas nem pontinhos entre as casas).
## Luz no alto e sombra embaixo dão o relevo de um bloco.
func _fill_piece(cells: Array, col: Color) -> void:
	var m := 3.0
	for c in cells:
		var cc: Vector2i = c
		var o := Vector2(cc) * cell
		var nl := (cc + Vector2i(-1, 0)) in cells
		var nr := (cc + Vector2i(1, 0)) in cells
		var nt := (cc + Vector2i(0, -1)) in cells
		var nb := (cc + Vector2i(0, 1)) in cells
		var r := Rect2(o + Vector2(0.0 if nl else m, 0.0 if nt else m),
			Vector2(cell - (0.0 if nl else m) - (0.0 if nr else m), cell - (0.0 if nt else m) - (0.0 if nb else m)))
		var sb := StyleBoxFlat.new()
		sb.bg_color = col
		sb.anti_aliasing = true
		var rad := 7
		sb.corner_radius_top_left = rad if not (nl or nt) else 0
		sb.corner_radius_top_right = rad if not (nr or nt) else 0
		sb.corner_radius_bottom_left = rad if not (nl or nb) else 0
		sb.corner_radius_bottom_right = rad if not (nr or nb) else 0
		draw_style_box(sb, r)
		# A faixa segue sem falha para a vizinha do lado (sem marquinha na emenda).
		var il := 0.0 if nl else 6.0
		var ir := 0.0 if nr else 6.0
		if not nt:
			draw_rect(Rect2(r.position + Vector2(il, 2), Vector2(r.size.x - il - ir, 3)), Color(1, 1, 1, 0.18))
		if not nb:
			draw_rect(Rect2(Vector2(r.position.x + il, r.end.y - 5), Vector2(r.size.x - il - ir, 3)), Color(0, 0, 0, 0.22))


## Contorno só nas bordas externas da peça (formatos em L não ganham caixa extra).
func _outline(cells: Array, col: Color, width := 4.0) -> void:
	for c in cells:
		var cc: Vector2i = c
		var o := Vector2(cc) * cell
		var a := 3.0
		var b := cell - 3.0
		if not (cc + Vector2i(0, -1)) in cells:
			draw_line(o + Vector2(0 if (cc + Vector2i(-1, 0)) in cells else a, a), o + Vector2(cell if (cc + Vector2i(1, 0)) in cells else b, a), col, width)
		if not (cc + Vector2i(0, 1)) in cells:
			draw_line(o + Vector2(0 if (cc + Vector2i(-1, 0)) in cells else a, b), o + Vector2(cell if (cc + Vector2i(1, 0)) in cells else b, b), col, width)
		if not (cc + Vector2i(-1, 0)) in cells:
			draw_line(o + Vector2(a, 0 if (cc + Vector2i(0, -1)) in cells else a), o + Vector2(a, cell if (cc + Vector2i(0, 1)) in cells else b), col, width)
		if not (cc + Vector2i(1, 0)) in cells:
			draw_line(o + Vector2(b, 0 if (cc + Vector2i(0, -1)) in cells else a), o + Vector2(b, cell if (cc + Vector2i(0, 1)) in cells else b), col, width)


func _draw_piece(i: int, it: Dictionary, font: Font) -> void:
	var id: String = it.id
	var col: Color = FX_COLORS.get(Spells.color_family(id), Kit.PANEL_HI)
	var used := fighter != null and not TurnChoice.can_cast(fighter, i)
	var placed: Array = choice.values_in(fighter, i) if (choice and fighter) else []
	var tops: Array = choice.tops_in(fighter, i) if (choice and fighter) else []
	var ready := placed.size() > 0 and Spells.complete(id, placed, tops)
	if used:
		col = col.darkened(0.6)
	if flash.has(i):
		col = col.lightened(0.5 * flash[i])
	var cells: Array = inv.cells_of(it)
	var lo := Vector2i(99, 99)
	var hi := Vector2i(-1, -1)
	for c in cells:
		var cc: Vector2i = c
		lo = Vector2i(mini(lo.x, cc.x), mini(lo.y, cc.y))
		hi = Vector2i(maxi(hi.x, cc.x), maxi(hi.y, cc.y))
	_fill_piece(cells, col)
	# Borda na cor da raridade (como a moldura dos cartões) e o ícone do efeito: a peça
	# não depende só da cor para dizer o que faz.
	_outline(cells, Kit.RARITY_COLORS.get(Spells.rarity(id), Kit.MUTED).darkened(0.15), 3.0)
	var box := Rect2(Vector2(lo) * cell, Vector2(hi - lo + Vector2i.ONE) * cell)
	if ready:
		draw_rect(box.grow(-3), Kit.ACCENT, false, 4.0)
	if i == selected_item or i == new_item:
		_outline(cells, Kit.TEXT if i == selected_item else Kit.ACCENT)
	if show_order:
		var pos := inv.order().find(i) + 1
		var rad := cell * 0.16
		var c := box.position + box.size - Vector2(rad + 8, rad + 8)
		draw_circle(c, rad, Color(0, 0, 0, 0.45))
		draw_string(font, c + Vector2(-rad, rad * 0.4), str(pos), HORIZONTAL_ALIGNMENT_CENTER, rad * 2, int(rad * 1.1), Kit.TEXT)
		if i == new_item:
			draw_string(font, box.position + Vector2(8, box.size.y - 10), Texts.t("ui.new_tag"), HORIZONTAL_ALIGNMENT_LEFT, -1, int(cell * 0.14), Kit.ACCENT)
	var icon := SpellCard.icon(Spells.icon_key(id))
	if compact:
		# Miniatura: só o ícone no meio da peça (três letras do nome não diziam nada).
		if icon:
			var side := minf(cell * 0.7, minf(box.size.x, box.size.y) * 0.6)
			draw_texture_rect(icon, Rect2(box.get_center() - Vector2(side, side) * 0.5, Vector2(side, side)), false,
				Color(1, 1, 1, 0.45 if used else 1.0))
			return
	elif icon:
		var side := cell * 0.32
		draw_texture_rect(icon, Rect2(box.position + Vector2(box.size.x - side - 6, box.size.y - side - 6 - (cell * 0.34 if show_order else 0.0)),
			Vector2(side, side)), false, Color(1, 1, 1, 0.45 if used else 0.95))
	var anchor: Vector2i = cells[0]
	for c in cells:
		var cc: Vector2i = c
		if cc.y < anchor.y or (cc.y == anchor.y and cc.x < anchor.x):
			anchor = cc
	var tl := Vector2(anchor) * cell + Vector2(6, 4)
	# Largura útil: as células da mesma linha do canto, contíguas à direita.
	var run_w := 1
	while (anchor + Vector2i(run_w, 0)) in cells:
		run_w += 1
	var w := cell * run_w - 12.0
	var fs := maxi(12, int(cell * (0.19 if not compact else 0.22)))
	var tfont := Kit.title_font()
	var name := Texts.spell_name(id)
	if compact:
		name = name.left(3)
	var nfs := fs
	while nfs > 10 and tfont.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, nfs).x > w:
		nfs -= 1
	draw_string_outline(tfont, tl + Vector2(0, fs), name, HORIZONTAL_ALIGNMENT_LEFT, w, nfs, 4, Color(0, 0, 0, 0.45))
	draw_string(tfont, tl + Vector2(0, fs), name, HORIZONTAL_ALIGNMENT_LEFT, w, nfs, Kit.TEXT)
	if compact:
		return
	var sub := req_label(id)
	if int(it.level) > 1:
		sub += "  " + Texts.t("ui.level", {"n": it.level})
	draw_string(font, tl + Vector2(0, fs * 2.1), sub, HORIZONTAL_ALIGNMENT_LEFT, w, int(fs * 0.85), Kit.TEXT)
	if used:
		draw_string(font, tl + Vector2(0, fs * 3.2), Texts.t("ui.used"), HORIZONTAL_ALIGNMENT_LEFT, w, int(fs * 0.85), Kit.MUTED)
	elif Spells.is_once(id):
		draw_string(font, tl + Vector2(0, fs * 3.2), Texts.t(Spells.use_key(id)), HORIZONTAL_ALIGNMENT_LEFT, w, int(fs * 0.75), Kit.TEXT.darkened(0.3))
	# Dados postos: quadradinhos no rodapé da peça.
	var sq := cell * 0.3
	for k in placed.size():
		var p := Vector2(anchor) * cell + Vector2(6 + k * (sq + 4), cell - sq - 6)
		draw_style_box(Kit.box(Color(0.93, 0.91, 0.86), 5, 0), Rect2(p, Vector2(sq, sq)))
		draw_string(font, p + Vector2(0, sq * 0.72), str(placed[k]), HORIZONTAL_ALIGNMENT_CENTER, sq, int(sq * 0.6), Color(0.1, 0.09, 0.12))
