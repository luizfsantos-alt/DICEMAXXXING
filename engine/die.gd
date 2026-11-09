class_name Die
extends RefCounted
## Um dado da bolsa: sempre d6, com faces editáveis, um elemento opcional
## e adesivos +2 (docs/SPEC_v3.md §4).

var faces: Array = [1, 2, 3, 4, 5, 6]
var element: String = "" ## "", H, Os, U, Pb, Na, Hg, Am, C, Fe, Cs, Au, Li, Ti
var stickers: Array = [0, 0, 0, 0, 0, 0] ## Adesivos +2 por face (cada um soma Config.STICKER_PLUS).
var gold: Array = [0, 0, 0, 0, 0, 0] ## Adesivos de ouro por face: +1 moeda cada, quando a face é usada.
var locked: Array = [false, false, false, false, false, false] ## Faces que não podem ser editadas.
var charge: int = 0 ## Lítio: carga da bateria (soma na rolagem; só vale na luta).


static func basic() -> Die:
	return Die.new()


static func with_element(el: String) -> Die:
	var d := Die.new()
	Elements.apply(d, el)
	return d


func value(face: int) -> int:
	return int(faces[face]) + Config.STICKER_PLUS * int(stickers[face])


func sticker_count() -> int:
	var n := 0
	for s in stickers:
		n += int(s)
	return n


## O maior valor entre as faces (para a exigência "face mais alta").
func max_value() -> int:
	var m := 0
	for f in 6:
		m = maxi(m, value(f))
	return m


## Soma de todas as faces (o dado "mais forte" da bolsa).
func face_sum() -> int:
	var t := 0
	for f in 6:
		t += value(f)
	return t


## Retorna false se a face estiver travada (Chumbo).
func add_sticker(face: int) -> bool:
	if locked[face]:
		return false
	stickers[face] = int(stickers[face]) + 1
	return true


## Adesivo de ouro: a face usada numa magia dá +1 moeda (por adesivo). false se travada.
func add_gold(face: int) -> bool:
	if locked[face]:
		return false
	gold[face] = int(gold[face]) + 1
	return true


func copy() -> Die:
	return Die.from_dict(to_dict())


func to_dict() -> Dictionary:
	return {"faces": faces.duplicate(), "element": element, "stickers": stickers.duplicate(), "locked": locked.duplicate(),
		"gold": gold.duplicate(), "charge": charge}


static func from_dict(d: Dictionary) -> Die:
	var x := Die.new()
	x.faces = _ints(d.get("faces", [1, 2, 3, 4, 5, 6]))
	x.element = str(d.get("element", ""))
	x.stickers = _ints(d.get("stickers", [0, 0, 0, 0, 0, 0]))
	x.gold = _ints(d.get("gold", [0, 0, 0, 0, 0, 0]))
	x.charge = int(d.get("charge", 0))
	var lk: Array = d.get("locked", [])
	x.locked = []
	for i in 6:
		x.locked.append(bool(lk[i]) if i < lk.size() else false)
	return x


static func _ints(a: Array) -> Array:
	var out := []
	for v in a:
		out.append(int(v))
	return out
