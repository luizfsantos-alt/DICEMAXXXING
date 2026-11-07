class_name Telemetry
extends RefCounted
## Telemetria local de playtest (docs/SPEC_v3.1.md §5.2): cada jornada encerrada fica
## gravada no aparelho (as últimas 50), para comparar o humano com o bot do simulador.
## Nada sai do aparelho: o menu copia o JSON para a área de transferência.
##
## RunState monta o registro da jornada (RunState.log) e chama finish() no fim.
## Só grava com enabled ligado (o jogo liga; testes e simulador não).

const PATH := "user://jornadas.json"
const MAX_RUNS := 50

static var enabled := false
static var path := PATH


## Registro novo de uma jornada.
static func start(character: String, run_seed: int) -> Dictionary:
	return {
		"version": AppVersion.current(), "character": character, "seed": str(run_seed),
		"date": Time.get_datetime_string_from_system(false, true),
		"result": "", "floor": 1, "cause": {}, "coins": 0, "floors": [],
	}


## Linha do andar atual (cria se ainda não existe).
static func floor_entry(log: Dictionary, floor_n: int) -> Dictionary:
	var fl: Array = log.get("floors", [])
	if fl.is_empty() or int(fl.back().get("floor", 0)) != floor_n:
		fl.append({"floor": floor_n, "doors": [], "door": "", "turns": 0, "hp_before": 0, "hp_after": 0,
			"reward_options": [], "reward_pick": "", "stop_options": [], "stop_pick": "", "buys": [], "mods": {}})
		log["floors"] = fl
	return fl.back()


## Nome curto de uma oferta para o registro: "spell:faisca", "sticker", "die:Na".
static func offer_key(o: Dictionary) -> String:
	var k := str(o.get("kind", ""))
	var id := str(o.get("id", ""))
	return k + ":" + id if id != "" else k


## O JSON lê números como float: os inteiros voltam a ser int (o save fica igual).
static func normalize(v: Variant) -> Variant:
	if v is Dictionary:
		var out := {}
		for k in v:
			out[k] = normalize(v[k])
		return out
	if v is Array:
		return v.map(func(x): return normalize(x))
	if v is float and is_equal_approx(v, roundf(v)):
		return int(v)
	return v


## Grava a jornada encerrada (mantém as últimas MAX_RUNS).
static func finish(log: Dictionary) -> void:
	if not enabled or log.is_empty():
		return
	var runs := load_all()
	runs.append(log)
	while runs.size() > MAX_RUNS:
		runs.pop_front()
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(runs))


static func load_all() -> Array:
	if not FileAccess.file_exists(path):
		return []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return []
	var v = JSON.parse_string(f.get_as_text())
	return v if v is Array else []


## JSON de todas as jornadas gravadas (o menu copia para a área de transferência).
static func export_text() -> String:
	return JSON.stringify(load_all(), "\t")


static func clear() -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
