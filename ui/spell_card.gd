class_name SpellCard
extends PanelContainer
## Magia na luta: cartão de tamanho padrão no palco (o formato só importa no grimório).
## Ícone do tipo de efeito, nome, efeito curto, uso, um buraco por dado pedido e a prévia do resultado.

signal tapped(item: int)

const FX_COLORS := {
	"dmg": Color(0.94, 0.44, 0.37),
	"block": Color(0.44, 0.66, 1.0), "dodge": Color(0.5, 0.83, 0.86), "mirror": Color(0.76, 0.65, 1.0),
	"heal": Color(0.44, 0.82, 0.55), "maxhp": Color(0.44, 0.82, 0.55), "sacrifice": Color(0.76, 0.65, 1.0),
}
const CARD := Color(0.114, 0.102, 0.141)
const CARD_HI := Color(0.149, 0.125, 0.173)
const LINE := Color(0.227, 0.204, 0.271)
const ICON_DIR := "res://assets/icons/"
static var _icons := {} ## chave -> Texture2D ou null (não existe)

var fighter: Fighter
var item := -1
var id := ""
var compact := false
var holes: Array = []
var name_label: Label
var tag_label: Label
var fx_label: Label
var preview: Label
var icon_rect: TextureRect
var _hi := Color.TRANSPARENT ## Borda de destaque desenhada por cima da moldura (textura).
var _hi_w := 0
var shown_used = null ## Durante a animação: lista de usadas exibida (null = estado real).


func setup(f: Fighter, i: int, hole_px: int, is_compact := false) -> SpellCard:
	fighter = f
	item = i
	id = str(f.inventory.items[i].id)
	compact = is_compact
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP
	name_label = Kit.label(Texts.spell_name(id), 20 if compact else 24, Kit.TEXT)
	name_label.add_theme_font_override("font", Kit.title_font())
	tag_label = Kit.label("", 16, Kit.ACCENT)
	fx_label = Kit.label(spell_fx(id, int(f.inventory.items[i].level)), 16 if compact else 19, Color(0.85, 0.83, 0.89), true)
	preview = Kit.label("", 19, Kit.TEXT, true)
	icon_rect = TextureRect.new()
	icon_rect.texture = icon(Spells.icon_key(id))
	icon_rect.custom_minimum_size = Vector2.ONE * (26 if compact else 32)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_rect.visible = icon_rect.texture != null
	# O cartão tem tamanho padrão no palco (FitGrid): textos longos não o esticam.
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	fx_label.max_lines_visible = 3
	preview.max_lines_visible = 2
	var hrow := Kit.hbox(6)
	hrow.alignment = BoxContainer.ALIGNMENT_BEGIN
	var n := hole_count(id)
	for k in n:
		if k > 0:
			hrow.add_child(_joiner())
		var h := Hole.new().set_interactive(false).setup(hole_px)
		hrow.add_child(h)
		holes.append(h)
	if compact:
		var row := Kit.hbox(8)
		add_child(row)
		var tv := Kit.vbox(0)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var head := Kit.hbox(6)
		head.add_child(icon_rect)
		head.add_child(name_label)
		head.add_child(tag_label)
		tv.add_child(head)
		tv.add_child(fx_label)
		row.add_child(tv)
		hrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(hrow)
	else:
		var v := Kit.vbox(4)
		add_child(v)
		var head := Kit.hbox(8)
		head.alignment = BoxContainer.ALIGNMENT_BEGIN
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(icon_rect)
		head.add_child(name_label)
		v.add_child(head)
		v.add_child(fx_label)
		v.add_child(tag_label)
		var sp := Control.new()
		sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(sp)
		hrow.add_theme_constant_override("separation", 6)
		hrow.alignment = BoxContainer.ALIGNMENT_CENTER # buracos no meio do cartão
		v.add_child(hrow)
		v.add_child(preview)
	refresh([], [], -1)
	return self


