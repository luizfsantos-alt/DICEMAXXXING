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
	assert_eq(run.hero.bag[1].value(4), 10)
	var o := Organizer.open(t, run.hero.inventory)
	await wait_process_frames(1)
	assert_true(o.is_inside_tree())
	BagPanel.open(t, run.hero.bag)
	t._leave()
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
	g.cell_tapped.emit(Vector2i(0, 0), 0)
	g.cell_tapped.emit(Vector2i(3, 2), -1)
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


func test_menu_oferece_os_tres_jogaveis():
	var main = load("res://ui/main.tscn").instantiate()
	add_child_autofree(main)
	await wait_process_frames(2)
	var m: MenuScreen = main.current
	assert_eq(m.picks.size(), 3)
	m.picks[2].pressed.emit()
	await wait_process_frames(2)
	assert_eq(main.run.character, "barbarian")
	assert_eq(main.run.phase, "doors")
	assert_true(main.current is TowerScreen)


func test_luta_com_cada_jogavel_pela_interface():
	for id in Characters.PLAYABLE:
		var run := RunState.new_run(42, id)
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
	d._start_player_phase()
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
	for id in ["block", "poison", "burn", "mirror", "dodge", "riposte", "immune"]:
		var ic := StatusIcon.new().setup({"id": id, "n": 3})
		assert_not_null(ic.art, "ícone com arte: " + id)
		ic.free()
	# Sem arte ainda: fica a sigla (placeholder).
	var ph := StatusIcon.new().setup({"id": "fury", "n": 2})
	assert_null(ph.art, "fúria ainda sem arte")
	ph.free()
	var mod := StatusIcon.new().setup({"id": "mod_minus1", "n": 1})
	assert_eq(mod._key(), "hand_mod", "mexidas na mão usam o mesmo ícone")
	mod.free()


func test_moldura_e_fonte_dos_numeros_existem():
	for p in Portrait.FRAMES.values():
		assert_true(ResourceLoader.exists(Portrait.ART_DIR + p), "moldura: " + p)
	assert_true(ResourceLoader.exists("res://assets/fonts/Bungee-Regular.ttf"), "fonte dos números")


func test_fundo_da_batalha_existe():
	assert_true(ResourceLoader.exists(DuelScreen.BACKGROUND), "fundo da taverna")


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
