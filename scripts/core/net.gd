## Autoload "Net": transporte de red para co-op (E1.1/E1.5). Dos vías, mismo
## juego después de conectar (señales, RPCs y spawners no distinguen):
## - LAN: host_game()/join_game(ip) sobre ENetMultiplayerPeer.
## - Steam: host_steam_game()/join_steam_game(lobby_id) sobre
##   SteamMultiplayerPeer + lobby (GodotSteam GDExtension), si steam_active.
extends Node

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal server_created
signal connection_succeeded
signal connection_failed
signal server_disconnected

const DEFAULT_PORT := 7777
const MAX_PLAYERS := 4

## AppID de pruebas de Valve (Spacewar). Cambiar cuando exista el AppID real.
const STEAM_APP_ID := 480
## Tag para filtrar NUESTROS lobbies en la lista pública de Spacewar.
const LOBBY_GAME_TAG := "demake-mago-arpg"

## true si Steam inició OK al arrancar (cliente corriendo + extensión cargada).
var steam_active := false

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	_init_steam()

func host_game(port: int = DEFAULT_PORT) -> Error:
	var peer := _create_peer()
	var err: Error = peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	server_created.emit()
	return OK

func join_game(address: String, port: int = DEFAULT_PORT) -> Error:
	var peer := _create_peer()
	var err: Error = peer.create_client(address, port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	return OK

func close_connection() -> void:
	player_classes.clear()
	if is_online():
		multiplayer.multiplayer_peer.close()
	# NUNCA dejar el peer en null: sin peer, multiplayer.is_server() deja de
	# dar true y el modo offline se rompe (la Arena no spawnea al player).
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()

# --- Registro de jugadores (E1.5) ----------------------------------------------

signal player_class_registered(peer_id: int, cls: StringName)

## Clase elegida por cada peer (peer_id -> StringName). Solo lo llena el host:
## cada cliente la registra por RPC recién al cargar el nivel (así el host no
## le spawnea el player antes de que exista su SpawnRoot).
var player_classes: Dictionary = {}

@rpc("any_peer", "reliable")
func register_player_class(cls: StringName) -> void:
	if not multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	if peer_id == 0: # llamada local (host registrándose a sí mismo)
		peer_id = 1
	player_classes[peer_id] = cls
	player_class_registered.emit(peer_id, cls)

func is_host() -> bool:
	return multiplayer.multiplayer_peer != null and multiplayer.is_server()

## true si hay una sesión de red real (co-op). Offline/single-player = false.
func is_online() -> bool:
	return multiplayer.multiplayer_peer != null \
		and not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer)

func _create_peer() -> MultiplayerPeer:
	return ENetMultiplayerPeer.new()

# --- Steam (E1.5): lobby + transporte SteamMultiplayerPeer -----------------
# El resto del juego no distingue transportes: una vez seteado el
# multiplayer_peer, señales, RPCs y spawners funcionan igual que con ENet.

signal steam_lobby_created(lobby_id: int)
signal steam_lobby_list(lobbies: Array)

func _init_steam() -> void:
	if not ClassDB.class_exists("SteamMultiplayerPeer"):
		return # sin GDExtension (no debería pasar: viaja en el repo)
	# embed_callbacks=true: GodotSteam corre los callbacks solo, sin
	# necesidad de llamar Steam.run_callbacks() por frame.
	var result: Dictionary = Steam.steamInitEx(STEAM_APP_ID, true)
	steam_active = int(result.get("status", -1)) == Steam.STEAM_API_INIT_RESULT_OK
	if not steam_active:
		print("[Net] Steam no disponible (%s) — co-op solo por LAN" % result.get("verbal", "?"))
		return
	Steam.lobby_created.connect(_on_steam_lobby_created)
	Steam.lobby_match_list.connect(_on_steam_lobby_match_list)
	print("[Net] Steam OK como %s" % Steam.getPersonaName())

## Hostear por Steam. Asíncrono: crea el lobby y al confirmarse se arma el
## peer y se emite steam_lobby_created (o connection_failed si falló).
func host_steam_game() -> void:
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, MAX_PLAYERS)

func _on_steam_lobby_created(result: int, lobby_id: int) -> void:
	if result != Steam.RESULT_OK:
		connection_failed.emit()
		return
	# Metadata para que la lista de partidas filtre solo NUESTRO juego
	# (el AppID 480 es compartido por todo el mundo en desarrollo).
	Steam.setLobbyData(lobby_id, "game", LOBBY_GAME_TAG)
	Steam.setLobbyData(lobby_id, "name", "%s" % Steam.getPersonaName())
	var peer := SteamMultiplayerPeer.new()
	if peer.host_with_lobby(lobby_id) != OK:
		connection_failed.emit()
		return
	multiplayer.multiplayer_peer = peer
	server_created.emit()
	steam_lobby_created.emit(lobby_id)

## Unirse a un lobby de Steam (el peer maneja join + conexión al host).
func join_steam_game(lobby_id: int) -> Error:
	var peer := SteamMultiplayerPeer.new()
	var err: Error = peer.connect_to_lobby(lobby_id)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	return OK

## Pide la lista de partidas nuestras. Asíncrono → steam_lobby_list emite
## Array de lobby_ids (usar lobby_name/lobby_players para mostrar).
func request_steam_lobbies() -> void:
	Steam.addRequestLobbyListStringFilter("game", LOBBY_GAME_TAG, Steam.LOBBY_COMPARISON_EQUAL)
	Steam.requestLobbyList()

func _on_steam_lobby_match_list(lobbies: Array) -> void:
	steam_lobby_list.emit(lobbies)

func lobby_name(lobby_id: int) -> String:
	var name := Steam.getLobbyData(lobby_id, "name")
	return name if name != "" else str(lobby_id)

func lobby_players(lobby_id: int) -> String:
	return "%d/%d" % [Steam.getNumLobbyMembers(lobby_id), Steam.getLobbyMemberLimit(lobby_id)]

func _on_peer_connected(id: int) -> void:
	player_connected.emit(id)

func _on_peer_disconnected(id: int) -> void:
	player_classes.erase(id)
	player_disconnected.emit(id)

func _on_connected_to_server() -> void:
	connection_succeeded.emit()

func _on_connection_failed() -> void:
	connection_failed.emit()

func _on_server_disconnected() -> void:
	server_disconnected.emit()
