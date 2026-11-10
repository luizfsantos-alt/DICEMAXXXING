extends GutTest
## Xamã: Síntese, Antítese, Correspondência e Marcado (docs/XAMA.md).

const H = preload("res://tests/helpers.gd")


## Xamã com dados comuns (sem o Cobre, para as contas ficarem limpas) contra um alvo.
func _pair(hp := 75, foe_hp := 60) -> Array:
	var s := EnemyFactory.base("shaman")
	s.reset_fight_state()
	for i in s.bag.size():
		s.bag[i] = Die.basic()
	s.hp = hp
	var e := H.fighter("alvo", ["faisca", "corte"], foe_hp)
	Fighter.link(s, e)
	return [s, e]


func _lost(ev: Array, side: String) -> int:
	var n := 0
	for x in ev:
		if str(x.side) != side:
			continue
		match str(x.t):
			"hit", "echo":
				n += int(x.dmg)
			"sigil_break", "self_dmg", "poison", "burn":
				n += int(x.n)
	return n


func test_ficha_do_xama():
	var s := EnemyFactory.base("shaman")
	assert_eq(s.max_hp, 75)
	assert_eq(s.hand_size, 4)
	assert_eq(s.bag.filter(func(d): return d.element == "Cu").size(), 2, "2 Cobre")
	assert_eq(s.inventory.ids(), ["antitese", "sintese", "polarizar"])
	for c in [Vector2i(0, 1), Vector2i(3, 1), Vector2i(0, 2), Vector2i(3, 2)]:
		assert_false(s.inventory.is_cell(c), "Ampulheta sem a casa %s" % c)
	for r in Config.RARITIES:
		assert_false("sintese" in Spells.ids_of_rarity(r), "Síntese fora da Loja")
		assert_false("antitese" in Spells.ids_of_rarity(r), "Antítese fora da Loja")
	assert_eq(Texts.character("shaman")[0], "Xamã")


func test_sintese_so_aceita_dado_maior_que_1():
	assert_false(Spells.accepts_partial("sintese", [], 1))
	assert_true(Spells.accepts_partial("sintese", [], 2))


func test_sintese_cura_efetiva_vira_dano_e_bloqueio_vira_marca():
	var p := _pair(60)
	var s: Fighter = p[0]
	var e: Fighter = p[1]
	H.hand(s, [6])
	var ev := H.cast(s, e, {"sintese": [0]})
	assert_eq(s.hp, 65, "cura 5")
	assert_eq(s.block, 5, "bloqueio 5")
	assert_eq(e.hp, 55, "a cura vira 5 de dano")
	assert_eq(e.sigil, 5, "o bloqueio vira 5 de marcado")
	assert_true(ev.any(func(x): return x.t == "echo" and int(x.dmg) == 5))


func test_cura_com_vida_cheia_nao_causa_dano():
	var p := _pair(75)
	H.hand(p[0], [4])
	H.cast(p[0], p[1], {"sintese": [0]})
	assert_eq(p[1].hp, 60, "vida cheia: cura 0, dano 0")
	assert_eq(p[1].sigil, 3, "o bloqueio marca mesmo assim")


func test_cura_parcial_causa_so_o_que_curou():
	var p := _pair(72)
	H.hand(p[0], [6])
	H.cast(p[0], p[1], {"sintese": [0]})
	assert_eq(p[1].hp, 57, "faltavam 3: dano 3")


func test_bloqueio_do_inimigo_absorve_a_correspondencia():
	var p := _pair(60)
	p[1].block = 3
	H.hand(p[0], [6])
	H.cast(p[0], p[1], {"sintese": [0]})
	assert_eq(p[1].block, 0)
	assert_eq(p[1].hp, 58, "5 de dano, 3 absorvidos")


