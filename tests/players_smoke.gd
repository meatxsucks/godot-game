## Smoke de E1.2 (co-op): con 2 jugadores en escena los enemigos targetean
## al MÁS CERCANO, los muertos no se targetean, y el melee golpea al que
## persigue — nada depende de get_first_node_in_group("player").
extends Node3D


## Doble de jugador: lo mínimo que los enemigos esperan del grupo "player".
class DummyPlayer extends Node3D:
	var alive := true
	var damage_taken := 0.0

	func _ready() -> void:
		add_to_group("player")

	func is_alive() -> bool:
		return alive

	func take_damage(amount: float, _is_crit: bool = false) -> void:
		damage_taken += amount


func _ready() -> void:
	# Piso para que el slime no caiga al vacío.
	var floor_body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(40, 1, 40)
	collision.shape = shape
	floor_body.add_child(collision)
	add_child(floor_body)
	floor_body.global_position = Vector3(0, -0.5, 0)

	var near_player := DummyPlayer.new()
	add_child(near_player)
	near_player.global_position = Vector3(3, 0, 0)

	var far_player := DummyPlayer.new()
	add_child(far_player)
	far_player.global_position = Vector3(-8, 0, 0)

	# Helper: el más cercano gana; los muertos no cuentan.
	assert(Players.nearest(get_tree(), Vector3.ZERO) == near_player,
		"nearest devuelve el jugador más cercano")
	near_player.alive = false
	assert(Players.nearest(get_tree(), Vector3.ZERO) == far_player,
		"un jugador muerto no se targetea")
	near_player.alive = true

	# Enemigo real: debe perseguir (y golpear) al jugador cercano, no al lejano.
	var slime = load("res://scenes/enemies/Slime.tscn").instantiate()
	add_child(slime)
	slime.global_position = Vector3.ZERO
	var start_x: float = slime.global_position.x

	for i in 120:
		await get_tree().physics_frame

	assert(slime.global_position.x > start_x + 0.5,
		"el slime se mueve hacia el jugador más cercano (+x)")
	assert(near_player.damage_taken > 0.0,
		"el melee golpea al jugador que persigue")
	assert(far_player.damage_taken == 0.0,
		"el jugador lejano no recibe golpes")

	print("PLAYERS SMOKE OK")
	get_tree().quit(0)
