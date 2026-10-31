extends GutTest
## Regras centrais: autodano, arredondamento, condições, reduções.

const H = preload("res://tests/helpers.gd")


func test_canhao_soma_e_autodano_dos_restantes():
	var a := H.fighter("A", [6, 5, 4, 3, 2, 1])
	var b := H.fighter("B", [1, 1, 1, 1, 1, 1])
	var r := H.play(a, b, TurnChoice.make([0, 1, 2]), H.idle())
	assert_eq(r.dmg_to_b, 15, "6+5+4")
	assert_eq(r.self_a, 6, "3+2+1")
	assert_eq(r.self_b, 6, "todos os 6 dados viram autodano")


func test_menos_ativos_mais_autodano():
	var a := H.fighter("A", [6, 5, 4, 3, 2, 1])
	var b := H.fighter("B", [1, 1, 1, 1, 1, 1])
	var r := H.play(a, b, TurnChoice.make([0, 1]), H.idle())
	assert_eq(r.self_a, 10, "4 dados sobrando = 4+3+2+1")


func test_martelo_arredonda_para_cima():
	var a := H.fighter("A", [4, 2, 1, 1, 1, 1], "A2")
	var b := H.fighter("B", [1, 1, 1, 1, 1, 1])
	var r := H.play(a, b, TurnChoice.make([0, 1, 2]), H.idle())
	assert_eq(r.dmg_to_b, 6, "7 x 0,8 = 5,6 -> 6")


func test_martelo_com_par_sem_erro_de_ponto_flutuante():
	var a := H.fighter("A", [5, 5, 1, 1, 1, 1], "A2")
	var b := H.fighter("B", [1, 1, 1, 1, 1, 1])
	var r := H.play(a, b, TurnChoice.make([0, 1]), H.idle())
	assert_eq(r.dmg_to_b, 13, "10 x 1,3 = 13 exato")


func test_lanca_trio_exige_tres_no_ataque():
	var a := H.fighter("A", [4, 4, 4, 1, 1, 1], "A3")
	var b := H.fighter("B", [1, 1, 1, 1, 1, 1])
	var r := H.play(a, b, TurnChoice.make([0, 1, 2]), H.idle())
	assert_eq(r.dmg_to_b, 24)
	var a2 := H.fighter("A", [4, 4, 4, 1, 1, 1], "A3", "D1")
	var b2 := H.fighter("B", [1, 1, 1, 1, 1, 1])
	var r2 := H.play(a2, b2, TurnChoice.make([0, 1], [2]), H.idle())
	assert_eq(r2.dmg_to_b, 7, "sem trio: 8 x 0,8 = 6,4 -> 7")


func test_arco_sequencia():
	var a := H.fighter("A", [3, 4, 5, 1, 1, 1], "A4")
	var b := H.fighter("B", [1, 1, 1, 1, 1, 1])
	var r := H.play(a, b, TurnChoice.make([0, 1, 2]), H.idle())
	assert_eq(r.dmg_to_b, 22)


func test_clava_dobra_o_primeiro_lancado():
	var a := H.fighter("A", [2, 6, 1, 1, 1, 1], "A5")
	var b := H.fighter("B", [1, 1, 1, 1, 1, 1])
	var r := H.play(a, b, TurnChoice.make([0, 1]), H.idle())
	assert_eq(r.dmg_to_b, 10, "2 lançado primeiro conta em dobro: 4 + 6")


func test_mangual_conta_para_o_valor():
	var a := H.fighter("A", [1, 2, 3, 1, 1, 1], "A6")
	var b := H.fighter("B", [1, 1, 1, 1, 1, 1])
	var r := H.play(a, b, TurnChoice.make([0, 1, 2]), H.idle())
	assert_eq(r.dmg_to_b, 15)


func test_adaga_impar():
	var a := H.fighter("A", [5, 3, 2, 1, 1, 1], "A8")
	var b := H.fighter("B", [1, 1, 1, 1, 1, 1])
	var r := H.play(a, b, TurnChoice.make([0, 1, 2]), H.idle())
	assert_eq(r.dmg_to_b, 14, "7+5+2")


func test_foice_usa_maior_autodano():
	var a := H.fighter("A", [6, 1, 1, 5, 2, 2], "A10")
	var b := H.fighter("B", [1, 1, 1, 1, 1, 1])
	var r := H.play(a, b, TurnChoice.make([0]), H.idle())
	assert_eq(r.dmg_to_b, 11, "6 + maior autodano 5")


func test_escudo_de_madeira_2x():
	var a := H.fighter("A", [1, 1, 1, 1, 1, 1])
	var b := H.fighter("B", [6, 6, 4, 1, 1, 1], "A1", "D1")
	var r := H.play(a, b, H.idle(), TurnChoice.make([0, 1], [2]))
	assert_eq(r.dmg_to_b, 0)
	a = H.fighter("A", [6, 6, 6, 1, 1, 1])
	b = H.fighter("B", [3, 1, 1, 1, 1, 1], "A1", "D1")
	r = H.play(a, b, TurnChoice.make([0, 1, 2]), TurnChoice.make([], [0]))
	assert_eq(r.dmg_to_b, 12, "18 - 6")


func test_escudo_dura_uma_rodada():
	var b := H.fighter("B", [3, 1, 1, 1, 1, 1], "A1", "D1")
	var a := H.fighter("A", [1, 1, 1, 1, 1, 1])
	H.play(a, b, H.idle(), TurnChoice.make([], [0]))
	assert_eq(b.round_shield, 0)


