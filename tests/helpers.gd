extends RefCounted
## Utilitários para montar cenários determinísticos.


static func fighter(name: String, dice: Array, attack_id := "A1", defense_id := "", passives := [], hp := 40) -> Fighter:
	var f := Fighter.new()
	f.name = name
	f.max_hp = hp
	f.hp = hp
	f.dice = dice.duplicate()
	f.dice_sides = [6, 6, 6, 6, 6, 6]
	f.attack_id = attack_id
	f.defense_id = defense_id
	f.passives = passives.duplicate()
	return f


static func rng(s := 1) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


## Resolve um turno com start_turn (sem rolagem: os dados já estão definidos).
static func play(a: Fighter, b: Fighter, ca: TurnChoice, cb: TurnChoice, turn := 2, seed := 1) -> Dictionary:
	var lg := []
	Resolver.start_turn(a, turn, lg)
	Resolver.start_turn(b, turn, lg)
	return Resolver.resolve(a, b, ca, cb, rng(seed), turn, lg)


static func idle() -> TurnChoice:
	return TurnChoice.make([], [])
