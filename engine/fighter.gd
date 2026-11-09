class_name Fighter
extends RefCounted
## Um lado do duelo (jogador ou inimigo): bolsa, inventário de magias e estado da luta.

var name: String = ""
var is_player: bool = false
var archetype: String = "sorcerer" ## Characters.ALL
var variant: String = "" ## "", lixeiro, piromante, fundidor, monge
var master_id: String = "" ## Mestre de Andar (ex.: porteiro).
var personality: String = "" ## bruto, cauteloso, caotico (oculta na UI).
var portrait: int = -1 ## Variação da foto (sorteada pela UI na primeira vez; -1 = ainda não).
var max_hp: int = 50
var hp: int = 50
var hand_size: int = Config.HAND_SIZE
var bag: Array = [] ## Array[Die]
var inventory: Inventory = Inventory.make(4, 3)

# Estado da luta.
var draw_pile: Array = [] ## Índices da bolsa.
var discard: Array = []
## Mão: [{bag: int (-1 = temporário, -2 = destruído), temp: Die|null, face, value,
## top (face mais alta do dado), fixed (marcado: não rola), plus (+ em todas as faces),
## spawn (magia que devolveu este dado na alocação, ou -1)}].
var hand: Array = []
var last_hand: Array = [] ## Valores da última mão (visível ao adversário).
var block: int = 0
var mirror: bool = false
var dodge: bool = false
var poison: int = 0
var burn: int = 0
var sacrifice_bonus: int = 0
var once_used: Array = [] ## Índices do inventário usados nesta luta (um por uso).
var turns_taken: int = 0
var riposte: int = 0 ## Revide Elegante: dano devolvido por golpe enquanto houver bloqueio.
var immune: int = 0 ## Imune a Críticas: anula os próximos efeitos negativos do inimigo.
var recycle: bool = false ## Improviso Brilhante: sobras viram bloqueio neste turno.
## Nível da magia que deu o Espelho, a Esquiva e o Improviso (o ganho vem na hora de usar).
var mirror_lvl: int = 1
var dodge_lvl: int = 1
var recycle_lvl: int = 1
## Marca para a próxima mão: {bag, temp (dict de Die, se bag < 0), value, fixed, plus}.
var marked: Dictionary = {}
var extra_next: Array = [] ## Dados que entram na próxima mão sem rolar: [{temp, value}].
var benched: Array = [] ## Índices da bolsa fora desta luta (Arrancar das Mãos).
var fight_mods: Array = [] ## Adesivos mexidos nesta luta, para desfazer: [{bag, face, d}].
var hand_mods: Array = [] ## Mexidas do inimigo que valem na próxima mão.
## Perfeccionista: dados guardados no fim do turno, como marcas: [{bag, temp, value}].
var keeps: Array = []
var dodge_bonus: int = 0 ## Assassino (Ágil): dados a mais na próxima mão.
var thirst_used: int = 0 ## Vampiro: vida máxima já ganha nesta luta com a Sede.
## Dados trocados só nesta luta (Fundidor): [{bag, die}] com o dado original.
var restore: Array = []
var turn_mods: Array = [] ## Mexidas valendo neste turno.
## Campos opcionais de um dado da mão (docs/SPEC_v3.1.md §1 e §8): "mod" (mexida que o
## mudou), "spent" (mexida que o gastou), "orig" e "orig_top" (antes da mudança) e "cause"
## (id da magia, mexida do inimigo ou elemento que mudou o valor), "mod_hist" (mexidas
## do turno, em ordem, com o valor de antes) e "chain" (cadeia do Carbono na rolagem).
const HAND_EXTRA := ["mod", "spent", "orig", "orig_top", "cause", "mod_hist", "chain"]


func die_of(entry: Dictionary) -> Die:
	if int(entry.bag) >= 0:
		return bag[int(entry.bag)]
	return entry.temp


func hand_values() -> Array:
	var out := []
	for e in hand:
		out.append(int(e.value))
	return out


func heal(n: int) -> int:
	if n <= 0:
		return 0
	var before := hp
	hp = mini(max_hp, hp + n)
	return hp - before


func reset_fight_state() -> void:
	end_fight_cleanup()
	draw_pile = range(bag.size())
	discard = []
	hand = []
	last_hand = []
	block = 0
	mirror = false
	dodge = false
	poison = 0
	burn = 0
	sacrifice_bonus = 0
	once_used = []
	turns_taken = 0
	riposte = 0
	immune = 0
	recycle = false
	mirror_lvl = 1
	dodge_lvl = 1
	recycle_lvl = 1
	marked = {}
	extra_next = []
	benched = []
	hand_mods = []
	turn_mods = []
	keeps = []
	thirst_used = 0
	dodge_bonus = 0