func test_barreira_persiste_ate_20():
	var b := H.fighter("B", [6, 1, 1, 1, 1, 1], "A1", "D5")
	var a := H.fighter("A", [1, 1, 1, 1, 1, 1])
	for i in 5:
		b.dice = [6, 1, 1, 1, 1, 1]
		H.play(a, b, H.idle(), TurnChoice.make([], [0]))
	assert_eq(b.barrier, 20)


func test_muralha_bloqueia_metade_para_cima():
	var a := H.fighter("A", [4, 2, 1, 1, 1, 1])
	var b := H.fighter("B", [4, 1, 1, 1, 1, 1], "A1", "D3")
	var r := H.play(a, b, TurnChoice.make([0, 1, 2]), TurnChoice.make([], [0]))
	assert_eq(r.dmg_to_b, 3, "7: bloqueia 4, passam 3")


func test_muralha_exige_valor_4():
	var a := H.fighter("A", [4, 2, 1, 1, 1, 1])
	var b := H.fighter("B", [5, 1, 1, 1, 1, 1], "A1", "D3")
	var r := H.play(a, b, TurnChoice.make([0, 1, 2]), TurnChoice.make([], [0]))
	assert_eq(r.dmg_to_b, 7)


func test_balsamo_metade_para_cima():
	var a := H.fighter("A", [5, 6, 1, 1, 1, 4], "A1", "D2")
	var b := H.fighter("B", [1, 1, 1, 1, 1, 1])
	var r := H.play(a, b, TurnChoice.make([1], [0]), H.idle())
	assert_eq(r.self_a, 4, "autodano 7 -> 4")


func test_elmo_anula_mas_condicao_continua():
	var a := H.fighter("A", [5, 5, 3, 1, 1, 1], "A2")
	var b := H.fighter("B", [5, 1, 1, 1, 1, 1], "A1", "D7")
	var r := H.play(a, b, TurnChoice.make([0, 1, 2]), TurnChoice.make([], [0]))
	assert_eq(r.dmg_to_b, 4, "par travado: 3 x 1,3 = 3,9 -> 4")


func test_elmo_anula_autodano_proprio():
	var a := H.fighter("A", [1, 1, 1, 1, 1, 1])
	var b := H.fighter("B", [4, 4, 4, 2, 4, 6], "A1", "D7")
	var r := H.play(a, b, H.idle(), TurnChoice.make([], [0]))
	assert_eq(r.self_b, 8, "4s anulados: 2+6")


func test_broquel_paridade():
	var a := H.fighter("A", [6, 4, 3, 1, 1, 1])
	var b := H.fighter("B", [2, 1, 1, 1, 1, 1], "A1", "D8")
	var r := H.play(a, b, TurnChoice.make([0, 1, 2]), TurnChoice.make([], [0]))
	assert_eq(r.dmg_to_b, 3)


func test_cota_de_malha():
	var a := H.fighter("A", [6, 4, 3, 1, 1, 1])
	var b := H.fighter("B", [3, 1, 1, 1, 1, 1], "A1", "D9")
	var r := H.play(a, b, TurnChoice.make([0, 1, 2]), TurnChoice.make([], [0]))
	assert_eq(r.dmg_to_b, 7, "cada dado perde 2: 4+2+1")


func test_chicote_explode_mesmo_reduzido():
	var a := H.fighter("A", [6, 1, 1, 1, 1, 1], "A7")
	var b := H.fighter("B", [1, 1, 1, 1, 1, 1], "A1", "", ["DF3"])
	var r := H.play(a, b, TurnChoice.make([0]), H.idle())
	assert_gt(r.dmg_to_b, 5, "6 explode e soma pelo menos 1 extra antes do -1 do Colete")


func test_fenix_cura_antes_do_autodano():
	var a := H.fighter("A", [3, 1, 1, 1, 1, 1], "A1", "D4", [], 40)
	a.hp = 38
	var b := H.fighter("B", [1, 1, 1, 1, 1, 1])
	H.play(a, b, TurnChoice.make([], [0]), H.idle())
	assert_eq(a.hp, 35, "cura até 40 (teto) e depois autodano 5")


func test_placa_vampirica_sobra_vira_cura():
	var a := H.fighter("A", [6, 1, 1, 1, 1, 1], "A1", "D10", [], 40)
	a.hp = 30
	var b := H.fighter("B", [2, 1, 1, 1, 1, 1])
	H.play(a, b, TurnChoice.make([], [0]), TurnChoice.make([0]))
	assert_eq(a.hp, 30 + 4 - 5, "escudo 6 absorve 2, sobra 4 vira cura")


func test_espinhos_por_dado_nao_anulado():
	var a := H.fighter("A", [6, 5, 4, 1, 1, 1])
	var b := H.fighter("B", [5, 1, 1, 1, 1, 1], "A1", "D6", [], 60)
	var r := H.play(a, b, TurnChoice.make([0, 1, 2]), TurnChoice.make([], [0]))
	assert_eq(r.dmg_to_a, 9, "3 dados x 3 espinhos")


func test_empate_contagem_de_morte_no_fim():
	var a := H.fighter("A", [6, 6, 6, 1, 1, 1], "A1", "", [], 10)
	var b := H.fighter("B", [6, 6, 6, 1, 1, 1], "A1", "", [], 10)
	H.play(a, b, TurnChoice.make([0, 1, 2]), TurnChoice.make([0, 1, 2]))
	assert_true(a.hp <= 0 and b.hp <= 0)
