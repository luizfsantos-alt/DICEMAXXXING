class_name DuelScreen
extends Control
## Tela do duelo em paisagem (docs/SPEC.md §10).
##
## Fases do turno:
## - "player":  você põe dados nos slots do seu equipamento (palco central).
## - "enemy":   o equipamento do inimigo aparece e os dados dele voam para os slots (não pulável).
## - "resolve": o palco some e os eventos do motor são animados na ordem oficial (tocar pula).
## - "between": pausa curta antes do próximo turno (tocar adianta).
## - "over":    aviso de vitória ou derrota.

signal finished

const DIE := 92 ## Dado do jogador.
const EDIE := 60 ## Dado do inimigo.
const SLOT := 104
const PARALLEL := ["attack", "damage", "self"] ## Tipos simultâneos na regra (etapas F, J e L).

var run: RunState
var duel: Duel
var fast := false ## Testes: sem esperas.

var phase := "player"
var attack: Array = [] ## Índices dos dados nos slots de ataque, em ordem (slot 1, 2, 3).
var defense: int = -1
var skip := false
var shown := {} ## Valores exibidos nas barras: side -> {hp, max, shield, barrier}.
var seq := 0 ## Invalida animações de início de turno antigas.
var last_log: Array = []
var snap := {} ## Dados do turno em resolução (o próximo turno já foi rolado).

# Nós.
var hud_label: Label
var log_panel: PanelContainer
var log_label: RichTextLabel
var bars := {} ## side -> HpBar
var portraits := {} ## side -> PanelContainer
var enemy_tray: HBoxContainer
var tray: HBoxContainer
var tray_views: Array = []
var enemy_views: Array = []
var stage: HBoxContainer
var atk_panel: PanelContainer
var atk_title: Label
var atk_slots: Array = []
var def_panel: PanelContainer
var def_title: Label
var def_slot: PanelContainer
var end_btn: Button
var info_label: Label
var fx: Control
var catcher: Control
var end_overlay: Control


func setup(r: RunState) -> DuelScreen:
	run = r
	duel = r.duel
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	_sync_shown()
	_new_turn([])
	return self


