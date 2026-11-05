class_name TurnChoice
extends RefCounted
## Alocação de um turno: quais dados da mão (índices) vão em qual magia
## (índice no inventário). A magia resolve na ordem do inventário.
##
## Dados devolvidos (Força Desnecessária, Imitação Barata): quando a magia recebe o
## dado, dois dados novos entram no fim da mão, já valendo, e podem ir para outras
## magias neste turno. Tirar o dado da magia recolhe os devolvidos (e solta o que
## dependia deles).

var casts: Dictionary = {} ## item -> Array de índices da mão
var spawned: Dictionary = {} ## item -> índices da mão dos dados devolvidos
var keep: Array = [] ## Perfeccionista: sobras a guardar para a próxima mão (até 2).


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


func tops_in(f: Fighter, item: int) -> Array:
	var out := []
	for h in dice_in(item):
		out.append(bool(f.hand[h].get("top", false)))
	return out


## Tenta pôr o dado h na magia; retorna false se a exigência não aceitar.
func place(f: Fighter, item: int, h: int) -> bool:
	if h < 0 or h >= f.hand.size() or h in used_dice() or not can_cast(f, item):
		return false
	var id: String = f.inventory.items[item].id
	var e: Dictionary = f.hand[h]
	if not Spells.accepts_partial(id, values_in(f, item), int(e.value), bool(e.get("top", false))):
		return false
	if not casts.has(item):
		casts[item] = []
	casts[item].append(h)
	_spawn(f, item)
	return true


## Magias que devolvem dados: assim que ficam completas, dois dados entram na mão.
func _spawn(f: Fighter, item: int) -> void:
	var id: String = f.inventory.items[item].id
	var fx := str(Spells.get_def(id).get("fx", ""))
	if not (fx in ["spawn_half", "spawn_copy"]) or spawned.has(item):
		return
	if not Spells.complete(id, values_in(f, item), tops_in(f, item)):
		return
	var src: Dictionary = f.hand[dice_in(item)[0]]
	var v := int(src.value)
	var out := []
	for _k in 2:
		var e := {"bag": -1, "temp": null, "face": 0, "value": v, "top": false, "fixed": true, "plus": 0, "spawn": item}
		if fx == "spawn_half":
			e.value = Config.ceil_div(v, 2)
			e.temp = Die.basic()
		else:
			var sd := f.die_of(src)
			e.temp = sd.copy() if sd else Die.basic()
		out.append(f.hand.size())
		f.hand.append(e)
	spawned[item] = out


## Devolve o dado h para a mão. Se ele estava numa magia que devolveu dados, esses
## dados saem da mão (e de onde tinham sido postos). Sem f, só tira o dado.
func remove_die(h: int, f: Fighter = null) -> void:
	var src_item := -1
	for k in casts.keys():
		if h in casts[k]:
			src_item = k
		casts[k].erase(h)
		if casts[k].is_empty():
			casts.erase(k)
	if f != null and src_item >= 0 and spawned.has(src_item):
		var outs: Array = spawned[src_item]
		_truncate(f, int(outs.min()))


## Corta a mão no índice first (os dados devolvidos ficam sempre no fim).
func _truncate(f: Fighter, first: int) -> void:
	if first < f.hand.size():
		f.hand.resize(first)
	for it in spawned.keys():
		var outs: Array = spawned[it]
		if outs.any(func(x): return int(x) >= first):
			spawned.erase(it)
			casts.erase(it)
	for k in casts.keys():
		casts[k] = casts[k].filter(func(x): return int(x) < first)
		if casts[k].is_empty():
			casts.erase(k)


static func can_cast(f: Fighter, item: int) -> bool:
	var id: String = f.inventory.items[item].id
	var lim := Spells.max_uses(id)
	return lim == 0 or f.uses_of(item) < lim


## Magias com exigência completa (as incompletas não são lançadas).
func ready_items(f: Fighter) -> Array:
	var out := []
	for item in f.inventory.order():
		if casts.has(item) and Spells.complete(f.inventory.items[item].id, values_in(f, item), tops_in(f, item)):
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
	if keep.size() > Characters.KEEP_MAX:
		return "dados guardados demais"
	for h in keep:
		if f.archetype != "perfectionist" or h < 0 or h >= f.hand.size() or seen.has(h):
			return "dado guardado inválido"
	return ""


func to_dict() -> Dictionary:
	var d := {}
	for k in casts:
		d[str(k)] = casts[k]
	if not keep.is_empty():
		d["keep"] = keep
	return d


static func from_dict(d: Dictionary) -> TurnChoice:
	var c := d.duplicate()
	c.erase("keep")
	var t := TurnChoice.make(c)
	t.keep = Die._ints(d.get("keep", []))
	return t
