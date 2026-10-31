class_name Texts
extends RefCounted
## Acesso aos textos PT-BR externalizados.

const PATH := "res://data/texts_pt_br.json"
static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var f := FileAccess.open(PATH, FileAccess.READ)
		if f == null:
			push_error("Texts: não foi possível abrir " + PATH)
			return {}
		var parsed = JSON.parse_string(f.get_as_text())
		if parsed is Dictionary:
			_data = parsed
	return _data


## Busca "secao.chave" e formata com {placeholders}.
static func t(key: String, args: Dictionary = {}) -> String:
	var parts := key.split(".")
	var node = data()
	for p in parts:
		if node is Dictionary and node.has(p):
			node = node[p]
		else:
			return key
	var s := str(node)
	return s.format(args) if not args.is_empty() else s


static func item_name(id: String) -> String:
	var items: Dictionary = data().get("items", {})
	return items[id][0] if items.has(id) else id


static func item_desc(id: String) -> String:
	var items: Dictionary = data().get("items", {})
	return items[id][1] if items.has(id) else ""


static func boss_name(id: String) -> String:
	var b: Dictionary = data().get("bosses", {})
	return b[id][0] if b.has(id) else id


static func boss_desc(id: String) -> String:
	var b: Dictionary = data().get("bosses", {})
	return b[id][1] if b.has(id) else ""


static func name_list(kind: String) -> Array:
	return data().get("names", {}).get(kind, [])
