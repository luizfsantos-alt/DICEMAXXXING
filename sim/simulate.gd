extends SceneTree
## Simulador headless de jornadas para balanceamento (docs/SPEC_v3.md).
## Uso: godot --headless -s res://sim/simulate.gd -- --runs=1000 --seed=1 --door=normal --char=sorcerer
## --char=all roda cada personagem. --spells imprime, por magia, quantas vezes foi
## oferecida, escolhida e quantas jornadas que a tinham chegaram ao fim (docs/RARIDADE.md §7).
## O bot joga com a IA "cautelosa", escolhe sempre a porta pedida (ou a mais fácil),
## pega a primeira recompensa que couber e, nas paradas, prefere Cura com pouca vida.
## Experimentos (não mudam o jogo): --hand=-1 soma à mão de todos (jogador e inimigos,
## mínimo 2); --h-mult=2 e --h-bag=6 trocam o multiplicador e a bolsa máxima do Hidrogênio.
## --enemy-hp=0.85 multiplica a vida dos inimigos; --hero-hp=70 troca a vida inicial do herói.
## --agile-stack: o +1 dado do Ágil (Assassino) acumula até o fim da luta.
## --report imprime vitórias por elemento na bolsa e derrotas por tipo de inimigo.


var offered := {}
var chosen := {}
var won_with := {}
var hand_delta := 0
var report := false
var enemy_hp := 1.0
var hero_hp := 0


func _init() -> void:
	var runs := 1000
	var seed0 := 1
	var door_pref := "normal"
	var chars := ["sorcerer"]
	var spell_report := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--char="):
			var c := a.split("=")[1]
			chars = Characters.ALL if c == "all" else [c]
		elif a == "--spells":
			spell_report = true
		elif a == "--report":
			report = true
		elif a == "--agile-stack":
			Characters.agile_stack = true
			print("Experimento: Ágil acumula até o fim da luta")
		elif a.begins_with("--enemy-hp="):
			enemy_hp = float(a.split("=")[1])
		elif a.begins_with("--hero-hp="):
			hero_hp = int(a.split("=")[1])
		elif a.begins_with("--hand="):
			hand_delta = int(a.split("=")[1])
		elif a.begins_with("--h-mult="):
			Elements.solitary_mult = int(a.split("=")[1])
		elif a.begins_with("--h-bag="):
			Elements.solitary_bag = int(a.split("=")[1])
		if a.begins_with("--runs="):
			runs = int(a.split("=")[1])
		elif a.begins_with("--seed="):
			seed0 = int(a.split("=")[1])
		elif a.begins_with("--door="):
			door_pref = a.split("=")[1]
	if enemy_hp != 1.0 or hero_hp > 0:
		print("Experimento: vida dos inimigos ×%.2f · vida do herói %s" % [enemy_hp, str(hero_hp) if hero_hp > 0 else "padrão"])
	if hand_delta != 0 or Elements.solitary_mult != Elements.SOLITARY_MULT or Elements.solitary_bag != Elements.SOLITARY_BAG:
		print("Experimento: mão %+d · Hidrogênio ×%d com bolsa ≤ %d" % [hand_delta, Elements.solitary_mult, Elements.solitary_bag])
	for c in chars:
		_simulate(c, runs, seed0, door_pref)
	if spell_report:
		_print_spells()
	quit()


