extends GutTest
## Personagens novos, magias novas, Amianto, Ósmio em toda mão e raridade
## (docs/PERSONAGENS.md, docs/RARIDADE.md).

const H = preload("res://tests/helpers.gd")


func _dmg(ev: Array, side: String) -> int:
	var n := 0
	for e in ev:
		if e.t == "hit" and e.side == side:
			n += int(e.dmg)
	return n


# ------------------------------------------------------------------ Kits
func test_ferro_sempre_tira_3():
	var d := Die.with_element("Fe")
	for i in 6:
		assert_eq(d.value(i), 3)
	assert_eq(EnemyFactory.base("barbarian").bag.filter(func(x): return x.element == "Fe").size(), 2)
	assert_false("Fe" in Elements.SHOP)
	assert_eq(Texts.element_name("Fe"), "Ferro")


func test_kits_de_todos_os_arquetipos():
	for id in Characters.ALL:
		var f := EnemyFactory.base(id)
		var c := Characters.get_def(id)
		assert_eq(f.max_hp, int(c.hp), "%s: vida" % id)
		assert_eq(f.hand_size, int(c.hand), "%s: mão" % id)
		assert_eq(f.bag.size(), int(c.bag_size), "%s: bolsa" % id)
		assert_eq(f.inventory.items.size(), c.spells.size(), "%s: magias" % id)
		var occ := {}
		for it in f.inventory.items:
			for cell in f.inventory.cells_of(it):
				assert_true(f.inventory.is_cell(cell), "%s: %s dentro do inventário" % [id, it.id])
				assert_false(occ.has(cell), "%s: peças não se sobrepõem" % id)
				occ[cell] = true
		var els := f.bag.filter(func(d): return d.element != "")
		assert_true(els.size() >= 1, "%s começa com pelo menos 1 elemento" % id)


func test_jogaveis_sao_os_tres_menos_complexos():
	assert_eq(Characters.PLAYABLE, ["assassin", "vampire", "barbarian"])
	for id in Characters.PLAYABLE:
		var run := RunState.new_run(7, id)
		assert_eq(run.character, id)
		assert_eq(run.phase, "doors", "%s vai direto para as portas" % id)
		assert_eq(run.hero.max_hp, Characters.max_hp(id))
		assert_true(run.hero.is_player)


func test_moldura_tem_buraco_no_meio():
	var f := EnemyFactory.base("perfectionist")
	assert_false(f.inventory.is_cell(Vector2i(1, 1)))
	assert_false(f.inventory.fits("bola"), "2×2 não cabe na Moldura")
	assert_true(f.inventory.fits("escudo"))
	var copy := Inventory.from_dict(f.inventory.to_dict())
	assert_eq(copy.blocked, f.inventory.blocked, "buracos sobrevivem ao salvar")


# ------------------------------------------------------------------ Magias novas
func test_dardo_arcano_pede_par():
	assert_true(Spells.accepts_partial("dardo", [], 4))
	assert_false(Spells.accepts_partial("dardo", [], 5))
	var a := H.fighter("A", ["dardo"])
	var b := H.fighter("B", [], 50)
	H.hand(a, [4])
	assert_eq(_dmg(H.cast(a, b, {"dardo": [0]}), "enemy"), 6)


func test_obra_prima_trio():
	assert_true(Spells.complete("obra", [5, 5, 5]))
	assert_false(Spells.complete("obra", [5, 5, 4]))
	var a := H.fighter("A", ["obra"])
	var b := H.fighter("B", [], 80)
	H.hand(a, [6, 2, 6, 6, 1])
	assert_eq(EnemyAI.best_dice(a, "obra", []), [0, 2, 3], "IA acha o trio")
	assert_eq(_dmg(H.cast(a, b, {"obra": [0, 2, 3]}), "enemy"), 36)


func test_mordida_e_banquete_curam():
	var a := H.fighter("A", ["mordida", "banquete"], 40, true)
	a.hp = 20
	var b := H.fighter("B", [], 80)
	H.hand(a, [5, 4, 2, 3])
	var ev := H.cast(a, b, {"mordida": [0], "banquete": [1, 2, 3]})
	assert_eq(_dmg(ev, "enemy"), 5 + 9)
	assert_eq(a.hp, 20 + 3 + 2, "Mordida cura metade (3), Banquete cura o menor (2)")


func test_machadada_e_cerrar_os_dentes():
	var a := H.fighter("A", ["machadada", "cerrar"], 40, true)
	a.hp = 10
	var b := H.fighter("B", [], 80)
	H.hand(a, [5, 3])
	H.cast(a, b, {"machadada": [0], "cerrar": [1]})
	assert_eq(b.hp, 70)
	assert_eq(a.hp, 19)
	assert_eq(Spells.max_uses("cerrar"), 2)


