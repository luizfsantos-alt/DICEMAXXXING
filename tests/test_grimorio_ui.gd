extends GutTest
## Fumaça do grimório fora da luta: segurar para mover, (i), descartar, a magia nova
## "na mão" (place_new), a venda de várias peças e a miniatura do formato.


func _parent() -> Control:
	var p := Control.new()
	p.size = Vector2(1280, 720)
	add_child_autofree(p)
	return p


func _find(n: Node, cls) -> Node:
	for c in n.get_children():
		if is_instance_of(c, cls):
			return c
		var r := _find(c, cls)
		if r:
			return r
	return null


func _button(n: Node, text: String) -> Button:
	for c in n.get_children():
		if c is Button and (c as Button).text.begins_with(text):
			return c
		var r := _button(c, text)
		if r:
			return r
	return null


func _tap(g: GrimoireView, pos: Vector2) -> void:
	g.press_at(pos)
	g.release_at(pos)


func _hold_drag(g: GrimoireView, from: Vector2i, to: Vector2i) -> void:
	g.press_at(g.cell_center(from))
	g.hold_now()
	g.move_to(g.cell_center(to))
	g.release_at(g.cell_center(to))


func test_toque_curto_nao_move():
	var inv := Inventory.make(4, 3)
	inv.add("faisca")
	var o := Organizer.open(_parent(), inv)
	await wait_process_frames(1)
	var g: GrimoireView = _find(o, GrimoireView)
	g.press_at(g.cell_center(Vector2i(0, 0)))
	g.move_to(g.cell_center(Vector2i(2, 1)))
	g.release_at(g.cell_center(Vector2i(2, 1)))
	_tap(g, g.cell_center(Vector2i(2, 1)))
	assert_eq([inv.items[0].x, inv.items[0].y], [0, 0], "arrastar sem segurar não move")
	assert_eq(g.selected_item, -1)


func test_segurar_pelo_tempo_levanta():
	var inv := Inventory.make(4, 3)
	inv.add("faisca")
	var o := Organizer.open(_parent(), inv)
	await wait_process_frames(1)
	var g: GrimoireView = _find(o, GrimoireView)
	g.press_at(g.cell_center(Vector2i(0, 0)))
	await wait_seconds(GrimoireView.HOLD_SEC + 0.15)
	assert_eq(g.selected_item, 0, "segurar levanta a peça")
	g.move_to(g.cell_center(Vector2i(1, 2)))
	assert_false(g.ghost.is_empty(), "fantasma enquanto arrasta")
	assert_true(g.ghost.ok)
	g.release_at(g.cell_center(Vector2i(1, 2)))
	assert_eq([inv.items[0].x, inv.items[0].y], [1, 2])


func test_soltar_onde_nao_cabe_volta():
	var inv := Inventory.make(4, 3)
	inv.add_at("faisca", 0, 0, 0)
	inv.add_at("faisca", 1, 0, 0)
	var o := Organizer.open(_parent(), inv)
	await wait_process_frames(1)
	var g: GrimoireView = _find(o, GrimoireView)
	_hold_drag(g, Vector2i(0, 0), Vector2i(1, 0))
	assert_eq([inv.items[0].x, inv.items[0].y], [0, 0], "casa ocupada: fica onde estava")
	assert_true(g.ghost.is_empty())


func test_girar_a_peca_levantada():
	var inv := Inventory.make(4, 3)
	inv.add_at("escudo", 0, 0, 0) ## 2 casas em pé.
	var o := Organizer.open(_parent(), inv)
	await wait_process_frames(1)
	var g: GrimoireView = _find(o, GrimoireView)
	var r0 := int(inv.items[0].rot)
	_button(o, Texts.t("ui.rotate")).pressed.emit()
	assert_eq(int(inv.items[0].rot), r0, "sem segurar, Girar não mexe")
	g.press_at(g.cell_center(Vector2i(0, 0)))
	g.hold_now()
	g.release_at(g.cell_center(Vector2i(0, 0)))
	_button(o, Texts.t("ui.rotate")).pressed.emit()
	assert_eq(int(inv.items[0].rot), (r0 + 1) % 4)


func test_icone_de_informacao():
	var inv := Inventory.make(4, 3)
	inv.add_at("bola", 2, 1, 0)
	var o := Organizer.open(_parent(), inv)
	await wait_process_frames(1)
	var g: GrimoireView = _find(o, GrimoireView)
	var cells := inv.cells_of(inv.items[0])
	var ic := GrimoireView._info_cell(cells)
	var at := Vector2(ic) * g.cell + Vector2(g.cell * 0.85, g.cell * 0.15)
	assert_eq(g.info_hit(at), 0)
	_tap(g, at)
	var labels: Array = []
	for l in o.find_children("*", "Label", true, false):
		labels.append((l as Label).text)
	assert_true(Texts.spell_name("bola") in labels, "o (i) mostra a magia no painel")
	assert_eq(g.selected_item, -1, "o (i) não levanta a peça")


