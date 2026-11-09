extends GutTest
## Regras do motor v3 (docs/SPEC_v3.md).

const H := preload("res://tests/helpers.gd")


# ------------------------------------------------------------ Dados e elementos
func test_adesivo_soma_2_na_face_e_acumula():
	var d := Die.basic()
	assert_true(d.add_sticker(5))
	assert_eq(d.value(5), 8)
	d.add_sticker(5)
	assert_eq(d.value(5), 10)
	assert_eq(d.sticker_count(), 2)


func test_chumbo_tem_tres_faces_1_travadas():
	var d := Elements.lead()
	assert_eq(d.faces.slice(0, 3), [1, 1, 1])
	assert_false(d.add_sticker(0), "face travada")
	assert_true(d.add_sticker(5))


func test_hidrogenio_dobra_com_bolsa_de_menos_de_8():
	var f := H.fighter("a", ["faisca"])
	f.bag.resize(Elements.SOLITARY_BAG)
	f.bag[0] = Die.with_element("H")
	f.reset_fight_state()
	f.draw_pile = [0]
	f.hand_size = 1
	f.draw_hand(H.rng())
	f.roll_hand(H.rng(), [])
	assert_eq(Elements.SOLITARY_BAG, 7, "menos de 8 dados")
	assert_eq(f.hand[0].value, (int(f.hand[0].face) + 1) * 2)
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


func test_cesio_irradia_e_o_veneno_nao_cai():
	var a := H.fighter("a", ["faisca"])
	var b := H.fighter("b", [])
	a.bag[0] = Die.with_element("Cs")
	a.bag[1] = Die.with_element("Cs")
	a.bag[2] = Die.with_element("Cs")
	H.hand(a, [3, 5, 5])
	H.cast(a, b, {"faisca": [0]})
	assert_eq(b.poison, Config.CESIUM_POISON, "cada dado de Césio usado põe 1")
	for t in 3:
		Resolver.start_turn(b, [])
	assert_eq(b.poison, Config.CESIUM_POISON, "não cai com as rodadas")
	assert_eq(b.hp, 40 - 3 - 3 * Config.CESIUM_POISON)
	var hp := b.hp
	H.hand(a, [3, 5, 5])
	H.cast(a, b, {"faisca": [0]})
	assert_eq(b.poison, 2 * Config.CESIUM_POISON, "acumula")
	assert_eq(a.poison, 0, "não irradia quem usa")
	assert_true(hp > b.hp)


func test_cesio_parado_nao_irradia_e_imune_bloqueia():
	var a := H.fighter("a", ["faisca"])
	var b := H.fighter("b", [])
	a.bag[1] = Die.with_element("Cs")
	H.hand(a, [3, 4])
	H.cast(a, b, {"faisca": [0]})
	assert_eq(b.poison, 0, "Césio que sobra na mão não faz nada")
	b.immune = 1
	a.bag[0] = Die.with_element("Cs")
	H.hand(a, [3])
	H.cast(a, b, {"faisca": [0]})
	assert_eq(b.poison, 0, "Imune a Críticas anula a radiação")
	assert_true("Cs" in Elements.SHOP)
	assert_eq(Elements.rarity("Cs"), "uncommon")


func test_litio_carrega_parado_e_descarrega_ao_usar():
	var a := H.fighter("a", ["faisca"])
	var b := H.fighter("b", [])
	a.bag[1] = Die.with_element("Li")
	H.hand(a, [3, 4])
	var ev := H.cast(a, b, {"faisca": [0]})
	assert_eq(a.bag[1].charge, Config.LITHIUM_STEP, "parado na mão: carrega")
	assert_true(ev.any(func(e): return e.t == "charge"))
	for t in 5:
		H.hand(a, [3, 4])
		H.cast(a, b, {"faisca": [0]})
	assert_eq(a.bag[1].charge, Config.LITHIUM_CAP, "até o teto")
	# A carga soma na rolagem.
	a.hand = [{"bag": 1, "temp": null, "face": 0, "value": 0}]
	a._roll_entry(a.hand[0], H.rng())
	assert_eq(int(a.hand[0].value), int(a.hand[0].face) + 1 + Config.LITHIUM_CAP)
	assert_eq(str(a.hand[0].cause), "Li")
	# Usado numa magia: descarrega.
	H.cast(a, b, {"faisca": [0]})
	assert_eq(a.bag[1].charge, 0, "descarrega ao ser usado")
	a.bag[1].charge = 4
	a.end_fight_cleanup()
	assert_eq(a.bag[1].charge, 0, "a luta seguinte começa sem carga")
	assert_eq(Elements.rarity("Li"), "common")
	assert_true("Li" in Elements.SHOP)


