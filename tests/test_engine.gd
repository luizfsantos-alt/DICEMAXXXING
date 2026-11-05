extends GutTest
## Regras do motor v3 (docs/SPEC_v3.md).

const H := preload("res://tests/helpers.gd")


# ------------------------------------------------------------ Dados e elementos
func test_adesivo_dobra_a_face_e_acumula():
	var d := Die.basic()
	assert_true(d.add_sticker(5))
	assert_eq(d.value(5), 12)
	d.add_sticker(5)
	assert_eq(d.value(5), 24)
	assert_eq(d.sticker_count(), 2)


func test_chumbo_tem_tres_faces_1_travadas():
	var d := Elements.lead()
	assert_eq(d.faces.slice(0, 3), [1, 1, 1])
	assert_false(d.add_sticker(0), "face travada")
	assert_true(d.add_sticker(5))


func test_hidrogenio_triplica_com_bolsa_pequena():
	var f := H.fighter("a", ["faisca"])
	f.bag.resize(Elements.SOLITARY_BAG)
	f.bag[0] = Die.with_element("H")
	f.reset_fight_state()
	f.draw_pile = [0]
	f.hand_size = 1
	f.draw_hand(H.rng())
	f.roll_hand(H.rng(), [])
	assert_eq(f.hand[0].value, (int(f.hand[0].face) + 1) * 3)
	f.bag.append(Die.basic())
	f.roll_hand(H.rng(), [])
	assert_eq(f.hand[0].value, int(f.hand[0].face) + 1, "bolsa acima do limite: sem bônus")


func test_carbono_soma_a_cadeia_da_mao():
	var f := H.fighter("a", ["faisca"])
	for i in 3:
		f.bag[i] = Die.with_element("C")
	f.reset_fight_state()
	f.draw_pile = [0, 1, 2, 3]
	f.hand_size = 4
	f.draw_hand(H.rng())
	f.roll_hand(H.rng(), [])
	for e in f.hand:
		var bonus := 2 * Elements.CHAIN_STEP if f.die_of(e).element == "C" else 0
		assert_eq(int(e.value), int(e.face) + 1 + bonus, "3 Carbonos: +2 por outro em cada")


func test_carbono_sozinho_nao_ganha_nada():
	var f := H.fighter("a", ["faisca"])
	f.bag[0] = Die.with_element("C")
	f.reset_fight_state()
	f.draw_pile = [0, 1]
	f.hand_size = 2
	f.draw_hand(H.rng())
	f.roll_hand(H.rng(), [])
	for e in f.hand:
		assert_eq(int(e.value), int(e.face) + 1)


func test_carbono_na_loja_e_com_texto():
	assert_true("C" in Elements.SHOP)
	assert_eq(Elements.rarity("C"), "common")
	assert_eq(Texts.element_name("C"), "Carbono")


func test_osmio_sai_na_primeira_mao():
	var f := H.fighter("a", ["faisca"])
	f.bag[7] = Die.with_element("Os")
	for s in 20:
		f.reset_fight_state()
		f.draw_hand(H.rng(s))
		assert_eq(int(f.hand[0].bag), 7)


func test_mercurio_copia_o_maior_da_mesa():
	var f := H.fighter("a", ["faisca"])
	f.bag[0] = Die.with_element("Hg")
	f.hand_size = 2
	f.draw_pile = [0, 1]
	f.draw_hand(H.rng())
	f.roll_hand(H.rng(), [9])
	for e in f.hand:
		if f.die_of(e).element == "Hg":
			assert_eq(e.value, 9, "copia a última mão do inimigo")


func test_uranio_parado_envenena_e_veneno_acumula():
	var a := H.fighter("a", ["faisca"])
	var b := H.fighter("b", [])
	a.bag[1] = Die.with_element("U")
	H.hand(a, [4, 8])
	H.cast(a, b, {"faisca": [0]})
	assert_eq(a.poison, Config.URANIUM_POISON)
	var ev := []
	Resolver.start_turn(a, ev)
	assert_eq(a.hp, 40 - Config.URANIUM_POISON)
	H.hand(a, [4, 8])
	H.cast(a, b, {"faisca": [1]})
	assert_eq(a.poison, Config.URANIUM_POISON, "usado não envenena")


