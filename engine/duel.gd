class_name Duel
extends RefCounted
## Uma luta em turnos sequenciais (docs/SPEC_v3.md §6). O jogador começa.
## Entre chamadas, o duelo está sempre no turno do jogador, com a mão já rolada.

var player: Fighter
var enemy: Fighter
var turn: int = 0 ## Turnos somados dos dois lados.
var rng := RandomNumberGenerator.new()
var state: String = "choosing" ## choosing, won, lost
var turn_events: Array = [] ## Início do turno do jogador (não salvo).
var dealt: int = 0
var taken: int = 0


func setup(p: Fighter, e: Fighter, duel_seed: int) -> void:
	player = p
	enemy = e
	for f in [p, e]:
		f.reset_fight_state()
	rng.seed = duel_seed
	turn_events = []
	_begin_player_turn(turn_events)


func _begin_player_turn(ev: Array) -> void:
	turn += 1
	ev.append({"t": "turn", "side": "player", "n": turn})
	Resolver.start_turn(player, ev)
	if _check(ev):
		return
	Resolver.draw_and_roll(player, enemy, rng, ev)


## Resolve o turno do jogador, joga o turno inteiro do inimigo e prepara o
## próximo turno do jogador. Retorna {events, enemy_choice} ou {error}.
func submit(choice: TurnChoice) -> Dictionary:
	if state != "choosing":
		return {"error": "luta encerrada"}
	var err := choice.validate(player)
	if err != "":
		return {"error": err}
	var ev := []
	var hp_e := enemy.hp
	var used := Resolver.cast_all(player, enemy, choice, ev)
	dealt += maxi(0, hp_e - enemy.hp)
	Resolver.end_turn(player, used, ev)
	var rep := {"events": ev, "enemy_choice": {}, "enemy_hand": []}
	if _check(ev) or _limit(ev):
		return rep
	# Turno do inimigo.
	var hp_p := player.hp
	turn += 1
	ev.append({"t": "turn", "side": "enemy", "n": turn})
	Resolver.start_turn(enemy, ev)
	if not _check(ev):
		Resolver.draw_and_roll(enemy, player, rng, ev)
		Resolver.on_turn_effects(enemy, player, ev)
		rep.enemy_hand = enemy.hand_values()
		var ec := EnemyAI.choose(enemy, player, rng)
		rep.enemy_choice = ec.to_dict()
		var eu := Resolver.cast_all(enemy, player, ec, ev)
		Resolver.end_turn(enemy, eu, ev)
	taken += maxi(0, hp_p - player.hp)
	if _check(ev) or _limit(ev):
		return rep
	turn_events = []
	_begin_player_turn(turn_events)
	return rep


## Empate = derrota do jogador.
func _check(ev: Array) -> bool:
	if player.hp <= 0:
		state = "lost"
	elif enemy.hp <= 0:
		state = "won"
	else:
		return false
	ev.append({"t": "end", "side": "player", "won": state == "won"})
	return true


func _limit(ev: Array) -> bool:
	if turn < Config.TURN_LIMIT:
		return false
	state = "lost"
	ev.append({"t": "turn_limit", "side": "player"})
	return true


func to_dict() -> Dictionary:
	return {
		"player": player.to_dict(), "enemy": enemy.to_dict(), "turn": turn,
		"seed": str(rng.seed), "rng_state": str(rng.state), "state": state,
		"dealt": dealt, "taken": taken,
	}


static func from_dict(d: Dictionary) -> Duel:
	var du := Duel.new()
	du.player = Fighter.from_dict(d.get("player", {}))
	du.enemy = Fighter.from_dict(d.get("enemy", {}))
	du.turn = int(d.get("turn", 0))
	du.rng.seed = int(str(d.get("seed", "0")))
	du.rng.state = int(str(d.get("rng_state", "0")))
	du.state = str(d.get("state", "choosing"))
	du.dealt = int(d.get("dealt", 0))
	du.taken = int(d.get("taken", 0))
	return du
