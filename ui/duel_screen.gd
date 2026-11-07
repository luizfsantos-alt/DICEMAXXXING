class_name DuelScreen
extends Control
## Tela da luta em paisagem (docs/SPEC_v3.md §13), turnos sequenciais (§6).
##
## Três colunas, da esquerda para a direita:
## 1. Personagens: foto do inimigo (com a coluna de status dele à direita), as duas
##    barras de vida juntas no meio, a sua foto (com a sua coluna de status) e, no
##    rodapé, as moedas da jornada.
## 2. Palco compartilhado: as magias de quem está jogando (no seu turno, as suas; na vez
##    do inimigo, as dele). Todas cabem: os cartões encolhem por igual, sem rolagem
##    (FitGrid). Embaixo, o banner, a dica, o resumo, o histórico e "Terminar turno".
## 3. Dados: coluna na altura toda com a mão de quem está jogando.
##
## Fases: "player" (você encaixa dados nas magias), "resolve" (eventos animados: o seu
## turno, depois o turno inteiro do inimigo; tocar acelera) e "over".
## Interação: arraste um dado da mão até uma magia (ou de uma magia para outra; de
## volta para a coluna, ele sai da magia). Também dá para tocar num dado e depois
## numa magia. Toque num dado encaixado para soltá-lo (ou na magia, para soltar
## todos). Não dá para terminar o turno com uma magia de vários dados pela metade.
## Segurar a foto do inimigo mostra as magias dele no palco (só leitura); soltar
## volta. Segurar um ícone de status mostra a descrição.

signal finished
signal stage_changed(side: String) ## O palco passou a mostrar as magias de "side".

const DIE := 92 ## Buraco da mão (tamanho padrão; a coluna encolhe se não couber).
const HOLE := 50 ## Buraco no cartão de magia.
const CARD := Vector2(240, 236) ## Cartão de magia no tamanho padrão.
const STATUS_PX := 40
const LEFT := 300 ## Coluna dos personagens.
const DICE_W := 116 ## Coluna dos dados.
const MARGIN := 14
## Folga extra à direita: no Android, deslizar a partir da borda abre o gesto do sistema
## (voltar/menu); a coluna dos dados fica longe dela para não acioná-lo sem querer.
const EDGE_RIGHT := 56
const GAP := 12
## Cor do efeito que voa da magia até o alvo (e do número que aparece sobre ele).
const FX_COLORS := {
	"heal": Color(0.35, 0.95, 0.45), "dmg": Color(1.0, 0.25, 0.22), "fx": Color(0.35, 0.65, 1.0),
}
const BOLT_TIME := 0.34
const CHAIN_BOLT_TIME := 0.2 ## Voo das ações seguintes da mesma magia.
const CHAIN_DELAY := 0.1 ## Pausa entre ações da mesma magia (vários efeitos de um item).
const BACKGROUND := "res://assets/backgrounds/tavern.jpg"
const BACKGROUND_SHADE := 0.68 ## Escurece bastante o fundo.
const FX_SIZE := 30 ## Números sobre as fotos.
const FX_OUTLINE := 12
const FX_EDGE := 6.0 ## Folga mínima dos números até a borda da tela.
const PANEL_BG := Color(0.098, 0.086, 0.125, 0.82) ## Painéis translúcidos sobre o fundo.
## Fonte grossa dos números sobre as fotos (Bungee, SIL OFL: assets/fonts/Bungee-OFL.txt).
## O texto pode passar da foto; só a arte do personagem fica presa na moldura.
var fx_font: Font = load("res://assets/fonts/Bungee-Regular.ttf") if ResourceLoader.exists("res://assets/fonts/Bungee-Regular.ttf") else null

var run: RunState
var duel: Duel
var fast := false ## Testes: sem esperas.
var phase := "player"
var choice := TurnChoice.new()
var selected := -1
var dragging := -1 ## Dado da mão sendo arrastado.
var _drag_end_frame := -100
var skip := false
var shown := {} ## side -> {hp, max, block}
## side -> Fighter.status_state() exibido: segue o "st" de cada evento animado, então
## cada ícone aparece (e some) quando a ação que o causa acontece.
var status_view := {}
var history: Array = [] ## Linhas do histórico (bbcode).
var summary: Array = [] ## Resumo do turno do inimigo.
var active_side := "player" ## De quem é a vez (o palco e os dados seguem).
var dice_side := "player" ## De quem são os dados na coluna da direita.
var peeking := false ## Segurando a foto do inimigo.
var _stage_shown := ""
var busy := false ## Animação de uma mexida em andamento: o toque espera.
var undo_btn: Button ## "Desfazer [mexida]" com um dado mexido selecionado.

var hud: Label
var enemy_name: Label
var enemy_sub: Label
var player_sub: Label
var enemy_photo: Portrait
var player_photo: Portrait
var bars := {}
var status_cols := {} ## side -> FitGrid de StatusIcon
var status_shown := {} ## side -> lista exibida (para não refazer à toa)
var coins_label: Label
var stage_title: Label
var player_grid: FitGrid
var enemy_grid: FitGrid
var enemy_cards: Array = []
var cards: Array = []
var dice_title: Label
var tray: FitGrid
var tray_views: Array = [] ## Hole por dado da coluna.
var banner: Label
var hint: Label
var info: Label
var end_btn: Button
var catcher: Control
var fx_layer: Control
var tip: PanelContainer ## Descrição do status segurado.
var tip_title: Label
var tip_desc: Label
var tip_icon: StatusIcon
var stage_panel: PanelContainer
const FLY_TO_TRAY := 0.32 ## Voo de cada dado da mesa até a coluna, em segundos.
var roller: DiceRoll3D ## Rolagem 3D em andamento (por cima do palco).
var fx_src = null ## Ponto (camada de efeitos) de onde saem os efeitos: o cartão da última magia.
var fx_bounce = null ## Golpe devolvido (Espelho, Revide): sai da foto de quem devolveu.
var bolts := 0 ## Efeitos disparados (testes).
var chained := false ## A ação atual vem da mesma magia que a anterior.
var content: Control ## Tudo menos o fundo (é o que treme no impacto).
var shaker: ScreenShake
var flash: ColorRect ## Clarão dos golpes enormes.
var last_shake := 0 ## Faixa da última tremida (testes).


func setup(r: RunState) -> DuelScreen:
	run = r
	duel = r.duel
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	_sync_shown()
	_feed_events(duel.turn_events)
	_start_player_phase()
	_intro_roll.call_deferred()
	return self


# ================================================================== Layout
func _build() -> void:
	_build_background()
	var root := Kit.hbox(GAP)
	var m := MarginContainer.new()
	for k in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + k, EDGE_RIGHT if k == "right" else MARGIN)
	m.add_child(root)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	content = m
	root.add_child(_build_fighters())
	root.add_child(_build_stage())
	root.add_child(_build_dice())

	fx_layer = Control.new()
	fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fx_layer)
	flash = ColorRect.new()
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1, 1, 1, 0)
	add_child(flash)
	shaker = ScreenShake.new().setup([content, fx_layer])
	add_child(shaker)
	_build_tip()
	# Durante a resolução, tocar no palco ou nos dados acelera. A coluna dos personagens
	# fica de fora: dá para segurar a foto do inimigo e os ícones a qualquer momento.
	catcher = Control.new()
	catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
	catcher.offset_left = MARGIN + LEFT + GAP * 0.5
	catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	catcher.visible = false
	catcher.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			skip = true)
	add_child(catcher)


## Fundo: a taverna cobrindo a tela inteira, escurecida para os painéis e textos lerem bem.
func _build_background() -> void:
	Kit.background(self, BACKGROUND, BACKGROUND_SHADE)


