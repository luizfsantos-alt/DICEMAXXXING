extends SceneTree
## Carrega todos os scripts do projeto e falha se algum tiver erro de análise.
func _init() -> void:
	var bad := 0
	for dir in ["res://engine", "res://ui", "res://sim", "res://tests"]:
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".gd"):
				var s = load(dir + "/" + f)
				if s == null or not s.can_instantiate():
					printerr("FALHOU: ", dir, "/", f)
					bad += 1
	print("scripts com erro: ", bad)
	quit(1 if bad > 0 else 0)
