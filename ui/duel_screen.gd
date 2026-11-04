class_name DuelScreen
extends Control
## Tela da luta em paisagem (docs/SPEC_v3.md §6), turnos sequenciais.
##
## Layout: trilho à esquerda com os dois personagens (inimigo em cima, você embaixo);
## à direita, as magias do inimigo, a bandeja da mão e as suas magias, todas em
## cartões iguais (o formato só importa no grimório). Cada magia tem um buraco por
## dado pedido. Não há registro na tela: o resultado aparece no lugar e o histórico
## completo abre por botão.
##
## Fases: "player" (você encaixa dados nas magias), "resolve" (eventos animados: o seu
## turno, depois o turno inteiro do inimigo; tocar acelera) e "over".
## Interação: toque num dado da mão e depois numa magia. Toque num dado posto (ou na
## magia) para devolvê-lo.

signal finished

const DIE := 92 ## Buraco da mão.
const EDIE := 28 ## Última mão do inimigo.
const RAIL := 270

var run: RunState
var duel: Duel
var fast := false ## Testes: sem esperas.
var phase := "player"
var choice := TurnChoice.new()
var selected := -1
var skip := false
var shown := {} ## side -> {hp, max, block}
var history: Array = [] ## Linhas do histórico (bbcode).
var summary: Array = [] ## Resumo do turno do inimigo.

var hud: Label
var enemy_name: Label
var enemy_sub: Label
var enemy_status: Label
var player_sub: Label
var player_status: Label
var bars := {}
var enemy_tray: HBoxContainer
var enemy_cards: Array = []
var cards: Array = []
var tray: HBoxContainer
var tray_views: Array = [] ## Hole por dado da mão.
var banner: Label
var hint: Label
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
	var root := Kit.hbox(18)
	var m := MarginContainer.new()
	for k in ["left", "right"]:
		m.add_theme_constant_override("margin_" + k, 18)
	for k in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + k, 12)
	m.add_child(root)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)

	# Trilho: inimigo em cima, você embaixo.
	var rail := Kit.vbox(10)
	rail.custom_minimum_size = Vector2(RAIL, 0)
	root.add_child(rail)
	var e := duel.enemy
	var eb := _fighter_box(e, false)
	eb.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and not ev.pressed:
			open_enemy_consult())
	rail.add_child(eb)
	var mid := Kit.vbox(8)
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	rail.add_child(mid)
	hud = Kit.label("", 16, Kit.MUTED, true)
	hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mid.add_child(hud)
	var hb := Kit.button(Texts.t("ui.history"), open_history, Kit.PANEL, 18)
	hb.custom_minimum_size = Vector2(0, 44)
	mid.add_child(hb)
	rail.add_child(_fighter_box(duel.player, true))

	# Arena.
	var arena := Kit.vbox(8)
	arena.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(arena)
	var eh := Kit.hbox(6)
	arena.add_child(eh)
	var el := Kit.label(Texts.t("ui.enemy_spells"), 15, Kit.MUTED)
	el.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eh.add_child(el)
	enemy_tray = Kit.hbox(5)
	enemy_tray.custom_minimum_size = Vector2(0, EDIE)
	eh.add_child(enemy_tray)
	var eg := _card_grid(e.inventory.order().size(), 4)
	arena.add_child(eg)
	for item in e.inventory.order():
		var c := SpellCard.new().setup(e, item, 40, true)
		c.tapped.connect(func(_i): open_enemy_consult())
		eg.add_child(c)
		enemy_cards.append(c)

	# Centro: turno, bandeja da mão e botão.
	var center := PanelContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_theme_stylebox_override("panel", Kit.box(Color(0.098, 0.086, 0.125), 18, 14))
	arena.add_child(center)
	var cv := Kit.vbox(6)
	cv.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(cv)
	var crow := Kit.hbox(14)
	crow.alignment = BoxContainer.ALIGNMENT_CENTER
	cv.add_child(crow)
	var bv := Kit.vbox(2)
	bv.custom_minimum_size = Vector2(150, 0)
	bv.alignment = BoxContainer.ALIGNMENT_CENTER
	banner = Kit.label("", 28, Kit.ACCENT, true)
	bv.add_child(banner)
	hint = Kit.label(Texts.t("ui.hint_place"), 15, Kit.MUTED, true)
	bv.add_child(hint)
	crow.add_child(bv)
	tray = Kit.hbox(8)
	tray.alignment = BoxContainer.ALIGNMENT_CENTER
	tray.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tray.custom_minimum_size = Vector2(0, DIE)
	crow.add_child(tray)
	end_btn = Kit.button(Texts.t("ui.end_turn"), _on_end_turn, Kit.ACCENT.darkened(0.45), 24)
	end_btn.custom_minimum_size = Vector2(200, 88)
	crow.add_child(end_btn)
	info = Kit.label("", 18, Kit.TEXT, true)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cv.add_child(info)

	# Suas magias, perto do polegar.
	arena.add_child(Kit.label(Texts.t("ui.your_spells"), 15, Kit.MUTED))
	var p := duel.player
	var n := p.inventory.order().size()
	var pg := _card_grid(n, 4)
	arena.add_child(pg)
	var big := n <= 4
	for item in p.inventory.order():
		var c := SpellCard.new().setup(p, item, 68 if big else 50)
		c.custom_minimum_size = Vector2(0, 186 if big else 128)
		c.tapped.connect(_on_card)
		pg.add_child(c)
		cards.append(c)

	fx_layer = Control.new()
	fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fx_layer)
	catcher = Control.new()
	catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
	catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	catcher.visible = false
	catcher.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			skip = true)
	add_child(catcher)


