class_name DieIcon
extends Control
## Um dado parado, desenhado como na luta (DieFace: foto do dado 3D ou face 2D), para as
## telas fora da luta: bolsa, faixa do jogador e selo das ofertas da torre.
## Com adesivo, o selo ×2 (assets/icons/offer/sticker.png) no canto; face travada, cadeado.

const STICKER := "res://assets/icons/offer/sticker.png"

var value := 6
var element := ""
var stickers := 0
var locked := false
var dim := 0.0


func setup(v: int, el := "", px := 56, n_stickers := 0, is_locked := false) -> DieIcon:
	value = v
	element = el
	stickers = n_stickers
	locked = is_locked
	custom_minimum_size = Vector2(px, px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	return self


func _draw() -> void:
	var s := minf(size.x, size.y)
	var r := Rect2((size - Vector2(s, s)) * 0.5, Vector2(s, s))
	DieFace.draw(self, r, value, element, dim)
	if stickers > 0:
		var st := Kit.tex(STICKER)
		var ss := s * 0.46
		var sr := Rect2(r.end - Vector2(ss, ss) * 0.85, Vector2(ss, ss))
		if st:
			draw_texture_rect(st, sr, false)
		else:
			draw_circle(sr.get_center(), ss * 0.5, Kit.ACCENT)
		if stickers > 1:
			draw_string(Kit.title_font(), sr.position + Vector2(0, ss * 0.72), "×" + str(int(pow(2, stickers))),
				HORIZONTAL_ALIGNMENT_CENTER, ss, int(ss * 0.5), Color(0.15, 0.08, 0.0))
	if locked:
		var lr := s * 0.13
		var c := r.position + Vector2(lr * 1.2, lr * 1.4)
		draw_rect(Rect2(c - Vector2(lr, lr * 0.4), Vector2(lr * 2, lr * 1.5)), Color(0.2, 0.2, 0.24))
		draw_arc(c - Vector2(0, lr * 0.4), lr * 0.65, PI, TAU, 10, Color(0.2, 0.2, 0.24), maxf(2.0, lr * 0.35))