# ================================================================== Layout
func _build() -> void:
	var root := Kit.vbox(10)
	var m := Kit.margin(root, 12)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)

	# --- Topo: HUD, barra e dados do inimigo | retrato do inimigo.
	var top := Kit.hbox(16)
	root.add_child(top)
	var top_left := Kit.vbox(8)
	top_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(top_left)
	var hud_row := Kit.hbox(12)
	hud_label = Kit.label("", 20, Kit.MUTED)
	hud_row.add_child(hud_label)
	if OS.is_debug_build():
		var lb := Kit.button(Texts.t("ui.log_button"), _toggle_log, Kit.PANEL_HI, 18)
		lb.custom_minimum_size = Vector2(70, 32)
		hud_row.add_child(lb)
	top_left.add_child(hud_row)
	top_left.add_child(_bar_row("enemy"))
	enemy_tray = Kit.hbox(8)
	top_left.add_child(enemy_tray)
	top.add_child(_portrait("enemy"))

	# --- Centro: palco (ataque retangular + defesa circular).
	var mid := CenterContainer.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(mid)
	stage = Kit.hbox(28)
	stage.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_child(stage)
	atk_panel = Kit.panel(Color(0.3, 0.13, 0.15))
	var av := Kit.vbox(6)
	atk_panel.add_child(av)
	atk_title = Kit.label("", 20, Kit.TEXT)
	atk_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	av.add_child(atk_title)
	var srow := Kit.hbox(10)
	av.add_child(srow)
	for k in Items.ATTACK_MAX_DICE:
		var s := _slot_box()
		srow.add_child(s)
		atk_slots.append(s)
	stage.add_child(atk_panel)
	def_panel = PanelContainer.new()
	def_panel.custom_minimum_size = Vector2(196, 196)
	def_panel.add_theme_stylebox_override("panel", Kit.box(Color(0.12, 0.2, 0.32), 98, 12))
	var dv := Kit.vbox(4)
	dv.alignment = BoxContainer.ALIGNMENT_CENTER
	def_panel.add_child(dv)
	def_title = Kit.label("", 16, Kit.TEXT, true)
	def_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	def_title.custom_minimum_size = Vector2(150, 0)
	dv.add_child(def_title)
	var dc := CenterContainer.new()
	def_slot = _slot_box()
	dc.add_child(def_slot)
	dv.add_child(dc)
	stage.add_child(def_panel)

	# --- Botão "Terminar turno", sempre abaixo do palco.
	var brow := Kit.hbox(16)
	brow.alignment = BoxContainer.ALIGNMENT_CENTER
	info_label = Kit.label("", 20, Kit.MUTED)
	info_label.custom_minimum_size = Vector2(380, 0)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	brow.add_child(info_label)
	end_btn = Kit.button(Texts.t("ui.end_turn"), _on_end_turn_pressed, Kit.ACCENT.darkened(0.55), 26)
	end_btn.custom_minimum_size = Vector2(320, 64)
	brow.add_child(end_btn)
	var pad := Control.new()
	pad.custom_minimum_size = Vector2(380, 0)
	brow.add_child(pad)
	root.add_child(brow)

	# --- Base: retrato do jogador | bandeja e barra do jogador.
	var bottom := Kit.hbox(16)
	root.add_child(bottom)
	bottom.add_child(_portrait("player"))
	var br := Kit.vbox(8)
	br.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(br)
	tray = Kit.hbox(10)
	tray.alignment = BoxContainer.ALIGNMENT_CENTER
	tray.custom_minimum_size = Vector2(0, DIE)
	br.add_child(tray)
	br.add_child(_bar_row("player"))

	# --- Camadas: efeitos, toque para pular, log de debug.
	fx = Control.new()
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fx)
	catcher = Control.new()
	catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
	catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	catcher.visible = false
	catcher.gui_input.connect(_on_catcher_input)
	add_child(catcher)
	log_panel = Kit.panel(Color(0.06, 0.05, 0.08, 0.96))
	log_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	log_panel.visible = false
	log_label = RichTextLabel.new()
	log_label.bbcode_enabled = false
	log_label.scroll_following = true
	log_label.add_theme_font_size_override("normal_font_size", 20)
	log_label.add_theme_color_override("default_color", Kit.MUTED)
	var lv := Kit.vbox(8)
	var close := Kit.button(Texts.t("ui.log_button") + "  ✕", _toggle_log, Kit.PANEL_HI, 18)
	close.custom_minimum_size = Vector2(0, 40)
	lv.add_child(close)
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.add_child(log_label)
	log_panel.add_child(lv)
	add_child(log_panel)


func _slot_box() -> PanelContainer:
	var s := PanelContainer.new()
	s.custom_minimum_size = Vector2(SLOT, SLOT)
	s.add_theme_stylebox_override("panel", Kit.box(Color(0, 0, 0, 0.3), 12, 6))
	return s


func _bar_row(side: String) -> HBoxContainer:
	var row := Kit.hbox(10)
	row.name = "BarRow_" + side
	var bar := HpBar.new().setup(Kit.DANGER if side == "enemy" else Kit.OK)
	bars[side] = bar
	row.add_child(bar)
	return row


func _portrait(side: String) -> PanelContainer:
	var p := Kit.panel(Color(0.2, 0.17, 0.25) if side == "enemy" else Color(0.17, 0.2, 0.25))
	p.custom_minimum_size = Vector2(230, 140 if side == "enemy" else 110)
	var v := Kit.vbox(2)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(v)
	portraits[side] = p
	return p


func _fill_portraits() -> void:
	var e := duel.enemy
	var ev: VBoxContainer = portraits.enemy.get_child(0)
	Kit.clear(ev)
	if e.boss_id != "":
		ev.add_child(Kit.label("★ " + Texts.t("ui.boss"), 16, Kit.ACCENT))
	ev.add_child(Kit.label(e.name, 20, Kit.TEXT, true))
	ev.add_child(Kit.label(Texts.t("ui.front_view"), 14, Kit.MUTED))
	var pv: VBoxContainer = portraits.player.get_child(0)
	Kit.clear(pv)
	pv.add_child(Kit.label(Texts.t("ui.you"), 22, Kit.TEXT))
	pv.add_child(Kit.label(Texts.t("ui.back_view"), 14, Kit.MUTED))


