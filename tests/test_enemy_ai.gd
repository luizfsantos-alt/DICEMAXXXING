extends GutTest
## IA reativa, Caótico sem absurdos, Calculista e variedade de inimigos (SPEC 8.2 e 8.3).

const H = preload("res://tests/helpers.gd")


func _player(dice: Array, hp := 60) -> Fighter:
	var p := H.fighter("P", dice, "A1", "", [], 60)
	p.is_player = true
	p.hp = hp
	return p


func test_cauteloso_saudavel_e_sem_ameaca_ataca_com_tudo():
	var f := H.fighter("E", [2, 6, 3, 5, 1, 4], "A1", "D1", [], 60)
	var c := EnemyAI.reactive_cautious(f, _player([1, 2, 3, 1, 2, 3]))
	assert_eq(c.attack, [1, 3, 5])
	assert_eq(c.defense, [])


func test_cauteloso_defende_com_vida_baixa():
	var f := H.fighter("E", [2, 6, 3, 5, 1, 4], "A1", "D1", [], 60)
	f.hp = 20
	var c := EnemyAI.reactive_cautious(f, _player([1, 2, 3, 1, 2, 3]))
	assert_eq(c.defense, [5])


func test_cauteloso_defende_diante_de_ameaca():
	var f := H.fighter("E", [2, 6, 3, 5, 1, 4], "A1", "D1", [], 60)
	var c := EnemyAI.reactive_cautious(f, _player([6, 5, 4, 1, 1, 1]))
	assert_eq(c.defense.size(), 1)


func test_cauteloso_vai_com_tudo_se_e_letal():
	var f := H.fighter("E", [2, 6, 3, 5, 1, 4], "A1", "D1", [], 60)
	f.hp = 10
	var c := EnemyAI.reactive_cautious(f, _player([6, 5, 4, 1, 1, 1], 12))
	assert_eq(c.attack.size(), 3, "6+5+4 derruba 12 de vida")


func test_bruto_guarda_defesa_diante_de_escudo_grande():
	var f := H.fighter("E", [2, 6, 3, 5, 1, 4], "A1", "D1", [], 60)
	var p := _player([1, 2, 3, 1, 2, 3])
	assert_eq(EnemyAI.reactive_brute(f, p).defense, [])
	p.barrier = 8
	assert_eq(EnemyAI.reactive_brute(f, p).defense.size(), 1)


func test_fuga_do_padrao_acontece_as_vezes():
	var rng := H.rng(4)
	var f := H.fighter("E", [2, 6, 3, 5, 1, 4], "A1", "D1", [], 60)
	f.personality = "bruto"
	var p := _player([6, 5, 4, 1, 1, 1]) ## Ameaça: o Cauteloso defenderia, o Bruto não.
	var defended := 0
	for i in 400:
		if not EnemyAI.choose(f, rng, p).defense.is_empty():
			defended += 1
	assert_between(defended, 30, 100, "~15% das vezes o Bruto age como Cauteloso")


func test_caotico_nunca_usa_o_menor_dado():
	var rng := H.rng(2)
	for i in 200:
		var f := H.fighter("E", [3, 4, 1, 5, 6, 2], "A1", "D1")
		var c := EnemyAI.chaotic(f, rng)
		assert_false(2 in (c.attack + c.defense), "o dado 1 (índice 2) fica de fora")
		assert_eq(c.validate(f), "")


func test_calculista_acha_a_jogada_letal():
	var rng := H.rng(5)
	var f := H.fighter("E", [6, 6, 5, 1, 1, 1], "A1", "D1", [], 60)
	f.personality = "calculista"
	var p := _player([1, 1, 1, 1, 1, 1], 17)
	for i in 30:
		var c := EnemyAI.choose(f, rng, p)
		assert_eq(c.validate(f), "")
		assert_eq(c.active_count(), 3)
	# A melhor jogada (6+6+5 = 17) é letal e fica no topo do ranking.
	var best := -INF
	var best_c: TurnChoice = null
	for c in EnemyAI.candidates(f):
		var s := EnemyAI.score(f, p, c)
		if s > best:
			best = s
			best_c = c
	assert_eq(best_c.attack.size(), 3)
	assert_gt(best, 500.0)


func test_calculista_nao_altera_o_duelo_real():
	var rng := H.rng(6)
	var f := H.fighter("E", [6, 4, 5, 2, 3, 1], "A2", "D6", [], 60)
	f.personality = "calculista"
	var p := _player([5, 5, 2, 3, 1, 6])
	Resolver.events = [{"t": "marca"}]
	var before_e := f.to_dict()
	var before_p := p.to_dict()
	EnemyAI.choose(f, rng, p)
	assert_eq(f.to_dict(), before_e)
	assert_eq(p.to_dict(), before_p)
	assert_eq(Resolver.events, [{"t": "marca"}], "eventos do início do turno preservados")


func test_bloco1_tem_variedade_e_calculista_so_depois():
	var rng := H.rng(11)
	var attacks := {}
	var shields := 0
	for i in 200:
		var e := EnemyFactory.create(rng.randi_range(1, 9), rng)
		attacks[e.attack_id] = true
		if e.defense_id == "D1":
			shields += 1
		assert_ne(e.personality, "calculista")
	assert_eq(attacks.size(), EnemyFactory.BLOCK1_ATTACKS.size())
	assert_between(shields, 70, 130)
	var calc := 0
	for i in 300:
		if EnemyFactory.create(rng.randi_range(21, 29), rng).personality == "calculista":
			calc += 1
	assert_between(calc, 70, 130, "~33% no bloco 3")


func test_chefes_continuam_sem_calculista():
	var rng := H.rng(1)
	for fight in [10, 20, 30]:
		assert_ne(EnemyFactory.create(fight, rng).personality, "calculista")