func test_descartar_com_confirmacao():
	var inv := Inventory.make(4, 3)
	inv.add("faisca")
	inv.add("escudo")
	var got := []
	var p := _parent()
	var o := Organizer.open(p, inv, Callable(), {"allow_discard": true, "on_discard": func(i):
		got.append(i)
		inv.remove(i)})
	await wait_process_frames(1)
	var g: GrimoireView = _find(o, GrimoireView)
	var btn := _button(o, Texts.t("ui.discard"))
	assert_true(btn.disabled, "sem peça levantada, nada a descartar")
	var c: Vector2i = inv.cells_of(inv.items[1])[0]
	g.press_at(g.cell_center(c))
	g.hold_now()
	g.release_at(g.cell_center(c))
	assert_false(btn.disabled)
	btn.pressed.emit()
	await wait_process_frames(1)
	var confirm: Overlay = null
	for ch in o.get_children():
		if ch is Overlay:
			confirm = ch
	assert_not_null(confirm, "pede confirmação")
	assert_eq(inv.items.size(), 2, "ainda não descartou")
	_button(confirm, Texts.t("ui.discard")).pressed.emit()
	assert_eq(got, [1])
	assert_eq(inv.ids(), ["faisca"])


func test_descartar_so_com_opcao():
	var inv := Inventory.make(4, 3)
	inv.add("faisca")
	var o := Organizer.open(_parent(), inv)
	await wait_process_frames(1)
	assert_null(_button(o, Texts.t("ui.discard")))


func test_place_new_confirma_sem_adicionar():
	var inv := Inventory.make(4, 3)
	inv.add_at("faisca", 0, 0, 0)
	var res := []
	var o := Organizer.place_new(_parent(), inv, "escudo", 1, func(r): res.append(r))
	await wait_process_frames(1)
	var g: GrimoireView = _find(o, GrimoireView)
	assert_false(g.hand.is_empty(), "a magia nova está na mão")
	assert_true(g.hand.ok)
	var ok_btn := _button(o, Texts.t("ui.confirm"))
	assert_false(ok_btn.disabled)
	# A peça da mão arrasta sem esperar.
	var hc: Vector2i = g.hand_cells()[0]
	g.press_at(g.cell_center(hc))
	g.move_to(g.cell_center(Vector2i(3, 1)))
	g.release_at(g.cell_center(Vector2i(3, 1)))
	assert_eq([int(g.hand.x), int(g.hand.y)], [3, 1])
	# Em cima de outra peça: não dá para confirmar.
	g.press_at(g.cell_center(Vector2i(3, 1)))
	g.move_to(g.cell_center(Vector2i(0, 0)))
	g.release_at(g.cell_center(Vector2i(0, 0)))
	assert_false(g.hand.ok)
	assert_true(ok_btn.disabled)
	g.press_at(g.cell_center(Vector2i(0, 0)))
	g.move_to(g.cell_center(Vector2i(2, 0)))
	g.release_at(g.cell_center(Vector2i(2, 0)))
	assert_true(g.hand.ok)
	_button(o, Texts.t("ui.rotate")).pressed.emit()
	var rot := int(g.hand.rot)
	assert_eq(rot, 1, "Girar gira a peça da mão")
	assert_true(g.hand.ok, "deitada também cabe em (2,0)")
	assert_false(ok_btn.disabled)
	ok_btn.pressed.emit()
	assert_eq(res, [{"x": 2, "y": 0, "rot": 1}])
	assert_eq(inv.items.size(), 1, "quem chama é que adiciona")


func test_place_new_cancela_e_mantem_mudancas():
	var inv := Inventory.make(4, 3)
	inv.add_at("faisca", 0, 0, 0)
	var res := []
	var o := Organizer.place_new(_parent(), inv, "faisca", 1, func(r): res.append(r))
	await wait_process_frames(1)
	var g: GrimoireView = _find(o, GrimoireView)
	_hold_drag(g, Vector2i(0, 0), Vector2i(3, 2))
	assert_eq([inv.items[0].x, inv.items[0].y], [3, 2], "as que já tem mudam de casa com segurar")
	o.close()
	assert_eq(res, [{}], "Cancelar devolve {}")
	assert_eq([inv.items[0].x, inv.items[0].y], [3, 2])


