class_name DieSnapshot
extends SubViewport
## Foto do dado 3D para a coluna e os cartões: o mesmo dado (malha, materiais), com a
## mesma câmera e as mesmas luzes da mesa (DiceRoll3D.stage). Assim o dado que voa da
## mesa para a coluna chega com exatamente a cara que tinha lá.
##
## As fotos são tiradas sob demanda, uma por vez, num SubViewport fora da tela, e ficam
## em cache. Enquanto a foto não fica pronta (e sem vídeo: testes, simulação), quem
## desenha usa a face 2D (DieFace).

const PX := 192 ## Lado da foto, em pixels.
const VIEW := 1.45 ## Quanto da mesa a foto cobre, em arestas de dado.
const FILL := 0.86 ## Aresta do dado em relação ao lado do quadrado onde ele é desenhado.

static var _cache := {} ## chave -> ImageTexture
static var _queue: Array = [] ## chaves esperando foto
static var _waiting := {} ## chave -> {id do objeto: WeakRef} (quem redesenhar quando ficar pronta)
static var _failed := {} ## chaves cuja foto veio vazia: ficam na face 2D
static var _node: DieSnapshot

var _mi: MeshInstance3D
var _busy := false


static func enabled() -> bool:
	return DisplayServer.get_name() != "headless"


## Estado do brilho em três degraus (repouso, meio, ativo): uma foto por degrau.
static func key(value: int, element: String, heat := 0.0) -> String:
	return "%d|%s|%d" % [value, element, roundi(clampf(heat, 0.0, 1.0) * 2.0)]


## A foto pronta, ou null (e ela entra na fila; who é redesenhado quando ficar pronta).
static func texture(value: int, element: String, heat := 0.0, who: CanvasItem = null) -> Texture2D:
	if not enabled():
		return null
	var k := key(value, element, heat)
	if _cache.has(k):
		return _cache[k]
	if _failed.has(k):
		return null
	if who != null:
		if not _waiting.has(k):
			_waiting[k] = {}
		_waiting[k][who.get_instance_id()] = weakref(who)
	if not (k in _queue):
		_queue.append(k)
	_kick()
	return null


## Pede as fotos de antemão (ex.: no começo da rolagem, para estarem prontas no fim).
static func prepare(value: int, element: String, heat := 0.0) -> void:
	texture(value, element, heat)


## Retângulo onde desenhar a foto para o dado ocupar o quadrado r como a face 2D ocuparia.
static func rect_for(r: Rect2) -> Rect2:
	var side := minf(r.size.x, r.size.y) * FILL * VIEW
	return Rect2(r.get_center() - Vector2(side, side) * 0.5, Vector2(side, side))


static func _kick() -> void:
	if _node != null and is_instance_valid(_node):
		if _node.is_inside_tree() and not _node._busy:
			_node._run()
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return
	_node = DieSnapshot.new()
	tree.root.add_child.call_deferred(_node)


func _ready() -> void:
	transparent_bg = true
	own_world_3d = true
	msaa_3d = Viewport.MSAA_4X
	size = Vector2i(PX, PX)
	render_target_update_mode = SubViewport.UPDATE_DISABLED
	var world := Node3D.new()
	add_child(world)
	var cam := Camera3D.new()
	world.add_child(cam)
	DiceRoll3D.stage(world, cam, VIEW)
	_mi = MeshInstance3D.new()
	_mi.mesh = Dice3D.mesh()
	world.add_child(_mi)
	_run()


func _run() -> void:
	_busy = true
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	while not _queue.is_empty():
		var k: String = _queue.pop_front()
		var parts := k.split("|")
		var v := int(parts[0])
		var el := parts[1]
		var heat := int(parts[2]) / 2.0
		# Face de cima (local 0) com o valor; as outras seguem os pares do d6.
		var labels := Dice3D.labels(0, v, [1, 2, 3, 4, 5, 6], clampi(v - 1, 0, 5))
		for s in 6:
			_mi.set_surface_override_material(s, Dice3D.material(int(labels[s]), el, heat))
		# Um quadro para o viewport desenhar com os materiais novos, outro para ler.
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img := get_texture().get_image()
		if img != null and not img.is_empty():
			_cache[k] = ImageTexture.create_from_image(img)
		else:
			_failed[k] = true
		for w: WeakRef in _waiting.get(k, {}).values():
			var o = w.get_ref()
			if o != null and o is CanvasItem:
				o.queue_redraw()
		_waiting.erase(k)
	render_target_update_mode = SubViewport.UPDATE_DISABLED
	_busy = false
