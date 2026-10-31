extends GutTest
## IA, duelo, jornada, loja e salvamento.

const H = preload("res://tests/helpers.gd")


func test_bruto_ataca_com_os_3_maiores():
	var f := H.fighter("E", [2, 6, 3, 5, 1, 4])
	var c := EnemyAI.brute(f)
	assert_eq(c.attack, [1, 3, 5])
	assert_eq(c.defense, [])


func test_cauteloso_defende():
	var f := H.fighter("E", [2, 6, 3, 5, 1, 4], "A1", "D1")
	var c := EnemyAI.cautious(f)
	assert_eq(c.attack, [1, 3])
	assert_eq(c.defense, [5])


func test_cauteloso_busca_dado_valido_fora_do_top3():
	var f := H.fighter("E", [2, 6, 3, 5, 1, 4], "A1", "D11")
	var c := EnemyAI.cautious(f)
	assert_eq(c.attack, [1, 3])
	assert_eq(c.defense.size(), 1)
	assert_true(f.dice[c.defense[0]] <= 2)


func test_caotico_sempre_valido():
	var rng := H.rng(9)
	for i in 100:
		var f := H.fighter("E", [rng.randi_range(1, 6), 2, 3, 4, 5, 6], "A1", "D3")
		var c := EnemyAI.chaotic(f, rng)
		assert_eq(c.validate(f), "")
		assert_eq(c.active_count(), 3)


func test_escolha_invalida_e_rejeitada():
	var f := H.fighter("P", [1, 2, 3, 4, 5, 6], "A1", "D1")
	assert_ne(TurnChoice.make([0, 1, 2], [3]).validate(f), "")
	assert_ne(TurnChoice.make([0, 0]).validate(f), "")
	assert_eq(TurnChoice.make([0, 1], [2]).validate(f), "")


func test_desafio_a_morte_salva_do_empate():
	var run := RunState.new_run(5)
	var d := run.duel
	d.player.hp = 1
	d.player.death_defy = true
	d.player.dice = [1, 1, 1, 6, 6, 6]
	d.submit(TurnChoice.make([0, 1, 2]))
	assert_false(d.player.death_defy)
	assert_eq(d.player.hp, d.player.max_hp)
	assert_ne(d.state, "lost")


func test_jornada_completa_com_bot_termina():
	var run := RunState.new_run(1234)
	var guard := 0
	while run.phase in ["duel", "shop"] and guard < 5000:
		guard += 1
		if run.phase == "duel":
			run.duel.submit(EnemyAI.brute(run.duel.player))
			if run.duel.state != "choosing":
				run.finish_duel()
			else:
				run.duel.begin_turn()
		else:
			Shop.buy(run)
			run.next_fight()
	assert_true(run.phase in ["victory", "defeat"])
	assert_true(run.fight >= 1 and run.fight <= Config.LAST_FIGHT)


func test_loja_compra_e_venda():
	var run := RunState.new_run(7)
	run.coins = 100
	run.offer = {"type": "passive", "id": "DF5", "price": 15}
	assert_eq(Shop.buy(run), "")
	assert_true("DF5" in run.passives)
	assert_eq(run.coins, 85)
	assert_true(Shop.sell(run, "DF5"))
	assert_eq(run.coins, 85 + 8)


func test_limite_de_passivos():
	var run := RunState.new_run(7)
	run.coins = 100
	run.passives = ["DF1", "DF2", "DF3"]
	run.offer = {"type": "passive", "id": "DF5", "price": 15}
	assert_eq(Shop.buy(run), "ui.passive_full")


func test_rerrolagens_gratis_limitadas():
	var run := RunState.new_run(7)
	for i in 3:
		assert_true(Shop.reroll(run))
	assert_false(Shop.reroll(run))


func test_save_roundtrip_mantem_dados_e_rng():
	var run := RunState.new_run(99)
	var d := run.to_dict()
	var copy := RunState.from_dict(JSON.parse_string(JSON.stringify(d)))
	assert_eq(copy.duel.player.dice, run.duel.player.dice)
	assert_eq(copy.duel.enemy.name, run.duel.enemy.name)
	assert_eq(copy.duel.enemy_choice.attack, run.duel.enemy_choice.attack)
	var c := EnemyAI.brute(run.duel.player)
	var r1 := run.duel.submit(c)
	var r2 := copy.duel.submit(c.duplicate_choice())
	assert_eq(r1.log, r2.log, "mesma resolução depois de salvar e carregar")
	run.duel.begin_turn()
	copy.duel.begin_turn()
	assert_eq(copy.duel.player.dice, run.duel.player.dice, "mesma rolagem seguinte")


func test_blocos_de_inimigos():
	var rng := H.rng(1)
	var e1 := EnemyFactory.create(3, rng)
	assert_eq(e1.attack_id, "A1")
	assert_eq(e1.defense_id, "")
	assert_between(e1.max_hp, 36, 48)
	var e2 := EnemyFactory.create(15, rng)
	assert_between(e2.max_hp, 44, 56)
	assert_ne(e2.defense_id, "")
	assert_eq(EnemyFactory.create(30, rng).name, "Kevin, Reflexo de Bolinha")
