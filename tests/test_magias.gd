extends GutTest
## Magias do catálogo (docs/CATALOGO_MAGIAS.md): exigências, efeitos e mecânicas de apoio.

const H := preload("res://tests/helpers.gd")


func _ev_count(ev: Array, t: String) -> int:
	return ev.filter(func(e): return e.t == t).size()


# ------------------------------------------------------------ Exigências e formatos
func test_exigencias_novas():
	assert_true(Spells.accepts_partial("expectativa", [], 5), "≥ 5")
	assert_false(Spells.accepts_partial("expectativa", [], 4))
	assert_true(Spells.accepts_partial("imune", [], 4), "par")
	assert_false(Spells.accepts_partial("imune", [], 3))
	assert_true(Spells.accepts_partial("suor", [], 3), "ímpar")
	assert_false(Spells.accepts_partial("suor", [], 2))
	assert_true(Spells.complete("matematica", [4, 4, 4]))
	assert_false(Spells.complete("matematica", [5, 1, 1]), "todos ≤ 4")
	assert_true(Spells.complete("foto", [5, 6, 5, 5]))
	assert_false(Spells.complete("foto", [4, 6, 6, 6]), "todos ≥ 5")
	assert_true(Spells.complete("fisica", [6, 3]))
	assert_true(Spells.complete("fisica", [3, 6]))
	assert_false(Spells.complete("fisica", [6, 5]), "um deles ≤ 3")
	assert_true(Spells.accepts_partial("fisica", [], 6))
	assert_false(Spells.accepts_partial("fisica", [6], 5))
	assert_true(Spells.accepts_partial("bis", [], 6, true), "face mais alta")
	assert_false(Spells.accepts_partial("bis", [], 6, false))


func test_formatos_novos_no_cinto_e_na_grade():
	var belt := Inventory.make(6, 1)
	assert_true(belt.fits("velocidade"))
	assert_true(belt.fits("foto"), "reta de 4")
	assert_false(belt.fits("rasteira"), "diagonal não cabe no cinto")
	assert_false(belt.fits("matematica"))
	var grid := Inventory.make(4, 3)
	assert_true(grid.fits("matematica"), "cruz")
	assert_true(grid.fits("rasteira"), "diagonal de 3")


func test_grupos_das_magias():
	assert_false(Spells.in_pool("forca", "sorcerer"))
	assert_true(Spells.in_pool("forca", "assassin"))
	assert_true(Spells.in_pool("bis", "sorcerer"))
	assert_true(Spells.in_pool("remendo", "assassin"), "qualquer")


func test_duas_vezes_por_luta():
	var a := H.fighter("a", ["suor"])
	var b := H.fighter("b", [])
	for _k in 2:
		assert_true(TurnChoice.can_cast(a, 0))
		H.hand(a, [3])
		H.cast(a, b, {"suor": [0]})
	assert_false(TurnChoice.can_cast(a, 0), "esgotou os 2 usos")


# ------------------------------------------------------------ Dano
func test_golpe_nas_sombras_ignora_todas_as_defesas():
	var a := H.fighter("a", ["sombras"])
	var b := H.fighter("b", [])
	b.block = 10
	b.dodge = 1
	b.mirror = 1
	H.hand(a, [6])
	H.cast(a, b, {"sombras": [0]})
	assert_eq(b.hp, 34)
	assert_eq(b.block, 10)
	assert_eq(b.dodge, 1, "esquiva não foi gasta")


func test_fisica_aplicada_maior_vezes_menor():
	var a := H.fighter("a", ["fisica"])
	var b := H.fighter("b", [])
	H.hand(a, [6, 3])
	H.cast(a, b, {"fisica": [0, 1]})
	assert_eq(b.hp, 40 - 18)


func test_matematica_superior_produto():
	var a := H.fighter("a", ["matematica"])
	var b := H.fighter("b", [], 100)
	H.hand(a, [4, 4, 3])
	H.cast(a, b, {"matematica": [0, 1, 2]})
	assert_eq(b.hp, 100 - 48)


