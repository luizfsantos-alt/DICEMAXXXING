class_name AppVersion
extends RefCounted
## Versão do app e comparação com o último release do GitHub (aviso de atualização).
## A versão instalada vem de application/config/version, que o CI preenche com a tag.

const REPO := "luizfsantos-alt/DICEMAXXXING"
const LATEST_URL := "https://api.github.com/repos/" + REPO + "/releases/latest"


static func current() -> String:
	return str(ProjectSettings.get_setting("application/config/version", ""))


## "v1.2.3-beta" -> {"nums": [1, 2, 3], "pre": "beta"}. Texto inválido -> {}.
static func parse(text: String) -> Dictionary:
	var s := text.strip_edges()
	if s.begins_with("v") or s.begins_with("V"):
		s = s.substr(1)
	var plus := s.find("+") ## Metadados de build não contam.
	if plus >= 0:
		s = s.substr(0, plus)
	var pre := ""
	var dash := s.find("-")
	if dash >= 0:
		pre = s.substr(dash + 1)
		s = s.substr(0, dash)
	if s == "":
		return {}
	var nums: Array[int] = []
	for p in s.split("."):
		if not p.is_valid_int() or int(p) < 0:
			return {}
		nums.append(int(p))
	return {"nums": nums, "pre": pre}


## true se `remote` for mais nova que `local`. Qualquer versão inválida -> false.
## Números iguais: a versão final (sem sufixo) ganha da pré-versão ("1.0.0" > "1.0.0-beta").
static func is_newer(remote: String, local: String) -> bool:
	var r := parse(remote)
	var l := parse(local)
	if r.is_empty() or l.is_empty():
		return false
	var rn: Array = r.nums
	var ln: Array = l.nums
	for i in maxi(rn.size(), ln.size()):
		var a: int = rn[i] if i < rn.size() else 0
		var b: int = ln[i] if i < ln.size() else 0
		if a != b:
			return a > b
	return r.pre == "" and l.pre != ""


## Resposta de /releases/latest -> {"version", "url"} ou {} se não servir.
## A url é o primeiro .apk do release; sem .apk, a página do release.
static func from_release(data) -> Dictionary:
	if not data is Dictionary:
		return {}
	var tag := str(data.get("tag_name", ""))
	if parse(tag).is_empty():
		return {}
	var url := str(data.get("html_url", ""))
	var assets = data.get("assets", [])
	if assets is Array:
		for a in assets:
			if a is Dictionary and str(a.get("name", "")).to_lower().ends_with(".apk"):
				url = str(a.get("browser_download_url", url))
				break
	if not url.begins_with("https://"):
		return {}
	return {"version": tag.trim_prefix("v").trim_prefix("V"), "url": url}
