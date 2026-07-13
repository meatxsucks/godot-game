## Generador procedural del mundo: rocas, pilares y árboles low-poly + parches
## de suelo, repartidos con un RNG sembrado (misma semilla = mismo mapa).
## Es hijo de NavRegion: sus obstáculos son colliders estáticos y entran al
## bake del navmesh, así los enemigos los rodean solos.
extends Node3D

## 0 = semilla aleatoria por partida.
@export var world_seed: int = 0
@export var obstacle_count: int = 45
@export var patch_count: int = 60
## Rectángulo del campo de batalla donde se genera (plano XZ).
@export var field_min := Vector2(-28, -28)
@export var field_max := Vector2(28, 12)
## Zona a mantener despejada (base + margen).
@export var keep_clear_center := Vector3(0, 0, 24)
@export var keep_clear_radius: float = 10.0

var _rng := RandomNumberGenerator.new()
var _placed: Array[Vector3] = []

func _ready() -> void:
	# Prioridad: seed del export (tests/diseño) → seed de la partida (en
	# co-op la reparte el host: todos generan el MISMO mapa) → aleatoria.
	var seed_used := world_seed
	if seed_used == 0:
		seed_used = Game.world_seed
	if seed_used == 0:
		seed_used = randi()
	_rng.seed = seed_used

	var made := 0
	for i in obstacle_count * 3: # intentos con rechazo
		if made >= obstacle_count:
			break
		var pos := _random_field_pos()
		if not _is_valid(pos):
			continue
		_placed.append(pos)
		_make_obstacle(pos)
		made += 1
	_make_patches()
	print("[World] semilla %d, %d obstáculos" % [seed_used, made])

func _random_field_pos() -> Vector3:
	return Vector3(
		_rng.randf_range(field_min.x, field_max.x),
		0.0,
		_rng.randf_range(field_min.y, field_max.y))

func _is_valid(pos: Vector3) -> bool:
	# Fuera de la base (+margen) y del corredor de la puerta.
	if pos.distance_to(keep_clear_center) < keep_clear_radius:
		return false
	if absf(pos.x) < 4.0 and pos.z > 10.0:
		return false
	for other in _placed:
		if pos.distance_to(other) < 2.5:
			return false
	return true

func _make_obstacle(pos: Vector3) -> void:
	match _rng.randi_range(0, 2):
		0:
			_make_rock(pos)
		1:
			_make_pillar(pos)
		2:
			_make_tree(pos)

func _toon_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.albedo_color = color
	mat.roughness = 0.9
	return mat

## StaticBody + collider en pos (los meshes se cuelgan encima).
func _make_body(pos: Vector3, shape: Shape3D, shape_offset_y: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	add_child(body)
	body.global_position = pos
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = shape_offset_y
	body.add_child(collision)
	return body

func _make_rock(pos: Vector3) -> void:
	var size := Vector3(
		_rng.randf_range(1.0, 2.2),
		_rng.randf_range(0.6, 1.4),
		_rng.randf_range(1.0, 2.2))
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _toon_material(Color(0.42, 0.4, 0.38).lerp(Color(0.3, 0.28, 0.33), _rng.randf()))
	var shape := BoxShape3D.new()
	shape.size = size
	var body := _make_body(pos, shape, size.y * 0.5)
	body.rotate_y(_rng.randf() * TAU)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.position.y = size.y * 0.5
	body.add_child(mesh_instance)

func _make_pillar(pos: Vector3) -> void:
	var height := _rng.randf_range(2.0, 3.2)
	var radius := _rng.randf_range(0.5, 0.8)
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.85
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.material = _toon_material(Color(0.5, 0.48, 0.55))
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	var body := _make_body(pos, shape, height * 0.5)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.position.y = height * 0.5
	body.add_child(mesh_instance)

func _make_tree(pos: Vector3) -> void:
	var trunk_height := _rng.randf_range(1.2, 1.8)
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.18
	trunk.bottom_radius = 0.25
	trunk.height = trunk_height
	trunk.material = _toon_material(Color(0.4, 0.26, 0.13))
	var shape := CylinderShape3D.new()
	shape.radius = 0.3
	shape.height = trunk_height
	var body := _make_body(pos, shape, trunk_height * 0.5)

	var trunk_mesh := MeshInstance3D.new()
	trunk_mesh.mesh = trunk
	trunk_mesh.position.y = trunk_height * 0.5
	body.add_child(trunk_mesh)

	# Copa cónica (sin collider: solo el tronco bloquea).
	var crown := CylinderMesh.new()
	crown.top_radius = 0.0
	crown.bottom_radius = _rng.randf_range(0.9, 1.4)
	crown.height = _rng.randf_range(1.6, 2.4)
	crown.material = _toon_material(Color(0.13, 0.42, 0.18).lerp(Color(0.2, 0.55, 0.2), _rng.randf()))
	var crown_mesh := MeshInstance3D.new()
	crown_mesh.mesh = crown
	crown_mesh.position.y = trunk_height + crown.height * 0.5 - 0.2
	body.add_child(crown_mesh)

## Parches de suelo decorativos (sin colisión) para romper el plano gris.
func _make_patches() -> void:
	for i in patch_count:
		var pos := _random_field_pos()
		var mesh := PlaneMesh.new()
		var patch_size := _rng.randf_range(2.0, 5.0)
		mesh.size = Vector2(patch_size, patch_size * _rng.randf_range(0.6, 1.4))
		var mat := StandardMaterial3D.new()
		var grass := Color(0.2, 0.3, 0.22)
		var dirt := Color(0.28, 0.24, 0.2)
		mat.albedo_color = grass.lerp(dirt, _rng.randf()).darkened(_rng.randf() * 0.2)
		mesh.material = mat
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = mesh
		add_child(mesh_instance)
		mesh_instance.global_position = pos + Vector3(0, 0.02, 0)
		mesh_instance.rotate_y(_rng.randf() * TAU)
