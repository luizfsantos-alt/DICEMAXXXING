class_name TowerScreen
extends Control
## Tela da torre fora das lutas: portas, recompensa, parada, Loja, Escola, Poço e
## a escolha inicial do Erudito. Cada opção é um ícone grande com o nome curto embaixo e
## um "i" para os detalhes; algumas pedem um dado ou face.

signal finished

## Ilustração da opção: cena 128×128 em assets/tower/ (portas e paradas) ou ícone 64×64 em
## assets/icons/offer/ (ofertas), mostrada grande. Sem arquivo, um disco com a inicial.
const BACKGROUND := "res://assets/backgrounds/tower.jpg"
static var _art := {} ## caminho -> Texture2D ou null (não existe)

var run: RunState
var strip: PlayerStrip
var title: Label
var cards: HBoxContainer
var info: Label
var bottom: HBoxContainer
var sell_row: HBoxContainer
var organizer: Overlay ## Aberto após ganhar uma magia (testes).
var details: Overlay ## Janela de detalhes aberta pelo "i" (testes).

## Lado do ícone de cada opção: o elemento principal do cartão. Encolhe com muitas opções.
const ICON_MAX := 240
const ROW_W := 1200
const CARD_GAP := 36
## Fases cujo título é o nome do lugar (as outras não têm título: as opções falam por si).
const PLACE_TITLES := {"shop": "stops.shop.0", "school": "stops.school.0", "well": "stops.well.0"}


func setup(r: RunState) -> TowerScreen:
	run = r
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var root := Kit.vbox(12)
	var m := Kit.margin(root, 20)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	strip = PlayerStrip.new()
	root.add_child(strip)
	title = Kit.label("", 32, Kit.ACCENT)
	root.add_child(title)
	var mid := CenterContainer.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(mid)
	cards = Kit.hbox(CARD_GAP)
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_child(cards)
	info = Kit.label("", 22, Kit.DANGER)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(info)
	sell_row = Kit.hbox(10)
	root.add_child(sell_row)
	bottom = Kit.hbox(16)
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(bottom)
	Kit.background(self, BACKGROUND)
	refresh()
	return self