## Grade de cartões: até "per_row" por linha, linhas equilibradas.
func _card_grid(n: int, per_row: int) -> GridContainer:
	var g := GridContainer.new()
	var rows := maxi(1, ceili(float(n) / per_row))
	g.columns = maxi(1, ceili(float(n) / rows))
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 8)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return g


func _fighter_box(f: Fighter, is_player: bool) -> PanelContainer:
	var b := PanelContainer.new()
	var sb := Kit.box(Color(0.114, 0.102, 0.141), 14, 10)
	sb.set_border_width_all(1)
	sb.border_color = SpellCard.LINE
	b.add_theme_stylebox_override("panel", sb)
	b.mouse_filter = Control.MOUSE_FILTER_STOP if not is_player else Control.MOUSE_FILTER_IGNORE
	var v := Kit.vbox(4)
	b.add_child(v)
	v.add_child(Portrait.new().setup(f.archetype, 112, is_player))
	var side := "player" if is_player else "enemy"
	if is_player:
		v.add_child(Kit.label(Texts.t("ui.you") + " · " + Texts.t("archetypes." + f.archetype), 20, Kit.TEXT))
		player_sub = Kit.label("", 14, Kit.MUTED)
		v.add_child(player_sub)
	else:
		enemy_name = Kit.label(f.name, 20, Kit.TEXT, true)
		v.add_child(enemy_name)
		enemy_sub = Kit.label("", 14, Kit.MUTED, true)
		v.add_child(enemy_sub)
	bars[side] = HpBar.new().setup(Kit.OK if is_player else Kit.DANGER)
	bars[side].custom_minimum_size = Vector2(0, 30)
	v.add_child(bars[side])
	var st := Kit.label("", 15, Color(1.0, 0.69, 0.4))
	v.add_child(st)
	if is_player:
		player_status = st
	else:
		enemy_status = st
	return b


# ================================================================== Estado
func _sync_shown() -> void:
	for f in [duel.player, duel.enemy]:
		shown[Resolver.side(f)] = {"hp": f.hp, "max": f.max_hp, "block": f.block}
	_refresh_bars()


func _refresh_bars() -> void:
	for s in ["player", "enemy"]:
		var v: Dictionary = shown[s]
		bars[s].set_values(v.max, v.hp, v.block, 0)
	hud.text = Texts.t("ui.hud_duel", {"n": run.floor_n, "max": Config.LAST_FLOOR, "coins": run.coins, "t": duel.turn})
	var e := duel.enemy
	var arch := Texts.master_name(e.master_id) if e.master_id != "" else Texts.t("archetypes." + e.archetype)
	enemy_sub.text = Texts.t("ui.enemy_sub", {"arch": arch, "n": e.bag.size()})
	player_sub.text = Texts.t("ui.bag_line", {"n": duel.player.bag.size(), "d": duel.player.discard.size()})
	enemy_status.text = _status(e)
	enemy_status.visible = enemy_status.text != ""
	player_status.text = _status(duel.player)
	player_status.visible = player_status.text != ""


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
	return " · ".join(p)


func _start_player_phase() -> void:
	phase = "player"
	for c in cards + enemy_cards:
		c.shown_used = null
	choice = TurnChoice.new()
	selected = -1
	banner.text = Texts.t("ui.your_turn")
	hint.text = Texts.t("ui.hint_place")
	catcher.visible = false
	end_btn.disabled = false
	_build_tray()
	_build_enemy_tray(duel.enemy.last_hand)
	_sync_shown()
	_refresh_tray()
	if not summary.is_empty():
		info.text = Texts.t("ui.enemy_summary", {"list": " · ".join(summary)})
		info.add_theme_color_override("font_color", Kit.TEXT)


func _build_tray() -> void:
	Kit.clear(tray)
	tray_views = []
	var p := duel.player
	for h in p.hand.size():
		var e: Dictionary = p.hand[h]
		var d := p.die_of(e)
		var v := Hole.new().setup(_die_px(p.hand.size()), h)
		v.set_die(int(e.value), d.element if d else "")
		v.tapped.connect(_on_die)
		tray.add_child(v)
		tray_views.append(v)


