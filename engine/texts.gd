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
	var node = data()
	for p in key.split("."):
		if node is Dictionary and node.has(p):
			node = node[p]
		else:
			return key
	var s := str(node)
	return s.format(args) if not args.is_empty() else s


static func _pair(section: String, id: String, k: int) -> String:
	var sec: Dictionary = data().get(section, {})
	return str(sec[id][k]) if sec.has(id) else id


static func spell_name(id: String) -> String:
	return _pair("spells", id, 0)


static func spell_desc(id: String) -> String:
	return _pair("spells", id, 1)


static func element_name(id: String) -> String:
	return _pair("elements", id, 0) if id != "" else t("ui.plain_die")


static func element_desc(id: String) -> String:
	return _pair("elements", id, 1) if id != "" else ""


static func master_name(id: String) -> String:
	return _pair("masters", id, 0)


static func master_desc(id: String) -> String:
	return _pair("masters", id, 1)


static func character(id: String) -> Array:
	return data().get("characters", {}).get(id, [id, "", ""])


static func name_list(kind: String) -> Array:
	return data().get("names", {}).get(kind, [])