## Buracos no cartão: um por dado pedido; o Ajuste Fino tem dois (+1 e −1), para um dado só.
static func hole_count(spell: String) -> int:
	return 2 if str(Spells.get_def(spell).get("mod", "")) == "nudge" else Spells.dice_needed(spell)


func _joiner() -> Label:
	var t := "=" if str(Spells.get_def(id).req) in ["pair", "trio"] else "›"
	if hole_count(id) != Spells.dice_needed(id):
		t = Texts.t("ui.or")
	var j := Kit.label(t, 20 if t.length() < 2 else 15, Hole.REQ_COLOR)
	j.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return j


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
		tapped.emit(item)
		accept_event()


## Textura do ícone (assets/icons/<chave>.png), ou null se ainda não há arte.
static func icon(key: String) -> Texture2D:
	if not _icons.has(key):
		var path := ICON_DIR + key + ".png"
		_icons[key] = load(path) if ResourceLoader.exists(path) else null
	return _icons[key]


static func spell_fx(spell: String, level := 1) -> String:
	return Texts.spell_fx(spell, level)


func used() -> bool:
	var lst: Array = shown_used if shown_used != null else fighter.once_used
	var lim := Spells.max_uses(id)
	return lim > 0 and lst.count(item) >= lim


## Fundo do cartão. Com a moldura da raridade (assets/ui/card_<raridade>.png), o fundo é a
## textura (escurecida se usada/recusada) e a borda de destaque é desenhada por cima.
func _style(bg: Color, border: Color, width: int) -> StyleBox:
	var tint := Color(0.6, 0.58, 0.62) if bg.v < CARD.v else Color.WHITE
	var tex := Kit.nine("card_" + Spells.rarity(id), 12 if compact else 16, tint)
	if tex:
		_hi = border if width > 1 else Color.TRANSPARENT
		_hi_w = width + 1
		queue_redraw()
		return tex
	var sb := Kit.box(bg, 14, 10 if compact else 12)
	sb.set_border_width_all(width)
	sb.border_color = border
	return sb


func _draw() -> void:
	if _hi.a > 0.0:
		var sb := Kit.box(Color.TRANSPARENT, 10, 0)
		sb.set_border_width_all(_hi_w)
		sb.border_color = _hi
		draw_style_box(sb, Rect2(Vector2(3, 3), size - Vector2(6, 6)))


## Texto no fundo do buraco k.
func _req_text(placed: Array, k: int) -> String:
	var d := Spells.get_def(id)
	match str(d.get("mod", "")):
		"nudge":
			return "+1" if k == 0 else "−1"
		"echo", "fuse":
			return "%dº" % (k + 1)
	match str(d.req):
		"max", "max_n":
			return "≤ %d" % int(d.v)
		"min", "min_n":
			return "≥ %d" % int(d.v)
		"exact":
			return str(int(d.v))
		"odd":
			return "ímpar"
		"even":
			return "par"
		"top":
			return "MÁX"
		"low_one":
			return "≤ %d" % int(d.v) if k == holes.size() - 1 else ""
		"pair", "trio":
			return str(placed[0]) if not placed.is_empty() else ""
	return ""