func test_exibicao_de_velocidade_golpes_separados():
	var a := H.fighter("a", ["velocidade"])
	var b := H.fighter("b", [])
	H.hand(a, [1, 2, 3])
	H.cast(a, b, {"velocidade": [0, 1, 2]})
	assert_eq(b.hp, 40 - 12)
	var c := H.fighter("c", [])
	c.dodge = 1
	H.hand(a, [2, 2, 2])
	var ev := H.cast(a, c, {"velocidade": [0, 1, 2]})
	assert_eq(_ev_count(ev, "dodged"), 1, "a esquiva só para o primeiro")
	assert_eq(c.hp, 40 - 5 * 4, "iguais: 6 golpes")


func test_levantar_peso_conta_os_1():
	var a := H.fighter("a", ["peso"])
	var b := H.fighter("b", [])
	H.hand(a, [1, 1, 5, 1])
	H.cast(a, b, {"peso": [0]})
	assert_eq(b.hp, 40 - 12)
	var c := H.fighter("c", [])
	H.hand(a, [1, 1, 1, 1, 1])
	H.cast(a, c, {"peso": [0]})
	assert_eq(c.hp, 40 - 12, "contam no máximo 3 dados de valor 1")
	assert_eq(Spells.max_uses("peso"), 2, "duas vezes por luta")


func test_forjamento_atira_os_1():
	var a := H.fighter("a", ["forjamento"])
	var b := H.fighter("b", [])
	assert_false(Spells.complete("forjamento", []), "vazio não lança")
	assert_true(Spells.complete("forjamento", [1]), "um dado já basta")
	assert_true(Spells.complete("forjamento", [1, 1, 1, 1]), "qualquer quantidade")
	assert_false(Spells.complete("forjamento", [1, 2]), "só dados de valor 1")
	assert_true(Spells.complete("forjamento", [1, 1, 1, 1, 1, 1, 1, 1]), "sem limite de dados")
	assert_eq(SpellCard.hole_count("forjamento"), 1, "um buraco só, com contador")
	assert_false(SpellCard.two_slots("forjamento"))
	assert_true(SpellCard.two_slots("ajuste"))
	H.hand(a, [1, 1, 1, 4])
	var ev := H.cast(a, b, {"forjamento": [0, 1, 2]})
	assert_eq(b.hp, 40 - 3, "três golpes de 1")
	assert_eq(ev.filter(func(e): return e.t == "hit").size(), 3)
	var c := TurnChoice.new()
	H.hand(a, [1, 1])
	assert_true(c.place(a, 0, 0))
	assert_true(c.incomplete_items(a).is_empty(), "com um dado já pode terminar o turno")
	var pick := EnemyAI.best_dice(a, "forjamento", [])
	assert_eq(pick.size(), 2, "a IA atira todos os 1")


func test_golpe_para_a_foto():
	var a := H.fighter("a", ["foto"])
	var b := H.fighter("b", [])
	H.hand(a, [5, 6, 5, 5])
	H.cast(a, b, {"foto": [0, 1, 2, 3]})
	assert_eq(b.hp, 40 - 24)


func test_bis_rola_de_novo_e_soma():
	var a := H.fighter("a", ["bis"])
	var b := H.fighter("b", [], 200)
	H.hand(a, [6])
	a.hand[0].top = true
	var ev := H.cast(a, b, {"bis": [0]})
	var extra := 0
	var rolls := ev.filter(func(e): return e.t == "encore")
	assert_between(rolls.size(), 1, Spells.ENCORE_MAX)
	for e in rolls:
		extra += int(e.v)
	assert_eq(b.hp, 200 - 6 - extra)
	assert_false(rolls[-1].again and rolls.size() < Spells.ENCORE_MAX, "para quando não sai a face máxima")


func test_bis_pede_face_mais_alta():
	var a := H.fighter("a", ["bis"])
	H.hand(a, [6])
	var c := TurnChoice.new()
	assert_false(c.place(a, 0, 0), "sem face máxima")
	a.hand[0].top = true
	assert_true(c.place(a, 0, 0))


