extends SceneTree
## Captura da mesa de feltro (uso manual: precisa de vídeo):
## godot --resolution 1280x720 -s res://sim/shot_felt.gd -- --out=/caminho
## 1. A luta com dados de Sódio, Urânio, Mercúrio e Ouro: rolando (sombras e luz no
##    feltro), parados na mesa, na coluna, um dado selecionado e outro posto numa magia.
## 2. O turno do inimigo (as magias dele pintadas no feltro).
## 3. Muitas magias no palco (os cartões encolhem, o contorno segue a perspectiva).
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

func _duel(seed: int, els: Array, extra: Array = []) -> DuelScreen:
	var run := RunState.new_run(seed)
	run.choose(0)
	run.choose(0)
	var p := run.duel.player
	for k in p.hand.size():
		p.die_of(p.hand[k]).element = els[k % els.size()]
	for id in extra:
		p.inventory.add(id)
	var d := DuelScreen.new().setup(run)
	get_root().add_child(d)
	return d

func _run() -> void:
	var d := _duel(42, ["Na", "U", "Hg", "Au", "Li", "Os"])
	for i in 4:
		await process_frame
	await _shot("felt_roll_a")
	for i in 4:
		await process_frame
	await _shot("felt_roll_b")
	# Dados parados na mesa (segurando o resultado), antes de voarem para a coluna.
	while d.roller != null and d.roller._t * DiceRoll3D.FPS < d.roller._frames.size():
		await process_frame
	await _shot("felt_roll_stop")
	if "--debug" in OS.get_cmdline_user_args():
		d.felt.vp.get_texture().get_image().save_png(out + "/felt_only.png")
	while d.phase != "player" or d.roller != null:
		await process_frame
	for i in 20:
		await process_frame
	await _shot("felt_after")
	# Seleciona um dado (cartões que aceitam acendem, os outros apagam) e põe outro numa magia.
	d._on_die(d.tray_views[0])
	await _shot("felt_select")
	for c: SpellCard in d.cards:
		if d.place(1, c.item):
			break
	d._on_die(d.tray_views[2])
	for i in 4:
		await process_frame
	await _shot("felt_placed")
	d.queue_free()
	await process_frame

	var d2 := _duel(7, ["", "Na", "", "U"], ["escudo", "remendo", "espelho", "sintese", "virar"])
	for i in 6:
		await process_frame
	await _shot("felt_many_roll")
	while d2.phase != "player" or d2.roller != null:
		await process_frame
	for i in 20:
		await process_frame
	await _shot("felt_many")
	# Turno do inimigo (sem pôr dado nenhum): as magias dele no palco.
	d2._on_end_turn()
	for i in 30:
		await process_frame
	await _shot("felt_enemy")
	quit()
