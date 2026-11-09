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
## Parada (rest): as paradas sorteadas ficam abertas até seguir para as portas. Loja, Poço e
## Escola guardam as ofertas entre as visitas (stop_offers: id -> opções); rest_options são
## as paradas (com "used" na Cura/Escola já usadas e "visited" nas visitadas).
var rest_options: Array = []
var stop_offers: Dictionary = {}
var duel: Duel
var rng := RandomNumberGenerator.new()
var stats := {"wins": 0, "dealt": 0, "taken": 0, "coins": 0}
var last_reward: int = 0
var last_heal: int = 0 ## Vida recuperada na última vitória (a tela mostra).
var tlog: Dictionary = {} ## Registro da jornada para a telemetria (engine/telemetry.gd).
var nemesis: Fighter ## Quem venceu o herói (tela final); null enquanto ele vive.


static func new_run(run_seed: int, char_id := "sorcerer") -> RunState:
	var r := RunState.new()
	r.rng.seed = run_seed
	r.character = char_id if Characters.DATA.has(char_id) else "sorcerer"
	r.hero = EnemyFactory.base(r.character)
	r.hero.name = Texts.t("ui.you")
	r.hero.is_player = true
	r.tlog = Telemetry.start(r.character, run_seed)
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
		_door_enemies()
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
	_door_enemies()


## O inimigo de cada porta nasce com as portas (docs/SPEC_v3.1.md §2.1): a porta mostra
## o arquétipo; a build só aparece na luta.
func _door_enemies() -> void:
	for o in options:
		if str(o.get("kind", "")) != "door" or o.has("enemy"):
			continue
		var e := EnemyFactory.create(floor_n, str(o.id) if o.id != "mestre" else "normal", rng)
		o["enemy"] = e.to_dict()
		o["arch"] = e.archetype
		o["variant"] = e.variant
		o["master"] = e.master_id


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
			var fe := Telemetry.floor_entry(tlog, floor_n)
			fe.doors = options.map(func(x): return {"id": str(x.id), "arch": str(x.get("master", "")) if str(x.get("master", "")) != "" else str(x.get("variant", "")) if str(x.get("variant", "")) != "" else str(x.get("arch", ""))})
			fe.door = str(o.id)
			fe.hp_before = hero.hp
			door = o.id if o.id != "mestre" else "normal"
			start_duel(o.get("enemy", {}))
			return ""
		"rest":
			return _enter_stop(i)
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
	_log_pick(o)
	match phase:
		"start_pick":
			_to_doors()
		"school":
			# Uma escolha por Escola: ela fica marcada e você volta para a parada.
			_mark_stop("school", "used")
			_back_to_rest()
		"reward", "master_reward", "master_rare":
			_advance()
		"shop":
			if o.kind == "maxhp":
				hp_bought += 1
				o.price = Config.PRICE_HP + hp_bought * Config.PRICE_HP_STEP
			else:
				options.remove_at(i)
			stop_offers[phase] = options
		"well":
			if o.kind == "destroy":
				destroys_used += 1
			stop_offers[phase] = options
	return ""


## Telemetria: o que foi escolhido na recompensa ou comprado (Loja, Poço, Escola).
func _log_pick(o: Dictionary) -> void:
	if tlog.is_empty():
		return
	var fe := Telemetry.floor_entry(tlog, floor_n)
	if phase in ["reward", "master_reward", "master_rare"]:
		fe.reward_options = options.map(func(x): return Telemetry.offer_key(x))
		fe.reward_pick = Telemetry.offer_key(o)
	else:
		fe.buys.append(phase + ":" + Telemetry.offer_key(o))


## Volta da Loja, do Poço ou da Escola para a parada; na parada, segue para as portas;
## na recompensa, pula (+moedas).
func leave() -> void:
	if phase == "master_rare":
		phase = "master_reward"
		options = Shop.master_reward()
	elif phase == "reward":
		if not tlog.is_empty():
			var fe := Telemetry.floor_entry(tlog, floor_n)
			fe.reward_options = options.map(func(x): return Telemetry.offer_key(x))
			fe.reward_pick = "skip"
		coins += Config.SKIP_REWARD_COINS
		stats.coins += Config.SKIP_REWARD_COINS
		_advance()
	elif phase in ["shop", "well", "school"]:
		stop_offers[phase] = options
		_back_to_rest()
	elif phase == "rest":
		if not tlog.is_empty():
			var fr := Telemetry.floor_entry(tlog, floor_n)
			fr.stop_options = options.map(func(x): return str(x.id))
			var seen := options.filter(func(x): return x.get("visited", false)).map(func(x): return str(x.id))
			fr.stop_pick = ",".join(PackedStringArray(seen))
		rest_options = []
		stop_offers = {}
		_to_doors()


func sell_spell(item: int) -> bool:
	if phase != "shop" or item < 0 or item >= hero.inventory.items.size():
		return false
	var it: Dictionary = hero.inventory.remove(item)
	coins += Spells.sell_price(str(it.id), int(it.level))
	return true


## Entra na parada i: a Cura cura na hora (paga, uma vez); Loja, Poço e Escola abrem as
## ofertas (sorteadas na 1ª visita e guardadas até seguir para as portas).
func _enter_stop(i: int) -> String:
	var o: Dictionary = options[i]
	var id := str(o.id)
	if o.get("used", false):
		return "ui.stop_used"
	if id == "heal":
		if hero.hp >= hero.max_hp:
			return "ui.hp_full"
		if coins < int(o.price):
			return "ui.not_enough"
		coins -= int(o.price)
		hero.thirst_used = 0 ## A Sede do Vampiro também vale na parada de Cura.
		hero.heal_full(heal_stop_amount(hero))
		o["used"] = true
		o["visited"] = true
		if not tlog.is_empty():
			Telemetry.floor_entry(tlog, floor_n).buys.append("rest:heal")
		return ""
	o["visited"] = true
	rest_options = options
	if not stop_offers.has(id):
		match id:
			"shop":
				stop_offers[id] = Shop.shop(hero, rng, hp_bought, floor_n)
			"school":
				stop_offers[id] = Shop.school(hero, rng, floor_n)
			"well":
				stop_offers[id] = Shop.well(rng, floor_n, hero)
	phase = id
	options = stop_offers[id]
	return ""


