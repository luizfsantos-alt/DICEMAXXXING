class_name ScreenShake
extends Node
## Tremida da tela no impacto de um golpe. Quanto maior o dano em relação à vida máxima
## do alvo, mais forte e mais longa: abaixo de 10% não treme (só a foto); a partir de
## 100% é quase uma explosão (a tela também pisca e gira um pouco).
## Move os controles de "targets" (o fundo fica parado, então nada vaza pelas bordas)
## e devolve tudo à posição original no fim.

## Faixas: [fração mínima da vida máxima, amplitude (px), duração (s), giro máximo (graus)].
const TIERS := [
	[0.10, 4.0, 0.18, 0.0],
	[0.25, 8.0, 0.26, 0.0],
	[0.50, 14.0, 0.36, 0.4],
	[0.80, 22.0, 0.48, 0.8],
	[1.00, 34.0, 0.70, 1.5],
]
const FREQ := 32.0 ## Trocas de direção por segundo (mais lento que um quadro: não vira chiado).

var targets: Array = [] ## Controles que tremem juntos.
var level := 0 ## Faixa em andamento (0 = parada).
var _amp := 0.0
var _rot := 0.0
var _time := 0.0
var _left := 0.0
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _step := 0.0
var _base := {} ## Control -> posição original.


## Faixa da tremida (0 a 5) para "dmg" de dano num alvo de vida máxima "max_hp".
static func tier(dmg: int, max_hp: int) -> int:
	if dmg <= 0 or max_hp <= 0:
		return 0
	var frac := float(dmg) / float(max_hp)
	var t := 0
	for k in TIERS.size():
		if frac >= TIERS[k][0] - 0.0001:
			t = k + 1
	return t


func setup(nodes: Array) -> ScreenShake:
	targets = nodes
	set_process(false)
	return self


## Começa uma tremida da faixa "t". Se já houver uma mais forte em andamento, ela segue.
func start(t: int) -> void:
	if t <= 0:
		return
	t = mini(t, TIERS.size())
	if level > t and _left > 0.0:
		return
	var row: Array = TIERS[t - 1]
	level = t
	_amp = row[1]
	_time = row[2]
	_left = _time
	_rot = deg_to_rad(row[3])
	_step = 0.0
	_from = Vector2.ZERO
	_to = _random_dir()
	for c in targets:
		if is_instance_valid(c) and not _base.has(c):
			_base[c] = c.position
	set_process(true)


func _process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		stop()
		return
	_step += delta * FREQ
	while _step >= 1.0:
		_step -= 1.0
		_from = _to
		_to = _random_dir()
	var k := _left / _time
	k *= k ## Começa forte e assenta depressa.
	var off := _from.lerp(_to, _step) * _amp * k
	var ang := sin(_left * 47.0) * _rot * k
	for c in targets:
		if is_instance_valid(c) and _base.has(c):
			c.position = _base[c] + off
			if _rot > 0.0:
				c.pivot_offset = c.size * 0.5
				c.rotation = ang


func stop() -> void:
	for c in _base:
		if is_instance_valid(c):
			c.position = _base[c]
			c.rotation = 0.0
	_base.clear()
	_left = 0.0
	level = 0
	set_process(false)


## Direção nova, sempre para o "outro lado" o bastante para sentir o tranco.
func _random_dir() -> Vector2:
	var a := randf() * TAU
	var d := Vector2(cos(a), sin(a)) * randf_range(0.6, 1.0)
	if d.dot(_to) > 0.0:
		d = -d
	return d
