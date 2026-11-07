extends SceneTree
## Captura de tela das mexidas (docs/SPEC_v3.1.md §1.9): antes, com o dado selecionado
## (prévia), e depois que a mexida resolveu e o cartão saiu do palco. Uso manual
## (precisa de vídeo): godot -s res://sim/shot_mexidas.gd -- --out=/caminho
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

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _run() -> void:
	var run := RunState.new_run(42, "metallurgist")
	run.choose(0)
	var p := run.duel.player
	p.inventory.add("ajuste")
	p.hand = []
	var vals := [1, 1, 4, 2]
	for i in vals.size():
		p.hand.append({"bag": i, "temp": null, "face": 0, "value": vals[i], "top": false, "fixed": false, "plus": 0, "spawn": -1})
	p.bag[0] = Elements.lead()
	p.bag[1] = Elements.lead()
	p.hand[2]["orig"] = 8
	p.hand[2]["cause"] = "halve"
	var d := DuelScreen.new().setup(run)
	d.fast = false
	get_root().add_child(d)
	await _frames(10)
	while d.phase != "player":
		await process_frame
	d.skip = false
	d._on_die(d.tray_views[0])
	await _frames(4)
	await _shot("mexida_antes")
	var vi := p.inventory.ids().find("virar")
	d._on_card(vi)
	while d.busy:
		await process_frame
	await _frames(20)
	await _shot("mexida_depois")
	quit()
