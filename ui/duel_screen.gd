class_name DuelScreen
extends Control
## Tela do duelo: bandeja de 6 dados, encaixe de ataque e de defesa, swipe para lançar.

signal finished

var run: RunState
var duel: Duel

# Estado da interação do turno.
var launched: Array = []
var staged: Array = []
var defense: Array = []
var selected: int = -1
var group_done: bool = false
var locked: bool = false

# Nós.
var enemy_info: VBoxContainer
var enemy_dice_row: HBoxContainer
var log_label: RichTextLabel
var player_info: VBoxContainer
var attack_slot: PanelContainer
var attack_content: VBoxContainer
var defense_slot: PanelContainer
var defense_content: VBoxContainer
var tray: HBoxContainer
var hint: Label
var action_row: HBoxContainer
var overlay: Control
var tray_views: Array = []
var _slot_press := Vector2.ZERO


func setup(r: RunState) -> DuelScreen:
	run = r
	duel = r.duel
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	_new_turn_ui()
	return self


# ------------------------------------------------------------------ Layout
func _build() -> void:
	var root := Kit.vbox(10)
	var m := Kit.margin(root, 16)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)

	var ep := Kit.panel()
	enemy_info = Kit.vbox(6)
	ep.add_child(enemy_info)
	root.add_child(ep)

	enemy_dice_row = Kit.hbox(8)
	enemy_dice_row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(enemy_dice_row)

	var lp := Kit.panel(Color(0.11, 0.1, 0.14))
	lp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_label = RichTextLabel.new()
	log_label.bbcode_enabled = true
	log_label.scroll_following = true
	log_label.add_theme_font_size_override("normal_font_size", 22)
	log_label.add_theme_color_override("default_color", Kit.MUTED)
	lp.add_child(log_label)
	root.add_child(lp)

	var pp := Kit.panel()
	player_info = Kit.vbox(6)
	pp.add_child(player_info)
	root.add_child(pp)

	var slots := Kit.hbox(10)
	attack_slot = Kit.panel(Color(0.3, 0.13, 0.15))
	attack_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	attack_slot.custom_minimum_size = Vector2(0, 190)
	attack_content = Kit.vbox(4)
	attack_slot.add_child(attack_content)
	attack_slot.gui_input.connect(_on_attack_slot_input)
	slots.add_child(attack_slot)
	defense_slot = Kit.panel(Color(0.12, 0.2, 0.32))
	defense_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	defense_slot.custom_minimum_size = Vector2(0, 190)
	defense_content = Kit.vbox(4)
	defense_slot.add_child(defense_content)
	defense_slot.gui_input.connect(_on_defense_slot_input)
	slots.add_child(defense_slot)
	root.add_child(slots)

	tray = Kit.hbox(8)
	tray.alignment = BoxContainer.ALIGNMENT_CENTER
	tray.custom_minimum_size = Vector2(0, 108)
	root.add_child(tray)

	hint = Kit.label("", 22, Kit.MUTED, true)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(hint)

	action_row = Kit.hbox(10)
	root.add_child(action_row)

	overlay = Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)


# ------------------------------------------------------------------ Turno
func _new_turn_ui() -> void:
	launched = []
	staged = []
	defense = []
	selected = -1
	group_done = false
	locked = false
	_render_enemy_dice(duel.enemy.dice, duel.enemy.dice_sides, null)
	_render_tray(duel.player.dice, duel.player.dice_sides)
	_render_info()
	_render_slots()
	_set_log(duel.turn_log)
	_set_hint_default()
	Kit.clear(action_row)
	var b := Kit.button(Texts.t("ui.end_turn"), _on_end_turn_pressed, Kit.PANEL_HI)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(b)