func test_titanio_da_bloqueio_ao_usar():
	var a := H.fighter("a", ["faisca"])
	var b := H.fighter("b", [])
	a.bag[0] = Die.with_element("Ti")
	H.hand(a, [3, 4])
	H.cast(a, b, {"faisca": [0]})
	assert_eq(a.block, Config.TITANIUM_BLOCK, "usado: bloqueio")
	assert_eq(b.hp, 40 - 3, "o dano da magia continua")
	a.block = 0
	a.bag[0] = Die.basic()
	a.bag[1] = Die.with_element("Ti")
	H.hand(a, [3, 4])
	H.cast(a, b, {"faisca": [0]})
	assert_eq(a.block, 0, "Titânio parado não bloqueia")
	assert_eq(Elements.rarity("Ti"), "common")
	assert_true("Ti" in Elements.SHOP)


func test_ouro_da_moeda_por_uso_e_a_jornada_recebe():
	var run := RunState.new_run(11)
	for _k in 5:
		if run.duel != null:
			break
		run.choose(0)
	var a := run.duel.player
	var b := run.duel.enemy
	a.bag[0] = Die.with_element("Au")
	a.bag[1].add_gold(2)
	a.inventory.add("faisca")
	a.hand = [{"bag": 0, "temp": null, "face": 3, "value": 4}]
	var ev := H.cast(a, b, {"faisca": [0]})
	assert_eq(a.coins_won, Config.GOLD_COINS, "Ouro usado: +1")
	assert_true(ev.any(func(e): return e.t == "coin" and e.src == "Au"))
	a.hand = [{"bag": 1, "temp": null, "face": 2, "value": 3}]
	H.cast(a, b, {"faisca": [0]})
	assert_eq(a.coins_won, 2, "face com adesivo de ouro: +1")
	a.hand = [{"bag": 1, "temp": null, "face": 0, "value": 1}]
	H.cast(a, b, {"faisca": [0]})
	assert_eq(a.coins_won, 2, "outra face do mesmo dado não dá")
	var before := run.coins
	run.duel.state = "won"
	run.finish_duel()
	assert_eq(run.coins, before + 2 + RunState.door_coins(run.door), "as moedas da luta vão para a jornada")
	assert_eq(run.hero.coins_won, 0)


func test_inimigo_nao_junta_moedas():
	var a := H.fighter("a", ["faisca"])
	a.is_player = false
	var b := H.fighter("b", [])
	a.bag[0] = Die.with_element("Au")
	H.hand(a, [3])
	H.cast(a, b, {"faisca": [0]})
	assert_eq(a.coins_won, 0)


func test_corte_duplo_aplica_os_efeitos_nos_dois_golpes():
	var a := H.fighter("a", ["corte"])
	var b := H.fighter("b", [], 200)
	a.bag[0] = Die.with_element("Na")
	a.bag[1] = Die.with_element("Cs")
	H.hand(a, [3, 5])
	H.cast(a, b, {"corte": [0, 1]})
	assert_eq(b.burn, 2 * Config.SODIUM_BURN, "ímpares: dois golpes, Sódio queima duas vezes")
	assert_eq(b.poison, 2 * Config.CESIUM_POISON, "Césio irradia duas vezes")
	var c := H.fighter("c", [], 200)
	H.hand(a, [3, 4])
	H.cast(a, c, {"corte": [0, 1]})
	assert_eq(c.burn, Config.SODIUM_BURN, "um golpe só: uma vez")