## values: dados postos (valores); sel: valor do dado selecionado (-1 = nenhum).
## tops: face mais alta, por dado posto; sel_top: o dado selecionado está na face mais alta.
## sel_ok: o dado selecionado passa nas regras fora do valor (mexido, cópia); sel_die e
## sel_plus: o dado selecionado, para a prévia das mexidas (chance de subir). marks: [+2, ouro]
## da face de cada dado posto (selos dos adesivos).
func refresh(values: Array, elements: Array, sel: int, tops: Array = [], sel_top := false, heats: Array = [],
		sel_ok := true, sel_die: Die = null, sel_plus := 0, marks: Array = []) -> void:
	var is_used := used()
	var lvl := int(fighter.inventory.items[item].level)
	fx_label.text = spell_fx(id, lvl) ## O efeito acompanha o nível (evoluir muda o texto).
	var tags := []
	if bool(fighter.inventory.items[item].get("temp", false)):
		tags.append(Texts.t("ui.copy_tag"))
	if lvl > 1:
		tags.append(Texts.t("ui.level", {"n": lvl}))
	if is_used:
		tags.append(Texts.t("ui.used").to_upper())
	elif Spells.is_once(id):
		tags.append(Texts.t(Spells.use_key(id)).to_upper())
	tag_label.text = "  ".join(tags)
	tag_label.add_theme_color_override("font_color", Kit.MUTED if is_used else Kit.ACCENT)
	var accepts := sel >= 0 and sel_ok and not is_used and Spells.accepts_partial(id, values, sel, sel_top)
	var two := hole_count(id) != Spells.dice_needed(id) ## Ajuste Fino: os dois buracos acendem.
	for k in holes.size():
		var h: Hole = holes[k]
		if k < values.size():
			h.set_die(int(values[k]), elements[k] if k < elements.size() else "", float(heats[k]) if k < heats.size() else 0.0)
			var mk: Array = marks[k] if k < marks.size() else [0, 0]
			h.set_marks(int(mk[0]), int(mk[1]))
		else:
			h.clear_die()
		h.req = _req_text(values, k)
		h.lit = accepts and (k == values.size() or two) and not (two and k == 1 and sel <= 1)
		h.queue_redraw()
	var col: Color = FX_COLORS.get(Spells.color_family(id), Kit.TEXT)
	var ready := Spells.complete(id, values, tops)
	modulate.a = 1.0
	preview.text = ""
	if is_used:
		add_theme_stylebox_override("panel", _style(Color(0.09, 0.08, 0.11), LINE, 1))
		modulate.a = 0.6
	elif sel >= 0 and not accepts and values.size() < holes.size():
		add_theme_stylebox_override("panel", _style(Color(0.1, 0.09, 0.125), LINE, 1))
		modulate.a = 0.5
		if not compact:
			preview.text = Texts.t("ui.no_accept", {"v": sel})
			preview.add_theme_color_override("font_color", Kit.MUTED)
	elif accepts:
		add_theme_stylebox_override("panel", _style(CARD_HI, Kit.ACCENT, 2))
	elif ready:
		add_theme_stylebox_override("panel", _style(CARD_HI, col, 2))
	else:
		add_theme_stylebox_override("panel", _style(CARD, LINE, 1))
	if ready and not compact:
		preview.text = preview_text(fighter, item, values)
		preview.add_theme_color_override("font_color", col.lightened(0.15))
	elif accepts and not compact and Spells.is_mod(id):
		var all := values.duplicate()
		all.append(sel)
		preview.text = mod_preview(fighter, item, all, sel_die, sel_plus)
		preview.add_theme_color_override("font_color", Kit.ACCENT)