func test_antitese_fere_antes_de_tudo_e_ignora_o_proprio_bloqueio():
	# Síntese antes da Antítese no inventário: o dano em si vem primeiro mesmo assim.
	var s := H.fighter("x", ["sintese", "antitese"], 75)
	s.archetype = "shaman"
	var e := H.fighter("alvo", ["faisca"], 60)
	Fighter.link(s, e)
	s.block = 10
	H.hand(s, [6, 4])
	var ev := H.cast(s, e, {"sintese": [0], "antitese": [1]})
	assert_eq(str(ev.filter(func(x): return x.t in ["self_dmg", "cast"])[0].t), "self_dmg", "o dano em si vem antes")
	assert_eq(s.hp, 72, "perde 8 (4 ×2, ignora o bloqueio) e cura 5 depois")
	# Inimigo: 5 da cura efetiva + 8 da Antítese + 5 da marca da Síntese (outro efeito).
	assert_eq(e.hp, 60 - 5 - 8 - 5)
	assert_eq(e.sigil, 0, "a Antítese quebrou a marca")


func test_antitese_nunca_deixa_menos_de_1():
	var p := _pair(10)
	H.hand(p[0], [6])
	var ev := H.cast(p[0], p[1], {"antitese": [0]})
	assert_eq(p[0].hp, 1, "perderia 12: fica com 1")
	assert_eq(p[1].hp, 48, "12 de dano no inimigo")
	assert_eq(int(ev.filter(func(x): return x.t == "self_dmg")[0].n), 9)
	p[0].hp = 1
	H.hand(p[0], [5])
	ev = H.cast(p[0], p[1], {"antitese": [0]})
	assert_false(ev.any(func(x): return x.t == "self_dmg"), "com 1 de vida, nada")
	assert_eq(p[0].hp, 1)


func test_marca_nao_quebra_com_golpe_absorvido_e_quebra_por_cima_do_bloqueio():
	var p := _pair()
	var e: Fighter = p[1]
	e.sigil = 6
	e.block = 4
	var a := H.fighter("a", ["faisca"])
	Fighter.link(a, e)
	H.hand(a, [3])
	H.cast(a, e, {"faisca": [0]})
	assert_eq(e.hp, 60, "absorvido: a vida não baixou")
	assert_eq(e.sigil, 6, "a marca fica")
	H.hand(a, [5])
	H.cast(a, e, {"faisca": [0]})
	assert_eq(e.hp, 60 - 4 - 6, "absorve 1, perde 4 e +6 da marca")
	assert_eq(e.sigil, 0)


func test_marca_nao_quebra_com_esquiva():
	var p := _pair()
	var e: Fighter = p[1]
	e.sigil = 5
	e.dodge = true
	var a := H.fighter("a", ["faisca"])
	H.hand(a, [6])
	H.cast(a, e, {"faisca": [0]})
	assert_eq(e.hp, 60)
	assert_eq(e.sigil, 5)


func test_varios_golpes_so_o_primeiro_quebra():
	var p := _pair()
	var e: Fighter = p[1]
	e.sigil = 4
	var a := H.fighter("a", ["corte"])
	H.hand(a, [5, 5])
	H.cast(a, e, {"corte": [0, 1]})
	assert_eq(e.hp, 60 - 10 - 4 - 10, "Corte Duplo ímpar: 2 golpes de 10, a marca só no primeiro")


func test_o_efeito_que_marcou_nao_quebra_a_propria_marca():
	# Síntese com Cobre: cura, bloqueio (marca) e depois o Cobre cura de novo (vira dano),
	# tudo no mesmo efeito: a marca fica.
	var p := _pair(50)
	var s: Fighter = p[0]
	var e: Fighter = p[1]
	s.bag[0] = Die.with_element("Cu")
	H.hand(s, [4])
	H.cast(s, e, {"sintese": [0]})
	assert_eq(e.sigil, 3)
	assert_eq(e.hp, 60 - 3 - 2, "3 da cura + 2 do Cobre, sem quebrar a marca")
	# Outra magia quebra.
	s.bag[0] = Die.basic()
	H.hand(s, [3])
	H.cast(s, e, {"antitese": [0]})
	assert_eq(e.sigil, 0)
	assert_eq(e.hp, 55 - 6 - 3)
	assert_eq(s.hp, 55 - 6, "a Antítese tira 3 ×2 do Xamã")


