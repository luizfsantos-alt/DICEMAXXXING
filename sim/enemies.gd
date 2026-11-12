extends SceneTree
## Perfil dos inimigos por andar (vida, magias, níveis, adesivos, elementos, dados).
## Uso: godot --headless -s res://sim/enemies.gd -- --n=200 --door=normal


func _init() -> void:
	var n := 200
	var door := "normal"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--n="):
			n = int(a.split("=")[1])
		elif a.begins_with("--door="):
			door = a.split("=")[1]
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	print("Porta %s, %d inimigos por andar (médias)" % [door, n])
	print("andar  vida  magias  niveis+  adesivos  maxface  dados  elem")
	for fl in [1, 2, 3, 4, 6, 9, 12, 15, 19, 22, 25, 29]:
		var hp := 0.0
		var sp := 0.0
		var lv := 0.0
		var st := 0.0
		var top := 0.0
		var dice := 0.0
		var el := 0.0
		for _i in n:
			var f := EnemyFactory.create(fl, door, rng)
			hp += f.max_hp
			sp += f.inventory.items.size()
			var best := 0
			for it in f.inventory.items:
				lv += int(it.level) - 1
			for d in f.bag:
				st += d.sticker_count()
				for k in 6:
					best = maxi(best, int(d.stickers[k]))
				el += int(d.element != "")
			top += best
			dice += f.bag.size()
		print("%5d %5.0f %7.1f %8.1f %9.1f %8.1f %6.1f %5.1f" % [fl, hp / n, sp / n, lv / n, st / n, top / n, dice / n, el / n])
	quit()
