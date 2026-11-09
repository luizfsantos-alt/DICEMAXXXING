extends GutTest
## Mexidas (docs/SPEC_v3.1.md §1) e a regra das cópias (§6).

const H := preload("res://tests/helpers.gd")


func _f(spells: Array, values: Array) -> Fighter:
	var f := H.fighter("a", spells, 40, true)
	H.hand(f, values)
	return f


func _vals(f: Fighter) -> Array:
	return f.hand_values()


func _place(f: Fighter, c: TurnChoice, id: String, dice: Array, slot := 0) -> bool:
	for h in dice:
		if not c.place(f, H.item(f, id), h, slot):
			return false
	return true


# ------------------------------------------------------------ Valores (critério 1)
func test_sangria_divide_em_tres():
	var f := _f(["sangria"], [7, 2])
	var c := TurnChoice.new()
	assert_true(_place(f, c, "sangria", [0]))
	assert_eq(_vals(f), [7, 2, 3, 2, 2], "as partes entram no fim da mão")
	assert_true(0 in c.used_dice(), "o original foi gasto")
	assert_false(c.accepts(f, H.item(f, "sangria"), 2), "a mexida já foi usada neste turno")
	var g := _f(["sangria"], [12])
	var c2 := TurnChoice.new()
	_place(g, c2, "sangria", [0])
	assert_eq(_vals(g).slice(1), [4, 4, 4])
	var k := _f(["sangria"], [2])
	assert_false(TurnChoice.new().place(k, 0, 0), "pede dado ≥ 3")


func test_nivelar_eco_juntar_escada():
	var f := _f(["nivelar"], [2, 6])
	_place(f, TurnChoice.new(), "nivelar", [0, 1])
	assert_eq(_vals(f), [4, 4])
	f = _f(["eco"], [5, 2])
	_place(f, TurnChoice.new(), "eco", [0, 1])
	assert_eq(_vals(f), [5, 5], "o 2º copia o 1º")
	f = _f(["juntar"], [12, 12, 3])
	var c := TurnChoice.new()
	_place(f, c, "juntar", [0, 1])
	assert_eq(int(f.hand[0].value), 24)
	assert_true(1 in c.used_dice(), "o segundo é gasto")
	f = _f(["escada"], [2, 6, 6])
	_place(f, TurnChoice.new(), "escada", [0, 1, 2])
	assert_eq(_vals(f), [2, 3, 4])


func test_virar_pico_inflar_polarizar():
	var f := _f(["virar"], [1])
	f.bag[0] = Elements.lead()
	_place(f, TurnChoice.new(), "virar", [0])
	assert_eq(_vals(f), [6], "Chumbo 1 vira 6")
	f = _f(["pico"], [2])
	f.bag[0].add_sticker(5)
	_place(f, TurnChoice.new(), "pico", [0])
	assert_eq(_vals(f), [12], "face máxima com adesivo")
	assert_true(bool(f.hand[0].top))
	f = _f(["inflar"], [3])
	_place(f, TurnChoice.new(), "inflar", [0])
	assert_eq(_vals(f), [6])
	f = _f(["polarizar"], [3])
	_place(f, TurnChoice.new(), "polarizar", [0])
	assert_eq(_vals(f), [1])
	f = _f(["polarizar"], [4])
	_place(f, TurnChoice.new(), "polarizar", [0])
	assert_eq(_vals(f), [6])


func test_ajuste_fino_dois_buracos():
	var f := _f(["ajuste"], [3, 1])
	var c := TurnChoice.new()
	assert_false(c.accepts(f, 0, 1, 1), "−1 recusa um 1")
	assert_true(c.place(f, 0, 0, 1))
	assert_eq(int(f.hand[0].value), 2)
	f = _f(["ajuste"], [3])
	TurnChoice.new().place(f, 0, 0, 0)
	assert_eq(int(f.hand[0].value), 4)


func test_nivel_soma_nos_dados_devolvidos():
	var f := _f(["virar"], [2])
	f.inventory.items[0].level = 3
	_place(f, TurnChoice.new(), "virar", [0])
	assert_eq(_vals(f), [7], "7 − 2 + 2")


func test_aleatorias_rolam_e_nao_desfazem():
	var f := _f(["segunda", "faisca"], [1])
	var c := TurnChoice.new()
	c.rng = H.rng(3)
	assert_true(_place(f, c, "segunda", [0]))
	var v := int(f.hand[0].value)
	assert_true(v >= 1, "fica com o maior")
	assert_false(c.undo_mod(f, H.item(f, "segunda")), "aleatória é definitiva")
	assert_eq(int(f.hand[0].value), v)
	assert_true(c.place(f, H.item(f, "faisca"), 0), "o dado mexido alimenta outra magia")
	# Tudo ou Nada: valor novo ×2, pode piorar.
	var seen_worse := false
	for s in 40:
		var g := _f(["tudo_nada"], [5])
		var cg := TurnChoice.new()
		cg.rng = H.rng(s)
		_place(g, cg, "tudo_nada", [0])
		var nv := int(g.hand[0].value)
		assert_true(nv % 2 == 0 and nv >= 2 and nv <= 12)
		if nv < 5:
			seen_worse = true
	assert_true(seen_worse, "o Tudo ou Nada às vezes piora")


