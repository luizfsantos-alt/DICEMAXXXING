class_name EndScreen
extends Control
## Fim da jornada: vitória da masmorra ou "perdeu, morreu".
## Na derrota, a "nota de falecimento": quem venceu (foto, nome e uma fala seca), o andar
## e um título póstumo irônico. Na vitória, o herói com o título conferido e a sua fala.
## Embaixo, a ata (estatísticas) e a build final.

signal finished

const BACKGROUNDS := {true: "res://assets/backgrounds/victory.jpg", false: "res://assets/backgrounds/defeat.jpg"}
const PHOTO_H := 250

var won := false
var quote_label: Label ## Fala do vencedor (testes).
var honor_label: Label ## Título póstumo ou conferido (testes).


func setup(r: RunState) -> EndScreen:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	won = r.phase == "victory"
	# Sorteio fixo por jornada: reabrir a tela não troca a fala.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([r.rng.seed, r.floor_n, r.stats.wins])
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(cc)
	var v := Kit.vbox(14)
	v.custom_minimum_size = Vector2(1180, 0)
	cc.add_child(v)
	Kit.background(self, BACKGROUNDS[won], 0.45 if won else 0.6)
	var t := Kit.title(Texts.t("ui.victory_title" if won else "ui.defeat_title"), 58, Kit.ACCENT if won else Kit.DANGER, 10)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)

	var cols := Kit.hbox(16)
	v.add_child(cols)
	cols.add_child(_hero_panel(r, rng))
	cols.add_child(_stats_panel(r))
	cols.add_child(_build_panel(r))

	var b := Kit.button(Texts.t("ui.menu"), func(): finished.emit(), Kit.PANEL_HI, 28)
	b.custom_minimum_size = Vector2(0, 72)
	v.add_child(b)
	return self


## Quem fica na foto: o vencedor. Na derrota é o inimigo; na vitória, o herói.
func _hero_panel(r: RunState, rng: RandomNumberGenerator) -> Control:
	var p := Kit.panel()
	p.custom_minimum_size = Vector2(380, 0)
	var pv := Kit.vbox(6)
	p.add_child(pv)
	var who: Fighter = r.hero if (won or r.nemesis == null) else r.nemesis
	var photo := Portrait.new().setup(who, PHOTO_H, who.is_player)
	pv.add_child(photo)
	var name := Texts.t("ui.you") if who.is_player else who.name
	var head := Texts.t("end.victory_by" if won else "end.defeat_by", {"name": name})
	var hl := Kit.title(head, 24, Kit.TEXT, 0)
	hl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pv.add_child(hl)
	pv.add_child(Kit.label(Texts.t("end.victory_where" if won else "end.defeat_where", {"floor": r.floor_n}), 18, Kit.MUTED, true))
	var quotes: Array = Texts.data().get("end", {}).get("victory_quotes" if won else "taunts", [])
	if not quotes.is_empty():
		quote_label = Kit.label("“%s”" % quotes[rng.randi() % quotes.size()], 22, Kit.ACCENT.lightened(0.3) if won else Kit.TEXT, true)
		pv.add_child(quote_label)
	return p


func _stats_panel(r: RunState) -> Control:
	var p := Kit.panel()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sv := Kit.vbox(8)
	p.add_child(sv)
	sv.add_child(Kit.title(Texts.t("end.stats_title"), 24, Kit.MUTED, 0))
	sv.add_child(Kit.label(Texts.t("ui.stats", {"floor": r.floor_n,
		"wins": r.stats.wins, "dealt": r.stats.dealt, "taken": r.stats.taken, "coins": r.stats.coins}), 20))
	# Título irônico (póstumo) ou merecido (conferido), como num diploma.
	var key := "victory_titles" if won else "posthumous_titles"
	var titles: Array = Texts.data().get("end", {}).get(key, [])
	if not titles.is_empty():
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([r.rng.seed, key])
		sv.add_child(Kit.label(Texts.t("end.conferred" if won else "end.posthumous"), 18, Kit.MUTED))
		honor_label = Kit.title(str(titles[rng.randi() % titles.size()]), 26, Kit.ACCENT, 0)
		honor_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sv.add_child(honor_label)
	return p


func _build_panel(r: RunState) -> Control:
	var bp := Kit.panel()
	bp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bv := Kit.vbox(6)
	bp.add_child(bv)
	bv.add_child(Kit.title(Texts.t("ui.build"), 24, Kit.MUTED, 0))
	bv.add_child(Kit.label(Texts.t("ui.consult_hp", {"hp": maxi(0, r.hero.hp), "max": r.hero.max_hp}), 20))
	var g := GrimoireView.new().setup(r.hero.inventory, 56, null)
	g.compact = true
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bv.add_child(g)
	# A bolsa resumida como na torre: um dado por elemento e a quantidade.
	var dice := Kit.hbox(4)
	for c in PlayerStrip.counts(r.hero.bag):
		dice.add_child(DieIcon.new().setup(6, str(c[0]), 34))
		var n := Kit.label("×%d" % int(c[1]), 18, Elements.COLORS.get(str(c[0]), Kit.TEXT))
		n.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dice.add_child(n)
	bv.add_child(dice)
	var stick := 0
	for d in r.hero.bag:
		stick += d.sticker_count()
	bv.add_child(Kit.label(Texts.t("ui.bag", {"n": r.hero.bag.size()}) + "  ·  " + Texts.t("ui.consult_stickers", {"n": stick}), 18, Kit.MUTED, true))
	return bp
