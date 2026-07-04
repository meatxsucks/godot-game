## Efectos de gamefeel (autoload "FX"): números de daño flotantes, ráfagas
## de partículas y screen shake. Todo construido por código, sin assets.
extends Node

## Número de daño flotante. Naranja y grande al critear; `color` fuerza uno
## custom (ej. rojo para el daño que recibe el jugador).
func damage_number(pos: Vector3, amount: float, is_crit: bool = false, color: Color = Color.TRANSPARENT) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var label := Label3D.new()
	label.text = str(int(roundf(amount)))
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = 96 if is_crit else 60
	label.outline_size = 20
	label.pixel_size = 0.005
	if color != Color.TRANSPARENT:
		label.modulate = color
	else:
		label.modulate = Color(1.0, 0.62, 0.1) if is_crit else Color.WHITE
	scene.add_child(label)
	label.global_position = pos + Vector3(randf_range(-0.3, 0.3), 1.3, randf_range(-0.3, 0.3))

	var tween := label.create_tween()
	tween.tween_property(label, "global_position:y", label.global_position.y + 1.2, 0.7)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.7).set_ease(Tween.EASE_IN)
	tween.tween_callback(label.queue_free)

## Ráfaga de partículas one-shot (impactos, muertes, dash, level up).
func burst(pos: Vector3, color: Color, count: int = 12, size: float = 0.08) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var particles := GPUParticles3D.new()
	particles.one_shot = true
	particles.emitting = false
	particles.amount = count
	particles.lifetime = 0.5
	particles.explosiveness = 1.0

	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = 180.0
	process.initial_velocity_min = 2.0
	process.initial_velocity_max = 4.5
	process.gravity = Vector3(0, -9.8, 0)
	process.scale_min = 0.6
	process.scale_max = 1.3
	process.color = color
	particles.process_material = process

	var mesh := SphereMesh.new()
	mesh.radius = size
	mesh.height = size * 2.0
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.5
	mesh.material = mat
	particles.draw_pass_1 = mesh

	scene.add_child(particles)
	particles.global_position = pos
	particles.emitting = true
	get_tree().create_timer(1.2).timeout.connect(particles.queue_free)

## Screen shake: lo ejecutan los rigs de cámara del grupo "camera_rig".
func shake(strength: float = 0.3) -> void:
	for rig in get_tree().get_nodes_in_group("camera_rig"):
		if rig.has_method("shake"):
			rig.shake(strength)