func test_velocidade_efeito_por_golpe():
	var a := H.fighter("a", ["velocidade"])
	var b := H.fighter("b", [], 300)
	a.bag[0] = Die.with_element("Na")
	H.hand(a, [2, 2, 2])
	H.cast(a, b, {"velocidade": [0, 1, 2]})
	assert_eq(b.burn, 2 * Config.SODIUM_BURN, "dados iguais: cada um bate duas vezes")


func test_loja_copiar_dado_e_adesivo_de_ouro():
	var run := RunState.new_run(11)
	run.choose(0)
	run.coins = 100
	run.hero.bag[3] = Die.with_element("Cs")
	run.hero.bag[3].add_sticker(5)
	run.phase = "shop"
	run.options = Shop.shop(run.hero, run.rng, 0)
	var ci := run.options.map(func(o): return o.kind).find("copy_die")
	assert_gt(ci, -1, "a Loja vende copiar um dado")
	assert_eq(run.choose(ci, {}), "ui.pick_die")
	var n := run.hero.bag.size()
	assert_eq(run.choose(ci, {"die": 3}), "")
	assert_eq(run.hero.bag.size(), n + 1)
	assert_eq(run.hero.bag.back().element, "Cs")
	assert_eq(run.hero.bag.back().value(5), 8, "copia os adesivos")
	assert_eq(run.coins, 100 - Config.PRICE_COPY_DIE)
	var gi := run.options.map(func(o): return o.kind).find("gold_sticker")
	assert_gt(gi, -1, "a Loja vende adesivo de ouro")
	assert_eq(run.choose(gi, {"die": 0, "face": 1}), "")
	assert_eq(int(run.hero.bag[0].gold[1]), 1)
	var d := Die.from_dict(run.hero.bag[0].to_dict())
	assert_eq(int(d.gold[1]), 1, "o save guarda o adesivo de ouro")
	assert_true(Shop.well(run.rng).any(func(o): return o.kind == "gold_sticker"), "o Poço também")


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
	# Cada jogável começa com uma mexida (docs/SPEC_v3.1.md §1.8).
	var mex := {"sorcerer": "segunda", "assassin": "ajuste", "barbarian": "pico", "vampire": "sangria", "metallurgist": "virar"}
	for arch in mex:
		assert_true(mex[arch] in EnemyFactory.base(arch).inventory.ids(), arch)
	assert_eq(EnemyFactory.base("sorcerer").inventory.ids(), ["faisca", "bola", "segunda"])
	assert_eq(EnemyFactory.base("assassin").inventory.ids(), ["estocada", "corte", "esquiva_mais", "ajuste"])
	var run := RunState.new_run(3)
	run.choose(0) ## Erudito
	assert_eq(run.hero.inventory.items.size(), 4, "Feiticeiro: 2 + Segunda Chance + a escolha do Erudito")
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
	var heal := int(ceil(run.hero.max_hp * Config.WIN_HEAL_FRACTION))
	assert_eq(run.hero.hp, 33 + heal, "a vida persiste; a vitória recupera 10%")
	assert_eq(run.last_heal, heal)


func test_masmorra_1_paradas_e_mestres_no_10_20_30():
	var run := RunState.new_run(3)
	run.choose(0)
	var masters := []
	for n in range(1, Config.LAST_FLOOR + 1):
		assert_eq(run.floor_n, n)
		assert_eq(run.phase, "doors", "andar %d" % n)
		if EnemyFactory.is_master(n):
			assert_eq(run.options.size(), 1, "só a porta do Mestre no andar %d" % n)
		run.choose(0)
		if run.duel.enemy.master_id != "":
			masters.append(run.duel.enemy.master_id)
		run.duel.state = "won"
		run.finish_duel()
		if n == Config.LAST_FLOOR:
			break
		if EnemyFactory.is_master(n):
			assert_eq(run.phase, "master_reward", "recompensa do Mestre no andar %d" % n)
			run.choose(1) # +1 dado na mão
		else:
			run.leave()
		if n % Config.REST_EVERY == 0:
			assert_eq(run.phase, "rest")
			run.choose(run.options.map(func(o): return o.id).find("heal"))
			if run.phase == "rest":
				run.choose(0)
			while run.phase != "doors":
				run.leave() ## Volta para a parada e segue.
	assert_eq(masters, ["porteiro", "alquimista", "reator"])
	assert_eq(run.phase, "victory")
	assert_eq(run.hero.hand_size, Config.HAND_SIZE + 2, "duas recompensas de Mestre (andares 10 e 20)")


