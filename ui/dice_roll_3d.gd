class_name DiceRoll3D
extends SubViewportContainer
## Rolagem 3D por cima do palco: os dados entram pela direita (do lado da coluna de
## dados), quicam, batem uns nos outros e param no valor sorteado (DicePhysics).
## Fundo transparente; não pega toques (o "tocar acelera" da tela de duelo continua).
##
## dice: Array de {value, element, faces (6 valores), face (índice que saiu), fixed,
## heat (estado do brilho, 0 a 1; opcional), stickers e gold (adesivos por face, 6
## valores; opcionais)}.
##
## Visual (docs/DADOS_VISUAL.md): os metais refletem um ambiente quente com a lâmpada
## da mesa (céu só de reflexo, o fundo continua transparente).
##
## Com a mesa de feltro (FeltTable, o fundo da luta), os dados vivem no mundo dela: a
## mesa os vê e recebe as sombras de verdade e a luz dos que brilham (uma OmniLight3D
## fraca por dado aceso); esta vista, por cima da interface, mostra só os dados. Sem a
## mesa (capturas, testes), a rolagem tem mundo próprio, sombra e halo desenhados.

signal done

const VIEW := 8.5 ## Altura visível do chão, em arestas de dado.
const TILT := 22.0 ## Inclinação da câmera (graus a partir da vertical).
const HOLD := 0.45 ## Tempo parado mostrando o resultado.

const FPS := 60.0 ## Quadros gravados por segundo (DicePhysics grava a cada 2 passos).

var skip := false ## Pular para o fim.
var skip_check: Callable ## Consultado a cada quadro: true pula para o fim (toque na tela).
var _frames: Array = []
var _t := 0.0
var _hold := 0.0
var vp: SubViewport
var world: Node3D
var _dice: Array = [] ## MeshInstance3D
var _shadows: Array = [] ## MeshInstance3D
var _halos: Array = [] ## MeshInstance3D ou null (dado sem brilho)
var _glow: Array = [] ## Por dado: {el, heat, mats (6 materiais)}
var _clock := 0.0
var _frames_started := false ## Pediu à mesa para redesenhar a cada quadro.
var _cam: Camera3D
var _sim: DicePhysics
var table: FeltTable ## Mesa de feltro compartilhada (ou null: mundo próprio).
var _lamps: Array = [] ## OmniLight3D ou null, por dado (com a mesa).

const LAMP_RANGE := 2.6 ## Alcance da luz de um dado aceso no feltro, em arestas.
const LAMP_ENERGY := 1.3


func setup(px: Vector2, felt: FeltTable = null) -> DiceRoll3D:
	set_process(false)
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = px
	table = felt
	vp = SubViewport.new()
	vp.transparent_bg = true
	if table != null:
		vp.own_world_3d = false
		vp.world_3d = table.vp.world_3d
	else:
		vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.size = Vector2i(px)
	add_child(vp)
	world = Node3D.new()
	vp.add_child(world)
	_cam = Camera3D.new()
	world.add_child(_cam)
	# Com a mesa, as luzes já estão no mundo dela, e esta câmera não vê o feltro.
	stage(world, _cam, VIEW, table == null)
	if table != null:
		_cam.cull_mask &= ~FeltTable.FELT_LAYER
	return self


func _exit_tree() -> void:
	if table != null and _frames_started:
		_frames_started = false
		table.end_live()


## Câmera, ambiente e luzes da mesa. Os dados da coluna (DieSnapshot) usam a mesma
## montagem, para o dado ter a mesma cara na mesa e na coluna.
## lights: pôr as luzes (a mesa compartilhada já as tem); shadows: a luz principal faz
## sombra (só a mesa, que tem o chão de feltro).
static func stage(world: Node3D, cam: Camera3D, view: float, lights := true, shadows := false) -> void:
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = view
	# Profundidade justa (a câmera fica a 30 da mesa): a sombra do feltro usa esse
	# intervalo para caber no mapa de sombra com boa resolução.
	cam.near = 20.0
	cam.far = 40.0
	var t := deg_to_rad(TILT)
	cam.environment = environment()
	cam.look_at_from_position(Vector3(0, 30 * cos(t), 30 * sin(t)), Vector3.ZERO, Vector3.FORWARD)
	if lights:
		add_lights(world, shadows)


