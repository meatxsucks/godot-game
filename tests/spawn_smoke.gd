## Smoke de E1.3: NetSpawn rutea enemigos/drops/proyectiles a los contenedores
## replicados del SpawnRoot (con props aplicadas ANTES del _ready y LootItem
## sobreviviendo el viaje serializado), y sin SpawnRoot cae al add_child
## clásico en el fallback_parent.
extends Node3D

func _ready() -> void:
	var spawn_root = load("res://scenes/levels/SpawnRoot.tscn").instantiate()
	add_child(spawn_root)

	# Enemigo: va al contenedor Enemies y su _ready ya vio las props.
	var slime = NetSpawn.enemy(load("res://scenes/enemies/Slime.tscn"),
		{"max_health": 55.0, "position": Vector3(2, 0, 2)}, self)
	assert(slime.get_parent() == spawn_root.get_node("Enemies"),
		"el enemigo cuelga del contenedor replicado")
	assert(slime.max_health == 55.0 and slime.current_health == 55.0,
		"las props llegan antes del _ready (current_health = max_health)")
	assert(slime.global_position.is_equal_approx(Vector3(2, 0, 2)),
		"la posición local al contenedor equivale a la global")

	# Drop: el LootItem viaja como to_save_dict y se reconstruye contra LootDB.
	var item := Loot.generate_random_item(3)
	var drop = NetSpawn.drop(load("res://scenes/loot/LootDrop.tscn"),
		item, Vector3(1, 0, 0), self)
	assert(drop.get_parent() == spawn_root.get_node("Drops"),
		"el drop cuelga del contenedor replicado")
	assert(drop.item != null and drop.item.display_name == item.display_name,
		"el LootItem sobrevive la serialización de spawn")

	# Loot instanciado por jugador (E1.7): drop con dueño ajeno = invisible
	# y sin colisión; drop mío (peer 1 offline) = normal; sin dueño = normal.
	var foreign = NetSpawn.drop(load("res://scenes/loot/LootDrop.tscn"),
		Loot.generate_random_item(1), Vector3(3, 0, 0), self, 2)
	assert(not foreign.visible and not foreign.monitoring,
		"el drop de OTRO jugador no se ve ni colisiona acá")
	var mine = NetSpawn.drop(load("res://scenes/loot/LootDrop.tscn"),
		Loot.generate_random_item(1), Vector3(4, 0, 0), self, 1)
	assert(mine.visible and mine.monitoring, "mi drop instanciado se ve y colisiona")
	assert(drop.visible and drop.monitoring, "el drop sin dueño (compartido) se ve")

	# Proyectil: transform completa vía props.
	var xform := Transform3D(Basis.looking_at(Vector3.RIGHT, Vector3.UP), Vector3(0, 0.55, 0))
	var bolt = NetSpawn.projectile(load("res://scenes/magic/Fireball.tscn"), {"transform": xform}, self)
	assert(bolt.get_parent() == spawn_root.get_node("Projectiles"),
		"el proyectil cuelga del contenedor replicado")
	assert(bolt.global_transform.origin.is_equal_approx(xform.origin),
		"el transform llega entero")

	# Sin SpawnRoot: fallback al parent clásico (tests y escenas sueltas).
	spawn_root.queue_free()
	remove_child(spawn_root)
	var loose = NetSpawn.enemy(load("res://scenes/enemies/Slime.tscn"),
		{"position": Vector3(5, 0, 5)}, self)
	assert(loose.get_parent() == self, "sin SpawnRoot, add_child al fallback")

	print("SPAWN SMOKE OK")
	get_tree().quit(0)