func _render_info() -> void:
	Kit.clear(enemy_info)
	var e := duel.enemy
	var title := e.name + ("  · " + Texts.t("ui.boss") if e.boss_id != "" else "")
	enemy_info.add_child(Kit.label(title, 26, Kit.ACCENT if e.boss_id != "" else Kit.TEXT, true))
	var fight_l := Kit.label(Texts.t("ui.fight", {"n": run.fight, "max": Config.LAST_FIGHT}), 20, Kit.MUTED)
	enemy_info.add_child(fight_l)
	enemy_info.add_child(Kit.hp_bar(e.max_hp, e.hp, Kit.DANGER))
	enemy_info.add_child(Kit.label(Texts.t("ui.hp", {"hp": maxi(0, e.hp), "max": e.max_hp}) + _shield_text(e), 22))
	var items := "Ataque: " + Texts.item_name(e.attack_id)
	if e.defense_id != "":
		items += "   Defesa: " + Texts.item_name(e.defense_id)
	enemy_info.add_child(Kit.label(items, 20, Kit.MUTED, true))
	if e.boss_id != "":
		enemy_info.add_child(Kit.label("★ " + Texts.boss_desc(e.boss_id), 20, Kit.ACCENT, true))

	Kit.clear(player_info)
	var p := duel.player
	player_info.add_child(Kit.hp_bar(p.max_hp, p.hp, Kit.OK))
	var line := Texts.t("ui.hp", {"hp": maxi(0, p.hp), "max": p.max_hp}) + _shield_text(p)
	line += "   " + Texts.t("ui.coins", {"n": run.coins})
	player_info.add_child(Kit.label(line, 22))
	var extras := []
	for id in p.passives:
		extras.append(Texts.item_name(id))
	if p.death_defy:
		extras.append(Texts.item_name("DEATH_DEFY"))
	if not extras.is_empty():
		player_info.add_child(Kit.label(" · ".join(extras), 18, Kit.MUTED, true))


func _shield_text(f: Fighter) -> String:
	var s := ""
	if f.round_shield + f.placa_shield > 0:
		s += "   " + Texts.t("ui.shield", {"n": f.round_shield + f.placa_shield})
	if f.barrier > 0:
		s += "   " + Texts.t("ui.barrier", {"n": f.barrier})
	return s


func _render_enemy_dice(values: Array, sides: Array, choice: TurnChoice) -> void:
	Kit.clear(enemy_dice_row)
	for i in values.size():
		var v := DieView.new()
		v.interactive = false
		v.setup(i, values[i], sides[i] if i < sides.size() else 6, 64)
		if choice != null:
			if i in choice.attack:
				v.set_state("attack")
			elif i in choice.defense:
				v.set_state("defense")
			else:
				v.set_state("self")
		enemy_dice_row.add_child(v)


func _render_tray(values: Array, sides: Array) -> void:
	Kit.clear(tray)
	tray_views = []
	for i in values.size():
		var v := DieView.new()
		v.setup(i, values[i], sides[i], 100)
		v.tapped.connect(_on_die_tapped)
		v.released.connect(_on_die_released)
		tray.add_child(v)
		tray_views.append(v)


func _render_slots() -> void:
	var p := duel.player
	Kit.clear(attack_content)
	attack_content.add_child(Kit.label(Texts.t("ui.attack_slot"), 18, Kit.MUTED))
	attack_content.add_child(Kit.label(Texts.item_name(p.attack_id), 24, Kit.TEXT, true))
	attack_content.add_child(Kit.label(Texts.item_desc(p.attack_id), 17, Kit.MUTED, true))
	var row := Kit.hbox(4)
	for i in launched + staged:
		var mini := DieView.new()
		mini.interactive = false
		mini.setup(i, duel.player.dice[i], duel.player.dice_sides[i], 46)
		mini.set_state("launched" if i in launched else "staged")
		row.add_child(mini)
	attack_content.add_child(row)

	Kit.clear(defense_content)
	defense_content.add_child(Kit.label(Texts.t("ui.defense_slot"), 18, Kit.MUTED))
	if p.defense_id == "":
		defense_content.add_child(Kit.label(Texts.t("ui.no_defense"), 22, Kit.MUTED, true))
	else:
		defense_content.add_child(Kit.label(Texts.item_name(p.defense_id), 24, Kit.TEXT, true))
		defense_content.add_child(Kit.label(Texts.item_desc(p.defense_id), 17, Kit.MUTED, true))
		var drow := Kit.hbox(4)
		for i in defense:
			var mini := DieView.new()
			mini.interactive = false
			mini.setup(i, duel.player.dice[i], duel.player.dice_sides[i], 46)
			mini.set_state("defense")
			drow.add_child(mini)
		defense_content.add_child(drow)


