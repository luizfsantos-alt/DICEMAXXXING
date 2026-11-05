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
static var _normals := {} ## valor -> ImageTexture


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


# ================================================================== Texturas
static func material(value: int, element: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = albedo_texture(value, element)
	m.normal_enabled = true
	m.normal_texture = normal_texture(value)
	m.normal_scale = 1.4
	m.roughness = 0.42
	m.metallic_specular = 0.6
	if element in ["Hg", "Os", "Pb", "Fe"]:
		m.metallic = 0.45
		m.roughness = 0.3
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m


static func albedo_texture(value: int, element: String) -> ImageTexture:
	var key := "%d|%s" % [value, element]
	if _albedo.has(key):
		return _albedo[key]
	var body: Color = Elements.COLORS.get(element, Elements.COLORS[""])
	var ink := DieFace.ink(body)
	var depth := depth_map(value)
	var img := Image.create(TEX, TEX, false, Image.FORMAT_RGB8)
	for y in TEX:
		for x in TEX:
			var d: float = depth[y * TEX + x]
			img.set_pixel(x, y, body.lerp(ink, smoothstep(0.0, 0.12, d)))
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_albedo[key] = t
	return t


static func normal_texture(value: int) -> ImageTexture:
	if _normals.has(value):
		return _normals[value]
	var depth := depth_map(value)
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
	_normals[value] = t
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