func test_veneno_e_queima_quebram_a_marca():
	var p := _pair()
	var e: Fighter = p[1]
	e.sigil = 3
	e.poison = 2
	var ev := []
	Resolver.start_turn(e, ev)
	assert_eq(e.hp, 60 - 2 - 3)
	assert_true(ev.any(func(x): return x.t == "sigil_break" and int(x.n) == 3))
	e.sigil = 2
	e.poison = 0
	e.burn = 1
	Resolver.start_turn(e, [])
	assert_eq(e.hp, 55 - 1 - 2, "queima também quebra")


func test_cura_fora_da_luta_nao_causa_dano():
	var p := _pair(40)
	p[0].heal_full(20) ## Parada de Cura e vitória curam direto, sem o Resolver.
	assert_eq(p[1].hp, 60)


func test_so_o_xama_tem_correspondencia():
	var b := H.fighter("b", ["cerrar", "escudo"], 40)
	var e := H.fighter("alvo", ["faisca"], 60)
	Fighter.link(b, e)
	b.hp = 30
	H.hand(b, [3])
	H.cast(b, e, {"cerrar": [0]})
	assert_eq(e.hp, 60)
	assert_eq(e.sigil, 0)


func test_imune_anula_a_marca():
	var p := _pair()
	p[1].immune = 1
	H.hand(p[0], [6])
	H.cast(p[0], p[1], {"sintese": [0]})
	assert_eq(p[1].sigil, 0)
	assert_eq(p[1].immune, 0)


func test_marca_fica_no_save():
	var p := _pair()
	p[1].sigil = 7
	assert_eq(Fighter.from_dict(p[1].to_dict()).sigil, 7)
	p[1].reset_fight_state()
	assert_eq(p[1].sigil, 0, "some no fim da luta")


func test_duelo_liga_os_lados_e_o_xama_inimigo_marca_o_jogador():
	var run := RunState.new_run(3, "sorcerer")
	run.choose(0)
	var hero := run.hero
	var foe := EnemyFactory.base("shaman")
	var d := Duel.new()
	d.setup(hero, foe, 5)
	assert_eq(hero.foe(), foe)
	assert_eq(foe.foe(), hero)
	foe.hp = 50
	H.hand(foe, [6])
	foe.bag[0] = Die.basic()
	H.cast(foe, hero, {"sintese": [0]})
	assert_eq(hero.sigil, 5, "o Xamã inimigo marca o jogador")
	var back := Duel.from_dict(d.to_dict())
	assert_eq(back.player.foe(), back.enemy, "ligados ao carregar")


func test_ia_do_xama_usa_as_magias():
	var p := _pair(60)
	var s: Fighter = p[0]
	H.hand(s, [5, 2, 3, 4])
	var c := EnemyAI.choose(s, p[1], H.rng())
	var ready := c.ready_items(s).map(func(i): return s.inventory.items[i].id)
	assert_true("sintese" in ready, "usa a Síntese")
	assert_true("antitese" in ready, "usa a Antítese")
	var si := H.item(s, "sintese")
	assert_eq(int(c.values_in(s, si)[0]), 6, "Polariza um dado alto para a Síntese")


func test_previa_da_sintese_mostra_o_dano_efetivo():
	var p := _pair(73)
	var s: Fighter = p[0]
	var t := SpellCard.preview_text(s, H.item(s, "sintese"), [6])
	assert_true("cura 5" in t, t)
	assert_true("2 de dano" in t, "só faltam 2: " + t)
	var a := SpellCard.preview_text(s, H.item(s, "antitese"), [4])
	assert_true("8 de dano" in a and "você −8" in a, a)
