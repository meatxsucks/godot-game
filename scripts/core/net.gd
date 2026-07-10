## Autoload "Net": transporte de red para co-op (E1.1). Hoy usa
## ENetMultiplayerPeer (IP directa, sirve para LAN/testing local sin
## dependencias). El swap a SteamMultiplayerPeer queda aislado en
## _create_steam_peer(): cuando el addon de GodotSteam esté instalado
## (addons/godotsteam/), alcanza con implementarlo ahí y poner use_steam=true;
## el resto del código (host_game/join_game/señales) no cambia.
extends Node

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal server_created
signal connection_succeeded
signal connection_failed
signal server_disconnected

const DEFAULT_PORT := 7777
const MAX_PLAYERS := 4

## true cuando GodotSteam esté instalado y se decida usarlo como transporte.
var use_steam := false

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func host_game(port: int = DEFAULT_PORT) -> Error:
	var peer := _create_peer()
	var err := peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	server_created.emit()
	return OK

func join_game(address: String, port: int = DEFAULT_PORT) -> Error:
	var peer := _create_peer()
	var err := peer.create_client(address, port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	return OK

func close_connection() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null

func is_host() -> bool:
	return multiplayer.multiplayer_peer != null and multiplayer.is_server()

func _create_peer() -> MultiplayerPeer:
	if use_steam:
		return _create_steam_peer()
	return ENetMultiplayerPeer.new()

func _create_steam_peer() -> MultiplayerPeer:
	push_error("Net: use_steam=true pero GodotSteam no está instalado (falta addons/godotsteam). Instalá el GDExtension o volvé a use_steam=false.")
	return ENetMultiplayerPeer.new()

func _on_peer_connected(id: int) -> void:
	player_connected.emit(id)

func _on_peer_disconnected(id: int) -> void:
	player_disconnected.emit(id)

func _on_connected_to_server() -> void:
	connection_succeeded.emit()

func _on_connection_failed() -> void:
	connection_failed.emit()

func _on_server_disconnected() -> void:
	server_disconnected.emit()