func test_plagio_rouba_adesivo_ate_o_fim_da_luta():
	var a := H.fighter("a", ["plagio"])
	var b := H.fighter("b", [])
	b.bag[2].add_sticker(5)
	b.bag[2].add_sticker(5)
	H.hand(a, [2])
	a.hand[0].face = 1
	H.cast(a, b, {"plagio": [0]})
	assert_eq(b.hp, 40 - 4, "dano com o valor novo")
	assert_eq(int(b.bag[2].stickers[5]), 1)
	assert_eq(int(a.bag[0].stickers[1]), 1)
	a.end_fight_cleanup()
	b.end_fight_cleanup()
	assert_eq(int(a.bag[0].stickers[1]), 0, "volta no fim da luta")
	assert_eq(int(b.bag[2].stickers[5]), 2)


func test_plagio_sem_adesivo_no_inimigo():
	var a := H.fighter("a", ["plagio"])
	var b := H.fighter("b", [])
	H.hand(a, [2])
	H.cast(a, b, {"plagio": [0]})
	assert_eq(b.hp, 38)


func test_arrancar_das_maos_tira_o_dado_mais_forte():
	var a := H.fighter("a", ["arrancar"])
	var b := H.fighter("b", [])
	b.bag[3].add_sticker(5)
	H.hand(a, [2])
	H.cast(a, b, {"arrancar": [0]})
	assert_eq(b.hp, 38)
	assert_eq(b.benched, [3])
	assert_false(3 in b.draw_pile)
	for s in 10:
		b.draw_hand(H.rng(s))
		for e in b.hand:
			assert_ne(int(e.bag), 3)
		b.discard_hand()


func test_expectativa_toxica_dano_por_dado_parado():
	var a := H.fighter("a", ["expectativa"])
	var b := H.fighter("b", [])
	H.hand(a, [5])
	H.cast(a, b, {"expectativa": [0]})
	assert_eq(b.hp, 30)
	assert_eq(b.hand_mods, ["idle_dmg"])
	var ev := []
	Resolver.draw_and_roll(b, a, H.rng(), ev)
	Resolver.end_turn(b, [], ev)
	assert_eq(b.hp, 30 - Spells.IDLE_DMG * Config.HAND_SIZE)
	assert_eq(b.poison, 0, "dano, não veneno")


# ------------------------------------------------------------ Dados devolvidos
func test_forca_desnecessaria_parte_o_dado():
	var a := H.fighter("a", ["forca", "faisca"])
	var forca := H.item(a, "forca")
	var faisca := H.item(a, "faisca")
	H.hand(a, [6, 1])
	var c := TurnChoice.new()
	assert_true(c.place(a, forca, 0))
	assert_eq(a.hand_values(), [6, 1, 3, 3], "dois dados de metade")
	assert_true(c.place(a, faisca, 2), "o dado devolvido serve a outra magia")
	c.remove_die(0, a)
	assert_eq(a.hand.size(), 2, "tirar o dado recolhe os devolvidos")
	assert_eq(c.dice_in(faisca), [], "e solta quem usava")


func test_forca_desnecessaria_dano_e_cadeia():
	var a := H.fighter("a", ["forca", "fisica"])
	var b := H.fighter("b", [])
	H.hand(a, [6])
	var c := TurnChoice.new()
	c.place(a, H.item(a, "forca"), 0)
	c.place(a, H.item(a, "fisica"), 1)
	c.place(a, H.item(a, "fisica"), 2)
	var ev := []
	Resolver.cast_all(a, b, c, ev)
	assert_eq(b.hp, 40 - 6 - 9)


func test_imitacao_barata_copia_valor_e_elemento():
	var a := H.fighter("a", ["imitacao", "bola"])
	a.bag[0] = Die.with_element("Na")
	H.hand(a, [5])
	var c := TurnChoice.new()
	assert_true(c.place(a, H.item(a, "imitacao"), 0))
	assert_eq(a.hand_values(), [5, 5, 5])
	assert_eq(a.die_of(a.hand[1]).element, "Na")
	assert_true(c.place(a, H.item(a, "bola"), 1))
	assert_true(c.place(a, H.item(a, "bola"), 2), "par fabricado")