# ------------------------------------------------------------------ Passivas
func test_furia_so_com_metade_da_vida():
	var f := EnemyFactory.base("barbarian")
	f.hp = 60
	assert_eq(Characters.fury(f), 0, "acima da metade, sem Fúria")
	f.hp = 46
	assert_eq(Characters.fury(f), 0, "46 de 90: ainda acima da metade")
	f.hp = 45
	assert_eq(Characters.fury(f), 4, "acende em 45 de 90 com +4")
	f.hp = 20
	assert_eq(Characters.fury(f), 7)
	var b := H.fighter("B", [], 80)
	f.reset_fight_state()
	H.hand(f, [5])
	assert_eq(_dmg(H.cast(f, b, {"machadada": [0]}), "enemy"), 10 + 7, "Machadada + Fúria")


func test_sede_do_vampiro():
	var v := EnemyFactory.base("vampire")
	v.reset_fight_state()
	var base := Characters.max_hp("vampire")
	assert_eq(v.hp, base)
	v.hp = 50
	var r := v.heal_full(4)
	assert_eq(int(r.hp), 4, "cura normal mesmo machucado")
	assert_eq(int(r.max), 1, "toda cura dá +1 de vida máxima")
	assert_eq(v.max_hp, base + 1)
	assert_eq(v.hp, 55)
	v.heal_full(0)
	assert_eq(v.max_hp, base + 1, "cura zero não conta")
	for i in 20:
		v.heal_full(2)
	assert_eq(v.max_hp, base + Characters.THIRST_CAP, "até o limite por luta")
	v.reset_fight_state()
	v.heal_full(3)
	assert_eq(v.max_hp, base + 1 + Characters.THIRST_CAP, "a luta seguinte libera de novo")


func test_vampiro_queima_em_dobro():
	var v := EnemyFactory.base("vampire")
	v.reset_fight_state()
	v.burn = 3
	var ev := []
	Resolver.start_turn(v, ev)
	assert_eq(v.hp, v.max_hp - 6, "queima 3 causa 6")


func test_peso_morto_puxa_dados():
	var m := EnemyFactory.base("metallurgist")
	m.bag = []
	for _i in 4:
		var d := Die.with_element("Pb")
		d.faces = [1, 1, 1, 1, 1, 1]
		m.bag.append(d)
	m.hand_size = 2
	m.reset_fight_state()
	var ev := []
	Resolver.draw_and_roll(m, H.fighter("B", []), H.rng(3), ev)
	assert_eq(m.hand.size(), 4, "cada 1 de Chumbo puxa mais um, até a bolsa acabar")
	assert_true(ev.any(func(e): return e.t == "dead_weight" and int(e.n) == 2))


func test_copista_copia_magia_que_cabe():
	var c := EnemyFactory.base("copyist")
	var foe := EnemyFactory.base("sorcerer")
	var du := Duel.new()
	du.setup(c, foe, 5)
	var temps := c.inventory.items.filter(func(it): return it.get("temp", false))
	assert_eq(temps.size(), 1, "uma cópia")
	assert_true(str(temps[0].id) in ["faisca", "bola"])
	c.end_fight_cleanup()
	assert_eq(c.inventory.items.size(), 2, "a cópia some no fim da luta")


func test_copista_sem_espaco_nao_copia():
	var c := EnemyFactory.base("copyist")
	c.inventory.add("foto") ## Reta 4: ocupa a linha livre.
	c.inventory.add("estocada")
	var foe := EnemyFactory.base("sorcerer")
	foe.inventory.items = [{"id": "bola", "level": 1, "x": 0, "y": 0, "rot": 0}]
	var ev := []
	Resolver.inspire(c, foe, H.rng(), ev)
	assert_eq(c.inventory.items.filter(func(it): return it.get("temp", false)).size(), 0)
	assert_eq(str(ev[0].spell), "")


func test_perfeccionista_guarda_dois_dados():
	var p := EnemyFactory.base("perfectionist")
	p.reset_fight_state()
	p.draw_hand(H.rng())
	for k in p.hand.size():
		p.hand[k].value = [6, 6, 2, 3, 1][k]
	var ev := []
	Resolver.end_turn(p, [], ev, [0, 1, 2])
	assert_eq(p.keeps.size(), 2, "no máximo 2")
	p.draw_hand(H.rng(2))
	var fixed := p.hand.filter(func(e): return e.get("fixed", false))
	assert_eq(fixed.size(), 2)
	assert_eq(fixed.map(func(e): return int(e.value)), [6, 6])
	assert_eq(p.hand.size(), p.hand_size + 2, "entram além da mão normal")


func test_ia_do_perfeccionista_guarda_repetidos():
	var p := EnemyFactory.base("perfectionist")
	p.reset_fight_state()
	H.hand(p, [2, 5, 5, 3, 1])
	assert_eq(EnemyAI.keep_pick(p, []), [1, 2])


