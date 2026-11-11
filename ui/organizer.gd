class_name Organizer
extends RefCounted
## O grimório fora da luta (a mochila de magias). É o único lugar onde o formato das
## magias importa. Tocar e segurar uma peça a levanta: arrastando, ela muda de casa
## (solta na casa sob o dedo); "Girar" gira a peça levantada. Toque curto não move
## nada; o (i) de cada peça mostra o que ela faz no painel ao lado. O número em cada
## peça é a ordem em que ela acontece na luta.
##
## - open: organizar (opts.allow_discard + opts.on_discard: botão Descartar).
## - place_new: a magia nova "na mão", para escolher onde ela entra (Confirmar/Cancelar;
##   opts.sell vende a peça levantada ali mesmo).
## - open_sell: marcar várias peças (tocar e segurar) e vender de uma vez.


## opts: {allow_discard: bool, on_discard: Callable(item), new_item: int}.
## Compatível com a assinatura antiga: um int no lugar de opts é a peça nova marcada.
static func open(parent: Control, inv: Inventory, on_done: Callable = Callable(), opts = {}) -> Overlay:
	var o_: Dictionary = {"new_item": opts} if typeof(opts) == TYPE_INT else opts
	var new_item := int(o_.get("new_item", -1))
	var title := Texts.t("ui.grimoire")
	if new_item >= 0 and new_item < inv.items.size():
		title = Texts.t("ui.new_spell_title", {"name": Texts.spell_name(inv.items[new_item].id)})
	var s := Session.new(parent, inv, title, Texts.t("ui.done"), "organize", o_)
	s.g.new_item = new_item
	s.show_info(new_item)
	if bool(o_.get("allow_discard", false)):
		s.discard_btn = Kit.button(Texts.t("ui.discard"), s.ask_discard, Kit.DANGER.darkened(0.45), 24)
		s.discard_btn.custom_minimum_size = Vector2(200, 60)
		s.o.footer.add_child(s.discard_btn)
	s.sync_buttons()
	if on_done.is_valid():
		s.o.closed.connect(on_done)
	return s.o


## A magia nova (id, level) "na mão": o jogador escolhe onde ela entra. Confirmar chama
## on_result.call({x, y, rot}) SEM adicionar a peça; Cancelar (ou fechar) chama
## on_result.call({}). Mudanças de casa e vendas feitas aqui valem nos dois casos.
## opts.sell: Callable(item) -> int vende a peça levantada; opts.price_of: Callable(item)
## -> int é o preço mostrado (sem ele, Spells.sell_price).
static func place_new(parent: Control, inv: Inventory, id: String, level: int, on_result: Callable, opts := {}) -> Overlay:
	var s := Session.new(parent, inv, Texts.t("ui.new_spell_title", {"name": Texts.spell_name(id)}), Texts.t("ui.cancel"), "place", opts)
	s.on_result = on_result
	var spot := inv.find_spot(id)
	s.g.hand = {"id": id, "level": level, "x": int(spot.get("x", 0)), "y": int(spot.get("y", 0)),
		"rot": int(spot.get("rot", 0)), "ok": not spot.is_empty()}
	s.g.free_drag = GrimoireView.HAND
	s.g.selected_item = GrimoireView.HAND
	s.show_info(GrimoireView.HAND)
	if opts.has("sell"):
		s.sell_btn = Kit.button(Texts.t("ui.sell_none"), s.sell_selected, Kit.PANEL, 24)
		s.sell_btn.custom_minimum_size = Vector2(200, 60)
		s.o.footer.add_child(s.sell_btn)
	s.confirm_btn = Kit.primary_button(Texts.t("ui.confirm"), s.confirm, 26)
	s.confirm_btn.custom_minimum_size = Vector2(220, 60)
	s.o.footer.add_child(s.confirm_btn)
	s.o.closed.connect(func():
		if not s.resolved:
			s.resolved = true
			on_result.call({}))
	s.update_hand()
	return s.o


