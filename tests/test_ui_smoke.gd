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
	main._on_new_run()
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
	d._on_cell(Vector2i.ZERO, faisca)
	assert_eq(d.choice.dice_in(faisca), [0], "dado posto na Faísca")
	d._on_die(d.tray_views[0])
	assert_eq(d.choice.used_dice(), [], "tocar no dado posto devolve")
	d._on_die(d.tray_views[0])
	d._on_cell(Vector2i.ZERO, faisca)
	var turn := run.duel.turn
	await d._submit()
	await wait_process_frames(2)
	assert_true(run.duel.turn > turn or run.duel.state != "choosing", "turno resolvido pela UI")
	if run.duel.state == "choosing":
		assert_eq(d.phase, "player")
		assert_eq(d.choice.used_dice(), [], "novo turno começa com magias vazias")
	assert_gt(d.feed.get_parsed_text().length(), 0)


func test_exigencia_recusa_dado_errado():
	var run := _run_at_duel(5)
	var p := run.duel.player
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
	d._on_cell(Vector2i.ZERO, faisca)
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