## Coluna 1: foto do inimigo + status, as duas barras, sua foto + status, moedas.
func _build_fighters() -> VBoxContainer:
	var col := Kit.vbox(8)
	col.custom_minimum_size = Vector2(LEFT, 0)
	var e := duel.enemy
	var p := duel.player

	var erow := _photo_row(e, false)
	col.add_child(erow)
	enemy_photo.mouse_filter = Control.MOUSE_FILTER_STOP
	enemy_photo.gui_input.connect(_on_enemy_photo_input)
	enemy_name = _photo_label(enemy_photo, e.name, 18, Kit.TEXT, true)
	enemy_sub = _photo_label(enemy_photo, "", 13, Kit.MUTED, false)

	var bv := Kit.vbox(4)
	for s in ["enemy", "player"]:
		var b := HpBar.new().setup(Kit.DANGER if s == "enemy" else Kit.OK)
		b.custom_minimum_size = Vector2(0, 34)
		bars[s] = b
		bv.add_child(b)
	col.add_child(bv)

	col.add_child(_photo_row(p, true))
	_photo_label(player_photo, Texts.t("ui.you") + " · " + Texts.t("archetypes." + p.archetype), 18, Kit.TEXT, true)
	player_sub = _photo_label(player_photo, "", 13, Kit.MUTED, false)

	# Moedas: faixa fina no rodapé.
	var strip := PanelContainer.new()
	strip.add_theme_stylebox_override("panel", Kit.box(PANEL_BG, 8, 4))
	var sh := Kit.hbox(8)
	strip.add_child(sh)
	sh.add_child(Kit.coin(20))
	coins_label = Kit.label("", 17, Kit.ACCENT)
	sh.add_child(coins_label)
	col.add_child(strip)
	return col


## Foto do personagem com a coluna de status logo à direita.
func _photo_row(f: Fighter, is_player: bool) -> HBoxContainer:
	var row := Kit.hbox(6)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var photo := Portrait.new().setup(f, 100, is_player)
	photo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(photo)
	var side := "player" if is_player else "enemy"
	var sc := FitGrid.new().setup(Vector2(STATUS_PX, STATUS_PX), 4, true)
	sc.custom_minimum_size = Vector2(STATUS_PX, 0)
	sc.size_flags_horizontal = Control.SIZE_FILL
	row.add_child(sc)
	status_cols[side] = sc
	status_shown[side] = []
	if is_player:
		player_photo = photo
	else:
		enemy_photo = photo
	return row


## Texto sobre a foto: nome no alto ("head"), linha de bolsa embaixo.
func _photo_label(photo: Control, text: String, fs: int, col: Color, head: bool) -> Label:
	var l := Kit.label(text, fs, col, true)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# A arte é escura e passa por baixo do texto.
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_TOP_WIDE if head else Control.PRESET_BOTTOM_WIDE)
	l.offset_left = 12
	l.offset_right = -12
	if head:
		l.offset_top = 8
	else:
		l.grow_vertical = Control.GROW_DIRECTION_BEGIN
		l.offset_bottom = -10
	photo.add_child(l)
	return l


## Coluna 2: palco compartilhado (magias do lado ativo) e o rodapé.
func _build_stage() -> VBoxContainer:
	var col := Kit.vbox(8)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_title = Kit.label("", 15, Kit.MUTED)
	col.add_child(stage_title)
	var stage := PanelContainer.new()
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.add_theme_stylebox_override("panel", Kit.box(PANEL_BG, 18, 10))
	col.add_child(stage)
	stage_panel = stage

	var p := duel.player
	player_grid = FitGrid.new().setup(CARD, 10)
	stage.add_child(player_grid)
	for item in p.inventory.order():
		var c := SpellCard.new().setup(p, item, HOLE)
		c.tapped.connect(_on_card)
		_wire_card(c)
		player_grid.add_child(c)
		cards.append(c)
	var e := duel.enemy
	enemy_grid = FitGrid.new().setup(CARD, 10)
	enemy_grid.visible = false
	stage.add_child(enemy_grid)
	for item in e.inventory.order():
		# Só leitura: tocar não faz nada.
		var c := SpellCard.new().setup(e, item, HOLE)
		enemy_grid.add_child(c)
		enemy_cards.append(c)

	# Rodapé: banner e dica, resumo, histórico/ficha e "Terminar turno".
	var foot := Kit.hbox(10)
	foot.custom_minimum_size = Vector2(0, 88)
	col.add_child(foot)
	var bv := Kit.vbox(2)
	bv.custom_minimum_size = Vector2(170, 0)
	bv.alignment = BoxContainer.ALIGNMENT_CENTER
	banner = Kit.label("", 26, Kit.ACCENT, true)
	bv.add_child(banner)
	hint = Kit.label(Texts.t("ui.hint_place"), 14, Kit.MUTED, true)
	bv.add_child(hint)
	hud = Kit.label("", 13, Kit.MUTED, true)
	bv.add_child(hud)
	undo_btn = Kit.button("", _on_undo, Kit.PANEL_HI, 15)
	undo_btn.custom_minimum_size = Vector2(0, 36)
	undo_btn.visible = false
	bv.add_child(undo_btn)
	foot.add_child(bv)
	info = Kit.label("", 16, Kit.TEXT, true)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info.max_lines_visible = 4
	foot.add_child(info)
	var btns := Kit.vbox(6)
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	var hb := Kit.button(Texts.t("ui.history"), open_history, Kit.PANEL, 16)
	hb.custom_minimum_size = Vector2(124, 40)
	btns.add_child(hb)
	var sb := Kit.button(Texts.t("ui.enemy_sheet"), open_enemy_consult, Kit.PANEL, 16)
	sb.custom_minimum_size = Vector2(124, 40)
	btns.add_child(sb)
	foot.add_child(btns)
	end_btn = Kit.button(Texts.t("ui.end_turn"), _on_end_turn, Kit.ACCENT.darkened(0.45), 22)
	end_btn.custom_minimum_size = Vector2(180, 84)
	end_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	foot.add_child(end_btn)
	return col


## Coluna 3: os dados de quem está jogando, na altura toda.
func _build_dice() -> PanelContainer:
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(DICE_W, 0)
	pc.add_theme_stylebox_override("panel", Kit.box(PANEL_BG, 14, 6))
	var v := Kit.vbox(6)
	pc.add_child(v)
	dice_title = Kit.label("", 13, Kit.MUTED, true)
	dice_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(dice_title)
	tray = FitGrid.new().setup(Vector2(DIE, DIE), 8)
	v.add_child(tray)
	# Soltar um dado encaixado na coluna devolve ele para a mão.
	pc.set_drag_forwarding(Callable(), _can_drop_tray, _drop_tray)
	return pc


func _build_tip() -> void:
	tip = PanelContainer.new()
	var sb := Kit.box(Color(0.06, 0.055, 0.08, 0.97), 12, 12)
	sb.set_border_width_all(1)
	sb.border_color = SpellCard.LINE
	tip.add_theme_stylebox_override("panel", sb)
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip.custom_minimum_size = Vector2(280, 0)
	var v := Kit.vbox(4)
	tip.add_child(v)
	tip_title = Kit.label("", 19, Kit.ACCENT)
	v.add_child(tip_title)
	tip_desc = Kit.label("", 16, Kit.TEXT, true)
	tip_desc.custom_minimum_size = Vector2(256, 0)
	v.add_child(tip_desc)
	tip.visible = false
	fx_layer.add_child(tip)


# ================================================================== Palco
## O palco mostra as magias de quem joga, ou as do inimigo enquanto a foto dele é segurada.
func stage_side() -> String:
	return "enemy" if peeking else active_side


func set_peek(on: bool) -> void:
	peeking = on
	_update_stage()


func _on_enemy_photo_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		set_peek(ev.pressed)


func _set_active(side: String) -> void:
	active_side = side
	_update_stage()


func _update_stage() -> void:
	var s := stage_side()
	# Na ficha (segurando a foto) aparecem todas as magias dele, inclusive as já usadas.
	if peeking:
		for c in enemy_cards:
			c.visible = true
	player_grid.visible = s == "player"
	enemy_grid.visible = s == "enemy"
	if s == "player":
		stage_title.text = Texts.t("ui.your_spells")
	else:
		stage_title.text = Texts.t("ui.enemy_spells")
		if peeking and active_side == "player":
			stage_title.text += "  ·  " + Texts.t("ui.read_only")
			var last := duel.enemy.last_hand
			if not last.is_empty():
				stage_title.text += "  ·  " + Texts.t("ui.enemy_last") + " " + " ".join(PackedStringArray(last.map(func(x): return str(x))))
	if s != _stage_shown:
		_stage_shown = s
		stage_changed.emit(s)