## Venda de várias magias: o grimório com o preço em cada peça; tocar e segurar marca
## ou desmarca. "Vender (N moedas)" fecha e chama on_sell.call(itens) (índices em ordem
## crescente). Nada muda de casa aqui.
static func open_sell(parent: Control, inv: Inventory, price_of: Callable, on_sell: Callable) -> Overlay:
	var s := Session.new(parent, inv, Texts.t("ui.sell_grimoire"), Texts.t("ui.close"), "sell", {})
	s.on_sell = on_sell
	for i in inv.items.size():
		s.g.prices[i] = int(price_of.call(i)) if price_of.is_valid() else Spells.sell_price(inv.items[i].id, int(inv.items[i].level))
	s.g.show_order = false
	s.hint.text = Texts.t("ui.sell_hint")
	s.sell_btn = Kit.primary_button(Texts.t("ui.sell_none"), s.sell_marked, 26)
	s.sell_btn.custom_minimum_size = Vector2(260, 60)
	s.o.footer.add_child(s.sell_btn)
	s.sync_buttons()
	return s.o


## Estado de uma janela do grimório. Fica viva enquanto a janela existir (meta "org").
class Session:
	extends RefCounted

	var o: Overlay
	var g: GrimoireView
	var inv: Inventory
	var mode := "organize" ## organize, place ou sell.
	var opts := {}
	var hint: Label
	var d_name: Label
	var d_desc: RichTextLabel
	var d_meta: Label
	var rot_btn: Button
	var discard_btn: Button
	var sell_btn: Button
	var confirm_btn: Button
	var on_result: Callable
	var on_sell: Callable
	var resolved := false
	var grab := Vector2i.ZERO ## Casa da peça que o dedo segura (em relação ao canto).
	var info_item := -1

	func _init(parent: Control, i: Inventory, title: String, close_text: String, m: String, op: Dictionary) -> void:
		inv = i
		mode = m
		opts = op
		o = Overlay.open(parent, title, close_text, 1180)
		o.set_meta("org", self)
		var row := Kit.hbox(28)
		o.body.add_child(row)
		# Grimório baixo e comprido (Assassina 6x1): a grade ganha largura do painel.
		var avail_w := 760.0 if inv.width >= 5 and inv.height <= 2 else 600.0
		var cell := mini(130, int(avail_w / inv.width))
		cell = mini(cell, int(420.0 / inv.height))
		var cc := CenterContainer.new()
		cc.custom_minimum_size = Vector2(avail_w, 420)
		row.add_child(cc)
		g = GrimoireView.new().setup(inv, cell)
		g.show_order = true
		g.show_info = true
		cc.add_child(g)
		var side := Kit.vbox(10)
		side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(side)
		hint = Kit.label(Texts.t("ui.place_hint" if mode == "place" else "ui.organize_hint"), 18, Kit.MUTED, true)
		side.add_child(hint)
		var detail := Kit.panel(Color(0.114, 0.102, 0.141))
		detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
		side.add_child(detail)
		var dv := Kit.vbox(8)
		detail.add_child(dv)
		d_name = Kit.label("", 30, Kit.TEXT, true)
		d_desc = ElementInfo.rich("", 20, Color(0.85, 0.83, 0.89)) ## Elementos citados: tocáveis.
		d_meta = Kit.label("", 18, Kit.MUTED, true)
		dv.add_child(d_name)
		dv.add_child(d_desc)
		dv.add_child(d_meta)
		show_info(-1)
		if mode != "sell":
			rot_btn = Kit.button(Texts.t("ui.rotate"), rotate, Kit.PANEL, 24)
			rot_btn.custom_minimum_size = Vector2(180, 60)
			o.footer.add_child(rot_btn)
		g.held.connect(_on_held)
		g.dragged.connect(_on_dragged)
		g.dropped.connect(_on_dropped)
		g.cell_tapped.connect(_on_tap)
		g.info_tapped.connect(show_info)

	## Painel ao lado: nome, nível, o que a magia faz e o lugar dela na luta.
	func show_info(item: int) -> void:
		info_item = item
		var it: Dictionary = {}
		if item == GrimoireView.HAND:
			it = g.hand
		elif item >= 0 and item < inv.items.size():
			it = inv.items[item]
		if it.is_empty():
			d_name.text = Texts.t("ui.pick_piece")
			ElementInfo.set_text(d_desc, "")
			d_meta.text = ""
			return
		var nm := Texts.spell_name(it.id)
		if int(it.level) > 1:
			nm += "  " + Texts.t("ui.level", {"n": it.level})
		d_name.text = nm
		var desc := Texts.spell_desc(it.id)
		if int(it.level) > 1 and Texts.scales_with_level(it.id):
			desc += "\n" + Texts.t("ui.level_fx", {"n": it.level, "fx": Texts.spell_fx(it.id, int(it.level))})
		ElementInfo.set_text(d_desc, desc)
		if item == GrimoireView.HAND:
			d_meta.text = Texts.t("ui.shape", {"n": Spells.shape(it.id).size()})
		else:
			d_meta.text = Texts.t("ui.piece_meta", {"n": Spells.shape(it.id).size(), "pos": inv.order().find(item) + 1})

	func _origin(item: int) -> Vector2i:
		var it: Dictionary = g.hand if item == GrimoireView.HAND else inv.items[item]
		return Vector2i(int(it.x), int(it.y))

	func _on_held(c: Vector2i, item: int) -> void:
		if mode == "sell":
			if item >= 0:
				if g.marked.has(item):
					g.marked.erase(item)
				else:
					g.marked[item] = true
				show_info(item)
				sync_buttons()
				g.refresh()
			return
		if item == -1:
			deselect()
			return
		if item != g.selected_item:
			deselect()
		g.selected_item = item
		grab = c - _origin(item)
		if item >= 0:
			hint.text = Texts.t("ui.organize_lifted")
		show_info(item)
		sync_buttons()
		g.refresh()

	## Canto da peça para a casa sob o dedo; a peça da mão não sai da grade.
	func _target(c: Vector2i, id: String, rot: int) -> Vector2i:
		var t := c - grab
		if not (grab in Spells.shape(id, rot)):
			t = c
		return t

	func _on_dragged(c: Vector2i, item: int) -> void:
		if mode == "sell" or item != g.selected_item or item == -1:
			return
		if item == GrimoireView.HAND:
			var t := _clamp_hand(_target(c, g.hand.id, int(g.hand.rot)))
			g.hand.x = t.x
			g.hand.y = t.y
			update_hand()
			return
		var it: Dictionary = inv.items[item]
		var rot := int(g.ghost.get("rot", it.rot))
		var t := _target(c, it.id, rot)
		_set_ghost(item, t.x, t.y, rot)

	func _on_dropped(c: Vector2i, item: int) -> void:
		if mode == "sell" or item == -1 or item != g.selected_item:
			return
		_on_dragged(c, item)
		if item == GrimoireView.HAND or g.ghost.is_empty():
			return
		if g.ghost.ok:
			inv.move(item, int(g.ghost.x), int(g.ghost.y), int(g.ghost.rot))
			g.ghost = {}
			hint.text = Texts.t("ui.organize_lifted")
		else:
			g.ghost = {} ## Não cabe: volta para onde estava.
			hint.text = Texts.t("ui.no_room")
		show_info(item)
		update_hand()
		g.refresh()

	func _on_tap(_c: Vector2i, item: int) -> void:
		if mode == "sell":
			if item >= 0:
				hint.text = Texts.t("ui.sell_hint")
			return
		if item == GrimoireView.HAND:
			deselect()
			g.selected_item = GrimoireView.HAND
			show_info(item)
		elif item >= 0 and item != g.selected_item:
			hint.text = Texts.t("ui.hold_hint")
		elif item == -1:
			deselect()
		sync_buttons()
		g.refresh()

	func deselect() -> void:
		g.selected_item = -1
		g.ghost = {}
		if mode == "organize":
			hint.text = Texts.t("ui.organize_hint")
		elif mode == "place":
			update_hand()
		sync_buttons()
		g.refresh()

	func _set_ghost(item: int, x: int, y: int, rot: int) -> void:
		var it: Dictionary = inv.items[item]
		g.ghost = {"id": it.id, "rot": rot, "x": x, "y": y, "ok": inv.can_place(it.id, rot, x, y, item)}
		g.refresh()

	## Girar: a peça levantada gira no lugar. Se não couber girada, fica o fantasma
	## vermelho até ser arrastada para um lugar livre. Sem peça levantada, gira a da mão.
	func rotate() -> void:
		var sel := g.selected_item
		if sel == -1 and mode == "place":
			sel = GrimoireView.HAND
		if sel == GrimoireView.HAND:
			g.hand.rot = (int(g.hand.rot) + 1) % 4
			var t := _clamp_hand(Vector2i(int(g.hand.x), int(g.hand.y)))
			g.hand.x = t.x
			g.hand.y = t.y
			update_hand()
			return
		if sel < 0:
			hint.text = Texts.t("ui.hold_hint")
			return
		var it: Dictionary = inv.items[sel]
		var rot := (int(g.ghost.get("rot", it.rot)) + 1) % 4
		var x := int(g.ghost.get("x", it.x))
		var y := int(g.ghost.get("y", it.y))
		if inv.can_place(it.id, rot, x, y, sel):
			inv.move(sel, x, y, rot)
			g.ghost = {}
			hint.text = Texts.t("ui.organize_lifted")
		else:
			_set_ghost(sel, x, y, rot)
			hint.text = Texts.t("ui.no_room")
		show_info(sel)
		update_hand()
		g.refresh()

	func _clamp_hand(t: Vector2i) -> Vector2i:
		var hi := Vector2i.ZERO
		for c in Spells.shape(g.hand.id, int(g.hand.rot)):
			hi = Vector2i(maxi(hi.x, c.x), maxi(hi.y, c.y))
		return Vector2i(clampi(t.x, 0, maxi(0, inv.width - hi.x - 1)), clampi(t.y, 0, maxi(0, inv.height - hi.y - 1)))

	## Recalcula se a peça da mão cabe onde está (e o Confirmar).
	func update_hand() -> void:
		if g.hand.is_empty():
			return
		g.hand.ok = inv.can_place(g.hand.id, int(g.hand.rot), int(g.hand.x), int(g.hand.y))
		if g.selected_item == -1 or g.selected_item == GrimoireView.HAND:
			if g.hand.ok:
				hint.text = Texts.t("ui.place_hint")
			else:
				hint.text = Texts.t("ui.place_no_room" if opts.has("sell") else "ui.place_no_room_nosell")
		sync_buttons()
		g.refresh()

	func price_of(item: int) -> int:
		var pf: Callable = opts.get("price_of", Callable())
		if pf.is_valid():
			return int(pf.call(item))
		return Spells.sell_price(inv.items[item].id, int(inv.items[item].level))

	func sync_buttons() -> void:
		var sel := g.selected_item
		if discard_btn:
			discard_btn.disabled = sel < 0
		if sell_btn and mode == "place":
			sell_btn.disabled = sel < 0
			sell_btn.text = Texts.t("ui.sell_short", {"n": price_of(sel)}) if sel >= 0 else Texts.t("ui.sell_none")
		if sell_btn and mode == "sell":
			var total := 0
			for k in g.marked:
				total += int(g.prices.get(k, 0))
			sell_btn.disabled = g.marked.is_empty()
			sell_btn.text = Texts.t("ui.sell_n", {"n": total}) if total > 0 or not g.marked.is_empty() else Texts.t("ui.sell_none")
		if confirm_btn:
			confirm_btn.disabled = not bool(g.hand.get("ok", false))

	func confirm() -> void:
		if resolved or not bool(g.hand.get("ok", false)):
			return
		resolved = true
		var target := {"x": int(g.hand.x), "y": int(g.hand.y), "rot": int(g.hand.rot)}
		o.close()
		on_result.call(target)

	## Vende a peça levantada (place_new com opts.sell).
	func sell_selected() -> void:
		var sel := g.selected_item
		if sel < 0 or not opts.has("sell"):
			return
		g.selected_item = -1
		g.ghost = {}
		opts.sell.call(sel)
		show_info(GrimoireView.HAND)
		g.selected_item = GrimoireView.HAND
		update_hand()

	func sell_marked() -> void:
		if g.marked.is_empty():
			return
		var items: Array = g.marked.keys()
		items.sort()
		o.close()
		if on_sell.is_valid():
			on_sell.call(items)

	## Descartar com confirmação: a magia some sem dar nada.
	func ask_discard() -> void:
		var sel := g.selected_item
		if sel < 0:
			return
		var c := Overlay.open(o, Texts.t("ui.discard_title", {"name": Texts.spell_name(inv.items[sel].id)}), Texts.t("ui.cancel"), 560)
		c.add_text(Texts.t("ui.discard_warn"), 22)
		var yes := Kit.button(Texts.t("ui.discard"), func():
			c.close()
			discard(sel), Kit.DANGER.darkened(0.3), 24)
		yes.custom_minimum_size = Vector2(220, 60)
		c.footer.add_child(yes)

	func discard(item: int) -> void:
		var cb: Callable = opts.get("on_discard", Callable())
		g.selected_item = -1
		g.ghost = {}
		if cb.is_valid():
			cb.call(item)
		else:
			inv.remove(item)
		if g.new_item == item:
			g.new_item = -1
		elif g.new_item > item:
			g.new_item -= 1
		show_info(-1)
		hint.text = Texts.t("ui.organize_hint")
		sync_buttons()
		g.refresh()