func test_sodio_queima_e_queima_decai():
	var a := H.fighter("a", ["faisca"])
	var b := H.fighter("b", [])
	a.bag[0] = Die.with_element("Na")
	H.hand(a, [3])
	H.cast(a, b, {"faisca": [0]})
	assert_eq(b.burn, Config.SODIUM_BURN)
	Resolver.start_turn(b, [])
	assert_eq(b.hp, 40 - 3 - Config.SODIUM_BURN)
	assert_eq(b.burn, Config.SODIUM_BURN - 1)


# ------------------------------------------------------------ Inventário
func test_formatos_giram_e_ocupam_a_grade():
	assert_eq(Spells.shape("escudo", 0), [Vector2i(0, 0), Vector2i(0, 1)])
	assert_eq(Spells.shape("escudo", 1).size(), 2)
	var inv := Inventory.make(4, 3)
	assert_true(inv.add("bola"))
	assert_true(inv.add("meteoro"))
	assert_false(inv.can_place("bola", 0, 0, 0), "ocupado")


func test_cinto_nao_aceita_2x2_mas_aceita_escudo_girado():
	var inv := Inventory.make(6, 1)
	assert_false(inv.fits("bola"))
	assert_false(inv.fits("meteoro"))
	assert_true(inv.add("escudo"), "1×2 girado vira 2×1")
	assert_eq(int(inv.items[0].rot) % 2, 1)


func test_ordem_de_resolucao_cima_para_baixo_esquerda_para_direita():
	var inv := Inventory.make(4, 3)
	inv.items = [
		{"id": "faisca", "level": 1, "x": 3, "y": 1, "rot": 0},
		{"id": "faisca", "level": 1, "x": 0, "y": 2, "rot": 0},
		{"id": "faisca", "level": 1, "x": 2, "y": 0, "rot": 0},
	]
	assert_eq(inv.order(), [2, 0, 1])


func test_arranjo_inicial_e_valido_e_todas_as_magias_cabem():
	for arch in ["sorcerer", "assassin"]:
		var f := EnemyFactory.base(arch)
		var occ := 0
		for it in f.inventory.items:
			occ += Spells.shape(it.id).size()
		assert_eq(f.inventory.occupied().size(), occ, "sem sobreposição (%s)" % arch)
	var s := EnemyFactory.base("sorcerer")
	for id in Spells.ERUDITE_CHOICES:
		assert_true(s.inventory.fits(id), "%s cabe no início" % id)


func test_kit_inicial_sem_defesa():
	assert_eq(EnemyFactory.base("sorcerer").inventory.ids(), ["faisca", "bola"])
	assert_eq(EnemyFactory.base("assassin").inventory.ids(), ["estocada", "corte"])
	var run := RunState.new_run(3)
	run.choose(0) ## Erudito
	assert_eq(run.hero.inventory.items.size(), 3, "Feiticeiro: 2 + a escolha do Erudito")
	assert_false("escudo" in run.hero.inventory.ids())
	assert_true("escudo" in Spells.ids_of_rarity("common"), "Escudo segue nas ofertas (Comum)")


func test_adicionar_reorganiza_quando_preciso():
	var inv := Inventory.make(4, 3)
	inv.items = [
		{"id": "faisca", "level": 1, "x": 0, "y": 0, "rot": 0},
		{"id": "escudo", "level": 1, "x": 1, "y": 0, "rot": 0},
		{"id": "bola", "level": 1, "x": 2, "y": 0, "rot": 0},
	]
	assert_true(inv.find_spot("meteoro").is_empty(), "não cabe sem mexer")
	assert_true(inv.add("meteoro"), "reorganiza")
	var occ := 0
	for it in inv.items:
		occ += Spells.shape(it.id).size()
	assert_eq(inv.occupied().size(), occ)
	assert_false(inv.fits("bola"), "sem espaço para outra 2×2")


