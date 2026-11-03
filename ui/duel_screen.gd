class_name DuelScreen
extends Control
## Tela da luta em paisagem (docs/SPEC_v3.md §6), turnos sequenciais.
##
## Fases: "player" (você põe dados nas magias), "resolve" (eventos animados: o seu
## turno, depois o turno inteiro do inimigo; tocar acelera) e "over".
## Interação: toque num dado da mão e depois numa magia do grimório. Toque num dado
## posto (ou na magia) para devolvê-lo.

signal finished

const DIE := 86
const EDIE := 50
const CELL := 92

var run: RunState
var duel: Duel
var fast := false ## Testes: sem esperas.
var phase := "player"
var choice := TurnChoice.new()
var selected := -1
var skip := false
var shown := {} ## side -> {hp, max, block}

var hud: Label
var enemy_name: Button
var enemy_status: Label
var player_status: Label
var bars := {}
var enemy_grid: GrimoireView
var enemy_tray: HBoxContainer
var grid: GrimoireView
var tray: HBoxContainer
var tray_views: Array = []
var feed: RichTextLabel
var banner: Label
var info: Label
var end_btn: Button
var catcher: Control
var fx_layer: Control


func setup(r: RunState) -> DuelScreen:
	run = r
	duel = r.duel
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	_sync_shown()
	_feed_events(duel.turn_events)
	_start_player_phase()
	return self


# ================================================================== Layout
func _build() -> void:
	var root := Kit.vbox(8)
	var m := Kit.margin(root, 12)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)

	# Topo: inimigo.
	var top := Kit.hbox(16)
	root.add_child(top)
	var tl := Kit.vbox(6)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tl)
	hud = Kit.label("", 18, Kit.MUTED)
	tl.add_child(hud)
	enemy_name = Kit.button("", open_enemy_consult, Kit.PANEL, 22)
	enemy_name.custom_minimum_size = Vector2(0, 44)
	enemy_name.alignment = HORIZONTAL_ALIGNMENT_LEFT
	tl.add_child(enemy_name)
	bars.enemy = HpBar.new().setup(Kit.DANGER)
	tl.add_child(bars.enemy)
	enemy_status = Kit.label("", 18, Kit.MUTED)
	tl.add_child(enemy_status)
	var tr := Kit.vbox(6)
	top.add_child(tr)
	enemy_tray = Kit.hbox(6)
	enemy_tray.custom_minimum_size = Vector2(0, EDIE)
	tr.add_child(enemy_tray)
	enemy_grid = GrimoireView.new().setup(duel.enemy.inventory, 34 if duel.enemy.inventory.width > 4 else 40, duel.enemy)
	enemy_grid.compact = true
	enemy_grid.cell_tapped.connect(func(_c, _i): open_enemy_consult())
	tr.add_child(enemy_grid)

	# Meio: grimório do jogador | registro.
	var mid := Kit.hbox(16)
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(mid)
	var gc := CenterContainer.new()
	mid.add_child(gc)
	grid = GrimoireView.new().setup(duel.player.inventory, CELL, duel.player)
	grid.choice = choice
	grid.cell_tapped.connect(_on_cell)
	gc.add_child(grid)
	var right := Kit.vbox(6)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_child(right)
	banner = Kit.label("", 28, Kit.ACCENT)
	right.add_child(banner)
	feed = RichTextLabel.new()
	feed.bbcode_enabled = true
	feed.scroll_following = true
	feed.size_flags_vertical = Control.SIZE_EXPAND_FILL
	feed.add_theme_font_size_override("normal_font_size", 19)
	feed.add_theme_color_override("default_color", Kit.MUTED)
	right.add_child(feed)
	info = Kit.label(Texts.t("ui.tap_spell"), 17, Kit.MUTED, true)
	right.add_child(info)

	# Base: mão, vida e botão.
	var bottom := Kit.hbox(16)
	root.add_child(bottom)
	var bl := Kit.vbox(6)
	bl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(bl)
	tray = Kit.hbox(8)
	tray.custom_minimum_size = Vector2(0, DIE)
	bl.add_child(tray)
	var pr := Kit.hbox(10)
	bars.player = HpBar.new().setup(Kit.OK)
	pr.add_child(bars.player)
	player_status = Kit.label("", 18, Kit.MUTED)
	pr.add_child(player_status)
	bl.add_child(pr)
	end_btn = Kit.button(Texts.t("ui.end_turn"), _on_end_turn, Kit.ACCENT.darkened(0.55), 26)
	end_btn.custom_minimum_size = Vector2(280, 0)
	bottom.add_child(end_btn)

	fx_layer = Control.new()
	fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fx_layer)
	catcher = Control.new()
	catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
	catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	catcher.visible = false
	catcher.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			skip = true)
	add_child(catcher)


