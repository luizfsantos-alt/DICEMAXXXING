extends SceneTree
## Lê as jornadas exportadas pelo jogo (botão "Copiar dados das jornadas" no menu, ou
## user://jornadas.json) e imprime o resumo no formato do simulador, para comparar o
## humano com o bot (docs/SPEC_v3.1.md §5.2).
## Uso: godot --headless -s res://sim/telemetria.gd -- --file=/caminho/jornadas.json


func _init() -> void:
	var path := Telemetry.PATH
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--file="):
			path = a.substr(7)
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		print("Sem arquivo: " + path)
		quit()
		return
	var runs = JSON.parse_string(f.get_as_text())
	if not (runs is Array):
		print("Arquivo inválido: " + path)
		quit()
		return
	report(runs)
	quit()


static func report(runs: Array) -> Dictionary:
	var by_char := {}
	var died_pos := [0, 0, 0]
	var fights_pos := [0, 0, 0]
	var doors := {}
	var mods := {}
	var turns := 0
	var duels := 0
	var early := 0
	var early_n := 0
	for r in runs:
		var c := str(r.get("character", "?"))
		var bc: Array = by_char.get(c, [0, 0, 0])
		bc[0] += 1
		bc[1] += int(r.get("floor", 0))
		if str(r.get("result", "")) == "victory":
			bc[2] += 1
		by_char[c] = bc
		var fl: Array = r.get("floors", [])
		for e in fl:
			if str(e.get("door", "")) == "":
				continue
			var pos := (int(e.floor) - 1) % 3
			fights_pos[pos] += 1
			doors[str(e.door)] = int(doors.get(str(e.door), 0)) + 1
			turns += int(e.get("turns", 0))
			duels += 1
			if int(e.floor) <= 3:
				early += int(e.get("turns", 0))
				early_n += 1
			for m in e.get("mods", {}):
				mods[m] = int(mods.get(m, 0)) + int(e.mods[m])
		if str(r.get("result", "")) == "defeat":
			died_pos[(int(r.get("floor", 1)) - 1) % 3] += 1
	print("Jornadas: %d" % runs.size())
	for c in by_char:
		var bc: Array = by_char[c]
		print("  %-13s %3d jornadas · andar médio %.1f · venceram %d" % [c, bc[0], float(bc[1]) / maxi(1, bc[0]), bc[2]])
	print("Turnos médios por luta (dois lados): %.2f · andares 1–3: %.2f" % [float(turns) / maxi(1, duels), float(early) / maxi(1, early_n)])
	print("Derrotas por posição no bloco (1ª/2ª/3ª luta depois da parada): %d · %d · %d (de %d · %d · %d lutas)" % [
		died_pos[0], died_pos[1], died_pos[2], fights_pos[0], fights_pos[1], fights_pos[2]])
	var dk := doors.keys()
	dk.sort()
	print("Portas escolhidas: " + ", ".join(dk.map(func(k): return "%s %d" % [k, doors[k]])))
	var mk := mods.keys()
	mk.sort()
	print("Mexidas usadas: " + ", ".join(mk.map(func(k): return "%s %d" % [k, mods[k]])))
	return {"by_char": by_char, "doors": doors, "mods": mods}