# ------------------------------------------------------------ Marca
func test_pose_congelada_volta_com_o_mesmo_valor():
	var a := H.fighter("a", ["pose"])
	var b := H.fighter("b", [])
	H.hand(a, [4])
	H.cast(a, b, {"pose": [0]})
	assert_eq(a.block, 4)
	assert_eq(int(a.marked.value), 4)
	assert_false(0 in a.discard, "o dado marcado não vai para o descarte")
	a.draw_hand(H.rng())
	a.roll_hand(H.rng(), [])
	assert_eq(a.hand.size(), Config.HAND_SIZE + 1, "além da mão normal")
	assert_eq(int(a.hand[-1].value), 4)
	assert_true(a.marked.is_empty())


func test_recuo_estrategico_esquiva_e_volta_valendo_6():
	var a := H.fighter("a", ["recuo"])
	var b := H.fighter("b", [])
	H.hand(a, [1])
	H.cast(a, b, {"recuo": [0]})
	assert_eq(a.dodge, 1)
	assert_eq(int(a.marked.value), 6)


func test_concentrar_forca_funde_os_dados():
	var a := H.fighter("a", ["concentrar"])
	var b := H.fighter("b", [])
	H.hand(a, [3, 3])
	H.cast(a, b, {"concentrar": [0, 1]})
	assert_eq(a.block, 6)
	assert_eq(int(a.marked.bag), -1)
	assert_eq(int(a.marked.value), 6)


func test_impulso_calculado_volta_com_mais_2():
	var a := H.fighter("a", ["impulso"])
	var b := H.fighter("b", [])
	H.hand(a, [4])
	H.cast(a, b, {"impulso": [0]})
	assert_eq(b.hp, 36)
	a.draw_hand(H.rng())
	a.roll_hand(H.rng(), [])
	var e: Dictionary = a.hand[-1]
	assert_eq(int(e.bag), 0)
	assert_eq(int(e.value), a.bag[0].value(int(e.face)) + 2)


# ------------------------------------------------------------ Defesa
func test_revide_elegante_devolve_o_valor():
	var a := H.fighter("a", ["faisca"])
	var b := H.fighter("b", ["revide"])
	H.hand(b, [3])
	H.cast(b, a, {"revide": [0]})
	assert_eq(b.block, 6)
	H.hand(a, [5])
	H.cast(a, b, {"faisca": [0]})
	assert_eq(b.hp, 40)
	assert_eq(a.hp, 37, "revide de 3")


func test_armadura_e_presenca():
	var a := H.fighter("a", ["armadura", "presenca"])
	var b := H.fighter("b", [])
	H.hand(a, [3, 3, 6, 1, 2])
	H.cast(a, b, {"armadura": [0, 1], "presenca": [2]})
	assert_eq(a.block, 18 + 15)


func test_improviso_brilhante_sobras_viram_bloqueio():
	var a := H.fighter("a", ["improviso"])
	var b := H.fighter("b", [])
	a.bag[2] = Die.with_element("U")
	H.hand(a, [1, 4, 5])
	H.cast(a, b, {"improviso": [0]})
	assert_eq(a.block, 9)
	assert_eq(a.poison, 0, "Urânio que sobrou não envenena")


func test_imune_a_criticas_anula_o_proximo_efeito():
	var a := H.fighter("a", ["bola"])
	var b := H.fighter("b", ["imune"])
	H.hand(b, [2])
	H.cast(b, a, {"imune": [0]})
	assert_eq(b.block, 4)
	H.hand(a, [3, 3])
	H.cast(a, b, {"bola": [0, 1]})
	assert_eq(b.hp, 40 - 8)
	assert_eq(b.burn, 0, "a queima foi anulada")
	assert_eq(b.immune, 0)


func test_suor_de_campeao_limpa_tudo():
	var a := H.fighter("a", ["suor"])
	var b := H.fighter("b", [])
	a.poison = 5
	a.burn = 3
	a.hand_mods = ["halve"]
	H.hand(a, [3])
	H.cast(a, b, {"suor": [0]})
	assert_eq(a.poison, 0)
	assert_eq(a.burn, 0)
	assert_eq(a.hand_mods, [])
	assert_eq(a.block, 3)


