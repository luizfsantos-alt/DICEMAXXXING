class_name GrimoireView
extends Control
## Inventário de magias desenhado em grade. Peças coloridas pelo tipo de efeito,
## com nome, exigência e os dados postos. A borda do grimório (e dos buracos, como o
## meio da Moldura) vem desenhada.
##
## Toque e gestos (mouse ou dedo; o toque chega como mouse):
## - toque curto: cell_tapped, ou info_tapped se foi no (i) da peça (show_info);
## - tocar e segurar (HOLD_SEC): held; ao arrastar, dragged a cada casa nova; ao soltar,
##   dropped. A peça free_drag (ex.: a nova, "na mão") começa a arrastar sem esperar.

signal cell_tapped(cell: Vector2i, item: int)
signal info_tapped(item: int)
signal held(cell: Vector2i, item: int)
signal dragged(cell: Vector2i, item: int)
signal dropped(cell: Vector2i, item: int)

const FX_COLORS := {
	# Dano escuro e cura clara: além do matiz, a luminosidade separa os dois (daltonismo).
	"dmg": Color(0.7, 0.2, 0.2),
	"block": Color(0.25, 0.45, 0.8), "dodge": Color(0.3, 0.6, 0.7), "mirror": Color(0.55, 0.6, 0.75),
	"heal": Color(0.32, 0.72, 0.55), "maxhp": Color(0.4, 0.76, 0.62), "sacrifice": Color(0.55, 0.3, 0.65),
}
const HAND := -2 ## Índice da peça "na mão" (fora do inventário) nos sinais.
const HOLD_SEC := 0.35
const SLOP := 14.0 ## Quanto o dedo pode tremer antes de virar arrasto.
const BORDER := Color(0.78, 0.66, 0.42) ## Moldura do grimório.

var inv: Inventory
var fighter: Fighter ## Para "usada" e dados postos (opcional).
var choice: TurnChoice
var cell := 96
var selected_item := -1 ## Edição: peça levantada (HAND = a peça nova).
var ghost := {} ## Edição: {id, rot, x, y, ok} prévia de onde a peça vai.
var compact := false ## Miniatura (sem textos longos).
var flash := {} ## item -> tempo restante do brilho.
var show_order := false ## Organizar: número da ordem de resolução em cada peça.
var new_item := -1 ## Organizar: peça recém-adquirida (marca "NOVA").
var show_info := false ## Desenha o (i) em cada peça.
var hand := {} ## Peça nova fora do inventário: {id, level, x, y, rot, ok}.
var free_drag := -99 ## Peça que arrasta sem precisar segurar.
var prices := {} ## Venda: item -> moedas, escritas na peça.
var marked := {} ## Venda: item -> true, peças marcadas.

var _press := {} ## {pos, cell, item, t, holding, moved, last}


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


static func piece_color(id: String) -> Color:
	return FX_COLORS.get(Spells.color_family(id), Kit.PANEL_HI)


## Miniatura do formato da peça (casas na cor do efeito), para os cartões de oferta.
static func shape_preview(id: String, rot := 0, cell_px := 18) -> Control:
	var cells := Spells.shape(id, rot)
	var hi := Vector2i.ZERO
	for c in cells:
		hi = Vector2i(maxi(hi.x, c.x), maxi(hi.y, c.y))
	var c := Control.new()
	c.custom_minimum_size = Vector2(hi + Vector2i.ONE) * cell_px
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var col := piece_color(id)
	var edge := Kit.RARITY_COLORS.get(Spells.rarity(id), Kit.MUTED) as Color
	c.draw.connect(func():
		var off := (c.size - c.custom_minimum_size) * 0.5
		for p in cells:
			var r := Rect2(off + Vector2(p) * cell_px, Vector2(cell_px, cell_px)).grow(-1)
			c.draw_rect(r, col)
			c.draw_rect(r, edge.darkened(0.15), false, 2.0))
	return c


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
	if not _press.is_empty() and not _press.holding and not _press.moved:
		done = false
		if (Time.get_ticks_msec() - int(_press.t)) / 1000.0 >= HOLD_SEC:
			hold_now()
	queue_redraw()
	if done:
		set_process(false)


func cell_of(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / cell), floori(pos.y / cell))


func cell_center(c: Vector2i) -> Vector2:
	return (Vector2(c) + Vector2(0.5, 0.5)) * cell


func hand_cells() -> Array:
	if hand.is_empty():
		return []
	var out := []
	for c in Spells.shape(hand.id, int(hand.rot)):
		out.append(Vector2i(int(hand.x), int(hand.y)) + c)
	return out