# ================================================================== Valores exibidos
func _fighter(side: String) -> Fighter:
	return duel.player if side == "player" else duel.enemy


func _state_of(f: Fighter) -> Dictionary:
	return {"hp": f.hp, "max": f.max_hp, "shield": f.round_shield + f.placa_shield, "barrier": f.barrier}


func _sync_shown() -> void:
	shown = {"player": _state_of(duel.player), "enemy": _state_of(duel.enemy)}
	_draw_bars()


func _draw_bars() -> void:
	for side in bars:
		var s: Dictionary = shown[side]
		bars[side].set_values(s.max, s.hp, s.shield, s.barrier)
	hud_label.text = Texts.t("ui.hud", {"n": run.fight, "max": Config.LAST_FIGHT, "coins": run.coins})


# ================================================================== Seu turno
func _new_turn(start_events: Array) -> void:
	phase = "player"
	seq += 1
	attack = []
	defense = -1
	skip = false
	catcher.visible = false
	Kit.clear(fx)
	stage.modulate.a = 1.0
	_fill_portraits()
	_render_trays()
	_render_stage_player()
	_refresh()
	_set_log(last_log + duel.turn_log)
	end_btn.disabled = false
	end_btn.visible = true
	if not start_events.is_empty():
		_play_start(start_events, seq)


func _render_trays() -> void:
	Kit.clear(tray)
	tray_views = []
	var p := duel.player
	for i in p.dice.size():
		var v := DieView.new()
		v.setup(i, p.dice[i], p.dice_sides[i], DIE)
		v.tapped.connect(_on_die_tapped)
		v.released.connect(_on_die_released)
		tray.add_child(v)
		tray_views.append(v)
	Kit.clear(enemy_tray)
	enemy_views = []
	var e := duel.enemy
	for i in e.dice.size():
		var v := DieView.new()
		v.interactive = false
		v.setup(i, e.dice[i], e.dice_sides[i] if i < e.dice_sides.size() else 6, EDIE)
		enemy_tray.add_child(v)
		enemy_views.append(v)


func _render_stage_player() -> void:
	var p := duel.player
	atk_panel.add_theme_stylebox_override("panel", Kit.box(Color(0.3, 0.13, 0.15)))
	atk_title.text = Texts.t("ui.attack_title", {"item": Texts.item_name(p.attack_id)})
	def_panel.add_theme_stylebox_override("panel", Kit.box(Color(0.12, 0.2, 0.32), 98, 12))
	def_title.text = Texts.item_name(p.defense_id) if p.defense_id != "" else Texts.t("ui.no_defense")
	def_slot.modulate.a = 1.0 if p.defense_id != "" else 0.3


func _clear_slot(s: PanelContainer, mark: String) -> void:
	Kit.clear(s)
	if mark != "":
		var l := Kit.label(mark, 22, Color(1, 1, 1, 0.35))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		s.add_child(l)


func _slot_mark(attack_id: String, k: int) -> String:
	return "×2" if attack_id == "A5" and k == 0 else str(k + 1)


func _refresh() -> void:
	var p := duel.player
	for k in atk_slots.size():
		var s: PanelContainer = atk_slots[k]
		if k < attack.size():
			Kit.clear(s)
			s.add_child(_placed_view(attack[k], "staged"))
		else:
			_clear_slot(s, _slot_mark(p.attack_id, k))
	if defense != -1:
		Kit.clear(def_slot)
		def_slot.add_child(_placed_view(defense, "defense"))
	else:
		_clear_slot(def_slot, "")
	for v in tray_views:
		v.set_state("launched" if (v.index in attack or v.index == defense) else "free")
	var used := _used()
	if used == 0:
		info_label.text = Texts.t("ui.place_hint")
	else:
		info_label.text = Texts.t("ui.active_count", {"sum": _self_sum(), "n": used, "max": Config.MAX_ACTIVE})


