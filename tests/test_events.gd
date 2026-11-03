extends GutTest
## Eventos estruturados do resolver: batem com os números do turno e com o log.

const H = preload("res://tests/helpers.gd")


func _of(events: Array, type: String, who := "") -> Array:
	return events.filter(func(e): return e.t == type and (who == "" or e.who == who))


func _sum(events: Array) -> int:
	var t := 0
	for e in events:
		t += int(e.n)
	return t


func test_espelho_gera_evento_com_o_refletido():
	var a := H.fighter("A", [6, 6, 2, 1, 1, 1], "A2", "", [], 60)
	var b := H.fighter("B", [1, 3, 3, 3, 3, 3], "A1", "D11", [], 60)
	var r := H.play(a, b, TurnChoice.make([0, 1, 2]), TurnChoice.make([], [0]))
	var m := _of(r.events, "mirror", "A")
	assert_eq(m.size(), 1)
	assert_eq(m[0].n, 9)
	assert_eq(m[0].src, "D11")
	assert_eq(_sum(_of(r.events, "damage", "A")), r.dmg_to_a)
	assert_eq(_sum(_of(r.events, "damage", "B")), r.dmg_to_b)


func test_corrente_gera_evento_com_os_dados_trocados():
	var a := H.fighter("A", [6, 1, 1, 1, 1, 1], "A1", "D12", [], 60)
	var b := H.fighter("B", [5, 4, 3, 2, 1, 1], "A1", "", [], 60)
	var r := H.play(a, b, TurnChoice.make([], [0]), TurnChoice.make([0, 1, 2]))
	var c := _of(r.events, "chain", "B")
	assert_eq(c.size(), 1)
	assert_eq(c[0].active, 0, "o 5 (maior ativo) sai")
	assert_true(c[0].self in [4, 5], "um 1 do autodano entra")


func test_chapeu_anula_corrente_e_avisa():
	var a := H.fighter("A", [6, 1, 1, 1, 1, 1], "A1", "D12", [], 60)
	var b := H.fighter("B", [5, 4, 3, 2, 1, 1], "A1", "", ["DF8"], 60)
	var r := H.play(a, b, TurnChoice.make([], [0]), TurnChoice.make([0, 1, 2]))
	assert_eq(_of(r.events, "chain").size(), 0)
	assert_eq(_of(r.events, "chapeu", "B").size(), 1)


func test_autodano_e_procs_de_itens():
	var a := H.fighter("A", [6, 5, 4, 3, 3, 2], "A1", "", ["DD7"], 60)
	var b := H.fighter("B", [1, 1, 1, 1, 1, 1], "A1", "", [], 60)
	var r := H.play(a, b, TurnChoice.make([0, 1, 2]), H.idle())
	var s := _of(r.events, "self", "A")
	assert_eq(s.size(), 1)
	assert_eq(s[0].n, r.self_a)
	assert_eq(r.self_a, 2, "3-3 se anulam pelo Ímã")
	assert_eq(_of(r.events, "annul", "A").size(), 2)
	var procs := _of(r.events, "proc", "A").map(func(e): return e.src)
	assert_true("DD7" in procs, "o Ímã pisca")


func test_whey_e_bone_piscam_ao_gerar_escudo():
	var a := H.fighter("A", [6, 5, 4, 3, 2, 1], "A1", "D1", ["DD10", "DF9"], 60)
	var b := H.fighter("B", [1, 1, 1, 1, 1, 1], "A1", "", [], 60)
	var r := H.play(a, b, TurnChoice.make([0, 1], [2]), H.idle())
	var sh := _of(r.events, "shield", "A")
	assert_eq(sh.size(), 1)
	assert_eq(sh[0].n, 11, "(2x4 + 1) x 1,2 = 10,8 -> 11")
	var procs := _of(r.events, "proc", "A").map(func(e): return e.src)
	assert_true("DD10" in procs)
	assert_true("DF9" in procs)


func test_inicio_de_turno_gera_eventos():
	var p := H.fighter("P", [1, 1, 1, 1, 1, 1], "A1", "", ["DF5", "DD1"], 60)
	p.is_player = true
	p.hp = 50
	var e := H.fighter("E", [1, 1, 1, 1, 1, 1], "A1", "", [], 60)
	var du := Duel.new()
	du.setup(p, e, 3)
	# setup restaura a vida; força dano para a cura do Bandeide aparecer.
	p.hp = 40
	du.begin_turn()
	var heals := _of(du.turn_events, "heal", "P")
	assert_eq(heals.size(), 1)
	assert_eq(heals[0].side, "player")
	assert_eq(_of(du.turn_events, "dice_change", "P").size(), 1, "Dado Viciado")


## Invariante: a vida após o turno é a anterior mais curas, menos dano e autodano.
func test_eventos_explicam_a_vida_em_duelos_aleatorios():
	var rng := H.rng(99)
	var checked := 0
	for n in 60:
		var fight := rng.randi_range(11, 30)
		var p := EnemyFactory.create(fight, rng)
		p.is_player = true
		p.name = "Você"
		var pool := Items.PASSIVES.duplicate()
		for k in 3:
			p.passives.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
		p.death_defy = rng.randf() < 0.3
		var e := EnemyFactory.create(fight, rng)
		var du := Duel.new()
		du.setup(p, e, rng.randi())
		while du.state == "choosing":
			var before := {"Você": p.hp, e.name: e.hp}
			var rep := du.submit(EnemyAI.choose(p, rng))
			for f in [p, e]:
				var evs: Array = rep.events.filter(func(x): return x.who == f.name)
				if not _of(evs, "death_defy").is_empty():
					continue
				var expected: int = before[f.name] + _sum(_of(evs, "heal")) \
					- _sum(_of(evs, "damage")) - _sum(_of(evs, "self"))
				assert_eq(f.hp, expected, "vida de %s no turno %d" % [f.name, du.turn])
				checked += 1
			assert_eq(_sum(_of(rep.events, "damage", "Você")), rep.dmg_to_a)
			assert_eq(_sum(_of(rep.events, "self", "Você")), rep.self_a)
			for x in rep.events:
				assert_true(x.has("t") and x.has("side") and x.has("who"))
			if du.state == "choosing":
				du.begin_turn()
	assert_gt(checked, 100)