static func environment() -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.82, 0.95)
	env.ambient_light_energy = 0.6
	# Céu só para reflexo: sem ele os metais (Mercúrio, Ósmio, Ouro) não têm o que
	# refletir. Uma sala quente e escura, o feltro rubro embaixo e a lâmpada da mesa
	# (um ponto forte na direção da luz principal).
	env.sky = Sky.new()
	env.sky.sky_material = reflection_sky()
	env.sky.radiance_size = Sky.RADIANCE_SIZE_64
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	return env


static var _sky: ShaderMaterial

const SKY_SHADER := """
shader_type sky;
uniform vec3 lamp_dir = vec3(-0.35, 0.86, -0.26);
uniform vec3 side_dir = vec3(-0.93, 0.33, 0.14);

void sky() {
	vec3 d = EYEDIR;
	vec3 top = vec3(0.30, 0.25, 0.21);
	vec3 horizon = vec3(0.62, 0.50, 0.38);
	vec3 felt = vec3(0.42, 0.05, 0.06);
	vec3 c = d.y > 0.0 ? mix(horizon, top, sqrt(d.y)) : mix(horizon * 0.7, felt, sqrt(-d.y));
	float s = max(dot(d, normalize(lamp_dir)), 0.0);
	float w = max(dot(d, normalize(side_dir)), 0.0);
	c += vec3(5.0, 4.5, 3.8) * pow(s, 90.0) + vec3(0.7, 0.6, 0.48) * pow(s, 6.0);
	c += vec3(1.6, 1.45, 1.25) * pow(w, 40.0);
	COLOR = c;
}
"""


## Céu do reflexo (um só material para a mesa, a rolagem e as fotos da coluna).
static func reflection_sky() -> ShaderMaterial:
	if _sky == null:
		var sh := Shader.new()
		sh.code = SKY_SHADER
		_sky = ShaderMaterial.new()
		_sky.shader = sh
	return _sky


## Luz principal do alto à esquerda (a mesma das faces 2D), uma luz suave de cima, uma
## lateral baixa vinda da esquerda (desenha as arestas e o brilho dos metais) e um
## preenchimento fraco do outro lado. shadows: só a principal faz sombra no feltro (um
## mapa de sombra só, para pesar pouco no celular).
static func add_lights(world: Node3D, shadows := false) -> void:
	for l in [
		[Vector3(-4, 10, -3), 1.1],
		[Vector3(0.6, 10, 1.5), 0.35],
		[Vector3(-10, 3.5, 1.5), 0.55],
		[Vector3(5, 4, 6), 0.25],
	]:
		var d := DirectionalLight3D.new()
		d.light_energy = l[1]
		if shadows and float(l[1]) > 1.0:
			d.shadow_enabled = true
			d.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
			d.directional_shadow_max_distance = 40.0
			d.shadow_blur = 2.0
			d.shadow_opacity = 0.9
		world.add_child(d)
		d.look_at_from_position(l[0], Vector3.ZERO, Vector3.UP)


## Meia largura e meia profundidade da caixa invisível (as bordas da área).
func arena() -> Vector2:
	var aspect := size.x / maxf(1.0, size.y)
	var depth := VIEW / cos(deg_to_rad(TILT))
	return Vector2(VIEW * aspect * 0.5 - 0.65, depth * 0.5 - 1.0)


## Simula e toca a rolagem. Retorna quando os dados param (e somem).
func roll(dice: Array, rng: RandomNumberGenerator = null) -> void:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var sim := plan(dice, arena(), rng)
	_sim = sim
	_build_nodes(dice, sim)
	if table != null and not _frames_started:
		_frames_started = true
		table.begin_live()
	await _play(sim)


## Física e rótulos (sem nós; testável). Devolve o DicePhysics já rodado.
static func plan(dice: Array, half: Vector2, rng: RandomNumberGenerator) -> DicePhysics:
	var sim := DicePhysics.new()
	sim.half = half
	var n := dice.size()
	var still := 0
	for i in n:
		var d: Dictionary = dice[i]
		var lane := lerpf(-half.y + 0.7, half.y - 0.7, (i + 0.5) / maxf(1.0, n))
		if bool(d.get("fixed", false)):
			# Dado marcado: já está parado, no canto esquerdo.
			sim.add_still(Vector3(-half.x + 0.7 + (still / 4) * 1.3, DicePhysics.H, -half.y + 0.7 + (still % 4) * 1.3))
			still += 1
			continue
		var p := Vector3(half.x - 0.7 - (i % 2) * 1.3, 1.6 + rng.randf() * 1.2, lane)
		var v := Vector3(-rng.randf_range(9.0, 13.0), rng.randf_range(1.0, 4.0), rng.randf_range(-2.5, 2.5))
		var axis := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1))
		if axis.length() < 0.1:
			axis = Vector3.FORWARD
		var q := Quaternion(axis.normalized(), rng.randf_range(0, TAU))
		var w := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.4, 0.4), rng.randf_range(-1, 1)).normalized() * rng.randf_range(14.0, 24.0)
		sim.add_thrown(p, v, q, w)
	sim.run()
	return sim