func _placed_view(i: int, state: String) -> DieView:
	var v := DieView.new()
	v.setup(i, duel.player.dice[i], duel.player.dice_sides[i], DIE)
	v.set_state(state)
	v.tapped.connect(_on_die_tapped)
	v.released.connect(_on_die_released)
	return v


func _used() -> int:
	return attack.size() + (1 if defense != -1 else 0)


func _self_sum() -> int:
	var s := 0
	for i in duel.player.dice.size():
		if not (i in attack) and i != defense:
			s += duel.player.dice[i]
	return s


# ------------------------------------------------------------------ Entrada
func _on_die_tapped(v: DieView) -> void:
	if phase != "player":
		return
	var i := v.index
	if i in attack or i == defense:
		_return(i)
	else:
		_place_attack(i)


func _on_die_released(v: DieView, pos: Vector2, _d: Vector2) -> void:
	if phase != "player":
		return
	var i := v.index
	for k in atk_slots.size():
		if atk_slots[k].get_global_rect().has_point(pos):
			_place_attack(i, k)
			return
	if atk_panel.get_global_rect().has_point(pos):
		_place_attack(i)
	elif def_panel.get_global_rect().has_point(pos):
		_place_defense(i)
	elif i in attack or i == defense:
		_return(i)


func _hint(text: String) -> void:
	info_label.text = text


func _return(i: int) -> void:
	attack.erase(i)
	if defense == i:
		defense = -1
	_refresh()


## Põe o dado `i` no ataque, no slot `at` (ou no fim). Os demais deslizam.
func _place_attack(i: int, at: int = -1) -> void:
	var was_def := defense == i
	var old_pos := attack.find(i)
	attack.erase(i)
	if was_def:
		defense = -1
	if _used() >= Config.MAX_ACTIVE or attack.size() >= Items.ATTACK_MAX_DICE:
		# Sem espaço: desfaz.
		if old_pos != -1:
			attack.insert(old_pos, i)
		if was_def:
			defense = i
		_refresh()
		_hint(Texts.t("ui.max_active", {"n": Config.MAX_ACTIVE}))
		return
	if at < 0 or at > attack.size():
		at = attack.size()
	attack.insert(at, i)
	_refresh()


func _place_defense(i: int) -> void:
	var p := duel.player
	if p.defense_id == "":
		return
	var old_pos := attack.find(i)
	attack.erase(i)
	var old_def := defense
	defense = -1
	if _used() >= Config.MAX_ACTIVE:
		if old_pos != -1:
			attack.insert(old_pos, i)
		defense = old_def
		_refresh()
		_hint(Texts.t("ui.max_active", {"n": Config.MAX_ACTIVE}))
		return
	defense = i
	_refresh()
	if not Items.defense_accepts(p.defense_id, p.dice[i]):
		_hint(Texts.t("log.def_invalid", {"who": "Atenção", "item": Texts.item_name(p.defense_id), "n": p.dice[i]}))


func _on_end_turn_pressed() -> void:
	if phase != "player":
		return
	if _used() >= Config.MAX_ACTIVE:
		_submit()
		return
	var dlg := ConfirmationDialog.new()
	dlg.dialog_text = Texts.t("ui.end_turn_warn", {"n": duel.player.dice.size() - _used(), "sum": _self_sum()})
	dlg.ok_button_text = Texts.t("ui.confirm")
	dlg.cancel_button_text = Texts.t("ui.cancel")
	dlg.confirmed.connect(_submit)
	add_child(dlg)
	dlg.popup_centered(Vector2i(620, 220))