func test_marcado_nao_aceita_aleatoria():
	var f := _f(["segunda", "virar"], [3])
	f.hand[0]["fixed"] = true
	var c := TurnChoice.new()
	assert_false(c.accepts(f, H.item(f, "segunda"), 0))
	assert_true(c.accepts(f, H.item(f, "virar"), 0), "determinística aceita")


# ------------------------------------------------------------ Uma mexida por dado (critério 2)
func test_um_dado_uma_mexida():
	var f := _f(["virar", "inflar"], [2])
	var c := TurnChoice.new()
	_place(f, c, "virar", [0])
	assert_eq(_vals(f), [5])
	assert_false(c.accepts(f, H.item(f, "inflar"), 0), "já mexido")


func test_copias_nao_alimentam_imitacao_sacrificio_transfusao():
	var f := _f(["imitacao", "transfusao", "sacrificio", "faisca"], [1, 4])
	f.inventory.add("imitacao")
	var c := TurnChoice.new()
	var im := f.inventory.ids().find("imitacao")
	assert_true(c.place(f, im, 0))
	var copy := f.hand.size() - 1
	assert_false(c.accepts(f, H.item(f, "sacrificio"), copy), "Sacrifício não aceita cópia")
	assert_false(c.accepts(f, H.item(f, "transfusao"), copy), "Transfusão não aceita cópia")
	var im2 := f.inventory.ids().rfind("imitacao")
	assert_ne(im2, im)
	assert_false(c.accepts(f, im2, copy), "Imitação não aceita cópia")
	assert_true(c.accepts(f, H.item(f, "faisca"), copy), "as outras aceitam")
	var sg := _f(["sangria", "sacrificio"], [3])
	var cs := TurnChoice.new()
	_place(sg, cs, "sangria", [0])
	assert_false(cs.accepts(sg, H.item(sg, "sacrificio"), 1), "parte da Sangria é devolvida")


# ------------------------------------------------------------ Corrente da crítica (critério 3)
func test_corrente_de_imitacoes_acabou():
	var f := H.fighter("a", [], 40, true)
	f.inventory.items = [
		{"id": "imitacao", "level": 3, "x": 0, "y": 0, "rot": 0},
		{"id": "imitacao", "level": 3, "x": 0, "y": 1, "rot": 0},
		{"id": "faisca", "level": 1, "x": 0, "y": 2, "rot": 0},
	]
	H.hand(f, [6, 1, 1, 1])
	var c := TurnChoice.new()
	assert_true(c.place(f, 0, 0))
	assert_eq(_vals(f).slice(4), [12, 12])
	assert_false(c.place(f, 1, 4), "a cópia não vai para outra Imitação")


# ------------------------------------------------------------ Desfazer (critério 4)
func test_desfazer_determinista_e_o_que_dependia():
	var f := _f(["sangria", "faisca"], [7])
	var c := TurnChoice.new()
	var sg := H.item(f, "sangria")
	_place(f, c, "sangria", [0])
	assert_true(c.place(f, H.item(f, "faisca"), 1), "parte na Faísca")
	assert_true(c.undo_mod(f, sg))
	assert_eq(_vals(f), [7], "partes recolhidas")
	assert_false(c.casts.has(H.item(f, "faisca")), "a Faísca perdeu a parte")
	assert_true(c.accepts(f, sg, 0), "a Sangria volta a aceitar")
	assert_false(f.hand[0].has("mod"))


func test_desfazer_imitacao_desfaz_mexida_nos_dados_depois():
	var f := _f(["virar", "faisca"], [2, 5])
	var c := TurnChoice.new()
	_place(f, c, "virar", [0])
	assert_true(c.undo_mod(f, H.item(f, "virar")))
	assert_eq(_vals(f), [2, 5])


# ------------------------------------------------------------ Uso e elementos (critério 5)
func test_mexida_nao_e_uso_uranio_parado_envenena():
	var a := _f(["virar"], [3])
	var b := H.fighter("b", [])
	Elements.apply(a.bag[0], "U")
	var c := TurnChoice.new()
	_place(a, c, "virar", [0])
	var ev := []
	var used := Resolver.cast_all(a, b, c, ev)
	Resolver.end_turn(a, used, ev)
	assert_eq(a.poison, Config.URANIUM_POISON, "o Urânio mexido e parado envenena")
	assert_eq(ev.filter(func(e): return e.t == "mod").size(), 1, "evento da mexida")


