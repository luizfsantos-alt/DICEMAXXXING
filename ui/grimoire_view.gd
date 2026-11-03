class_name GrimoireView
extends Control
## Inventário de magias desenhado em grade. Peças coloridas pelo tipo de efeito,
## com nome, exigência e os dados postos. Toque numa célula emite cell_tapped.

signal cell_tapped(cell: Vector2i, item: int)

const FX_COLORS := {
	"dmg": Color(0.75, 0.25, 0.25), "meteor": Color(0.85, 0.35, 0.15),
	"block": Color(0.25, 0.45, 0.8), "dodge": Color(0.3, 0.6, 0.7), "mirror": Color(0.55, 0.6, 0.75),
	"heal": Color(0.3, 0.65, 0.35), "maxhp": Color(0.35, 0.7, 0.5), "sacrifice": Color(0.55, 0.3, 0.65),
}

var inv: Inventory
var fighter: Fighter ## Para "usada" e dados postos (opcional).
var choice: TurnChoice
var cell := 96
var selected_item := -1 ## Edição: peça levantada.
var ghost := {} ## Edição: {id, rot, x, y, ok} prévia de onde a peça vai.
var compact := false ## Miniatura (sem textos longos).
var flash := {} ## item -> tempo restante do brilho.


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
		"exact":
			return "= %d" % int(d.v)
		"pair":
			return "par"
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


func _draw_piece(i: int, it: Dictionary, font: Font) -> void:
	var id: String = it.id
	var def := Spells.get_def(id)
	var col: Color = FX_COLORS.get(str(def.fx), Kit.PANEL_HI)
	var used := fighter != null and Spells.is_once(id) and i in fighter.once_used
	var placed: Array = choice.values_in(fighter, i) if (choice and fighter) else []
	var ready := placed.size() > 0 and Spells.complete(id, placed)
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
		draw_style_box(Kit.box(col, 6, 0), Rect2(Vector2(cc) * cell, Vector2(cell, cell)).grow(-3))
	# Preenche as emendas entre células vizinhas da mesma peça (e o miolo de blocos 2×2).
	for c in cells:
		var cc: Vector2i = c
		var o := Vector2(cc) * cell
		if (cc + Vector2i(1, 0)) in cells:
			draw_rect(Rect2(o + Vector2(cell - 4, 3), Vector2(8, cell - 6)), col)
		if (cc + Vector2i(0, 1)) in cells:
			draw_rect(Rect2(o + Vector2(3, cell - 4), Vector2(cell - 6, 8)), col)
		if (cc + Vector2i(1, 0)) in cells and (cc + Vector2i(0, 1)) in cells and (cc + Vector2i(1, 1)) in cells:
			draw_rect(Rect2(o + Vector2(cell - 4, cell - 4), Vector2(8, 8)), col)
	var box := Rect2(Vector2(lo) * cell, Vector2(hi - lo + Vector2i.ONE) * cell)
	if ready:
		draw_rect(box.grow(-3), Kit.ACCENT, false, 4.0)
	if i == selected_item:
		draw_rect(box.grow(-3), Kit.TEXT, false, 4.0)
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
	var fs := maxi(10, int(cell * (0.17 if not compact else 0.22)))
	var name := Texts.spell_name(id)
	if compact:
		name = name.left(3)
	var nfs := fs
	while nfs > 10 and font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, nfs).x > w:
		nfs -= 1
	draw_string(font, tl + Vector2(0, fs), name, HORIZONTAL_ALIGNMENT_LEFT, w, nfs, Kit.TEXT)
	if compact:
		return
	var sub := req_label(id)
	if int(it.level) > 1:
		sub += "  " + Texts.t("ui.level", {"n": it.level})
	draw_string(font, tl + Vector2(0, fs * 2.1), sub, HORIZONTAL_ALIGNMENT_LEFT, w, int(fs * 0.85), Kit.TEXT.darkened(0.15))
	if used:
		draw_string(font, tl + Vector2(0, fs * 3.2), Texts.t("ui.used"), HORIZONTAL_ALIGNMENT_LEFT, w, int(fs * 0.85), Kit.MUTED)
	elif Spells.is_once(id):
		draw_string(font, tl + Vector2(0, fs * 3.2), Texts.t("ui.once"), HORIZONTAL_ALIGNMENT_LEFT, w, int(fs * 0.75), Kit.TEXT.darkened(0.3))
	# Dados postos: quadradinhos no rodapé da peça.
	var sq := cell * 0.3
	for k in placed.size():
		var p := Vector2(anchor) * cell + Vector2(6 + k * (sq + 4), cell - sq - 6)
		draw_style_box(Kit.box(Color(0.93, 0.91, 0.86), 5, 0), Rect2(p, Vector2(sq, sq)))
		draw_string(font, p + Vector2(0, sq * 0.72), str(placed[k]), HORIZONTAL_ALIGNMENT_CENTER, sq, int(sq * 0.6), Color(0.1, 0.09, 0.12))