func test_mover_respeita_limites():
	var inv := Inventory.make(4, 3)
	inv.add("faisca")
	inv.add("bola")
	assert_false(inv.move(0, 1, 0, 0), "em cima da bola")
	assert_true(inv.move(0, 3, 2, 0))
	assert_false(inv.move(1, 3, 2, 0), "sai da grade")


# ------------------------------------------------------------ Exigências
func test_exigencias():
	assert_true(Spells.accepts_partial("escudo", [], 3))
	assert_false(Spells.accepts_partial("escudo", [], 4))
	assert_true(Spells.complete("bola", [5, 5]))
	assert_false(Spells.complete("bola", [5, 4]))
	assert_true(Spells.complete("meteoro", [4, 2, 3]))
	assert_false(Spells.complete("meteoro", [2, 3, 5]))
	assert_false(Spells.accepts_partial("meteoro", [3], 3), "repetido não forma sequência")
	assert_true(Spells.complete("espelho", [1]))
	assert_false(Spells.complete("corte", [4]))


func test_magia_incompleta_nao_e_lancada():
	var a := H.fighter("a", ["bola"])
	var b := H.fighter("b", [])
	H.hand(a, [5, 2])
	var c := TurnChoice.new()
	assert_true(c.place(a, 0, 0))
	assert_false(c.place(a, 0, 1), "2 não forma par com 5")
	var ev := []
	Resolver.cast_all(a, b, c, ev)
	assert_eq(b.hp, 40)


# ------------------------------------------------------------ Efeitos
func test_dano_bloqueio_e_bloqueio_dura_ate_o_proximo_turno_do_dono():
	var a := H.fighter("a", ["faisca"])
	var b := H.fighter("b", ["escudo"])
	H.hand(b, [3])
	H.cast(b, a, {"escudo": [0]})
	assert_eq(b.block, 9)
	H.hand(a, [6])
	H.cast(a, b, {"faisca": [0]})
	assert_eq(b.hp, 40)
	assert_eq(b.block, 3)
	Resolver.start_turn(b, [])
	assert_eq(b.block, 0, "some no início do próximo turno do dono")


func test_bola_de_fogo_uma_vez_por_luta_e_queima():
	var a := H.fighter("a", ["bola"])
	var b := H.fighter("b", [], 100)
	H.hand(a, [4, 4])
	H.cast(a, b, {"bola": [0, 1]})
	assert_eq(b.hp, 100 - 16, "soma ×2")
	assert_eq(b.burn, 3)
	assert_false(TurnChoice.can_cast(a, 0), "uso único na luta")
	a.reset_fight_state()
	assert_true(TurnChoice.can_cast(a, 0), "volta na próxima luta")



func test_meteoro_soma_mais_dez():
	var a := H.fighter("a", ["meteoro"])
	var b := H.fighter("b", [], 100)
	H.hand(a, [3, 4, 5])
	H.cast(a, b, {"meteoro": [0, 1, 2]})
	assert_eq(b.hp, 100 - 22)
	assert_false(TurnChoice.can_cast(a, 0), "uso único na luta")

func test_espelho_devolve_e_reflexo_nao_volta():
	var a := H.fighter("a", ["espelho", "faisca"])
	var b := H.fighter("b", ["espelho"])
	H.hand(b, [1])
	H.cast(b, a, {"espelho": [0]})
	H.hand(a, [1, 6])
	H.cast(a, b, {"espelho": [0], "faisca": [1]})
	assert_eq(b.hp, 40)
	assert_eq(a.hp, 34, "o reflexo passa pelo espelho de quem atacou")
	assert_true(a.mirror, "e não gasta esse espelho")


