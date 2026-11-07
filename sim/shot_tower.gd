extends SceneTree
## Captura de tela da torre: portas, Mestre, paradas, Loja, Poço e recompensa do Mestre com as ilustrações dos cartões
## (uso manual: precisa de vídeo). godot -s res://sim/shot_tower.gd -- --out=/caminho
var out := "user://"

func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	_run.call_deferred()

func _shot(t: TowerScreen, name: String, phase: String, opts: Array) -> void:
	t.run.phase = phase
	t.run.options = opts
	t.run.coins = 99
	t.refresh()
	for i in 3:
		await process_frame
	get_root().get_texture().get_image().save_png(out + "/" + name + ".png")

func _run() -> void:
	var bg := ColorRect.new()
	bg.color = Kit.BG
	bg.size = Vector2(1280, 720)
	get_root().add_child(bg)
	var run := RunState.new_run(42)
	run.choose(0)
	var t := TowerScreen.new().setup(run)
	get_root().add_child(t)
	var doors := []
	for id in ["facil", "normal", "dificil", "insana"]:
		doors.append({"kind": "door", "id": id, "price": 0, "needs": "", "coins": RunState.door_coins(id)})
	run.options = doors
	run._door_enemies() ## Cada porta mostra o arquétipo do inimigo.
	await _shot(t, "doors", "doors", doors)
	await _shot(t, "master", "doors", [{"kind": "door", "id": "mestre", "price": 0, "needs": ""}])
	var stops := []
	for id in ["shop", "heal", "school", "well"]:
		stops.append({"kind": "stop", "id": id, "price": 0, "needs": ""})
	await _shot(t, "stops", "rest", stops)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	await _shot(t, "shop", "shop", Shop.shop(run.hero, rng, 0, 3))
	await _shot(t, "well", "well", Shop.well(rng, 3, run.hero))
	await _shot(t, "master_reward", "master_reward", Shop.master_reward())
	quit()
