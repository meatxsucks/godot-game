## Smoke de E3 (tags de estado): Quemado hace ticks, Sangrado apila,
## Marcado amplifica el próximo golpe, detonar consume el tag por daño
## extra, y el combo cruzado de party (aplicó OTRO peer) da bonus.
extends Node3D

func _ready() -> void:
	# Piso para que el slime no caiga al vacío.
	var floor_body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(30, 1, 30)
	collision.shape = shape
	floor_body.add_child(collision)
	add_child(floor_body)
	floor_body.global_position = Vector3(0, -0.5, 0)

	var slime = load("res://scenes/enemies/Slime.tscn").instantiate()
	slime.max_health = 1000.0
	add_child(slime)
	await get_tree().physics_frame

	# --- Quemado: hace ticks de daño con el tiempo -------------------------
	slime.apply_status(&"burn", 20.0, 1) # golpe de 20 → ticks de 3 (15%)
	var before: float = slime.current_health
	for i in 40: # ~0.66s → al menos 1 tick de 0.5s
		await get_tree().physics_frame
	assert(slime.current_health < before, "Quemado hace daño por tick")

	# --- Sangrado: apila y el tick escala por stacks -----------------------
	slime.apply_status(&"bleed", 10.0, 1)
	slime.apply_status(&"bleed", 10.0, 1)
	slime.apply_status(&"bleed", 10.0, 1)
	assert(slime._tags.has(&"bleed"), "Sangrado quedó activo")
	assert(slime._tags._active[&"bleed"]["stacks"] == 3, "Sangrado apila (3 stacks)")

	# --- Marcado: el próximo golpe se amplifica y consume el tag -----------
	slime.apply_status(&"marked", 10.0, 1)
	var health_before_hit: float = slime.current_health
	slime.take_damage(100.0)
	var marked_hit: float = health_before_hit - slime.current_health
	assert(marked_hit >= 149.0, "Marcado amplificó el golpe (%.0f ≥ 150)" % marked_hit)
	assert(not slime._tags.has(&"marked"), "Marcado se consumió al golpear")

	# --- Detonar: consume el tag y aplica daño extra ------------------------
	slime.apply_status(&"burn", 50.0, 1)
	var health_before_det: float = slime.current_health
	slime.detonate_status([&"burn"], 1)
	var det_damage: float = health_before_det - slime.current_health
	assert(det_damage >= 99.0, "detonar Quemado dañó ×2 (%.0f ≥ 100)" % det_damage)
	assert(not slime._tags.has(&"burn"), "el tag detonado se consumió")

	# --- Combo cruzado: detonar lo de OTRO jugador da bonus -----------------
	var solo: bool = slime._tags.apply(&"frozen", 40.0, 1)
	assert(solo, "frozen aplicado")
	var same_peer: float = slime._tags.detonate([&"frozen"], 1) # mismo peer: sin bonus
	slime._tags.apply(&"frozen", 40.0, 1)
	var cross_peer: float = slime._tags.detonate([&"frozen"], 2) # OTRO peer: ×1.25
	assert(cross_peer > same_peer, "el combo cruzado de party da más daño (%.0f > %.0f)" % [cross_peer, same_peer])

	# --- Un tag desconocido no rompe nada -----------------------------------
	slime.apply_status(&"no_existe", 10.0, 1)
	assert(not slime._tags.has(&"no_existe"), "tag desconocido se ignora")

	print("TAGS SMOKE OK")
	get_tree().quit(0)