## Desfaz o que vale só nesta luta (adesivos roubados pelo Plágio, Chumbo do Fundidor,
## cópia do Copista).
func end_fight_cleanup() -> void:
	for r in restore:
		var b := int(r.bag)
		if b >= 0 and b < bag.size():
			bag[b] = Die.from_dict(r.die)
	restore = []
	if inventory:
		inventory.drop_temp()
	for m in fight_mods:
		var b := int(m.bag)
		if b >= 0 and b < bag.size():
			var d: Die = bag[b]
			d.stickers[int(m.face)] = maxi(0, int(d.stickers[int(m.face)]) - int(m.d))
	fight_mods = []


## Quantas vezes a magia do item já foi usada nesta luta.
func uses_of(item: int) -> int:
	return once_used.count(item)


## Tira a mão da bolsa. O Ósmio sai em toda mão, antes dos outros (ocupa vaga).
## minus: dados a menos (Interrupção Rude, Rasteira), com mínimo de 2. A marca, os
## dados guardados e os recebidos entram além da mão normal.
func draw_hand(rng: RandomNumberGenerator, minus := 0, bonus := 0) -> void:
	hand = []
	var base := hand_size + maxi(0, bonus)
	var n := base if minus <= 0 else maxi(2, base - minus)
	for pile in [draw_pile, discard]:
		for i in pile.duplicate():
			if hand.size() < n and bag[i].element == "Os":
				pile.erase(i)
				hand.append(_entry(i))
	while hand.size() < n:
		var e := draw_one(rng)
		if e.is_empty():
			break
		hand.append(e)
	if not marked.is_empty():
		var m := marked
		marked = {}
		var e := _entry(int(m.bag))
		if int(m.bag) < 0:
			e.temp = Die.from_dict(m.temp)
		e.fixed = bool(m.fixed)
		e.value = int(m.value)
		e.plus = int(m.plus)
		hand.append(e)
	for x in extra_next:
		var e := _entry(-1)
		e.temp = Die.from_dict(x.temp)
		e.fixed = true
		e.value = int(x.value)
		hand.append(e)
	extra_next = []
	for k in keeps:
		var e := _entry(int(k.bag))
		if int(k.bag) < 0:
			e.temp = Die.from_dict(k.temp)
		e.fixed = true
		e.value = int(k.value)
		hand.append(e)
	keeps = []


## Tira um dado da bolsa (o descarte volta embaralhado se ela esvaziar). {} se não há.
func draw_one(rng: RandomNumberGenerator) -> Dictionary:
	if draw_pile.is_empty():
		if discard.is_empty():
			return {}
		draw_pile = discard
		discard = []
		_shuffle(draw_pile, rng)
	var k := rng.randi_range(0, draw_pile.size() - 1)
	return _entry(int(draw_pile.pop_at(k)))


func add_temp(d: Die) -> void:
	var e := _entry(-1)
	e.temp = d
	hand.append(e)


func _entry(i: int) -> Dictionary:
	return {"bag": i, "temp": null, "face": 0, "value": 0, "top": false, "fixed": false, "plus": 0, "spawn": -1}


## Tira um dado da bolsa até o fim da luta (Arrancar das Mãos).
func bench(i: int) -> void:
	draw_pile.erase(i)
	discard.erase(i)
	if not (i in benched):
		benched.append(i)


## Rola a mão. foe_last: últimos valores do adversário (Mercúrio). O Carbono soma a
## cadeia antes do Mercúrio copiar o maior valor. Metalurgista
## (Peso Morto): cada Chumbo que sai com 1 puxa mais um dado. Retorna quantos puxou.
func roll_hand(rng: RandomNumberGenerator, foe_last: Array) -> int:
	for e in hand:
		_roll_entry(e, rng)
	var pulled := 0
	if archetype == "metallurgist":
		var k := 0
		while k < hand.size():
			var e: Dictionary = hand[k]
			k += 1
			if e.get("fixed", false) or die_of(e) == null or die_of(e).element != "Pb" or int(e.value) != 1:
				continue
			var x := draw_one(rng)
			if x.is_empty():
				break
			_roll_entry(x, rng)
			hand.append(x)
			pulled += 1
	var chain := Elements.chain_bonus(self)
	if chain > 0:
		for e in hand:
			if die_of(e).element == "C" and not e.get("fixed", false):
				Resolver.mark_cause(e, "C")
				e.value = int(e.value) + chain
				e["chain"] = chain
	var top := 0
	for e in hand:
		if die_of(e).element != "Hg":
			top = maxi(top, int(e.value))
	for v in foe_last:
		top = maxi(top, int(v))
	for e in hand:
		if die_of(e).element == "Hg" and not e.get("fixed", false) and top > int(e.value):
			Resolver.mark_cause(e, "Hg")
			e.value = top
	return pulled