func test_porteiro_poe_chumbo_na_mao():
	var run := RunState.new_run(3)
	run.floor_n = 10
	run.start_duel()
	var leads := run.duel.player.hand.filter(func(e): return run.duel.player.die_of(e).element == "Pb")
	assert_eq(leads.size(), 1)
	assert_eq(run.duel.player.hand.size(), Config.HAND_SIZE + 1)


func test_alquimista_troca_o_maior_pelo_menor_dela():
	var p := H.fighter("p", ["faisca"], 40, true)
	var e := EnemyFactory.create(20, "normal", H.rng(4))
	assert_eq(e.master_id, "alquimista")
	e.last_hand = [5, 2, 4]
	p.hand = []
	for v in [3, 6, 1]:
		var en := p._entry(p.hand.size())
		en.value = v
		p.hand.append(en)
	var ev := []
	Resolver.alchemy(p, e, ev)
	assert_eq(p.hand_values(), [3, 2, 1])
	assert_eq(e.last_hand, [5, 6, 4])
	assert_eq(ev.filter(func(x): return x.t == "alchemy").size(), 1)
	# Sem mão anterior dela, nada muda.
	e.last_hand = []
	Resolver.alchemy(p, e, [])
	assert_eq(p.hand_values(), [3, 2, 1])


func test_reator_bolsa_de_uranio_e_dado_parado_envenena():
	var run := RunState.new_run(3, "assassin")
	run.floor_n = Config.LAST_FLOOR
	run.start_duel()
	var e := run.duel.enemy
	assert_eq(e.master_id, "reator")
	assert_true(e.bag.all(func(d): return d.element == "U" or d.element == "Fe"), "bolsa de Urânio (e o Ferro do Bárbaro)")
	assert_true(run.duel.reactor())
	var p := run.duel.player
	var n := p.hand.filter(func(x): return p.die_of(x).element != "U").size()
	var before := p.poison
	Resolver.end_turn(p, [], [], [], true)
	assert_eq(p.poison - before, n * Config.REACTOR_POISON)


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
	assert_eq(run.hero.bag[2].value(5), 8)
	assert_eq(run.coins, 100 - Config.PRICE_STICKER)
	assert_eq(run.choose(0, {"die": 2, "face": 5}), "")
	assert_eq(run.coins, 100 - Config.PRICE_STICKER * 3, "o segundo adesivo no mesmo dado custa o dobro")
	assert_eq(run.choose(4, {"die": 0}), "")
	assert_eq(run.hero.bag.size(), 7)
	run.leave()
	assert_eq(run.phase, "rest", "volta para a parada")
	run.leave()
	assert_eq(run.phase, "doors")
	run.phase = "school"
	run.options = Shop.school(run.hero, run.rng)
	var ev := run.options.map(func(o): return o.kind).find("evolve")
	var item: int = run.options[ev].item
	run.choose(ev)
	assert_eq(int(run.hero.inventory.items[item].level), 2)
	assert_eq(run.phase, "rest", "a Escola volta para a parada")


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


func test_eventos_do_duelo_levam_os_status_do_momento():
	var a := H.fighter("a", ["esquiva"], 40, true)
	var b := H.fighter("b", ["faisca"])
	Resolver.watch = [a, b]
	H.hand(a, [2])
	var ev := H.cast(a, b, {"esquiva": [0]})
	H.hand(b, [6])
	ev.append_array(H.cast(b, a, {"faisca": [0]}))
	Resolver.watch = []
	var up: Dictionary = ev.filter(func(e): return e.t == "dodge_up")[0]
	assert_true(up.st.player.dodge, "esquiva guardada no momento em que é criada")
	var used: Dictionary = ev.filter(func(e): return e.t == "dodged")[0]
	assert_false(used.st.player.dodge, "e gasta quando anula o golpe")
	assert_false(a.dodge)
	assert_false(H.cast(a, b, {}).any(func(e): return e.has("st")), "fora do duelo, sem anotação")


