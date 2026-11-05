extends SceneTree
## Captura de tela da rolagem 3D e das faces 2D (uso manual: precisa de vídeo).
## godot -s res://sim/shot_dice.gd -- --out=/caminho
var out := "user://"

func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	_run.call_deferred()

func _run() -> void:
	var root := Control.new()
	root.size = Vector2(1280, 720)
	get_root().add_child(root)
	var bg := ColorRect.new()
	bg.color = Kit.BG
	bg.size = root.size
	root.add_child(bg)
	var vals := [1, 2, 3, 4, 5, 6, 8, 12, 27]
	var els := ["", "H", "Os", "U", "Na", "Hg", "Pb", "Am", "C"]
	for k in vals.size():
		var h := Hole.new().set_interactive(false).setup(92)
		h.position = Vector2(20 + k * 100, 600)
		h.set_die(vals[k], els[k])
		root.add_child(h)
	var r := DiceRoll3D.new().setup(Vector2(820, 560))
	r.position = Vector2(20, 20)
	root.add_child(r)
	var dice := []
	for k in 6:
		dice.append({"value": vals[k + 3], "element": els[k], "faces": [1, 2, 3, 4, 5, 6], "face": k % 6})
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var sim := DiceRoll3D.plan(dice, r.arena(), rng)
	r._build_nodes(dice, sim)
	var n := sim.frames.size()
	print("frames: ", n)
	for f in [n / 6, n / 3, n - 1]:
		r._show_frame(sim.frames[f])
		for i in 3:
			await process_frame
		get_root().get_texture().get_image().save_png(out + "/dice_%d.png" % f)
	quit()
