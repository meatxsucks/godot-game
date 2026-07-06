## Vista previa 3D del personaje en el inventario: muestra el modelo de la
## clase girando lentamente, con TODO el equipo puesto (paper-doll), para
## apreciar de cerca cada pieza. Renderiza en un SubViewport y ENCUADRA el
## cuerpo completo automáticamente (según el AABB real del modelo).
class_name CharacterPreview
extends SubViewportContainer

var _pivot: Node3D = null
var _cam: Camera3D = null

func setup(player: Node) -> void:
	stretch = true
	# Recuadro fijo y compacto (no se expande ni empuja el panel).
	custom_minimum_size = Vector2(150, 165)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.size = Vector2i(150, 165)
	vp.render_target_update_mode = SubViewport.UPDATE_WHEN_PARENT_VISIBLE
	add_child(vp)

	# Iluminación propia del subviewport (mundo aislado).
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.05, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.55, 0.65)
	env.ambient_light_energy = 1.5
	world_env.environment = env
	vp.add_child(world_env)

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-30, -40, 0)
	key_light.light_energy = 1.4
	vp.add_child(key_light)

	_cam = Camera3D.new()
	_cam.fov = 30.0
	_cam.current = true
	vp.add_child(_cam)

	# Modelo de la clase (mismo GLB que el jugador). Sin él, no hay preview.
	var def := Game.class_def(Game.selected_class)
	var path: String = def.get("model", "")
	if path == "" or not ResourceLoader.exists(path):
		return
	var scene = load(path)
	if scene == null:
		return

	_pivot = Node3D.new()
	vp.add_child(_pivot)
	var model: Node3D = scene.instantiate()
	_pivot.add_child(model)

	# Idle para no quedar en T-pose.
	var anim: AnimationPlayer = model.find_child("AnimationPlayer", true, false)
	if anim and anim.has_animation("Idle"):
		anim.play("Idle")

	# Paper-doll: reutiliza el componente del jugador sobre este modelo.
	var visuals := EquipmentVisuals.new()
	add_child(visuals)
	visuals.setup(player, model)

	_frame_camera(model)

## Encuadra la cámara al cuerpo completo según el AABB combinado del modelo.
func _frame_camera(model: Node3D) -> void:
	var aabb := AABB()
	var first := true
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mesh
		var world_aabb := m.global_transform * m.get_aabb()
		if first:
			aabb = world_aabb
			first = false
		else:
			aabb = aabb.merge(world_aabb)
	if first:
		# Sin meshes: encuadre por defecto.
		_cam.position = Vector3(0, 1.0, 5.0)
		_cam.look_at(Vector3(0, 0.9, 0), Vector3.UP)
		return

	var center := aabb.position + aabb.size * 0.5
	# El personaje real (en Idle) es más bajo que el AABB en bind pose, así
	# que encuadro un poco más ajustado que la altura completa del AABB.
	var frame_height: float = maxf(aabb.size.y * 0.85, 1.9)
	var dist: float = (frame_height * 0.5) / tan(deg_to_rad(_cam.fov) * 0.5) + 0.4
	_cam.position = Vector3(center.x, center.y, center.z + dist)
	_cam.look_at(center, Vector3.UP)

## Turntable: gira el modelo lentamente para ver todos los ángulos.
func _process(delta: float) -> void:
	if _pivot and is_visible_in_tree():
		_pivot.rotate_y(delta * 0.6)