func _roll_entry(e: Dictionary, rng: RandomNumberGenerator) -> void:
	if e.get("fixed", false):
		e.top = false
		return
	var d := die_of(e)
	e.face = rng.randi_range(0, 5)
	var raw := d.value(e.face)
	e.top = raw == d.max_value()
	e.value = raw + int(e.get("plus", 0))
	e.erase("orig")
	e.erase("cause")
	e.erase("chain")
	if Elements.solitary(self, d):
		Resolver.mark_cause(e, "H")
		e.value *= Elements.solitary_mult


## Cura. Vampiro (Sede): toda cura também dá +1 de vida máxima, até THIRST_CAP por luta.
## Retorna {hp: vida recuperada, max: vida máxima ganha}.
func heal_full(n: int) -> Dictionary:
	var got := heal(n)
	var gain := 0
	if archetype == "vampire" and n > 0:
		gain = mini(1, Characters.THIRST_CAP - thirst_used)
		if gain > 0:
			thirst_used += gain
			max_hp += gain
			hp += gain
	return {"hp": got, "max": maxi(0, gain)}


## Remove um dado da bolsa para sempre (Sacrifício, Fornalha) e corrige os índices.
func destroy_bag_die(i: int) -> void:
	bag.remove_at(i)
	for arr in [draw_pile, discard]:
		arr.erase(i)
		for k in arr.size():
			if arr[k] > i:
				arr[k] -= 1
	for e in hand:
		if int(e.bag) == i:
			e.bag = -2 ## Destruído: some no descarte.
		elif int(e.bag) > i:
			e.bag = int(e.bag) - 1
	benched.erase(i)
	for k in benched.size():
		if benched[k] > i:
			benched[k] -= 1
	if not marked.is_empty() and int(marked.bag) >= 0:
		if int(marked.bag) == i:
			marked = {}
		elif int(marked.bag) > i:
			marked.bag = int(marked.bag) - 1
	keeps = keeps.filter(func(k): return int(k.bag) != i)
	for k in keeps:
		if int(k.bag) > i:
			k.bag = int(k.bag) - 1
	restore = restore.filter(func(r): return int(r.bag) != i)
	for r in restore:
		if int(r.bag) > i:
			r.bag = int(r.bag) - 1
	var keep := []
	for m in fight_mods:
		if int(m.bag) == i:
			continue
		if int(m.bag) > i:
			m.bag = int(m.bag) - 1
		keep.append(m)
	fight_mods = keep


func discard_hand() -> void:
	last_hand = hand_values()
	var held := []
	if not marked.is_empty():
		held.append(int(marked.bag))
	for k in keeps:
		held.append(int(k.bag))
	for e in hand:
		var b := int(e.bag)
		if b >= 0 and not (b in held) and not (b in benched) and not (b in discard):
			discard.append(b)
	hand = []


static func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp


func to_dict() -> Dictionary:
	var bag_d := []
	for d in bag:
		bag_d.append(d.to_dict())
	var hand_d := []
	for e in hand:
		var hd := {"bag": e.bag, "temp": e.temp.to_dict() if e.temp else {}, "face": e.face, "value": e.value,
			"top": e.get("top", false), "fixed": e.get("fixed", false), "plus": e.get("plus", 0), "spawn": e.get("spawn", -1)}
		for k in HAND_EXTRA:
			if e.has(k):
				hd[k] = e[k]
		hand_d.append(hd)
	return {
		"name": name, "is_player": is_player, "archetype": archetype, "variant": variant,
		"master_id": master_id, "personality": personality, "portrait": portrait, "max_hp": max_hp, "hp": hp,
		"hand_size": hand_size, "bag": bag_d, "inventory": inventory.to_dict(),
		"draw_pile": draw_pile, "discard": discard, "hand": hand_d, "last_hand": last_hand,
		"block": block, "mirror": mirror, "dodge": dodge, "poison": poison, "burn": burn,
		"sacrifice_bonus": sacrifice_bonus, "once_used": once_used, "turns_taken": turns_taken,
		"riposte": riposte, "immune": immune, "recycle": recycle, "marked": marked,
		"mirror_lvl": mirror_lvl, "dodge_lvl": dodge_lvl, "recycle_lvl": recycle_lvl,
		"extra_next": extra_next, "benched": benched, "fight_mods": fight_mods,
		"hand_mods": hand_mods, "turn_mods": turn_mods, "keeps": keeps, "thirst_used": thirst_used, "dodge_bonus": dodge_bonus,
		"restore": restore,
	}


