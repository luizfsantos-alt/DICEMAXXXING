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
	Resolver.watch = [p, e]
	Resolver.inspire(p, e, rng, turn_events)
	Resolver.inspire(e, p, rng, turn_events)
	_begin_player_turn(turn_events)
	Resolver.watch = []


func _begin_player_turn(ev: Array) -> void:
	turn += 1
	Resolver.push(ev, {"t": "turn", "side": "player", "n": turn})
	Resolver.start_turn(player, ev)
	if _check(ev):
		return
	Resolver.draw_and_roll(player, enemy, rng, ev)


## Resolve o turno do jogador, joga o turno inteiro do inimigo e prepara o
## próximo turno do jogador. Retorna {events, enemy_choice} ou {error}.
## Cada evento leva "st": os status dos dois lados naquele instante.
func submit(choice: TurnChoice) -> Dictionary:
	Resolver.watch = [player, enemy]
	var rep := _submit(choice)
	Resolver.watch = []
	return rep


func _submit(choice: TurnChoice) -> Dictionary:
	if state != "choosing":
		return {"error": "luta encerrada"}
	var err := choice.validate(player)
	if err != "":
		return {"error": err}
	var ev := []
	var hp_e := enemy.hp
	var used := Resolver.cast_all(player, enemy, choice, ev, rng)
	dealt += maxi(0, hp_e - enemy.hp)
	Resolver.end_turn(player, used, ev, choice.keep, reactor())
	var rep := {"events": ev, "enemy_choice": {}, "enemy_hand": []}
	if _check(ev) or _limit(ev):
		return rep
	# Turno do inimigo.
	var hp_p := player.hp
	turn += 1
	Resolver.push(ev, {"t": "turn", "side": "enemy", "n": turn})
	Resolver.start_turn(enemy, ev)
	if not _check(ev):
		Resolver.draw_and_roll(enemy, player, rng, ev)
		Resolver.on_turn_effects(enemy, player, ev)
		rep.enemy_hand = enemy.hand_values()
		var ec := EnemyAI.choose(enemy, player, rng)
		rep.enemy_choice = ec.to_dict()
		var eu := Resolver.cast_all(enemy, player, ec, ev, rng)
		Resolver.end_turn(enemy, eu, ev, ec.keep, reactor())
	taken += maxi(0, hp_p - player.hp)
	if _check(ev) or _limit(ev):
		return rep
	turn_events = []
	_begin_player_turn(turn_events)
	return rep


## O Reator: todo dado parado no fim do turno envenena quem o rolou (os dois lados).
func reactor() -> bool:
	return enemy.master_id == "reator" or player.master_id == "reator"


## Empate = derrota do jogador.
func _check(ev: Array) -> bool:
	if player.hp <= 0:
		state = "lost"
	elif enemy.hp <= 0:
		state = "won"
	else:
		return false
	Resolver.push(ev, {"t": "end", "side": "player", "won": state == "won"})
	_cleanup()
	return true


## O que vale só nesta luta (adesivos roubados) volta ao normal.
func _cleanup() -> void:
	player.end_fight_cleanup()
	enemy.end_fight_cleanup()


func _limit(ev: Array) -> bool:
	if turn < Config.TURN_LIMIT:
		return false
	state = "lost"
	Resolver.push(ev, {"t": "turn_limit", "side": "player"})
	_cleanup()
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