## Valores de cada face local do dado i, com o sorteado na face que ficou para cima.
static func face_labels(sim: DicePhysics, i: int, d: Dictionary) -> Array:
	return Dice3D.labels(sim.up_face(i), int(d.value), d.get("faces", []), int(d.get("face", 0)))


func _build_nodes(dice: Array, sim: DicePhysics) -> void:
	for c in _dice + _shadows + _halos + _lamps:
		if c != null:
			c.queue_free()
	_dice = []
	_shadows = []
	_halos = []
	_lamps = []
	_glow = []
	var shadow_mesh := QuadMesh.new()
	shadow_mesh.size = Vector2(1.5, 1.5)
	shadow_mesh.orientation = PlaneMesh.FACE_Y
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var g := GradientTexture2D.new()
	g.fill = GradientTexture2D.FILL_RADIAL
	g.fill_from = Vector2(0.5, 0.5)
	g.fill_to = Vector2(1.0, 0.5)
	var grad := Gradient.new()
	grad.set_color(0, Color(0, 0, 0, 0.5))
	grad.set_color(1, Color(0, 0, 0, 0))
	g.gradient = grad
	sm.albedo_texture = g
	shadow_mesh.material = sm
	for i in dice.size():
		var d: Dictionary = dice[i]
		var el := str(d.get("element", ""))
		var mi := MeshInstance3D.new()
		mi.mesh = Dice3D.mesh()
		var labels := face_labels(sim, i, d)
		var heat := float(d.get("heat", 0.0))
		var mats := []
		for k in 6:
			var m := Dice3D.material(int(labels[k]), el, heat)
			mi.set_surface_override_material(k, m)
			mats.append(m)
		_glow.append({"el": el, "heat": heat, "mats": mats})
		# Adesivos: selos colados nas faces que têm (cada face local leva a face do dado).
		var stk: Array = d.get("stickers", [])
		var gld: Array = d.get("gold", [])
		if not stk.is_empty() or not gld.is_empty():
			var slots := Dice3D.face_slots(sim.up_face(i), int(d.get("face", 0)))
			for k in 6:
				var fi := int(slots[k])
				var mk := Dice3D.marks_node(k, int(_at(stk, fi)), int(_at(gld, fi)))
				if mk != null:
					mi.add_child(mk)
		var lk := Elements.look(el)
		var halo: MeshInstance3D = null
		var lamp: OmniLight3D = null
		if str(lk.glow) != "" and table != null:
			# Luz de verdade no feltro (e nos vizinhos); fica no centro do dado, que não
			# se ilumina por dentro.
			lamp = OmniLight3D.new()
			lamp.light_color = lk.emission
			lamp.omni_range = LAMP_RANGE
			lamp.omni_attenuation = 1.6
			lamp.light_energy = 0.0
			lamp.light_specular = 0.0
			world.add_child(lamp)
		elif str(lk.glow) != "":
			halo = MeshInstance3D.new()
			halo.mesh = _halo_mesh(lk.emission)
			world.add_child(halo)
		_halos.append(halo)
		_lamps.append(lamp)
		world.add_child(mi)
		_dice.append(mi)
		var sh: MeshInstance3D = null
		if table == null:
			# Sem a mesa não há chão: a sombra é um disco desenhado.
			sh = MeshInstance3D.new()
			sh.mesh = shadow_mesh
			world.add_child(sh)
		_shadows.append(sh)


static func _at(a: Array, k: int) -> int:
	return int(a[k]) if k < a.size() else 0