func test_queima_anotada_ja_descontada():
	var a := H.fighter("a", [])
	a.burn = 2
	Resolver.watch = [a]
	var ev := []
	Resolver.start_turn(a, ev)
	Resolver.watch = []
	assert_eq(ev[0].n, 2)
	assert_eq(ev[0].st.enemy.burn, 1, "o ícone já mostra a queima que sobra")


func test_texto_da_magia_por_nivel():
	assert_eq(Texts.spell_fx("escudo", 1), "Bloqueio = valor ×3")
	assert_eq(Texts.spell_fx("escudo", 2), "Bloqueio = valor ×4,5")
	assert_eq(Texts.spell_fx("escudo", 3), "Bloqueio = valor ×6")
	assert_eq(Texts.spell_fx("faisca", 2), "Dano = valor ×1,5")
	assert_eq(Texts.spell_fx("bola", 3), "Soma ×4 e queima 3")
	assert_eq(Texts.spell_fx("sacrificio", 2), "Destrói o dado; +8 de dano nas magias desta luta", "constante arredondada como no jogo")
	assert_eq(Texts.spell_fx("banquete", 2), "Dano = soma ×1,5; cura o menor ×1,5")
	assert_eq(Texts.spell_fx("espelho", 2), "Reflete o próximo golpe ×1,5")
	assert_eq(Texts.spell_fx("esquiva", 2), "Anula o próximo golpe; vira bloqueio ×0,5")
	assert_eq(Texts.spell_fx("esquiva", 3), "Anula o próximo golpe; vira bloqueio ×1")
	assert_eq(Texts.spell_fx("chave", 3), "Dados dele valem metade; dano = valor ×2")
	for id in Spells.DATA:
		for lvl in [1, 2, 3]:
			assert_false("{" in Texts.spell_fx(id, lvl), "%s nível %d sem marcador sobrando" % [id, lvl])
	# Toda magia melhora com o nível, e o texto diz como.
	for id in Spells.DATA:
		assert_true(Texts.scales_with_level(id), id)
		assert_ne(Texts.spell_fx(id, 2), Texts.spell_fx(id, 1), id)
		assert_ne(Texts.spell_fx(id, 3), Texts.spell_fx(id, 2), id)


# ------------------------------------------------------------ Ganho por nível das magias sem número
func _lv(f: Fighter, id: String, lvl: int) -> void:
	f.inventory.items[H.item(f, id)].level = lvl


func test_espelho_evoluido_devolve_mais():
	var a := H.fighter("a", ["faisca"])
	var b := H.fighter("b", ["espelho"])
	_lv(b, "espelho", 3)
	H.hand(b, [1])
	H.cast(b, a, {"espelho": [0]})
	H.hand(a, [6])
	H.cast(a, b, {"faisca": [0]})
	assert_eq(b.hp, 40)
	assert_eq(a.hp, 28, "devolve o dobro no nível 3")


func test_esquiva_evoluida_vira_bloqueio():
	for c in [[1, 0], [2, 3], [3, 6]]:
		var a := H.fighter("a", ["faisca"])
		var b := H.fighter("b", ["esquiva"])
		_lv(b, "esquiva", c[0])
		H.hand(b, [2])
		H.cast(b, a, {"esquiva": [0]})
		H.hand(a, [6])
		H.cast(a, b, {"faisca": [0]})
		assert_eq(b.hp, 40, "nível %d anula" % c[0])
		assert_eq(b.block, c[1], "nível %d: bloqueio do golpe anulado" % c[0])
	var f := H.fighter("f", ["esquiva"])
	_lv(f, "esquiva", 3)
	H.hand(f, [2])
	H.cast(f, H.fighter("x", []), {"esquiva": [0]})
	Resolver.start_turn(f, [])
	assert_eq(f.dodge_lvl, 1, "o nível some com a esquiva")


