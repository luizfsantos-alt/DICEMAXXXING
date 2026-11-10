class_name DieIcon
extends Control
## Um dado parado, desenhado como na luta (DieFace: foto do dado 3D ou face 2D), para as
## telas fora da luta: bolsa, faixa do jogador e selo das ofertas da torre.
## Adesivos como na luta (DieFace.marks): bolinha vermelha "+2" e bolinha dourada;
## face travada, cadeado.

var value := 6
var element := ""
var stickers := 0
var locked := false
var gold := 0
var dim := 0.0


func setup(v: int, el := "", px := 56, n_stickers := 0, is_locked := false, n_gold := 0) -> DieIcon:
	value = v
	element = el
	stickers = n_stickers
	locked = is_locked
	gold = n_gold
	custom_minimum_size = Vector2(px, px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	return self


func _draw() -> void:
	var s := minf(size.x, size.y)
	var r := Rect2((size - Vector2(s, s)) * 0.5, Vector2(s, s))
	DieFace.draw(self, r, value, element, dim)
	DieFace.marks(self, r, stickers, gold, dim)
	if locked:
		var lr := s * 0.13
		var c := r.position + Vector2(lr * 1.2, lr * 1.4)
		draw_rect(Rect2(c - Vector2(lr, lr * 0.4), Vector2(lr * 2, lr * 1.5)), Color(0.2, 0.2, 0.24))
		draw_arc(c - Vector2(0, lr * 0.4), lr * 0.65, PI, TAU, 10, Color(0.2, 0.2, 0.24), maxf(2.0, lr * 0.35))