## Peça sob a casa: a da mão vem por cima das do grimório.
func item_under(c: Vector2i) -> int:
	if c in hand_cells():
		return HAND
	if c.x < 0 or c.y < 0 or c.x >= inv.width or c.y >= inv.height:
		return -1
	return inv.item_at(c)


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			press_at(e.position)
		else:
			release_at(e.position)
		accept_event()
	elif e is InputEventMouseMotion and not _press.is_empty():
		move_to(e.position)
		accept_event()


func press_at(pos: Vector2) -> void:
	var c := cell_of(pos)
	_press = {"pos": pos, "cell": c, "item": item_under(c), "t": Time.get_ticks_msec(),
		"holding": false, "moved": false, "last": c}
	set_process(true)


## Segurou o bastante: a peça fica "levantada" (held) e pode ser arrastada.
func hold_now() -> void:
	if _press.is_empty() or _press.holding:
		return
	_press.holding = true
	held.emit(_press.cell, int(_press.item))


func move_to(pos: Vector2) -> void:
	if _press.is_empty():
		return
	if not _press.holding:
		if pos.distance_to(_press.pos) <= SLOP:
			return
		if int(_press.item) == free_drag and free_drag != -99:
			hold_now()
		else:
			_press.moved = true ## Arrastou antes de segurar: não é gesto de peça.
			return
	var c := cell_of(pos)
	if c != _press.last:
		_press.last = c
		dragged.emit(c, int(_press.item))


func release_at(pos: Vector2) -> void:
	if _press.is_empty():
		return
	var p := _press
	_press = {}
	var c := cell_of(pos)
	if p.holding:
		dropped.emit(c, int(p.item))
	elif not p.moved:
		var inf := info_hit(pos)
		if inf != -1:
			info_tapped.emit(inf)
		elif c.x >= 0 and c.y >= 0 and c.x < inv.width and c.y < inv.height:
			cell_tapped.emit(c, item_under(c))


## Item cujo (i) está sob pos, ou -1. A área de toque é um canto inteiro da casa.
func info_hit(pos: Vector2) -> int:
	if not show_info:
		return -1
	var c := cell_of(pos)
	var it := item_under(c)
	if it == -1:
		return -1
	var ic := _info_cell(_cells(it))
	if c != ic:
		return -1
	var local := pos - Vector2(c) * cell
	return it if local.x >= cell * 0.5 and local.y <= cell * 0.5 else -1


func _cells(item: int) -> Array:
	return hand_cells() if item == HAND else inv.cells_of(inv.items[item])


static func _anchor(cells: Array) -> Vector2i:
	var a: Vector2i = cells[0]
	for c in cells:
		var cc: Vector2i = c
		if cc.y < a.y or (cc.y == a.y and cc.x < a.x):
			a = cc
	return a


## Onde fica o (i): a última casa da linha de cima da peça, à direita do nome.
static func _info_cell(cells: Array) -> Vector2i:
	var a := _anchor(cells)
	while (a + Vector2i(1, 0)) in cells:
		a += Vector2i(1, 0)
	return a


func _draw() -> void:
	var font := ThemeDB.fallback_font
	for y in inv.height:
		for x in inv.width:
			var p := Vector2i(x, y)
			if not inv.is_cell(p):
				_draw_hole(p)
				continue
			var r := Rect2(Vector2(x, y) * cell, Vector2(cell, cell)).grow(-2)
			draw_style_box(Kit.box(Color(0.1, 0.09, 0.13), 8, 0), r)
	_draw_border()
	var lifted := selected_item >= 0 and not ghost.is_empty()
	for i in inv.items.size():
		if i == selected_item and lifted:
			continue
		_draw_piece(i, inv.items[i], inv.cells_of(inv.items[i]), font)
	if not hand.is_empty():
		var hc := hand_cells()
		_draw_piece(HAND, hand, hc, font, 1.0 if bool(hand.get("ok", true)) else 0.9)
		if not bool(hand.get("ok", true)):
			_outline(hc, Kit.DANGER, 4.0)
	if not ghost.is_empty():
		var col := Kit.OK if ghost.ok else Kit.DANGER
		for c in Spells.shape(ghost.id, ghost.rot):
			var p: Vector2i = Vector2i(ghost.x, ghost.y) + c
			var r := Rect2(Vector2(p) * cell, Vector2(cell, cell)).grow(-4)
			draw_rect(r, Color(col, 0.35))
			draw_rect(r, col, false, 3.0)


