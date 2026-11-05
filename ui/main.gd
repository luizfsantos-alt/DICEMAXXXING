extends Control
## Raiz: troca de telas conforme a fase da jornada.

var run: RunState
var current: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Kit.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	show_menu()


func _swap(c: Control) -> void:
	if current:
		current.queue_free()
	current = c
	add_child(c)


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
