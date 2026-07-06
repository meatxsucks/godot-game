## Vista previa 3D del personaje en el inventario: muestra el modelo de la
## clase girando lentamente, con TODO el equipo puesto (paper-doll), para
## apreciar de cerca cada pieza que te equipas. Renderiza en un SubViewport.
class_name CharacterPreview
extends SubViewportContainer

var _pivot: Node3D = null

func setup(player: Node) -> void:
	stretch = true
	custom_minimum_size = Vector2(150, 190)

	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	# Solo renderiza cuando el inventario está visible (ahorra rendimiento).
	vp.render_target_update_mode = SubViewport.UPDATE_WHEN_PARENT_VISIBLE
	add_child(vp)

	# Iluminación propia del subviewport (mundo aislado).
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.06, 0.1)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.55, 0.65)
	env.ambient_light_energy = 1.4
	world_env.environment = env
	vp.add_child(world_env)

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-35, -40, 0)
	key_light.light_energy = 1.3
	vp.add_child(key_light)

	var cam := Camera3D.new()
	cam.fov = 38.0
	cam.position = Vector3(0, 1.05, 3.6)
	cam.current = true
	vp.add_child(cam)
	cam.look_at(Vector3(0, 0.95, 0), Vector3.UP)

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

	# Paper-doll: reutiliza el mismo componente del jugador sobre este modelo.
	# Escucha las señales del player y muestra el equipo puesto en vivo.
	var visuals := EquipmentVisuals.new()
	add_child(visuals)
	visuals.setup(player, model)

## Turntable: gira el modelo lentamente para ver todos los ángulos.
func _process(delta: float) -> void:
	if _pivot and is_visible_in_tree():
		_pivot.rotate_y(delta * 0.7)
