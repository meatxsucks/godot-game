extends Control

@onready var btn_play: Button = $VBox/BtnPlay
@onready var btn_loot: Button = $VBox/BtnLoot
@onready var btn_quit: Button = $VBox/BtnQuit

## Co-op ENet local (E1.5). Un solo botón en el menú principal que abre un
## submenú aparte (así el menú no crece y tapa el título). Construido por
## código; cuando entre GodotSteam esto se reemplaza por el lobby de Steam.
var _coop_panel: Control
var _btn_host: Button
var _ip_edit: LineEdit
var _btn_join: Button
var _net_status: Label
## Lista de lobbies de Steam encontrados (botones para unirse).
var _lobby_list: VBoxContainer

func _ready() -> void:
	btn_play.pressed.connect(_on_play_pressed)
	btn_loot.pressed.connect(_on_loot_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)

	# Si venimos de una partida (retry/menú), soltar la sesión de red anterior
	# y apagar el poder en prueba del Laboratorio (solo aplica desde el lab).
	Net.close_connection()
	AbilityLab.test_ability_id = &""
	_build_coop_ui()
	Net.connection_succeeded.connect(_on_join_succeeded)
	Net.connection_failed.connect(_on_join_failed)

	# Asegurar que el primer botón tiene foco para usar teclado/mando
	btn_play.grab_focus()

func _build_coop_ui() -> void:
	var vbox: VBoxContainer = $VBox

	# Menú principal: un solo botón que abre el submenú de LAN.
	var btn_coop := Button.new()
	btn_coop.text = tr("Co-op (LAN)")
	btn_coop.pressed.connect(_on_coop_pressed)
	vbox.add_child(btn_coop)

	var btn_lab := Button.new()
	btn_lab.text = tr("Laboratorio de poderes")
	btn_lab.pressed.connect(_on_lab_pressed)
	vbox.add_child(btn_lab)
	# El Salir queda siempre último.
	vbox.move_child(btn_quit, vbox.get_child_count() - 1)

	# Submenú co-op: pantalla aparte, centrada, oculta hasta que se abre.
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.visible = false
	add_child(center)
	_coop_panel = center

	var panel := PanelContainer.new()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(220, 0)
	box.add_theme_constant_override(&"separation", 8)
	panel.add_child(box)

	var title := Label.new()
	title.text = tr("Co-op")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	# --- Steam (solo si el cliente está corriendo) ---
	if Net.steam_active:
		var btn_steam_host := Button.new()
		btn_steam_host.text = tr("Hostear (Steam)")
		btn_steam_host.pressed.connect(_on_steam_host_pressed)
		box.add_child(btn_steam_host)

		var btn_steam_list := Button.new()
		btn_steam_list.text = tr("Buscar partidas (Steam)")
		btn_steam_list.pressed.connect(Net.request_steam_lobbies)
		box.add_child(btn_steam_list)

		_lobby_list = VBoxContainer.new()
		box.add_child(_lobby_list)

		Net.steam_lobby_created.connect(_on_steam_lobby_ready)
		Net.steam_lobby_list.connect(_on_steam_lobby_list)
		box.add_child(HSeparator.new())

	var lan_label := Label.new()
	lan_label.text = tr("LAN (IP directa)")
	lan_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(lan_label)

	_btn_host = Button.new()
	_btn_host.text = tr("Hostear (LAN)")
	_btn_host.pressed.connect(_on_host_pressed)
	box.add_child(_btn_host)

	_ip_edit = LineEdit.new()
	_ip_edit.text = "127.0.0.1"
	_ip_edit.placeholder_text = tr("IP del host")
	_ip_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_ip_edit)

	_btn_join = Button.new()
	_btn_join.text = tr("Unirse")
	_btn_join.pressed.connect(_on_join_pressed)
	box.add_child(_btn_join)

	_net_status = Label.new()
	_net_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_net_status)

	var btn_back := Button.new()
	btn_back.text = tr("Volver")
	btn_back.pressed.connect(_on_coop_back_pressed)
	box.add_child(btn_back)

func _on_coop_pressed() -> void:
	$VBox.visible = false
	_coop_panel.visible = true
	_btn_host.grab_focus()

func _on_coop_back_pressed() -> void:
	Net.close_connection() # cancela un intento de conexión colgado
	_btn_join.disabled = false
	_net_status.text = ""
	_coop_panel.visible = false
	$VBox.visible = true
	btn_play.grab_focus()

func _on_host_pressed() -> void:
	if Net.host_game() == OK:
		SceneManager.change_scene("res://scenes/ui/LobbyRoom.tscn")
	else:
		_net_status.text = tr("No se pudo abrir el server (¿puerto ocupado?)")

func _on_join_pressed() -> void:
	if Net.join_game(_ip_edit.text.strip_edges()) == OK:
		_net_status.text = tr("Conectando…")
		_btn_join.disabled = true
	else:
		_net_status.text = tr("Dirección inválida")

func _on_join_succeeded() -> void:
	SceneManager.change_scene("res://scenes/ui/LobbyRoom.tscn")

# --- Steam ------------------------------------------------------------------

func _on_steam_host_pressed() -> void:
	_net_status.text = tr("Creando lobby de Steam…")
	Net.host_steam_game() # asíncrono → steam_lobby_created / connection_failed

func _on_steam_lobby_ready(_lobby_id: int) -> void:
	SceneManager.change_scene("res://scenes/ui/LobbyRoom.tscn")

func _on_steam_lobby_list(lobbies: Array) -> void:
	for child in _lobby_list.get_children():
		child.queue_free()
	if lobbies.is_empty():
		_net_status.text = tr("No hay partidas de Steam abiertas")
		return
	_net_status.text = ""
	for lobby_id: int in lobbies:
		var btn := Button.new()
		btn.text = "%s  (%s)" % [Net.lobby_name(lobby_id), Net.lobby_players(lobby_id)]
		btn.pressed.connect(_on_steam_join_pressed.bind(lobby_id))
		_lobby_list.add_child(btn)

func _on_steam_join_pressed(lobby_id: int) -> void:
	if Net.join_steam_game(lobby_id) == OK:
		_net_status.text = tr("Conectando…")
	else:
		_net_status.text = tr("No se pudo unir al lobby")

func _on_join_failed() -> void:
	Net.close_connection()
	_btn_join.disabled = false
	_net_status.text = tr("No se pudo conectar al host")

func _on_lab_pressed() -> void:
	SceneManager.change_scene("res://scenes/ui/AbilityLab.tscn")

func _on_play_pressed() -> void:
	# Primero se elige clase (rol); la Arena se carga desde ahí.
	SceneManager.change_scene("res://scenes/ui/ClassSelect.tscn")

func _on_loot_pressed() -> void:
	SceneManager.change_scene("res://scenes/LootDemo.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
