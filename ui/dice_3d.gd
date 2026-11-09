class_name Dice3D
extends RefCounted
## Malha e texturas do dado 3D, tudo gerado em código (sem arquivos de arte).
##
## - Malha: cubo de cantos arredondados, uma superfície por face (cada uma com o seu
##   material), na ordem de DicePhysics.FACE_NORMALS.
## - Texturas: de 1 a 6, pontinhos; os demais valores, algarismos traçados. Os dois
##   escavados (baixo relevo): um mapa de altura vira mapa de normais, então a luz da
##   cena desenha a sombra dentro do buraco e o brilho na borda.

const TEX := 128
const ROUND := 0.12 ## Raio do arredondamento das arestas (aresta do dado = 1).
const DEPTH := 3.2 ## Profundidade do baixo relevo, em pixels da textura.

## Algarismos como traços (polilinhas) numa caixa de 0,6 × 1 (y para baixo).
static var _glyphs := {}
static var _mesh: ArrayMesh
static var _albedo := {} ## "valor|elemento" -> ImageTexture
static var _normals := {} ## "valor|acabamento" -> ImageTexture
static var _emission := {} ## "valor|brilho" -> ImageTexture


# ================================================================== Malha
static func mesh() -> ArrayMesh:
	if _mesh:
		return _mesh
	var h := DicePhysics.H
	var grid := [-h, -h + ROUND * 0.3, -h + ROUND * 0.7, -h + ROUND, 0.0, h - ROUND, h - ROUND * 0.7, h - ROUND * 0.3, h]
	_mesh = ArrayMesh.new()
	for n in DicePhysics.FACE_NORMALS:
		var u := _face_u(n)
		var v: Vector3 = u.cross(n)
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for j in grid.size():
			for i in grid.size():
				var c: Vector3 = n * h + u * float(grid[i]) + v * float(grid[j])
				var inner := c.clamp(Vector3.ONE * -(h - ROUND), Vector3.ONE * (h - ROUND))
				var dn := (c - inner).normalized()
				st.set_normal(dn)
				st.set_uv(Vector2((float(grid[i]) + h) / (2 * h), (float(grid[j]) + h) / (2 * h)))
				st.add_vertex(inner + dn * ROUND)
		var w := grid.size()
		for j in w - 1:
			for i in w - 1:
				var a := j * w + i
				# Sentido horário visto de fora (face da frente no Godot).
				for k in [a, a + 1, a + w, a + 1, a + w + 1, a + w]:
					st.add_index(k)
		st.generate_tangents()
		st.commit(_mesh)
	return _mesh


## Eixo "direita" da textura em cada face (a de cima fica legível com a câmera de cima).
static func _face_u(n: Vector3) -> Vector3:
	if absf(n.y) > 0.5:
		return Vector3.RIGHT
	return Vector3.UP.cross(n).normalized() * -1.0


# ================================================================== Rótulos
## Valores escritos em cada face local (ordem de FACE_NORMALS) para que a face que
## ficou para cima (up) mostre o valor sorteado. faces: as seis faces do dado; face:
## a que saiu. As faces opostas seguem os pares do d6 (1-6, 2-5, 3-4).
static func labels(up: int, value: int, faces: Array, face: int) -> Array:
	var out := [0, 0, 0, 0, 0, 0]
	var f6: Array = faces if faces.size() == 6 else [1, 2, 3, 4, 5, 6]
	var f := clampi(face, 0, 5)
	out[up] = value
	out[up ^ 1] = int(f6[5 - f])
	# Os outros dois pares vão para os dois pares de faces locais que sobraram.
	var pairs := []
	for k in 3:
		if k != mini(f, 5 - f):
			pairs.append([int(f6[k]), int(f6[5 - k])])
	var slots := []
	for k in [0, 2, 4]:
		if k != (up & ~1):
			slots.append(k)
	for k in 2:
		out[slots[k]] = pairs[k][0]
		out[slots[k] + 1] = pairs[k][1]
	return out


