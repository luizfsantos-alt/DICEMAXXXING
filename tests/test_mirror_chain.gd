extends GutTest
## Espelho (contribuição proporcional), Kevin e Corrente.

const H = preload("res://tests/helpers.gd")


func test_espelho_martelo_6_6_2():
	var a := H.fighter("A", [6, 6, 2, 1, 1, 1], "A2", "", [], 60)
	var b := H.fighter("B", [1, 3, 3, 3, 3, 3], "A1", "D11", [], 60)
	var r := H.play(a, b, TurnChoice.make([0, 1, 2]), TurnChoice.make([], [0]))
	# Total ceil(14 x 1,3) = 19; o 6 reflete ceil(19 x 6/14) = 9; passam 10.
	assert_eq(r.dmg_to_b, 10)
	assert_eq(r.dmg_to_a, 9)


func test_espelho_arco_inclui_bonus_fixo():
	var a := H.fighter("A", [3, 4, 5, 1, 1, 1], "A4", "", [], 60)
	var b := H.fighter("B", [2, 3, 3, 3, 3, 3], "A1", "D11", [], 60)
	var r := H.play(a, b, TurnChoice.make([0, 1, 2]), TurnChoice.make([], [0]))
	assert_eq(r.dmg_to_a, 10, "ceil(22 x 5/12)")
	assert_eq(r.dmg_to_b, 12)


func test_espelho_exige_1_ou_2():
	var a := H.fighter("A", [6, 6, 6, 1, 1, 1], "A1", "", [], 60)
	var b := H.fighter("B", [3, 3, 3, 3, 3, 3], "A1", "D11", [], 60)
	var r := H.play(a, b, TurnChoice.make([0, 1, 2]), TurnChoice.make([], [0]))
	assert_eq(r.dmg_to_a, 0)
	assert_eq(r.dmg_to_b, 18)


func test_reflexo_reduzido_pelas_defesas_de_quem_atacou():
	var a := H.fighter("A", [6, 5, 4, 3, 1, 1], "A1", "D1", [], 60)
	var b := H.fighter("B", [1, 3, 3, 3, 3, 3], "A1", "D11", [], 60)
	var r := H.play(a, b, TurnChoice.make([0, 1], [3]), TurnChoice.make([], [0]))
	# Ataque 11; reflete ceil(11 x 6/11) = 6; escudo de A = 6 absorve tudo.
	assert_eq(r.dmg_to_a, 0)
	assert_eq(r.dmg_to_b, 5)


func test_reflexo_ignora_cota_de_quem_espelha_e_reducoes_por_dado():
	var kevin := EnemyFactory.boss(30)
	kevin.dice = [1, 1, 1, 1, 1, 1]
	kevin.max_hp = 60
	kevin.hp = 60
	var a := H.fighter("A", [6, 3, 1, 1, 1, 1], "A1", "", [], 60)
	var r := H.play(a, kevin, TurnChoice.make([0, 1]), TurnChoice.make([], [0]))
	# Kevin com Cota X=1: cada dado perde 1 -> 5 + 2 = 7; o 6 reflete ceil(7 x 5/7) = 5.
	assert_eq(r.dmg_to_a, 5)
	assert_eq(r.dmg_to_b, 2)


func test_kevin_reflete_todos_os_6():
	var kevin := EnemyFactory.boss(30)
	kevin.dice = [2, 2, 2, 2, 2, 2]
	kevin.defense_id = ""
	kevin.max_hp = 60
	kevin.hp = 60
	var a := H.fighter("A", [6, 6, 3, 1, 1, 1], "A1", "", [], 60)
	var r := H.play(a, kevin, TurnChoice.make([0, 1, 2]), H.idle())
	assert_eq(r.dmg_to_a, 12)
	assert_eq(r.dmg_to_b, 3)


func test_espelho_duplo_sem_vai_e_vem():
	var a := H.fighter("A", [6, 5, 1, 2, 2, 2], "A1", "D11", [], 60)
	var b := H.fighter("B", [4, 3, 2, 1, 1, 1], "A1", "D11", [], 60)
	var r := H.play(a, b, TurnChoice.make([0, 1], [2]), TurnChoice.make([0, 1], [2]))
	# A: 11, reflete 6 -> B recebe 5, A recebe 6. B: 7, reflete 4 -> A recebe 3, B recebe 4.
	assert_eq(r.dmg_to_a, 6 + 3)
	assert_eq(r.dmg_to_b, 5 + 4)


func test_corrente_troca_maior_ativo_com_menor_autodano():
	var a := H.fighter("A", [6, 1, 1, 1, 1, 1], "A1", "D12", [], 60)
	var b := H.fighter("B", [6, 5, 4, 3, 2, 1], "A1", "", [], 60)
	var r := H.play(a, b, TurnChoice.make([], [0]), TurnChoice.make([0, 1, 2]))
	# O 6 de B vai para o autodano e o 1 assume o ataque: 1+5+4 = 10.
	assert_eq(r.dmg_to_a, 10)
	assert_eq(r.self_b, 6 + 3 + 2)


func test_corrente_invalida_defesa_com_requisito():
	var a := H.fighter("A", [6, 5, 1, 1, 1, 1], "A1", "D12", [], 60)
	var b := H.fighter("B", [4, 1, 1, 2, 2, 2], "A1", "D3", [], 60)
	var r := H.play(a, b, TurnChoice.make([1], [0]), TurnChoice.make([1], [0]))
	# O 4 da Muralha é o maior ativo de B: vai para o autodano e entra um 1.
	# A Muralha não aceita 1, então não bloqueia nada.
	assert_eq(r.dmg_to_b, 5)


func test_chapeu_ignora_primeira_corrente():
	var a := H.fighter("A", [6, 1, 1, 1, 1, 1], "A1", "D12", [], 60)
	var b := H.fighter("B", [6, 5, 4, 3, 2, 1], "A1", "", ["DF8"], 60)
	var r := H.play(a, b, TurnChoice.make([], [0]), TurnChoice.make([0, 1, 2]))
	assert_eq(r.dmg_to_a, 15)
	assert_true(b.chapeu_used)


func test_corrente_dupla_simultanea():
	var a := H.fighter("A", [6, 5, 1, 2, 3, 3], "A1", "D12", [], 60)
	var b := H.fighter("B", [6, 4, 1, 2, 3, 3], "A1", "D12", [], 60)
	var r := H.play(a, b, TurnChoice.make([1], [0]), TurnChoice.make([1], [0]))
	# Cada lado perde o 6 da defesa (maior ativo) para o 1 do autodano;
	# as duas Correntes valem pois foram decididas nas colocações originais.
	assert_eq(r.dmg_to_a, 4)
	assert_eq(r.dmg_to_b, 5)