## Prévia da mexida com estes valores (o último é o dado selecionado): o resultado nas
## determinísticas ("→ 6", "→ 2 · 2 · 2") e a chance nas aleatórias (docs/SPEC_v3.1.md §1.5).
static func mod_preview(f: Fighter, i: int, values: Array, sel_die: Die = null, sel_plus := 0) -> String:
	var it: Dictionary = f.inventory.items[i]
	var d := Spells.get_def(str(it.id))
	var lvl := int(it.level)
	var b := lvl - 1
	if values.is_empty():
		return ""
	var v := int(values.back())
	match str(d.get("mod", "")):
		"reroll_max", "gamble":
			if sel_die == null:
				return ""
			var good := 0
			for k in 6:
				var fv := sel_die.value(k) + sel_plus
				if str(d.mod) == "gamble":
					fv *= lvl + 1
				if fv > v:
					good += 1
			var key := "ui.pv_chance_up" if str(d.mod) == "reroll_max" else "ui.pv_chance_better"
			return Texts.t(key, {"p": int(round(100.0 * good / 6.0))})
		"nudge":
			return "→ %d / %d" % [v + 1 + b, maxi(1, v - 1 - b)]
		"top":
			return "→ %d" % ((sel_die.max_value() if sel_die else v) + b)
		"split3":
			@warning_ignore("integer_division")
			var q := v / 3
			var parts := []
			for k in 3:
				parts.append(str(q + (1 if k < v % 3 else 0) + b))
			return "→ " + " · ".join(PackedStringArray(parts))
		"flip":
			return "→ %d" % (7 - v + b)
		"polar":
			return "→ %d" % ((1 if v <= 3 else 6) + b)
		"double":
			return "→ %d" % (v * 2 + b)
		"polish":
			return "→ %d" % (5 + lvl)
		"tide_low":
			return "→ %d · %d" % [Config.TIDE_LOW_VALUE + b, Config.TIDE_LOW_VALUE + b]
		"lingot":
			return "→ %d × 1" % (v + b)
		"insight":
			return Texts.t("ui.pv_insight")
		"avg":
			if values.size() == 2:
				var a := Config.ceil_div(int(values[0]) + int(values[1]), 2) + b
				return "→ %d · %d" % [a, a]
		"echo":
			if values.size() == 2:
				return "→ %d · %d" % [int(values[0]) + b, int(values[0]) + b]
		"fuse":
			if values.size() == 2:
				return "→ %d" % (int(values[0]) + int(values[1]) + b)
		"stairs":
			if values.size() == 3:
				var lo := int(values.min())
				return "→ %d · %d · %d" % [lo + b, lo + 1 + b, lo + 2 + b]
	return ""


## Mostra os dados que o inimigo usou (resolução).
func show_cast(values: Array) -> void:
	refresh(values, [], -1)
	flash()


## Brilho rápido (sem mexer na escala, que o palco usa para encolher os cartões).
func flash() -> void:
	var m0 := modulate
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1.45, 1.35, 1.1, m0.a), 0.1)
	tw.tween_property(self, "modulate", m0, 0.2)


