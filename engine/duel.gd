class_name Duel
extends RefCounted
## Um duelo: turnos, rolagens, escolha oculta do inimigo e checagem de morte.

var player: Fighter
var enemy: Fighter
var turn: int = 0
var rng := RandomNumberGenerator.new()
var enemy_choice: TurnChoice
var state: String = "choosing" ## choosing, won, lost
var turn_log: Array = [] ## Eventos do início do turno atual (antes da escolha).
var last_log: Array = [] ## Log completo do último turno resolvido.
var turn_events: Array = [] ## Eventos estruturados do início do turno atual (não salvos).
var dealt: int = 0
var taken: int = 0


func setup(p: Fighter, e: Fighter, duel_seed: int) -> void:
	player = p
	enemy = e
	for f in [p, e]:
		f.reset_duel_state()
		f.hp = f.max_hp
	rng.seed = duel_seed
	begin_turn()


## A e B da ordem oficial, mais a escolha (oculta) do inimigo.
func begin_turn() -> void:
	turn += 1
	Resolver.events = []
	turn_log = [Texts.t("log.turn", {"n": turn})]
	Resolver.start_turn(player, turn, turn_log)
	Resolver.start_turn(enemy, turn, turn_log)
	Resolver.roll(player, rng, turn, turn_log)
	Resolver.roll(enemy, rng, turn, turn_log)
	enemy_choice = EnemyAI.choose(enemy, rng)
	turn_events = Resolver.take_events()


## C a N. Retorna o relatório do turno (ou {"error": ...}).
func submit(choice: TurnChoice) -> Dictionary:
	if state != "choosing":
		return {"error": "duelo encerrado"}
	var err := choice.validate(player)
	if err != "":
		return {"error": err}
	var lg := turn_log.duplicate()
	var rep := Resolver.resolve(player, enemy, choice, enemy_choice, rng, turn, lg)
	dealt += rep.dmg_to_b
	taken += rep.dmg_to_a + rep.self_a
	# N. Morte: empate = derrota do jogador; Desafio à Morte restaura.
	var player_dead := player.hp <= 0
	if player_dead and player.death_defy:
		player.death_defy = false
		player.hp = player.max_hp
		player_dead = false
		lg.append(Texts.t("log.death_defy", {"who": player.name}))
		rep.events.append({"t": "death_defy", "side": "player", "who": player.name, "hp": player.hp})
	if player_dead:
		state = "lost"
	elif enemy.hp <= 0:
		state = "won"
	elif turn >= Config.TURN_LIMIT:
		state = "lost"
		lg.append(Texts.t("log.turn_limit"))
		rep.events.append({"t": "turn_limit", "side": "player", "who": player.name})
	rep.log = lg
	rep.enemy_choice = enemy_choice
	rep.player_choice = choice
	last_log = lg
	return rep


func to_dict() -> Dictionary:
	return {
		"player": player.to_dict(), "enemy": enemy.to_dict(), "turn": turn,
		"seed": str(rng.seed), "rng_state": str(rng.state),
		"enemy_choice": enemy_choice.to_dict() if enemy_choice else {},
		"state": state, "turn_log": turn_log, "last_log": last_log,
		"dealt": dealt, "taken": taken,
	}


static func from_dict(d: Dictionary) -> Duel:
	var du := Duel.new()
	du.player = Fighter.from_dict(d.get("player", {}))
	du.enemy = Fighter.from_dict(d.get("enemy", {}))
	du.turn = int(d.get("turn", 0))
	du.rng.seed = int(str(d.get("seed", "0")))
	du.rng.state = int(str(d.get("rng_state", "0")))
	du.enemy_choice = TurnChoice.from_dict(d.get("enemy_choice", {}))
	du.state = d.get("state", "choosing")
	du.turn_log = Array(d.get("turn_log", []))
	du.last_log = Array(d.get("last_log", []))
	du.dealt = int(d.get("dealt", 0))
	du.taken = int(d.get("taken", 0))
	return du
