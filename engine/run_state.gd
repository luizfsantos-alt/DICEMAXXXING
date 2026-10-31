class_name RunState
extends RefCounted
## Uma jornada completa no coliseu.

var fight: int = 1
var coins: int = 0
var rerolls: int = Config.FREE_REROLLS
var hp_bought: int = 0
var chinelo_bonus: int = 0
var dice_sides: Array = [6, 6, 6, 6, 6, 6]
var attack_id: String = "A1"
var defense_id: String = "D1"
var passives: Array = []
var death_defy: bool = false
var phase: String = "duel" ## duel, shop, victory, defeat
var duel: Duel
var offer: Dictionary = {}
var rng := RandomNumberGenerator.new()
var stats := {"wins": 0, "dealt": 0, "taken": 0, "coins": 0}
var last_reward: int = 0


static func new_run(run_seed: int) -> RunState:
	var r := RunState.new()
	r.rng.seed = run_seed
	r.start_duel()
	return r


func player_max_hp() -> int:
	return Config.BASE_HP + Config.GLADIATOR_HP_BONUS + hp_bought * Config.HP_UPGRADE + chinelo_bonus


func make_player() -> Fighter:
	var p := Fighter.new()
	p.name = "Você"
	p.is_player = true
	p.max_hp = player_max_hp()
	p.hp = p.max_hp
	p.dice_sides = dice_sides.duplicate()
	p.attack_id = attack_id
	p.defense_id = defense_id
	p.passives = passives.duplicate()
	p.death_defy = death_defy
	return p


func start_duel() -> void:
	phase = "duel"
	var enemy := EnemyFactory.create(fight, rng)
	duel = Duel.new()
	duel.setup(make_player(), enemy, rng.randi())


## Chamar quando duel.state deixar de ser "choosing".
func finish_duel() -> void:
	death_defy = duel.player.death_defy
	stats.dealt += duel.dealt
	stats.taken += duel.taken
	if duel.state == "won":
		stats.wins += 1
		last_reward = (Config.COINS_BOSS if EnemyFactory.is_boss(fight) else Config.COINS_WIN) + duel.player.coins_earned
		coins += last_reward
		stats.coins += last_reward
		if "DF1" in passives:
			chinelo_bonus += 1
		if fight >= Config.LAST_FIGHT:
			phase = "victory"
		else:
			phase = "shop"
			offer = Shop.generate(self)
	else:
		phase = "defeat"


func next_fight() -> void:
	fight += 1
	offer = {}
	start_duel()


func to_dict() -> Dictionary:
	return {
		"version": 1, "fight": fight, "coins": coins, "rerolls": rerolls,
		"hp_bought": hp_bought, "chinelo_bonus": chinelo_bonus, "dice_sides": dice_sides,
		"attack_id": attack_id, "defense_id": defense_id, "passives": passives,
		"death_defy": death_defy, "phase": phase, "offer": offer, "stats": stats,
		"last_reward": last_reward,
		"seed": str(rng.seed), "rng_state": str(rng.state),
		"duel": duel.to_dict() if duel else {},
	}


static func from_dict(d: Dictionary) -> RunState:
	var r := RunState.new()
	r.fight = int(d.get("fight", 1))
	r.coins = int(d.get("coins", 0))
	r.rerolls = int(d.get("rerolls", Config.FREE_REROLLS))
	r.hp_bought = int(d.get("hp_bought", 0))
	r.chinelo_bonus = int(d.get("chinelo_bonus", 0))
	r.dice_sides = Fighter._ints(d.get("dice_sides", [6, 6, 6, 6, 6, 6]))
	r.attack_id = d.get("attack_id", "A1")
	r.defense_id = d.get("defense_id", "D1")
	r.passives = Array(d.get("passives", []))
	r.death_defy = d.get("death_defy", false)
	r.phase = d.get("phase", "duel")
	r.offer = d.get("offer", {})
	if r.offer.has("price"):
		r.offer.price = int(r.offer.price)
	var st: Dictionary = d.get("stats", {})
	for k in r.stats:
		r.stats[k] = int(st.get(k, 0))
	r.last_reward = int(d.get("last_reward", 0))
	r.rng.seed = int(str(d.get("seed", "0")))
	r.rng.state = int(str(d.get("rng_state", "0")))
	var dd: Dictionary = d.get("duel", {})
	if not dd.is_empty():
		r.duel = Duel.from_dict(dd)
	return r
