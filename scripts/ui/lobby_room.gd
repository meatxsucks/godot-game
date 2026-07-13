## Sala de espera del co-op (LAN y Steam), v2 (2026-07-12): se entra CON la
## clase ya elegida (flujo Clase → Sala → Arena, patrón lobby estándar).
## Cada peer anuncia nombre + clase por RPC y además PIDE la info de los que
## ya estaban (pull) — así el orden de carga no importa y todos ven la misma
## lista. El host comienza cuando todos eligieron: manda la SEED del mundo
## (mismo escenario procedural para todos) y todos cargan la Arena directo.
extends Control

@onready var status: Label = %Status
@onready var player_list: VBoxContainer = %PlayerList
@onready var btn_start: Button = %BtnStart
@onready var btn_class: Button = %BtnClass
@onready var btn_leave: Button = %BtnLeave

## peer_id -> {"name": String, "cls": StringName} anunciado.
var _infos: Dictionary = {}

func _ready() -> void:
	btn_start.visible = multiplayer.is_server()
	btn_start.pressed.connect(_on_start_pressed)
	btn_class.pressed.connect(_on_class_pressed)
	btn_leave.pressed.connect(_leave)

	Net.player_connected.connect(_on_peer_changed)
	Net.player_disconnected.connect(_on_player_disconnected)
	Net.server_disconnected.connect(_leave)

	_infos[multiplayer.get_unique_id()] = {
		"name": Net.local_display_name(), "cls": Game.selected_class}
	# Push a los presentes + pull de los que ya estaban: cubre ambos órdenes
	# de carga (antes el anuncio del host se perdía si el cliente aún no
	# había cargado la sala).
	_announce_info.rpc(Net.local_display_name(), Game.selected_class)
	_request_infos.rpc()
	_refresh()
	if multiplayer.is_server():
		btn_start.grab_focus()
	else:
		btn_leave.grab_focus()

func _on_peer_changed(_peer_id: int) -> void:
	_refresh() # aparece como "eligiendo clase…" hasta que anuncie

func _on_player_disconnected(peer_id: int) -> void:
	_infos.erase(peer_id)
	_refresh()

@rpc("any_peer", "reliable")
func _announce_info(display_name: String, cls: StringName) -> void:
	var peer_id := multiplayer.get_remote_sender_id()
	if peer_id == 0:
		peer_id = multiplayer.get_unique_id()
	_infos[peer_id] = {"name": display_name, "cls": cls}
	_refresh()

## Un peer que entra pide la info de los que ya estaban en la sala.
@rpc("any_peer", "reliable")
func _request_infos() -> void:
	var sender := multiplayer.get_remote_sender_id()
	if sender != 0:
		_announce_info.rpc_id(sender, Net.local_display_name(), Game.selected_class)

func _refresh() -> void:
	for child in player_list.get_children():
		child.queue_free()

	# Todos los peers de la sesión: los anunciados con nombre y clase, los
	# que siguen eligiendo clase como pendientes.
	var ids: Array = _infos.keys()
	for peer_id: int in multiplayer.get_peers():
		if not ids.has(peer_id):
			ids.append(peer_id)
	ids.sort()

	var missing := 0
	for peer_id: int in ids:
		var row := Label.new()
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if _infos.has(peer_id):
			var info: Dictionary = _infos[peer_id]
			var cls_name: String = tr(Game.class_def(info["cls"]).display_name)
			var tag := tr(" (host)") if peer_id == 1 else ""
			var you := tr(" — tú") if peer_id == multiplayer.get_unique_id() else ""
			row.text = "•  %s — %s%s%s" % [info["name"], cls_name, tag, you]
		else:
			missing += 1
			row.text = tr("•  Jugador %d — eligiendo clase…") % peer_id
			row.modulate = Color(1, 1, 1, 0.6)
		player_list.add_child(row)

	var total := ids.size()
	if multiplayer.is_server():
		btn_start.disabled = missing > 0
		if missing > 0:
			status.text = tr("Esperando a que todos elijan clase…")
		elif total < 2:
			status.text = tr("Esperando jugadores… (pueden unirse %d más)") % (Net.MAX_PLAYERS - total)
		else:
			status.text = tr("%d jugadores conectados. ¡Listos para empezar!") % total
	else:
		status.text = tr("Conectado. Esperando a que el host comience…")

func _on_class_pressed() -> void:
	# Volver a elegir clase SIN cortar la sesión; al elegir se regresa acá.
	# Retirar nuestro anuncio: mientras elegimos, el host nos ve como
	# pendientes y no puede comenzar sin nosotros.
	_retract_info.rpc()
	SceneManager.change_scene("res://scenes/ui/ClassSelect.tscn")

@rpc("any_peer", "reliable")
func _retract_info() -> void:
	_infos.erase(multiplayer.get_remote_sender_id())
	_refresh()

func _on_start_pressed() -> void:
	Net.lock_steam_lobby()
	# La seed viaja con el arranque: todos generan el MISMO escenario
	# procedural (patrón estándar: el host reparte la semilla).
	_start_game.rpc(randi())

## La manda el host a todos (incluido él): cada peer carga la Arena directo
## con su clase ya elegida. La Arena espera a que TODOS carguen antes de
## spawnear players y oleadas.
@rpc("authority", "call_local", "reliable")
func _start_game(world_seed: int) -> void:
	Game.world_seed = world_seed
	SceneManager.change_scene("res://scenes/levels/Arena.tscn")

func _leave() -> void:
	Net.close_connection()
	SceneManager.change_scene("res://scenes/ui/MainMenu.tscn")
