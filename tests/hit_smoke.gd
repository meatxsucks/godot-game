## Test de regresión: los proyectiles DEBEN golpear a slimes de todos los
## tamaños (bug histórico: volaban a 1.2m — la altura de la varita — y
## pasaban por encima de los enemigos chicos).
extends Node3D

func _ready() -> void:
	# Piso para que los slimes no caigan al vacío.
	var floor_body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(30, 1, 30)
	collision.shape = shape
	floor_body.add_child(collision)
	add_child(floor_body)
	floor_body.global_position = Vector3(0, -0.5, 0)

	# Slime normal (0.9m) y slime rápido (0.75m, el peor caso).
	var normal = load("res://scenes/enemies/Slime.tscn").instantiate()
	normal.position = Vector3(0, 0, 0)
	add_child(normal)

	var fast = load("res://scenes/enemies/Slime.tscn").instantiate()
	fast.size_scale = 0.75
	fast.max_health = 16.0
	fast.position = Vector3(6, 0, 0)
	add_child(fast)

	# Una fireball hacia cada uno, a la altura de vuelo real de las habilidades.
	for x in [0.0, 6.0]:
		var fireball = load("res://scenes/magic/Fireball.tscn").instantiate()
		fireball.position = Vector3(x, Ability.PROJECTILE_HEIGHT, 5)
		add_child(fireball)
		fireball.setup(5.0, null, false)

	var normal_start: float = normal.current_health
	var fast_start: float = fast.current_health

	for i in 45:
		await get_tree().physics_frame

	assert(normal.current_health < normal_start, "la fireball golpea al slime normal")
	assert(fast.current_health < fast_start, "la fireball golpea al slime rápido (chico)")
	print("HIT SMOKE OK")
	get_tree().quit(0)
