class_name RunState
extends RefCounted
## Uma jornada na torre (docs/SPEC_v3.md §2). A vida do herói persiste entre as lutas.
##
## Fases: start_pick (Erudito), doors, duel, reward, master_reward, master_rare, rest,
## shop, school, well, victory, defeat. As fases de escolha usam `options` e `choose()`.

var character: String = "sorcerer"
var hero: Fighter
var floor_n: int = 1
var coins: int = 0
var hp_bought: int = 0
var destroys_used: int = 0
var since_rest: int = 0
var door: String = "normal"
var phase: String = "start_pick"
var options: Array = []
var duel: Duel
var rng := RandomNumberGenerator.new()
var stats := {"wins": 0, "dealt": 0, "taken": 0, "coins": 0}
var last_reward: int = 0


static func new_run(run_seed: int, char_id := "sorcerer") -> RunState:
	var r := RunState.new()
	r.rng.seed = run_seed
	r.character = char_id if Characters.DATA.has(char_id) else "sorcerer"
	r.hero = EnemyFactory.base(r.character)
	r.hero.name = Texts.t("ui.you")
	r.hero.is_player = true
	if char_id == "sorcerer":
		r.phase = "start_pick"
		var pool := Spells.ERUDITE_CHOICES.duplicate()
		Fighter._shuffle(pool, r.rng)
		r.options = []
		for id in pool.slice(0, 3):
			r.options.append({"kind": "spell", "id": id, "price": 0, "needs": ""})
	else:
		r._to_doors()
	return r


func _to_doors() -> void:
	phase = "doors"
	if EnemyFactory.is_master(floor_n):
		options = [{"kind": "door", "id": "mestre", "price": 0, "needs": ""}]
		return
	var pool := ["facil", "normal", "dificil"]
	Fighter._shuffle(pool, rng)
	var two := pool.slice(0, 2)
	two.sort_custom(func(a, b): return Config.DOORS[a][0] < Config.DOORS[b][0])
	if rng.randf() < Config.INSANE_DOOR_CHANCE:
		two.append("insana")
	options = []
	for id in two:
		options.append({"kind": "door", "id": id, "price": 0, "needs": "", "coins": door_coins(id)})


static func door_coins(id: String) -> int:
	return int(Config.DOORS.get(id, Config.DOORS.normal)[1])


func is_master_floor() -> bool:
	return EnemyFactory.is_master(floor_n)


## Escolhe a opção i (target: {die, face} quando a oferta pede). Retorna "" ou a chave do erro.
func choose(i: int, target: Dictionary = {}) -> String:
	if i < 0 or i >= options.size():
		return "ui.invalid"
	var o: Dictionary = options[i]
	match phase:
		"doors":
			door = o.id if o.id != "mestre" else "normal"
			start_duel()
			return ""
		"rest":
			return _enter_stop(o.id)
		"master_reward":
			if o.kind == "rare_pick":
				phase = "master_rare"
				options = Shop.rare_choices(rng)
				return ""
	var err := Shop.check(o, hero, target)
	if err != "":
		return err
	var price := Shop.price_of(o, hero, target, destroys_used)
	if coins < price:
		return "ui.not_enough"
	coins -= price
	Shop.apply(o, hero, target)
	match phase:
		"start_pick", "school":
			_to_doors()
		"reward", "master_reward", "master_rare":
			_advance()
		"shop":
			if o.kind == "maxhp":
				hp_bought += 1
				o.price = Config.PRICE_HP + hp_bought * Config.PRICE_HP_STEP
			else:
				options.remove_at(i)
		"well":
			if o.kind == "destroy":
				destroys_used += 1
	return ""


## Sai da Loja, do Poço ou da Escola sem (mais) compras; pula a recompensa (+moedas).
func leave() -> void:
	if phase == "master_rare":
		phase = "master_reward"
		options = Shop.master_reward()
	elif phase == "reward":
		coins += Config.SKIP_REWARD_COINS
		stats.coins += Config.SKIP_REWARD_COINS
		_advance()
	elif phase in ["shop", "well", "school"]:
		_to_doors()