# ================================================================== Estado
func _sync_shown() -> void:
	for f in [duel.player, duel.enemy]:
		shown[Resolver.side(f)] = {"hp": f.hp, "max": f.max_hp, "block": f.block}
	_refresh_bars()


func _refresh_bars() -> void:
	for s in ["player", "enemy"]:
		var v: Dictionary = shown[s]
		bars[s].set_values(v.max, v.hp, v.block, 0)
	hud.text = Texts.t("ui.hud", {"n": run.floor_n, "max": Config.LAST_FLOOR, "coins": run.coins,
		"hp": duel.player.hp, "maxhp": duel.player.max_hp}) + "  ·  " + Texts.t("ui.turn", {"n": duel.turn})
	var e := duel.enemy
	var who := e.name
	if e.master_id != "":
		who += "  ·  " + Texts.master_name(e.master_id)
	else:
		who += "  ·  " + Texts.t("archetypes." + e.archetype)
	enemy_name.text = who + "  ⓘ"
	enemy_status.text = _status(e)
	player_status.text = _status(duel.player)


func _status(f: Fighter) -> String:
	var p := []
	if f.poison > 0:
		p.append(Texts.t("ui.poison", {"n": f.poison}))
	if f.burn > 0:
		p.append(Texts.t("ui.burn", {"n": f.burn}))
	if f.mirror:
		p.append(Texts.t("ui.mirror"))
	if f.dodge:
		p.append(Texts.t("ui.dodge"))
	return "  ".join(p)


func _start_player_phase() -> void:
	phase = "player"
	choice = TurnChoice.new()
	grid.choice = choice
	selected = -1
	banner.text = Texts.t("ui.your_turn")
	catcher.visible = false
	end_btn.disabled = false
	_build_tray()
	_sync_shown()
	grid.refresh()
	enemy_grid.refresh()


func _build_tray() -> void:
	Kit.clear(tray)
	tray_views = []
	var p := duel.player
	for h in p.hand.size():
		var e: Dictionary = p.hand[h]
		var d := p.die_of(e)
		var v := DieView.new().setup(h, int(e.value), d.element if d else "", DIE)
		v.tapped.connect(_on_die)
		tray.add_child(v)
		tray_views.append(v)
	_refresh_tray()


func _build_enemy_tray(values: Array, elements: Array = []) -> void:
	Kit.clear(enemy_tray)
	if values.is_empty():
		return
	enemy_tray.add_child(Kit.label(Texts.t("ui.enemy_last"), 16, Kit.MUTED))
	for i in values.size():
		var v := DieView.new()
		v.interactive = false
		v.setup(i, int(values[i]), elements[i] if i < elements.size() else "", EDIE)
		enemy_tray.add_child(v)


func _refresh_tray() -> void:
	var used := choice.used_dice()
	for v in tray_views:
		if v.index in used:
			var item := -1
			for k in choice.casts:
				if v.index in choice.casts[k]:
					item = k
			v.set_state("placed", Texts.spell_name(duel.player.inventory.items[item].id).left(8))
		elif v.index == selected:
			v.set_state("selected")
		else:
			v.set_state("free")
	grid.refresh()


# ================================================================== Interação
func _on_die(v: DieView) -> void:
	if phase != "player":
		return
	if v.index in choice.used_dice():
		choice.remove_die(v.index)
		selected = -1
	else:
		selected = -1 if selected == v.index else v.index
	info.text = Texts.t("ui.tap_spell")
	_refresh_tray()


func _on_cell(_c: Vector2i, item: int) -> void:
	if phase != "player" or item < 0:
		return
	if selected >= 0:
		place(selected, item)
		return
	for h in choice.dice_in(item).duplicate():
		choice.remove_die(h)
	_refresh_tray()


## Põe o dado h na magia item. Retorna false se não aceitar.
func place(h: int, item: int) -> bool:
	var p := duel.player
	var id: String = p.inventory.items[item].id
	if not TurnChoice.can_cast(p, item):
		info.text = Texts.t("ui.spell_used")
		return false
	if not choice.place(p, item, h):
		info.text = Texts.t("ui.not_accepted", {"name": Texts.spell_name(id), "req": GrimoireView.req_label(id)})
		return false
	selected = -1
	info.text = Texts.t("ui.tap_spell")
	_refresh_tray()
	return true