# ================================================================== Status
## Efeitos ativos de um lado, na ordem dos ícones: [{id, n, name, desc}].
## "st" é um Fighter.status_state() (o atual ou o anotado num evento).
static func statuses(st: Dictionary) -> Array:
	var out := []
	if int(st.block) > 0:
		out.append(_st("block", int(st.block)))
	if int(st.poison) > 0:
		out.append(_st("poison", int(st.poison)))
	if int(st.burn) > 0:
		out.append(_st("burn", int(st.burn)))
	if st.mirror:
		out.append(_st("mirror", 1))
	if st.dodge:
		out.append(_st("dodge", 1))
	if int(st.riposte) > 0:
		out.append(_st("riposte", int(st.riposte)))
	if int(st.immune) > 0:
		out.append(_st("immune", int(st.immune)))
	if int(st.kept) > 0:
		out.append(_st("marked", int(st.kept)))
	if int(st.fury) > 0:
		out.append(_st("fury", int(st.fury)))
	var thirst := int(st.thirst_used)
	if st.archetype == "vampire" and thirst > 0:
		var t := _st("thirst", thirst)
		t.desc += " " + Texts.t("ui.thirst", {"n": thirst, "max": Characters.THIRST_CAP})
		out.append(t)
	var mods := {}
	for m in st.hand_mods:
		mods[str(m)] = int(mods.get(str(m), 0)) + 1
	for m in mods:
		out.append({"id": "mod_" + m, "n": mods[m],
			"name": Texts.t("ui.next_hand", {"mod": Texts.t("ui.mod_" + m)}), "desc": Texts.t("status.hand_mod.1")})
	return out


static func _st(id: String, n: int) -> Dictionary:
	return {"id": id, "n": n, "name": Texts.t("status.%s.0" % id), "desc": Texts.t("status.%s.1" % id)}


func _refresh_status() -> void:
	for f in [duel.player, duel.enemy]:
		var s := Resolver.side(f)
		var lst := statuses(status_view[s])
		if lst == status_shown[s]:
			continue
		status_shown[s] = lst
		var col: FitGrid = status_cols[s]
		if tip.visible and is_instance_valid(tip_icon) and tip_icon.get_parent() == col:
			_hide_tip()
		Kit.clear(col)
		for st in lst:
			var ic := StatusIcon.new().setup(st, STATUS_PX)
			ic.held.connect(_on_status_held)
			col.add_child(ic)


## Ícones de status exibidos de um lado (testes e dicas).
func status_icons(side: String) -> Array:
	return status_cols[side].get_children().filter(func(x): return x is StatusIcon and not x.is_queued_for_deletion())


func _on_status_held(ic: StatusIcon, on: bool) -> void:
	if not on:
		_hide_tip()
		return
	tip_icon = ic
	tip_title.text = ic.title + ("  ·  %d" % ic.count)
	tip_desc.text = ic.desc
	tip.visible = true
	tip.reset_size()
	var r := Rect2(ic.global_position, ic.size * ic.get_global_transform().get_scale())
	var pos := Vector2(r.end.x + 8, r.position.y)
	var vp := get_viewport_rect().size if is_inside_tree() else size
	pos.x = minf(pos.x, vp.x - tip.size.x - 4)
	pos.y = clampf(pos.y, 4, maxf(4, vp.y - tip.size.y - 4))
	tip.position = pos - fx_layer.global_position


func _hide_tip() -> void:
	tip.visible = false
	tip_icon = null


# ================================================================== Estado
func _sync_shown() -> void:
	for f in [duel.player, duel.enemy]:
		shown[Resolver.side(f)] = {"hp": f.hp, "max": f.max_hp, "block": f.block}
		status_view[Resolver.side(f)] = f.status_state()
	_refresh_bars()


func _refresh_bars() -> void:
	_refresh_shown_only()
	hud.text = Texts.t("ui.hud_floor", {"n": run.floor_n, "max": Config.LAST_FLOOR, "t": duel.turn})
	coins_label.text = str(run.coins)
	var e := duel.enemy
	var arch := Texts.master_name(e.master_id) if e.master_id != "" else Texts.t("archetypes." + e.archetype)
	enemy_sub.text = Texts.t("ui.enemy_sub", {"arch": arch, "n": e.bag.size()})
	player_sub.text = Texts.t("ui.bag_line", {"n": duel.player.bag.size(), "d": duel.player.discard.size()})


## Texto corrido dos efeitos (ficha do inimigo).
func _status(f: Fighter) -> String:
	var p := []
	for st in statuses(f.status_state()):
		p.append(st.name if st.id in ["mirror", "dodge", "immune", "marked"] or str(st.id).begins_with("mod_") else "%s %d" % [st.name, st.n])
	return " · ".join(p)


func _start_player_phase() -> void:
	phase = "player"
	for c in cards + enemy_cards:
		c.shown_used = null
	# Save no meio do turno: as mexidas ficam na mão e a escolha se remonta a partir dela.
	choice = TurnChoice.from_hand(duel.player)
	choice.rng = duel.rng
	selected = -1
	busy = false
	banner.text = Texts.t("ui.your_turn")
	hint.text = Texts.t("ui.hint_place")
	catcher.visible = false
	end_btn.disabled = false
	_set_active("player")
	_build_tray()
	_sync_shown()
	_refresh_tray()
	if not summary.is_empty():
		info.text = Texts.t("ui.enemy_summary", {"list": " · ".join(summary)})
		info.add_theme_color_override("font_color", Kit.TEXT)


func _build_tray() -> void:
	var p := duel.player
	var els := []
	var heats := []
	for e in p.hand:
		var d := p.die_of(e)
		els.append(d.element if d else "")
		heats.append(Elements.heat(p, d))
	_fill_tray(p.hand_values(), els, true, heats)


## Coluna de dados com uma mão qualquer (a sua é tocável; a do inimigo, não).
## heats: estado do brilho de cada dado (Elements.heat), opcional.
func _fill_tray(values: Array, elements: Array, interactive: bool, heats: Array = []) -> void:
	Kit.clear(tray)
	tray_views = []
	dice_side = "player" if interactive else "enemy"
	dice_title.text = Texts.t("ui.your_hand") if interactive else Texts.t("ui.enemy_dice")
	for h in values.size():
		var v := Hole.new().set_interactive(interactive).setup(DIE, h)
		v.set_die(int(values[h]), elements[h] if h < elements.size() else "", float(_at(heats, h, 0.0)))
		if interactive:
			v.tapped.connect(_on_die)
			v.set_drag_forwarding(_drag_from.bind(v), _can_drop_tray, _drop_tray)
		tray.add_child(v)
		tray_views.append(v)


## Rolagem 3D por cima do palco: os buracos da coluna ficam vazios enquanto os dados
## rolam e se enchem quando param. ev: o evento "hand" (valores, elementos, faces...).
func _roll_tray(ev: Dictionary) -> void:
	if fast or skip or not is_inside_tree() or stage_panel == null:
		return
	var dice := []
	var vals: Array = ev.get("values", [])
	for k in vals.size():
		dice.append({
			"value": int(vals[k]),
			"element": _at(ev.get("elements", []), k, ""),
			"faces": _at(ev.get("faces", []), k, []),
			"face": int(_at(ev.get("face", []), k, 0)),
			"fixed": bool(_at(ev.get("fixed", []), k, false)),
			"heat": float(_at(ev.get("heat", []), k, 0.0)),
		})
	for v: Hole in tray_views:
		v.has_die = false
		v.queue_redraw()
	# Fotos dos dados para a coluna: tiradas durante a rolagem, prontas quando os dados param.
	for d in dice:
		DieSnapshot.prepare(int(d.value), str(d.element), float(d.heat))
	var r := Rect2(stage_panel.global_position - fx_layer.global_position, stage_panel.size)
	roller = DiceRoll3D.new().setup(r.size)
	roller.position = r.position
	fx_layer.add_child(roller)
	roller.skip_check = func() -> bool: return skip
	await roller.roll(dice)
	var spots := roller.dice_on_screen() if not skip else []
	if not spots.is_empty():
		roller.hide_dice()
	var fade := roller.create_tween()
	fade.tween_property(roller, "modulate:a", 0.0, 0.18)
	fade.tween_callback(roller.queue_free)
	var origin := roller.position
	roller = null
	if spots.is_empty():
		for v: Hole in tray_views:
			v.has_die = true
			v.queue_redraw()
		return
	await _fly_to_tray(spots, origin)


