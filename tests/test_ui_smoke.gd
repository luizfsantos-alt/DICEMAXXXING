extends GutTest
## Fumaça da interface: monta todas as telas e joga pela UI.


func after_each():
	SaveGame.clear()


func _run_at_duel(s: int) -> RunState:
	var run := RunState.new_run(s)
	run.choose(0) ## Erudito
	run.choose(0) ## Porta
	return run


func test_menu_abre():
	var main = load("res://ui/main.tscn").instantiate()
	add_child_autofree(main)
	await wait_process_frames(2)
	assert_true(main.current is MenuScreen)


func test_nova_jornada_pela_raiz():
	var main = load("res://ui/main.tscn").instantiate()
	add_child_autofree(main)
	await wait_process_frames(2)
	main._on_new_run("sorcerer")
	await wait_process_frames(2)
	assert_true(main.current is TowerScreen, "começa na escolha do Erudito")
	var t: TowerScreen = main.current
	t._pick(0)
	await wait_process_frames(2)
	assert_true(main.current is TowerScreen, "portas")
	assert_eq(main.run.phase, "doors")
	main.current._pick(0)
	await wait_process_frames(2)
	assert_true(main.current is DuelScreen)


func test_duelo_pela_interface():
	var run := _run_at_duel(321)
	var d := DuelScreen.new().setup(run)
	d.fast = true
	add_child_autofree(d)
	await wait_process_frames(2)
	assert_eq(d.tray_views.size(), Config.HAND_SIZE)
	var faisca := run.duel.player.inventory.ids().find("faisca")
	d._on_die(d.tray_views[0])
	assert_eq(d.selected, 0)
	d._on_card(faisca)
	assert_eq(d.choice.dice_in(faisca), [0], "dado posto na Faísca")
	d._on_die(d.tray_views[0])
	assert_eq(d.choice.used_dice(), [], "tocar no dado posto devolve")
	d._on_die(d.tray_views[0])
	d._on_card(faisca)
	var turn := run.duel.turn
	await d._submit()
	await wait_process_frames(2)
	assert_true(run.duel.turn > turn or run.duel.state != "choosing", "turno resolvido pela UI")
	if run.duel.state == "choosing":
		assert_eq(d.phase, "player")
		assert_eq(d.choice.used_dice(), [], "novo turno começa com magias vazias")
	assert_gt(d.history.size(), 0, "histórico registrado")


func test_exigencia_recusa_dado_errado():
	var run := _run_at_duel(5)
	var p := run.duel.player
	p.inventory.add("escudo") ## Não vem mais no kit inicial.
	var escudo := p.inventory.ids().find("escudo")
	p.hand[0].value = 6
	var d := DuelScreen.new().setup(run)
	d.fast = true
	add_child_autofree(d)
	await wait_process_frames(2)
	assert_false(d.place(0, escudo), "Escudo Arcano só aceita até 3")
	assert_true(d.info.text.length() > 0)


func test_luta_inteira_e_fim():
	var run := _run_at_duel(8)
	run.duel.enemy.hp = 1
	run.duel.enemy.max_hp = 1
	var d := DuelScreen.new().setup(run)
	d.fast = true
	add_child_autofree(d)
	await wait_process_frames(2)
	var faisca := run.duel.player.inventory.ids().find("faisca")
	d._on_die(d.tray_views[0])
	d._on_card(faisca)
	await d._submit()
	assert_eq(d.phase, "over")
	d._finish()
	assert_eq(run.phase, "reward")


func test_consulta_do_inimigo():
	var run := _run_at_duel(9)
	var d := DuelScreen.new().setup(run)
	d.fast = true
	add_child_autofree(d)
	await wait_process_frames(2)
	var o := d.open_enemy_consult()
	await wait_process_frames(1)
	assert_true(is_instance_valid(o) and o.is_inside_tree())


func test_torre_loja_poco_bolsa_e_grimorio():
	var run := RunState.new_run(5)
	run.choose(0)
	run.coins = 100
	run.phase = "well"
	run.options = Shop.well(run.rng)
	var t := TowerScreen.new().setup(run)
	add_child_autofree(t)
	await wait_process_frames(2)
	t._pick(0) ## Adesivo: abre a escolha de face.
	await wait_process_frames(1)
	assert_true(t.get_children().any(func(x): return x is Overlay))
	t._apply(0, {"die": 1, "face": 4})
	assert_eq(run.hero.bag[1].value(4), 7)
	var o := Organizer.open(t, run.hero.inventory)
	await wait_process_frames(1)
	assert_true(o.is_inside_tree())
	BagPanel.open(t, run.hero.bag)
	t._leave()
	assert_eq(run.phase, "rest", "Voltar leva à parada")
	run.leave()
	assert_eq(run.phase, "doors")
	run.phase = "shop"
	run.options = Shop.shop(run.hero, run.rng, 0)
	t.refresh()
	assert_gt(t.sell_row.get_child_count(), 1, "pode vender magias na loja")


func test_organizar_move_peca():
	var inv := Inventory.make(4, 3)
	inv.add("faisca")
	var parent := Control.new()
	add_child_autofree(parent)
	var o := Organizer.open(parent, inv)
	await wait_process_frames(1)
	var g: GrimoireView = _find(o, GrimoireView)
	# Tocar e segurar levanta; arrastar e soltar muda de casa.
	g.press_at(g.cell_center(Vector2i(0, 0)))
	g.hold_now()
	g.move_to(g.cell_center(Vector2i(3, 2)))
	g.release_at(g.cell_center(Vector2i(3, 2)))
	assert_eq([inv.items[0].x, inv.items[0].y], [3, 2])


func _find(n: Node, cls) -> Node:
	for c in n.get_children():
		if is_instance_of(c, cls):
			return c
		var r := _find(c, cls)
		if r:
			return r
	return null


func test_fim_de_jornada():
	var run := RunState.new_run(5)
	run.phase = "defeat"
	var e := EndScreen.new().setup(run)
	add_child_autofree(e)
	await wait_process_frames(2)
	assert_true(e.get_child_count() > 0)


