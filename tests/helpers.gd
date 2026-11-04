extends RefCounted
## Utilitários para montar cenários determinísticos.


static func fighter(name: String, spells: Array, hp := 40, player := false, grid := Vector2i(4, 3)) -> Fighter:
	var f := Fighter.new()
	f.name = name
	f.is_player = player
	f.max_hp = hp
	f.hp = hp
	f.inventory = Inventory.make(grid.x, grid.y)
	for id in spells:
		f.inventory.add(id)
	for _i in 8:
		f.bag.append(Die.basic())
	f.reset_fight_state()
	return f


## Põe uma mão com valores fixos (dados da bolsa 0..n-1).
static func hand(f: Fighter, values: Array) -> void:
	f.hand = []
	for i in values.size():
		f.hand.append({"bag": i, "temp": null, "face": 0, "value": int(values[i])})


static func item(f: Fighter, id: String) -> int:
	return f.inventory.ids().find(id)


static func cast(a: Fighter, b: Fighter, casts: Dictionary) -> Array:
	var ev := []
	var c := TurnChoice.new()
	for id in casts:
		c.casts[item(a, id)] = casts[id]
	var used := Resolver.cast_all(a, b, c, ev)
	Resolver.end_turn(a, used, ev)
	return ev


static func rng(s := 1) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r