# ------------------------------------------------------------ Próxima mão do inimigo
func test_interrupcao_rude_tira_2_dados():
	var a := H.fighter("a", ["interrupcao"])
	var b := H.fighter("b", [])
	H.hand(a, [2, 3])
	H.cast(a, b, {"interrupcao": [0, 1]})
	var ev := []
	Resolver.draw_and_roll(b, a, H.rng(), ev)
	assert_eq(b.hand.size(), Config.HAND_SIZE - 2)


func test_rasteira_bloqueia_e_tira_1_dado():
	var a := H.fighter("a", ["rasteira"])
	var b := H.fighter("b", [])
	H.hand(a, [1, 2])
	H.cast(a, b, {"rasteira": [0, 1]})
	assert_eq(a.block, 6)
	var ev := []
	Resolver.draw_and_roll(b, a, H.rng(), ev)
	assert_eq(b.hand.size(), Config.HAND_SIZE - 1)


func test_chave_de_braco_divide_todos():
	var a := H.fighter("a", ["chave"])
	var b := H.fighter("b", [])
	H.hand(a, [3])
	H.cast(a, b, {"chave": [0]})
	var ev := []
	Resolver.draw_and_roll(b, a, H.rng(), ev)
	for v in b.hand_values():
		assert_between(int(v), 1, 3)


func test_meia_verdade_pares_viram_1():
	var a := H.fighter("a", ["meia_verdade"])
	var b := H.fighter("b", [])
	H.hand(a, [6])
	H.cast(a, b, {"meia_verdade": [0]})
	var ev := []
	Resolver.draw_and_roll(b, a, H.rng(3), ev)
	for v in b.hand_values():
		assert_eq(int(v) % 2, 1)


func test_licao_de_anatomia_face_maxima_vira_1():
	var a := H.fighter("a", ["anatomia"])
	var b := H.fighter("b", [])
	H.hand(a, [4, 4])
	H.cast(a, b, {"anatomia": [0, 1]})
	assert_eq(b.hp, 40 - 16)
	for s in 5:
		b.hand_mods = ["top_to_one"]
		var ev := []
		Resolver.draw_and_roll(b, a, H.rng(s), ev)
		assert_false(6 in b.hand_values())
		b.discard_hand()


func test_roubar_a_cena_leva_o_maior_dado():
	var a := H.fighter("a", ["roubar_cena"])
	var b := H.fighter("b", [])
	H.hand(a, [2])
	H.cast(a, b, {"roubar_cena": [0]})
	var ev := []
	Resolver.draw_and_roll(b, a, H.rng(), ev)
	assert_eq(b.hand.size(), Config.HAND_SIZE - 1)
	assert_eq(a.extra_next.size(), 1)
	var stolen := int(a.extra_next[0].value)
	for v in b.hand_values():
		assert_true(int(v) <= stolen, "levou o maior")
	a.draw_hand(H.rng())
	a.roll_hand(H.rng(), [])
	assert_eq(a.hand.size(), Config.HAND_SIZE + 1)
	assert_eq(int(a.hand[-1].value), stolen, "entra sem rolar")


# ------------------------------------------------------------ IA e salvamento
func test_ia_usa_os_dados_devolvidos():
	var a := H.fighter("a", ["forca", "fisica"])
	var b := H.fighter("b", [])
	H.hand(a, [6, 5])
	var c := EnemyAI.choose(a, b, H.rng())
	assert_eq(c.dice_in(H.item(a, "forca")), [0])
	assert_eq(c.ready_items(a).size(), 2, "a Física Aplicada usa uma metade")


func test_estado_novo_sobrevive_ao_salvamento():
	var a := H.fighter("a", ["pose"])
	a.marked = {"bag": 2, "temp": {}, "value": 5, "fixed": true, "plus": 0}
	a.hand_mods = ["halve"]
	a.benched = [4]
	a.riposte = 3
	a.immune = 1
	a.fight_mods = [{"bag": 1, "face": 2, "d": 1}]
	var b := Fighter.from_dict(JSON.parse_string(JSON.stringify(a.to_dict())))
	assert_eq(int(b.marked.value), 5)
	assert_eq(b.hand_mods, ["halve"])
	assert_eq(b.benched, [4])
	assert_eq(b.riposte, 3)
	assert_eq(b.immune, 1)
	assert_eq(b.fight_mods.size(), 1)
