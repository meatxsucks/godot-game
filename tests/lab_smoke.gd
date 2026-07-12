## Smoke del Laboratorio de Poderes: el ejemplo del repo carga y valida, un
## spec malicioso queda saneado (clamps/whitelists), la DataAbility castea de
## verdad en una Arena offline y el slot Q queda ocupado por el poder en
## prueba.
extends Node

func _ready() -> void:
	# El ejemplo del repo cargó al arrancar el autoload.
	assert(AbilityLab.specs.has(&"lab_anillo_de_chispas"), "el ejemplo del repo carga")

	# Un spec crudo (como el que devolvería la IA) queda saneado.
	var spec: Dictionary = AbilityLab.validate({
		"name": "Prueba Rota",
		"element": "no-existe",
		"behavior": "hackear",
		"template": "../../etc/passwd",
		"cooldown": 9999.0,
		"damage_mult": 50.0,
		"count": 100,
		"props": {"speed": 9999.0, "position": "no-permitida", "pierces": true},
	})
	assert(spec["id"].begins_with("lab_"), "el id se genera con prefijo lab_")
	assert(spec["element"] == "fire", "elemento inválido cae al default")
	assert(spec["behavior"] == "projectile", "behavior inválido cae al default")
	assert(spec["template"] == "fireball", "template inválido cae al default")
	assert(spec["cooldown"] <= 15.0, "cooldown clampeado")
	assert(spec["damage_mult"] <= 3.0, "daño clampeado")
	assert(spec["count"] <= 8, "count clampeado")
	assert(not spec["props"].has("position"), "props fuera de la whitelist se descartan")
	assert(spec["props"]["speed"] <= 30.0, "props numéricas clampeadas")
	assert(spec["props"]["pierces"] is bool, "props booleanas pasan como bool")

	# Con un poder en prueba, el player lo equipa en el slot Q (índice 3).
	AbilityLab.test_ability_id = &"lab_anillo_de_chispas"
	Game.selected_class = &"mage"
	Net.close_connection()
	var arena: Node3D = load("res://scenes/levels/Arena.tscn").instantiate()
	add_child(arena)
	for i in 30:
		await get_tree().physics_frame

	var player: Node = get_tree().get_first_node_in_group("player")
	assert(player != null, "hay player en la arena")
	var ability: Ability = player.get_ability(3)
	assert(ability is DataAbility, "el slot Q tiene el poder del lab")
	assert(ability.display_name == "Anillo de Chispas", "con su nombre")

	# Castear de verdad: spawnea proyectiles (el abanico entra al árbol).
	player.stats.mana = 100.0
	var before := _count_projectiles(arena)
	assert(ability.execute(player), "el poder castea")
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert(_count_projectiles(arena) > before, "el casteo spawneó proyectiles")

	AbilityLab.test_ability_id = &""
	print("LAB SMOKE OK")
	get_tree().quit(0)

func _count_projectiles(arena: Node) -> int:
	return arena.get_node("SpawnRoot/Projectiles").get_child_count()
