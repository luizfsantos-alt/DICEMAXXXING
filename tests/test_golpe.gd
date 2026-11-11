extends GutTest
## O que vem no golpe só pega se o golpe pegar (0.26.1): Sódio, Césio, a queima da
## Bola de Fogo e as mexidas que vêm num golpe. Esquiva: nada. Espelho: volta para quem
## atacou. Bloqueio: o golpe acertou, o efeito entra. Magia que não golpeia: nada no inimigo.

const H := preload("res://tests/helpers.gd")


func _el(f: Fighter, i: int, el: String) -> void:
	f.bag[i] = Die.with_element(el)


func _ev_count(ev: Array, t: String) -> int:
	return ev.filter(func(e): return e.t == t).size()


func test_sodio_queima_3_no_golpe_que_acerta():
	var a := H.fighter("a", ["faisca"])
	var b := H.fighter("b", [], 100)
	_el(a, 0, "Na")
	H.hand(a, [5])
	H.cast(a, b, {"faisca": [0]})
	assert_eq(b.hp, 95)
	assert_eq(b.burn, 3, "Sódio queima 3")


func test_cesio_envenena_2():
	var a := H.fighter("a", ["faisca"])
	var b := H.fighter("b", [], 100)
	_el(a, 0, "Cs")
	H.hand(a, [5])
	H.cast(a, b, {"faisca": [0]})
	assert_eq(b.poison, 2, "Césio envenena 2")


func test_golpe_absorvido_pelo_bloqueio_ainda_queima():
	var a := H.fighter("a", ["faisca"])
	var b := H.fighter("b", [], 100)
	b.block = 20
	_el(a, 0, "Na")
	H.hand(a, [5])
	H.cast(a, b, {"faisca": [0]})
	assert_eq(b.hp, 100, "o bloqueio segurou o dano")
	assert_eq(b.burn, 3, "mas o golpe acertou: queima")


func test_sodio_em_magia_que_nao_golpeia_nao_queima_o_inimigo():
	var a := H.fighter("a", ["escudo", "remendo"])
	var b := H.fighter("b", [], 100)
	_el(a, 0, "Na")
	_el(a, 1, "Cs")
	H.hand(a, [3, 4])
	H.cast(a, b, {"escudo": [0], "remendo": [1]})
	assert_eq(a.block, 9)
	assert_eq(b.burn, 0, "o bloqueio foi em mim")
	assert_eq(b.poison, 0, "a cura foi em mim")
	assert_eq(a.burn, 0)


func test_esquiva_anula_os_efeitos_do_golpe():
	var a := H.fighter("a", ["bola"])
	var b := H.fighter("b", [], 100)
	b.dodge = 1
	_el(a, 0, "Na")
	_el(a, 1, "Cs")
	H.hand(a, [4, 4])
	H.cast(a, b, {"bola": [0, 1]})
	assert_eq(b.hp, 100)
	assert_eq(b.burn, 0, "nem o Sódio nem a queima da Bola")
	assert_eq(b.poison, 0)
	assert_eq(a.burn, 0)


func test_espelho_devolve_os_efeitos_para_quem_atacou():
	var a := H.fighter("a", ["bola"], 100)
	var b := H.fighter("b", [], 100)
	b.mirror = 1
	_el(a, 0, "Na")
	_el(a, 1, "Cs")
	H.hand(a, [4, 4])
	var ev := H.cast(a, b, {"bola": [0, 1]})
	assert_eq(a.hp, 100 - 16, "o golpe voltou")
	assert_eq(a.burn, 3 + 3, "queima da Bola e do Sódio voltam")
	assert_eq(a.poison, 2, "o Césio também")
	assert_eq(b.burn, 0)
	assert_eq(b.poison, 0)
	assert_eq(_ev_count(ev, "fx_back"), 1, "a tela avisa que os efeitos voltaram")


func test_reflexo_esquivado_nao_pega_em_ninguem():
	var a := H.fighter("a", ["faisca"], 100)
	var b := H.fighter("b", [], 100)
	b.mirror = 1
	a.dodge = 1
	_el(a, 0, "Na")
	H.hand(a, [5])
	H.cast(a, b, {"faisca": [0]})
	assert_eq(a.hp, 100)
	assert_eq(a.burn, 0)
	assert_eq(b.burn, 0)


func test_imune_de_quem_atacou_anula_o_efeito_que_volta():
	var a := H.fighter("a", ["faisca"], 100)
	var b := H.fighter("b", [], 100)
	b.mirror = 1
	a.immune = 1
	_el(a, 0, "Na")
	H.hand(a, [5])
	H.cast(a, b, {"faisca": [0]})
	assert_eq(a.burn, 0)
	assert_eq(a.immune, 0)


func test_mexida_que_vem_no_golpe_segue_o_golpe():
	var a := H.fighter("a", ["anatomia"], 100)
	var b := H.fighter("b", [], 100)
	b.dodge = 1
	H.hand(a, [3, 3])
	H.cast(a, b, {"anatomia": [0, 1]})
	assert_true(b.hand_mods.is_empty(), "esquivada: sem mexida")
	var c := H.fighter("c", [], 100)
	c.mirror = 1
	a.reset_fight_state()
	H.hand(a, [3, 3])
	H.cast(a, c, {"anatomia": [0, 1]})
	assert_true(c.hand_mods.is_empty())
	assert_eq(a.hand_mods, ["top_to_one"], "refletida: a mexida volta")


func test_golpes_multiplos_cada_um_leva_o_seu_dado():
	var a := H.fighter("a", ["velocidade"])
	var b := H.fighter("b", [], 100)
	b.dodge = 1
	_el(a, 0, "Na")
	_el(a, 1, "Na")
	_el(a, 2, "Na")
	H.hand(a, [1, 2, 3])
	H.cast(a, b, {"velocidade": [0, 1, 2]})
	assert_eq(b.hp, 100 - 4 - 6, "o primeiro golpe foi esquivado")
	assert_eq(b.burn, 6, "só os dois que acertaram queimam")


func test_efeitos_em_quem_usa_valem_mesmo_esquivado():
	var a := H.fighter("a", ["faisca"], 100)
	var b := H.fighter("b", [], 100)
	b.dodge = 1
	_el(a, 0, "Ti")
	H.hand(a, [5])
	H.cast(a, b, {"faisca": [0]})
	assert_eq(a.block, Config.TITANIUM_BLOCK, "o Titânio é em mim")
