extends SceneTree
## Capturas do grimório fora da luta: organizar (com peça levantada e fantasma), a
## Moldura com buracos e o Descartar, a magia nova na mão (place_new), a venda de
## várias peças e as miniaturas do formato (uso manual: precisa de vídeo).
## godot -s res://sim/shot_grimorio.gd -- --out=/caminho [--tag=celular]
var out := "user://"
var tag := ""
var host: Control


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		if a.begins_with("--tag="):
			tag = "_" + a.substr(6)
	_run.call_deferred()


func _shot(name: String) -> void:
	for i in 4:
		await process_frame
	get_root().get_texture().get_image().save_png(out + "/" + name + tag + ".png")


func _fresh() -> Control:
	if host:
		host.free()
	host = Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(host)
	var bg := ColorRect.new()
	bg.color = Kit.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(bg)
	return host


func _view(o: Overlay) -> GrimoireView:
	return o.find_children("*", "GrimoireView", true, false)[0]


func _run() -> void:
	# 1. Organizar: grimório 4x3 cheio de formatos, uma peça levantada no meio do arrasto.
	var inv := Inventory.make(4, 3)
	inv.add_at("bola", 0, 0, 0)
	inv.add_at("chave", 2, 0, 0)
	inv.add_at("escudo", 3, 0, 0, 2)
	inv.add_at("forca", 2, 1, 0)
	inv.add_at("faisca", 0, 2, 0)
	inv.add_at("corte", 1, 2, 0)
	var o := Organizer.open(_fresh(), inv, Callable(), {"allow_discard": true, "new_item": 1})
	await _shot("organizar")
	var g := _view(o)
	g.press_at(g.cell_center(Vector2i(0, 2)))
	g.hold_now()
	g.move_to(g.cell_center(Vector2i(3, 2)))
	await _shot("organizar_arrasto")
	g.move_to(g.cell_center(Vector2i(2, 1)))
	await _shot("organizar_arrasto_vermelho")
	g.release_at(g.cell_center(Vector2i(2, 1)))
	var bi: int = inv.ids().find("bola")
	g.info_tapped.emit(bi)
	await _shot("organizar_info")
	# 2. Moldura do Copista (buracos no meio) e a confirmação do Descartar.
	var cop := Inventory.make(4, 3, [Vector2i(1, 1), Vector2i(2, 1)])
	cop.add_at("plagio", 0, 0, 1)
	cop.add_at("imitacao", 2, 0, 1)
	cop.add_at("dardo", 0, 1, 0)
	cop.add_at("meia_verdade", 3, 2, 0)
	o = Organizer.open(_fresh(), cop, Callable(), {"allow_discard": true})
	g = _view(o)
	await _shot("moldura")
	g.press_at(g.cell_center(Vector2i(0, 1)))
	g.hold_now()
	g.release_at(g.cell_center(Vector2i(0, 1)))
	o.find_children("*", "Button", true, false).filter(func(b): return b.text == Texts.t("ui.discard"))[0].pressed.emit()
	await _shot("descartar")
	# 3. Magia nova na mão: cabe; e não cabe (com Vender da peça levantada).
	var inv2 := Inventory.make(4, 3)
	inv2.add_at("bola", 0, 0, 0)
	inv2.add_at("faisca", 2, 0, 0)
	inv2.add_at("sangria", 3, 0, 0)
	o = Organizer.place_new(_fresh(), inv2, "escudo", 1, func(_r): pass, {"sell": func(i):
		inv2.remove(i)
		return 2})
	await _shot("nova_cabe")
	var full := Inventory.make(4, 3)
	for y in 3:
		for x in 4:
			full.add_at(["faisca", "dardo", "pico", "esquiva", "remendo", "mordida"][(x + y * 4) % 6], x, y, 0)
	o = Organizer.place_new(_fresh(), full, "bola", 1, func(_r): pass, {"sell": func(i):
		full.remove(i)
		return 2})
	g = _view(o)
	g.press_at(g.cell_center(Vector2i(3, 2)))
	g.hold_now()
	g.release_at(g.cell_center(Vector2i(3, 2)))
	await _shot("nova_sem_lugar")
	# 4. Venda de várias peças.
	o = Organizer.open_sell(_fresh(), inv, func(i): return Spells.sell_price(inv.items[i].id, int(inv.items[i].level)), func(_items): pass)
	g = _view(o)
	for c in [Vector2i(0, 0), Vector2i(2, 0)]:
		g.press_at(g.cell_center(c))
		g.hold_now()
		g.release_at(g.cell_center(c))
	await _shot("vender")
	# 5. Assassina (6x1) e as miniaturas do formato para os cartões de oferta.
	var asn := Inventory.make(6, 1)
	for id in ["estocada", "recuo", "virar", "sacrificio", "roubar_cena", "segunda"]:
		asn.add(id)
	o = Organizer.open(_fresh(), asn)
	await _shot("assassina")
	var h := _fresh()
	var row := Kit.hbox(24)
	row.position = Vector2(40, 40)
	h.add_child(row)
	for id in ["faisca", "escudo", "bola", "corte", "chave", "machadada", "pele", "sintese"]:
		var v := Kit.vbox(6)
		v.add_child(GrimoireView.shape_preview(id, 0, 18))
		v.add_child(Kit.label(Texts.spell_name(id), 16))
		row.add_child(v)
	await _shot("miniaturas")
	quit()