func _refresh() -> void:
	for v in tray_views:
		var i: int = v.index
		if i in launched:
			v.set_state("launched")
		elif i in staged:
			v.set_state("staged")
		elif i in defense:
			v.set_state("defense")
		elif i == selected:
			v.set_state("selected")
		else:
			v.set_state("free")
	_render_slots()
	var used := launched.size() + staged.size() + defense.size()
	var self_sum := 0
	for i in duel.player.dice.size():
		if not (i in launched) and not (i in staged) and not (i in defense):
			self_sum += duel.player.dice[i]
	if used > 0:
		hint.text = Texts.t("ui.self_damage", {"sum": self_sum}) + "  ·  ativos %d/%d" % [used, Config.MAX_ACTIVE]


func _set_hint_default() -> void:
	hint.text = Texts.t("ui.swipe_hint_group" if Items.is_group_launch(duel.player.attack_id) else "ui.swipe_hint_single")


func _set_log(lines: Array) -> void:
	log_label.text = "\n".join(lines)


# ------------------------------------------------------------------ Entrada
func _used() -> int:
	return launched.size() + staged.size() + defense.size()


func _is_group() -> bool:
	return Items.is_group_launch(duel.player.attack_id)


func _on_die_tapped(v: DieView) -> void:
	if locked:
		return
	var i := v.index
	if i in staged:
		staged.erase(i)
	elif i in defense:
		defense.erase(i)
	elif selected == i:
		selected = -1
	else:
		selected = i
	_refresh()


func _on_die_released(v: DieView, pos: Vector2, d: Vector2) -> void:
	if locked:
		return
	var i := v.index
	selected = -1
	if defense_slot.get_global_rect().has_point(pos):
		_fit_defense(i)
	elif attack_slot.get_global_rect().has_point(pos) or (d.y < -60.0 and absf(d.y) > absf(d.x)):
		if _is_group():
			if i in staged:
				_launch_group()
			else:
				_stage(i)
		else:
			_launch(i)
	_refresh()


func _on_attack_slot_input(e: InputEvent) -> void:
	if locked or not (e is InputEventMouseButton) or e.button_index != MOUSE_BUTTON_LEFT:
		return
	if e.pressed:
		_slot_press = e.global_position
		return
	var d: Vector2 = e.global_position - _slot_press
	if d.y < -50.0 and _is_group() and not staged.is_empty():
		_launch_group()
	elif d.length() < 16.0 and selected != -1:
		var i := selected
		selected = -1
		if _is_group():
			_stage(i)
		else:
			_launch(i)
	_refresh()


func _on_defense_slot_input(e: InputEvent) -> void:
	if locked or not (e is InputEventMouseButton) or e.button_index != MOUSE_BUTTON_LEFT or e.pressed:
		return
	if selected != -1:
		var i := selected
		selected = -1
		_fit_defense(i)
	elif not defense.is_empty():
		defense.clear()
	_refresh()


func _has_room_for(i: int) -> bool:
	var used := _used()
	if i in staged or i in defense:
		used -= 1
	if used >= Config.MAX_ACTIVE:
		hint.text = "Máximo de %d dados ativos." % Config.MAX_ACTIVE
		return false
	return true


func _stage(i: int) -> void:
	if group_done or i in launched or i in staged:
		return
	if not _has_room_for(i):
		return
	defense.erase(i)
	staged.append(i)


func _fit_defense(i: int) -> void:
	if duel.player.defense_id == "" or i in launched:
		return
	var old: Array = defense.duplicate()
	defense.clear()
	if not _has_room_for(i):
		defense = old
		return
	staged.erase(i)
	defense = [i]
	if not Items.defense_accepts(duel.player.defense_id, duel.player.dice[i]):
		hint.text = Texts.t("log.def_invalid", {"who": "Atenção", "item": Texts.item_name(duel.player.defense_id), "n": duel.player.dice[i]})