## Cada dado sai de onde parou na mesa e voa até o seu buraco na coluna, com a mesma
## cara (a foto do dado 3D) e girando até ficar reto. spots: DiceRoll3D.dice_on_screen;
## origin: posição da mesa na camada de efeitos.
func _fly_to_tray(spots: Array, origin: Vector2) -> void:
	var last: Tween = null
	for k in tray_views.size():
		var v: Hole = tray_views[k]
		if k >= spots.size() or not is_inside_tree():
			v.has_die = true
			v.queue_redraw()
			continue
		var sp: Dictionary = spots[k]
		var target_px := maxf(24.0, _visual_px(v))
		# Buraco cujo dado tem a mesma aresta que o dado 3D tinha na tela.
		var start_px := float(sp.width) / DieSnapshot.FILL / 0.88
		var g := Hole.new().set_interactive(false).setup(int(target_px))
		g.set_die(v.value, v.element, v.heat)
		g.pivot_offset = g.size / 2.0
		g.scale = Vector2.ONE * (start_px / target_px)
		g.rotation = wrapf(float(sp.angle), -PI, PI) ## Começa girado como estava na mesa.
		g.position = origin + sp.center - g.size / 2.0
		g.floor_hidden = true
		fx_layer.add_child(g)
		var dest := v.global_position + v.size * v.get_global_transform().get_scale() / 2.0 - fx_layer.global_position
		var tw := g.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		var delay := k * 0.04
		tw.tween_property(g, "position", dest - g.size / 2.0, FLY_TO_TRAY).set_delay(delay)
		tw.tween_property(g, "scale", Vector2.ONE, FLY_TO_TRAY).set_delay(delay)
		tw.tween_property(g, "rotation", 0.0, FLY_TO_TRAY).set_delay(delay)
		tw.chain().tween_callback(func() -> void:
			v.has_die = true
			v.queue_redraw()
			g.queue_free())
		last = tw
	if last != null:
		await last.finished


static func _at(a: Array, k: int, def: Variant) -> Variant:
	return a[k] if k < a.size() else def


## Primeira mão da luta: rola em 3D ao abrir a tela (tocar pula).
func _intro_roll() -> void:
	if fast or not is_inside_tree() or phase != "player":
		return
	# Espera o primeiro layout (o palco precisa ter tamanho).
	await get_tree().process_frame
	if fast or not is_inside_tree() or phase != "player":
		return
	phase = "resolve"
	end_btn.disabled = true
	catcher.visible = true
	skip = false
	var ev := Resolver.hand_dice(duel.player)
	ev["values"] = duel.player.hand_values()
	await _roll_tray(ev)
	if not is_inside_tree():
		return
	skip = false
	catcher.visible = false
	end_btn.disabled = false
	phase = "player"


## Tamanho na tela (com a escala do palco ou da coluna).
static func _visual_px(c: Control) -> float:
	return c.size.x * c.get_global_transform().get_scale().x