# ================================================================== Resolução
func _submit() -> void:
	if phase != "player":
		return
	seq += 1
	var choice := TurnChoice.make(attack, [defense] if defense != -1 else [])
	snap = {
		"pdice": duel.player.dice.duplicate(), "psides": duel.player.dice_sides.duplicate(),
		"edice": duel.enemy.dice.duplicate(), "esides": duel.enemy.dice_sides.duplicate(),
	}
	_sync_shown()
	var rep := duel.submit(choice)
	if rep.has("error"):
		_hint(str(rep.error))
		return
	phase = "enemy"
	end_btn.disabled = true
	var post := {"player": _state_of(duel.player), "enemy": _state_of(duel.enemy)}
	var start_events: Array = []
	# Salva já com o próximo turno rolado: fechar o app não rerrola nada.
	if duel.state == "choosing":
		duel.begin_turn()
		start_events = duel.turn_events
		SaveGame.save(run)
	else:
		run.finish_duel()
		if run.phase in ["victory", "defeat"]:
			SaveGame.clear()
		else:
			SaveGame.save(run)
	last_log = rep.log
	_set_log(last_log)

	await _enemy_phase(rep.enemy_choice)
	if not _alive():
		return
	await _resolve_phase(rep, choice, post)
	if not _alive():
		return
	if duel.state == "choosing":
		phase = "between"
		skip = false
		catcher.visible = true
		await _wait(0.5)
		if not _alive():
			return
		_new_turn(start_events)
	else:
		_show_end()


func _alive() -> bool:
	return is_inside_tree() and not is_queued_for_deletion()


func _wait(t: float, skippable := true) -> void:
	if not _alive():
		return
	if fast or t <= 0.0:
		await get_tree().process_frame
		return
	var end := Time.get_ticks_msec() + int(t * 1000.0)
	while Time.get_ticks_msec() < end:
		if skippable and skip:
			return
		await get_tree().process_frame
		if not _alive():
			return


func _on_catcher_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		skip = true
		accept_event()


## Fase do inimigo: equipamento dele no palco e dados voando para os slots. Não pulável.
func _enemy_phase(ec: TurnChoice) -> void:
	var e := duel.enemy
	info_label.text = Texts.t("ui.enemy_turn")
	end_btn.visible = false
	for v in tray_views:
		v.set_state("launched")
	atk_panel.add_theme_stylebox_override("panel", Kit.box(Color(0.36, 0.1, 0.22)))
	atk_title.text = Texts.t("ui.attack_title", {"item": Texts.item_name(e.attack_id)})
	def_panel.add_theme_stylebox_override("panel", Kit.box(Color(0.2, 0.14, 0.34), 98, 12))
	def_title.text = Texts.item_name(e.defense_id) if e.defense_id != "" else Texts.t("ui.no_defense")
	def_slot.modulate.a = 1.0 if e.defense_id != "" else 0.3
	for k in atk_slots.size():
		_clear_slot(atk_slots[k], _slot_mark(e.attack_id, k))
	_clear_slot(def_slot, "")
	await _wait(0.25, false)
	var targets := []
	for k in ec.attack.size():
		targets.append([ec.attack[k], atk_slots[k], "attack"])
	for i in ec.defense:
		targets.append([i, def_slot, "defense"])
	for t in targets:
		if not _alive():
			return
		var i: int = t[0]
		var slot: PanelContainer = t[1]
		var src: DieView = enemy_views[i]
		_fly_ghost(src.global_position, src.size.x, slot.global_position + Vector2(6, 6), SLOT - 12,
			snap.edice[i], snap.esides[i], t[2], 0.2)
		src.set_state("launched")
		await _wait(0.22, false)
		if not _alive():
			return
		Kit.clear(slot)
		var v := DieView.new()
		v.interactive = false
		v.setup(i, snap.edice[i], snap.esides[i], SLOT - 12)
		v.set_state(t[2])
		slot.add_child(v)
	await _wait(0.3, false)


