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
		elif node is Array and p.is_valid_int() and int(p) < node.size():
			node = node[int(p)]
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


## Efeito curto da magia no nível "level" (o texto do cartão). Do nível 2 em diante usa
## "spell_fx_lv": uma lista [nível 2, nível 3] ou um modelo em que "{3}" vira 3 × o
## multiplicador do nível (4,5 no nível 2; 6 no 3), "{=5}" o mesmo arredondado para cima
## como no jogo (Config.scale) e "{-1}" só o que o nível acrescenta (0,5 no 2; 1 no 3).
static func spell_fx(id: String, level := 1) -> String:
	if level > 1 and scales_with_level(id):
		level = clampi(level, 1, Config.MAX_LEVEL)
		var mult: float = Config.LEVEL_MULT[level - 1]
		var raw = data().spell_fx_lv[id]
		if raw is Array:
			return str(raw[mini(level - 2, raw.size() - 1)])
		var s := str(raw)
		var re := RegEx.create_from_string("\\{([=-]?)(\\d+)\\}")
		for m in re.search_all(s):
			var n := int(m.get_string(2))
			var txt := num(n * mult)
			if m.get_string(1) == "=":
				txt = str(Config.scale(n, level))
			elif m.get_string(1) == "-":
				txt = num(n * (mult - 1.0))
			s = s.replace(m.get_string(0), txt)
		return s
	var short := t("spell_fx." + id)
	return short if short != "spell_fx." + id else spell_desc(id)


## A magia tem texto por nível (todas têm; o teste confere).
static func scales_with_level(id: String) -> bool:
	return data().get("spell_fx_lv", {}).has(id)


## Número com vírgula, sem casas à toa: 4.5 -> "4,5"; 6.0 -> "6".
static func num(v: float) -> String:
	if is_equal_approx(v, roundf(v)):
		return str(int(roundf(v)))
	return ("%.1f" % v).replace(".", ",")


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


## Como o lutador aparece: Mestre pelo nome; os outros pela variante ("Piromante") ou
## pelo arquétipo ("Assassino"). Inimigos comuns não têm nome próprio.
static func fighter_title(f: Fighter) -> String:
	if f.master_id != "":
		return master_name(f.master_id)
	if f.variant != "":
		return t("variants." + f.variant).get_slice(":", 0)
	return t("archetypes." + f.archetype)
