class_name FeltTable
extends SubViewportContainer
## Fundo da luta: a mesa de feltro rubro (como o da roleta), um plano 3D que cobre a tela
## inteira, com a mesma câmera ortográfica inclinada e as mesmas luzes dos dados
## (DiceRoll3D.stage). A rolagem 3D (DiceRoll3D) põe os dados neste mesmo mundo: as
## sombras deles caem de verdade no feltro e os que brilham acendem o pano em volta.
##
## Custo: parada, a mesa é desenhada uma vez só (UPDATE_ONCE) e não gasta nada por
## quadro; só durante a rolagem ela é redesenhada a cada quadro (live).

const FELT_LAYER := 2 ## Camada do feltro: a câmera da rolagem (por cima da interface) não o vê.
const SIZE := 400.0 ## Lado do plano, em arestas de dado (sobra para qualquer tela).
const SHADER := """
shader_type spatial;
// Feltro: fosco, ruído fino de fibra, sem padrão. Luz direcional = Lambert (com a sombra
// em ATTENUATION); luz pontual (dado que brilha) também deixa um brilho que não depende
// da cor do pano, senão o verde do Urânio sumiria no vermelho.
uniform vec3 base : source_color = vec3(0.16, 0.024, 0.03);
uniform float grain = 0.16;
uniform float sheen = 0.55;
uniform vec2 pool = vec2(-0.4, -0.5);
uniform float pool_r = 9.0;
varying vec3 wpos;

float hash(vec2 p) {
	vec3 q = fract(vec3(p.xyx) * 0.1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wpos.xz;
	// Fibras: grão fino em duas direções cruzadas, mais umas manchas largas e suaves.
	float fine = hash(floor(p * 64.0)) * 0.5 + hash(floor(p * vec2(23.0, 96.0) + 7.0)) * 0.25 + hash(floor(p * vec2(96.0, 23.0) + 3.0)) * 0.25;
	float mid = vnoise(p * 9.0);
	float big = vnoise(p * 0.55) * 0.6 + vnoise(p * 1.7) * 0.4;
	float n = (fine - 0.5) * grain + (mid - 0.5) * grain * 0.6 + (big - 0.5) * 0.12;
	// Poça da luz principal (do alto, à esquerda): o pano escurece devagar longe dela.
	float d = length(p - pool) / pool_r;
	float lamp = mix(1.04, 0.72, smoothstep(0.15, 1.1, d));
	ALBEDO = base * (1.0 + n) * lamp;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	SPECULAR = 0.0;
}

void light() {
	float ndl = max(dot(NORMAL, LIGHT), 0.0);
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * ndl;
	if (!LIGHT_IS_DIRECTIONAL) {
		SPECULAR_LIGHT += LIGHT_COLOR * ATTENUATION * ndl * sheen;
	}
}
"""

var vp: SubViewport
var world: Node3D
var cam: Camera3D
var felt: MeshInstance3D
var _live := 0
static var _shader: Shader


func setup() -> FeltTable:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	vp = SubViewport.new()
	vp.own_world_3d = false
	vp.world_3d = World3D.new()
	vp.msaa_3d = Viewport.MSAA_DISABLED ## Só o pano e as sombras (os dados de verdade vão por cima).
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(vp)
	world = Node3D.new()
	vp.add_child(world)
	cam = Camera3D.new()
	world.add_child(cam)
	DiceRoll3D.stage(world, cam, DiceRoll3D.VIEW, true, true)
	felt = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(SIZE, SIZE)
	felt.mesh = pm
	felt.layers = FELT_LAYER
	felt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := ShaderMaterial.new()
	m.shader = shader()
	felt.material_override = m
	world.add_child(felt)
	resized.connect(redraw)
	return self


static func shader() -> Shader:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	return _shader


## Enquadra a câmera para o retângulo stage (coordenadas deste controle) mostrar a mesma
## mesa que a rolagem mostra (DiceRoll3D.VIEW arestas de altura, centro na origem).
func frame(stage: Rect2) -> void:
	if stage.size.y < 1.0 or size.y < 1.0:
		return
	var k := DiceRoll3D.VIEW / stage.size.y ## Arestas por pixel.
	cam.size = size.y * k
	var d := (size * 0.5 - stage.get_center()) * k
	cam.h_offset = d.x
	cam.v_offset = -d.y
	redraw()


## Desenha de novo uma vez (a mesa parada não gasta nada por quadro).
func redraw() -> void:
	if vp != null and _live == 0:
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE


## Dados rolando em cima: redesenha a cada quadro até end_live.
func begin_live() -> void:
	_live += 1
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS


func end_live() -> void:
	_live = maxi(0, _live - 1)
	redraw()


func live() -> bool:
	return _live > 0