func test_mexidas_evoluidas_causam_dano():
	for c in [[1, 40], [2, 37], [3, 34]]:
		var a := H.fighter("a", ["chave"])
		var b := H.fighter("b", [])
		_lv(a, "chave", c[0])
		H.hand(a, [3])
		H.cast(a, b, {"chave": [0]})
		assert_eq(b.hp, c[1], "Chave nível %d" % c[0])
		assert_true("halve" in b.hand_mods, "a mexida continua")


func test_improviso_evoluido_rende_mais_bloqueio():
	var a := H.fighter("a", ["improviso"])
	_lv(a, "improviso", 2)
	H.hand(a, [1, 4, 5])
	H.cast(a, H.fighter("b", []), {"improviso": [0]})
	assert_eq(a.block, Config.scale(4, 2) + Config.scale(5, 2), "sobras ×1,5")


func test_imitacao_evoluida_copias_valem_mais():
	var a := H.fighter("a", ["imitacao"])
	_lv(a, "imitacao", 3)
	H.hand(a, [4])
	var c := TurnChoice.new()
	assert_true(c.place(a, H.item(a, "imitacao"), 0))
	assert_eq(a.hand_values(), [4, 8, 8], "cópias valem o dobro no nível 3")


# ------------------------------------------------------------ Spec v3.1: portas, desgaste e Mestres
func test_porta_mostra_o_inimigo_que_vai_lutar():
	var run := RunState.new_run(11, "barbarian")
	assert_eq(run.phase, "doors")
	for o in run.options:
		assert_true(o.has("enemy") and str(o.arch) != "", "cada porta tem o inimigo")
	var want: Dictionary = run.options[0].enemy
	run.choose(0)
	assert_eq(run.duel.enemy.archetype, str(want.archetype), "o inimigo da porta é o da luta")
	assert_eq(run.duel.enemy.name, str(want.name))


func test_save_antigo_na_porta_ganha_inimigo():
	var run := RunState.new_run(12, "barbarian")
	var d := run.to_dict()
	for o in d.options:
		o.erase("enemy")
		o.erase("arch")
	var back := RunState.from_dict(JSON.parse_string(JSON.stringify(d)))
	for o in back.options:
		assert_true(o.has("enemy"))
	back.choose(0)
	assert_eq(back.phase, "duel")


func test_recompensa_tem_opcoes_pela_porta():
	var h := EnemyFactory.base("barbarian")
	assert_eq(Shop.reward(h, H.rng(), 3, "facil").size(), 2)
	assert_eq(Shop.reward(h, H.rng(), 3, "normal").size(), 3)
	assert_eq(Shop.reward(h, H.rng(), 3, "dificil").size(), 3)
	var ins := Shop.reward(h, H.rng(), 3, "insana")
	assert_eq(ins.size(), 4)
	assert_true(ins.any(func(o): return o.kind == "spell" and Spells.rarity(o.id) == "rare"))
	assert_true(RunState.door_coins("dificil") > RunState.door_coins("normal"))


func test_cura_da_parada_e_do_mestre():
	var run := RunState.new_run(13, "barbarian")
	run.hero.hp = 10
	run.phase = "rest"
	run.options = [{"kind": "stop", "id": "heal", "price": Config.PRICE_HEAL_STOP, "needs": ""}]
	assert_eq(run.choose(0), "ui.not_enough", "a Cura custa moedas")
	run.coins = Config.PRICE_HEAL_STOP
	assert_eq(run.choose(0), "")
	assert_eq(run.hero.hp, 10 + int(ceil(run.hero.max_hp * Config.HEAL_STOP_FRACTION)))
	assert_eq(run.coins, 0)
	assert_eq(run.phase, "rest", "continua na parada")
	assert_eq(run.choose(0), "ui.stop_used", "uma vez por parada")


func test_cura_da_parada_vale_metade_para_o_vampiro():
	var run := RunState.new_run(13, "vampire")
	run.hero.hp = 10
	run.coins = Config.PRICE_HEAL_STOP
	run.phase = "rest"
	run.options = [{"kind": "stop", "id": "heal", "price": Config.PRICE_HEAL_STOP, "needs": ""}]
	var n := int(ceil(run.hero.max_hp * Config.HEAL_STOP_FRACTION * 0.5))
	assert_eq(RunState.heal_stop_amount(run.hero), n)
	var before := run.hero.max_hp
	assert_eq(run.choose(0), "")
	assert_eq(run.hero.hp, 10 + n, "metade da Cura (a Sede vem vazia)")
	assert_eq(run.hero.max_hp, before + 1, "a Sede continua valendo")