func test_fundidor_troca_e_devolve():
	var e := EnemyFactory.base("metallurgist")
	e.variant = "fundidor"
	var p := EnemyFactory.base("vampire")
	p.reset_fight_state()
	var ev := []
	Resolver.on_turn_effects(e, p, ev)
	assert_eq(p.bag.filter(func(d): return d.element == "Pb").size(), 1)
	p.end_fight_cleanup()
	assert_eq(p.bag.filter(func(d): return d.element == "Pb").size(), 0, "volta ao normal depois da luta")


# ------------------------------------------------------------------ Elementos
func test_amianto():
	var d := Die.with_element("Am")
	assert_eq(d.faces, [4, 5, 6, 7, 8, 9])
	var a := H.fighter("A", ["faisca"], 40, true)
	a.bag[0] = d
	var b := H.fighter("B", [], 50)
	H.hand(a, [9])
	var ev := H.cast(a, b, {"faisca": [0]})
	assert_eq(b.hp, 41)
	assert_eq(a.hp, 37, "machuca quem usa")
	assert_true(ev.any(func(e): return e.t == "asbestos"))


func test_amianto_ignora_bloqueio_e_espelho():
	var a := H.fighter("A", ["faisca"], 40, true)
	a.bag[0] = Die.with_element("Am")
	a.block = 20
	a.mirror = true
	H.hand(a, [5])
	H.cast(a, H.fighter("B", [], 50), {"faisca": [0]})
	assert_eq(a.hp, 37)
	assert_eq(a.block, 20)


func test_osmio_sai_em_toda_mao():
	var f := H.fighter("A", [])
	f.bag[5] = Die.with_element("Os")
	f.hand_size = 2
	f.reset_fight_state()
	var r := H.rng(9)
	for _t in 6:
		f.draw_hand(r)
		assert_true(f.hand.any(func(e): return int(e.bag) == 5), "Ósmio na mão")
		f.discard_hand()
		f.turns_taken += 1


func test_osmio_resiste_a_mao_menor():
	var f := H.fighter("A", [])
	f.bag[3] = Die.with_element("Os")
	f.reset_fight_state()
	f.draw_hand(H.rng(), 4)
	assert_eq(f.hand.size(), 2)
	assert_true(f.hand.any(func(e): return int(e.bag) == 3), "outros dados saem primeiro")


func test_aviso_de_elemento():
	var f := H.fighter("A", [])
	f.bag.resize(Elements.SOLITARY_BAG)
	f.bag[0] = Die.with_element("H")
	f.hand_size = 8
	f.reset_fight_state()
	var ev := []
	Resolver.draw_and_roll(f, H.fighter("B", []), H.rng(), ev)
	assert_true(ev.any(func(e): return e.t == "element" and e.el == "H"))


func test_aviso_do_carbono_em_cadeia():
	var f := H.fighter("A", [])
	f.bag[0] = Die.with_element("C")
	f.bag[1] = Die.with_element("C")
	f.hand_size = 8
	f.reset_fight_state()
	var ev := []
	Resolver.draw_and_roll(f, H.fighter("B", []), H.rng(), ev)
	assert_true(ev.any(func(e): return e.t == "element" and e.el == "C"))


# ------------------------------------------------------------------ Raridade
func test_todas_as_magias_tem_raridade():
	for id in Spells.DATA:
		assert_true(Spells.rarity(id) in Config.RARITIES, id)
	assert_eq(Spells.ids_of_rarity("common").size(), 16)
	assert_eq(Spells.ids_of_rarity("uncommon").size(), 20)
	assert_eq(Spells.ids_of_rarity("rare").size(), 9)
	assert_eq(Elements.rarity("Os"), "rare")
	assert_eq(Elements.rarity("Am"), "common")


func test_tabela_por_andar():
	var r := H.rng(4)
	var count := {"common": 0, "uncommon": 0, "rare": 0}
	for _k in 3000:
		count[Shop.roll_rarity(r, Shop.band(1))] += 1
	assert_almost_eq(count.common / 3000.0, 0.70, 0.04)
	assert_almost_eq(count.rare / 3000.0, 0.05, 0.02)
	assert_eq(Shop.band(3), 0)
	assert_eq(Shop.band(4), 1)
	assert_eq(Shop.band(10), 2)


func test_precos_pela_raridade():
	var h := EnemyFactory.base("vampire")
	var opts := Shop.shop(h, H.rng(2), 0, 1)
	for o in opts:
		if o.kind == "spell":
			assert_eq(int(o.price), Config.PRICE_SPELL_BY_RARITY[Spells.rarity(o.id)])
		elif o.kind == "die":
			assert_ne(str(o.id), "", "dado oferecido sempre tem elemento")
			assert_eq(int(o.price), Config.PRICE_DIE_BY_RARITY[Elements.rarity(o.id)])
	assert_eq(Spells.sell_price("bis", 1), 9)
	assert_eq(Spells.sell_price("faisca", 2), 8)


