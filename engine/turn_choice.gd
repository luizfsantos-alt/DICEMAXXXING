class_name TurnChoice
extends RefCounted
## Alocação de um turno: quais dados da mão (índices) vão em qual magia
## (índice no inventário). A magia resolve na ordem do inventário.

var casts: Dictionary = {} ## item -> Array de índices da mão


static func make(c: Dictionary = {}) -> TurnChoice:
	var t := TurnChoice.new()
	for k in c:
		t.casts[int(k)] = Die._ints(c[k])
	return t


func used_dice() -> Array:
	var out := []
	for k in casts:
		out.append_array(casts[k])
	return out


func dice_in(item: int) -> Array:
	return casts.get(item, [])


func values_in(f: Fighter, item: int) -> Array:
	var out := []
	for h in dice_in(item):
		out.append(int(f.hand[h].value))
	return out


## Tenta pôr o dado h na magia; retorna false se a exigência não aceitar.
func place(f: Fighter, item: int, h: int) -> bool:
	if h in used_dice() or not can_cast(f, item):
		return false
	var id: String = f.inventory.items[item].id
	if not Spells.accepts_partial(id, values_in(f, item), int(f.hand[h].value)):
		return false
	if not casts.has(item):
		casts[item] = []
	casts[item].append(h)
	return true


func remove_die(h: int) -> void:
	for k in casts.keys():
		casts[k].erase(h)
		if casts[k].is_empty():
			casts.erase(k)


static func can_cast(f: Fighter, item: int) -> bool:
	var id: String = f.inventory.items[item].id
	return not (Spells.is_once(id) and item in f.once_used)


## Magias com exigência completa (as incompletas não são lançadas).
func ready_items(f: Fighter) -> Array:
	var out := []
	for item in f.inventory.order():
		if casts.has(item) and Spells.complete(f.inventory.items[item].id, values_in(f, item)):
			out.append(item)
	return out


## "" se válida, ou a descrição do problema.
func validate(f: Fighter) -> String:
	var seen := {}
	for item in casts:
		if item < 0 or item >= f.inventory.items.size():
			return "magia inválida"
		if not can_cast(f, item):
			return "magia já usada nesta luta"
		for h in casts[item]:
			if h < 0 or h >= f.hand.size() or seen.has(h):
				return "dado inválido"
			seen[h] = true
	return ""


func to_dict() -> Dictionary:
	var d := {}
	for k in casts:
		d[str(k)] = casts[k]
	return d


static func from_dict(d: Dictionary) -> TurnChoice:
	return TurnChoice.make(d)