## Buraco no meio do grimório: hachura escura, para não parecer casa vazia.
func _draw_hole(p: Vector2i) -> void:
	var o := Vector2(p) * cell
	var step := maxf(10.0, cell / 7.0)
	var k := step
	while k < cell * 2.0:
		var a := o + Vector2(maxf(0.0, k - cell), minf(k, cell))
		var b := o + Vector2(minf(k, cell), maxf(0.0, k - cell))
		draw_line(a, b, Color(BORDER, 0.16), 2.0)
		k += step


## A moldura: linha em toda aresta entre uma casa do grimório e o que não é casa
## (fora da grade ou buraco). Os cantos de fora ganham um ponto para fechar a quina.
func _draw_border() -> void:
	var w := maxf(3.0, cell * 0.04)
	var dirs := [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	for y in inv.height:
		for x in inv.width:
			var p := Vector2i(x, y)
			if not inv.is_cell(p):
				continue
			var o := Vector2(p) * cell
			for d in dirs:
				if inv.is_cell(p + d):
					continue
				var a: Vector2
				var b: Vector2
				match d:
					Vector2i(0, -1):
						a = o
						b = o + Vector2(cell, 0)
					Vector2i(0, 1):
						a = o + Vector2(0, cell)
						b = o + Vector2(cell, cell)
					Vector2i(-1, 0):
						a = o
						b = o + Vector2(0, cell)
					_:
						a = o + Vector2(cell, 0)
						b = o + Vector2(cell, cell)
				draw_line(a, b, BORDER, w)
				draw_circle(a, w * 0.5, BORDER)
				draw_circle(b, w * 0.5, BORDER)


## Peça como uma forma só: cada casa se estende até a vizinha da mesma peça, e só os
## cantos de fora são arredondados (sem emendas nem pontinhos entre as casas).
## Luz no alto e sombra embaixo dão o relevo de um bloco.
func _fill_piece(cells: Array, col: Color, relief := true) -> void:
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
		if not relief:
			continue
		# A faixa segue sem falha para a vizinha do lado (sem marquinha na emenda).
		var il := 0.0 if nl else 6.0
		var ir := 0.0 if nr else 6.0
		if not nt:
			draw_rect(Rect2(r.position + Vector2(il, 2), Vector2(r.size.x - il - ir, 3)), Color(1, 1, 1, 0.18 * col.a))
		if not nb:
			draw_rect(Rect2(Vector2(r.position.x + il, r.end.y - 5), Vector2(r.size.x - il - ir, 3)), Color(0, 0, 0, 0.22 * col.a))


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


## Nome cabendo na largura w (as linhas nos primeiros narrow_h px só têm w_first, por
## causa do (i)): uma
## linha, senão até max_lines, senão palavras cortadas ("Desneces."). Devolve {lines, fs}.
static func fit_name(name: String, w: float, fs_max: int, fs_min: int, max_lines: int, f: Font, w_first := -1.0, narrow_h := 0.0) -> Dictionary:
	if w_first < 0.0:
		w_first = w
	var width := func(s: String, fs: int) -> float:
		return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var ok := func(lines: Array, fs: int) -> bool:
		for k in lines.size():
			if width.call(lines[k], fs) > _lim(k, fs, w, w_first, narrow_h):
				return false
		return lines.size() <= max_lines
	for fs in range(fs_max, fs_min - 1, -1):
		if width.call(name, fs) <= w_first:
			return {"lines": [name], "fs": fs}
	var words := name.split(" ", false)
	for fs in range(fs_max, fs_min - 1, -1):
		var lines := _wrap(words, w, fs, f, w_first, narrow_h)
		if ok.call(lines, fs):
			return {"lines": lines, "fs": fs}
	# Último recurso: cada palavra encurtada com ponto até caber.
	var short: Array = []
	for k in words.size():
		var s: String = words[k]
		var lim := w_first ## Na dúvida, a largura menor.
		while s.length() > 3 and width.call(s, fs_min) > lim:
			s = s.left(s.length() - 2) + "."
		short.append(s)
	var lines := _wrap(PackedStringArray(short), w, fs_min, f, w_first, narrow_h)
	if lines.size() > max_lines:
		lines = lines.slice(0, max_lines)
		var last: String = lines[-1]
		lines[-1] = last.left(maxi(1, last.length() - 1)) + "…"
	return {"lines": lines, "fs": fs_min}


## Largura da linha k: estreita enquanto a linha começa ao lado do (i).
static func _lim(k: int, fs: int, w: float, w_first: float, narrow_h: float) -> float:
	if w_first < 0.0:
		return w
	return w_first if k == 0 or k * fs * 1.05 < narrow_h else w


static func _wrap(words: PackedStringArray, w: float, fs: int, f: Font, w_first := -1.0, narrow_h := 0.0) -> Array:
	var lines: Array = []
	var cur := ""
	for wd in words:
		var t := wd if cur == "" else cur + " " + wd
		var lim := _lim(lines.size(), fs, w, w_first, narrow_h)
		if cur != "" and f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > lim:
			lines.append(cur)
			cur = wd
		else:
			cur = t
	if cur != "":
		lines.append(cur)
	return lines


func _draw_piece(i: int, it: Dictionary, cells: Array, font: Font, alpha := 1.0) -> void:
	var id: String = it.id
	var col := piece_color(id)
	var used := i >= 0 and fighter != null and not TurnChoice.can_cast(fighter, i)
	var placed: Array = choice.values_in(fighter, i) if (choice and fighter and i >= 0) else []
	var tops: Array = choice.tops_in(fighter, i) if (choice and fighter and i >= 0) else []
	var ready := placed.size() > 0 and Spells.complete(id, placed, tops)
	if used:
		col = col.darkened(0.6)
	if flash.has(i):
		col = col.lightened(0.5 * flash[i])
	col.a = alpha
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
	var is_new := i == new_item or i == HAND
	if i == selected_item or is_new:
		_outline(cells, Kit.TEXT if i == selected_item else Kit.ACCENT, 5.0 if i == selected_item else 4.0)
	if marked.has(i):
		_fill_piece(cells, Color(Kit.OK, 0.25), false)
		_outline(cells, Kit.OK, 6.0)
	var icon := SpellCard.icon(Spells.icon_key(id))
	if compact:
		# Miniatura: só o ícone no meio da peça (três letras do nome não diziam nada).
		if icon:
			var side := minf(cell * 0.7, minf(box.size.x, box.size.y) * 0.6)
			draw_texture_rect(icon, Rect2(box.get_center() - Vector2(side, side) * 0.5, Vector2(side, side)), false,
				Color(1, 1, 1, 0.45 if used else 1.0))
		return
	var anchor := _anchor(cells)
	var corner := box.position + box.size ## Canto de baixo à direita: número e ícone.
	var bottom_used := 0.0
	if show_order and i >= 0:
		var pos := inv.order().find(i) + 1
		var rad := maxf(11.0, cell * 0.13)
		var c := corner - Vector2(rad + 7, rad + 7)
		draw_circle(c, rad, Color(0, 0, 0, 0.5))
		draw_string(font, c + Vector2(-rad, rad * 0.4), str(pos), HORIZONTAL_ALIGNMENT_CENTER, rad * 2, int(rad * 1.15), Kit.TEXT)
		bottom_used = rad * 2 + 6
	if marked.has(i):
		# Marcada para vender: um visto no lugar do ícone (não depende só da cor).
		var r := maxf(14.0, cell * 0.16)
		var cc := corner - Vector2(r + 7, r + 7)
		draw_circle(cc, r, Kit.OK.darkened(0.2))
		draw_polyline(PackedVector2Array([cc + Vector2(-r * 0.5, 0), cc + Vector2(-r * 0.1, r * 0.4), cc + Vector2(r * 0.55, -r * 0.4)]),
			Color(0.05, 0.15, 0.05), maxf(3.0, r * 0.25), true)
	elif icon:
		var side := cell * 0.28
		var ip := corner - Vector2(side + 6, side + 6)
		if bottom_used > 0.0:
			ip.x -= bottom_used ## Ao lado do número, não em cima dele.
		draw_texture_rect(icon, Rect2(ip, Vector2(side, side)), false, Color(1, 1, 1, 0.45 if used else 0.95))
	# Largura útil do nome: as casas da linha de cima, contíguas à direita do canto.
	var run_w := 1
	while (anchor + Vector2i(run_w, 0)) in cells:
		run_w += 1
	var w := cell * run_w - 12.0
	var w1 := w
	var irad := clampf(cell * 0.12, 10.0, 15.0)
	if show_info:
		var ic := _info_cell(cells)
		var cc := Vector2(ic) * cell + Vector2(cell - irad - 6, irad + 6)
		draw_circle(cc, irad, Color(0, 0, 0, 0.55))
		draw_arc(cc, irad, 0, TAU, 24, Color(Kit.TEXT, 0.9), 2.0, true)
		draw_string(Kit.title_font(), cc + Vector2(-irad, irad * 0.55), "i", HORIZONTAL_ALIGNMENT_CENTER, irad * 2, int(irad * 1.5), Kit.TEXT)
		w1 -= irad * 2 + 4
	var tl := Vector2(anchor) * cell + Vector2(6, 4)
	var fs := maxi(12, int(cell * 0.19))
	var tfont := Kit.title_font()
	var nm := Texts.spell_name(id)
	var lines_max := 3 if hi.y == lo.y else 2
	var nh := irad * 2 + 4.0 if show_info else 0.0
	var fit := fit_name(nm, w, fs, mini(fs, maxi(13, int(cell * 0.13))), lines_max, tfont, w1, nh)
	var nfs: int = fit.fs
	# A fonte de pixel embaralha abaixo de 18 px: o nome pequeno vai na fonte comum.
	var nfont: Font = tfont if nfs >= 18 else font
	if nfont != tfont:
		fit = fit_name(nm, w, nfs, mini(nfs, 13), lines_max, nfont, w1, nh)
		nfs = fit.fs
	var y := tl.y
	for k in fit.lines.size():
		var line: String = fit.lines[k]
		y += nfs * 1.05
		var lw := _lim(k, nfs, w, w1, nh)
		draw_string_outline(nfont, Vector2(tl.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, lw, nfs, 4, Color(0, 0, 0, 0.5))
		draw_string(nfont, Vector2(tl.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, lw, nfs, Kit.TEXT)
	var sw := cell * run_w - 12.0
	var sfs := maxi(13, int(fs * 0.8))
	if prices.has(i):
		_price_pill(Vector2(anchor) * cell + Vector2(6, cell - 6), int(prices[i]), font)
	else:
		var sub := req_label(id)
		if int(it.level) > 1:
			sub += "  " + Texts.t("ui.level", {"n": it.level})
		y += sfs * 1.25
		draw_string(font, Vector2(tl.x, y), sub, HORIZONTAL_ALIGNMENT_LEFT, sw, sfs, Kit.TEXT)
		var extra := ""
		var ecol := Kit.TEXT.darkened(0.3)
		if used:
			extra = Texts.t("ui.used")
			ecol = Kit.MUTED
		elif Spells.is_once(id):
			extra = Texts.t(Spells.use_key(id))
		if extra != "" and y + sfs * 1.2 < Vector2(anchor).y * cell + cell - (bottom_used if run_w == 1 and hi.y == lo.y else 0.0):
			y += sfs * 1.2
			draw_string(font, Vector2(tl.x, y), extra, HORIZONTAL_ALIGNMENT_LEFT, sw, int(sfs * 0.9), ecol)
	if is_new and show_order and (box.size.x > cell or box.size.y > cell):
		var tag := Texts.t("ui.new_tag")
		var tfs := maxi(14, int(cell * 0.13))
		var tp := box.position + Vector2(8, box.size.y - 8)
		if prices.has(i):
			tp.y -= tfs * 1.6
		draw_string_outline(font, tp, tag, HORIZONTAL_ALIGNMENT_LEFT, -1, tfs, 4, Color(0, 0, 0, 0.6))
		draw_string(font, tp, tag, HORIZONTAL_ALIGNMENT_LEFT, -1, tfs, Kit.ACCENT)
	# Dados postos: quadradinhos no rodapé da peça.
	var sq := cell * 0.3
	for k in placed.size():
		var p := Vector2(anchor) * cell + Vector2(6 + k * (sq + 4), cell - sq - 6)
		draw_style_box(Kit.box(Color(0.93, 0.91, 0.86), 5, 0), Rect2(p, Vector2(sq, sq)))
		draw_string(font, p + Vector2(0, sq * 0.72), str(placed[k]), HORIZONTAL_ALIGNMENT_CENTER, sq, int(sq * 0.6), Color(0.1, 0.09, 0.12))


## Preço de venda na peça: moeda e número numa pílula escura, no rodapé.
func _price_pill(bl: Vector2, n: int, font: Font) -> void:
	var fs := maxi(16, int(cell * 0.17))
	var txt := str(n)
	var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var h := fs * 1.4
	var r := Rect2(bl - Vector2(0, h), Vector2(h + tw + 10, h))
	draw_style_box(Kit.box(Color(0, 0, 0, 0.6), int(h * 0.5), 0), r)
	var cc := r.position + Vector2(h * 0.5 + 2, h * 0.5)
	draw_circle(cc, h * 0.34, Kit.ACCENT.darkened(0.25))
	draw_circle(cc, h * 0.23, Kit.ACCENT)
	draw_string(font, Vector2(r.position.x + h + 2, r.position.y + h * 0.75), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Kit.ACCENT)
