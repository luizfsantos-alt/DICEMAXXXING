class_name TowerScreen
extends Control
## Tela da torre fora das lutas: portas, recompensa, parada, Loja, Escola, Poço e
## a escolha inicial do Erudito. Cada opção é um cartão; algumas pedem um dado ou face.

signal finished

var run: RunState
var hud: Label
var title: Label
var cards: HBoxContainer
var info: Label
var bottom: HBoxContainer
var sell_row: HBoxContainer
var organizer: Overlay ## Aberto após ganhar uma magia (testes).


func setup(r: RunState) -> TowerScreen:
	run = r
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var root := Kit.vbox(16)
	var m := Kit.margin(root, 20)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	hud = Kit.label("", 22, Kit.MUTED)
	root.add_child(hud)
	title = Kit.label("", 36, Kit.ACCENT)
	root.add_child(title)
	var mid := CenterContainer.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(mid)
	cards = Kit.hbox(16)
	mid.add_child(cards)
	info = Kit.label("", 22, Kit.DANGER)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(info)
	sell_row = Kit.hbox(10)
	root.add_child(sell_row)
	bottom = Kit.hbox(16)
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(bottom)
	refresh()
	return self


func refresh() -> void:
	var h := run.hero
	hud.text = Texts.t("ui.hud", {"n": run.floor_n, "max": Config.LAST_FLOOR, "coins": run.coins, "hp": h.hp, "maxhp": h.max_hp})
	title.text = Texts.t({
		"start_pick": "ui.pick_start", "doors": "ui.pick_door", "reward": "ui.pick_reward",
		"rest": "ui.pick_rest", "shop": "stops.shop.0", "school": "stops.school.0", "well": "stops.well.0",
	}.get(run.phase, "ui.title"))
	Kit.clear(cards)
	for i in run.options.size():
		cards.add_child(_card(i, run.options[i]))
	Kit.clear(sell_row)
	if run.phase == "shop" and not h.inventory.items.is_empty():
		sell_row.add_child(Kit.label(Texts.t("ui.sell_title"), 20, Kit.MUTED))
		for k in h.inventory.items.size():
			var it: Dictionary = h.inventory.items[k]
			var idx := k
			var b := Kit.button(Texts.t("ui.sell", {"name": Texts.spell_name(it.id), "n": Spells.sell_price(int(it.level))}),
				func(): _sell(idx), Kit.PANEL, 18)
			b.custom_minimum_size = Vector2(0, 48)
			sell_row.add_child(b)
	Kit.clear(bottom)
	_bottom_btn(Texts.t("ui.bag", {"n": h.bag.size()}), func(): BagPanel.open(self, h.bag))
	_bottom_btn(Texts.t("ui.grimoire"), func(): Organizer.open(self, h.inventory, _save))
	if run.phase == "reward":
		_bottom_btn(Texts.t("ui.skip_reward", {"n": Config.SKIP_REWARD_COINS}), _leave)
	elif run.phase in ["shop", "well", "school"]:
		_bottom_btn(Texts.t("ui.leave"), _leave)


func _bottom_btn(t: String, cb: Callable) -> void:
	var b := Kit.button(t, cb, Kit.PANEL_HI, 24)
	b.custom_minimum_size = Vector2(240, 64)
	bottom.add_child(b)


func _card(i: int, o: Dictionary) -> Control:
	var lines := _describe(o)
	var price := Shop.price_of(o, run.hero, {}, run.destroys_used)
	var b := Button.new()
	b.custom_minimum_size = Vector2(260, 300)
	b.clip_text = true
	b.focus_mode = Control.FOCUS_NONE
	var col := Kit.PANEL_HI
	if o.kind == "door":
		col = {"facil": Color(0.2, 0.35, 0.25), "normal": Color(0.25, 0.25, 0.35), "dificil": Color(0.4, 0.22, 0.2),
			"insana": Color(0.45, 0.12, 0.3), "mestre": Color(0.45, 0.35, 0.1)}.get(o.id, col)
	for st in ["normal", "hover", "pressed", "disabled"]:
		var c2: Color = col
		if st == "hover":
			c2 = col.lightened(0.12)
		elif st == "disabled":
			c2 = col.darkened(0.5)
		b.add_theme_stylebox_override(st, Kit.box(c2, 16, 14))
	var v := Kit.vbox(8)
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 14
	v.offset_right = -14
	v.offset_top = 14
	v.offset_bottom = -14
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var t := Kit.label(lines[0], 26, Kit.TEXT, true)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(t)
	var d := Kit.label(lines[1], 18, Kit.MUTED, true)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(d)
	if not (run.phase in ["doors", "rest"]):
		var p := Kit.label(Texts.t("ui.free") if price == 0 else Texts.t("ui.price", {"n": price}), 22, Kit.ACCENT)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(p)
	if o.kind == "spell" and not run.hero.inventory.fits(o.id):
		b.disabled = true
		d.text += "\n\n" + Texts.t("ui.no_room")
	elif price > run.coins:
		b.disabled = true
	b.pressed.connect(func(): _pick(i))
	return b


func _describe(o: Dictionary) -> Array:
	match str(o.kind):
		"door":
			if o.id == "mestre":
				return [Texts.master_name("porteiro"), Texts.master_desc("porteiro")]
			return [Texts.t("ui.door", {"d": Texts.t("doors." + o.id)}), Texts.t("ui.door_info", {"d": Texts.t("doors." + o.id), "c": o.get("coins", 0)})]
		"stop":
			return [Texts.t("stops.%s.0" % o.id), Texts.t("stops.%s.1" % o.id)]
		"spell":
			return [Texts.spell_name(o.id), Texts.spell_desc(o.id) + "\n" + Texts.t("ui.shape", {"n": Spells.shape(o.id).size()})]
		"die":
			return [Texts.t("offers.die", {"name": Texts.element_name(o.id)}), Texts.element_desc(o.id)]
		"element":
			return [Texts.t("offers.element", {"name": Texts.element_name(o.id)}), Texts.element_desc(o.id)]
		"evolve":
			var lvl := int(run.hero.inventory.items[int(o.item)].level) + 1
			return [Texts.t("offers.evolve", {"name": Texts.spell_name(o.id), "lvl": lvl}), Texts.spell_desc(o.id)]
	return [Texts.t("offers." + o.kind), ""]


func _pick(i: int) -> void:
	var o: Dictionary = run.options[i]
	match str(o.needs):
		"face":
			BagPanel.open(self, run.hero.bag, "face", func(d, f): _apply(i, {"die": d, "face": f}))
		"die":
			BagPanel.open(self, run.hero.bag, "die", func(d, _f): _apply(i, {"die": d}))
		_:
			_apply(i, {})


func _apply(i: int, target: Dictionary) -> void:
	var phase := run.phase
	var o: Dictionary = run.options[i]
	var had := run.hero.inventory.items.size()
	var err := run.choose(i, target)
	info.text = Texts.t(err) if err != "" else ""
	_save()
	var after := func():
		_save()
		if run.phase != phase:
			finished.emit()
		else:
			refresh()
	# Ganhou uma magia: sempre dá a chance de organizar o grimório, com ela marcada.
	if err == "" and o.kind == "spell" and run.hero.inventory.items.size() > had:
		organizer = Organizer.open(self, run.hero.inventory, after, run.hero.inventory.items.size() - 1)
		return
	after.call()


func _sell(k: int) -> void:
	run.sell_spell(k)
	_save()
	refresh()


func _leave() -> void:
	run.leave()
	_save()
	finished.emit()


func _save() -> void:
	SaveGame.save(run)
	refresh()