func _simulate(char_id: String, runs: int, seed0: int, door_pref: String) -> void:
	var reached := {}
	var died_at := {}
	var turns_total := 0
	var duels_total := 0
	var hp_after := {}
	var el_runs := {} ## Elemento na bolsa em alguma luta -> [jornadas, vitórias].
	var foe_stats := {} ## Tipo de inimigo -> [lutas, derrotas].
	for i in runs:
		var run := RunState.new_run(seed0 + i, char_id)
		run.hero.hand_size = maxi(2, run.hero.hand_size + hand_delta)
		if hero_hp > 0:
			run.hero.max_hp = hero_hp
			run.hero.hp = hero_hp
		var els := {}
		var guard := 0
		while not (run.phase in ["victory", "defeat"]) and guard < 10000:
			guard += 1
			match run.phase:
				"duel":
					var bot_rng := RandomNumberGenerator.new()
					bot_rng.seed = seed0 + i
					run.duel.player.personality = "cauteloso"
					var foe := run.duel.enemy
					foe.hand_size = maxi(2, foe.hand_size + hand_delta)
					if enemy_hp != 1.0:
						foe.max_hp = maxi(1, int(round(foe.max_hp * enemy_hp)))
						foe.hp = foe.max_hp
					var kind := foe.master_id if foe.master_id != "" else (foe.variant if foe.variant != "" else foe.archetype)
					if not (kind in ["minimalist", "monge"]) and foe.bag.any(func(d): return Elements.solitary(foe, d)):
						kind += "+H"
					for d in run.hero.bag:
						if d.element == "H" and Elements.solitary(run.hero, d):
							els["H ligado"] = true
						elif d.element != "":
							els[d.element] = true
					while run.duel.state == "choosing":
						run.duel.submit(EnemyAI.choose(run.duel.player, run.duel.enemy, bot_rng))
					turns_total += run.duel.turn
					duels_total += 1
					var fs: Array = foe_stats.get(kind, [0, 0])
					fs[0] += 1
					if run.duel.state != "won":
						fs[1] += 1
					foe_stats[kind] = fs
					run.finish_duel()
					if run.phase != "defeat":
						var k := run.floor_n
						hp_after[k] = hp_after.get(k, 0) + float(run.hero.hp) / run.hero.max_hp
				"doors":
					var pick := 0
					for j in run.options.size():
						if run.options[j].id == door_pref:
							pick = j
					run.choose(pick)
				"rest":
					var pick := 0
					var low := run.hero.hp * 2 < run.hero.max_hp
					for j in run.options.size():
						if (low and run.options[j].id == "heal") or (not low and run.options[j].id == "school"):
							pick = j
					run.choose(pick)
				_:
					_take_something(run)
		if run.phase == "victory":
			for id in run.hero.inventory.ids():
				won_with[id] = won_with.get(id, 0) + 1
		var last_won := run.floor_n if run.phase == "victory" else run.floor_n - 1
		for f in range(1, last_won + 1):
			reached[f] = reached.get(f, 0) + 1
		if run.phase == "defeat":
			died_at[run.floor_n] = died_at.get(run.floor_n, 0) + 1
		for el in els:
			var er: Array = el_runs.get(el, [0, 0])
			er[0] += 1
			if run.phase == "victory":
				er[1] += 1
			el_runs[el] = er
	print("Personagem: %s · Porta: %s · Jornadas: %d" % [char_id, door_pref, runs])
	print("Turnos médios por luta (dois lados): %.2f" % (float(turns_total) / maxi(1, duels_total)))
	for f in range(1, Config.LAST_FLOOR + 1):
		var w: int = reached.get(f, 0)
		print("Venceu o andar %2d: %5.1f%%   vida média depois: %3.0f%%" % [f, 100.0 * w / runs, 100.0 * hp_after.get(f, 0.0) / maxi(1, w)])
	if not report:
		return
	print("Elemento na bolsa (em alguma luta): jornadas · venceram o andar %d" % Config.LAST_FLOOR)
	var keys := el_runs.keys()
	keys.sort()
	for el in keys:
		var er: Array = el_runs[el]
		print("  %-9s %5d · %5.1f%%" % [el, er[0], 100.0 * er[1] / maxi(1, er[0])])
	print("Inimigo: lutas · derrotas do jogador")
	keys = foe_stats.keys()
	keys.sort_custom(func(a, b): return float(foe_stats[a][1]) / foe_stats[a][0] > float(foe_stats[b][1]) / foe_stats[b][0])
	for k in keys:
		var fs: Array = foe_stats[k]
		print("  %-16s %5d · %5.1f%%" % [k, fs[0], 100.0 * fs[1] / maxi(1, fs[0])])


func _print_spells() -> void:
	print("Magia (raridade): oferecida · escolhida · jornadas vencidas com ela")
	var ids := Spells.DATA.keys()
	ids.sort_custom(func(a, b): return chosen.get(a, 0) > chosen.get(b, 0))
	for id in ids:
		print("  %-12s (%s): %5d · %5d · %4d" % [id, Spells.rarity(id), offered.get(id, 0), chosen.get(id, 0), won_with.get(id, 0)])


## Recompensa, Loja, Escola, Poço, Erudito: compra em ordem o que puder (até 3 vezes); depois sai.
func _take_something(run: RunState) -> void:
	var phase := run.phase
	for o in run.options:
		if o.kind == "spell":
			offered[o.id] = offered.get(o.id, 0) + 1
	for _k in 3:
		var bought := false
		for j in run.options.size():
			var o: Dictionary = run.options[j]
			if o.kind == "destroy":
				continue
			var target := {}
			if o.needs == "face":
				target = {"die": _best_die(run.hero), "face": 5}
			elif o.needs == "die":
				target = {"die": _plain_die(run.hero)}
			if run.choose(j, target) == "":
				if o.kind == "spell":
					chosen[o.id] = chosen.get(o.id, 0) + 1
				bought = true
				break
		if run.phase != phase or not bought:
			break
	if run.phase == phase:
		run.leave()


func _best_die(h: Fighter) -> int:
	var best := 0
	for i in h.bag.size():
		if h.bag[i].value(5) > h.bag[best].value(5) and not h.bag[i].locked[5]:
			best = i
	return best


func _plain_die(h: Fighter) -> int:
	for i in h.bag.size():
		if h.bag[i].element == "":
			return i
	return 0
