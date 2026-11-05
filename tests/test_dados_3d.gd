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