## Um dado voa de um buraco para outro (camada de efeitos).
func _fly(from: Hole, to: Hole) -> void:
	if fast or skip or not is_inside_tree():
		return
	var fs := _visual_px(from)
	var g := Hole.new().set_interactive(false).setup(int(fs))
	g.set_die(from.value, from.element, from.heat)
	g.position = from.global_position - fx_layer.global_position
	fx_layer.add_child(g)
	from.has_die = false
	from.queue_redraw()
	var sc := _visual_px(to) / maxf(1.0, fs)
	var tw := g.create_tween()
	tw.tween_property(g, "position", to.global_position - fx_layer.global_position, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(g, "scale", Vector2(sc, sc), 0.3)
	await _wait(0.32)
	g.queue_free()


func _item_of(h: int) -> int:
	for k in choice.casts:
		if h in choice.casts[k]:
			return k
	return -1


func _refresh_tray() -> void:
	var p := duel.player
	# Dados devolvidos entram e saem da mão durante a alocação.
	if phase == "player" and p.hand.size() != tray_views.size():
		if selected >= p.hand.size():
			selected = -1
		_build_tray()
	var used := choice.used_dice()
	for v in tray_views:
		var hv: Hole = v
		hv.has_die = not (hv.index in used or hv.index == dragging)
		hv.caption = ""
		if hv.index >= 0 and hv.index < p.hand.size():
			var e: Dictionary = p.hand[hv.index]
			var dd := p.die_of(e)
			# Mexidas mudam o valor na própria mão.
			hv.value = int(e.value)
			hv.element = dd.element if dd else ""
			hv.set_cause(int(e.get("orig", -1)), str(e.get("cause", "")))
			if hv.index in used:
				var it := _item_of(hv.index)
				if it < 0:
					it = int(e.get("spent", -1))
				if it >= 0:
					hv.caption = Texts.spell_name(p.inventory.items[it].id)
			hv.heat = Elements.heat(p, dd, not (hv.index in used))
		hv.raised = hv.index == selected
		hv.queue_redraw()
	var sel := int(p.hand[selected].value) if selected >= 0 else -1
	var sel_top := bool(p.hand[selected].get("top", false)) if selected >= 0 else false
	var sel_die: Die = p.die_of(p.hand[selected]) if selected >= 0 else null
	var sel_plus := int(p.hand[selected].get("plus", 0)) if selected >= 0 else 0
	for c in cards:
		if phase == "player":
			# Magia que já resolveu neste turno (mexida, Imitação, Força) ou sem uso
			# disponível sai do palco (docs/SPEC_v3.1.md §1.9).
			c.visible = not (choice.mods.has(c.item) or choice.spawned.has(c.item) or c.used())
		var vals := choice.values_in(p, c.item)
		var els := []
		var heats := []
		for h in choice.dice_in(c.item):
			var d := p.die_of(p.hand[h])
			els.append(d.element if d else "")
			heats.append(Elements.heat(p, d, false))
		var ins := choice.dice_in(c.item)
		for k in c.holes.size():
			c.holes[k].index = int(ins[k]) if k < ins.size() else -1
		var sel_ok := selected >= 0 and choice.available(p, c.item) and TurnChoice.die_allowed(p, c.item, selected)
		c.refresh(vals, els, sel if (dragging >= 0 or not (selected in used)) else -1, choice.tops_in(p, c.item), sel_top, heats,
			sel_ok, sel_die, sel_plus)
	_refresh_undo()
	if phase != "player":
		return
	# Magia de vários dados pela metade: o botão fica apagado (tocar explica).
	end_btn.modulate.a = 1.0 if choice.incomplete_items(p).is_empty() else 0.5
	if selected >= 0:
		info.text = Texts.t("ui.die_selected", {"v": sel})
		var se: Dictionary = p.hand[selected]
		var cause := str(se.get("cause", ""))
		if cause != "":
			# Dado mexido: a causa e a conta.
			info.text += "  ·  " + Texts.t("ui.cause_line", {"name": cause_name(cause), "from": int(se.get("orig", sel)), "to": sel})
			var mi := int(se.get("mod", -1))
			if mi >= 0 and choice.mods.has(mi) and bool(choice.mods[mi].random):
				info.text += "  ·  " + Texts.t("ui.mod_final", {"name": Texts.spell_name(p.inventory.items[mi].id)})
		var sd := p.die_of(p.hand[selected])
		if sd and sd.element != "":
			# Tocar no dado explica o elemento.
			info.text += "  ·  %s: %s" % [Texts.element_name(sd.element), Texts.element_desc(sd.element)]
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
## O toque que encerra um arrasto não conta como toque.
func _just_dragged() -> bool:
	return dragging >= 0 or Engine.get_process_frames() - _drag_end_frame <= 1


## Cartão do jogador: recebe dados arrastados; tocar num buraco com dado o solta.
func _wire_card(c: SpellCard) -> void:
	c.set_drag_forwarding(Callable(), _can_drop_card.bind(c.item), _drop_card.bind(c.item))
	for k in c.holes.size():
		var h: Hole = c.holes[k]
		h.set_interactive(true)
		h.tapped.connect(_on_card_hole.bind(c.item))
		h.set_drag_forwarding(_drag_from.bind(h), _can_drop_card.bind(c.item), _drop_card_slot.bind(c.item, k))


## Começa a arrastar o dado do buraco (da mão ou de uma magia).
func _drag_from(_at: Vector2, hole: Hole) -> Variant:
	var p := duel.player
	if phase != "player" or busy or not hole.has_die or hole.index < 0 or hole.index >= p.hand.size():
		return null
	var h := hole.index
	var px := int(maxf(24.0, _visual_px(hole)))
	var g := Hole.new().set_interactive(false).setup(px)
	g.set_die(hole.value, hole.element, hole.heat)
	g.position = -g.size / 2.0
	var prev := Control.new()
	prev.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prev.add_child(g)
	hole.set_drag_preview(prev)
	summary = []
	dragging = h
	selected = h
	_refresh_tray()
	return {"die": h}


func _drag_die(data: Variant) -> int:
	if phase != "player" or not (data is Dictionary) or not data.has("die"):
		return -1
	var h := int(data.die)
	return h if h >= 0 and h < duel.player.hand.size() else -1


func _can_drop_card(_at: Vector2, data: Variant, item: int) -> bool:
	return _drag_die(data) >= 0 and item >= 0


func _drop_card(_at: Vector2, data: Variant, item: int) -> void:
	move_die(_drag_die(data), item)


## Solto num buraco: o buraco escolhe o lado do Ajuste Fino (0 = +1, 1 = −1).
func _drop_card_slot(_at: Vector2, data: Variant, item: int, slot: int) -> void:
	move_die(_drag_die(data), item, _slot_for(item, slot))


## Buraco k do cartão como "slot" do motor (só o Ajuste Fino usa).
func _slot_for(item: int, k: int) -> int:
	var id: String = duel.player.inventory.items[item].id
	return k if SpellCard.hole_count(id) != Spells.dice_needed(id) else 0


func _can_drop_tray(_at: Vector2, data: Variant) -> bool:
	return _drag_die(data) >= 0


func _drop_tray(_at: Vector2, data: Variant) -> void:
	var h := _drag_die(data)
	if h >= 0 and _item_of(h) >= 0:
		choice.remove_die(h, duel.player)
	selected = -1
	_refresh_tray()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and dragging >= 0:
		dragging = -1
		selected = -1
		_drag_end_frame = Engine.get_process_frames()
		if phase == "player":
			_refresh_tray()


## Põe o dado h na magia item, tirando-o antes da magia onde estava (se a nova não
## aceitar, ele fica onde estava). Retorna false se não aceitar.
func move_die(h: int, item: int, slot := 0) -> bool:
	var p := duel.player
	if phase != "player" or busy or h < 0 or h >= p.hand.size() or item < 0:
		return false
	if h in choice.dice_in(item):
		return true
	if _item_of(h) >= 0:
		var e: Dictionary = p.hand[h]
		if not choice.available(p, item) or not TurnChoice.die_allowed(p, item, h, slot) \
				or not Spells.accepts_partial(p.inventory.items[item].id, choice.values_in(p, item), int(e.value), bool(e.get("top", false))):
			# Mostra o motivo sem tirar o dado de onde está.
			var ok := place(h, item, slot)
			selected = -1
			_refresh_tray()
			return ok
		choice.remove_die(h, p)
	return place(h, item, slot)


## Tocar num buraco de magia: com dado, solta só ele; vazio, vale como tocar na magia.
func _on_card_hole(hole: Hole, item: int) -> void:
	if phase != "player" or busy or _just_dragged():
		return
	if hole.has_die and hole.index >= 0 and hole.index in choice.dice_in(item):
		summary = []
		choice.remove_die(hole.index, duel.player)
		selected = -1
		_refresh_tray()
		return
	var c := _card_of(cards, item)
	_on_card(item, _slot_for(item, c.holes.find(hole) if c else 0))


func _on_die(v: Hole) -> void:
	if phase != "player" or busy or _just_dragged():
		return
	summary = []
	var p := duel.player
	var sp := int(p.hand[v.index].get("spent", -1)) if v.index >= 0 and v.index < p.hand.size() else -1
	if sp >= 0:
		# Dado gasto por uma mexida (Sangria, Juntar Cacos): tocar desfaz a mexida.
		choice.undo_mod(p, sp)
		selected = -1
		_refresh_tray()
		return
	if v.index in choice.used_dice():
		choice.remove_die(v.index, duel.player)
		selected = -1
	else:
		selected = -1 if selected == v.index else v.index
	_refresh_tray()


func _on_card(item: int, slot := 0) -> void:
	if phase != "player" or busy or item < 0 or _just_dragged():
		return
	summary = []
	if selected >= 0:
		place(selected, item, slot)
		return
	for h in choice.dice_in(item).duplicate():
		choice.remove_die(h, duel.player)
	_refresh_tray()


## Põe o dado h na magia item. Retorna false se não aceitar.
func place(h: int, item: int, slot := 0) -> bool:
	var p := duel.player
	if busy:
		return false
	var id: String = p.inventory.items[item].id
	if not choice.available(p, item):
		info.text = Texts.t("ui.spell_used")
		return false
	var before := []
	for x in choice.dice_in(item):
		before.append(x)
	before.append(h)
	var prev := []
	for x in before:
		prev.append(int(p.hand[x].value))
	if not choice.place(p, item, h, slot):
		info.text = Texts.t("ui.not_accepted", {"name": Texts.spell_name(id), "req": GrimoireView.req_label(id)})
		info.add_theme_color_override("font_color", Kit.DANGER.lightened(0.2))
		return false
	selected = -1
	if choice.mods.has(item) or choice.spawned.has(item):
		_resolve_anim(item, before, prev, slot)
		return true
	_refresh_tray()
	return true


## Nome da causa de um dado mexido: magia, elemento, mexida do inimigo ou Mestre.
static func cause_name(cause: String) -> String:
	if Spells.DATA.has(cause):
		return Texts.spell_name(cause)
	if cause in Elements.ALL:
		return Texts.element_name(cause)
	return Texts.t("ui.cause_" + cause)


## Mexida (ou Imitação, Força) que acabou de resolver na alocação: o dado voa até o
## cartão, muda (as aleatórias giram os números), volta para a mão e o cartão sai do
## palco; os outros se reorganizam (docs/SPEC_v3.1.md §1.9).
func _resolve_anim(item: int, dice: Array, prev: Array, slot: int) -> void:
	var p := duel.player
	var c := _card_of(cards, item)
	var targets := []
	var random := false
	if choice.mods.has(item):
		var m: Dictionary = choice.mods[item]
		random = bool(m.random)
		for q in m.prev:
			if not bool(q.spent):
				targets.append(int(q.h))
		targets.append_array(m.spawn)
	else:
		targets = choice.spawned.get(item, []).duplicate()
	if fast or not is_inside_tree() or c == null:
		_refresh_tray()
		return
	busy = true
	var two := SpellCard.hole_count(c.id) != Spells.dice_needed(c.id)
	for k in dice.size():
		var hk := slot if two else mini(k, c.holes.size() - 1)
		var tv := _tray_view(int(dice[k]))
		var el := ""
		var dd := p.die_of(p.hand[int(dice[k])]) if int(dice[k]) < p.hand.size() else null
		if dd:
			el = dd.element
		if tv:
			tv.value = int(prev[k])
			tv.set_cause(-1, "")
			await _fly(tv, c.holes[hk])
		c.holes[hk].set_die(int(prev[k]), el)
	if random:
		var hk2 := slot if two else 0
		for _t in 8:
			c.holes[hk2].set_die(randi_range(1, 6), c.holes[hk2].element)
			await _wait(0.055)
	for k in dice.size():
		var hk := slot if two else mini(k, c.holes.size() - 1)
		var h := int(dice[k])
		if h in targets and h < p.hand.size():
			c.holes[hk].set_die(int(p.hand[h].value), c.holes[hk].element)
	c.flash()
	await _wait(0.22)
	if not is_inside_tree():
		busy = false
		return
	# Volta para a mão (a coluna se refaz com os dados novos).
	_build_tray()
	for t in targets:
		var tv := _tray_view(int(t))
		if tv:
			tv.has_die = false
			tv.queue_redraw()
	for i in targets.size():
		var tv := _tray_view(int(targets[i]))
		var from: Hole = c.holes[mini(i, c.holes.size() - 1)]
		if two:
			from = c.holes[slot]
		if tv == null:
			continue
		from.set_die(int(p.hand[int(targets[i])].value), from.element)
		_fly(from, tv) ## Em paralelo.
	await _wait(0.34)
	for c2 in c.holes:
		c2.clear_die()
	await _leave_card(c, cards)
	busy = false
	_refresh_tray()


func _tray_view(h: int) -> Hole:
	for v in tray_views:
		if v.index == h:
			return v
	return null


## O cartão some (esmaece) e os outros deslizam para o lugar novo na grade.
func _leave_card(c: SpellCard, list: Array) -> void:
	if fast or skip or not is_inside_tree():
		c.visible = false
		return
	var tw := c.create_tween()
	tw.tween_property(c, "modulate:a", 0.0, 0.25)
	await tw.finished
	if not is_inside_tree():
		return
	var olds := {}
	for x in list:
		if x.visible and x != c:
			olds[x] = x.position
	c.visible = false
	c.modulate.a = 1.0
	await get_tree().process_frame
	for x: Control in olds:
		var np: Vector2 = x.position
		x.position = olds[x]
		var t2: Tween = x.create_tween()
		t2.tween_property(x, "position", np, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await _wait(0.25)


## Dado mexido selecionado: "Desfazer [mexida]" (só as determinísticas).
func _refresh_undo() -> void:
	if undo_btn == null:
		return
	var it := _undo_item()
	undo_btn.visible = phase == "player" and it >= 0
	if it >= 0:
		undo_btn.text = Texts.t("ui.undo_mod", {"name": Texts.spell_name(duel.player.inventory.items[it].id)})


func _undo_item() -> int:
	var p := duel.player
	if selected < 0 or selected >= p.hand.size():
		return -1
	var it := int(p.hand[selected].get("mod", -1))
	if it < 0 or not choice.mods.has(it) or bool(choice.mods[it].random):
		return -1
	return it


func _on_undo() -> void:
	if phase != "player" or busy:
		return
	var it := _undo_item()
	if it >= 0:
		choice.undo_mod(duel.player, it)
	selected = -1
	_refresh_tray()


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
		o.body.add_child(ElementInfo.rich(Texts.master_name(e.master_id) + ": " + Texts.master_desc(e.master_id), 20, Kit.ACCENT))
	else:
		o.add_text(Texts.t("archetypes." + e.archetype), 20, Kit.ACCENT)
	if e.variant != "":
		o.body.add_child(ElementInfo.rich(Texts.t("variants." + e.variant), 18, Kit.ACCENT))
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
		o.body.add_child(ElementInfo.rich(t + ": " + Texts.spell_desc(it.id), 18, Color(0.85, 0.83, 0.89)))
	return o


# ================================================================== Turno
func _on_end_turn() -> void:
	_submit()


## Bloqueia o fim do turno com magia de vários dados pela metade (vazia pode).
func can_end_turn() -> bool:
	var bad := choice.incomplete_items(duel.player)
	if bad.is_empty():
		return true
	var item: int = bad[0]
	info.text = Texts.t("ui.incomplete_block", {"name": Texts.spell_name(duel.player.inventory.items[item].id)})
	info.add_theme_color_override("font_color", Kit.DANGER.lightened(0.2))
	var c := _card_of(cards, item)
	if c:
		c.flash()
	return false


func _submit() -> void:
	if phase != "player" or busy or not can_end_turn():
		return
	end_btn.modulate.a = 1.0
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
	# Entre o turno do inimigo e o começo do seu, a tela não pula para o estado final:
	# vida e status seguem os eventos até o fim.
	await _animate(rep.events, duel.state != "choosing")
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


func _animate(events: Array, sync := true) -> void:
	for i in events.size():
		var ev: Dictionary = events[i]
		chained = i > 0 and _same_item(events[i - 1], ev)
		await _apply_event(ev)
		_feed_events([ev])
		var next_chained := i + 1 < events.size() and _same_item(ev, events[i + 1])
		await _wait(CHAIN_DELAY if next_chained else _delay(ev))
	chained = false
	if sync:
		_sync_shown()


## "b" é mais uma ação da mesma magia que "a". Só os efeitos levam "of_item" (o
## "cast" não): a pausa entre o cartão piscar e o primeiro efeito continua normal.
static func _same_item(a: Dictionary, b: Dictionary) -> bool:
	return a.has("of_item") and b.has("of_item") and int(a.of_item) == int(b.of_item)


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
	if ev.has("st"):
		for k in ev.st:
			status_view[k] = ev.st[k].duplicate()
	match str(ev.t):
		"turn":
			# Começo do turno: as proteções de quem joga somem (Resolver.start_turn).
			if status_view.has(s):
				var sv: Dictionary = status_view[s]
				sv.block = 0
				sv.mirror = false
				sv.dodge = false
				sv.riposte = 0
			fx_src = null
			fx_bounce = null
			banner.text = Texts.t("ui.your_turn") if s == "player" else Texts.t("ui.enemy_turn")
			# O palco e a coluna de dados passam para quem joga agora.
			_set_active(s)
			if s == "enemy":
				shown.enemy.block = 0
				summary = []
				info.text = ""
				hint.text = Texts.t("ui.tap_to_skip")
				for c in enemy_cards:
					c.refresh([], [], -1)
					c.visible = not c.used() ## As já gastas não aparecem no palco.
				for c in cards:
					c.refresh([], [], -1)
			else:
				shown.player.block = 0
		"hand":
			# Os dois lados rolam a mão na coluna de dados.
			fx_src = null
			if s == "enemy":
				hint.text = Texts.t("ui.enemy_rolling")
			_fill_tray(ev["values"], ev.get("elements", []), s == "player", ev.get("heat", []))
			var origs: Array = ev.get("orig", [])
			var causes: Array = ev.get("cause", [])
			for k in mini(tray_views.size(), causes.size()):
				tray_views[k].set_cause(int(origs[k]) if k < origs.size() else -1, str(causes[k]))
			await _roll_tray(ev)
		"mod":
			# As suas já foram animadas na alocação; as do inimigo acontecem agora.
			if s == "enemy":
				await _enemy_mod(ev)
		"cast":
			var cc := _card_of(cards if s == "player" else enemy_cards, int(ev.item))
			if cc and cc.shown_used != null:
				cc.shown_used.append(int(ev.item))
			fx_src = _center(cc) if cc else null
			fx_bounce = null
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
			var from = fx_bounce if ev.get("reflected", false) and fx_bounce != null else fx_src
			fx_bounce = null
			await _effect(s, hit_txt, "dmg" if int(ev.dmg) > 0 else "fx", from, ScreenShake.tier(int(ev.dmg), int(v.max)))
			_note(s, hit_txt)
		"asbestos":
			_burst(fx_src, Elements.look("Am").body, false)
			v.hp -= int(ev.n)
			await _effect(s, Texts.t("ui.fx_asbestos", {"n": ev.n}), "dmg", "src", ScreenShake.tier(int(ev.n), int(v.max)))
			_note(s, Texts.t("ui.fx_asbestos", {"n": ev.n}))
		"element":
			_float(s, Texts.t("ui.fx_el_" + str(ev.el), {"v": ev.v}), Elements.COLORS.get(str(ev.el), Kit.TEXT))
		"burn_up":
			if str(ev.get("src", "")) == "Na":
				_burst(fx_src, Elements.look("Na").emission, true)
				await _effect(s, Texts.t("ui.fx_el_Na", {"n": ev.n}), "fx")
			else:
				await _effect(s, Texts.t("ui.fx_burn_up", {"n": ev.n}), "fx")
		"poison_up":
			# Urânio (ou dado parado, com o Reator) no fim do turno: sem magia de origem.
			var pk := "ui.fx_reactor" if str(ev.get("src", "")) == "reactor" else "ui.fx_el_U"
			await _effect(s, Texts.t(pk, {"n": ev.n}), "fx", null)
		"alchemy":
			_float(s, Texts.t("ui.fx_alchemy", {"from": ev["from"], "to": ev.to}), Kit.ACCENT)
		"dead_weight":
			_float(s, Texts.t("ui.fx_dead_weight", {"n": ev.n}), Elements.COLORS.Pb)
		"copy":
			if str(ev.spell) != "":
				_float(s, Texts.t("ui.fx_copy", {"name": Texts.spell_name(ev.spell)}), Kit.ACCENT)
		"lead_convert":
			_float(s, Texts.t("ui.fx_lead"), Elements.COLORS.Pb)
		"poison", "burn", "idle_dmg":
			# Começo ou fim do turno: o dano acontece no próprio alvo, sem viagem.
			v.hp -= int(ev.n)
			await _effect(s, "−%d" % int(ev.n), "dmg", null, ScreenShake.tier(int(ev.n), int(v.max)))
			_note(s, Texts.t("ui.fx_" + str(ev.t), {"n": ev.n}))
		"riposte":
			await _effect(s, Texts.t("ui.fx_riposte"), "fx", null)
			fx_bounce = _portrait_point(s)
			_note(s, Texts.t("ui.fx_riposte"))
		"immune_block":
			await _effect(s, Texts.t("ui.fx_immune"), "fx")
			_note(s, Texts.t("ui.fx_immune"))
		"encore":
			_float(s, "+%d" % int(ev.v), Kit.ACCENT)
		"block":
			# Bloqueio reciclado (dados parados no fim do turno) não vem de uma magia.
			await _effect(s, Texts.t("ui.fx_block", {"n": ev.n}), "fx", null if ev.get("recycled", false) else fx_src)
			v.block = int(ev.total)
		"heal":
			await _effect(s, Texts.t("ui.fx_heal", {"n": ev.n}), "heal")
			v.hp += int(ev.n)
		"maxhp":
			await _effect(s, Texts.t("ui.fx_thirst" if ev.get("thirst", false) else "ui.fx_maxhp", {"n": ev.n}), "heal")
			v.max += int(ev.n)
			v.hp += int(ev.n)
		"dodged":
			await _effect(s, Texts.t("ui.fx_dodged"), "fx")
			_note(s, Texts.t("ui.fx_dodged"))
		"mirrored":
			await _effect(s, Texts.t("ui.fx_mirror"), "fx")
			fx_bounce = _portrait_point(s)
			_note(s, Texts.t("ui.fx_mirror"))
		"dodge_up":
			await _effect(s, Texts.t("status.dodge.0"), "fx")
		"mirror_up":
			await _effect(s, Texts.t("status.mirror.0"), "fx")
		"riposte_up":
			await _effect(s, "%s %d" % [Texts.t("status.riposte.0"), int(ev.n)], "fx")
		"immune_up":
			await _effect(s, Texts.t("status.immune.0"), "fx")
		"cleanse":
			await _effect(s, Texts.t("ui.fx_cleanse"), "fx")
		"recycle_up":
			await _effect(s, Texts.t("ui.fx_recycle"), "fx")
		"hand_mod_up":
			await _effect(s, Texts.t("ui.mod_" + str(ev.mod)), "fx")
		"mark":
			await _effect(s, Texts.t("status.marked.0"), "fx")
		"bench":
			await _effect(s, Texts.t("ui.fx_bench"), "fx")
		"steal_sticker":
			await _effect(s, Texts.t("ui.fx_steal"), "fx")
		"sacrifice":
			await _effect(s, Texts.t("ui.fx_sacrifice", {"n": ev.bonus}), "fx")
	_refresh_shown_only()


## Mexida do inimigo: os dados voam até o cartão, mudam e voltam; o cartão sai do palco.
func _enemy_mod(ev: Dictionary) -> void:
	var ec := _card_of(enemy_cards, int(ev.item))
	var dice: Array = ev.dice
	var from: Array = ev["from"]
	var to: Array = ev.to
	summary.append(Texts.spell_name(ev.spell) + " " + " ".join(PackedStringArray(from.map(func(x): return str(x)))) + " → " \
		+ " ".join(PackedStringArray(to.filter(func(x): return int(x) > 0).map(func(x): return str(x)))))
	if ec == null:
		return
	var two := SpellCard.hole_count(ec.id) != Spells.dice_needed(ec.id)
	var slot := 1 if two and not to.is_empty() and int(to[0]) < int(from[0]) else 0
	for k in dice.size():
		var h := int(dice[k])
		var hk := slot if two else mini(k, ec.holes.size() - 1)
		var el := ""
		if h < tray_views.size():
			el = tray_views[h].element
			tray_views[h].value = int(from[k])
			await _fly(tray_views[h], ec.holes[hk])
		ec.holes[hk].set_die(int(from[k]), el)
	if bool(ev.get("random", false)):
		for _t in 8:
			ec.holes[slot if two else 0].set_die(randi_range(1, 6), ec.holes[0].element)
			await _wait(0.055)
	for k in dice.size():
		var hk := slot if two else mini(k, ec.holes.size() - 1)
		if k < to.size() and int(to[k]) > 0:
			ec.holes[hk].set_die(int(to[k]), ec.holes[hk].element)
	if not fast:
		ec.flash()
	await _wait(0.22)
	for k in dice.size():
		var h := int(dice[k])
		if h >= tray_views.size():
			continue
		var tv: Hole = tray_views[h]
		if k < to.size() and int(to[k]) > 0:
			tv.set_die(int(to[k]), tv.element)
			tv.set_cause(int(from[k]), str(ev.spell))
		else:
			tv.has_die = false
			tv.caption = Texts.spell_name(ev.spell)
			tv.queue_redraw()
	for j in range(dice.size(), to.size()):
		var v := Hole.new().set_interactive(false).setup(DIE, tray_views.size())
		v.set_die(int(to[j]), "")
		v.set_cause(int(from[0]) if not from.is_empty() else -1, str(ev.spell))
		tray.add_child(v)
		tray_views.append(v)
	for hc in ec.holes:
		hc.clear_die()
	await _leave_card(ec, enemy_cards)


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
		bars[s].set_values(v.max, v.hp, 0, 0) ## O bloqueio é um ícone de status.
	_refresh_status()


## Texto que sobe e some sobre a foto de "s" (+X verde, −X vermelho, efeitos em azul).
## Textos seguidos no mesmo lado empilham para não se cobrirem.
## Explosão de partículas no ponto at (camada de efeitos): faíscas do Sódio (sparks)
## ou poeira do Amianto. Some sozinha.
## "speed" acelera as partículas (velocidade e gravidade, mesma trajetória em menos tempo).
func _burst(at: Variant, col: Color, sparks: bool, speed := 1.0) -> void:
	if fast or skip or at == null or not is_inside_tree():
		return
	var pt := CPUParticles2D.new()
	pt.position = at
	pt.one_shot = true
	pt.explosiveness = 0.9
	pt.amount = 28 if sparks else 40
	pt.lifetime = 0.6 if sparks else 1.1
	pt.spread = 180.0
	pt.gravity = (Vector2(0, 260) if sparks else Vector2(0, -25)) * speed * speed
	pt.initial_velocity_min = (180.0 if sparks else 30.0) * speed
	pt.initial_velocity_max = (340.0 if sparks else 90.0) * speed
	pt.scale_amount_min = 2.0 if sparks else 3.0
	pt.scale_amount_max = 4.0 if sparks else 7.0
	var ramp := Gradient.new()
	ramp.set_color(0, Color(col.lightened(0.4), 1.0) if sparks else Color(col, 0.7))
	ramp.set_color(1, Color(col, 0.0))
	pt.color_ramp = ramp
	fx_layer.add_child(pt)
	pt.emitting = true
	pt.finished.connect(pt.queue_free)


func _float(s: String, text: String, col: Color) -> void:
	if fast:
		return
	var at := _portrait_point(s)
	var stack := 0
	for c in fx_layer.get_children():
		if c is Label and c.get_meta("fx_side", "") == s and not c.is_queued_for_deletion():
			stack += 1
	# O texto pode passar da foto, mas nunca da tela: textos longos diminuem até caber
	# e a caixa é empurrada para dentro da borda.
	# O "pulo" de entrada passa um pouco do tamanho final (TRANS_BACK): reserva 10%.
	var room := (fx_layer.size.x - FX_EDGE * 2.0) / 1.1
	var fs := FX_SIZE
	var font: Font = fx_font if fx_font else get_theme_default_font()
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + FX_OUTLINE
	if w > room and room > 0.0:
		fs = maxi(12, int(fs * room / w))
		w = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + FX_OUTLINE
	var l := Kit.label(text, fs, col)
	l.set_meta("fx_side", s)
	if fx_font:
		l.add_theme_font_override("font", fx_font)
	l.add_theme_constant_override("outline_size", FX_OUTLINE)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.size = Vector2(maxf(260.0, w + 8.0), 44)
	var x := at.x - l.size.x * 0.5
	if room > 0.0:
		var pad := FX_EDGE + l.size.x * 0.05
		x = clampf(x, pad, maxf(pad, fx_layer.size.x - pad - l.size.x))
	l.position = Vector2(x, at.y - 22 + 34 * (stack % 3))
	l.pivot_offset = l.size / 2.0
	l.scale = Vector2(0.5, 0.5)
	fx_layer.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "position:y", l.position.y - 46, 1.1)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.6).set_delay(0.5)
	tw.tween_callback(l.queue_free)


