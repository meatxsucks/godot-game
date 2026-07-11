## Orquestador del nivel (E1.5): spawnea un player por peer vía NetSpawn.
## El host se spawnea al cargar; cada cliente, recién cuando SU nivel está
## cargado, registra su clase por RPC y el host le spawnea el player (así
## nunca llegan spawns a un cliente sin SpawnRoot). Offline funciona igual:
## el "host" local spawnea al único jugador.
extends Node3D

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
## Donde vivía el Player estático de la escena; los siguientes jugadores
## aparecen desplazados para no encimarse.
const SPAWN_POS := Vector3(0, 0, 24.5)

func _ready() -> void:
	if multiplayer.is_server():
		Net.player_class_registered.connect(_on_class_registered)
		Net.player_disconnected.connect(_on_player_left)
		_spawn_player(1, Game.selected_class)
		# Clientes que registraron su clase antes de que cargara este nivel.
		for peer_id: int in Net.player_classes:
			if peer_id != 1:
				_spawn_player(peer_id, Net.player_classes[peer_id])
	else:
		Net.register_player_class.rpc_id(1, Game.selected_class)

func _on_class_registered(peer_id: int, cls: StringName) -> void:
	_spawn_player(peer_id, cls)

func _on_player_left(peer_id: int) -> void:
	var player := _find_player(peer_id)
	if player:
		player.queue_free()

func _spawn_player(peer_id: int, cls: StringName) -> void:
	if _find_player(peer_id):
		return
	var count := get_tree().get_nodes_in_group("player").size()
	NetSpawn.player(PLAYER_SCENE, peer_id, {
		"name": "Player%d" % peer_id,
		"player_class": cls,
		"position": SPAWN_POS + Vector3(2.0 * count, 0, 0),
	}, self)

func _find_player(peer_id: int) -> Node:
	for node in get_tree().get_nodes_in_group("player"):
		if node.get_multiplayer_authority() == peer_id:
			return node
	return null
