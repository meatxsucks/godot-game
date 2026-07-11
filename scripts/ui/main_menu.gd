extends Control

@onready var btn_play: Button = $VBox/BtnPlay
@onready var btn_loot: Button = $VBox/BtnLoot
@onready var btn_quit: Button = $VBox/BtnQuit

## Co-op ENet local (E1.5). Construida por código para no tocar la escena;
## cuando entre GodotSteam esto se reemplaza por el lobby de Steam.
var _btn_host: Button
var _ip_edit: LineEdit
var _btn_join: Button
var _net_status: Label

func _ready() -> void:
	btn_play.pressed.connect(_on_play_pressed)
	btn_loot.pressed.connect(_on_loot_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)

	# Si venimos de una partida (retry/menú), soltar la sesión de red anterior.
	Net.close_connection()
	_build_coop_ui()
	Net.connection_succeeded.connect(_on_join_succeeded)
	Net.connection_failed.connect(_on_join_failed)

	# Asegurar que el primer botón tiene foco para usar teclado/mando
	btn_play.grab_focus()

func _build_coop_ui() -> void:
	var vbox: VBoxContainer = $VBox

	_btn_host = Button.new()
	_btn_host.text = tr("Co-op: hostear (LAN)")
	_btn_host.pressed.connect(_on_host_pressed)
	vbox.add_child(_btn_host)

	# Todo en vertical, como el resto del menú.
	_ip_edit = LineEdit.new()
	_ip_edit.text = "127.0.0.1"
	_ip_edit.placeholder_text = tr("IP del host")
	_ip_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_ip_edit)

	_btn_join = Button.new()
	_btn_join.text = tr("Unirse")
	_btn_join.pressed.connect(_on_join_pressed)
	vbox.add_child(_btn_join)

	_net_status = Label.new()
	_net_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_net_status)

	# El Salir queda siempre último.
	vbox.move_child(btn_quit, vbox.get_child_count() - 1)

func _on_host_pressed() -> void:
	if Net.host_game() == OK:
		SceneManager.change_scene("res://scenes/ui/ClassSelect.tscn")
	else:
		_net_status.text = tr("No se pudo abrir el server (¿puerto ocupado?)")

func _on_join_pressed() -> void:
	if Net.join_game(_ip_edit.text.strip_edges()) == OK:
		_net_status.text = tr("Conectando…")
		_btn_join.disabled = true
	else:
		_net_status.text = tr("Dirección inválida")

func _on_join_succeeded() -> void:
	SceneManager.change_scene("res://scenes/ui/ClassSelect.tscn")

func _on_join_failed() -> void:
	Net.close_connection()
	_btn_join.disabled = false
	_net_status.text = tr("No se pudo conectar al host")

func _on_play_pressed() -> void:
	# Primero se elige clase (rol); la Arena se carga desde ahí.
	SceneManager.change_scene("res://scenes/ui/ClassSelect.tscn")

func _on_loot_pressed() -> void:
	SceneManager.change_scene("res://scenes/LootDemo.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