## Um efeito chega em "s": voa de "from" (por padrão, o cartão da última magia) até a
## foto do alvo na cor do tipo ("heal", "dmg", "fx") e então mostra o texto e a reação.
## Sem origem (veneno, queima, fim do turno) ou acelerando, só o texto e a reação.
## "shake" é a faixa da tremida da tela no impacto (ScreenShake.tier; 0 = nenhuma).
func _effect(s: String, text: String, kind: String, from: Variant = "src", shake := 0) -> void:
	if from is String:
		from = fx_src
	var col: Color = FX_COLORS[kind]
	if from != null and not fast and not skip and is_inside_tree():
		bolts += 1
		var b := SpellBolt.new().setup(from, _portrait_point(s), col, CHAIN_BOLT_TIME if chained else BOLT_TIME)
		fx_layer.add_child(b)
		await b.arrived
	if fast:
		return
	_float(s, text, col)
	var ph: Portrait = player_photo if s == "player" else enemy_photo
	ph.react(col, kind == "dmg")
	_impact(s, shake)


## Impacto de um golpe: a tela treme conforme a faixa; nas duas maiores, um clarão
## vermelho e, a partir de 100% da vida, quase uma explosão (clarão branco e estilhaços).
func _impact(s: String, t: int) -> void:
	if t <= 0 or fast or not is_inside_tree():
		return
	last_shake = t
	shaker.start(t)
	if t < 4:
		return
	var big := t >= 5
	flash.color = Color(1.0, 0.95, 0.85, 0.55) if big else Color(1.0, 0.2, 0.15, 0.28)
	var tw := flash.create_tween()
	tw.tween_property(flash, "color:a", 0.0, 0.45 if big else 0.3).set_ease(Tween.EASE_OUT)
	if big:
		var at := _portrait_point(s)
		_burst(at, Color(1.0, 0.55, 0.2), true, ScreenShake.STRENGTH)
		_burst(at, Color(0.55, 0.12, 0.1), false, ScreenShake.STRENGTH)