## Índice da face do dado (0 a 5, a ordem de Die.faces) em cada face local, com a mesma
## distribuição de labels(): serve para os adesivos irem na face certa.
static func face_slots(up: int, face: int) -> Array:
	var out := [0, 0, 0, 0, 0, 0]
	var f := clampi(face, 0, 5)
	out[up] = f
	out[up ^ 1] = 5 - f
	var pairs := []
	for k in 3:
		if k != mini(f, 5 - f):
			pairs.append([k, 5 - k])
	var slots := []
	for k in [0, 2, 4]:
		if k != (up & ~1):
			slots.append(k)
	for k in 2:
		out[slots[k]] = pairs[k][0]
		out[slots[k] + 1] = pairs[k][1]
	return out


## Selos dos adesivos numa face local do dado 3D (como DieFace.marks): bolinha vermelha
## com "+2" no canto de cima à direita e bolinha dourada embaixo à esquerda. Nós filhos
## do dado, colados na face; null se a face não tem adesivo.
static func marks_node(local_face: int, stickers: int, gold: int) -> Node3D:
	if stickers <= 0 and gold <= 0:
		return null
	var n: Vector3 = DicePhysics.FACE_NORMALS[local_face]
	var u := _face_u(n)
	var v: Vector3 = u.cross(n) ## Para baixo na textura.
	var root := Node3D.new()
	root.transform = Transform3D(Basis(u, -v, n), n * (DicePhysics.H + 0.004))
	var rr := 0.16
	if stickers > 0:
		root.add_child(_mark_disc(Vector2(0.5 - 0.05 - rr, 0.5 - 0.05 - rr), rr, DieFace.STICKER_RED,
			"+%d" % (Config.STICKER_PLUS * stickers), Color.WHITE))
	if gold > 0:
		root.add_child(_mark_disc(Vector2(-0.5 + 0.05 + rr, -0.5 + 0.05 + rr), rr * 0.85, DieFace.GOLD,
			str(gold) if gold > 1 else "", Color(0.3, 0.18, 0.0)))
	return root


static var _disc_tex := {}


## Disco com contorno (textura gerada) e o texto por cima (Label3D), no plano da face.
static func _mark_disc(at: Vector2, rr: float, col: Color, txt: String, ink: Color) -> Node3D:
	var key := col.to_html()
	if not _disc_tex.has(key):
		var px := 64
		var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
		var c := Vector2(px, px) * 0.5
		for y in px:
			for x in px:
				var d := (Vector2(x + 0.5, y + 0.5) - c).length() / (px * 0.5)
				var a := clampf((1.0 - d) * px * 0.5, 0.0, 1.0)
				var cc := col if d < 0.84 else col.darkened(0.4)
				if (Vector2(x + 0.5, y + 0.5) - c * Vector2(0.7, 0.66)).length() < px * 0.12:
					cc = cc.lerp(Color.WHITE, 0.35)
				img.set_pixel(x, y, Color(cc, a))
		img.generate_mipmaps()
		_disc_tex[key] = ImageTexture.create_from_image(img)
	var node := Node3D.new()
	node.position = Vector3(at.x, at.y, 0)
	var sp := Sprite3D.new()
	sp.texture = _disc_tex[key]
	sp.pixel_size = rr * 2.0 / 64.0
	sp.shaded = true
	sp.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sp.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	node.add_child(sp)
	if txt != "":
		var lb := Label3D.new()
		lb.text = txt
		lb.font = Kit.num_font()
		lb.font_size = 64
		lb.pixel_size = rr * (1.0 if txt.length() <= 2 else 0.8) / 64.0
		lb.modulate = ink
		lb.outline_size = 0
		lb.position = Vector3(0, -rr * 0.04, 0.003)
		lb.alpha_cut = Label3D.ALPHA_CUT_DISCARD
		node.add_child(lb)
	return node