func test_escola_cobra_evoluir_rara():
	var h := EnemyFactory.base("copyist") ## Imitação Barata é Rara.
	for s in 20:
		var opts := Shop.school(h, H.rng(s), 1)
		assert_ne(Spells.rarity(opts[1].id), "common", "2ª magia no mínimo Incomum")
		for o in opts:
			if o.kind == "evolve":
				assert_eq(int(o.price), Config.PRICE_EVOLVE_RARE if o.id == "imitacao" else 0)


func test_porta_insana_garante_rara():
	for s in 30:
		var opts := Shop.reward(EnemyFactory.base("barbarian"), H.rng(s), 1, "insana")
		assert_true(opts.any(func(o): return o.kind == "spell" and Spells.rarity(o.id) == "rare"))


func test_inimigo_sem_rara_antes_do_andar_4():
	var r := H.rng(11)
	for _k in 200:
		var f := EnemyFactory.base("sorcerer")
		for _u in 6:
			EnemyFactory.upgrade(f, r, 3)
		for it in f.inventory.items.slice(2):
			assert_ne(Spells.rarity(it.id), "rare", it.id)
		for d in f.bag:
			assert_ne(Elements.rarity(d.element), "rare") if d.element != "" else null


func test_ofertas_dos_passivos():
	var mini := EnemyFactory.base("minimalist")
	var rw := Shop.reward(mini, H.rng(), 1, "normal")
	assert_eq(rw[rw.size() - 1].kind, "destroy")
	assert_eq(int(rw[rw.size() - 1].price), 0)
	var well := Shop.well(H.rng(), 1, mini)
	assert_eq(int(well[well.size() - 1].price), 0, "destruir no Poço é grátis")
	var met := EnemyFactory.base("metallurgist")
	assert_true(Shop.shop(met, H.rng(), 0, 1).any(func(o): return o.kind == "die" and o.id == "Pb"))
	assert_true(Shop.well(H.rng(), 1, met).any(func(o): return o.kind == "element" and o.id == "Pb"))


func test_recompensa_do_mestre():
	var run := RunState.new_run(5, "barbarian")
	run.phase = "master_reward"
	run.options = Shop.master_reward()
	var w := run.hero.inventory.width
	assert_eq(run.choose(0), "")
	assert_eq(run.hero.inventory.width, w + 1, "+1 coluna")
	run.phase = "master_reward"
	run.options = Shop.master_reward()
	var hs := run.hero.hand_size
	run.choose(1)
	assert_eq(run.hero.hand_size, hs + 1)
	run.phase = "master_reward"
	run.options = Shop.master_reward()
	run.choose(2)
	assert_eq(run.phase, "master_rare")
	assert_eq(run.options.size(), 3)
	for o in run.options:
		assert_eq(Spells.rarity(o.id), "rare")


func test_inimigos_de_todos_os_arquetipos():
	var r := H.rng(21)
	var seen := {}
	for _k in 400:
		var f := EnemyFactory.create(6, "normal", r)
		seen[f.archetype] = true
		if f.variant == "monge":
			assert_eq(f.bag.size(), 4)
			assert_true(f.bag.all(func(d): return d.element == "H"))
	for id in Characters.ALL:
		assert_true(seen.has(id), "%s aparece como inimigo" % id)


func test_salvar_carregar_estado_novo():
	var p := EnemyFactory.base("perfectionist")
	p.keeps = [{"bag": 1, "temp": {}, "value": 6}]
	p.thirst_used = 3
	p.inventory.items.append({"id": "faisca", "level": 1, "x": 3, "y": 2, "rot": 0, "temp": true})
	var q := Fighter.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())))
	assert_eq(int(q.keeps[0].value), 6)
	assert_eq(q.thirst_used, 3)
	assert_true(q.inventory.items[2].get("temp", false))
	assert_eq(q.inventory.blocked.size(), 2)


func test_jornada_inteira_de_cada_jogavel():
	for id in Characters.PLAYABLE:
		for s in 3:
			var run := RunState.new_run(100 + s, id)
			var guard := 0
			while not (run.phase in ["victory", "defeat"]) and guard < 2000:
				guard += 1
				match run.phase:
					"duel":
						var br := H.rng(s)
						while run.duel.state == "choosing":
							run.duel.submit(EnemyAI.choose(run.duel.player, run.duel.enemy, br))
						run.finish_duel()
					"doors", "rest":
						run.choose(0)
					_:
						if run.choose(0, {"die": 0, "face": 5}) != "" or run.phase in ["shop", "well", "school"]:
							run.leave()
			assert_true(run.phase in ["victory", "defeat"], "%s termina a jornada" % id)
