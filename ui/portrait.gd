class_name Portrait
extends Control
## Espaço do personagem. Cada arquétipo tem 3 variações em assets/portraits/
## (<arquétipo>_1..3.png).
## A variação é sorteada uma vez e guardada no lutador (Fighter.portrait), então não muda
## no meio da run. A arte preenche a foto inteira e só aparece dentro da moldura
## (vermelha para o inimigo, verde para você). Sem a arte, desenha uma silhueta na cor do arquétipo.
## Também faz o retorno visual quando um efeito chega (tremida e brilho colorido).

const COLORS := {
	"sorcerer": Color(0.45, 0.4, 0.85), "assassin": Color(0.75, 0.3, 0.35),
	"minimalist": Color(0.85, 0.85, 0.9), "metallurgist": Color(0.5, 0.52, 0.58), "copyist": Color(0.75, 0.6, 0.3),
	"perfectionist": Color(0.35, 0.7, 0.65), "vampire": Color(0.6, 0.12, 0.2), "barbarian": Color(0.75, 0.45, 0.2),
	"shaman": Color(0.37, 0.88, 0.8),
}
const ART_DIR := "res://assets/portraits/"
## Arquétipos ainda sem as fotos (docs/ARTE_FALTANDO.md): usam a silhueta na cor de COLORS.
const PENDING_ART := ["shaman"]
const VARIATIONS := 3
const BG := Color(0.0, 0.0, 0.0) ## Igual ao fundo da arte, para emendar.
const FRAMES := {true: "frame_player.png", false: "frame_enemy.png"}
## Bordas da moldura que não esticam (esq., cima, dir., baixo), em pixels da textura.
const FRAME_MARGINS := [22, 22, 22, 24]
const INSET := 3.0 ## A arte começa no meio da borda da moldura (nada passa para fora).
const CHAMFER := 6.0 ## Cantos chanfrados da moldura.
const FACE_X := 0.45 ## Ponto da arte (fração da largura) que fica no centro da foto.

var archetype := "sorcerer"
var back := false ## Jogador de costas.
var art: Texture2D
var frame: StyleBoxTexture
var _shake := 0.0 ## Tremida restante (segundos).
var _glow := Color(0, 0, 0, 0) ## Brilho do último efeito (some sozinho).


## Caminho da foto do lutador; sorteia a variação se ainda não tiver uma.
## Mestre de Andar e variantes (Lixeiro, Piromante…) têm foto própria, uma só
## (<id>_1.png); sem ela, usam a do arquétipo.
static func art_path(f: Fighter) -> String:
	if f.portrait < 0 or f.portrait >= VARIATIONS:
		f.portrait = randi() % VARIATIONS
	for special in [f.master_id, f.variant]:
		if special != "" and ResourceLoader.exists("%s%s_1.png" % [ART_DIR, special]):
			return "%s%s_1.png" % [ART_DIR, special]
	return "%s%s_%d.png" % [ART_DIR, f.archetype, f.portrait + 1]


## Roseta de prêmio presa no canto da moldura (assets/ui/rosette_<metal>.png, pixel art de
## tools/desenhar_roseta.py): a vaidade do tema. O metal diz algo: no inimigo, a porta
## (bronze na Fácil, prata na Normal, ouro na Difícil, na Insana e no Mestre); no herói,
## o progresso (bronze até o andar 10, prata até o 20, ouro depois).
const ROSETTE_DIR := "res://assets/ui/rosette_%s.png"
var rosette: TextureRect


static func enemy_metal(f: Fighter, door: String) -> String:
	if f.master_id != "" or door in ["dificil", "insana"]:
		return "gold"
	return "bronze" if door == "facil" else "silver"


static func hero_metal(floor_n: int) -> String:
	return "bronze" if floor_n <= 10 else ("silver" if floor_n <= 20 else "gold")