func test_esquiva_anula_o_proximo_golpe():
	var a := H.fighter("a", ["faisca"])
	var b := H.fighter("b", ["esquiva"])
	H.hand(b, [2])
	H.cast(b, a, {"esquiva": [0]})
	H.hand(a, [6])
	H.cast(a, b, {"faisca": [0]})
	assert_eq(b.hp, 40)
	assert_false(b.dodge)


func test_corte_duplo_golpeia_de_novo_com_impares():
	var a := H.fighter("a", ["corte"])
	var b := H.fighter("b", [], 100)
	H.hand(a, [3, 5])
	H.cast(a, b, {"corte": [0, 1]})
	assert_eq(b.hp, 84)
	a.reset_fight_state()
	H.hand(a, [3, 4])
	H.cast(a, b, {"corte": [0, 1]})
	assert_eq(b.hp, 77)


func test_sacrificio_destroi_o_dado_e_soma_dano():
	var a := H.fighter("a", ["sacrificio", "faisca"])
	var b := H.fighter("b", [])
	H.hand(a, [1, 6])
	H.cast(a, b, {"sacrificio": [0], "faisca": [1]})
	assert_eq(a.bag.size(), 7)
	assert_eq(b.hp, 40 - 6 - Config.SACRIFICE_BONUS)
	assert_eq(a.discard, [0], "só a Faísca (agora índice 0) vai ao descarte")


func test_transfusao_aumenta_vida_maxima():
	var a := H.fighter("a", ["transfusao"])
	var b := H.fighter("b", [])
	H.hand(a, [4, 4])
	H.cast(a, b, {"transfusao": [0, 1]})
	assert_eq(a.max_hp, 44)


func test_evolucao_multiplica_o_efeito():
	var a := H.fighter("a", ["faisca"])
	var b := H.fighter("b", [], 100)
	a.inventory.items[0].level = 3
	H.hand(a, [5])
	H.cast(a, b, {"faisca": [0]})
	assert_eq(b.hp, 90)


# ------------------------------------------------------------ Duelo e torre
func test_duelo_sequencial_ate_o_fim():
	var run := RunState.new_run(42)
	run.choose(0)
	assert_eq(run.phase, "doors")
	run.choose(0)
	assert_eq(run.phase, "duel")
	var d := run.duel
	assert_eq(d.turn, 1)
	assert_eq(d.player.hand.size(), Config.HAND_SIZE)
	var guard := 0
	while d.state == "choosing" and guard < 100:
		var rep := d.submit(EnemyAI.choose(d.player, d.enemy, H.rng()))
		assert_false(rep.has("error"))
		guard += 1
	assert_true(d.state in ["won", "lost"])
	assert_true(d.turn % 2 == 0 or d.state != "choosing")


func test_vida_persiste_entre_lutas():
	var run := RunState.new_run(7)
	run.choose(0)
	run.choose(0)
	run.duel.enemy.hp = 1
	run.duel.player.hp = 33
	run.duel.state = "won"
	run.finish_duel()
	assert_eq(run.phase, "reward")
	assert_eq(run.hero.hp, 33)


func test_parada_a_cada_3_lutas_e_mestre_no_10():
	var run := RunState.new_run(3)
	run.choose(0)
	for n in range(1, Config.LAST_FLOOR):
		assert_eq(run.phase, "doors", "andar %d" % n)
		run.choose(0)
		run.duel.state = "won"
		run.finish_duel()
		run.leave()
		if n % Config.REST_EVERY == 0:
			assert_eq(run.phase, "rest")
			run.choose(run.options.map(func(o): return o.id).find("heal"))
			if run.phase == "rest":
				run.choose(0)
				run.leave()
	assert_eq(run.floor_n, Config.LAST_FLOOR)
	assert_eq(run.options.size(), 1)
	run.choose(0)
	assert_eq(run.duel.enemy.master_id, "porteiro")
	run.duel.state = "won"
	run.finish_duel()
	assert_eq(run.phase, "victory")