# ================================================================== Texturas
## Material de uma face: cor, acabamento e brilho do elemento (Elements.LOOKS).
## heat: estado do dado, de 0 (repouso) a 1 (efeito ativo); só muda a energia do brilho.
static func material(value: int, element: String, heat := 0.0) -> StandardMaterial3D:
	var l := Elements.look(element)
	var m := StandardMaterial3D.new()
	m.albedo_texture = albedo_texture(value, element)
	m.normal_enabled = true
	m.normal_texture = normal_texture(value, str(l.finish))
	m.normal_scale = 1.4
	m.roughness = float(l.rough)
	m.metallic = float(l.metal)
	m.metallic_specular = 0.6
	if float(l.coat) > 0.0:
		m.clearcoat_enabled = true
		m.clearcoat = float(l.coat)
		m.clearcoat_roughness = 0.15
	if float(l.rim) > 0.0:
		m.rim_enabled = true
		m.rim = float(l.rim)
		m.rim_tint = 0.6
	if float(l.alpha) < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
		m.albedo_color = Color(1, 1, 1, float(l.alpha))
	if str(l.glow) != "":
		m.emission_enabled = true
		m.emission = l.emission
		m.emission_energy_multiplier = Elements.energy(element, heat)
		m.emission_texture = emission_texture(value, str(l.glow))
		if l.get("glow_only", false):
			# Só a máscara acende (o modo padrão soma a cor no dado inteiro).
			m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m


static func albedo_texture(value: int, element: String) -> ImageTexture:
	var key := "%d|%s" % [value, element]
	if _albedo.has(key):
		return _albedo[key]
	var l := Elements.look(element)
	var body: Color = l.body
	var body2: Color = l.body2
	var ink: Color = l.ink
	var finish := str(l.finish)
	var depth := depth_map(value)
	var noise := _noise(finish)
	var img := Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	for y in TEX:
		for x in TEX:
			var u := (x + 0.5) / TEX
			var v := (y + 0.5) / TEX
			var c := _finish_color(finish, body, body2, u, v, noise)
			var d: float = depth[y * TEX + x]
			img.set_pixel(x, y, c.lerp(ink, smoothstep(0.0, 0.12, d)))
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_albedo[key] = t
	return t


## Ruído fixo (mesma semente sempre) para os acabamentos com textura.
static func _noise(finish: String) -> FastNoiseLite:
	if not (finish in ["fosco", "fibroso", "ferrugem"]):
		return null
	var n := FastNoiseLite.new()
	n.seed = 7
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = 0.06 if finish == "ferrugem" else 0.2
	return n


## Cor do corpo no ponto (u, v) da face, antes da tinta do baixo relevo.
static func _finish_color(finish: String, body: Color, body2: Color, u: float, v: float, noise: FastNoiseLite) -> Color:
	var edge := minf(minf(u, 1.0 - u), minf(v, 1.0 - v)) ## 0 na aresta, 0,5 no centro.
	match finish:
		"vidro", "ceroso":
			# Miolo mais claro: luz presa dentro do material.
			var r := Vector2(u - 0.5, v - 0.5).length() / 0.7
			return body2.lerp(body, clampf(r, 0.0, 1.0))
		"espelho":
			# Faixa clara diagonal (o reflexo de verdade vem do céu do ambiente).
			var band := 1.0 - clampf(absf((u + v) - 0.9) / 0.18, 0.0, 1.0)
			return body.lerp(body2, band * 0.45)
		"fosco":
			# Arranhões: riscos finos e claros em duas direções.
			var s1 := absf(fmod(u * 9.0 + v * 4.0 + noise.get_noise_2d(u * 40, v * 40) * 0.6, 1.0) - 0.5)
			var s2 := absf(fmod(u * 3.0 - v * 7.0, 1.0) - 0.5)
			var scratch := maxf(1.0 - smoothstep(0.0, 0.025, s1), 1.0 - smoothstep(0.0, 0.02, s2)) * 0.5
			return body.lightened(scratch * 0.35).darkened(maxf(0.0, noise.get_noise_2d(u * 90, v * 90)) * 0.12)
		"fibroso":
			# Fibras finas quase paralelas.
			var f := sin((u * 0.35 + v) * 140.0 + noise.get_noise_2d(u * 60, v * 60) * 6.0)
			return body.lightened(maxf(0.0, f) * 0.14).darkened(maxf(0.0, -f) * 0.12)
		"ferrugem":
			# Manchas de ferrugem e o metal aparecendo nas arestas gastas.
			var n := noise.get_noise_2d(u * TEX, v * TEX)
			var c := body.lightened(maxf(0.0, n) * 0.25).darkened(maxf(0.0, -n) * 0.3)
			var wear := 1.0 - smoothstep(0.03, 0.09 + n * 0.03, edge)
			return c.lerp(body2, wear)
		"anodizado":
			# Furta-cor do óxido: magenta, azul e dourado em faixas diagonais onduladas.
			var t := fposmod((u * 0.8 + v) * 0.9 + sin(u * 7.0 + v * 3.0) * 0.08, 1.0)
			var mid := Color("#3d6fe0") ## Azul do meio do furta-cor.
			var c2 := body.lerp(mid, t * 2.0) if t < 0.5 else mid.lerp(body2, (t - 0.5) * 2.0)
			var sheen := 1.0 - clampf(absf((u + v) - 0.8) / 0.12, 0.0, 1.0)
			return c2.lightened(sheen * 0.3)
		"grafite":
			# Lustro de grafite: uma faixa suave na diagonal.
			var sheen := 1.0 - clampf(absf((u + v) - 1.0) / 0.35, 0.0, 1.0)
			return body.lerp(body2, sheen * 0.6)
	# Marfim: só um leve degradê de cima para baixo.
	return body.lerp(body2, (1.0 - v) * 0.35)