## Pendura a roseta (metal "" tira). scale: pixels da tela por pixel da arte.
func set_rosette(metal: String, scale := 3) -> void:
	if rosette:
		rosette.queue_free()
		rosette = null
	var t := Kit.tex(ROSETTE_DIR % metal) if metal != "" else null
	if t == null:
		return
	rosette = TextureRect.new()
	rosette.texture = t
	rosette.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rosette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rosette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rosette.size = t.get_size() * scale
	rosette.position = Vector2(INSET + 4, INSET + 2)
	rosette.rotation_degrees = -8.0
	add_child(rosette)


func setup(f: Fighter, h: int, is_back := false) -> Portrait:
	archetype = f.archetype
	back = is_back
	custom_minimum_size = Vector2(0, h)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	var path := art_path(f)
	if ResourceLoader.exists(path):
		art = load(path)
	var fpath: String = ART_DIR + FRAMES[is_back]
	if ResourceLoader.exists(fpath):
		frame = StyleBoxTexture.new()
		frame.texture = load(fpath)
		frame.texture_margin_left = FRAME_MARGINS[0]
		frame.texture_margin_top = FRAME_MARGINS[1]
		frame.texture_margin_right = FRAME_MARGINS[2]
		frame.texture_margin_bottom = FRAME_MARGINS[3]
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
	var off := Vector2.ZERO
	if _shake > 0.0:
		var k := _shake / 0.28
		off = Vector2(sin(_shake * 90.0) * 7.0 * k, cos(_shake * 70.0) * 3.0 * k)
	if not art:
		draw_style_box(Kit.box(Color(0.09, 0.08, 0.11), 10, 0), r)
		_draw_silhouette(off)
		if _glow.a > 0.0:
			var sb := Kit.box(Color(_glow.r, _glow.g, _glow.b, _glow.a * 0.35), 10, 0)
			sb.set_border_width_all(3)
			sb.border_color = _glow
			draw_style_box(sb, r)
		return
	# Com arte: tudo treme junto (arte e moldura).
	draw_set_transform(off)
	var clip := _clip_polygon()
	draw_colored_polygon(clip, BG)
	_draw_art(clip)
	if _glow.a > 0.0:
		draw_colored_polygon(clip, Color(_glow.r, _glow.g, _glow.b, _glow.a * 0.35))
	if frame:
		draw_style_box(frame, r)
	if _glow.a > 0.0:
		var ring := clip.duplicate()
		ring.append(clip[0])
		draw_polyline(ring, _glow, 3.0)
	draw_set_transform(Vector2.ZERO)


## Área de dentro da moldura (retângulo com cantos chanfrados).
func _clip_polygon() -> PackedVector2Array:
	var a := INSET
	var b := INSET
	var c := size.x - INSET
	var d := size.y - INSET
	var k := CHAMFER
	return PackedVector2Array([
		Vector2(a + k, b), Vector2(c - k, b), Vector2(c, b + k), Vector2(c, d - k),
		Vector2(c - k, d), Vector2(a + k, d), Vector2(a, d - k), Vector2(a, b + k),
	])


## A arte cobre toda a área da moldura (o que sobra dos lados fica cortado), apoiada
## embaixo e com o rosto perto do centro; só a parte dentro de "clip" é desenhada.
func _draw_art(clip: PackedVector2Array) -> void:
	var area := Rect2(Vector2(INSET, INSET), size - Vector2(INSET, INSET) * 2.0)
	var ts := art.get_size()
	var s := maxf(area.size.x / ts.x, area.size.y / ts.y)
	var d := ts * s
	var x := area.position.x + area.size.x * 0.5 - d.x * FACE_X
	x = clampf(x, area.end.x - d.x, area.position.x)
	var pos := Vector2(x, area.end.y - d.y)
	var uvs := PackedVector2Array()
	for p in clip:
		uvs.append((p - pos) / d)
	draw_colored_polygon(clip, Color.WHITE, uvs, art)


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
