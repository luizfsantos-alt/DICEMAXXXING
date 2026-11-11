class_name FeltPaint
## Tinta e perspectiva do que é pintado no feltro da luta (as magias: SpellCard e os
## buracos delas).
##
## Perspectiva: o palco das magias é a mesa vista de frente. Uma homografia leva o
## retângulo do palco a um trapézio: a borda de baixo fica igual, a de cima encolhe
## KEYSTONE da largura para o centro, e as fileiras de cima ficam um pouco mais baixas
## (a parte longe da mesa encolhe também na altura). Tudo dentro do palco (contornos,
## textos, ícones, buracos e o dado posto) é desenhado deformado por um shader de
## vértice; os controles continuam no lugar de sempre. Por isso:
## - entrada: SpellCard e Hole respondem ao toque pela área deformada (_has_point usa
##   unwarp, a homografia inversa);
## - saída: quem precisa do ponto na tela de um cartão ou buraco (efeitos, dados
##   voando) usa warp, a homografia direta (DuelScreen._on_screen).
##
## Com u = x − centro e v = (y − topo) / altura (0 em cima, 1 embaixo):
##   d = 1 + m·(1 − v);  u' = u / d;  v' = v / d;  m = KEYSTONE / (1 − KEYSTONE).

const KEYSTONE := 0.11 ## Quanto a borda de cima do palco encolhe (fração da largura).

## Vértice: leva cada ponto (no espaço da tela, MODEL_MATRIX) pela homografia.
const WARP_CODE := """
uniform vec4 table = vec4(0.0);
uniform float persp = 0.0;

vec2 warp(vec2 g) {
	if (table.z <= 0.0 || table.w <= 0.0 || persp <= 0.0) {
		return g;
	}
	float v = (g.y - table.y) / table.w;
	float d = max(0.2, 1.0 + persp * (1.0 - v));
	float cx = table.x + table.z * 0.5;
	return vec2(cx + (g.x - cx) / d, table.y + table.w * v / d);
}

void vertex() {
	vec2 g = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	VERTEX = (inverse(MODEL_MATRIX) * vec4(warp(g), 0.0, 1.0)).xy;
}
"""

## Tinta no feltro: escurece um pouco a cor (absorvida pelo pano), corta a borda do traço
## de forma irregular e abre falhas de pigmento em fios, como a fibra. O ruído é preso à
## tela (FRAGCOORD): o desenho e o texto "pegam" a trama de onde estão pintados.
const PAINT_CODE := """
uniform float wear = 0.0;
uniform float soak = 0.86;

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

void fragment() {
	vec4 c = COLOR;
	vec2 p = FRAGCOORD.xy;
	// Fios do pano: ruído esticado em duas direções, mais o grão de cada ponto.
	float fiber = max(vnoise(p * vec2(0.9, 0.16)), vnoise(p * vec2(0.16, 0.9) + 11.0));
	float n = fiber * 0.55 + vnoise(p * 0.45 + 3.0) * 0.25 + hash(floor(p)) * 0.2;
	// Borda serrilhada: onde a tinta é fina (beira do traço), o ruído come o pigmento.
	float edge = clamp((c.a - (1.0 - n) * (0.45 + wear * 0.4)) * 2.2, 0.0, 1.0);
	// Falhas: pontos onde o pigmento não pegou (mais com o desgaste).
	float gap = smoothstep(0.12 + wear * 0.45, 0.36 + wear * 0.45, n);
	c.a = edge * mix(0.4, 0.97, gap) * (1.0 - wear * 0.3);
	c.rgb *= soak * mix(0.9, 1.04, n);
	COLOR = c;
}
"""

static var stage := Rect2() ## Palco na tela (coordenadas globais); vazio = sem perspectiva.
static var _paint := {} ## desgaste -> ShaderMaterial (tinta + perspectiva)
static var _warp: ShaderMaterial ## Só a perspectiva (o dado posto num buraco).
static var _shaders := {}


static func persp() -> float:
	return KEYSTONE / (1.0 - KEYSTONE)


static func active() -> bool:
	return stage.size.x > 0.0 and stage.size.y > 0.0


## Liga a perspectiva para este palco (retângulo global); Rect2() desliga.
static func set_stage(r: Rect2) -> void:
	stage = r
	for m: ShaderMaterial in _paint.values():
		_apply(m)
	if _warp != null:
		_apply(_warp)


static func _apply(m: ShaderMaterial) -> void:
	m.set_shader_parameter("table", Vector4(stage.position.x, stage.position.y, stage.size.x, stage.size.y))
	m.set_shader_parameter("persp", persp() if active() else 0.0)


static func _shader(paint: bool) -> Shader:
	if not _shaders.has(paint):
		var sh := Shader.new()
		sh.code = "shader_type canvas_item;\n" + WARP_CODE + (PAINT_CODE if paint else "")
		_shaders[paint] = sh
	return _shaders[paint]


## Tinta com este desgaste (0 nova, 1 gasta), já em perspectiva; uma por valor.
static func paint(wear: float) -> ShaderMaterial:
	var k := snappedf(wear, 0.05)
	if not _paint.has(k):
		var m := ShaderMaterial.new()
		m.shader = _shader(true)
		m.set_shader_parameter("wear", k)
		_apply(m)
		_paint[k] = m
	return _paint[k]


## Só a perspectiva, sem tinta (o dado posto no buraco não é pintado).
static func warp_only() -> ShaderMaterial:
	if _warp == null:
		_warp = ShaderMaterial.new()
		_warp.shader = _shader(false)
		_apply(_warp)
	return _warp


## Ponto global como aparece na tela (homografia direta).
static func warp(g: Vector2) -> Vector2:
	if not active():
		return g
	var m := persp()
	var v := (g.y - stage.position.y) / stage.size.y
	var d := maxf(0.2, 1.0 + m * (1.0 - v))
	var cx := stage.get_center().x
	return Vector2(cx + (g.x - cx) / d, stage.position.y + stage.size.y * v / d)


## Ponto da tela levado de volta ao lugar do controle (homografia inversa).
static func unwarp(p: Vector2) -> Vector2:
	if not active():
		return p
	var m := persp()
	var vp := (p.y - stage.position.y) / stage.size.y
	var v := vp * (1.0 + m) / maxf(0.2, 1.0 + m * vp)
	var d := maxf(0.2, 1.0 + m * (1.0 - v))
	var cx := stage.get_center().x
	return Vector2(cx + (p.x - cx) * d, stage.position.y + stage.size.y * v)


## Ponto local p de c (no espaço da tela deformada) levado ao espaço local sem
## deformação: para o toque cair onde o controle aparece.
static func local_hit(c: Control, p: Vector2) -> Vector2:
	if not active():
		return p
	var xf := c.get_global_transform()
	return xf.affine_inverse() * unwarp(xf * p)