## Resolução: o palco some; cada evento vira um efeito visual, na ordem oficial.
func _resolve_phase(rep: Dictionary, pc: TurnChoice, post: Dictionary) -> void:
	phase = "resolve"
	skip = false
	catcher.visible = true
	info_label.text = ""
	stage.modulate.a = 0.0
	# Bandejas mostram o papel de cada dado: ataque, defesa, autodano.
	var ec: TurnChoice = rep.enemy_choice
	for side in ["player", "enemy"]:
		var views: Array = tray_views if side == "player" else enemy_views
		var c: TurnChoice = pc if side == "player" else ec
		var vals: Array = snap.pdice if side == "player" else snap.edice
		for v in views:
			v.value = vals[v.index]
			v.set_state("attack" if v.index in c.attack else ("defense" if v.index in c.defense else "self"))
	var events: Array = rep.events
	var k := 0
	while k < events.size() and not skip:
		var ev: Dictionary = events[k]
		var dur := _play(ev)
		# Etapas simultâneas na regra animam juntas.
		while ev.t in PARALLEL and k + 1 < events.size() and events[k + 1].t == ev.t:
			k += 1
			dur = maxf(dur, _play(events[k]))
		k += 1
		await _wait(dur)
		if not _alive():
			return
	Kit.clear(fx)
	shown = post
	_draw_bars()
	for side in ["player", "enemy"]:
		var views: Array = tray_views if side == "player" else enemy_views
		for v in views:
			if v.state == "self":
				v.set_state("launched")
	catcher.visible = false


## Efeitos do início do turno (curas, escudos, dados alterados): destaque breve, sem travar.
func _play_start(events: Array, my_seq: int) -> void:
	for ev in events:
		if seq != my_seq or not _alive():
			return
		await _wait(_play(ev) * 0.8, false)
	if seq == my_seq and _alive():
		_sync_shown()


