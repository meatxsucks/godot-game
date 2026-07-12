## Sala de espera del co-op (LAN y Steam): después de hostear/unirse TODOS
## pasan por acá. Cada peer anuncia su nombre por RPC — verse en la lista
## significa que la conexión funciona en los dos sentidos. Solo el host
## puede comenzar: manda a todos a elegir clase y cierra el lobby de Steam
## a nuevos miembros (un late-join se perdería lo ya spawneado).
extends Control

@onready var status: Label = %Status
@onready var player_list: VBoxContainer = %PlayerList
@onready var btn_start: Button = %BtnStart
@onready var btn_leave: Button = %BtnLeave

## peer_id -> nombre anunciado.
var _names: Dictionary = {}

func _ready() -> void:
	btn_start.visible = multiplayer.is_server()
	btn_start.pressed.connect(_on_start_pressed)
	btn_leave.pressed.connect(_leave)

	Net.player_connected.connect(_on_player_connected)
	Net.player_disconnected.connect(_on_player_disconnected)
	Net.server_disconnected.connect(_leave)

	_names[multiplayer.get_unique_id()] = Net.local_display_name()
	# Anunciarse a los que ya están (el que entra último también los ve:
	# ellos se re-anuncian cuando este peer conecta).
	_announce_name.rpc(Net.local_display_name())
	_refresh()
	if multiplayer.is_server():
		btn_start.grab_focus()
	else:
		btn_leave.grab_focus()

func _on_player_connected(peer_id: int) -> void:
	# Peer nuevo: mandarle nuestro nombre directo (el rpc() general de
	# _ready fue antes de que existiera).
	_announce_name.rpc_id(peer_id, Net.local_display_name())
	_refresh()

func _on_player_disconnected(peer_id: int) -> void:
	_names.erase(peer_id)
	_refresh()

@rpc("any_peer", "reliable")
func _announce_name(display_name: String) -> void:
	var peer_id := multiplayer.get_remote_sender_id()
	if peer_id == 0:
		peer_id = multiplayer.get_unique_id()
	_names[peer_id] = display_name
	_refresh()

func _refresh() -> void:
	for child in player_list.get_children():
		child.queue_free()
	var ids := _names.keys()
	ids.sort()
	for peer_id: int in ids:
		var row := Label.new()
		var tag := tr(" (host)") if peer_id == 1 else ""
		var you := tr(" — tú") if peer_id == multiplayer.get_unique_id() else ""
		row.text = "•  %s%s%s" % [_names[peer_id], tag, you]
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		player_list.add_child(row)

	var total := _names.size()
	if multiplayer.is_server():
		if total < 2:
			status.text = tr("Esperando jugadores… (pueden unirse %d más)") % (Net.MAX_PLAYERS - total)
		else:
			status.text = tr("%d jugadores conectados. ¡Listos para empezar!") % total
	else:
		status.text = tr("Conectado. Esperando a que el host comience…")

func _on_start_pressed() -> void:
	Net.lock_steam_lobby()
	_start_game.rpc()

## La manda el host a todos (incluido él): cada peer va a elegir su clase.
## La Arena espera a que TODOS hayan cargado antes de spawnear players y
## oleadas, así que no importa quién elija más rápido.
@rpc("authority", "call_local", "reliable")
func _start_game() -> void:
	SceneManager.change_scene("res://scenes/ui/ClassSelect.tscn")

func _leave() -> void:
	Net.close_connection()
	SceneManager.change_scene("res://scenes/ui/MainMenu.tscn")