## Máscara do brilho: "pips" acende os baixos relevos, "body" o corpo (sem os
## baixos relevos, para o valor continuar legível) e "rim" as arestas.
static func emission_texture(value: int, glow: String) -> ImageTexture:
	var key := "%d|%s" % [value, glow]
	if _emission.has(key):
		return _emission[key]
	var depth := depth_map(value)
	var img := Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	for y in TEX:
		for x in TEX:
			var d := smoothstep(0.0, 0.12, depth[y * TEX + x])
			var k := 0.0
			match glow:
				"pips":
					k = d
				"body":
					k = 1.0 - d
				"rim":
					var u := (x + 0.5) / TEX
					var v := (y + 0.5) / TEX
					var edge := minf(minf(u, 1.0 - u), minf(v, 1.0 - v))
					k = 1.0 - smoothstep(0.0, 0.14, edge)
			img.set_pixel(x, y, Color(k, k, k))
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_emission[key] = t
	return t


static func normal_texture(value: int, finish := "") -> ImageTexture:
	var key := "%d|%s" % [value, finish if finish in ["fosco", "fibroso", "ferrugem"] else ""]
	if _normals.has(key):
		return _normals[key]
	var depth := depth_map(value)
	var noise := _noise(finish)
	if noise != null:
		# Relevo do acabamento: fibras, arranhões ou corrosão bem rasos.
		var amp := 0.06 if finish == "ferrugem" else 0.035
		for y in TEX:
			for x in TEX:
				var i := y * TEX + x
				var n := noise.get_noise_2d(x * (0.4 if finish == "fibroso" else 1.0), y * (3.0 if finish == "fibroso" else 1.0))
				depth[i] = depth[i] + (n * 0.5 + 0.5) * amp
	var img := Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	for y in TEX:
		for x in TEX:
			var l := depth[y * TEX + maxi(0, x - 1)]
			var r := depth[y * TEX + mini(TEX - 1, x + 1)]
			var u := depth[maxi(0, y - 1) * TEX + x]
			var dn := depth[mini(TEX - 1, y + 1) * TEX + x]
			# Altura = -profundidade. Normal no espaço da tangente (verde para cima).
			var dhdx := -(r - l) * 0.5 * DEPTH
			var dhdy := -(dn - u) * 0.5 * DEPTH
			var nv := Vector3(dhdx, -dhdy, 1.0).normalized()
			img.set_pixel(x, y, Color(nv.x * 0.5 + 0.5, nv.y * 0.5 + 0.5, nv.z * 0.5 + 0.5))
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_normals[key] = t
	return t


## Profundidade de 0 (face lisa) a 1 (fundo do buraco), pixel a pixel.
static func depth_map(value: int) -> PackedFloat32Array:
	var buf := PackedFloat32Array()
	buf.resize(TEX * TEX)
	buf.fill(0.0)
	if DieFace.uses_pips(value):
		var r := DieFace.PIP_R * TEX * 0.98
		for p in DieFace.PIPS[value]:
			var c: Vector2 = p * TEX
			_stamp(buf, c, c, r)
		return buf
	var txt := str(value)
	# Caixa de cada algarismo: 0,6 × 1, com 0,2 de espaço entre eles.
	var units := txt.length() * 0.6 + (txt.length() - 1) * 0.22
	var gh := minf(TEX * 0.5, TEX * 0.74 / units)
	var sw := gh * 0.12
	var x0 := (TEX - units * gh) * 0.5
	var y0 := (TEX - gh) * 0.5
	for ch in txt:
		for line in glyph(ch):
			for k in range(line.size() - 1):
				_stamp(buf, Vector2(x0, y0) + line[k] * gh, Vector2(x0, y0) + line[k + 1] * gh, sw)
		x0 += gh * 0.82
	return buf