func test_parada_entra_e_volta_quando_quiser():
	var run := RunState.new_run(21, "sorcerer")
	run.choose(0)
	run.coins = 200
	run.hero.hp = 10
	run.phase = "rest"
	run.options = [
		{"kind": "stop", "id": "well", "price": 0, "needs": ""},
		{"kind": "stop", "id": "heal", "price": Config.PRICE_HEAL_STOP, "needs": ""},
		{"kind": "stop", "id": "shop", "price": 0, "needs": ""},
	]
	assert_eq(run.choose(0), "")
	assert_eq(run.phase, "well")
	var well := run.options.duplicate(true)
	assert_eq(run.choose(0, {"die": 1, "face": 5}), "", "compra no Poço")
	run.leave()
	assert_eq(run.phase, "rest", "volta depois de comprar")
	assert_eq(run.choose(1), "", "e usa a Cura")
	assert_gt(run.hero.hp, 10)
	assert_eq(run.choose(2), "")
	assert_eq(run.phase, "shop")
	var shop_n := run.options.size()
	assert_eq(run.choose(0), "")
	run.leave()
	# Voltar ao Poço: as mesmas ofertas de antes (não sorteia de novo).
	assert_eq(run.choose(0), "")
	assert_eq(run.options.map(func(o): return o.kind), well.map(func(o): return o.kind))
	run.leave()
	assert_eq(run.choose(2), "")
	assert_eq(run.options.size(), shop_n - 1, "a magia comprada não volta à Loja")
	# Salvar e carregar dentro da Loja mantém a parada.
	var back := RunState.from_dict(JSON.parse_string(JSON.stringify(run.to_dict())))
	assert_eq(back.phase, "shop")
	assert_eq(back.options.size(), shop_n - 1)
	back.leave()
	assert_eq(back.phase, "rest")
	assert_eq(back.options.size(), 3)
	assert_true(back.options[1].get("used", false), "a Cura já usada continua marcada")
	back.leave()
	assert_eq(back.phase, "doors", "Seguir vai para as portas")


func test_mestres_tem_kit_fixo_que_cabe():
	for fl in Config.MASTER_FLOORS:
		var e := EnemyFactory.create(fl, "normal", H.rng(fl))
		var kit: Dictionary = Config.MASTER_KITS[e.master_id]
		assert_eq(e.inventory.ids().size(), kit.spells.size(), e.master_id)
		var occ := 0
		for it in e.inventory.items:
			occ += Spells.shape(it.id, int(it.rot)).size()
			for c in e.inventory.cells_of(it):
				assert_true(e.inventory.is_cell(c), "%s: %s dentro do inventário" % [e.master_id, it.id])
		assert_eq(e.inventory.occupied().size(), occ, "%s sem sobreposição" % e.master_id)
		var e2 := EnemyFactory.create(fl, "normal", H.rng(fl + 100))
		assert_eq(e2.inventory.ids(), e.inventory.ids(), "kit fixo, sem sorteio")
	var reator := EnemyFactory.create(30, "normal", H.rng())
	assert_true(reator.bag.all(func(d): return d.element == "U"), "Reator: bolsa de Urânio")
	var alq := EnemyFactory.create(20, "normal", H.rng())
	assert_eq(alq.bag.filter(func(d): return d.element == "Hg").size(), 4)


func test_adesivo_do_inimigo_pode_acumular():
	var f := EnemyFactory.base("sorcerer")
	f.bag[0].add_sticker(5)
	var stacked := false
	for s in 20:
		var g := EnemyFactory.base("sorcerer")
		g.bag[0].add_sticker(5)
		EnemyFactory._sticker(g, H.rng(s))
		if int(g.bag[0].stickers[5]) == 2:
			stacked = true
	assert_true(stacked)