func open_enemy_consult() -> Overlay:
	var e := duel.enemy
	var o := Overlay.open(self, e.name, "OK", 820)
	if e.master_id != "":
		o.add_text(Texts.master_name(e.master_id) + ": " + Texts.master_desc(e.master_id), 20, Kit.ACCENT)
	else:
		o.add_text(Texts.t("archetypes." + e.archetype), 20, Kit.ACCENT)
	if e.variant != "":
		o.add_text(Texts.t("variants." + e.variant), 18, Kit.ACCENT)
	o.add_text(Texts.t("ui.consult_hp", {"hp": e.hp, "max": e.max_hp}) + "   " + _status(e), 20)
	var counts := {}
	for d in e.bag:
		var k := Texts.element_name(d.element)
		counts[k] = counts.get(k, 0) + 1
	var parts := []
	for k in counts:
		parts.append("%d %s" % [counts[k], k])
	var stick := 0
	for d in e.bag:
		stick += d.sticker_count()
	var bag_txt := Texts.t("ui.consult_bag", {"list": ", ".join(parts)})
	if stick > 0:
		bag_txt += "  ·  " + Texts.t("ui.consult_stickers", {"n": stick})
	o.add_text(bag_txt, 18)
	var row := Kit.hbox(16)
	o.body.add_child(row)
	var g := GrimoireView.new().setup(e.inventory, 54 if e.inventory.width > 4 else 70, e)
	g.compact = true
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(g)
	var lst := Kit.vbox(4)
	lst.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lst)
	for it in e.inventory.items:
		var t := "• %s" % Texts.spell_name(it.id)
		if int(it.level) > 1:
			t += " (" + Texts.t("ui.level", {"n": it.level}) + ")"
		lst.add_child(Kit.label(t + ": " + Texts.spell_desc(it.id), 16, Kit.MUTED, true))
	return o


# ================================================================== Turno
func _on_end_turn() -> void:
	_submit()


func _submit() -> void:
	if phase != "player":
		return
	phase = "resolve"
	end_btn.disabled = true
	catcher.visible = true
	skip = false
	selected = -1
	var rep := duel.submit(choice)
	if rep.has("error"):
		info.text = str(rep.error)
		_start_player_phase()
		return
	await _animate(rep.events)
	if duel.state == "choosing":
		await _animate(duel.turn_events)
	SaveGame.save(run)
	if duel.state != "choosing":
		_show_over()
	else:
		_start_player_phase()


func _wait(t: float) -> void:
	if fast or skip or not is_inside_tree():
		return
	var left := t
	while left > 0.0 and not skip and is_inside_tree():
		await get_tree().process_frame
		left -= get_process_delta_time()


func _animate(events: Array) -> void:
	for ev in events:
		_apply_event(ev)
		_feed_events([ev])
		await _wait(_delay(ev))
	_sync_shown()


func _delay(ev: Dictionary) -> float:
	match str(ev.t):
		"turn":
			return 0.6
		"hand":
			return 0.5 if ev.side == "enemy" else 0.2
		"cast":
			return 0.45
		"hit", "poison", "burn":
			return 0.55
	return 0.3


func _apply_event(ev: Dictionary) -> void:
	var s: String = str(ev.side)
	var v: Dictionary = shown.get(s, {})
	match str(ev.t):
		"turn":
			banner.text = Texts.t("ui.your_turn") if s == "player" else Texts.t("ui.enemy_turn")
			if s == "enemy":
				shown.enemy.block = 0
			else:
				shown.player.block = 0
		"hand":
			if s == "enemy":
				_build_enemy_tray(ev["values"], ev.get("elements", []))
		"cast":
			if s == "player":
				grid.pulse_item(int(ev.item))
				for h in ev.dice:
					if h < tray_views.size():
						tray_views[h].set_state("used")
			else:
				enemy_grid.pulse_item(int(ev.item))
		"hit":
			v.hp -= int(ev.dmg)
			v.block = maxi(0, int(v.block) - int(ev.absorbed))
			_float(s, "−%d" % int(ev.dmg) if int(ev.dmg) > 0 else Texts.t("ui.fx_absorb", {"n": ev.absorbed}), Kit.DANGER)
		"poison", "burn":
			v.hp -= int(ev.n)
			_float(s, "−%d" % int(ev.n), Color(0.6, 0.9, 0.3) if ev.t == "poison" else Color(1.0, 0.6, 0.2))
		"block":
			v.block = int(ev.total)
			_float(s, Texts.t("ui.fx_block", {"n": ev.n}), Kit.SHIELD)
		"heal":
			v.hp += int(ev.n)
			_float(s, Texts.t("ui.fx_heal", {"n": ev.n}), Kit.OK)
		"maxhp":
			v.max += int(ev.n)
			v.hp += int(ev.n)
			_float(s, Texts.t("ui.fx_maxhp", {"n": ev.n}), Kit.OK)
		"dodged":
			_float(s, Texts.t("ui.fx_dodged"), Kit.SHIELD)
		"mirrored":
			_float(s, Texts.t("ui.fx_mirror"), Kit.TEXT)
	_refresh_shown_only()