## Luz que o dado aceso joga na mesa: um disco colorido que some para as bordas.
static func _halo_mesh(col: Color) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(2.8, 2.8)
	q.orientation = PlaneMesh.FACE_Y
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var g := GradientTexture2D.new()
	g.fill = GradientTexture2D.FILL_RADIAL
	g.fill_from = Vector2(0.5, 0.5)
	g.fill_to = Vector2(1.0, 0.5)
	var grad := Gradient.new()
	grad.set_color(0, Color(col, 0.75))
	grad.set_color(1, Color(col, 0.0))
	g.gradient = grad
	m.albedo_texture = g
	q.material = m
	return q


## Pulso do brilho: lento em repouso; o Urânio ativo pisca como um contador Geiger.
static func glow_pulse(el: String, heat: float, t: float) -> float:
	if el == "U" and heat > 0.5:
		var k := int(t * 9.0) % 11
		return 1.5 if k in [1, 5, 8] else 1.0
	return 1.0 + 0.15 * sin(t * TAU / 2.6)


func _update_glow() -> void:
	for i in _glow.size():
		var g: Dictionary = _glow[i]
		var base := Elements.energy(str(g.el), float(g.heat))
		if base <= 0.0:
			continue
		var p := glow_pulse(str(g.el), float(g.heat), _clock)
		for m: StandardMaterial3D in g.mats:
			m.emission_energy_multiplier = base * p
		if _lamps[i] != null:
			_lamps[i].light_energy = LAMP_ENERGY * clampf(base, 0.3, 1.2) * p
		if _halos[i] != null:
			var a := clampf(base, 0.25, 1.0) * p
			var hm: StandardMaterial3D = (_halos[i].mesh as QuadMesh).material
			hm.albedo_color = Color(1, 1, 1, clampf(a, 0.0, 1.0))


## Onde cada dado parou, na tela (coordenadas deste controle): centro, largura da aresta
## em pixels e o ângulo da face de cima (para o dado voar até a coluna sem pular).
func dice_on_screen() -> Array:
	var out := []
	if _cam == null or _sim == null:
		return out
	for i in _dice.size():
		var mi: MeshInstance3D = _dice[i]
		var p := mi.position
		var c := _cam.unproject_position(p)
		var w := _cam.unproject_position(p + Vector3.RIGHT * 0.5).distance_to(_cam.unproject_position(p - Vector3.RIGHT * 0.5))
		var n: Vector3 = DicePhysics.FACE_NORMALS[_sim.up_face(i)]
		var u := mi.transform.basis * Dice3D._face_u(n)
		var a := _cam.unproject_position(p + u * 0.5) - c
		out.append({"center": c, "width": w, "angle": atan2(a.y, a.x)})
	return out


## Esconde os dados (e sombras e halos): quem segue é a cópia que voa até a coluna.
func hide_dice() -> void:
	for c in _dice + _shadows + _halos + _lamps:
		if c != null:
			c.visible = false


func _show_frame(fr: Array) -> void:
	for i in _dice.size():
		var p: Vector3 = fr[i][0]
		var q: Quaternion = fr[i][1]
		_dice[i].transform = Transform3D(Basis(q), p)
		var hgt := maxf(0.0, p.y - DicePhysics.H)
		if _shadows[i] != null:
			_shadows[i].position = Vector3(p.x + hgt * 0.25, 0.01, p.z + hgt * 0.2)
			var s := 1.0 + hgt * 0.25
			_shadows[i].scale = Vector3(s, 1, s)
		if _lamps[i] != null:
			_lamps[i].position = p
		if _halos[i] != null:
			# Mais alto, luz mais espalhada e mais fraca na mesa.
			_halos[i].position = Vector3(p.x, 0.005, p.z)
			var hs := 1.0 + hgt * 0.4
			_halos[i].scale = Vector3(hs, 1, hs)


func _play(sim: DicePhysics) -> void:
	_frames = sim.frames
	_t = 0.0
	_hold = HOLD
	_show_frame(_frames[0])
	set_process(true)
	await done


## Toca a gravação quadro a quadro e segura o resultado; depois emite done.
func _process(delta: float) -> void:
	if _frames.is_empty():
		set_process(false)
		return
	if skip_check.is_valid() and skip_check.call():
		skip = true
	var last := _frames.size() - 1
	var k := last if skip else mini(int(_t * FPS), last)
	_show_frame(_frames[k])
	_clock += delta
	_update_glow()
	_t += delta
	if k < last:
		return
	_hold -= delta
	if _hold <= 0.0 or skip:
		_frames = []
		set_process(false)
		done.emit()
