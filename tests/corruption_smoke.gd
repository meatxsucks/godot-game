## Smoke de E2.1 (Corrupción): el medidor clampea en PlayerStats, sube con el
## tiempo fuera de zona segura, se limpia adentro, y un golpe suma corrupción.
extends Node3D

func _ready() -> void:
	var floor_body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(40, 1, 40)
	collision.shape = shape
	floor_body.add_child(collision)
	add_child(floor_body)
	floor_body.global_position = Vector3(0, -0.5, 0)

	# --- Unidad: PlayerStats clampea 0..CORRUPTION_MAX ----------------------
	var stats := PlayerStats.new()
	assert(stats.corruption == 0.0, "arranca en 0")
	stats.add_corruption(40.0)
	assert(stats.corruption == 40.0, "suma corrupción")
	stats.add_corruption(1000.0)
	assert(stats.corruption == PlayerStats.CORRUPTION_MAX, "clampea al máximo")
	stats.clear_corruption(30.0)
	assert(stats.corruption == PlayerStats.CORRUPTION_MAX - 30.0, "limpia una cantidad")
	stats.clear_corruption()
	assert(stats.corruption == 0.0, "clear_corruption() sin monto limpia todo")
	stats.add_corruption(-50.0)
	assert(stats.corruption == 0.0, "clampea abajo de 0")

	# --- Integración: fuera de zona segura sube con el tiempo ---------------
	var zone = load("res://scenes/world/SafeZone.tscn").instantiate()
	add_child(zone) # entra al grupo "safe_zone" ANTES de instanciar al player
	zone.global_position = Vector3(0, 0, 0)

	var player = load("res://scenes/player/Player.tscn").instantiate()
	add_child(player)
	player.global_position = Vector3(20, 0, 20) # lejos (radio de la zona = 5)

	for i in 60: # 1s a 60 fps
		await get_tree().physics_frame
	assert(player.stats.corruption > 0.0, "la corrupción sube fuera de zona segura")

	# --- Adentro de la zona segura se limpia ---------------------------------
	player.stats.add_corruption(50.0)
	player.global_position = zone.global_position
	var before: float = player.stats.corruption
	for i in 30: # 0.5s — la limpieza es más rápida que la subida
		await get_tree().physics_frame
	assert(player.stats.corruption < before, "la corrupción baja en zona segura")

	# --- Un golpe suma corrupción --------------------------------------------
	player.global_position = Vector3(20, 0, 20) # afuera, para que no se limpie en el mismo frame
	var hit_before: float = player.stats.corruption
	player.take_damage(10.0)
	assert(player.stats.corruption > hit_before, "recibir daño suma corrupción")

	print("CORRUPTION SMOKE OK")
	get_tree().quit(0)