## Escava um traço de a até b (ou um ponto, se a == b) com fundo arredondado.
static func _stamp(buf: PackedFloat32Array, a: Vector2, b: Vector2, r: float) -> void:
	var lo := Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2(r + 1, r + 1)
	var hi := Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + Vector2(r + 1, r + 1)
	var ab := b - a
	var len2 := ab.length_squared()
	for y in range(maxi(0, int(lo.y)), mini(TEX, int(hi.y) + 1)):
		for x in range(maxi(0, int(lo.x)), mini(TEX, int(hi.x) + 1)):
			var p := Vector2(x + 0.5, y + 0.5)
			var t := 0.0 if len2 == 0.0 else clampf((p - a).dot(ab) / len2, 0.0, 1.0)
			var d := p.distance_to(a + ab * t)
			if d >= r:
				continue
			var q := d / r
			var v := sqrt(1.0 - q * q)
			var i := y * TEX + x
			if v > buf[i]:
				buf[i] = v


static func glyph(ch: String) -> Array:
	if _glyphs.is_empty():
		_build_glyphs()
	return _glyphs.get(ch, [])


static func _arc(c: Vector2, r: Vector2, a0: float, a1: float, n := 14) -> Array:
	var out := []
	for k in n + 1:
		var a := deg_to_rad(lerpf(a0, a1, float(k) / n))
		out.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	return out


static func _bez(p0: Vector2, p1: Vector2, p2: Vector2, n := 10) -> Array:
	var out := []
	for k in n + 1:
		var t := float(k) / n
		out.append(p0.lerp(p1, t).lerp(p1.lerp(p2, t), t))
	return out


static func _build_glyphs() -> void:
	var V := func(x: float, y: float) -> Vector2: return Vector2(x, y)
	_glyphs["0"] = [_arc(V.call(0.3, 0.5), V.call(0.28, 0.48), 0, 360, 24)]
	_glyphs["1"] = [[V.call(0.1, 0.2), V.call(0.34, 0.02), V.call(0.34, 0.98)], [V.call(0.1, 0.98), V.call(0.56, 0.98)]]
	_glyphs["2"] = [_arc(V.call(0.3, 0.28), V.call(0.27, 0.26), -165, 25) + [V.call(0.03, 0.98), V.call(0.58, 0.98)]]
	_glyphs["3"] = [_arc(V.call(0.3, 0.26), V.call(0.26, 0.24), -160, 90, 12), _arc(V.call(0.3, 0.73), V.call(0.29, 0.25), -90, 160, 12)]
	_glyphs["4"] = [[V.call(0.44, 0.98), V.call(0.44, 0.02), V.call(0.02, 0.68), V.call(0.6, 0.68)]]
	_glyphs["5"] = [[V.call(0.54, 0.02), V.call(0.1, 0.02), V.call(0.06, 0.46)] + _arc(V.call(0.3, 0.68), V.call(0.29, 0.3), -140, 155, 14)]
	_glyphs["6"] = [_bez(V.call(0.5, 0.03), V.call(0.03, 0.2), V.call(0.03, 0.68)), _arc(V.call(0.3, 0.7), V.call(0.27, 0.28), 0, 360, 20)]
	_glyphs["7"] = [[V.call(0.02, 0.02), V.call(0.58, 0.02), V.call(0.2, 0.98)]]
	_glyphs["8"] = [_arc(V.call(0.3, 0.26), V.call(0.23, 0.23), 0, 360, 18), _arc(V.call(0.3, 0.74), V.call(0.28, 0.25), 0, 360, 20)]
	_glyphs["9"] = [_arc(V.call(0.3, 0.3), V.call(0.27, 0.28), 0, 360, 20), _bez(V.call(0.57, 0.3), V.call(0.57, 0.85), V.call(0.1, 0.97))]
	_glyphs["-"] = [[V.call(0.08, 0.55), V.call(0.52, 0.55)]]