## Buraco da bandeja: menor quando a mão tem mais de 5 dados (cabe na largura).
func _die_px(n: int) -> int:
	return DIE if n <= 5 else maxi(60, int((540.0 - (n - 1) * 8) / n))


## Bandeja do centro com uma mão qualquer (a sua é tocável; a do inimigo, não).
func _fill_tray(values: Array, elements: Array, interactive: bool) -> void:
	Kit.clear(tray)
	tray_views = []
	for h in values.size():
		var v := Hole.new().set_interactive(interactive).setup(_die_px(values.size()), h)
		v.set_die(int(values[h]), elements[h] if h < elements.size() else "")
		if interactive:
			v.tapped.connect(_on_die)
		tray.add_child(v)
		tray_views.append(v)


## Rolagem: as faces trocam rápido antes de parar no valor sorteado.
func _roll_tray() -> void:
	if fast or skip:
		return
	var final := []
	for v in tray_views:
		final.append(v.value)
	for step in 6:
		for v in tray_views:
			v.value = randi_range(1, 6)
			v.queue_redraw()
		await _wait(0.06)
		if skip:
			break
	for k in tray_views.size():
		tray_views[k].value = final[k]
		tray_views[k].queue_redraw()


## Um dado voa de um buraco para outro (camada de efeitos).
func _fly(from: Hole, to: Hole) -> void:
	if fast or skip or not is_inside_tree():
		return
	var g := Hole.new().set_interactive(false).setup(int(from.size.x))
	g.set_die(from.value, from.element)
	g.position = from.global_position
	fx_layer.add_child(g)
	from.has_die = false
	from.queue_redraw()
	var sc := to.size.x / maxf(1.0, from.size.x)
	var tw := g.create_tween()
	tw.tween_property(g, "position", to.global_position, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(g, "scale", Vector2(sc, sc), 0.3)
	await _wait(0.32)
	g.queue_free()


func _build_enemy_tray(values: Array, elements: Array = []) -> void:
	Kit.clear(enemy_tray)
	if values.is_empty():
		return
	enemy_tray.add_child(Kit.label(Texts.t("ui.enemy_last"), 14, Kit.MUTED))
	for i in values.size():
		var v := DieView.new()
		v.interactive = false
		v.setup(i, int(values[i]), elements[i] if i < elements.size() else "", EDIE)
		enemy_tray.add_child(v)


func _item_of(h: int) -> int:
	for k in choice.casts:
		if h in choice.casts[k]:
			return k
	return -1


func _refresh_tray() -> void:
	var p := duel.player
	var used := choice.used_dice()
	for v in tray_views:
		var hv: Hole = v
		if hv.index in used:
			hv.has_die = false
			hv.caption = Texts.spell_name(p.inventory.items[_item_of(hv.index)].id)
		else:
			hv.has_die = true
			hv.caption = ""
		hv.raised = hv.index == selected
		hv.queue_redraw()
	var sel := int(p.hand[selected].value) if selected >= 0 else -1
	for c in cards:
		var vals := choice.values_in(p, c.item)
		var els := []
		for h in choice.dice_in(c.item):
			var d := p.die_of(p.hand[h])
			els.append(d.element if d else "")
		c.refresh(vals, els, sel if not (selected in used) else -1)
	if phase != "player":
		return
	if selected >= 0:
		info.text = Texts.t("ui.die_selected", {"v": sel})
		info.add_theme_color_override("font_color", Kit.ACCENT)
	elif not used.is_empty():
		var parts := []
		for item in choice.ready_items(p):
			parts.append(Texts.spell_name(p.inventory.items[item].id) + " " + SpellCard.preview_text(p, item, choice.values_in(p, item)))
		info.text = Texts.t("ui.this_turn", {"list": " · ".join(parts)}) if not parts.is_empty() else Texts.t("ui.incomplete")
		info.add_theme_color_override("font_color", Kit.TEXT)
	elif summary.is_empty():
		info.text = Texts.t("ui.back_to_bag")
		info.add_theme_color_override("font_color", Kit.MUTED)


# ================================================================== Interação
func _on_die(v: Hole) -> void:
	if phase != "player":
		return
	summary = []
	if v.index in choice.used_dice():
		choice.remove_die(v.index)
		selected = -1
	else:
		selected = -1 if selected == v.index else v.index
	_refresh_tray()


func _on_card(item: int) -> void:
	if phase != "player" or item < 0:
		return
	summary = []
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
		info.add_theme_color_override("font_color", Kit.DANGER.lightened(0.2))
		return false
	selected = -1
	_refresh_tray()
	return true


func open_history() -> Overlay:
	var o := Overlay.open(self, Texts.t("ui.history"), "OK", 760)
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.custom_minimum_size = Vector2(0, 440)
	r.scroll_following = true
	r.add_theme_font_size_override("normal_font_size", 19)
	r.add_theme_color_override("default_color", Color(0.85, 0.83, 0.89))
	r.text = "\n".join(history)
	o.body.add_child(r)
	return o


func open_enemy_consult() -> Overlay:
	var e := duel.enemy
	var o := Overlay.open(self, e.name, "OK", 860)
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
	for it in e.inventory.items:
		var t := "• %s" % Texts.spell_name(it.id)
		if int(it.level) > 1:
			t += " (" + Texts.t("ui.level", {"n": it.level}) + ")"
		o.add_text(t + ": " + Texts.spell_desc(it.id), 18, Color(0.85, 0.83, 0.89))
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
	# As magias "1× por luta" só aparecem como usadas quando a animação chega nelas.
	for c in cards:
		c.shown_used = duel.player.once_used.duplicate()
	for c in enemy_cards:
		c.shown_used = duel.enemy.once_used.duplicate()
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
		await _apply_event(ev)
		_feed_events([ev])
		await _wait(_delay(ev))
	_sync_shown()


func _delay(ev: Dictionary) -> float:
	match str(ev.t):
		"turn":
			return 0.6
		"hand":
			return 0.4 if ev.side == "enemy" else 0.15
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
				summary = []
				info.text = ""
				hint.text = Texts.t("ui.tap_to_skip")
				for c in enemy_cards:
					c.refresh([], [], -1)
				for c in cards:
					c.refresh([], [], -1)
			else:
				shown.player.block = 0
		"hand":
			# Os dois lados rolam a mão na bandeja do centro.
			if s == "enemy":
				hint.text = Texts.t("ui.enemy_rolling")
			_fill_tray(ev["values"], ev.get("elements", []), s == "player")
			await _roll_tray()
		"cast":
			var cc := _card_of(cards if s == "player" else enemy_cards, int(ev.item))
			if cc and cc.shown_used != null:
				cc.shown_used.append(int(ev.item))
			var vals := " + ".join(PackedStringArray(ev["values"].map(func(x): return str(x))))
			if s == "player":
				var pc := _card_of(cards, int(ev.item))
				if pc and not fast:
					pc.flash()
				for h in ev.dice:
					if h < tray_views.size():
						tray_views[h].faded = true
						tray_views[h].queue_redraw()
			else:
				var ec := _card_of(enemy_cards, int(ev.item))
				if ec:
					# Os dados do inimigo voam da bandeja até os buracos da magia dele.
					var dice: Array = ev.dice
					for k in dice.size():
						var h := int(dice[k])
						if h < tray_views.size() and k < ec.holes.size():
							await _fly(tray_views[h], ec.holes[k])
							tray_views[h].has_die = false
							tray_views[h].caption = Texts.spell_name(ev.spell)
							tray_views[h].queue_redraw()
							ec.refresh(ev["values"].slice(0, k + 1), [], -1)
					ec.refresh(ev["values"], [], -1)
					if not fast:
						ec.flash()
				summary.append(Texts.spell_name(ev.spell) + " " + vals)
		"hit":
			v.hp -= int(ev.dmg)
			v.block = maxi(0, int(v.block) - int(ev.absorbed))
			var hit_txt := "−%d" % int(ev.dmg) if int(ev.dmg) > 0 else Texts.t("ui.fx_absorb", {"n": ev.absorbed})
			_float(s, hit_txt, Kit.DANGER)
			_note(s, hit_txt)
		"poison", "burn":
			v.hp -= int(ev.n)
			_float(s, "−%d" % int(ev.n), Color(0.6, 0.9, 0.3) if ev.t == "poison" else Color(1.0, 0.6, 0.2))
			_note(s, Texts.t("ui.fx_" + str(ev.t), {"n": ev.n}))
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
			_note(s, Texts.t("ui.fx_dodged"))
		"mirrored":
			_float(s, Texts.t("ui.fx_mirror"), Kit.TEXT)
			_note(s, Texts.t("ui.fx_mirror"))
	_refresh_shown_only()


func _card_of(list: Array, item: int) -> SpellCard:
	for c in list:
		if c.item == item:
			return c
	return null


## Resumo do turno do inimigo: o que aconteceu com cada lado.
func _note(s: String, text: String) -> void:
	if banner.text != Texts.t("ui.enemy_turn"):
		return
	var who := Texts.t("ui.you") if s == "player" else Texts.t("ui.enemy")
	if summary.is_empty():
		summary.append(who + " " + text)
	else:
		summary[summary.size() - 1] += " → " + who.to_lower() + " " + text


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
			history.append(line)


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
