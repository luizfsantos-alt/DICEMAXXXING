class_name FitGrid
extends Container
## Grade que mostra todos os filhos sem rolagem (docs/SPEC_v3.md §13).
##
## Calcula colunas e linhas conforme a quantidade de filhos visíveis e o espaço
## disponível. Cada célula tem um tamanho padrão ("cell"): com poucos filhos eles ficam
## nesse tamanho (não esticam); quando não cabem, todos encolhem por igual, por escala,
## mantendo a proporção. A última linha fica centralizada.

var cell := Vector2(100, 100) ## Tamanho padrão de uma célula.
var gap := 8.0
var top := false ## Alinha no topo (senão, centraliza na vertical).
var columns := 1 ## Resultado do último arranjo (para testes).
var rows := 1
var fit_scale := 1.0


func setup(c: Vector2, g := 8.0, align_top := false) -> FitGrid:
	cell = c
	gap = g
	top = align_top
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_PASS
	return self


func _get_minimum_size() -> Vector2:
	return Vector2.ZERO ## Pode encolher à vontade: os filhos se ajustam.


## Melhor arranjo para n células de tamanho c em avail: maior escala (até 1); no empate,
## menos linhas; depois, menos colunas. Retorna {cols, rows, scale}.
static func arrange(n: int, avail: Vector2, c: Vector2, g: float) -> Dictionary:
	var best := {"cols": 1, "rows": maxi(1, n), "scale": -1.0}
	if n <= 0:
		best.scale = 1.0
		return best
	for cols in range(1, n + 1):
		var r := ceili(float(n) / cols)
		if cols > 1 and ceili(float(n) / (cols - 1)) == r:
			continue ## Mesma quantidade de linhas com menos colunas já foi vista.
		var sx := (avail.x - g * (cols - 1)) / (c.x * cols)
		var sy := (avail.y - g * (r - 1)) / (c.y * r)
		var s := clampf(minf(sx, sy), 0.01, 1.0)
		if s > float(best.scale) + 0.0001 or (absf(s - float(best.scale)) <= 0.0001 and r < int(best.rows)):
			best = {"cols": cols, "rows": r, "scale": s}
	return best


func visible_children() -> Array:
	var out := []
	for ch in get_children():
		if ch is Control and ch.visible and not ch.top_level:
			out.append(ch)
	return out


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_layout()


func _layout() -> void:
	var kids := visible_children()
	var n := kids.size()
	if n == 0:
		return
	var a := arrange(n, size, cell, gap)
	columns = int(a.cols)
	rows = int(a.rows)
	fit_scale = float(a.scale)
	var cw := cell * fit_scale
	var total := Vector2(columns * cw.x + gap * (columns - 1), rows * cw.y + gap * (rows - 1))
	var origin := Vector2((size.x - total.x) * 0.5, 0.0 if top else (size.y - total.y) * 0.5)
	for i in n:
		var ch: Control = kids[i]
		@warning_ignore("integer_division")
		var r := i / columns
		var col := i % columns
		var in_row := columns if r < rows - 1 else n - columns * (rows - 1)
		var row_off := (columns - in_row) * (cw.x + gap) * 0.5
		var pos := origin + Vector2(row_off + col * (cw.x + gap), r * (cw.y + gap))
		# O filho fica no tamanho padrão (ou no mínimo dele, se maior) e é escalado para
		# caber na célula: nunca invade a vizinha.
		var full := cell.max(ch.get_combined_minimum_size())
		var k := fit_scale * minf(cell.x / full.x, cell.y / full.y)
		ch.pivot_offset = Vector2.ZERO
		ch.scale = Vector2(k, k)
		ch.size = full
		ch.position = pos + (cw - full * k) * 0.5


## Retângulo visível de um filho, em coordenadas da grade (com a escala).
static func visual_rect(ch: Control) -> Rect2:
	return Rect2(ch.position, ch.size * ch.scale)
