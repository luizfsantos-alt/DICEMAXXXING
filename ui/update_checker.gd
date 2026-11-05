class_name UpdateChecker
extends HTTPRequest
## Consulta o último release no GitHub ao abrir o jogo. Só avisa quando há versão
## mais nova; sem internet ou com qualquer erro, some em silêncio.

signal found(info: Dictionary) ## {"version", "url"}

var local_version := AppVersion.current()


func _ready() -> void:
	timeout = 10.0
	request_completed.connect(_on_done)
	var headers := ["Accept: application/vnd.github+json", "User-Agent: DICEMAXXING"]
	if request(AppVersion.LATEST_URL, headers) != OK:
		queue_free()


func _on_done(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		var info := AppVersion.from_release(JSON.parse_string(body.get_string_from_utf8()))
		if not info.is_empty() and AppVersion.is_newer(info.version, local_version):
			found.emit(info)
	queue_free()
