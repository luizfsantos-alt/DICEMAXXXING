extends GutTest
## Dados 3D: a física para os dados deitados numa face e a face de cima recebe o valor
## sorteado; faces 2D: pontinhos até 6, algarismos acima.


func _dice(values: Array) -> Array:
	var out := []
	for k in values.size():
		out.append({"value": values[k], "element": "", "faces": [1, 2, 3, 4, 5, 6], "face": k % 6})
	return out


func test_rolagem_para_plana_e_mostra_o_valor():
	for s in 20:
		var rng := RandomNumberGenerator.new()
		rng.seed = s
		var dice := _dice([1, 2, 3, 4, 5, 6, 12, 27])
		var half := Vector2(5.5, 3.8)
		var sim := DiceRoll3D.plan(dice, half, rng)
		assert_lt(sim.frames.size(), DicePhysics.MAX_STEPS / sim.record_every + 2)
		for i in dice.size():
			var b: Dictionary = sim.bodies[i]
			var up := sim.up_face(i)
			var n: Vector3 = b.q * DicePhysics.FACE_NORMALS[up]
			assert_almost_eq(n.y, 1.0, 0.001, "face de cima plana (seed %d, dado %d)" % [s, i])
			assert_almost_eq(b.p.y, DicePhysics.H, 0.001, "encostado no chão")
			assert_lt(absf(b.p.x), half.x + 0.3, "dentro da caixa")
			assert_lt(absf(b.p.z), half.y + 0.3, "dentro da caixa")
			var labels := DiceRoll3D.face_labels(sim, i, dice[i])
			assert_eq(labels[up], dice[i].value, "valor sorteado na face de cima")
			var last: Array = sim.frames[sim.frames.size() - 1][i]
			assert_eq(last[1], b.q, "a gravação termina na pose final")


func test_dado_marcado_nao_rola():
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var dice := _dice([4, 5])
	dice[0].fixed = true
	var sim := DiceRoll3D.plan(dice, Vector2(5, 4), rng)
	assert_eq(sim.up_face(0), 0)
	assert_eq(DiceRoll3D.face_labels(sim, 0, dice[0])[0], 4)


func test_rotulos_seguem_os_pares_do_d6():
	var faces := [1, 2, 3, 4, 5, 6]
	for up in 6:
		for f in 6:
			var l := Dice3D.labels(up, faces[f], faces, f)
			assert_eq(l[up], faces[f])
			assert_eq(l[up ^ 1], 7 - faces[f], "face oposta soma 7")
			var sorted := l.duplicate()
			sorted.sort()
			assert_eq(sorted, faces, "as seis faces aparecem")
			for k in [0, 2, 4]:
				assert_eq(l[k] + l[k + 1], 7)


func test_faces_2d_e_texturas():
	assert_true(DieFace.uses_pips(1))
	assert_true(DieFace.uses_pips(6))
	assert_false(DieFace.uses_pips(7))
	assert_false(DieFace.uses_pips(0))
	for v in [1, 6, 9, 12, 108]:
		var d := Dice3D.depth_map(v)
		var dug := 0
		for x in d:
			if x > 0.5:
				dug += 1
		assert_gt(dug, 50, "valor %d escavado na textura" % v)
	assert_eq(Dice3D.mesh().get_surface_count(), 6)


# ================================================================== Visual (docs/DADOS_VISUAL.md)
const H := preload("res://tests/helpers.gd")
const LOOK_KEYS := ["body", "body2", "ink", "accent", "finish", "rough", "metal", "coat", "alpha", "rim", "glow", "emission", "energy"]


