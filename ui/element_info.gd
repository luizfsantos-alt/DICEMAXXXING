class_name ElementInfo
extends RefCounted
## Elemento citado num texto (magia, oferta, Mestre...): o nome vira um link sublinhado na
## cor do elemento e o toque abre o que ele faz. A explicação só aparece quando pedida.

static var _re: RegEx
static var _by_name := {} ## nome em minúsculas -> id do elemento


## Ids dos elementos citados em text, na ordem em que aparecem (sem repetir).
static func mentions(text: String) -> Array:
	var out := []
	for m in _regex().search_all(text):
		var id: String = _by_name[m.get_string().to_lower()]
		if not (id in out):
			out.append(id)
	return out


## text em BBCode com cada elemento citado como link (meta "el:<id>").
static func linkify(text: String) -> String:
	var safe := text.replace("[", "[lb]")
	var out := ""
	var at := 0
	for m in _regex().search_all(safe):
		var id: String = _by_name[m.get_string().to_lower()]
		var col: Color = Elements.COLORS.get(id, Kit.TEXT)
		out += safe.substr(at, m.get_start() - at)
		out += "[url=el:%s][color=#%s][u]%s[/u][/color][/url]" % [id, col.to_html(false), m.get_string()]
		at = m.get_end()
	return out + safe.substr(at)


## Texto com os elementos tocáveis. Cresce com o conteúdo, como um Label com quebra.
static func rich(text: String, size := 18, color := Kit.TEXT) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_color_override("default_color", color)
	r.meta_underlined = false ## O [u] já sublinha só os elementos.
	r.text = linkify(text)
	r.meta_clicked.connect(func(meta): on_meta(r, meta))
	return r


## Troca o texto de um rich() já criado.
static func set_text(r: RichTextLabel, text: String) -> void:
	r.text = linkify(text)


static func on_meta(from: Control, meta) -> void:
	var s := str(meta)
	if s.begins_with("el:"):
		open(from, s.substr(3))


## Janela com o nome, a raridade e o efeito do elemento. Abre sobre a tela de from.
static func open(from: Control, id: String) -> Overlay:
	var host := _host(from)
	var o := Overlay.open(host, Texts.element_name(id), "OK", 560)
	var rar := Elements.rarity(id)
	o.add_text(Texts.t("rarity." + rar), 16, Kit.RARITY_COLORS.get(rar, Kit.MUTED))
	o.add_text(Texts.element_desc(id), 22)
	return o


## A tela inteira (filho da raiz): a janela cobre tudo, mesmo aberta de dentro de outra.
static func _host(from: Control) -> Control:
	var n: Node = from
	while n.get_parent() != null and n.get_parent() is Control:
		n = n.get_parent()
	return n as Control


static func _regex() -> RegEx:
	if _re == null:
		var names := []
		for id in Elements.LOOKS:
			if id == "":
				continue
			var nm := Texts.element_name(id)
			_by_name[nm.to_lower()] = id
			names.append(nm)
		# Nomes mais longos primeiro; o (?i) aceita "chumbo" no meio da frase.
		names.sort_custom(func(a, b): return a.length() > b.length())
		_re = RegEx.create_from_string("(?i)(?<![\\p{L}])(" + "|".join(names) + ")(?![\\p{L}])")
	return _re
