class_name SpellCard
extends PanelContainer
## Magia na luta: cartão de tamanho fixo (o formato só importa no grimório).
## Nome, efeito curto, uso, um buraco por dado pedido e a prévia do resultado.

signal tapped(item: int)

const FX_COLORS := {
	"dmg": Color(0.94, 0.44, 0.37),
	"block": Color(0.44, 0.66, 1.0), "dodge": Color(0.5, 0.83, 0.86), "mirror": Color(0.76, 0.65, 1.0),
	"heal": Color(0.44, 0.82, 0.55), "maxhp": Color(0.44, 0.82, 0.55), "sacrifice": Color(0.76, 0.65, 1.0),
}
const CARD := Color(0.114, 0.102, 0.141)
const CARD_HI := Color(0.149, 0.125, 0.173)
const LINE := Color(0.227, 0.204, 0.271)

var fighter: Fighter
var item := -1
var id := ""
var compact := false
var holes: Array = []
var name_label: Label
var tag_label: Label
var fx_label: Label
var preview: Label
var shown_used = null ## Durante a animação: lista de usadas exibida (null = estado real).


func setup(f: Fighter, i: int, hole_px: int, is_compact := false) -> SpellCard:
	fighter = f
	item = i
	id = str(f.inventory.items[i].id)
	compact = is_compact
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP
	name_label = Kit.label(Texts.spell_name(id), 20 if compact else 24, Kit.TEXT)
	tag_label = Kit.label("", 14, Kit.ACCENT)
	fx_label = Kit.label(spell_fx(id), 15 if compact else 17, Color(0.85, 0.83, 0.89), true)
	preview = Kit.label("", 19, Kit.TEXT, true)
	var hrow := Kit.hbox(6)
	hrow.alignment = BoxContainer.ALIGNMENT_BEGIN
	var n := Spells.dice_needed(id)
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
		v.add_child(name_label)
		v.add_child(fx_label)
		v.add_child(tag_label)
		var sp := Control.new()
		sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(sp)
		hrow.add_theme_constant_override("separation", 6)
		v.add_child(hrow)
		v.add_child(preview)
	refresh([], [], -1)
	return self


func _joiner() -> Label:
	var j := Kit.label("=" if str(Spells.get_def(id).req) in ["pair", "trio"] else "›", 20, Hole.REQ_COLOR)
	j.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return j


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
		tapped.emit(item)
		accept_event()


static func spell_fx(spell: String) -> String:
	var s := Texts.t("spell_fx." + spell)
	return s if s != "spell_fx." + spell else Texts.spell_desc(spell)


func used() -> bool:
	var lst: Array = shown_used if shown_used != null else fighter.once_used
	var lim := Spells.max_uses(id)
	return lim > 0 and lst.count(item) >= lim


func _style(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var sb := Kit.box(bg, 14, 10 if compact else 12)
	sb.set_border_width_all(width)
	sb.border_color = border
	return sb


## Texto no fundo do buraco k.
func _req_text(placed: Array, k: int) -> String:
	var d := Spells.get_def(id)
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
func refresh(values: Array, elements: Array, sel: int, tops: Array = [], sel_top := false) -> void:
	var is_used := used()
	var lvl := int(fighter.inventory.items[item].level)
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
	var accepts := sel >= 0 and not is_used and Spells.accepts_partial(id, values, sel, sel_top)
	for k in holes.size():
		var h: Hole = holes[k]
		if k < values.size():
			h.set_die(int(values[k]), elements[k] if k < elements.size() else "")
		else:
			h.clear_die()
		h.req = _req_text(values, k)
		h.lit = accepts and k == values.size()
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


## Mostra os dados que o inimigo usou (resolução).
func show_cast(values: Array) -> void:
	refresh(values, [], -1)
	flash()


func flash() -> void:
	pivot_offset = size / 2.0
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.04, 1.04), 0.1)
	tw.tween_property(self, "scale", Vector2.ONE, 0.2)


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
			s = "→ " + Texts.t("ui.pv_spawn", {"v": total})
		"block":
			s = Texts.t("ui.pv_block", {"n": Config.scale(total * mult, lvl)})
		"block_product":
			s = Texts.t("ui.pv_block", {"n": Config.scale(prod * mult, lvl)})
		"block_hand":
			s = Texts.t("ui.pv_block", {"n": Config.scale(int(d.get("per", 1)) * Resolver._hand_count(f), lvl)})
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