func test_fim_mostra_quem_venceu_e_titulo():
	var run := RunState.new_run(5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	run.nemesis = EnemyFactory.create(4, "normal", rng)
	run.phase = "defeat"
	var back := RunState.from_dict(run.to_dict())
	assert_eq(back.nemesis.archetype, run.nemesis.archetype, "o vencedor vai no save")
	assert_eq(run.nemesis.name, "", "inimigo comum não tem nome")
	var e := EndScreen.new().setup(run)
	add_child_autofree(e)
	await wait_process_frames(2)
	assert_not_null(e.quote_label, "fala do vencedor")
	assert_true(e.quote_label.text.begins_with("“"))
	assert_not_null(e.honor_label, "título póstumo")
	var e2 := EndScreen.new().setup(run)
	add_child_autofree(e2)
	assert_eq(e2.quote_label.text, e.quote_label.text, "a fala não muda ao reabrir")


func test_bolsa_desenha_os_dados():
	var run := RunState.new_run(5)
	run.hero.bag[0].element = "Na"
	run.hero.bag[0].stickers[5] = 1
	var host := Control.new()
	add_child_autofree(host)
	var o := BagPanel.open(host, run.hero.bag)
	await wait_process_frames(1)
	var icons := []
	var stack: Array = [o]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is DieIcon:
			icons.append(n)
		stack.append_array(n.get_children())
	assert_eq(icons.size(), run.hero.bag.size() * 6, "uma face desenhada por face")
	assert_true(icons.any(func(i): return i.element == "Na" and i.stickers == 1), "selo +2 no dado de Sódio")


func test_escolher_face_sem_rolar():
	var run := RunState.new_run(5)
	for k in 8:
		run.hero.bag.append(Die.basic()) ## Bolsa grande: 16 dados.
	run.hero.bag[2].add_gold(4)
	var frame := Control.new()
	frame.size = Vector2(1280, 720)
	add_child_autofree(frame)
	var picked := []
	var o := BagPanel.open(frame, run.hero.bag, "face", func(d, f): picked.append([d, f]))
	await wait_process_frames(2)
	assert_eq(_nodes_of(o, ScrollContainer).size(), 0, "sem rolagem")
	var cells: Array = _nodes_of(o, Button).filter(func(b): return b.get_parent() is GridContainer)
	cells.sort_custom(func(x, y): return x.get_index() < y.get_index())
	assert_eq(cells.size(), run.hero.bag.size(), "um botão por dado")
	for c in cells:
		var r: Rect2 = c.get_global_rect()
		assert_true(r.end.y <= 720 and r.position.y >= 0, "o dado cabe na tela")
	assert_true(_nodes_of(o, DieIcon).any(func(i): return i.gold == 1), "a moeda do adesivo de ouro aparece")
	cells[2].pressed.emit()
	await wait_process_frames(1)
	var faces: Array = _nodes_of(o, Button).filter(func(b): return b.get_child_count() > 0 and b.get_child(0) is DieIcon)
	faces.sort_custom(func(x, y): return x.get_index() < y.get_index())
	assert_eq(faces.size(), 6, "as 6 faces do dado escolhido")
	faces[4].pressed.emit()
	assert_eq(picked, [[2, 4]])


func _nodes_of(root: Node, type: Variant) -> Array:
	var out := []
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if is_instance_of(n, type):
			out.append(n)
		stack.append_array(n.get_children())
	return out


func test_cartoes_buracos_previa_e_historico():
	var run := _run_at_duel(12)
	var p := run.duel.player
	p.inventory.add("escudo") ## Não vem mais no kit inicial.
	var faisca := p.inventory.ids().find("faisca")
	var escudo := p.inventory.ids().find("escudo")
	p.hand[0].value = 6
	var d := DuelScreen.new().setup(run)
	d.fast = true
	add_child_autofree(d)
	await wait_process_frames(2)
	assert_eq(d.cards.size(), p.inventory.items.size(), "um cartão por magia")
	d._on_die(d.tray_views[0])
	var fc: SpellCard = d._card_of(d.cards, faisca)
	var ec: SpellCard = d._card_of(d.cards, escudo)
	assert_true(fc.holes[0].lit, "Faísca aceita o 6: buraco aceso")
	assert_false(ec.holes[0].lit, "Escudo Arcano não aceita 6")
	d._on_card(faisca)
	assert_true(fc.holes[0].has_die, "dado encaixado no buraco")
	assert_false(d.tray_views[0].has_die, "buraco da mão fica vazio")
	assert_eq(fc.preview.text, Texts.t("ui.pv_dmg", {"n": 6}))
	var o := d.open_history()
	await wait_process_frames(1)
	assert_true(o.is_inside_tree(), "histórico abre por botão")


func test_ganhar_magia_abre_o_grimorio():
	var run := RunState.new_run(5)
	var t := TowerScreen.new().setup(run)
	add_child_autofree(t)
	await wait_process_frames(2)
	assert_eq(run.phase, "start_pick")
	var n := run.hero.inventory.items.size()
	t._apply(0, {})
	await wait_process_frames(1)
	assert_eq(run.hero.inventory.items.size(), n + 1)
	assert_true(is_instance_valid(t.organizer) and t.organizer.is_inside_tree(), "grimório abre com a magia nova")
	var g: GrimoireView = _find(t.organizer, GrimoireView)
	assert_eq(g.new_item, n, "a nova magia vem marcada")
	assert_eq(run.phase, "doors", "a escolha já valeu")
	t.organizer.close()


func test_inimigo_encaixa_dados_nas_magias_dele():
	var run := _run_at_duel(321)
	var d := DuelScreen.new().setup(run)
	d.fast = true
	add_child_autofree(d)
	await wait_process_frames(2)
	await d._submit()
	if run.duel.state != "choosing":
		return
	var filled := 0
	for c in d.enemy_cards:
		for h in c.holes:
			if h.has_die:
				filled += 1
	assert_gt(filled, 0, "dados do inimigo ficam nos buracos das magias dele")
	assert_true(d.tray_views[0].interactive, "a bandeja volta a ser a sua mão")


func test_menu_oferece_os_jogaveis_com_retrato():
	var main = load("res://ui/main.tscn").instantiate()
	add_child_autofree(main)
	await wait_process_frames(2)
	var m: MenuScreen = main.current
	assert_eq(m.picks.size(), Characters.PLAYABLE.size())
	for b in m.picks:
		assert_eq(b.find_children("*", "Portrait", true, false).size(), 1, "cartão com retrato")
		assert_true(b.size.x <= MenuScreen.CARD.x + 1, "cartão compacto")
	m.picks[Characters.PLAYABLE.find("barbarian")].pressed.emit()
	await wait_process_frames(2)
	assert_eq(main.run.character, "barbarian")
	assert_eq(main.run.phase, "doors")
	assert_true(main.current is TowerScreen)


func test_luta_com_cada_jogavel_pela_interface():
	for id in Characters.PLAYABLE:
		var run := RunState.new_run(42, id)
		if run.phase == "start_pick":
			run.choose(0) ## Erudito
		run.choose(0) ## Porta
		var d := DuelScreen.new().setup(run)
		d.fast = true
		add_child_autofree(d)
		await wait_process_frames(2)
		assert_eq(d.tray_views.size(), run.duel.player.hand.size(), id)
		var guard := 0
		while run.duel.state == "choosing" and guard < 40:
			guard += 1
			d.choice = EnemyAI.choose(run.duel.player, run.duel.enemy, H_rng())
			await d._submit()
		assert_ne(run.duel.state, "choosing", "%s termina a luta" % id)
		d.queue_free()


func test_ofertas_mostram_raridade():
	var run := RunState.new_run(8, "vampire")
	run.phase = "shop"
	run.options = Shop.shop(run.hero, run.rng, 0, 5)
	var t := TowerScreen.new().setup(run)
	add_child_autofree(t)
	await wait_process_frames(2)
	assert_eq(TowerScreen.offer_rarity(run.options[0]), Spells.rarity(run.options[0].id))
	assert_eq(t.cards.get_child_count(), run.options.size())


func test_mestre_e_bolsa_na_torre():
	var run := RunState.new_run(8, "minimalist")
	run.phase = "master_reward"
	run.options = Shop.master_reward()
	var t := TowerScreen.new().setup(run)
	add_child_autofree(t)
	await wait_process_frames(2)
	assert_eq(t.cards.get_child_count(), 3)
	var o := BagPanel.open(t, run.hero.bag)
	await wait_process_frames(1)
	assert_not_null(o)


func H_rng() -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = 3
	return r


# ================================================================== Layout da luta
## Tela da luta num quadro 1280×720, como no celular em paisagem.
func _duel_in_frame(run: RunState) -> DuelScreen:
	var frame := Control.new()
	frame.size = Vector2(1280, 720)
	add_child_autofree(frame)
	var d := DuelScreen.new().setup(run)
	d.fast = true
	frame.add_child(d)
	return d


func _press(on: bool) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = on
	return e


func test_grade_calcula_colunas_e_encolhe():
	var avail := Vector2(792, 550)
	var one := FitGrid.arrange(1, avail, DuelScreen.CARD, 10)
	assert_eq(one.scale, 1.0, "uma magia fica no tamanho padrão")
	var three := FitGrid.arrange(3, avail, DuelScreen.CARD, 10)
	assert_eq([three.cols, three.rows, three.scale], [3, 1, 1.0], "três numa linha, tamanho padrão")
	var twelve := FitGrid.arrange(12, avail, DuelScreen.CARD, 10)
	assert_lt(twelve.scale, 1.0, "doze encolhem")
	assert_true(twelve.cols * twelve.rows >= 12)
	var w: float = twelve.cols * DuelScreen.CARD.x * twelve.scale + 10 * (twelve.cols - 1)
	var h: float = twelve.rows * DuelScreen.CARD.y * twelve.scale + 10 * (twelve.rows - 1)
	assert_true(w <= avail.x + 0.5 and h <= avail.y + 0.5, "doze cabem sem rolagem")


func test_palco_cabe_todas_as_magias():
	var pool := ["faisca", "bola", "foto", "transfusao"]
	for n in [1, 3, 6, 12]:
		var run := _run_at_duel(77)
		var p := run.duel.player
		p.inventory = Inventory.make(12, 12)
		for k in n:
			assert_true(p.inventory.add(pool[k % pool.size()]), "cabe no inventário")
		var d := _duel_in_frame(run)
		await wait_process_frames(4)
		var g := d.player_grid
		assert_true(g.visible)
		assert_eq(g.visible_children().size(), n, "%d magias no palco" % n)
		assert_gt(g.size.x, 100.0)
		var rects := []
		for c in g.visible_children():
			var r := FitGrid.visual_rect(c)
			assert_true(Rect2(Vector2.ZERO, g.size).grow(0.5).encloses(r), "%d magias: cartão dentro do palco" % n)
			assert_true(r.size.x <= DuelScreen.CARD.x + 0.5 and r.size.y <= DuelScreen.CARD.y + 0.5, "não estica além do padrão")
			for o in rects:
				assert_false(r.grow(-0.5).intersects(o), "%d magias: sem sobreposição" % n)
			rects.append(r)
		if n <= 3:
			assert_eq(g.fit_scale, 1.0, "%d magias: tamanho padrão" % n)
		var anc: Node = g
		while anc:
			assert_false(anc is ScrollContainer, "sem rolagem")
			anc = anc.get_parent()


func test_palco_e_dados_trocam_por_turno():
	var run := _run_at_duel(321)
	var d := _duel_in_frame(run)
	await wait_process_frames(2)
	assert_eq(d.stage_side(), "player")
	assert_true(d.player_grid.visible and not d.enemy_grid.visible)
	assert_eq(d.dice_side, "player")
	var sides := []
	d.stage_changed.connect(func(s): sides.append(s))
	await d._submit()
	await wait_process_frames(2)
	assert_true("enemy" in sides, "o palco mostrou as magias do inimigo na vez dele")
	if run.duel.state != "choosing":
		return
	assert_eq(sides.back(), "player", "no turno seguinte o palco volta para você")
	assert_true(d.player_grid.visible and not d.enemy_grid.visible)
	assert_eq(d.dice_side, "player")
	assert_true(d.tray_views[0].interactive)
	# A coluna de dados mostra os dados do inimigo na vez dele.
	await d._apply_event({"t": "turn", "side": "enemy"})
	assert_eq(d.stage_side(), "enemy")
	assert_true(d.enemy_grid.visible and not d.player_grid.visible)
	await d._apply_event({"t": "hand", "side": "enemy", "values": [3, 5, 1], "elements": []})
	assert_eq(d.dice_side, "enemy")
	assert_eq(d.tray_views.size(), 3)
	assert_false(d.tray_views[0].interactive, "dados do inimigo não são tocáveis")
	d.skip = true ## Tocou para acelerar o turno do inimigo.
	d._start_player_phase()
	assert_false(d.skip, "a sua vez volta com as animações (mexidas voam e giram)")
	assert_eq(d.stage_side(), "player")
	assert_eq(d.dice_side, "player")
	assert_eq(d.tray_views.size(), run.duel.player.hand.size())


func test_segurar_a_foto_do_inimigo():
	var run := _run_at_duel(12)
	var d := _duel_in_frame(run)
	await wait_process_frames(2)
	var faisca := run.duel.player.inventory.ids().find("faisca")
	d._on_die(d.tray_views[0])
	d._on_card(faisca)
	assert_eq(d.choice.dice_in(faisca), [0])
	d._on_enemy_photo_input(_press(true))
	assert_true(d.peeking)
	assert_eq(d.stage_side(), "enemy", "segurando: magias do inimigo")
	assert_true(d.enemy_grid.visible and not d.player_grid.visible)
	# Só leitura: tocar numa magia do inimigo não muda nada.
	d.enemy_cards[0]._gui_input(_press(false))
	assert_eq(d.choice.used_dice(), [0])
	d._on_enemy_photo_input(_press(false))
	assert_false(d.peeking)
	assert_eq(d.stage_side(), "player", "soltar volta para as suas magias")
	assert_true(d.player_grid.visible and not d.enemy_grid.visible)
	assert_eq(d.choice.dice_in(faisca), [0], "dados encaixados preservados")
	var fc: SpellCard = d._card_of(d.cards, faisca)
	assert_true(fc.holes[0].has_die)


func _icon(d: DuelScreen, side: String, id: String) -> StatusIcon:
	for ic in d.status_icons(side):
		if ic.id == id:
			return ic
	return null


func test_icones_de_status():
	var run := _run_at_duel(12)
	var d := _duel_in_frame(run)
	await wait_process_frames(2)
	var e := run.duel.enemy
	var p := run.duel.player
	assert_null(_icon(d, "enemy", "poison"))
	e.poison = 3
	e.burn = 2
	p.block = 5
	d._sync_shown()
	var pi := _icon(d, "enemy", "poison")
	assert_not_null(pi, "veneno aparece")
	assert_eq(pi.count, 3)
	assert_eq(_icon(d, "enemy", "burn").count, 2)
	assert_eq(_icon(d, "player", "block").count, 5, "bloqueio é um ícone de status")
	assert_eq(d.bars.player.shield, 0, "a barra de vida não mostra mais o bloqueio")
	# Segurar mostra nome e descrição; soltar fecha.
	pi._gui_input(_press(true))
	assert_true(d.tip.visible)
	assert_string_contains(d.tip_title.text, Texts.t("status.poison.0"))
	assert_eq(d.tip_desc.text, Texts.t("status.poison.1"))
	pi._gui_input(_press(false))
	assert_false(d.tip.visible)
	e.poison = 1
	d._sync_shown()
	assert_eq(_icon(d, "enemy", "poison").count, 1, "contagem atualiza")
	e.poison = 0
	p.block = 0
	d._sync_shown()
	assert_null(_icon(d, "enemy", "poison"), "veneno some em 0")
	assert_null(_icon(d, "player", "block"), "bloqueio some em 0")
	assert_not_null(_icon(d, "enemy", "burn"))
	assert_eq(d.status_icons("enemy").size(), 1)


func test_arrastar_dados_entre_magias_e_soltar_com_toque():
	var run := _run_at_duel(77)
	var p := run.duel.player
	p.inventory.add("corte")
	var faisca := p.inventory.ids().find("faisca")
	var corte := p.inventory.ids().find("corte")
	assert_gt(corte, -1, "Corte no grimório")
	var d := DuelScreen.new().setup(run)
	d.fast = true
	add_child_autofree(d)
	await wait_process_frames(2)
	var cc: SpellCard = d._card_of(d.cards, corte)
	assert_true(cc.holes[0].interactive, "buracos das suas magias são tocáveis")
	assert_true(d._can_drop_card(Vector2.ZERO, {"die": 0}, corte), "aceita dado arrastado")
	assert_false(d._can_drop_card(Vector2.ZERO, {"x": 1}, corte), "recusa outra coisa")
	# Arrasta o dado 0 para a Faísca, depois da Faísca para o Corte.
	d._drop_card(Vector2.ZERO, {"die": 0}, faisca)
	assert_eq(d.choice.dice_in(faisca), [0])
	d._drop_card(Vector2.ZERO, {"die": 0}, corte)
	assert_eq(d.choice.dice_in(faisca), [], "saiu da Faísca")
	assert_eq(d.choice.dice_in(corte), [0], "foi para o Corte")
	assert_eq(cc.holes[0].index, 0, "o buraco sabe qual dado tem")
	d._drop_card(Vector2.ZERO, {"die": 1}, corte)
	assert_eq(d.choice.dice_in(corte), [0, 1])
	# Tocar num dado encaixado solta só ele.
	d._on_card_hole(cc.holes[0], corte)
	assert_eq(d.choice.dice_in(corte), [1], "tocar no buraco solta o dado")
	# Arrastar de volta para a coluna também solta.
	d._drop_tray(Vector2.ZERO, {"die": 1})
	assert_eq(d.choice.used_dice(), [], "dado volta para a mão")


func test_nao_termina_turno_com_magia_de_varios_dados_pela_metade():
	var run := _run_at_duel(78)
	var p := run.duel.player
	p.inventory.add("corte")
	var faisca := p.inventory.ids().find("faisca")
	var corte := p.inventory.ids().find("corte")
	var d := DuelScreen.new().setup(run)
	d.fast = true
	add_child_autofree(d)
	await wait_process_frames(2)
	var turn := run.duel.turn
	assert_true(d.move_die(0, corte))
	assert_eq(d.choice.incomplete_items(p), [corte])
	await d._submit()
	assert_eq(run.duel.turn, turn, "turno não termina com o Corte pela metade")
	assert_eq(d.phase, "player")
	assert_true(d.info.text.contains(Texts.spell_name("corte")), "explica qual magia falta")
	# Vazia pode: tira o dado do Corte e põe na Faísca.
	assert_true(d.move_die(0, faisca))
	assert_eq(d.choice.incomplete_items(p), [])
	await d._submit()
	assert_true(run.duel.turn > turn or run.duel.state != "choosing", "agora o turno resolve")


func test_efeitos_voam_da_magia_ate_o_alvo():
	var run := _run_at_duel(77)
	var d := DuelScreen.new().setup(run)
	d.fast = true
	add_child_autofree(d)
	await wait_process_frames(2)
	assert_not_null(d.enemy_photo.art, "arte provisória do inimigo")
	assert_not_null(d.player_photo.art, "arte provisória do aliado (de costas)")
	d.fast = false
	d.fx_src = d._center(d.cards[0])
	var before := d.bolts
	await d._effect("enemy", "−5", "dmg")
	assert_eq(d.bolts, before + 1, "dano com origem dispara o efeito")
	var floats := d.fx_layer.get_children().filter(func(c): return c is Label and c.get_meta("fx_side", "") == "enemy")
	assert_eq(floats.size(), 1, "número sobre o alvo")
	assert_eq(floats[0].text, "−5")
	assert_eq(floats[0].get_theme_color("font_color"), DuelScreen.FX_COLORS.dmg, "dano em vermelho")
	await d._effect("player", "+3", "heal", null)
	assert_eq(d.bolts, before + 1, "sem origem (veneno, queima) não voa")
	await wait_seconds(1.2)
	d.fast = true


func test_foto_sorteia_variacao_e_guarda():
	for arch in ["sorcerer", "vampire", "barbarian", "assassin", "copyist"]:
		var f := Fighter.new()
		f.archetype = arch
		var path := Portrait.art_path(f)
		assert_between(f.portrait, 0, Portrait.VARIATIONS - 1, "variação sorteada")
		assert_eq(Portrait.art_path(f), path, "mesma foto na próxima vez")
		assert_true(ResourceLoader.exists(path), "arte existe: " + path)
		assert_eq(Fighter.from_dict(f.to_dict()).portrait, f.portrait, "variação salva")


func test_mestre_e_variantes_tem_foto_propria():
	var casos := [["sorcerer", "porteiro", ""], ["assassin", "", "lixeiro"], ["sorcerer", "", "piromante"],
		["metallurgist", "", "fundidor"], ["minimalist", "", "monge"]]
	for c in casos:
		var f := Fighter.new()
		f.archetype = c[0]
		f.master_id = c[1]
		f.variant = c[2]
		var path := Portrait.art_path(f)
		assert_eq(path, Portrait.ART_DIR + (c[1] if c[1] != "" else c[2]) + "_1.png", "foto própria de " + str(c))
		assert_true(ResourceLoader.exists(path), "arte existe: " + path)
	# Variante sem foto própria cai na do arquétipo.
	var f2 := Fighter.new()
	f2.archetype = "vampire"
	f2.variant = "inexistente"
	assert_true(Portrait.art_path(f2).begins_with(Portrait.ART_DIR + "vampire_"), "sem foto própria usa a do arquétipo")


func test_icones_de_status_com_arte_e_placeholder():
	for id in StatusIcon.STYLE:
		var ic := StatusIcon.new().setup({"id": id, "n": 3})
		assert_not_null(ic.art, "ícone com arte: " + id)
		ic.free()
	# Sem arquivo: fica a sigla (placeholder).
	var ph := StatusIcon.new().setup({"id": "inexistente", "n": 2})
	assert_null(ph.art, "id sem arte cai na sigla")
	ph.free()
	var mod := StatusIcon.new().setup({"id": "mod_minus1", "n": 1})
	assert_eq(mod._key(), "hand_mod", "mexidas na mão usam o mesmo ícone")
	assert_not_null(mod.art, "mexida na mão tem arte")
	mod.free()


func test_cartao_de_magia_tem_icone_do_efeito():
	# Toda magia tem um ícone de tipo de efeito com arte.
	for id in Spells.DATA:
		var key := Spells.icon_key(id)
		assert_not_null(SpellCard.icon(key), "ícone de %s (%s)" % [id, key])
	assert_eq(Spells.icon_key("faisca"), "fx/dmg")
	assert_eq(Spells.icon_key("banquete"), "fx/drain")
	assert_eq(Spells.icon_key("bis"), "fx/dice")
	assert_eq(Spells.icon_key("escudo"), "status/block")
	assert_eq(Spells.icon_key("chave"), "status/hand_mod")


func test_cartoes_da_torre_tem_ilustracao():
	for id in ["facil", "normal", "dificil", "insana", "mestre"]:
		assert_not_null(TowerScreen.art({"kind": "door", "id": id}), "porta " + id)
	for id in ["shop", "heal", "school", "well"]:
		assert_not_null(TowerScreen.art({"kind": "stop", "id": id}), "parada " + id)
	for k in ["spell", "die", "element", "sticker", "maxhp", "evolve", "destroy", "slots", "hand", "rare_pick"]:
		assert_not_null(TowerScreen.art({"kind": k, "id": ""}), "oferta " + k)
	# Toda oferta que a torre gera tem ilustração.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var run := RunState.new_run(7)
	var all: Array = Shop.shop(run.hero, rng, 0, 3) + Shop.well(rng, 3, run.hero) + Shop.master_reward() + Shop.rest_stops(rng)
	for o in all:
		assert_not_null(TowerScreen.art(o), "arte de %s %s" % [o.kind, o.id])


func test_todo_arquetipo_tem_3_fotos():
	for arch in Portrait.COLORS:
		if arch in Portrait.PENDING_ART:
			continue ## Silhueta até chegar a arte (docs/ARTE_FALTANDO.md).
		for k in Portrait.VARIATIONS:
			assert_true(ResourceLoader.exists("%s%s_%d.png" % [Portrait.ART_DIR, arch, k + 1]), "foto %s %d" % [arch, k + 1])


func test_texturas_da_interface_e_fundos_existem():
	for name in Kit.NINE:
		assert_not_null(Kit.nine(name), "9-slice " + name)
	for bg in ["menu", "tower", "victory", "defeat", "tavern"]:
		assert_not_null(Kit.tex("res://assets/backgrounds/%s.jpg" % bg), "fundo " + bg)
	var c := Kit.coin(20)
	assert_true(c is TextureRect, "moeda com arte")
	c.free()
	var b := Kit.button("x", func(): pass)
	assert_true(b.get_theme_stylebox("normal") is StyleBoxTexture, "botão neutro usa textura")
	b.free()
	var bd := Kit.button("x", func(): pass, Kit.DANGER)
	assert_true(bd.get_theme_stylebox("normal") is StyleBoxFlat, "botão colorido continua liso")
	bd.free()


func test_menu_usa_logo_do_titulo():
	assert_not_null(Kit.tex(MenuScreen.TITLE_LOGO), "logo do título existe")
	var m := MenuScreen.new().setup()
	var found := false
	for n in m.find_children("*", "TextureRect", true, false):
		if (n as TextureRect).texture == Kit.tex(MenuScreen.TITLE_LOGO):
			found = true
	assert_true(found, "menu mostra o logo do título")
	m.free()


func test_moldura_e_fonte_dos_numeros_existem():
	for p in Portrait.FRAMES.values():
		assert_true(ResourceLoader.exists(Portrait.ART_DIR + p), "moldura: " + p)
	assert_true(ResourceLoader.exists("res://assets/fonts/Bungee-Regular.ttf"), "fonte dos números")


func test_fundo_da_batalha_e_a_mesa_de_feltro():
	var run := _run_at_duel(77)
	var d := DuelScreen.new().setup(run)
	d.fast = true
	add_child_autofree(d)
	await wait_process_frames(2)
	assert_not_null(d.felt, "fundo é a mesa de feltro")
	assert_eq(d.get_child(0), d.felt, "atrás de tudo")
	assert_eq(d.felt.felt.layers, FeltTable.FELT_LAYER)
	assert_false(d.felt.live(), "parada, a mesa não redesenha a cada quadro")
	# A rolagem usa o mundo da mesa (sombras e luz no feltro) e não vê o feltro.
	var r := DiceRoll3D.new().setup(Vector2(400, 300), d.felt)
	add_child_autofree(r)
	assert_eq(r.vp.world_3d, d.felt.vp.world_3d, "mesmo mundo 3D")
	assert_eq(r._cam.cull_mask & FeltTable.FELT_LAYER, 0, "a câmera da rolagem não vê o feltro")


func test_perspectiva_da_mesa_converte_coordenadas():
	FeltPaint.set_stage(Rect2(100, 50, 1000, 500))
	var k := FeltPaint.KEYSTONE
	# Embaixo nada muda; em cima a borda encolhe KEYSTONE para o centro.
	assert_eq(FeltPaint.warp(Vector2(100, 550)), Vector2(100, 550), "canto de baixo fica")
	assert_eq(FeltPaint.warp(Vector2(600, 50)), Vector2(600, 50), "centro de cima fica")
	var tl := FeltPaint.warp(Vector2(100, 50))
	assert_almost_eq(tl.x, 100.0 + 500.0 * k, 0.01, "canto de cima vai para o centro")
	assert_almost_eq(tl.y, 50.0, 0.01)
	# A metade de cima fica mais baixa que a de baixo (a parte longe encolhe).
	assert_true(FeltPaint.warp(Vector2(600, 300)).y < 300.0, "fileira de cima encolhe na altura")
	# Ida e volta.
	for g in [Vector2(130, 70), Vector2(600, 300), Vector2(1090, 540), Vector2(420, 180)]:
		var back := FeltPaint.unwarp(FeltPaint.warp(g))
		assert_almost_eq(back.x, g.x, 0.01, "ida e volta x %s" % g)
		assert_almost_eq(back.y, g.y, 0.01, "ida e volta y %s" % g)
	# Toque local: um controle no canto de cima responde onde aparece, não onde está.
	var c := Control.new()
	c.position = Vector2(100, 50)
	c.size = Vector2(100, 100)
	add_child_autofree(c)
	var seen := FeltPaint.warp(Vector2(110, 60)) - c.position
	assert_true(Rect2(Vector2.ZERO, c.size).has_point(FeltPaint.local_hit(c, seen)), "toque onde aparece")
	assert_false(Rect2(Vector2.ZERO, c.size).has_point(FeltPaint.local_hit(c, Vector2(2, 2))), "canto que sumiu não pega")
	FeltPaint.set_stage(Rect2())
	assert_eq(FeltPaint.warp(Vector2(5, 5)), Vector2(5, 5), "desligada: identidade")


func test_magias_pintadas_no_feltro_em_perspectiva():
	var run := _run_at_duel(12)
	var d := _duel_in_frame(run)
	await wait_process_frames(3)
	assert_true(FeltPaint.active(), "a luta liga a perspectiva do palco")
	assert_eq(FeltPaint.stage, d.stage_panel.get_global_rect())
	var c: SpellCard = d.cards[0]
	assert_true(c.get_theme_stylebox("panel") is StyleBoxEmpty, "sem painel: o feltro aparece")
	assert_true(c.holes[0].painted, "buracos pintados")
	assert_true(c.material is ShaderMaterial, "o cartão é tinta no feltro")
	assert_true(c.name_label.use_parent_material, "o texto usa a mesma tinta")
	assert_eq(c.holes[0].paint_material, SpellCard.paint_material(0.0), "buraco com tinta nova")
	assert_eq(c.holes[0].die_material, FeltPaint.warp_only(), "o dado posto entra na perspectiva")
	# Saída: o efeito sai de onde o cartão aparece.
	var shown := FeltPaint.warp(c.get_global_transform() * (c.size * 0.5)) - d.fx_layer.global_position
	assert_eq(d._center(c), shown, "efeitos partem do cartão como ele aparece")
	d.queue_free()
	await wait_process_frames(1)
	assert_false(FeltPaint.active(), "saiu da luta: sem perspectiva")


func _mouse(p: Vector2, button: bool, held: bool, last: Vector2) -> Vector2:
	var w := get_viewport().get_final_transform() * p
	var ev: InputEventMouse
	if button:
		var b := InputEventMouseButton.new()
		b.button_index = MOUSE_BUTTON_LEFT
		b.pressed = held
		ev = b
	else:
		var m := InputEventMouseMotion.new()
		m.relative = w - last
		ev = m
	ev.position = w
	ev.global_position = w
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	get_tree().root.push_input(ev)
	return w


func test_arrastar_dado_ate_o_buraco_em_perspectiva():
	var run := _run_at_duel(12)
	var p := run.duel.player
	var faisca := p.inventory.ids().find("faisca")
	var d := _duel_in_frame(run)
	await wait_process_frames(3)
	var fc: SpellCard = d._card_of(d.cards, faisca)
	var hole: Hole = fc.holes[0]
	var real := hole.get_global_rect().get_center()
	var to := FeltPaint.warp(real)
	assert_true(to.distance_to(real) > 3.0, "o buraco aparece fora do lugar real")
	# Toque: vale onde o buraco aparece, não onde o controle está.
	var r := hole.get_global_rect()
	var inv := hole.get_global_transform().affine_inverse()
	var seen_tl := FeltPaint.warp(r.position) + Vector2(3, 3)
	var gone_br := r.end - Vector2(3, 3)
	assert_false(r.has_point(seen_tl), "canto que aparece fica fora do lugar real")
	assert_true(hole._has_point(inv * seen_tl), "toque no canto que aparece pega")
	assert_false(hole._has_point(inv * gone_br), "toque no lugar real que sumiu não pega")
	var tv: Hole = d.tray_views[0]
	var from := tv.get_global_rect().get_center()
	# A janela do GUT fica por cima de tudo: escondida durante o toque.
	var gut_layer := get_tree().root.find_child("GutLayer", true, false) as CanvasLayer
	if gut_layer != null:
		gut_layer.visible = false
	var last := _mouse(from, true, true, Vector2.ZERO)
	await wait_process_frames(1)
	for k in 10:
		last = _mouse(from.lerp(to, (k + 1) / 10.0), false, true, last)
		await wait_process_frames(1)
	assert_true(get_viewport().gui_is_dragging(), "arrastando o dado")
	_mouse(to, true, false, last)
	await wait_process_frames(2)
	if gut_layer != null:
		gut_layer.visible = true
	assert_true(hole.has_die, "solto onde o buraco aparece: o dado entra")
	assert_eq(d.choice.dice_in(faisca), [0])


func test_numeros_nao_saem_da_tela():
	var run := _run_at_duel(321)
	var d := DuelScreen.new().setup(run)
	add_child_autofree(d)
	await wait_process_frames(2)
	d._float("player", "Peso Morto: +3 dado(s) e mais um texto bem comprido", Kit.TEXT)
	var l: Label = null
	for c in d.fx_layer.get_children():
		if c is Label:
			l = c
	assert_not_null(l, "texto criado")
	var grow := l.size.x * 0.05 ## O pulo de entrada passa um pouco do tamanho final.
	assert_true(l.position.x - grow >= 0.0, "não vaza pela esquerda")
	assert_true(l.position.x + l.size.x + grow <= d.fx_layer.size.x, "não vaza pela direita")


func test_botao_menu_perde_a_partida():
	var main = load("res://ui/main.tscn").instantiate()
	add_child_autofree(main)
	await wait_process_frames(2)
	assert_false(main.quit_btn.visible, "no menu, sem botão")
	main._on_new_run("vampire")
	await wait_process_frames(2)
	assert_true(main.quit_btn.visible, "na jornada, com botão")
	main._on_quit_pressed()
	assert_true(main.current is TowerScreen, "1º toque só pede confirmação")
	main._on_quit_pressed()
	await wait_process_frames(2)
	assert_true(main.current is MenuScreen, "voltou ao menu")
	assert_false(SaveGame.exists(), "partida apagada")


func test_voltar_na_jornada_pergunta_antes_de_sair():
	var main = load("res://ui/main.tscn").instantiate()
	add_child_autofree(main)
	await wait_process_frames(2)
	main._on_new_run("sorcerer")
	await wait_process_frames(2)
	main.on_back()
	assert_true(is_instance_valid(main.exit_dialog), "abre a pergunta")
	assert_eq(main.exit_dialog.footer.get_child_count(), 2, "continuar e sair")
	main.on_back()
	assert_null(main.exit_dialog, "voltar de novo fecha a pergunta")
	await wait_process_frames(2)
	assert_true(main.current is TowerScreen, "continua no jogo")


func test_acoes_da_mesma_magia_marcam_o_item():
	var run := _run_at_duel(321)
	var p: Fighter = run.duel.player
	var e: Fighter = run.duel.enemy
	var ev := []
	var choice := TurnChoice.new()
	for item in p.inventory.items.size():
		for h in p.hand.size():
			choice.place(p, item, h)
	Resolver.cast_all(p, e, choice, ev)
	var cast_seen := false
	for x in ev:
		if str(x.t) == "cast":
			cast_seen = true
			assert_false(x.has("of_item"), "o cast em si não leva a marca")
		elif cast_seen:
			assert_true(x.has("of_item"), "efeito %s marcado" % x.t)
	assert_true(DuelScreen._same_item({"of_item": 1}, {"of_item": 1}))
	assert_false(DuelScreen._same_item({"of_item": 1}, {"of_item": 2}))
	assert_false(DuelScreen._same_item({"t": "cast"}, {"of_item": 1}))


# ================================================================== Decisões na torre
func _find_all(n: Node, cls, out: Array = []) -> Array:
	if is_instance_of(n, cls):
		out.append(n)
	for c in n.get_children():
		_find_all(c, cls, out)
	return out


func test_recompensa_sem_titulo_e_com_icone_grande():
	var run := RunState.new_run(5)
	run.choose(0)
	run.phase = "reward"
	run.options = Shop.reward(run.hero, run.rng)
	var t := TowerScreen.new().setup(run)
	add_child_autofree(t)
	await wait_process_frames(2)
	assert_false(t.title.visible, "sem \"Recompensa: escolha uma\"")
	assert_eq(t.cards.get_child_count(), run.options.size())
	var icon: Button = t.cards.get_child(0).get_child(0)
	assert_gte(icon.custom_minimum_size.x, 200.0, "o ícone é o elemento principal")
	assert_true(icon.get_theme_stylebox("normal") is StyleBoxEmpty, "sem retângulo atrás")
	run.phase = "shop"
	t.refresh()
	assert_true(t.title.visible, "a Loja mantém o nome do lugar")


func test_nomes_curtos_ate_cinco_palavras():
	var run := RunState.new_run(5)
	var t := TowerScreen.new().setup(run)
	add_child_autofree(t)
	var opts := []
	for id in ["facil", "normal", "dificil", "insana", "mestre"]:
		opts.append({"kind": "door", "id": id})
	for id in ["shop", "heal", "school", "well"]:
		opts.append({"kind": "stop", "id": id})
	for id in Spells.DATA:
		opts.append({"kind": "spell", "id": id})
		opts.append({"kind": "evolve", "id": id})
	for el in Elements.LOOKS:
		opts.append({"kind": "die", "id": el})
		opts.append({"kind": "element", "id": el})
	for k in ["sticker", "destroy", "maxhp", "slots", "hand", "rare_pick"]:
		opts.append({"kind": k, "id": ""})
	for o in opts:
		var s := t.short_name(o)
		assert_false(s.begins_with("short."), "texto de %s" % o.kind)
		assert_lte(s.split(" ", false).size(), 5, "'%s' tem até 5 palavras" % s)
	assert_eq(t.short_name({"kind": "door", "id": "facil"}), Texts.t("doors.facil"), "porta: só o nome")


func test_i_abre_detalhes_sem_escolher():
	var run := RunState.new_run(5)
	run.choose(0)
	var t := TowerScreen.new().setup(run)
	add_child_autofree(t)
	await wait_process_frames(2)
	assert_eq(run.phase, "doors")
	var info_btn: Button = t.cards.get_child(0).get_child(1).get_child(1)
	var name_label: Label = t.cards.get_child(0).get_child(1).get_child(0)
	assert_eq(name_label.mouse_filter, Control.MOUSE_FILTER_IGNORE, "o nome não é tocável")
	info_btn.pressed.emit()
	await wait_process_frames(1)
	assert_true(is_instance_valid(t.details) and t.details.is_inside_tree(), "o i abre os detalhes")
	assert_eq(run.phase, "doors", "ler não escolhe")
	t.details.close()


func test_elementos_citados_viram_link():
	var s := Texts.master_desc("porteiro")
	assert_eq(ElementInfo.mentions(s), ["Pb"])
	assert_string_contains(ElementInfo.linkify(s), "[url=el:Pb]")
	assert_eq(ElementInfo.mentions("Dano igual ao valor."), [])
	assert_eq(ElementInfo.mentions("dados de Sódio e Hidrogênio"), ["Na", "H"])
	assert_eq(ElementInfo.linkify("a [b]"), "a [lb]b]", "colchete do texto não vira BBCode")
	var host := Control.new()
	add_child_autofree(host)
	var o := ElementInfo.open(host, "U")
	assert_true(o.is_inside_tree(), "o toque explica o elemento")


func test_faixa_do_jogador_mostra_bolsa_vida_e_moedas():
	var run := RunState.new_run(5)
	run.choose(0)
	run.hero.bag[0].element = "H"
	run.hero.bag[1].element = "H"
	run.coins = 17
	var t := TowerScreen.new().setup(run)
	add_child_autofree(t)
	await wait_process_frames(2)
	var c := PlayerStrip.counts(run.hero.bag)
	assert_eq(c[0], ["H", 2], "elementos primeiro")
	assert_eq(c[c.size() - 1], ["", run.hero.bag.size() - 2], "comuns por último")
	assert_eq(t.strip.coins_label.text, "17")
	assert_eq(t.strip.hp_label.text, "%d/%d" % [run.hero.hp, run.hero.max_hp])
	assert_eq(t.strip.chips.get_child_count(), c.size())
	assert_string_contains(t.strip.bag_button.text, str(run.hero.bag.size()))


func test_tremida_da_tela_por_faixa_de_dano():
	assert_eq(ScreenShake.tier(0, 40), 0)
	assert_eq(ScreenShake.tier(3, 40), 0, "abaixo de 10%: só a foto treme")
	assert_eq(ScreenShake.tier(4, 40), 1, "10%")
	assert_eq(ScreenShake.tier(10, 40), 2, "25%")
	assert_eq(ScreenShake.tier(19, 40), 2)
	assert_eq(ScreenShake.tier(20, 40), 3, "50%")
	assert_eq(ScreenShake.tier(32, 40), 4, "80%")
	assert_eq(ScreenShake.tier(40, 40), 5, "100%: quase uma explosão")
	assert_eq(ScreenShake.tier(99, 40), 5, "acima de 100% não passa da maior")
	var amps := ScreenShake.TIERS.map(func(r): return r[1])
	for k in range(1, amps.size()):
		assert_gt(amps[k], amps[k - 1], "cada faixa treme mais")


func test_golpe_grande_treme_a_tela_e_volta_ao_lugar():
	var run := _run_at_duel(77)
	var d := DuelScreen.new().setup(run)
	d.fast = true
	add_child_autofree(d)
	await wait_process_frames(2)
	var base := d.content.position
	d.fast = false
	await d._effect("enemy", "−3", "dmg", null, 0)
	assert_eq(d.last_shake, 0, "golpe pequeno não treme a tela")
	await d._effect("enemy", "−99", "dmg", null, 5)
	assert_eq(d.last_shake, 5)
	assert_gt(d.flash.color.a, 0.0, "clarão no golpe enorme")
	await wait_process_frames(3)
	assert_ne(d.content.position, base, "a tela está tremendo")
	d.shaker.start(1)
	assert_eq(d.shaker.level, 5, "tremida mais fraca não corta a mais forte")
	await wait_seconds(0.9)
	assert_eq(d.content.position, base, "volta ao lugar")
	assert_eq(d.content.rotation, 0.0)
	d.fast = true


func test_status_aparecem_quando_a_acao_acontece():
	var run := _run_at_duel(12)
	var d := _duel_in_frame(run)
	await wait_process_frames(2)
	var p := run.duel.player
	var e := run.duel.enemy
	var snap := func(): return {"player": p.status_state(), "enemy": e.status_state()}
	# Estado final do turno: veneno no inimigo e esquiva já gasta.
	p.dodge = 1
	var up := {"t": "dodge_up", "side": "player", "st": snap.call()}
	p.dodge = 0
	var cast := {"t": "cast", "side": "player", "spell": "faisca", "item": 0, "dice": [], "values": [1], "st": snap.call()}
	e.poison = 3
	d._animate([cast], false)
	await wait_process_frames(1)
	assert_null(_icon(d, "enemy", "poison"), "o veneno só aparece quando chega")
	await d._animate([up], false)
	assert_not_null(_icon(d, "player", "dodge"), "esquiva guardada tem ícone")
	var turn := {"t": "turn", "side": "player", "n": 3, "st": up.st}
	await d._animate([turn], false)
	assert_null(_icon(d, "player", "dodge"), "some no começo do seu turno")
	d._sync_shown()
	assert_not_null(_icon(d, "enemy", "poison"), "no fim, o estado real")


func test_cartao_mostra_o_efeito_do_nivel():
	var run := _run_at_duel(12)
	var d := _duel_in_frame(run)
	await wait_process_frames(2)
	var c: SpellCard = d.cards[0]
	var it: Dictionary = run.hero.inventory.items[c.item]
	assert_eq(c.fx_label.text, Texts.spell_fx(c.id, 1))
	it.level = 3
	c.refresh([], [], -1)
	assert_eq(c.fx_label.text, Texts.spell_fx(c.id, 3), "evoluir atualiza o texto")
	it.level = 1


func test_escola_mostra_como_a_magia_fica():
	var txt := TowerScreen.evolve_text("escudo", 2)
	assert_string_contains(txt, "Bloqueio = valor ×3")
	assert_string_contains(txt, "Bloqueio = valor ×4,5")
	assert_string_contains(TowerScreen.evolve_text("espelho", 2), "Reflete o próximo golpe ×1,5")


# ------------------------------------------------------------ Mexidas (docs/SPEC_v3.1.md §1.9)
func _duel_with(spells: Array, values: Array) -> DuelScreen:
	var run := _run_at_duel(77)
	var p := run.duel.player
	p.inventory = Inventory.make(4, 3)
	for id in spells:
		p.inventory.add(id)
	p.hand = []
	for i in values.size():
		p.hand.append({"bag": i, "temp": null, "face": 0, "value": int(values[i]), "top": false, "fixed": false, "plus": 0, "spawn": -1})
	var d := DuelScreen.new().setup(run)
	d.fast = true
	add_child_autofree(d)
	return d


func test_mexida_sai_do_palco_e_muda_o_dado():
	var d := await _mexida_screen(["faisca", "virar"], [2, 5])
	var p := d.duel.player
	var vi := p.inventory.ids().find("virar")
	var card := d._card_of(d.cards, vi)
	assert_true(card.visible)
	d._on_die(d.tray_views[0])
	d._on_card(vi)
	assert_eq(int(p.hand[0].value), 5, "2 virou 5")
	assert_false(card.visible, "o cartão saiu do palco")
	assert_eq(d.tray_views[0].value, 5, "a coluna mostra o valor novo")
	assert_eq(d.tray_views[0].orig, 2, "o original riscado")
	assert_true(d.tray_views[0].has_die, "o dado voltou para a mão")
	# Desfazer volta o valor e o cartão.
	d._on_die(d.tray_views[0])
	assert_true(d.undo_btn.visible)
	d._on_undo()
	assert_eq(int(p.hand[0].value), 2)
	assert_true(card.visible, "o cartão voltou")


func _mexida_screen(spells: Array, values: Array) -> DuelScreen:
	var d := _duel_with(spells, values)
	await wait_process_frames(2)
	return d


func test_ajuste_fino_buraco_do_menos():
	var d := await _mexida_screen(["ajuste"], [4, 1])
	var p := d.duel.player
	var card := d._card_of(d.cards, 0)
	assert_eq(card.holes.size(), 2, "dois buracos")
	d._on_die(d.tray_views[0])
	d._on_card_hole(card.holes[1], 0)
	assert_eq(int(p.hand[0].value), 3, "−1")


func test_aleatoria_nao_mostra_desfazer():
	var d := await _mexida_screen(["segunda", "faisca"], [1, 3])
	d._on_die(d.tray_views[0])
	d._on_card(0)
	d._on_die(d.tray_views[0])
	assert_false(d.undo_btn.visible, "Segunda Chance é definitiva")
	assert_true("não se desfaz" in d.info.text)


func test_sangria_aumenta_a_coluna_e_tocar_no_original_desfaz():
	var d := await _mexida_screen(["sangria"], [7, 2])
	d._on_die(d.tray_views[0])
	d._on_card(0)
	assert_eq(d.tray_views.size(), 5, "3 partes na coluna")
	assert_false(d.tray_views[0].has_die, "o original foi gasto")
	d._on_die(d.tray_views[0])
	assert_eq(d.tray_views.size(), 2, "desfeito")


func test_magia_uma_vez_por_luta_usada_some_no_turno_seguinte():
	var run := _run_at_duel(5)
	var p := run.duel.player
	assert_true(p.inventory.add("remendo"), "cabe o Remendo")
	var d := DuelScreen.new().setup(run)
	d.fast = true
	add_child_autofree(d)
	await wait_process_frames(2)
	var rem := p.inventory.ids().find("remendo")
	var bola := p.inventory.ids().find("bola")
	p.once_used.append(rem)
	p.once_used.append(bola)
	d._refresh_tray()
	assert_false(d._card_of(d.cards, rem).visible, "Remendo já usado não aparece")
	assert_true(d._card_of(d.cards, bola).visible, "Bola de Fogo não tem limite por luta")


func test_mexida_do_inimigo_anima_sem_erro():
	var d := await _mexida_screen(["faisca"], [3])
	var e := d.duel.enemy
	e.inventory = Inventory.make(4, 3)
	e.inventory.add("virar")
	var c := SpellCard.new().setup(e, 0, DuelScreen.HOLE)
	d.enemy_grid.add_child(c)
	d.enemy_cards = [c]
	d._fill_tray([2, 4], ["", ""], false)
	await d._apply_event({"t": "mod", "side": "enemy", "spell": "virar", "item": 0, "dice": [0], "from": [2], "to": [5], "random": false})
	assert_eq(d.tray_views[0].value, 5)
	assert_false(c.visible, "o cartão dele saiu do palco")
	assert_true("Virar" in d._describe({"t": "mod", "side": "enemy", "spell": "virar", "from": [2], "to": [5]}))


func test_dado_mexido_pelo_inimigo_mostra_a_causa():
	var d := await _mexida_screen(["faisca"], [3])
	var p := d.duel.player
	p.hand[0]["orig"] = 6
	p.hand[0]["cause"] = "halve"
	d._refresh_tray()
	assert_eq(d.tray_views[0].orig, 6)
	assert_eq(d.tray_views[0].badge, "½")
	d._on_die(d.tray_views[0])
	assert_true("Chave de Braço" in d.info.text)
func test_so_mestres_tem_nome_e_rosetas():
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var e := EnemyFactory.create(3, "normal", rng)
	assert_eq(e.name, "", "inimigo comum sem nome")
	assert_eq(Texts.fighter_title(e), Texts.fighter_title(e).get_slice(":", 0))
	assert_ne(Texts.fighter_title(e), "", "aparece pelo arquétipo ou variante")
	var m := EnemyFactory.create(10, "normal", rng)
	assert_eq(m.name, Texts.master_name(m.master_id), "Mestre mantém o nome")
	assert_eq(Texts.fighter_title(m), m.name)
	assert_eq(Portrait.enemy_metal(m, "facil"), "gold", "Mestre: ouro")
	assert_eq(Portrait.enemy_metal(e, "facil"), "bronze")
	assert_eq(Portrait.enemy_metal(e, "normal"), "silver")
	assert_eq(Portrait.enemy_metal(e, "insana"), "gold")
	assert_eq(Portrait.hero_metal(10), "bronze")
	assert_eq(Portrait.hero_metal(11), "silver")
	assert_eq(Portrait.hero_metal(21), "gold")
	for metal in ["bronze", "silver", "gold"]:
		assert_not_null(Kit.tex(Portrait.ROSETTE_DIR % metal), "roseta " + metal)


func test_adesivos_aparecem_na_coluna_e_no_dado_3d():
	var run := _run_at_duel(5)
	var p := run.duel.player
	p.bag[p.hand[0].bag].stickers[int(p.hand[0].face)] = 1
	p.bag[p.hand[0].bag].gold[int(p.hand[0].face)] = 2
	var info := Resolver.hand_dice(p)
	assert_eq(int(info.stickers[0]), 1, "+2 da face que saiu")
	assert_eq(int(info.gold[0]), 2, "ouro da face que saiu")
	var d := DuelScreen.new().setup(run)
	add_child_autofree(d)
	await wait_process_frames(2)
	d._build_tray()
	assert_eq(d.tray_views[0].stickers, 1, "a coluna mostra o selo +2")
	assert_eq(d.tray_views[0].gold, 2, "e o dourado")
	# No dado 3D, cada face local recebe os adesivos da face do dado que ela mostra.
	var slots := Dice3D.face_slots(0, 4)
	assert_eq(slots[0], 4)
	assert_eq(slots[1], 1, "face oposta")
	var all := slots.duplicate()
	all.sort()
	assert_eq(all, [0, 1, 2, 3, 4, 5])
	var labels := Dice3D.labels(0, 50, [10, 20, 30, 40, 50, 60], 4)
	for k in 6:
		assert_eq(int(labels[k]), [10, 20, 30, 40, 50, 60][slots[k]], "face_slots segue labels")
	var mk := Dice3D.marks_node(0, 1, 1)
	assert_not_null(mk)
	mk.free()
	assert_null(Dice3D.marks_node(0, 0, 0))
