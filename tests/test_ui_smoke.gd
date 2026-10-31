extends GutTest
## Fumaça da interface: monta todas as telas e joga alguns turnos pela UI.


func test_menu_abre():
	var main = load("res://ui/main.tscn").instantiate()
	add_child_autofree(main)
	await wait_process_frames(2)
	assert_not_null(main.current)
	assert_true(main.current is MenuScreen)


func test_duelo_pela_interface():
	var run := RunState.new_run(321)
	var d := DuelScreen.new().setup(run)
	add_child_autofree(d)
	await wait_process_frames(2)
	assert_eq(d.tray_views.size(), 6)
	# Encaixa defesa, lança dois dados e termina o turno.
	d._fit_defense(5)
	d._launch(0)
	d._launch(1)
	await wait_seconds(0.8)
	assert_true(run.duel.turn >= 2 or run.phase != "duel", "turno resolvido pela UI")
	if run.duel.state == "choosing":
		d._new_turn_ui()
		d.launched = [0]
		d._submit()
		await wait_process_frames(2)
	assert_gt(d.log_label.text.length(), 0)


func test_duelo_lancamento_em_grupo():
	var run := RunState.new_run(77)
	run.duel.player.attack_id = "A2"
	var d := DuelScreen.new().setup(run)
	add_child_autofree(d)
	await wait_process_frames(2)
	d._stage(0)
	d._stage(1)
	d._launch_group()
	assert_true(d.group_done)
	d._launch(2)
	assert_eq(d.launched.size(), 2, "depois do grupo não lança mais nada")
	d._submit()
	await wait_process_frames(2)
	assert_true(run.duel.turn >= 2 or run.phase != "duel")


func test_loja_e_fim():
	var run := RunState.new_run(5)
	run.phase = "shop"
	run.coins = 50
	run.offer = Shop.generate(run)
	var s := ShopScreen.new().setup(run)
	add_child_autofree(s)
	await wait_process_frames(2)
	s._on_reroll()
	s._on_buy()
	s._on_leave()
	assert_eq(run.fight, 2)
	assert_eq(run.phase, "duel")
	run.phase = "defeat"
	var e := EndScreen.new().setup(run)
	add_child_autofree(e)
	await wait_process_frames(2)
	assert_true(e.get_child_count() > 0)
	SaveGame.clear()