func sell_spell(item: int) -> bool:
	if phase != "shop" or item < 0 or item >= hero.inventory.items.size():
		return false
	var it: Dictionary = hero.inventory.remove(item)
	coins += Spells.sell_price(str(it.id), int(it.level))
	return true


func _enter_stop(id: String) -> String:
	match id:
		"heal":
			hero.thirst_used = 0 ## A Sede do Vampiro também vale na parada de Cura.
			hero.heal_full(int(ceil(hero.max_hp * Config.HEAL_STOP_FRACTION)))
			_to_doors()
		"shop":
			phase = "shop"
			options = Shop.shop(hero, rng, hp_bought, floor_n)
		"school":
			phase = "school"
			options = Shop.school(hero, rng, floor_n)
		"well":
			phase = "well"
			options = Shop.well(rng, floor_n, hero)
	return ""


func start_duel() -> void:
	phase = "duel"
	options = []
	var enemy := EnemyFactory.create(floor_n, door, rng)
	duel = Duel.new()
	duel.setup(hero, enemy, rng.randi())


## Chamar quando duel.state deixar de ser "choosing".
func finish_duel() -> void:
	stats.dealt += duel.dealt
	stats.taken += duel.taken
	hero = duel.player
	var won := duel.state == "won"
	duel = null
	if not won:
		phase = "defeat"
		return
	stats.wins += 1
	last_reward = door_coins(door) if not is_master_floor() else 20
	coins += last_reward
	stats.coins += last_reward
	if floor_n >= Config.LAST_FLOOR:
		phase = "victory"
		return
	if is_master_floor():
		phase = "master_reward"
		options = Shop.master_reward()
		return
	phase = "reward"
	options = Shop.reward(hero, rng, floor_n, door)


func _advance() -> void:
	floor_n += 1
	since_rest += 1
	if since_rest >= Config.REST_EVERY:
		since_rest = 0
		phase = "rest"
		options = Shop.rest_stops(rng)
	else:
		_to_doors()


func to_dict() -> Dictionary:
	return {
		"version": 3, "character": character, "hero": hero.to_dict(), "floor": floor_n,
		"coins": coins, "hp_bought": hp_bought, "destroys_used": destroys_used,
		"since_rest": since_rest, "door": door, "phase": phase, "options": options,
		"stats": stats, "last_reward": last_reward,
		"seed": str(rng.seed), "rng_state": str(rng.state),
		"duel": duel.to_dict() if duel else {},
	}


static func from_dict(d: Dictionary) -> RunState:
	if int(d.get("version", 0)) != 3:
		return null
	var r := RunState.new()
	r.character = str(d.get("character", "sorcerer"))
	r.hero = Fighter.from_dict(d.get("hero", {}))
	r.floor_n = int(d.get("floor", 1))
	r.coins = int(d.get("coins", 0))
	r.hp_bought = int(d.get("hp_bought", 0))
	r.destroys_used = int(d.get("destroys_used", 0))
	r.since_rest = int(d.get("since_rest", 0))
	r.door = str(d.get("door", "normal"))
	r.phase = str(d.get("phase", "doors"))
	r.options = []
	for o in d.get("options", []):
		var oo: Dictionary = o.duplicate()
		oo.price = int(oo.get("price", 0))
		if oo.has("item"):
			oo.item = int(oo.item)
		if oo.has("coins"):
			oo.coins = int(oo.coins)
		r.options.append(oo)
	var st: Dictionary = d.get("stats", {})
	for k in r.stats:
		r.stats[k] = int(st.get(k, 0))
	r.last_reward = int(d.get("last_reward", 0))
	r.rng.seed = int(str(d.get("seed", "0")))
	r.rng.state = int(str(d.get("rng_state", "0")))
	var dd: Dictionary = d.get("duel", {})
	if not dd.is_empty():
		r.duel = Duel.from_dict(dd)
		r.hero = r.duel.player
	return r
