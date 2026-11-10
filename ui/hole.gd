class_name Hole
extends Control
## Buraco onde um dado encaixa: fundo escuro e afundado, com a exigência escrita
## no fundo quando vazio. Usado na bandeja da mão e nos cartões de magia.

signal tapped(hole: Hole)

const FLOOR := Color(0.043, 0.039, 0.055)
const FLOOR_LO := Color(0.075, 0.067, 0.09)
const REQ_COLOR := Color(0.6, 0.57, 0.66)

var index: int = -1 ## Na bandeja: índice do dado na mão.
var req: String = "" ## Texto no fundo do buraco vazio ("≤ 3", "1").
var caption: String = "" ## Texto pequeno no buraco vazio (ex.: magia onde o dado foi).
var has_die := false
var value := 0
var element := ""
var lit := false ## Aceita o dado selecionado.
var raised := false ## Dado selecionado: levantado.
var faded := false ## Dado já lançado neste turno.
var _glows := false ## O dado encaixado brilha (pulsa: redesenha a cada quadro).
var heat := 0.0 ## Estado do brilho do dado (Elements.heat): 0 repouso, 1 ativo.
var stickers := 0 ## Adesivos +2 na face que saiu (selo vermelho).
var gold := 0 ## Adesivos de ouro na face que saiu (selo dourado).
var interactive := true
var floor_hidden := false ## Só o dado, sem o buraco (dado voando).
## Dado mexido (docs/SPEC_v3.1.md §8): valor de antes, riscado no alto, e a causa num selo.
var orig := -1
var badge := ""
var badge_color := Color(0.76, 0.65, 1.0)

## Selo curto de cada causa: mexidas do inimigo, Alquimista, elementos e as suas mexidas.
const BADGES := {
	"halve": "½", "even_to_one": "1", "top_to_one": "1", "alquimista": "⇄", "porteiro": "Pb",
	"H": "H", "C": "C", "Hg": "Hg", "Li": "Li", "Sr": "Sr",
}


## Mostra o valor original e a causa (cause: id de magia, mexida do inimigo ou elemento).
func set_cause(o: int, cause: String) -> void:
	orig = o if cause != "" and o != value else -1
	badge = ""
	if cause == "":
		queue_redraw()
		return
	if BADGES.has(cause):
		badge = BADGES[cause]
		badge_color = Elements.COLORS.get(cause, Color(1.0, 0.55, 0.5)) if cause in ["H", "C", "Hg", "Li", "Sr", "porteiro"] else Color(1.0, 0.55, 0.5)
		if cause == "porteiro":
			badge_color = Elements.COLORS.Pb
	else:
		badge = "✦" ## Uma mexida sua.
		badge_color = Kit.ACCENT
	queue_redraw()


func setup(px: int, i := -1) -> Hole:
	index = i
	custom_minimum_size = Vector2(px, px)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	return self


func set_interactive(on: bool) -> Hole:
	interactive = on
	mouse_filter = Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE
	return self


func set_die(v: int, el := "", h := 0.0) -> void:
	has_die = true
	value = v
	element = el
	heat = h
	_glows = str(Elements.look(el).glow) != ""
	queue_redraw()


## Adesivos da face do dado encaixado (DieFace.marks). clear_die zera.
func set_marks(n_stickers: int, n_gold: int) -> void:
	stickers = n_stickers
	gold = n_gold
	queue_redraw()


## Mesmo dado de outro buraco (valor, elemento, brilho e adesivos): cópias que voam.
func copy_die(o: Hole) -> void:
	set_die(o.value, o.element, o.heat)
	set_marks(o.stickers, o.gold)


func set_heat(h: float) -> void:
	heat = h
	queue_redraw()


func _process(_delta: float) -> void:
	if _glows and has_die and not faded:
		queue_redraw()


func clear_die() -> void:
	has_die = false
	stickers = 0
	gold = 0
	orig = -1
	badge = ""
	raised = false
	faded = false
	queue_redraw()


func _gui_input(e: InputEvent) -> void:
	if interactive and e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
		tapped.emit(self)
		accept_event()