## Contraste (WCAG) entre duas cores.
static func _contrast(a: Color, b: Color) -> float:
	var la := _lum(a)
	var lb := _lum(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


static func _lum(c: Color) -> float:
	var l := c.srgb_to_linear()
	return 0.2126 * l.r + 0.7152 * l.g + 0.0722 * l.b


func test_todo_elemento_tem_visual_legivel():
	for el in [""] + Elements.ALL:
		assert_true(Elements.LOOKS.has(el), "visual de '%s'" % el)
		var l: Dictionary = Elements.LOOKS[el]
		for k in LOOK_KEYS:
			assert_true(l.has(k), "'%s' tem %s" % [el, k])
		assert_gt(_contrast(l.body, l.ink), 3.0, "tinta legível no corpo de '%s'" % el)
		assert_gt(_contrast(l.accent, Kit.BG), 4.5, "texto de '%s' legível no fundo" % el)
		assert_eq(Elements.COLORS[el], l.accent, "COLORS é o accent de '%s'" % el)


func test_corpos_diferentes_entre_si():
	var els := [""] + Elements.ALL
	for i in els.size():
		for j in range(i + 1, els.size()):
			var a: Color = Elements.look(els[i]).body
			var b: Color = Elements.look(els[j]).body
			var d := Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()
			assert_gt(d, 0.1, "corpos de '%s' e '%s' distintos" % [els[i], els[j]])


func test_brilho_so_nos_quatro_e_cresce_com_o_estado():
	for el in [""] + Elements.ALL:
		var glows: bool = el in ["H", "U", "Na", "C"]
		assert_eq(str(Elements.look(el).glow) != "", glows, "'%s' brilha?" % el)
		if glows:
			assert_gt(Elements.energy(el, 1.0), Elements.energy(el, 0.0), "'%s' acende mais ativo" % el)
		else:
			assert_eq(Elements.energy(el, 1.0), 0.0)
	var m := Dice3D.material(5, "C", 1.0)
	assert_true(m.emission_enabled)
	assert_almost_eq(m.emission_energy_multiplier, Elements.energy("C", 1.0), 0.001)
	assert_false(Dice3D.material(5, "Pb").emission_enabled)
	assert_gt(Dice3D.material(5, "Hg").metallic, 0.5, "Mercúrio é metal")
	assert_lt(Dice3D.material(5, "Hg").metallic, 1.0, "mas não espelho puro (sumia no fundo escuro)")
	assert_eq(Dice3D.material(9, "H").transparency, BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS)
	for glow in ["pips", "body", "rim"]:
		var img := Dice3D.emission_texture(4, glow).get_image()
		var c := img.get_pixel(Dice3D.TEX / 2, Dice3D.TEX / 2)
		var e := img.get_pixel(0, Dice3D.TEX / 2)
		match glow:
			"rim":
				assert_gt(e.r, 0.8, "aresta acesa")
				assert_lt(c.r, 0.1, "centro apagado")
			"body":
				assert_gt(e.r, 0.8, "corpo aceso")
	for el in [""] + Elements.ALL:
		assert_not_null(Dice3D.albedo_texture(6, el), "textura de '%s'" % el)


func test_estado_do_brilho():
	var f: Fighter = H.fighter("eu", [], 40, true)
	f.bag = [Die.with_element("H"), Die.basic(), Die.with_element("U"), Die.with_element("C"), Die.with_element("C")]
	assert_eq(Elements.heat(f, f.bag[0]), 1.0, "Hidrogênio solitário (bolsa de 5)")
	assert_eq(Elements.heat(f, f.bag[1]), 0.0, "comum não brilha")
	assert_eq(Elements.heat(f, f.bag[2], true), 1.0, "Urânio parado na mão")
	assert_eq(Elements.heat(f, f.bag[2], false), 0.0, "Urânio posto numa magia")
	H.hand(f, [1, 2, 3, 4, 5])
	assert_gt(Elements.heat(f, f.bag[3]), 0.0, "dois Carbonos na mão: cadeia")
	H.hand(f, [1, 2, 3, 4])
	assert_eq(Elements.heat(f, f.bag[3]), 0.0, "Carbono sozinho na mão")
	for i in 4:
		f.bag.append(Die.basic())
	assert_eq(Elements.heat(f, f.bag[0]), 0.0, "Hidrogênio com bolsa grande")
	assert_eq(Elements.heat(f, null), 0.0)


func test_foto_do_dado_para_a_coluna():
	assert_eq(DieSnapshot.key(5, "Hg"), "5|Hg|0")
	assert_eq(DieSnapshot.key(5, "H", 1.0), "5|H|2")
	assert_eq(DieSnapshot.key(5, "C", 0.4), "5|C|1", "brilho em três degraus")
	var r := DieSnapshot.rect_for(Rect2(10, 10, 100, 100))
	assert_almost_eq(r.get_center(), Vector2(60, 60), Vector2(0.01, 0.01), "foto centrada no dado")
	assert_almost_eq(r.size.x * 1.0 / DieSnapshot.VIEW, 100.0 * DieSnapshot.FILL, 0.01, "aresta do dado = FILL do quadrado")
	if not DieSnapshot.enabled():
		assert_null(DieSnapshot.texture(5, "Hg"), "sem vídeo: face 2D")
