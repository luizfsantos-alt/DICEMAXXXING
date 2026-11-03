class_name Inventory
extends RefCounted
## Grade de magias com formato (docs/SPEC_v3.md §3 e §5). As peças podem girar.
## A ordem de resolução segue a posição: de cima para baixo, da esquerda para a direita.

var width: int = 4
var height: int = 3
var items: Array = [] ## [{id, level, x, y, rot}]


static func make(w: int, h: int) -> Inventory:
	var inv := Inventory.new()
	inv.width = w
	inv.height = h
	return inv


func cells_of(it: Dictionary) -> Array:
	var out := []
	for c in Spells.shape(it.id, int(it.rot)):
		var p: Vector2i = Vector2i(int(it.x), int(it.y)) + c
		out.append(p)
	return out


func occupied(ignore: int = -1) -> Dictionary:
	var occ := {}
	for i in items.size():
		if i == ignore:
			continue
		for c in cells_of(items[i]):
			occ[c] = i
	return occ


func can_place(id: String, rot: int, x: int, y: int, ignore: int = -1) -> bool:
	var occ := occupied(ignore)
	for c in Spells.shape(id, rot):
		var p: Vector2i = Vector2i(x, y) + c
		if p.x < 0 or p.y < 0 or p.x >= width or p.y >= height or occ.has(p):
			return false
	return true


## Primeiro lugar livre (tentando as 4 rotações). Retorna {x, y, rot} ou {}.
func find_spot(id: String) -> Dictionary:
	for rot in 4:
		for y in height:
			for x in width:
				if can_place(id, rot, x, y):
					return {"x": x, "y": y, "rot": rot}
	return {}


## Cabe, mesmo que seja preciso reorganizar as outras peças?
func fits(id: String) -> bool:
	return not find_spot(id).is_empty() or not _repack(id).is_empty()


## Adiciona no primeiro lugar livre; se não houver, reorganiza tudo (se algum arranjo servir).
func add(id: String, level: int = 1) -> bool:
	var s := find_spot(id)
	if not s.is_empty():
		items.append({"id": id, "level": level, "x": s.x, "y": s.y, "rot": s.rot})
		return true
	var packed := _repack(id)
	if packed.is_empty():
		return false
	var news: Dictionary = packed.pop_back()
	for i in items.size():
		items[i].x = packed[i].x
		items[i].y = packed[i].y
		items[i].rot = packed[i].rot
	items.append({"id": id, "level": level, "x": news.x, "y": news.y, "rot": news.rot})
	return true


## Busca um arranjo para as peças atuais + a nova. Retorna as posições na ordem
## de `items` (a nova por último), ou [] se não existe.
func _repack(id: String) -> Array:
	var ids_all := ids()
	ids_all.append(id)
	var free := width * height
	for x in ids_all:
		free -= Spells.shape(x).size()
	if free < 0:
		return []
	var order_idx := range(ids_all.size())
	order_idx.sort_custom(func(a, b): return Spells.shape(ids_all[a]).size() > Spells.shape(ids_all[b]).size())
	var tmp := Inventory.make(width, height)
	var placed := {}
	_steps = 0
	if not _place_rec(tmp, ids_all, order_idx, 0, placed):
		return []
	var out := []
	for i in ids_all.size():
		out.append(placed[i])
	return out


var _steps := 0
const REPACK_BUDGET := 20000 ## Desiste de buscas longas demais (grade quase cheia).


func _place_rec(tmp: Inventory, ids_all: Array, order_idx: Array, k: int, placed: Dictionary) -> bool:
	if k >= order_idx.size():
		return true
	_steps += 1
	if _steps > REPACK_BUDGET:
		return false
	var i: int = order_idx[k]
	for rot in 4:
		for y in height:
			for x in width:
				if tmp.can_place(ids_all[i], rot, x, y):
					tmp.items.append({"id": ids_all[i], "level": 1, "x": x, "y": y, "rot": rot})
					placed[i] = {"x": x, "y": y, "rot": rot}
					if _place_rec(tmp, ids_all, order_idx, k + 1, placed):
						return true
					tmp.items.pop_back()
	return false


func move(index: int, x: int, y: int, rot: int) -> bool:
	var it: Dictionary = items[index]
	if not can_place(it.id, rot, x, y, index):
		return false
	it.x = x
	it.y = y
	it.rot = rot
	return true


func remove(index: int) -> Dictionary:
	return items.pop_at(index)


func item_at(cell: Vector2i) -> int:
	return int(occupied().get(cell, -1))


## Índices dos itens na ordem de resolução.
func order() -> Array:
	var idx := range(items.size())
	idx.sort_custom(func(a, b):
		var pa := _anchor(items[a])
		var pb := _anchor(items[b])
		return pa.y < pb.y or (pa.y == pb.y and pa.x < pb.x))
	return idx


func _anchor(it: Dictionary) -> Vector2i:
	var best := Vector2i(999, 999)
	for c in cells_of(it):
		if c.y < best.y or (c.y == best.y and c.x < best.x):
			best = c
	return best


func ids() -> Array:
	var out := []
	for it in items:
		out.append(it.id)
	return out


func copy() -> Inventory:
	return Inventory.from_dict(to_dict())


func to_dict() -> Dictionary:
	return {"width": width, "height": height, "items": items.duplicate(true)}


static func from_dict(d: Dictionary) -> Inventory:
	var inv := Inventory.make(int(d.get("width", 4)), int(d.get("height", 3)))
	for it in d.get("items", []):
		inv.items.append({"id": str(it.id), "level": int(it.level), "x": int(it.x), "y": int(it.y), "rot": int(it.rot)})
	return inv
