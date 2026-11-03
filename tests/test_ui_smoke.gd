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
	d.fast = true
	add_child_autofree(d)
	await wait_process_frames(2)
	assert_eq(d.tray_views.size(), 6)
	# Toque põe no ataque; toque de novo devolve; defesa por arraste.
	d._place_attack(0)
	d._place_attack(1)
	assert_eq(d.attack, [0, 1])
	d._return(0)
	assert_eq(d.attack, [1])
	d._place_defense(5)
	assert_eq(d.defense, 5)
	d._place_attack(0)
	await d._submit()
	await wait_process_frames(2)
	assert_true(run.duel.turn >= 2 or run.phase != "duel", "turno resolvido pela UI")
	if run.phase == "duel":
		assert_eq(d.phase, "player")
		assert_eq(d.attack, [], "novo turno começa com slots vazios")
	assert_gt(d.log_label.text.length(), 0)


func test_slots_ordem_e_limite():
	var run := RunState.new_run(77)
	run.duel.player.attack_id = "A5"
	var d := DuelScreen.new().setup(run)
	d.fast = true
	add_child_autofree(d)
	await wait_process_frames(2)
	d._place_attack(0)
	d._place_attack(1)
	d._place_attack(2, 0)
	assert_eq(d.attack, [2, 0, 1], "arrastar para o slot 1 empurra os outros")
	d._place_attack(3)
	assert_eq(d.attack.size(), 3, "no máximo 3 ativos")
	d._place_defense(3)
	assert_eq(d.defense, -1, "sem espaço para a defesa")
	d._place_defense(1)
	assert_eq(d.defense, 1, "mover do ataque para a defesa")
	assert_eq(d.attack, [2, 0])
	var slot_mark: Label = d.atk_slots[2].get_child(0)
	assert_eq(slot_mark.text, "3")


func test_resolucao_pode_ser_pulada():
	var run := RunState.new_run(5)
	var d := DuelScreen.new().setup(run)
	add_child_autofree(d)
	await wait_process_frames(2)
	d._place_attack(0)
	d._place_attack(1)
	d._place_attack(2)
	d._submit()
	assert_eq(d.phase, "enemy")
	d.skip = true
	assert_eq(d.phase, "enemy", "a fase do inimigo não é pulável")
	await wait_seconds(1.5)
	assert_ne(d.phase, "enemy", "fase do inimigo dura até 1,5 s")
	d.skip = true
	await wait_seconds(0.1)
	assert_true(d.phase in ["between", "player", "over"], "tocar pula a resolução")
	d.skip = true
	await wait_seconds(0.1)
	assert_true(d.phase in ["player", "over"], "tocar adianta o próximo turno")


func test_passiva_itens_medalha_e_consulta():
	var run := RunState.new_run(9)
	run.fight = 30
	run.passives = ["DF5", "DD2"]
	run.death_defy = true
	run.start_duel()
	var d := DuelScreen.new().setup(run)
	d.fast = true
	add_child_autofree(d)
	await wait_process_frames(2)
	assert_true(d.chips.player.has("P1"), "passiva do personagem na barra")
	assert_true(d.chips.enemy.has("C3"), "regra do chefe na barra do inimigo")
	assert_eq(d.items_row.get_child_count(), 2, "fileira de itens do jogador")
	assert_true(d.chips.player.has("DEATH_DEFY"), "medalha do Desafio à Morte")
	var c := d.open_enemy_consult()
	await wait_process_frames(1)
	assert_true(is_instance_valid(c) and c.is_inside_tree())
	c.queue_free()
	d._on_chip_pressed(d.chips.player["DF5"])
	await wait_process_frames(1)
	assert_true(d.get_children().any(func(x): return x is Consult))


func test_inimigo_comum_tem_passiva_vazia_e_sem_itens():
	var run := RunState.new_run(9)
	var d := DuelScreen.new().setup(run)
	d.fast = true
	add_child_autofree(d)
	await wait_process_frames(2)
	assert_true(d.chips.enemy.is_empty(), "sem passiva, quadrado vazio")
	var row: HBoxContainer = d.bar_rows.enemy
	assert_true(row.get_child(0) is Chip, "mas o quadrado está presente")
	assert_eq(run.duel.enemy.passives, [], "inimigo nunca tem itens")


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