func test_sodio_so_queima_ao_ser_gasto():
	var a := _f(["virar", "faisca"], [2])
	var b := H.fighter("b", [])
	Elements.apply(a.bag[0], "Na")
	var c := TurnChoice.new()
	_place(a, c, "virar", [0])
	var ev := []
	Resolver.cast_all(a, b, c, ev)
	assert_eq(b.burn, 0, "mexida não queima")
	var a2 := _f(["virar", "faisca"], [2])
	Elements.apply(a2.bag[0], "Na")
	var c2 := TurnChoice.new()
	_place(a2, c2, "virar", [0])
	c2.place(a2, H.item(a2, "faisca"), 0)
	var b2 := H.fighter("b", [])
	Resolver.cast_all(a2, b2, c2, [])
	assert_eq(b2.burn, Config.SODIUM_BURN, "gasto na Faísca, queima")
	assert_eq(b2.hp, 40 - 5, "Faísca com o dado virado (2 → 5)")


func test_pico_uma_vez_por_luta():
	var a := _f(["pico"], [2])
	var b := H.fighter("b", [])
	var c := TurnChoice.new()
	_place(a, c, "pico", [0])
	Resolver.cast_all(a, b, c, [])
	assert_false(TurnChoice.can_cast(a, H.item(a, "pico")), "1× por luta")


# ------------------------------------------------------------ Lapidar (critério 6)
func test_lapidar_edita_a_face_para_sempre():
	var a := _f(["lapidar"], [1])
	var b := H.fighter("b", [])
	a.hand[0].face = 0
	var c := TurnChoice.new()
	assert_true(_place(a, c, "lapidar", [0]))
	assert_eq(int(a.hand[0].value), 6)
	assert_eq(a.bag[0].value(0), 1, "só edita ao terminar o turno")
	Resolver.cast_all(a, b, c, [])
	assert_eq(a.bag[0].value(0), 6, "para sempre")
	var p := _f(["lapidar"], [1])
	p.bag[0] = Elements.lead()
	p.hand[0].face = 0
	assert_false(TurnChoice.new().accepts(p, 0, 0), "face travada do Chumbo")
	var t := _f(["lapidar"], [1])
	t.hand[0].bag = -1
	t.hand[0].temp = Die.basic()
	assert_false(TurnChoice.new().accepts(t, 0, 0), "dado temporário")


# ------------------------------------------------------------ Save e IA
func test_save_no_meio_do_turno_mantem_mexidas():
	var f := _f(["segunda", "virar"], [2, 3])
	var c := TurnChoice.new()
	c.rng = H.rng(7)
	_place(f, c, "segunda", [0])
	_place(f, c, "virar", [1])
	var back := Fighter.from_dict(f.to_dict())
	var c2 := TurnChoice.from_hand(back)
	assert_true(c2.mods.has(H.item(back, "segunda")))
	assert_true(c2.mods.has(H.item(back, "virar")))
	assert_true(bool(c2.mods[H.item(back, "segunda")].random))
	assert_eq(back.hand_values(), f.hand_values())
	assert_true(c2.undo_mod(back, H.item(back, "virar")))
	assert_eq(int(back.hand[1].value), 3)


func test_ia_usa_segunda_chance_para_fazer_o_par():
	var f := H.fighter("ia", ["bola", "segunda"], 40)
	f.personality = "cauteloso"
	H.hand(f, [5, 1, 3])
	var foe := H.fighter("b", [])
	var c := EnemyAI.choose(f, foe, H.rng(2))
	assert_true(c.mods.has(H.item(f, "segunda")), "usa a mexida")


func test_ia_vira_o_chumbo_para_a_estocada():
	var f := H.fighter("ia", ["estocada", "virar"], 40)
	f.personality = "cauteloso"
	H.hand(f, [1, 2])
	f.bag[0] = Elements.lead()
	var c := EnemyAI.choose(f, H.fighter("b", []), H.rng(1))
	assert_true(c.mods.has(H.item(f, "virar")))
	assert_eq(c.values_in(f, H.item(f, "estocada")), [6])


func test_sangria_partes_mantem_o_elemento():
	var f := _f(["sangria"], [9, 2])
	f.bag[0] = Die.with_element("Na")
	var c := TurnChoice.new()
	assert_true(_place(f, c, "sangria", [0]))
	for h in [2, 3, 4]:
		assert_eq(f.die_of(f.hand[h]).element, "Na", "a parte guarda o elemento")
	assert_eq(_vals(f).slice(2), [3, 3, 3])


func test_sangria_mercurio_nao_recalcula():
	var f := _f(["sangria"], [6, 2])
	f.bag[0] = Die.with_element("Hg")
	_place(f, TurnChoice.new(), "sangria", [0])
	assert_eq(f.die_of(f.hand[2]).element, "Hg")
	assert_eq(_vals(f).slice(2), [2, 2, 2], "o Mercúrio não copia o maior de novo")