# ------------------------------------------------------------------ Um evento
## Dispara o efeito visual de um evento e devolve quanto tempo ele pede.
func _play(ev: Dictionary) -> float:
	var side: String = ev.side
	var other := "enemy" if side == "player" else "player"
	var n := int(ev.get("n", 0))
	var src: String = str(ev.get("src", ""))
	match ev.t:
		"heal":
			_hp(side, n)
			return 0.35
		"shield":
			shown[side].shield += n
			_draw_bars()
			_float_at_bar(side, Texts.t("ui.fx_shield", {"n": n}), Kit.SHIELD)
			return 0.35
		"barrier":
			shown[side].barrier = int(ev.get("total", shown[side].barrier + n))
			_draw_bars()
			_float_at_bar(side, Texts.t("ui.barrier", {"n": shown[side].barrier}), Kit.SHIELD)
			return 0.35
		"proc":
			_pulse(side, src)
			if src in ["DD10", "DF9"]:
				return 0.12
			_float_at_portrait(side, _src_name(src), Kit.ACCENT)
			return 0.35
		"coin":
			_pulse(side, src)
			_float_at(hud_label.get_global_rect().get_center(), Texts.t("ui.fx_coin", {"n": n}), Kit.ACCENT)
			return 0.3
		"dice_change":
			var v := _die(side, int(ev.die))
			if v:
				v.value = int(ev.to)
				v.queue_redraw()
				_ring(v, Kit.ACCENT)
			_pulse(side, src)
			return 0.35
		"chain", "chapeu":
			if ev.t == "chapeu":
				_pulse(side, "DF8")
				_float_at_portrait(side, _src_name("DF8"), Kit.ACCENT)
				if ev.get("effect", "") != "chain":
					return 0.4
			var views: Array = tray_views if side == "player" else enemy_views
			if ev.t == "chain":
				var a: DieView = views[int(ev.active)]
				var b: DieView = views[int(ev.self)]
				fx.add_child(Fx.chain(_center(a), _center(b), a.size.x * 0.62))
				var st := a.state
				a.set_state("self")
				b.set_state(st)
			else:
				var pr: Control = portraits[side]
				var c := _center(pr)
				fx.add_child(Fx.chain(c + Vector2(-70, 0), c + Vector2(70, 0), 30.0, true))
			return 0.7
		"def_invalid":
			var v := _die(side, int(ev.die))
			if v:
				_mark(v, "cross", Kit.MUTED)
				_float_at(_center(v), Texts.t("ui.fx_invalid"), Kit.MUTED)
			return 0.35
		"annul":
			var v := _die(side, int(ev.die))
			if v:
				_mark(v, "cross", Kit.DANGER)
			return 0.3
		"reduce_die":
			for i in ev.get("dice", []):
				var v := _die(side, int(i))
				if v:
					_float_at(_center(v), "−%d" % n, Kit.SHIELD)
			return 0.3
		"explode":
			var v := _die(side, int(ev.die))
			if v:
				_ring(v, Color(1.0, 0.55, 0.15))
				_float_at(_center(v), "BOOM +%d" % n, Color(1.0, 0.6, 0.2))
			return 0.4
		"attack":
			var dice: Array = ev.get("dice", [])
			if dice.is_empty():
				return 0.0
			var from := _center(portraits[side])
			var to := _center(portraits[other])
			var eff: Array = ev.get("eff", [])
			var f := _fighter(side)
			for j in dice.size():
				var idx: int = dice[j]
				var sides: int = f.dice_sides[idx] if idx < f.dice_sides.size() else 6
				var val: int = eff[j] if j < eff.size() else 0
				_fly_ghost(from + Vector2((j - 1) * 30, 0) - Vector2(30, 30), 60, to - Vector2(30, 30), 60,
					val, sides, "attack", 0.4 + j * 0.05)
			_float_at(to + Vector2(0, -60), str(n), Kit.DANGER.lightened(0.2), 34)
			return 0.6
		"mirror":
			var idx := int(ev.die)
			var vals: Array = snap.pdice if side == "player" else snap.edice
			var sides_l: Array = snap.psides if side == "player" else snap.esides
			var sides: int = sides_l[idx] if idx < sides_l.size() else 6
			var from := _center(portraits[other])
			var to := _center(portraits[side])
			_fly_ghost(from - Vector2(30, 30), 60, to - Vector2(30, 30), 60, vals[idx], sides, "mirror", 0.45)
			_pulse(other, src)
			_float_at(to + Vector2(0, -40), Texts.t("ui.fx_reflected", {"n": n}), Color(0.85, 0.88, 0.95))
			return 0.6
		"thorns":
			var pr: Control = portraits[other]
			fx.add_child(Fx.make("spikes", pr.get_global_rect().grow(10), Color(0.55, 0.85, 0.4, 0.85)))
			_float_at(_center(portraits[side]), Texts.t("ui.fx_thorns", {"n": n}), Color(0.6, 0.9, 0.45))
			return 0.5
		"block":
			_pulse(side, src)
			_float_at_bar(side, Texts.t("ui.fx_blocked", {"n": n}), Kit.SHIELD)
			return 0.3
		"absorb":
			var s: Dictionary = shown[side]
			var bar_used: int = maxi(0, s.barrier - int(ev.get("barrier", s.barrier)))
			s.barrier = int(ev.get("barrier", s.barrier))
			s.shield = maxi(0, s.shield - maxi(0, n - bar_used))
			_draw_bars()
			_float_at_bar(side, Texts.t("ui.fx_absorb", {"n": n}), Kit.SHIELD)
			return 0.3
		"damage":
			_hp(side, -n)
			_shake(portraits[side])
			return 0.45
		"self":
			var views: Array = tray_views if side == "player" else enemy_views
			for i in ev.get("dice", []):
				if int(i) < views.size():
					views[int(i)].set_state("launched")
			if n > 0:
				shown[side].hp -= n
				_draw_bars()
				_float_at_bar(side, Texts.t("ui.fx_self", {"n": n}), Color(0.75, 0.55, 0.95))
			return 0.45 if n > 0 else 0.15
		"death_defy":
			shown[side].hp = int(ev.get("hp", shown[side].max))
			_draw_bars()
			_float_at(_center(portraits[side]), Texts.t("ui.fx_death_defy"), Kit.ACCENT, 34)
			_ring(portraits[side], Kit.ACCENT)
			return 0.9
		"turn_limit":
			_float_at(get_global_rect().get_center(), Texts.t("ui.fx_turn_limit"), Kit.DANGER, 36)
			return 0.8
	return 0.0


func _src_name(src: String) -> String:
	if Texts.data().get("bosses", {}).has(src):
		return Texts.boss_name(src)
	return Texts.item_name(src)


func _die(side: String, i: int) -> DieView:
	var views: Array = tray_views if side == "player" else enemy_views
	return views[i] if i >= 0 and i < views.size() else null


## Passivas, itens e medalha piscam quando agem (preenchido na etapa de quadradinhos).
func _pulse(_side: String, _src: String) -> void:
	pass


