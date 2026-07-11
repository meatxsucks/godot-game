## Smoke de E1.5: sin red (modo single-player), el orquestador de Arena
## spawnea UN player local (autoridad 1, clase seleccionada, bajo el
## contenedor replicado), y cámara y HUD terminan colgados de él aunque
## nazca unos frames después que ellos.
extends Node

func _ready() -> void:
	Game.selected_class = &"warrior"
	var arena: Node3D = load("res://scenes/levels/Arena.tscn").instantiate()
	add_child(arena)

	for i in 30:
		await get_tree().physics_frame

	var players := get_tree().get_nodes_in_group("player")
	assert(players.size() == 1, "offline se spawnea exactamente un player")
	var player: Node3D = players[0]
	assert(player.get_multiplayer_authority() == 1, "el player local es del peer 1")
	assert(player.is_multiplayer_authority(), "y tiene autoridad local")
	assert(player.player_class == &"warrior", "con la clase seleccionada")
	assert(player.name == "Player1", "nombre determinístico por peer")
	assert(player.get_parent() == arena.get_node("SpawnRoot/Players"),
		"cuelga del contenedor replicado de players")
	assert(player.global_position.distance_to(Vector3(0, 0, 24.5)) < 1.0,
		"aparece en el punto de spawn del nivel")

	var camera := arena.get_node("CameraRig")
	assert(camera.target == player, "la cámara siguió al player local")
	var hud := arena.get_node("HUD")
	assert(hud.player == player, "el HUD se colgó del player local")

	print("LOBBY SMOKE OK")
	get_tree().quit(0)
