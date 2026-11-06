extends SceneTree
## Captura da tremida da tela: um golpe de cada faixa (10, 25, 50, 80 e 100% da vida do
## inimigo), quadro a quadro (uso manual: precisa de vídeo). Rode com --fixed-fps para os
## quadros saírem no ritmo certo e junte com ffmpeg:
## xvfb-run godot --fixed-fps 30 -s res://sim/shot_shake.gd -- --out=/caminho
var out := "user://"
const CASES := [[0.10, 1], [0.25, 2], [0.50, 3], [0.80, 4], [1.00, 5]]
const FRAMES := 36 ## Por golpe (1,2 s a 30 fps).

func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	_run.call_deferred()

func _run() -> void:
	var bg := ColorRect.new()
	bg.color = Kit.BG
	bg.size = Vector2(1280, 720)
	get_root().add_child(bg)
	var run := RunState.new_run(42)
	run.choose(0)
	run.choose(0)
	var d := DuelScreen.new().setup(run)
	get_root().add_child(d)
	while d.phase != "player" or d.roller != null:
		await process_frame
	for i in 20:
		await process_frame
	var tag := Kit.label("", 30, Color.WHITE)
	tag.add_theme_constant_override("outline_size", 10)
	tag.add_theme_color_override("font_outline_color", Color.BLACK)
	tag.position = Vector2(380, 20)
	get_root().add_child(tag)
	var e: Dictionary = d.shown.enemy
	var n := 0
	for c in CASES:
		var dmg := maxi(1, int(ceil(float(c[0]) * float(e.max))))
		tag.text = "Dano %d de %d (%d%% da vida)" % [dmg, int(e.max), int(c[0] * 100.0)]
		e.hp = int(e.max) - dmg ## Como num golpe de verdade: a barra cai e o número sobe.
		d.fx_src = d._center(d.cards[0])
		d._effect("enemy", "−%d" % dmg, "dmg", "src", int(c[1]))
		for f in FRAMES:
			await process_frame
			get_root().get_texture().get_image().save_png("%s/f_%d_%03d.png" % [out, int(c[1]), f])
			n += 1
			if f == 12:
				d._refresh_shown_only()
		e.hp = int(e.max)
		d._refresh_shown_only()
	print("quadros: ", n)
	quit()