func _refresh_shown_only() -> void:
	for s in ["player", "enemy"]:
		var v: Dictionary = shown[s]
		bars[s].set_values(v.max, v.hp, v.block, 0)


func _float(s: String, text: String, col: Color) -> void:
	if fast:
		return
	var bar: Control = bars[s]
	var l := Kit.label(text, 30, col)
	l.position = bar.global_position + Vector2(bar.size.x * 0.5 - 40, -30)
	fx_layer.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 40, 0.8)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.8)
	tw.tween_callback(l.queue_free)


func _feed_events(events: Array) -> void:
	for ev in events:
		var line := _describe(ev)
		if line != "":
			feed.append_text(line + "\n")


func _who(s: String) -> String:
	return Texts.t("ui.you") if s == "player" else Texts.t("ui.enemy")


func _describe(ev: Dictionary) -> String:
	var s: String = str(ev.side)
	var w := _who(s)
	match str(ev.t):
		"turn":
			return "[color=#ffc833]— %s —[/color]" % (Texts.t("ui.your_turn") if s == "player" else Texts.t("ui.enemy_turn"))
		"hand":
			return Texts.t("ev.hand", {"who": w, "v": " ".join(PackedStringArray(ev["values"].map(func(x): return str(x))))})
		"cast":
			return Texts.t("ev.cast", {"who": w, "spell": Texts.spell_name(ev.spell),
				"v": "+".join(PackedStringArray(ev["values"].map(func(x): return str(x))))})
		"hit":
			var t := Texts.t("ev.hit", {"who": w, "n": ev.dmg})
			if int(ev.absorbed) > 0:
				t += " " + Texts.t("ev.absorbed", {"n": ev.absorbed})
			if ev.get("reflected", false):
				t += " " + Texts.t("ev.reflected")
			return t
		"block":
			return Texts.t("ev.block", {"who": w, "n": ev.n})
		"heal":
			return Texts.t("ev.heal", {"who": w, "n": ev.n})
		"maxhp":
			return Texts.t("ev.maxhp", {"who": w, "n": ev.n})
		"poison":
			return Texts.t("ev.poison", {"who": w, "n": ev.n})
		"burn":
			return Texts.t("ev.burn", {"who": w, "n": ev.n})
		"poison_up":
			return Texts.t("ev.poison_up", {"who": w, "n": ev.n})
		"burn_up":
			return Texts.t("ev.burn_up", {"who": w, "n": ev.n})
		"dodge_up":
			return Texts.t("ev.dodge_up", {"who": w})
		"mirror_up":
			return Texts.t("ev.mirror_up", {"who": w})
		"dodged":
			return Texts.t("ev.dodged", {"who": w})
		"mirrored":
			return Texts.t("ev.mirrored", {"who": w})
		"sacrifice":
			return Texts.t("ev.sacrifice", {"who": w, "n": ev.bonus})
		"lead_hand":
			return Texts.t("ev.lead_hand")
		"lead_bag":
			return Texts.t("ev.lead_bag")
		"turn_limit":
			return Texts.t("ui.fx_turn_limit")
	return ""


# ================================================================== Fim
func _show_over() -> void:
	phase = "over"
	catcher.visible = false
	end_btn.disabled = true
	var won := duel.state == "won"
	var coins := RunState.door_coins(run.door) if not run.is_master_floor() else 20
	var o := Overlay.open(self, Texts.t("ui.won_duel", {"coins": coins}) if won else Texts.t("ui.lost_duel"), Texts.t("ui.continue_btn"), 520)
	o.closed.connect(_finish)


func _finish() -> void:
	run.finish_duel()
	SaveGame.save(run)
	finished.emit()