func test_porteiro_poe_chumbo_na_mao():
	var run := RunState.new_run(3)
	run.floor_n = Config.LAST_FLOOR
	run.start_duel()
	var leads := run.duel.player.hand.filter(func(e): return run.duel.player.die_of(e).element == "Pb")
	assert_eq(leads.size(), 1)
	assert_eq(run.duel.player.hand.size(), Config.HAND_SIZE + 1)


func test_lixeiro_poe_chumbo_na_bolsa_e_fica():
	var a := H.fighter("a", ["faisca"], 40, true)
	var e := H.fighter("e", ["faisca"])
	e.variant = "lixeiro"
	var ev := []
	Resolver.on_turn_effects(e, a, ev)
	assert_eq(a.bag.size(), 9)
	assert_eq(a.bag[8].element, "Pb")


func test_inimigo_cresce_com_o_andar_e_a_porta():
	var lo := EnemyFactory.create(1, "facil", H.rng(5))
	var hi := EnemyFactory.create(9, "insana", H.rng(5))
	assert_lt(lo.max_hp, hi.max_hp)
	var stickers := 0
	for d in hi.bag:
		stickers += d.sticker_count()
	var levels := 0
	for it in hi.inventory.items:
		levels += int(it.level)
	assert_gt(stickers + levels + hi.inventory.items.size(), 3, "recebeu melhorias")


func test_loja_poco_e_escola():
	var run := RunState.new_run(11)
	run.choose(0)
	run.coins = 100
	run.phase = "well"
	run.options = Shop.well(run.rng)
	assert_eq(run.choose(0, {"die": 2}), "ui.pick_face")
	assert_eq(run.choose(0, {"die": 2, "face": 5}), "")
	assert_eq(run.hero.bag[2].value(5), 12)
	assert_eq(run.coins, 100 - Config.PRICE_STICKER)
	assert_eq(run.choose(0, {"die": 2, "face": 5}), "")
	assert_eq(run.coins, 100 - Config.PRICE_STICKER * 3, "o segundo adesivo no mesmo dado custa o dobro")
	assert_eq(run.choose(3, {"die": 0}), "")
	assert_eq(run.hero.bag.size(), 7)
	run.leave()
	assert_eq(run.phase, "doors")
	run.phase = "school"
	run.options = Shop.school(run.hero, run.rng)
	var ev := run.options.map(func(o): return o.kind).find("evolve")
	var item: int = run.options[ev].item
	run.choose(ev)
	assert_eq(int(run.hero.inventory.items[item].level), 2)
	assert_eq(run.phase, "doors")


func test_salvar_e_carregar_no_meio_do_duelo():
	var run := RunState.new_run(99)
	run.choose(0)
	run.choose(0)
	var d1 := JSON.stringify(run.to_dict())
	var back := RunState.from_dict(JSON.parse_string(d1))
	assert_eq(JSON.stringify(back.to_dict()), d1)
	var c1 := EnemyAI.choose(run.duel.player, run.duel.enemy, H.rng())
	var c2 := EnemyAI.choose(back.duel.player, back.duel.enemy, H.rng())
	run.duel.submit(c1)
	back.duel.submit(c2)
	assert_eq(run.duel.player.hp, back.duel.player.hp, "mesmo resultado depois de carregar")
	assert_eq(run.duel.player.hand_values(), back.duel.player.hand_values())


func test_save_antigo_e_ignorado():
	assert_null(RunState.from_dict({"version": 1, "fight": 3}))


func test_magia_de_varios_dados_pela_metade_fica_incompleta():
	var f := H.fighter("Eu", ["faisca", "corte"], 40, true)
	H.hand(f, [4, 5, 6])
	var c := TurnChoice.new()
	assert_true(c.place(f, 0, 0))
	assert_eq(c.incomplete_items(f), [], "magia de um dado já completa")
	assert_true(c.place(f, 1, 1))
	assert_eq(c.incomplete_items(f), [1], "Corte com um dado só")
	assert_true(c.place(f, 1, 2))
	assert_eq(c.incomplete_items(f), [], "Corte completo")
