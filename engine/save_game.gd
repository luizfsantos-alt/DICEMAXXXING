class_name SaveGame
extends RefCounted
## Salvamento automático da jornada em user://save.json.

const PATH := "user://save.json"


static func save(run: RunState) -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_error("SaveGame: não foi possível salvar")
		return
	f.store_string(JSON.stringify(run.to_dict()))


static func exists() -> bool:
	return FileAccess.file_exists(PATH)


static func load_run() -> RunState:
	if not exists():
		return null
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return null
	var d = JSON.parse_string(f.get_as_text())
	if not (d is Dictionary):
		return null
	return RunState.from_dict(d)


static func clear() -> void:
	if exists():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