## Estado dos status deste lado (o que os ícones mostram), sem a vida e a bolsa.
## O motor guarda uma cópia em cada evento ("st") para a interface mostrar cada ícone
## no momento em que a ação acontece.
func status_state() -> Dictionary:
	return {
		"block": block, "poison": poison, "burn": burn, "mirror": mirror, "dodge": dodge,
		"riposte": riposte, "immune": immune, "kept": (0 if marked.is_empty() else 1) + keeps.size(),
		"fury": Characters.fury(self), "archetype": archetype, "thirst_used": thirst_used,
		"hand_mods": hand_mods.duplicate(),
	}


static func from_dict(d: Dictionary) -> Fighter:
	var f := Fighter.new()
	f.name = str(d.get("name", ""))
	f.is_player = bool(d.get("is_player", false))
	f.archetype = str(d.get("archetype", "sorcerer"))
	f.variant = str(d.get("variant", ""))
	f.master_id = str(d.get("master_id", ""))
	f.personality = str(d.get("personality", ""))
	f.portrait = int(d.get("portrait", -1))
	f.max_hp = int(d.get("max_hp", 50))
	f.hp = int(d.get("hp", 50))
	f.hand_size = int(d.get("hand_size", Config.HAND_SIZE))
	for x in d.get("bag", []):
		f.bag.append(Die.from_dict(x))
	f.inventory = Inventory.from_dict(d.get("inventory", {}))
	f.draw_pile = Die._ints(d.get("draw_pile", []))
	f.discard = Die._ints(d.get("discard", []))
	for e in d.get("hand", []):
		var t: Dictionary = e.get("temp", {})
		f.hand.append({"bag": int(e.bag), "temp": Die.from_dict(t) if not t.is_empty() else null,
			"face": int(e.face), "value": int(e.value), "top": bool(e.get("top", false)),
			"fixed": bool(e.get("fixed", false)), "plus": int(e.get("plus", 0)), "spawn": int(e.get("spawn", -1))})
		var he: Dictionary = f.hand.back()
		for k in HAND_EXTRA:
			if e.has(k):
				if k == "mod_hist":
					he[k] = _hist(e[k])
				else:
					he[k] = bool(e[k]) if k == "orig_top" else (str(e[k]) if k == "cause" else int(e[k]))
	f.last_hand = Die._ints(d.get("last_hand", []))
	f.block = int(d.get("block", 0))
	f.mirror = bool(d.get("mirror", false))
	f.dodge = bool(d.get("dodge", false))
	f.poison = int(d.get("poison", 0))
	f.burn = int(d.get("burn", 0))
	f.sacrifice_bonus = int(d.get("sacrifice_bonus", 0))
	f.once_used = Die._ints(d.get("once_used", []))
	f.turns_taken = int(d.get("turns_taken", 0))
	f.riposte = int(d.get("riposte", 0))
	f.immune = int(d.get("immune", 0))
	f.recycle = bool(d.get("recycle", false))
	f.mirror_lvl = int(d.get("mirror_lvl", 1))
	f.dodge_lvl = int(d.get("dodge_lvl", 1))
	f.recycle_lvl = int(d.get("recycle_lvl", 1))
	var mk: Dictionary = d.get("marked", {})
	if not mk.is_empty():
		f.marked = {"bag": int(mk.bag), "temp": mk.get("temp", {}), "value": int(mk.value),
			"fixed": bool(mk.fixed), "plus": int(mk.get("plus", 0))}
	for x in d.get("extra_next", []):
		f.extra_next.append({"temp": x.get("temp", {}), "value": int(x.value)})
	f.benched = Die._ints(d.get("benched", []))
	for m in d.get("fight_mods", []):
		f.fight_mods.append({"bag": int(m.bag), "face": int(m.face), "d": int(m.d)})
	for m in d.get("hand_mods", []):
		f.hand_mods.append(str(m))
	for m in d.get("turn_mods", []):
		f.turn_mods.append(str(m))
	for k in d.get("keeps", []):
		f.keeps.append({"bag": int(k.bag), "temp": k.get("temp", {}), "value": int(k.value)})
	f.thirst_used = int(d.get("thirst_used", 0))
	f.dodge_bonus = int(d.get("dodge_bonus", 0))
	for r in d.get("restore", []):
		f.restore.append({"bag": int(r.bag), "die": r.die})
	return f


static func _hist(a: Variant) -> Array:
	var out := []
	if a is Array:
		for r in a:
			if r is Dictionary:
				out.append({"item": int(r.get("item", -1)), "seq": int(r.get("seq", 0)), "value": int(r.get("value", 0)),
					"top": bool(r.get("top", false)), "face": int(r.get("face", 0))})
	return out
