## Smoke de E1.4: Slime/Boss/Player traen MultiplayerSynchronizer con las
## propiedades esperadas, y el gating de autoridad funciona — una réplica
## (autoridad de otro peer) no corre IA/física ni acepta daño local, pero
## anticipa la muerte cuando la vida sincronizada llega a 0; con autoridad
## local todo se comporta como siempre.
extends Node3D


class DummyPlayer extends Node3D:
	func _ready() -> void:
		add_to_group("player")

	func is_alive() -> bool:
		return true

	func take_damage(_amount: float, _is_crit: bool = false) -> void:
		pass


func _ready() -> void:
	# Piso para la física del slime con autoridad local.
	var floor_body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(40, 1, 40)
	collision.shape = shape
	floor_body.add_child(collision)
	add_child(floor_body)
	floor_body.global_position = Vector3(0, -0.5, 0)

	# 1) Las escenas replicables declaran su Sync con las props esperadas.
	var expected := {
		"res://scenes/enemies/Slime.tscn": [".:position", ".:rotation", ".:current_health"],
		"res://scenes/enemies/Boss.tscn": [".:position", ".:rotation", ".:current_health"],
		"res://scenes/player/Player.tscn": [".:position", "Visual:rotation"],
	}
	for scene_path: String in expected:
		var node: Node = load(scene_path).instantiate()
		var sync := node.get_node_or_null("Sync") as MultiplayerSynchronizer
		assert(sync != null, "%s tiene MultiplayerSynchronizer" % scene_path)
		var props: Array = sync.replication_config.get_properties()
		for prop: String in expected[scene_path]:
			assert(props.has(NodePath(prop)), "%s sincroniza %s" % [scene_path, prop])
		node.free()

	var dummy := DummyPlayer.new()
	add_child(dummy)
	dummy.global_position = Vector3(4, 0, 0)

	# 2) Réplica (autoridad de otro peer): sin IA, sin física, sin daño local.
	var replica = load("res://scenes/enemies/Slime.tscn").instantiate()
	replica.set_multiplayer_authority(2)
	add_child(replica)
	replica.global_position = Vector3.ZERO
	var hp: float = replica.current_health
	replica.take_damage(10.0)
	assert(replica.current_health == hp, "réplica: take_damage no aplica")
	var start: Vector3 = replica.global_position
	for i in 30:
		await get_tree().physics_frame
	assert(replica.global_position.distance_to(start) < 0.1,
		"réplica: no persigue ni le afecta la gravedad")

	# Muerte anticipada: la vida "sincronizada" llega a 0 y la réplica lo nota.
	replica.current_health = 0.0
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert(replica._dying, "réplica: anticipa la muerte al ver vida 0")

	# 3) Autoridad local (host/single-player): IA y daño como siempre.
	var host_slime = load("res://scenes/enemies/Slime.tscn").instantiate()
	add_child(host_slime)
	host_slime.global_position = Vector3.ZERO
	host_slime.take_damage(5.0)
	assert(host_slime.current_health == host_slime.max_health - 5.0,
		"host: take_damage aplica")
	for i in 45:
		await get_tree().physics_frame
	assert(host_slime.global_position.x > 0.3, "host: la IA persigue al jugador")

	# 4) Player réplica: ni input ni física local (queda donde el sync lo deje).
	var puppet = load("res://scenes/player/Player.tscn").instantiate()
	puppet.set_multiplayer_authority(2)
	add_child(puppet)
	puppet.global_position = Vector3(-12, 0, 0)
	for i in 10:
		await get_tree().physics_frame
	assert(puppet.global_position.is_equal_approx(Vector3(-12, 0, 0)),
		"réplica de player: sin movimiento local")

	print("SYNC SMOKE OK")
	get_tree().quit(0)