## Centro de um controle na camada de efeitos.
func _center(c: Control) -> Vector2:
	return c.get_global_transform() * (c.size * 0.5) - fx_layer.global_position


func _portrait_point(s: String) -> Vector2:
	var ph: Portrait = player_photo if s == "player" else enemy_photo
	return ph.target_point() - fx_layer.global_position


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
			if ev.get("pierce", false):
				t += " " + Texts.t("ev.pierce")
			return t
		"block":
			if ev.get("recycled", false):
				return Texts.t("ev.recycled", {"who": w, "n": ev.n})
			return Texts.t("ev.block", {"who": w, "n": ev.n})
		"heal":
			return Texts.t("ev.heal", {"who": w, "n": ev.n})
		"maxhp":
			return Texts.t("ev.thirst" if ev.get("thirst", false) else "ev.maxhp", {"who": w, "n": ev.n})
		"poison":
			return Texts.t("ev.poison", {"who": w, "n": ev.n})
		"burn":
			return Texts.t("ev.burn", {"who": w, "n": ev.n})
		"poison_up":
			if str(ev.get("src", "")) == "reactor":
				return Texts.t("ev.poison_reactor", {"who": w, "n": ev.n})
			return Texts.t("ev.poison_up", {"who": w, "n": ev.n})
		"alchemy":
			return Texts.t("ev.alchemy", {"from": ev["from"], "to": ev.to})
		"burn_up":
			if str(ev.get("src", "")) == "Na":
				return Texts.t("ev.burn_up_na", {"who": w, "n": ev.n})
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
		"idle_dmg":
			return Texts.t("ev.idle_dmg", {"who": w, "n": ev.n})
		"riposte":
			return Texts.t("ev.riposte", {"who": w, "n": ev.n})
		"riposte_up":
			return Texts.t("ev.riposte_up", {"who": w, "n": ev.n})
		"immune_up":
			return Texts.t("ev.immune_up", {"who": w})
		"immune_block":
			return Texts.t("ev.immune_block", {"who": w})
		"cleanse":
			return Texts.t("ev.cleanse", {"who": w})
		"recycle_up":
			return Texts.t("ev.recycle_up", {"who": w})
		"encore":
			return Texts.t("ev.encore", {"who": w, "v": ev.v})
		"steal_sticker":
			return Texts.t("ev.steal_sticker", {"who": w, "v": ev.v})
		"bench":
			return Texts.t("ev.bench", {"who": w})
		"mark":
			return Texts.t("ev.mark", {"who": w})
		"stolen":
			return Texts.t("ev.stolen", {"who": w, "v": ev.v})
		"hand_mod_up":
			return Texts.t("ev.hand_mod_up", {"who": w, "mod": Texts.t("ui.mod_" + str(ev.mod))})
		"hand_mod":
			return Texts.t("ev.hand_mod", {"who": w, "mod": Texts.t("ui.mod_" + str(ev.mod))})
		"lead_hand":
			return Texts.t("ev.lead_hand")
		"lead_bag":
			return Texts.t("ev.lead_bag")
		"lead_convert":
			return Texts.t("ev.lead_convert")
		"asbestos":
			return Texts.t("ev.asbestos", {"who": w, "n": ev.n})
		"element":
			return Texts.t("ev.el_" + str(ev.el), {"who": w, "v": ev.v})
		"dead_weight":
			return Texts.t("ev.dead_weight", {"who": w, "n": ev.n})
		"copy":
			if str(ev.spell) == "":
				return Texts.t("ev.copy_none", {"who": w})
			return Texts.t("ev.copy", {"who": w, "name": Texts.spell_name(ev.spell)})
		"keep":
			return Texts.t("ev.keep", {"who": w, "n": ev.n})
		"turn_limit":
			return Texts.t("ui.fx_turn_limit")
		"mod":
			return Texts.t("ev.mod", {"who": w, "spell": Texts.spell_name(ev.spell),
				"from": " ".join(PackedStringArray(ev["from"].map(func(x): return str(x)))),
				"to": " ".join(PackedStringArray(ev.to.filter(func(x): return int(x) > 0).map(func(x): return str(x))))})
	return ""