func test_place_new_sem_lugar_e_vender():
	var inv := Inventory.make(2, 1)
	inv.add_at("faisca", 0, 0, 0)
	inv.add_at("dardo", 1, 0, 0)
	var sold := []
	var res := []
	var opts := {"sell": func(i):
		sold.append(i)
		inv.remove(i)
		return 3}
	var o := Organizer.place_new(_parent(), inv, "pico", 1, func(r): res.append(r), opts)
	await wait_process_frames(1)
	var g: GrimoireView = _find(o, GrimoireView)
	var ok_btn := _button(o, Texts.t("ui.confirm"))
	assert_true(ok_btn.disabled, "sem lugar livre, não confirma")
	var sell := _button(o, Texts.t("ui.sell_none"))
	assert_true(sell.disabled, "nada levantado para vender")
	# A peça da mão está por cima da casa (0,0): segurar a de (1,0).
	g.press_at(g.cell_center(Vector2i(1, 0)))
	g.hold_now()
	g.release_at(g.cell_center(Vector2i(1, 0)))
	assert_eq(g.selected_item, 1)
	assert_false(sell.disabled)
	assert_eq(sell.text, Texts.t("ui.sell_short", {"n": Spells.sell_price("dardo", 1)}), "mostra o preço")
	sell.pressed.emit()
	assert_eq(sold, [1])
	# A mão ficou em (0,0), em cima da Faísca: arrasta para a casa livre.
	g.press_at(g.cell_center(Vector2i(0, 0)))
	g.move_to(g.cell_center(Vector2i(1, 0)))
	g.release_at(g.cell_center(Vector2i(1, 0)))
	assert_true(g.hand.ok)
	assert_false(ok_btn.disabled)
	ok_btn.pressed.emit()
	assert_eq(res, [{"x": 1, "y": 0, "rot": int(g.hand.rot)}])


func test_venda_marca_varias():
	var inv := Inventory.make(4, 3)
	inv.add("faisca")
	inv.add("escudo")
	inv.add("bola")
	var got := []
	var o := Organizer.open_sell(_parent(), inv, func(i): return 10 + i, func(items): got.append(items))
	await wait_process_frames(1)
	var g: GrimoireView = _find(o, GrimoireView)
	assert_eq(g.prices, {0: 10, 1: 11, 2: 12}, "preço em cada peça")
	var btn := _button(o, Texts.t("ui.sell_none"))
	assert_true(btn.disabled)
	for i in [2, 0, 1]:
		var c: Vector2i = inv.cells_of(inv.items[i])[0]
		g.press_at(g.cell_center(c))
		g.hold_now()
		g.move_to(g.cell_center(Vector2i(3, 2)))
		g.release_at(g.cell_center(Vector2i(3, 2)))
	assert_eq(btn.text, Texts.t("ui.sell_n", {"n": 33}))
	var c1: Vector2i = inv.cells_of(inv.items[1])[0]
	g.press_at(g.cell_center(c1))
	g.hold_now()
	g.release_at(g.cell_center(c1))
	assert_eq(btn.text, Texts.t("ui.sell_n", {"n": 22}), "segurar de novo desmarca")
	assert_eq([inv.items[0].x, inv.items[0].y], [int(inv.items[0].x), int(inv.items[0].y)])
	var before := inv.to_dict()
	btn.pressed.emit()
	assert_eq(got, [[0, 2]])
	assert_eq(inv.to_dict(), before, "nada muda de casa na venda")


func test_grimorio_com_buracos_desenha():
	var inv := Inventory.make(4, 3, [Vector2i(1, 1), Vector2i(2, 1)])
	inv.add("faisca")
	inv.add("chave")
	var o := Organizer.open(_parent(), inv)
	await wait_process_frames(2)
	var g: GrimoireView = _find(o, GrimoireView)
	assert_eq(g.item_under(Vector2i(1, 1)), -1)
	_hold_drag(g, Vector2i(0, 0), Vector2i(1, 1))
	assert_eq([inv.items[0].x, inv.items[0].y], [0, 0], "buraco não é casa")


func test_nome_cabe_na_peca():
	var f := Kit.title_font()
	var fit := GrimoireView.fit_name("Chave de Braço Didática", 80, 18, 13, 3, ThemeDB.fallback_font)
	assert_between(fit.lines.size(), 1, 3)
	for l in fit.lines:
		assert_true(ThemeDB.fallback_font.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, fit.fs).x <= 80, l)
	assert_not_null(f)


func test_miniatura_do_formato():
	var c := GrimoireView.shape_preview("bola", 0, 18)
	add_child_autofree(c)
	var n := Spells.shape("bola").size()
	assert_true(c.custom_minimum_size.x >= 18 and c.custom_minimum_size.y >= 18)
	assert_eq(n, 4)
	var w := GrimoireView.shape_preview("escudo", 1, 10)
	add_child_autofree(w)
	var z := GrimoireView.shape_preview("escudo", 0, 10)
	add_child_autofree(z)
	assert_ne(w.custom_minimum_size, z.custom_minimum_size, "gira")
	await wait_process_frames(1)
