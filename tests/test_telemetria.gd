extends GutTest
## Telemetria local de playtest (docs/SPEC_v3.1.md §5.2).

const H := preload("res://tests/helpers.gd")
const Report := preload("res://sim/telemetria.gd")


func before_each():
	Telemetry.path = "user://test_jornadas.json"
	Telemetry.clear()
	Telemetry.enabled = true


func after_each():
	Telemetry.clear()
	Telemetry.enabled = false
	Telemetry.path = Telemetry.PATH


func _play(run_seed: int) -> RunState:
	var run := RunState.new_run(run_seed, "barbarian")
	var bot := SimBot.new()
	var guard := 0
	while not (run.phase in ["victory", "defeat"]) and guard < 3000:
		guard += 1
		match run.phase:
			"duel":
				var r := H.rng(run_seed)
				run.duel.player.personality = "cauteloso"
				while run.duel.state == "choosing":
					run.duel.submit(EnemyAI.choose(run.duel.player, run.duel.enemy, r))
				run.finish_duel()
			"doors":
				run.choose(bot.pick_door(run))
			"market":
				var j: int = bot.pick_stop(run)
				if j < 0 or run.choose(j) != "":
					run.leave()
			_:
				bot.shop_phase(run)
	return run


func test_jornada_encerrada_fica_gravada():
	var run := _play(3)
	var all := Telemetry.load_all()
	assert_eq(all.size(), 1)
	var r: Dictionary = all[0]
	assert_eq(str(r.character), "barbarian")
	assert_eq(str(r.result), run.phase)
	assert_eq(int(r.floor), run.floor_n)
	assert_true(r.floors.size() >= 1)
	var f0: Dictionary = r.floors[0]
	assert_true(str(f0.door) != "" and f0.doors.size() >= 2, "portas oferecidas e escolhida")
	assert_true(int(f0.turns) > 0)
	if str(r.result) == "defeat":
		assert_true(str(r.cause.kind) != "", "causa da derrota")


func test_guarda_so_as_ultimas_50_e_le_o_exportado():
	for i in Telemetry.MAX_RUNS + 2:
		Telemetry.finish({"character": "sorcerer", "floor": i, "result": "defeat", "floors": []})
	var all := Telemetry.load_all()
	assert_eq(all.size(), Telemetry.MAX_RUNS)
	assert_eq(int(all[0].floor), 2, "as mais antigas saem")
	var parsed = JSON.parse_string(Telemetry.export_text())
	assert_true(parsed is Array)
	var out: Dictionary = Report.report(parsed)
	assert_eq(int(out.by_char.sorcerer[0]), Telemetry.MAX_RUNS)


func test_desligada_nao_grava():
	Telemetry.enabled = false
	Telemetry.finish({"character": "x", "floors": []})
	assert_eq(Telemetry.load_all().size(), 0)
