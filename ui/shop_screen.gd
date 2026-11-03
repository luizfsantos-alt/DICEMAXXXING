class_name ShopScreen
extends Control
## Loja: 1 oferta por visita, rerrolagem grátis limitada, venda de itens.

signal finished

var run: RunState
var body: VBoxContainer
var msg: Label


func setup(r: RunState) -> ShopScreen:
	run = r
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(cc)
	body = Kit.vbox(14)
	body.custom_minimum_size = Vector2(1080, 0)
	cc.add_child(body)
	_render()
	return self


func _btn(text: String, cb: Callable, color := Kit.PANEL_HI, font := 24) -> Button:
	var b := Kit.button(text, cb, color, font)
	b.custom_minimum_size = Vector2(0, 64)
	return b


func _render() -> void:
	Kit.clear(body)
	var head := Kit.hbox(24)
	head.add_child(Kit.label(Texts.t("ui.shop"), 44, Kit.ACCENT))
	var coins := Kit.label(Texts.t("ui.coins", {"n": run.coins}), 28)
	coins.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(coins)
	body.add_child(head)
	var cols := Kit.hbox(20)
	body.add_child(cols)

	# Esquerda: a oferta.
	var left := Kit.vbox(12)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.0
	cols.add_child(left)
	var card := Kit.panel(Kit.PANEL_HI)
	var cv := Kit.vbox(8)
	card.add_child(cv)
	var o := run.offer
	if o.is_empty():
		cv.add_child(Kit.label("Esgotado. Volte depois da próxima luta.", 24, Kit.MUTED, true))
	else:
		cv.add_child(Kit.label(_category(o.type), 20, Kit.MUTED))
		cv.add_child(Kit.label(Texts.item_name(o.id), 32, Kit.TEXT, true))
		cv.add_child(Kit.label(Texts.item_desc(o.id), 22, Kit.MUTED, true))
		var replaced := ""
		if o.type == "attack":
			replaced = run.attack_id
		elif o.type == "defense":
			replaced = run.defense_id
		if replaced != "":
			cv.add_child(Kit.label(Texts.t("ui.replaces", {"name": Texts.item_name(replaced)}), 20, Kit.DANGER, true))
		var buy := _btn(Texts.t("ui.buy", {"price": o.price}), _on_buy, Kit.OK.darkened(0.45))
		buy.disabled = run.coins < int(o.price)
		cv.add_child(buy)
	left.add_child(card)
	msg = Kit.label("", 22, Kit.ACCENT, true)
	left.add_child(msg)

	# Direita: ações e build.
	var right := Kit.vbox(12)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(right)
	var rr := _btn(Texts.t("ui.reroll", {"n": run.rerolls}), _on_reroll)
	rr.disabled = run.rerolls <= 0
	right.add_child(rr)
	var bp := Kit.panel()
	var bv := Kit.vbox(6)
	bp.add_child(bv)
	bv.add_child(Kit.label("Vida máxima: %d" % run.player_max_hp(), 20))
	bv.add_child(Kit.label("Ataque: " + Texts.item_name(run.attack_id), 20))
	bv.add_child(Kit.label("Defesa: " + Texts.item_name(run.defense_id), 20))
	if run.death_defy:
		bv.add_child(Kit.label(Texts.t("ui.death_defy_owned"), 20, Kit.ACCENT))
	bv.add_child(Kit.label(Texts.t("ui.passives", {"n": run.passives.size(), "max": Config.PASSIVE_LIMIT}), 20, Kit.MUTED))
	for id in run.passives:
		var row := Kit.hbox(8)
		var l := Kit.label(Texts.item_name(id) + " — " + Texts.item_desc(id), 17, Kit.TEXT, true)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		var sell := Kit.button(Texts.t("ui.sell", {"price": Shop.sell_price()}), _on_sell.bind(id), Kit.DANGER.darkened(0.5), 18)
		sell.custom_minimum_size = Vector2(140, 52)
		row.add_child(sell)
		bv.add_child(row)
	right.add_child(bp)
	right.add_child(_btn(Texts.t("ui.leave", {"n": run.fight + 1}), _on_leave, Kit.ACCENT.darkened(0.55)))


func _category(t: String) -> String:
	match t:
		"attack":
			return "EQUIPAMENTO DE ATAQUE"
		"defense":
			return "EQUIPAMENTO DE DEFESA"
		"passive":
			return "ITEM · RARO"
		"death_defy":
			return "MEDALHA · RARA"
		_:
			return "MELHORIA"


func _on_buy() -> void:
	var err := Shop.buy(run)
	SaveGame.save(run)
	_render()
	msg.text = Texts.t(err) if err != "" else Texts.t("ui.bought")


func _on_reroll() -> void:
	Shop.reroll(run)
	SaveGame.save(run)
	_render()


func _on_sell(id: String) -> void:
	Shop.sell(run, id)
	SaveGame.save(run)
	_render()


func _on_leave() -> void:
	run.next_fight()
	SaveGame.save(run)
	finished.emit()