static func _sb(bg: Color, radius: int, border := 0, border_color := Color.TRANSPARENT) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	if border > 0:
		sb.set_border_width_all(border)
		sb.border_color = border_color
	return sb


func _draw() -> void:
	var s := minf(size.x, size.y)
	var o := Vector2((size.x - s) * 0.5, (size.y - s) * 0.5)
	var r := Rect2(o, Vector2(s, s))
	var rad := int(s * 0.2)
	if floor_hidden and has_die:
		var p0 := s * 0.06
		var dr := Rect2(r.position + Vector2(p0, p0), Vector2(s - p0 * 2, s - p0 * 2))
		DieFace.draw(self, dr, value, element, 0.0, heat, Time.get_ticks_msec() / 1000.0)
		DieFace.marks(self, dr, stickers, gold)
		return
	# Afundado: borda de cima mais escura, fundo um pouco mais claro embaixo.
	draw_style_box(_sb(FLOOR, rad), r)
	var lip := maxf(3.0, s * 0.07)
	draw_style_box(_sb(FLOOR_LO, rad), Rect2(r.position + Vector2(2, lip), r.size - Vector2(4, lip + 2)))
	draw_line(r.position + Vector2(rad, s - 1), r.position + Vector2(s - rad, s - 1), Color(1, 1, 1, 0.07), 1.0)
	if lit:
		draw_style_box(_sb(Color.TRANSPARENT, rad, 3, Kit.ACCENT), r)
	var font := ThemeDB.fallback_font
	if not has_die:
		if req != "":
			var fs := int(s * 0.32)
			draw_string(font, o + Vector2(0, s * 0.5 + fs * 0.35), req, HORIZONTAL_ALIGNMENT_CENTER, s, fs, Kit.ACCENT if lit else REQ_COLOR)
		if caption != "":
			var cs := maxi(12, int(s * 0.15))
			draw_string(font, o + Vector2(2, s * 0.5 + cs * 0.35), caption, HORIZONTAL_ALIGNMENT_CENTER, s - 4, cs, REQ_COLOR)
		return
	# Dado encaixado.
	var pad := s * 0.06
	var d := Rect2(r.position + Vector2(pad, pad), Vector2(s - pad * 2, s - pad * 2))
	if raised:
		d.position.y -= s * 0.14
		draw_style_box(_sb(Color(0, 0, 0, 0.45), rad), Rect2(d.position + Vector2(0, s * 0.12), d.size))
	DieFace.draw(self, d, value, element, 0.6 if faded else 0.0, heat, Time.get_ticks_msec() / 1000.0)
	DieFace.marks(self, d, stickers, gold, 0.6 if faded else 0.0)
	if raised:
		draw_style_box(_sb(Color.TRANSPARENT, int(rad * 0.85) + 2, 4, Kit.ACCENT), d.grow(3))
	_draw_cause(d, font, s)


## Valor de antes riscado (no alto, à esquerda) e o selo da causa (embaixo, à direita).
func _draw_cause(d: Rect2, font: Font, s: float) -> void:
	if faded:
		return
	var fs := maxi(10, int(s * 0.2))
	if orig >= 0:
		var t := str(orig)
		var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var box := Rect2(d.position + Vector2(-2, -2), Vector2(w + 8, fs + 4))
		draw_style_box(_sb(Color(0, 0, 0, 0.78), 4), box)
		draw_string(font, box.position + Vector2(4, fs), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.85, 0.83, 0.89))
		var y := box.position.y + box.size.y * 0.55
		draw_line(Vector2(box.position.x + 2, y), Vector2(box.end.x - 2, y), Color(1.0, 0.45, 0.4), 2.0)
	if badge != "":
		var w2 := font.get_string_size(badge, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var bw := maxf(w2 + 8, fs + 6)
		var b := Rect2(d.end - Vector2(bw - 2, fs + 2), Vector2(bw, fs + 4))
		draw_style_box(_sb(Color(0, 0, 0, 0.78), int((fs + 4) * 0.5), 1, badge_color), b)
		draw_string(font, b.position + Vector2(0, fs), badge, HORIZONTAL_ALIGNMENT_CENTER, bw, fs, badge_color)