func refresh() -> void:
	var h := run.hero
	strip.refresh(run, self)
	title.text = Texts.t(PLACE_TITLES[run.phase]) if PLACE_TITLES.has(run.phase) else ""
	title.visible = title.text != ""
	Kit.clear(cards)
	var px := icon_px(run.options.size())
	for i in run.options.size():
		cards.add_child(_card(i, run.options[i], px))
	Kit.clear(sell_row)
	if run.phase == "shop" and not h.inventory.items.is_empty():
		sell_row.add_child(Kit.label(Texts.t("ui.sell_title"), 20, Kit.MUTED))
		for k in h.inventory.items.size():
			var it: Dictionary = h.inventory.items[k]
			var idx := k
			var b := Kit.button(Texts.t("ui.sell", {"name": Texts.spell_name(it.id), "n": Spells.sell_price(str(it.id), int(it.level))}),
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
	elif run.phase == "master_rare":
		_bottom_btn(Texts.t("ui.cancel"), _leave)


func _bottom_btn(t: String, cb: Callable) -> void:
	var b := Kit.button(t, cb, Kit.PANEL_HI, 24)
	b.custom_minimum_size = Vector2(240, 64)
	bottom.add_child(b)


## Lado do ícone para n opções lado a lado na largura da tela.
static func icon_px(n: int) -> int:
	return mini(ICON_MAX, (ROW_W - CARD_GAP * maxi(0, n - 1)) / maxi(1, n))


## Por que a opção não pode ser escolhida agora ("" se pode).
func _blocked(o: Dictionary, price: int) -> String:
	if o.kind == "spell" and not run.hero.inventory.fits(o.id):
		return Texts.t("ui.fits_no")
	if price > run.coins:
		return Texts.t("ui.not_enough")
	return ""


## Cartão sem moldura: o ícone grande (é ele que escolhe), o nome curto com o "i" dos
## detalhes ao lado (o nome não reage ao toque) e o preço.
func _card(i: int, o: Dictionary, px: int) -> Control:
	var price := Shop.price_of(o, run.hero, {}, run.destroys_used)
	var blocked := _blocked(o, price)
	var v := Kit.vbox(6)
	v.custom_minimum_size = Vector2(px, 0)
	var b := Button.new()
	b.custom_minimum_size = Vector2(px, px)
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	var img := _icon(o)
	b.add_child(img)
	b.disabled = blocked != ""
	if b.disabled:
		img.modulate = Color(0.45, 0.45, 0.5)
	else:
		b.mouse_entered.connect(func(): img.modulate = Color(1.2, 1.2, 1.2))
		b.mouse_exited.connect(func(): img.modulate = Color.WHITE)
		b.button_down.connect(func(): img.modulate = Color(0.8, 0.8, 0.8))
		b.button_up.connect(func(): img.modulate = Color.WHITE)
	b.pressed.connect(func(): _pick(i))
	v.add_child(b)
	var row := Kit.hbox(8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var rar := offer_rarity(o)
	var col: Color = Kit.TEXT if rar in ["", "common"] else Kit.RARITY_COLORS[rar]
	var name := Kit.label(short_name(o), 24, col, true)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.custom_minimum_size = Vector2(px - 56, 0)
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_outline(name)
	row.add_child(name)
	row.add_child(_info_btn(func(): open_details(i)))
	v.add_child(row)
	if blocked != "":
		var bl := Kit.label(blocked, 20, Kit.DANGER)
		bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_outline(bl)
		v.add_child(bl)
	elif not (run.phase in ["doors", "rest"]):
		var p: Control
		if price == 0:
			p = Kit.label(Texts.t("ui.free"), 22, Kit.ACCENT)
		else:
			p = Kit.price_tag(Texts.t("ui.price", {"n": price}))
			(p as HBoxContainer).alignment = BoxContainer.ALIGNMENT_CENTER
		if p is Label:
			p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		for l in [p] + p.get_children():
			if l is Label:
				_outline(l)
		v.add_child(p)
	return v


## Contorno escuro: o texto fica solto sobre o fundo da torre.
static func _outline(l: Label) -> void:
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)


## Ilustração cobrindo o botão; sem arte, um disco com a inicial do nome.
func _icon(o: Dictionary) -> Control:
	var tex := art(o)
	if tex:
		var img := TextureRect.new()
		img.texture = tex
		img.set_anchors_preset(Control.PRESET_FULL_RECT)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return img
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var letter := short_name(o).left(1)
	c.draw.connect(func():
		var r := minf(c.size.x, c.size.y) * 0.42
		c.draw_circle(c.size * 0.5, r, Kit.PANEL_HI)
		var fs := int(r)
		c.draw_string(ThemeDB.fallback_font, Vector2(0, c.size.y * 0.5 + fs * 0.35), letter,
			HORIZONTAL_ALIGNMENT_CENTER, c.size.x, fs, Kit.TEXT))
	return c


## Botão redondo "i": abre os detalhes da opção sem escolhê-la.
static func _info_btn(cb: Callable) -> Button:
	var b := Button.new()
	b.text = "i"
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(44, 44)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 24)
	for st in ["normal", "hover", "pressed"]:
		var sb := Kit.box(Kit.PANEL_HI.lightened(0.15 if st == "hover" else 0.0), 22, 0)
		sb.set_border_width_all(2)
		sb.border_color = Kit.MUTED
		b.add_theme_stylebox_override(st, sb)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", Kit.TEXT)
	b.pressed.connect(cb)
	return b


