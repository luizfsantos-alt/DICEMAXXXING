extends SceneTree
## Captura de tela: menu e tela de duelo durante a rolagem 3D da primeira mão
## (uso manual: precisa de vídeo). godot -s res://sim/shot_duel.gd -- --out=/caminho
var out := "user://"

func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	_run.call_deferred()

func _shot(name: String) -> void:
	await process_frame
	await process_frame
	get_root().get_texture().get_image().save_png(out + "/" + name + ".png")

func _run() -> void:
	var bg := ColorRect.new()
	bg.color = Kit.BG
	bg.size = Vector2(1280, 720)
	get_root().add_child(bg)
	var m := MenuScreen.new().setup()
	get_root().add_child(m)
	await _shot("menu")
	m.queue_free()
	var run := RunState.new_run(42)
	run.choose(0)
	run.choose(0)
	var d := DuelScreen.new().setup(run)
	get_root().add_child(d)
	for i in 25:
		await process_frame
	await _shot("duel_roll")
	while d.phase != "player" or d.roller != null:
		await process_frame
	for i in 20:
		await process_frame
	await _shot("duel_after")
	quit()
