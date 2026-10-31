extends GutTest
## Passivos defensivos e de dados.

const H = preload("res://tests/helpers.gd")


func test_ima_anula_repetidos():
	var a := H.fighter("A", [6, 3, 3, 5, 1, 1], "A1", "", ["DD7"])
	var b := H.fighter("B", [1, 1, 1, 1, 1, 1])
	var r := H.play(a, b, TurnChoice.make([0, 4, 5]), H.idle())
	assert_eq(r.self_a, 5, "3-3-5 -> sobra 5")


func test_cadeado_limita_10():
	var a := H.fighter("A", [1, 1, 1, 6, 6, 6], "A1", "", ["DF10"])
	var b := H.fighter("B", [1, 1, 1, 1, 1, 1])
	var r := H.play(a, b, TurnChoice.make([0, 1, 2]), H.idle())
	assert_eq(r.self_a, 10)


func test_capacete_nega_autodano_no_turno_1():
	var a := H.fighter("A", [1, 1, 1, 6, 6, 6], "A1", "", ["DF2"])
	var b := H.fighter("B", [1, 1, 1, 1, 1, 1])
	var r := H.play(a, b, TurnChoice.make([0, 1, 2]), H.idle(), 1)
	assert_eq(r.self_a, 0)
	a.dice = [1, 1, 1, 6, 6, 6]
	r = H.play(a, b, TurnChoice.make([0, 1, 2]), H.idle(), 2)
	assert_eq(r.self_a, 18)


func test_garrafa_com_pouca_vida():
	var a := H.fighter("A", [1, 1, 1, 3, 2, 2], "A1", "", ["DF7"], 40)
	a.hp = 10
	var b := H.fighter("B", [1, 1, 1, 1, 1, 1])
	var r := H.play(a, b, TurnChoice.make([0, 1, 2]), H.idle())
	assert_eq(r.self_a, 4, "7 -> 4")


func test_meia_com_vida_cheia():
	var a := H.fighter("A", [6, 6, 1, 1, 1, 1])
	var b := H.fighter("B", [1, 1, 1, 1, 1, 1], "A1", "", ["DF6"])
	var r := H.play(a, b, TurnChoice.make([0, 1]), H.idle())
	assert_eq(r.dmg_to_b, 10)


func test_bone_e_whey_no_escudo():
	var a := H.fighter("A", [6, 6, 6, 1, 1, 1])
	var b := H.fighter("B", [3, 1, 1, 1, 1, 1], "A1", "D1", ["DD10", "DF9"])
	var r := H.play(a, b, TurnChoice.make([0, 1, 2]), TurnChoice.make([], [0]))
	# Escudo 2x3 = 6, +1 Whey = 7, +20% Boné = ceil(8,4) = 9.
	assert_eq(r.dmg_to_b, 18 - 9)


func test_pochete_so_no_primeiro_turno():
	var a := H.fighter("A", [6, 1, 1, 1, 1, 1])
	var b := H.fighter("B", [1, 1, 1, 1, 1, 1], "A1", "", ["DF4"])
	var r := H.play(a, b, TurnChoice.make([0]), H.idle(), 1)
	assert_eq(r.dmg_to_b, 3)
	a.dice = [6, 1, 1, 1, 1, 1]
	r = H.play(a, b, TurnChoice.make([0]), H.idle(), 2)
	assert_eq(r.dmg_to_b, 6)


func test_bandeide_cura_no_inicio():
	var a := H.fighter("A", [1, 1, 1, 1, 1, 1], "A1", "", ["DF5"], 40)
	a.hp = 30
	var lg := []
	Resolver.start_turn(a, 2, lg)
	assert_eq(a.hp, 32)


func test_colete_reduz_maior_dado():
	var a := H.fighter("A", [6, 4, 1, 1, 1, 1])
	var b := H.fighter("B", [1, 1, 1, 1, 1, 1], "A1", "", ["DF3"])
	var r := H.play(a, b, TurnChoice.make([0, 1]), H.idle())
	assert_eq(r.dmg_to_b, 9)


func test_calculadora_conta_para_o_par():
	var a := H.fighter("A", [4, 3, 1, 1, 1, 1], "A2", "", ["DD4"])
	var b := H.fighter("B", [1, 1, 1, 1, 1, 1])
	var r := H.play(a, b, TurnChoice.make([0, 1]), H.idle())
	assert_eq(r.dmg_to_b, 11, "3 vira 4: par de 4 -> 8 x 1,3 = 10,4 -> 11")


func test_raspadinha_dobra():
	var a := H.fighter("A", [1, 2, 3, 4, 5, 6], "A1", "", ["DD2"])
	var b := H.fighter("B", [1, 1, 1, 1, 1, 1])
	var lg := []
	Resolver.apply_dice_passives(a, H.rng(), 2, lg)
	assert_true(a.raspadinha)
	var r := Resolver.resolve(a, b, TurnChoice.make([5, 4, 3]), H.idle(), H.rng(), 2, lg)
	assert_eq(r.dmg_to_b, 30)


func test_dado_viciado_vira_menor():
	var a := H.fighter("A", [1, 4, 4, 4, 4, 4], "A1", "", ["DD1"])
	Resolver.apply_dice_passives(a, H.rng(), 2, [])
	assert_eq(a.dice[0], 6)


func test_figurinha_copia_maior():
	var a := H.fighter("A", [6, 5, 2, 2, 1, 1], "A1", "", ["DD8"])
	Resolver.apply_dice_passives(a, H.rng(), 2, [])
	assert_eq(a.dice, [6, 6, 2, 2, 1, 1])


func test_ioio_carrega_maior():
	var a := H.fighter("A", [6, 5, 2, 2, 1, 3], "A1", "", ["DD6"])
	Resolver.apply_dice_passives(a, H.rng(), 2, [])
	assert_eq(a.ioio_carry, 6)
	a.dice = [3, 3, 3, 3, 1, 3]
	Resolver.apply_dice_passives(a, H.rng(), 3, [])
	assert_eq(a.dice[4], 6)


func test_gato_nunca_rola_1():
	var a := H.fighter("A", [1, 1, 1, 1, 1, 1], "A1", "", ["DD9"])
	var rng := H.rng(42)
	for i in 200:
		Resolver.roll(a, rng, 2, [])
		assert_false(1 in a.dice)
		if 1 in a.dice:
			break


func test_cleitinho_rola_sete_e_descarta():
	var c := EnemyFactory.boss(10)
	Resolver.roll(c, H.rng(3), 1, [])
	assert_eq(c.dice.size(), 6)


func test_nota_de_3_reais():
	var a := H.fighter("A", [4, 4, 4, 1, 2, 3], "A1", "", ["DD5"])
	Resolver.apply_dice_passives(a, H.rng(), 2, [])
	assert_eq(a.coins_earned, 1)