## Detalhes da opção: nome completo, raridade, descrição (elementos tocáveis) e o
## botão de escolher, para quem decidiu lendo.
func open_details(i: int) -> Overlay:
	var o: Dictionary = run.options[i]
	var lines := _describe(o)
	var price := Shop.price_of(o, run.hero, {}, run.destroys_used)
	var blocked := _blocked(o, price)
	details = Overlay.open(self, lines[0], Texts.t("ui.cancel") if blocked == "" else "OK", 640)
	var rar := offer_rarity(o)
	if rar != "":
		details.add_text(Texts.t("rarity." + rar), 16, Kit.RARITY_COLORS[rar])
	if str(lines[1]) != "":
		details.body.add_child(ElementInfo.rich(lines[1], 22, Kit.TEXT))
	if blocked != "":
		details.add_text(blocked, 20, Kit.DANGER)
	else:
		var d := details
		var ch := Kit.button(Texts.t("ui.choose"), func():
			d.close()
			_pick(i), Kit.PANEL_HI, 24)
		ch.custom_minimum_size = Vector2(220, 60)
		details.footer.add_child(ch)
	return details


## Nome curto embaixo do ícone (até 5 palavras): o que a pessoa ganha. Portas: só o nome.
func short_name(o: Dictionary) -> String:
	match str(o.kind):
		"door":
			return Texts.t("doors." + o.id)
		"stop":
			return Texts.t("stops.%s.0" % o.id)
		"spell":
			return Texts.spell_name(o.id)
		"die":
			return Texts.t("short.die", {"name": Texts.element_name(o.id)}) if o.id != "" else Texts.t("short.die_plain")
		"element":
			return Texts.t("short.element", {"name": Texts.element_name(o.id)})
		"evolve":
			return Texts.t("short.evolve", {"name": Texts.spell_name(o.id)})
	return Texts.t("short." + o.kind)


## Caminho da ilustração da opção (existindo ou não).
static func art_path(o: Dictionary) -> String:
	match str(o.kind):
		"door":
			return "res://assets/tower/door_%s.png" % o.id
		"stop":
			return "res://assets/tower/stop_%s.png" % o.id
	return "res://assets/icons/offer/%s.png" % o.kind


static func art(o: Dictionary) -> Texture2D:
	var path := art_path(o)
	if not _art.has(path):
		_art[path] = load(path) if ResourceLoader.exists(path) else null
	return _art[path]


## Raridade da magia ou do elemento oferecido ("" se não tem).
static func offer_rarity(o: Dictionary) -> String:
	match str(o.kind):
		"spell", "evolve":
			return Spells.rarity(o.id)
		"die", "element":
			return Elements.rarity(o.id) if o.id != "" else ""
	return ""


func _describe(o: Dictionary) -> Array:
	match str(o.kind):
		"door":
			if o.id == "mestre":
				var mid := EnemyFactory.master_of(run.floor_n) if run else ""
				if mid == "":
					mid = "porteiro"
				return [Texts.t("doors.mestre"), Texts.master_name(mid) + ": " + Texts.master_desc(mid)]
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
			return [Texts.t("offers.evolve", {"name": Texts.spell_name(o.id), "lvl": lvl}), evolve_text(o.id, lvl)]
		"slots":
			return [Texts.t("offers.slots"), Texts.t("offers.slots_desc")]
		"hand":
			return [Texts.t("offers.hand"), Texts.t("offers.hand_desc", {"n": run.hero.hand_size + 1})]
		"rare_pick":
			return [Texts.t("offers.rare_pick"), Texts.t("offers.rare_pick_desc")]
	return [Texts.t("offers." + o.kind), ""]


## Escola: como a magia fica no nível "lvl", comparada com o nível atual.
static func evolve_text(id: String, lvl: int) -> String:
	return "\n".join(PackedStringArray([
		Texts.t("ui.evolve_now", {"n": lvl - 1, "fx": Texts.spell_fx(id, lvl - 1)}),
		Texts.t("ui.evolve_next", {"n": lvl, "fx": Texts.spell_fx(id, lvl)}),
	]))


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