func _launch(i: int) -> void:
	if group_done or i in launched:
		return
	if not _has_room_for(i):
		return
	defense.erase(i)
	launched.append(i)
	_fly(tray_views[i], enemy_info)
	_refresh()
	if launched.size() + defense.size() >= Config.MAX_ACTIVE:
		_auto_submit()


func _launch_group() -> void:
	if staged.is_empty() or group_done:
		return
	for i in staged:
		launched.append(i)
		_fly(tray_views[i], enemy_info)
	staged.clear()
	group_done = true
	_refresh()
	if launched.size() + defense.size() >= Config.MAX_ACTIVE:
		_auto_submit()


func _auto_submit() -> void:
	locked = true
	await get_tree().create_timer(0.45).timeout
	_submit()


func _on_end_turn_pressed() -> void:
	if locked:
		return
	var used := launched.size() + defense.size()
	if used >= Config.MAX_ACTIVE and staged.is_empty():
		_submit()
		return
	var n := duel.player.dice.size() - used
	var s := 0
	for i in duel.player.dice.size():
		if not (i in launched) and not (i in defense):
			s += duel.player.dice[i]
	var dlg := ConfirmationDialog.new()
	dlg.dialog_text = Texts.t("ui.end_turn_warn", {"n": n, "sum": s})
	dlg.ok_button_text = Texts.t("ui.confirm")
	dlg.cancel_button_text = Texts.t("ui.cancel")
	dlg.confirmed.connect(_submit)
	add_child(dlg)
	dlg.popup_centered(Vector2i(560, 260))


# ------------------------------------------------------------------ Resolução
func _submit() -> void:
	locked = true
	staged.clear()
	var snap := {
		"pdice": duel.player.dice.duplicate(), "psides": duel.player.dice_sides.duplicate(),
		"edice": duel.enemy.dice.duplicate(), "esides": duel.enemy.dice_sides.duplicate(),
	}
	var rep := duel.submit(TurnChoice.make(launched, defense))
	if rep.has("error"):
		hint.text = str(rep.error)
		locked = false
		return
	# Salva já com o próximo turno rolado: fechar o app não rerrola nada.
	if duel.state == "choosing":
		duel.begin_turn()
		SaveGame.save(run)
	else:
		run.finish_duel()
		if run.phase in ["victory", "defeat"]:
			SaveGame.clear()
		else:
			SaveGame.save(run)
	_show_result(rep, snap)


func _show_result(rep: Dictionary, snap: Dictionary) -> void:
	var ec: TurnChoice = rep.enemy_choice
	_render_enemy_dice(snap.edice, snap.esides, ec)
	for v in enemy_dice_row.get_children():
		if v.index in ec.attack:
			_fly(v, player_info)
	_render_info()
	_set_log(rep.log)
	Kit.clear(action_row)
	var b: Button
	match duel.state:
		"choosing":
			hint.text = ""
			b = Kit.button(Texts.t("ui.next_turn"), _new_turn_ui, Kit.PANEL_HI)
		"won":
			hint.text = Texts.t("ui.won_duel", {"name": duel.enemy.name, "coins": run.last_reward})
			var label := Texts.t("ui.to_shop") if run.phase == "shop" else Texts.t("ui.victory_title")
			b = Kit.button(label, func(): finished.emit(), Kit.OK.darkened(0.4))
		_:
			hint.text = Texts.t("ui.defeat_title")
			b = Kit.button(Texts.t("ui.defeat_title"), func(): finished.emit(), Kit.DANGER.darkened(0.4))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(b)


## Único efeito animado: o dado voa até o alvo e some (wow factor).
func _fly(from: Control, to: Control) -> void:
	if not is_inside_tree() or not (from is DieView):
		return
	var src := from as DieView
	var ghost := DieView.new()
	ghost.interactive = false
	ghost.setup(-1, src.value, src.sides, int(src.size.x))
	ghost.set_state("attack" if src.state != "launched" else "selected")
	overlay.add_child(ghost)
	ghost.global_position = src.global_position
	var target := to.get_global_rect().get_center() - ghost.size / 2.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(ghost, "global_position", target, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(ghost, "modulate:a", 0.0, 0.35).set_delay(0.15)
	tw.chain().tween_callback(ghost.queue_free)
