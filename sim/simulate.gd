extends SceneTree
## Simulador headless de jornadas para balanceamento.
## Uso: godot --headless -s res://sim/simulate.gd -- --runs=2000 --seed=1
## Bot: os 3 maiores dados no ataque, sem defesa; compra a oferta se puder.


func _init() -> void:
	var runs := 1000
	var seed0 := 1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--runs="):
			runs = int(a.split("=")[1])
		elif a.begins_with("--seed="):
			seed0 = int(a.split("=")[1])
	var reached := {}
	var died_at := {}
	var turns_total := 0
	var duels_total := 0
	for i in runs:
		var run := RunState.new_run(seed0 + i)
		while run.phase in ["duel", "shop"]:
			if run.phase == "duel":
				run.duel.submit(EnemyAI.brute(run.duel.player))
				if run.duel.state != "choosing":
					turns_total += run.duel.turn
					duels_total += 1
					run.finish_duel()
				else:
					run.duel.begin_turn()
			else:
				Shop.buy(run)
				run.next_fight()
		var last_won := run.fight if run.phase == "victory" else run.fight - 1
		for f in range(1, last_won + 1):
			reached[f] = reached.get(f, 0) + 1
		if run.phase == "defeat":
			died_at[run.fight] = died_at.get(run.fight, 0) + 1
	print("Jornadas: %d" % runs)
	print("Turnos médios por duelo: %.2f" % (float(turns_total) / maxi(1, duels_total)))
	for f in [5, 9, 10, 15, 19, 20, 25, 29, 30]:
		print("Venceu a luta %2d: %5.1f%%" % [f, 100.0 * reached.get(f, 0) / runs])
	var worst := died_at.keys()
	worst.sort_custom(func(x, y): return died_at[x] > died_at[y])
	var top := []
	for f in worst.slice(0, 5):
		top.append("luta %d (%d)" % [f, died_at[f]])
	print("Onde mais morre: " + ", ".join(top))
	quit()
