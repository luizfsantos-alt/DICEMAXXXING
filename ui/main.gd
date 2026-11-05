extends Control
## Raiz: troca de telas conforme a fase da jornada.

var run: RunState
var current: Control
## Botão de depuração no canto: volta ao menu e apaga a partida ativa (pede um 2º toque).
var quit_btn: Button
var _quit_armed := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Kit.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	show_menu()


## Botão pequeno no canto superior direito, por cima de todas as telas da jornada.
func _make_quit_button() -> void:
	quit_btn = Kit.button(Texts.t("ui.quit_menu"), _on_quit_pressed, Kit.DANGER.darkened(0.45), 14)
	quit_btn.custom_minimum_size = Vector2(0, 0)
	quit_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	quit_btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	quit_btn.offset_right = -2
	quit_btn.offset_top = 2
	quit_btn.modulate.a = 0.75
	add_child(quit_btn)


func _on_quit_pressed() -> void:
	if not _quit_armed:
		_quit_armed = true
		quit_btn.text = Texts.t("ui.quit_confirm")
		get_tree().create_timer(3.0).timeout.connect(_disarm_quit)
		return
	abandon_run()


func _disarm_quit() -> void:
	_quit_armed = false
	if is_instance_valid(quit_btn):
		quit_btn.text = Texts.t("ui.quit_menu")


## Perde a partida ativa (o save é apagado) e volta ao menu.
func abandon_run() -> void:
	SaveGame.clear()
	run = null
	show_menu()


func _swap(c: Control) -> void:
	if current:
		current.queue_free()
	current = c
	add_child(c)
	# O botão de voltar ao menu só aparece durante a jornada e fica por cima da tela.
	if quit_btn == null:
		_make_quit_button()
	_quit_armed = false
	quit_btn.text = Texts.t("ui.quit_menu")
	quit_btn.visible = not (c is MenuScreen or c is EndScreen)
	move_child(quit_btn, -1)


func show_menu() -> void:
	var m := MenuScreen.new().setup()
	m.new_run.connect(_on_new_run)
	m.continue_run.connect(_on_continue)
	_swap(m)


func _on_new_run(char_id: String) -> void:
	SaveGame.clear()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	run = RunState.new_run(rng.randi(), char_id)
	SaveGame.save(run)
	show_phase()


func _on_continue() -> void:
	run = SaveGame.load_run()
	if run == null:
		show_menu()
		return
	show_phase()


func show_phase() -> void:
	match run.phase:
		"duel":
			var d := DuelScreen.new().setup(run)
			d.finished.connect(show_phase)
			_swap(d)
		"victory", "defeat":
			SaveGame.clear()
			var e := EndScreen.new().setup(run)
			e.finished.connect(show_menu)
			_swap(e)
		_:
			var t := TowerScreen.new().setup(run)
			t.finished.connect(show_phase)
			_swap(t)