func _hp(side: String, delta: int) -> void:
	if delta == 0:
		return
	shown[side].hp = mini(shown[side].max, shown[side].hp + delta)
	_draw_bars()
	_float_at_bar(side, ("+%d" % delta) if delta > 0 else ("−%d" % -delta), Kit.OK if delta > 0 else Kit.DANGER, 30)


# ------------------------------------------------------------------ Efeitos
func _center(c: Control) -> Vector2:
	return c.get_global_rect().get_center()


func _float_at_bar(side: String, text: String, color: Color, size_px := 24) -> void:
	var r: Rect2 = bars[side].get_global_rect()
	_float_at(Vector2(r.position.x + r.size.x * 0.5, r.position.y - 4), text, color, size_px)


func _float_at_portrait(side: String, text: String, color: Color) -> void:
	_float_at(_center(portraits[side]) + Vector2(0, -50), text, color, 22)


func _float_at(at: Vector2, text: String, color: Color, size_px := 24) -> void:
	if fast:
		return
	var l := Kit.label(text, size_px, color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 6)
	fx.add_child(l)
	l.reset_size()
	l.global_position = at - l.size / 2.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(l, "global_position:y", l.global_position.y - 46.0, 0.9).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.5)
	tw.chain().tween_callback(l.queue_free)


func _ring(c: Control, color: Color) -> void:
	if fast:
		return
	var f := Fx.make("ring", c.get_global_rect().grow(6), color)
	fx.add_child(f)
	var tw := create_tween()
	tw.tween_property(f, "modulate:a", 0.0, 0.6).set_delay(0.2)
	tw.tween_callback(f.queue_free)


func _mark(c: Control, kind: String, color: Color) -> void:
	fx.add_child(Fx.make(kind, c.get_global_rect(), color))


func _shake(c: Control) -> void:
	if fast:
		return
	var x := c.position.x
	var tw := create_tween()
	for k in 3:
		tw.tween_property(c, "position:x", x + 8.0, 0.04)
		tw.tween_property(c, "position:x", x - 8.0, 0.04)
	tw.tween_property(c, "position:x", x, 0.04)


func _fly_ghost(from: Vector2, from_px: float, to: Vector2, to_px: float, value: int, sides: int, state: String, t: float) -> void:
	if fast:
		return
	var g := DieView.new()
	g.interactive = false
	g.setup(-1, value, sides, int(from_px))
	g.set_state(state)
	fx.add_child(g)
	g.global_position = from
	var s := to_px / maxf(1.0, from_px)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(g, "global_position", to, t).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(g, "scale", Vector2(s, s), t)
	tw.chain().tween_callback(g.queue_free)


# ================================================================== Fim e log
func _show_end() -> void:
	phase = "over"
	catcher.visible = false
	stage.modulate.a = 0.0
	end_overlay = ColorRect.new()
	end_overlay.color = Color(0, 0, 0, 0.6)
	end_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(end_overlay)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	end_overlay.add_child(cc)
	var p := Kit.panel(Kit.PANEL_HI)
	p.custom_minimum_size = Vector2(560, 0)
	var v := Kit.vbox(18)
	p.add_child(v)
	cc.add_child(p)
	var won := duel.state == "won"
	var title := Texts.t("ui.won_duel", {"name": duel.enemy.name, "coins": run.last_reward}) if won else Texts.t("ui.defeat_title")
	var t := Kit.label(title, 30, Kit.OK if won else Kit.DANGER, true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var label := Texts.t("ui.to_shop") if run.phase == "shop" else (Texts.t("ui.victory_title") if won else Texts.t("ui.defeat_title"))
	var b := Kit.button(label, func(): finished.emit(), (Kit.OK if won else Kit.DANGER).darkened(0.45))
	b.custom_minimum_size = Vector2(0, 72)
	v.add_child(b)


func _set_log(lines: Array) -> void:
	log_label.text = "\n".join(lines)


func _toggle_log() -> void:
	log_panel.visible = not log_panel.visible
	if log_panel.visible:
		move_child(log_panel, get_child_count() - 1)
