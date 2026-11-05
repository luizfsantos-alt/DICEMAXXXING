class_name DicePhysics
extends RefCounted
## Física própria e simples para rolar dados 3D (sem motor de física): cubos de lado 1
## numa caixa (chão y = 0 e quatro paredes), com quique, atrito e choque entre dados.
##
## A rolagem é simulada inteira antes de aparecer na tela e gravada quadro a quadro.
## No fim, cada dado assenta numa face; a interface escreve o valor sorteado nessa face
## (e os outros valores do dado nas demais) e só então toca a gravação. Assim o dado
## rola de verdade e para exatamente no número que o motor de regras decidiu.

const H := 0.5 ## Meia aresta.
const DT := 1.0 / 120.0
const GRAVITY := Vector3(0, -30, 0)
const RESTITUTION := 0.35
const FRICTION := 0.45
const INV_MASS := 1.0
const INV_INERTIA := 6.0 ## Cubo maciço de massa 1 e aresta 1: I = 1/6.
const DIE_RADIUS := 0.6 ## Choque entre dados como esferas.
const MAX_STEPS := 600 ## 5 s simulados no máximo.
const REST_STEPS := 24

## Normais locais das seis faces, na ordem usada para os rótulos.
const FACE_NORMALS := [Vector3.UP, Vector3.DOWN, Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]

var half := Vector2(4, 3) ## Meia largura (x) e meia profundidade (z) da caixa.
var bodies: Array = [] ## {p, v, q, w, fixed}
var frames: Array = [] ## Por passo gravado: Array de [Vector3, Quaternion] por dado.
var record_every := 2 ## Grava a 60 quadros por segundo.

var _corners: Array = []


func _init() -> void:
	for x in [-H, H]:
		for y in [-H, H]:
			for z in [-H, H]:
				_corners.append(Vector3(x, y, z))


## Dado parado (já marcado, não rola).
func add_still(p: Vector3, q := Quaternion.IDENTITY) -> void:
	bodies.append({"p": p, "v": Vector3.ZERO, "q": q, "w": Vector3.ZERO, "fixed": true})


func add_thrown(p: Vector3, v: Vector3, q: Quaternion, w: Vector3) -> void:
	bodies.append({"p": p, "v": v, "q": q.normalized(), "w": w, "fixed": false})


## Simula até todos pararem (ou MAX_STEPS). Depois alinha cada dado à face de cima.
func run() -> void:
	frames = [_snapshot()]
	var calm := 0
	for step in MAX_STEPS:
		_step()
		if step % record_every == record_every - 1:
			frames.append(_snapshot())
		calm = calm + 1 if _all_resting() else 0
		if calm >= REST_STEPS:
			break
	_settle_flat()


## Índice (em FACE_NORMALS) da face local que ficou para cima no dado i.
func up_face(i: int) -> int:
	var q: Quaternion = bodies[i].q
	var best := 0
	var best_y := -2.0
	for k in FACE_NORMALS.size():
		var y: float = (q * FACE_NORMALS[k]).y
		if y > best_y:
			best_y = y
			best = k
	return best


func _snapshot() -> Array:
	var out := []
	for b in bodies:
		out.append([b.p, b.q])
	return out


func _all_resting() -> bool:
	for b in bodies:
		if b.fixed:
			continue
		if b.v.length() > 0.08 or b.w.length() > 0.25 or b.p.y > H + 0.05:
			return false
	return true


func _step() -> void:
	for b in bodies:
		if b.fixed:
			continue
		b.v += GRAVITY * DT
		b.p += b.v * DT
		var wl: float = b.w.length()
		if wl > 0.0001:
			b.q = (Quaternion(b.w / wl, wl * DT) * b.q).normalized()
	for _it in 3:
		for b in bodies:
			if not b.fixed:
				_collide_box(b)
	_collide_dice()
	for b in bodies:
		if b.fixed:
			continue
		# Amortecimento leve; no chão, rolamento perde força mais rápido.
		var grounded: bool = b.p.y < H * 1.75
		b.v *= 0.998 if not grounded else 0.99
		b.w *= 0.995 if not grounded else 0.975


