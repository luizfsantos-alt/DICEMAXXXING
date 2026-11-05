class_name Portrait
extends Control
## Espaço do personagem. Arte provisória: o mago de costas para o seu lado e o vampiro
## para o inimigo (assets/portraits/). Sem a arte, desenha uma silhueta na cor do arquétipo.
## Também faz o retorno visual quando um efeito chega (tremida e brilho colorido).

const COLORS := {
	"sorcerer": Color(0.45, 0.4, 0.85), "assassin": Color(0.75, 0.3, 0.35),
	"minimalist": Color(0.85, 0.85, 0.9), "metallurgist": Color(0.5, 0.52, 0.58), "copyist": Color(0.75, 0.6, 0.3),
	"perfectionist": Color(0.35, 0.7, 0.65), "vampire": Color(0.6, 0.12, 0.2), "barbarian": Color(0.75, 0.45, 0.2),
}
const ART := {
	true: "res://assets/portraits/ally_back.png",
	false: "res://assets/portraits/enemy.png",
}
const BG := Color(0.0, 0.0, 0.0) ## Igual ao fundo da arte, para emendar.

var archetype := "sorcerer"
var back := false ## Jogador de costas.
var art: Texture2D
var _shake := 0.0 ## Tremida restante (segundos).
var _glow := Color(0, 0, 0, 0) ## Brilho do último efeito (some sozinho).


func setup(arch: String, h: int, is_back := false) -> Portrait:
	archetype = arch
	back = is_back
	custom_minimum_size = Vector2(0, h)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	var path: String = ART[is_back]
	if ResourceLoader.exists(path):
		art = load(path)
	set_process(false)
	return self


## Centro da foto na tela (destino dos efeitos).
func target_point() -> Vector2:
	return get_global_transform() * (size * Vector2(0.5, 0.5))


## Retorno de um efeito: "dmg" treme e pisca em vermelho; os outros só brilham na cor.
func react(col: Color, shake := false) -> void:
	_glow = Color(col.r, col.g, col.b, 0.55)
	if shake:
		_shake = 0.28
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_shake = maxf(0.0, _shake - delta)
	_glow.a = maxf(0.0, _glow.a - delta * 1.4)
	if _shake <= 0.0 and _glow.a <= 0.0:
		set_process(false)
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_style_box(Kit.box(BG if art else Color(0.09, 0.08, 0.11), 10, 0), r)
	var off := Vector2.ZERO
	if _shake > 0.0:
		var k := _shake / 0.28
		off = Vector2(sin(_shake * 90.0) * 7.0 * k, cos(_shake * 70.0) * 3.0 * k)
	if art:
		_draw_art(off)
	else:
		_draw_silhouette(off)
	if _glow.a > 0.0:
		var sb := Kit.box(Color(_glow.r, _glow.g, _glow.b, _glow.a * 0.35), 10, 0)
		sb.set_border_width_all(3)
		sb.border_color = _glow
		draw_style_box(sb, r)


## A arte inteira cabe na foto (sem cortar o personagem), centrada e apoiada no chão.
func _draw_art(off: Vector2) -> void:
	var ts := art.get_size()
	var s := minf(size.x / ts.x, size.y / ts.y)
	var d := ts * s
	var pos := Vector2((size.x - d.x) * 0.5, size.y - d.y) + off
	draw_texture_rect(art, Rect2(pos, d), false)


func _draw_silhouette(off: Vector2) -> void:
	var col: Color = COLORS.get(archetype, Kit.PANEL_HI)
	var cx := size.x * 0.5 + off.x
	var floor_y := size.y * 0.94 + off.y
	# Plataforma.
	draw_set_transform(Vector2(cx, floor_y), 0.0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, size.y * 0.5, Color(0.16, 0.145, 0.2))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Corpo e cabeça.
	var head := size.y * 0.16
	var body := Rect2(Vector2(cx - size.y * 0.22, size.y * 0.42 + off.y), Vector2(size.y * 0.44, floor_y - size.y * 0.42 - off.y))
	draw_style_box(Kit.box(col.darkened(0.2), int(size.y * 0.18), 0), body)
	draw_circle(Vector2(cx, size.y * 0.27 + off.y), head, col if not back else col.darkened(0.35))
	if not back:
		draw_circle(Vector2(cx - head * 0.4, size.y * 0.26 + off.y), head * 0.13, Kit.TEXT)
		draw_circle(Vector2(cx + head * 0.4, size.y * 0.26 + off.y), head * 0.13, Kit.TEXT)