## "→ 6 de dano", "→ 9 bloq"… com os valores postos (exigência completa).
static func preview_text(f: Fighter, i: int, values: Array) -> String:
	var it: Dictionary = f.inventory.items[i]
	var spell := str(it.id)
	var d := Spells.get_def(spell)
	var lvl := int(it.level)
	var mult := int(d.get("mult", 1))
	var bonus := Resolver.dmg_bonus(f)
	var total := 0
	var prod := 1
	for v in values:
		total += int(v)
		prod *= int(v)
	var hi := 0
	var lo := 999
	for v in values:
		hi = maxi(hi, int(v))
		lo = mini(lo, int(v))
	var s := ""
	match str(d.fx):
		"dmg":
			s = Texts.t("ui.pv_dmg", {"n": Config.scale((total + int(d.get("plus", 0))) * mult, lvl) + bonus})
			if d.get("odd_twice", false) and values.all(func(x): return int(x) % 2 == 1):
				s += " ×2"
			if d.has("burn"):
				s += " · " + Texts.t("ui.burn", {"n": d.burn}).to_lower()
			if d.get("pierce", false):
				s += " · " + Texts.t("ui.pv_pierce")
		"product":
			s = Texts.t("ui.pv_dmg", {"n": Config.scale(prod * mult, lvl) + bonus})
		"lever":
			s = Texts.t("ui.pv_dmg", {"n": Config.scale(hi * lo, lvl) + bonus})
		"top_x":
			s = Texts.t("ui.pv_dmg", {"n": Config.scale(hi * mult, lvl) + bonus})
		"multi":
			var blows := []
			for v in values:
				blows.append(str(Config.scale(int(v) * mult, lvl) + bonus))
			if values.size() > 1 and values.all(func(x): return int(x) == int(values[0])):
				blows.append_array(blows.duplicate())
			s = Texts.t("ui.pv_multi", {"list": " + ".join(PackedStringArray(blows))})
		"ones":
			var ones := 0
			for e in f.hand:
				if int(e.bag) != -2 and int(e.value) == 1:
					ones += 1
			s = Texts.t("ui.pv_dmg", {"n": Config.scale(int(d.get("per", 1)) * ones, lvl) + bonus})
		"encore":
			s = Texts.t("ui.pv_encore", {"n": Config.scale(total, lvl) + bonus})
		"steal_sticker":
			s = Texts.t("ui.pv_steal", {"n": Config.scale(total, lvl) + bonus})
		"bench":
			s = Texts.t("ui.pv_dmg", {"n": Config.scale(total, lvl) + bonus}) + " · " + Texts.t("ui.pv_bench")
		"spawn_half":
			s = Texts.t("ui.pv_dmg", {"n": Config.scale(total, lvl) + bonus}) + " · " + Texts.t("ui.pv_spawn", {"v": Config.ceil_div(total, 2)})
		"spawn_copy":
			s = "→ " + Texts.t("ui.pv_spawn", {"v": Config.scale(total, lvl)})
		"debuff":
			if lvl > 1:
				s = Texts.t("ui.pv_dmg", {"n": total * (lvl - 1) + bonus})
		"block":
			s = Texts.t("ui.pv_block", {"n": Config.scale(total * mult, lvl)})
		"block_product":
			s = Texts.t("ui.pv_block", {"n": Config.scale(prod * mult, lvl)})
		"block_hand":
			s = Texts.t("ui.pv_block", {"n": Config.scale(int(d.get("per", 1)) * Resolver._hand_count(f), lvl)})
		"skin":
			s = Texts.t("ui.pv_skin", {"n": mini(f.skin + 1, Config.SKIN_CAP + lvl - 1)})
		"tide_out":
			s = Texts.t("ui.pv_tide_out", {"n": Config.TIDE_ONES + lvl - 1})
		"block_count":
			s = Texts.t("ui.pv_block", {"n": Config.scale(int(d.get("per", 1)) * Resolver.count_value(f, int(d.get("count", 1))), lvl)})
		"riposte":
			s = Texts.t("ui.pv_block", {"n": Config.scale(total * mult, lvl)}) + " · " + Texts.t("ui.pv_riposte", {"n": Config.scale(total, lvl)})
		"immune":
			s = Texts.t("ui.pv_block", {"n": Config.scale(total * mult, lvl)}) + " · " + Texts.t("ui.pv_immune")
		"cleanse":
			s = Texts.t("ui.pv_cleanse") + " · " + Texts.t("ui.pv_block", {"n": Config.scale(total, lvl)}).trim_prefix("→ ")
		"recycle":
			s = Texts.t("ui.pv_recycle")
		"dodge":
			s = Texts.t("ui.pv_dodge")
		"mirror":
			s = Texts.t("ui.pv_mirror")
		"heal":
			s = Texts.t("ui.pv_heal", {"n": Config.scale(total * mult, lvl)})
		"drain":
			s = Texts.t("ui.pv_dmg", {"n": Config.scale(total, lvl) + bonus}) + " · " + Texts.t("ui.pv_heal", {"n": Config.ceil_div(Config.scale(total, lvl), 2)}).trim_prefix("→ ")
		"feast":
			s = Texts.t("ui.pv_dmg", {"n": Config.scale(total, lvl) + bonus}) + " · " + Texts.t("ui.pv_heal", {"n": Config.scale(lo, lvl)}).trim_prefix("→ ")
		"maxhp":
			s = Texts.t("ui.pv_maxhp", {"n": Config.scale(int(values[0]), lvl)})
		"sacrifice":
			s = Texts.t("ui.pv_sacrifice", {"n": Config.scale(Config.SACRIFICE_BONUS, lvl)})
	if d.has("hand_mod"):
		var m := Texts.t("ui.mod_" + str(d.hand_mod))
		s = (s + " · " + m) if s != "" else "→ " + m
	if d.has("mark"):
		s += " · " + Texts.t("ui.pv_mark")
	return s
