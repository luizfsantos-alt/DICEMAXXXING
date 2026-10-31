class_name ShopScreen
extends Control
## Loja: 1 oferta por visita, rerrolagem grátis limitada, venda de passivos.

signal finished

var run: RunState
var body: VBoxContainer
var msg: Label


func setup(r: RunState) -> ShopScreen:
	run = r
	set_anchors_preset(Control.PRESET_FULL_RECT)
	body = Kit.vbox(16)
	var m := Kit.margin(body, 24)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	_render()
	return self


func _render() -> void:
	Kit.clear(body)
	body.add_child(Kit.label(Texts.t("ui.shop"), 44, Kit.ACCENT))
	body.add_child(Kit.label(Texts.t("ui.coins", {"n": run.coins}), 28))

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
		var buy := Kit.button(Texts.t("ui.buy", {"price": o.price}), _on_buy, Kit.OK.darkened(0.45))
		buy.disabled = run.coins < int(o.price)
		cv.add_child(buy)
	body.add_child(card)

	var rr := Kit.button(Texts.t("ui.reroll", {"n": run.rerolls}), _on_reroll)
	rr.disabled = run.rerolls <= 0
	body.add_child(rr)

	msg = Kit.label("", 22, Kit.ACCENT, true)
	body.add_child(msg)

	var bp := Kit.panel()
	var bv := Kit.vbox(8)
	bp.add_child(bv)
	bv.add_child(Kit.label("Vida máxima: %d" % run.player_max_hp(), 22))
	bv.add_child(Kit.label("Ataque: " + Texts.item_name(run.attack_id), 22))
	bv.add_child(Kit.label("Defesa: " + Texts.item_name(run.defense_id), 22))
	if run.death_defy:
		bv.add_child(Kit.label(Texts.t("ui.death_defy_owned"), 22, Kit.ACCENT))
	bv.add_child(Kit.label(Texts.t("ui.passives", {"n": run.passives.size(), "max": Config.PASSIVE_LIMIT}), 22, Kit.MUTED))
	for id in run.passives:
		var row := Kit.hbox(8)
		var l := Kit.label(Texts.item_name(id) + " — " + Texts.item_desc(id), 18, Kit.TEXT, true)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		var sell := Kit.button(Texts.t("ui.sell", {"price": Shop.sell_price()}), _on_sell.bind(id), Kit.DANGER.darkened(0.5), 20)
		sell.custom_minimum_size = Vector2(150, 64)
		row.add_child(sell)
		bv.add_child(row)
	body.add_child(bp)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(spacer)
	body.add_child(Kit.button(Texts.t("ui.leave", {"n": run.fight + 1}), _on_leave, Kit.ACCENT.darkened(0.55)))


func _category(t: String) -> String:
	match t:
		"attack":
			return "EQUIPAMENTO DE ATAQUE"
		"defense":
			return "EQUIPAMENTO DE DEFESA"
		"passive":
			return "PASSIVO · RARO"
		"death_defy":
			return "ITEM RARO"
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