## Vida que a Cura da parada recupera: 35% da máxima; metade disso para o Vampiro.
static func heal_stop_amount(h: Fighter) -> int:
	var frac := Config.HEAL_STOP_FRACTION
	if h.archetype == "vampire":
		frac *= Config.VAMPIRE_HEAL_STOP_MULT
	return int(ceil(h.max_hp * frac))


func _back_to_rest() -> void:
	phase = "rest"
	options = rest_options


func _mark_stop(id: String, flag: String) -> void:
	for o in rest_options:
		if str(o.id) == id:
			o[flag] = true


func start_duel(enemy_d: Dictionary = {}) -> void:
	phase = "duel"
	options = []
	var enemy := Fighter.from_dict(enemy_d) if not enemy_d.is_empty() else EnemyFactory.create(floor_n, door, rng)
	duel = Duel.new()
	duel.setup(hero, enemy, rng.randi())


## Chamar quando duel.state deixar de ser "choosing".
func finish_duel() -> void:
	stats.dealt += duel.dealt
	stats.taken += duel.taken
	hero = duel.player
	# Moedas ganhas durante a luta (dado de Ouro, adesivo de ouro).
	coins += hero.coins_won
	stats.coins += hero.coins_won
	hero.coins_won = 0
	var won := duel.state == "won"
	var fe := Telemetry.floor_entry(tlog, floor_n)
	fe.turns = duel.turn
	fe.mods = duel.mods_used.duplicate()
	fe.hp_after = maxi(0, hero.hp)
	var foe := duel.enemy
	if not won:
		nemesis = duel.enemy
	duel = null
	if not won:
		phase = "defeat"
		_end_log("defeat", {"kind": foe.master_id if foe.master_id != "" else (foe.variant if foe.variant != "" else foe.archetype),
			"hp": foe.hp, "max": foe.max_hp, "turn": fe.turns})
		return
	stats.wins += 1
	last_reward = door_coins(door) if not is_master_floor() else Config.MASTER_COINS
	coins += last_reward
	stats.coins += last_reward
	if floor_n >= Config.LAST_FLOOR:
		phase = "victory"
		_end_log("victory", {})
		return
	if is_master_floor():
		if Config.MASTER_HEAL_FRACTION > 0.0:
			hero.heal_full(int(ceil(hero.max_hp * Config.MASTER_HEAL_FRACTION)))
		phase = "master_reward"
		options = Shop.master_reward()
		return
	# Vitória comum: recupera um pouco da vida, antes da recompensa (sem a Sede do Vampiro).
	last_heal = hero.heal(int(ceil(hero.max_hp * Config.WIN_HEAL_FRACTION)))
	fe.hp_after = hero.hp
	phase = "reward"
	options = Shop.reward(hero, rng, floor_n, door)


func _end_log(result: String, cause: Dictionary) -> void:
	tlog.result = result
	tlog.floor = floor_n
	tlog.cause = cause
	tlog.coins = stats.coins
	Telemetry.finish(tlog)


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
		"rest_options": rest_options, "stop_offers": stop_offers,
		"stats": stats, "last_reward": last_reward,
		"seed": str(rng.seed), "rng_state": str(rng.state),
		"duel": duel.to_dict() if duel else {},
		"tlog": tlog,
		"nemesis": nemesis.to_dict() if nemesis else {},
	}


static func _offers(a: Array) -> Array:
	var out := []
	for o in a:
		var oo: Dictionary = o.duplicate()
		oo.price = int(oo.get("price", 0))
		if oo.has("item"):
			oo.item = int(oo.item)
		if oo.has("coins"):
			oo.coins = int(oo.coins)
		out.append(oo)
	return out


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
	r.options = _offers(d.get("options", []))
	r.rest_options = _offers(d.get("rest_options", []))
	r.stop_offers = {}
	var so: Dictionary = d.get("stop_offers", {})
	for k in so:
		r.stop_offers[str(k)] = _offers(so[k])
	# A parada e o lugar aberto apontam para as mesmas listas (as compras ficam guardadas).
	if r.phase == "rest" and not r.rest_options.is_empty():
		r.options = r.rest_options
	elif r.phase in ["shop", "well", "school"] and r.stop_offers.has(r.phase):
		r.options = r.stop_offers[r.phase]
	var st: Dictionary = d.get("stats", {})
	for k in r.stats:
		r.stats[k] = int(st.get(k, 0))
	r.last_reward = int(d.get("last_reward", 0))
	r.tlog = Telemetry.normalize(d.get("tlog", {}))
	r.rng.seed = int(str(d.get("seed", "0")))
	r.rng.state = int(str(d.get("rng_state", "0")))
	if r.phase == "doors":
		r._door_enemies() ## Save de antes: as portas ganham o inimigo ao carregar.
	var nd: Dictionary = d.get("nemesis", {})
	if not nd.is_empty():
		r.nemesis = Fighter.from_dict(nd)
	var dd: Dictionary = d.get("duel", {})
	if not dd.is_empty():
		r.duel = Duel.from_dict(dd)
		r.hero = r.duel.player
	return r