# ================================================================== Fim
func _show_over() -> void:
	phase = "over"
	catcher.visible = false
	end_btn.disabled = true
	var won := duel.state == "won"
	var coins := RunState.door_coins(run.door) if not run.is_master_floor() else Config.MASTER_COINS
	var msg := Texts.t("ui.won_duel", {"coins": coins}) if won else Texts.t("ui.lost_duel")
	var heal := mini(duel.player.max_hp - maxi(0, duel.player.hp), int(ceil(duel.player.max_hp * Config.MASTER_HEAL_FRACTION)))
	if won and run.is_master_floor() and run.floor_n < Config.LAST_FLOOR and heal > 0:
		msg += "\n" + Texts.t("ui.master_heal", {"n": heal})
	elif won and not run.is_master_floor() and run.floor_n < Config.LAST_FLOOR:
		var wh := mini(duel.player.max_hp - maxi(0, duel.player.hp), int(ceil(duel.player.max_hp * Config.WIN_HEAL_FRACTION)))
		if wh > 0:
			msg += "\n" + Texts.t("ui.win_heal", {"n": wh})
	var o := Overlay.open(self, msg, Texts.t("ui.continue_btn"), 520)
	o.closed.connect(_finish)


func _finish() -> void:
	run.finish_duel()
	SaveGame.save(run)
	finished.emit()