## Planos: chão e paredes. Cada canto que atravessa leva um impulso.
func _collide_box(b: Dictionary) -> void:
	var planes := [
		[Vector3.UP, 0.0],
		[Vector3.LEFT, -half.x], [Vector3.RIGHT, -half.x],
		[Vector3.FORWARD, -half.y], [Vector3.BACK, -half.y],
	]
	for pl in planes:
		var n: Vector3 = pl[0]
		var d0: float = pl[1]
		var deepest := 0.0
		for c in _corners:
			var r: Vector3 = b.q * c
			var pen: float = (b.p + r).dot(n) - d0
			if pen >= 0.0:
				continue
			deepest = minf(deepest, pen)
			_impulse(b, r, n)
		if deepest < 0.0:
			b.p -= n * deepest * 0.8


func _impulse(b: Dictionary, r: Vector3, n: Vector3) -> void:
	var vp: Vector3 = b.v + b.w.cross(r)
	var vn := vp.dot(n)
	if vn >= 0.0:
		return
	var rn := r.cross(n)
	var k := INV_MASS + INV_INERTIA * rn.dot(rn)
	var e := RESTITUTION if vn < -2.0 else 0.0
	var j := -(1.0 + e) * vn / k
	b.v += n * j * INV_MASS
	b.w += INV_INERTIA * r.cross(n * j)
	# Atrito de Coulomb na direção do escorregão.
	vp = b.v + b.w.cross(r)
	var vt := vp - n * vp.dot(n)
	var vtl := vt.length()
	if vtl < 1e-5:
		return
	var t := vt / vtl
	var rt := r.cross(t)
	var kt := INV_MASS + INV_INERTIA * rt.dot(rt)
	var jt := minf(vtl / kt, FRICTION * j)
	b.v -= t * jt * INV_MASS
	b.w -= INV_INERTIA * r.cross(t * jt)


func _collide_dice() -> void:
	var lim := DIE_RADIUS * 2.0
	for i in bodies.size():
		for k in range(i + 1, bodies.size()):
			var a: Dictionary = bodies[i]
			var b: Dictionary = bodies[k]
			var d: Vector3 = b.p - a.p
			var dist := d.length()
			if dist >= lim or dist < 1e-5:
				continue
			var n := d / dist
			var ia := 0.0 if a.fixed else INV_MASS
			var ib := 0.0 if b.fixed else INV_MASS
			if ia + ib == 0.0:
				continue
			var over := lim - dist
			a.p -= n * over * ia / (ia + ib)
			b.p += n * over * ib / (ia + ib)
			var rel: float = (b.v - a.v).dot(n)
			if rel < 0.0:
				var j := -(1.0 + 0.3) * rel / (ia + ib)
				a.v -= n * j * ia
				b.v += n * j * ib
				# Um pouco de giro no choque, para não deslizarem como discos.
				a.w += n.cross(Vector3.UP) * j * 0.6 * ia
				b.w -= n.cross(Vector3.UP) * j * 0.6 * ib


## Fim da rolagem: gira cada dado até a face de cima ficar exatamente plana e o encosta
## no chão, misturando nos últimos quadros (sem salto visível).
func _settle_flat() -> void:
	var blend := mini(12, frames.size() - 1)
	for i in bodies.size():
		var b: Dictionary = bodies[i]
		var up: Vector3 = FACE_NORMALS[up_face(i)]
		var world_up: Vector3 = b.q * up
		var fix := Quaternion(world_up.normalized(), Vector3.UP)
		var q_end: Quaternion = (fix * b.q).normalized()
		var p_end := Vector3(b.p.x, H, b.p.z)
		for f in range(1, blend + 1):
			var idx := frames.size() - 1 - blend + f
			var t := float(f) / blend
			var q_rec: Quaternion = frames[idx][i][1]
			var p_rec: Vector3 = frames[idx][i][0]
			frames[idx][i] = [p_rec.lerp(p_end, t), q_rec.slerp(q_end, t)]
		if blend == 0:
			frames[frames.size() - 1][i] = [p_end, q_end]
		b.q = q_end
		b.p = p_end
