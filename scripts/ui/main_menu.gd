extends Control

@onready var btn_play: Button = $VBox/BtnPlay
@onready var btn_loot: Button = $VBox/BtnLoot
@onready var btn_quit: Button = $VBox/BtnQuit

func _ready() -> void:
	btn_play.pressed.connect(_on_play_pressed)
	btn_loot.pressed.connect(_on_loot_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)
	
	# Asegurar que el primer botón tiene foco para usar teclado/mando
	btn_play.grab_focus()

func _on_play_pressed() -> void:
	# Primero se elige clase (rol); la Arena se carga desde ahí.
	SceneManager.change_scene("res://scenes/ui/ClassSelect.tscn")

func _on_loot_pressed() -> void:
	SceneManager.change_scene("res://scenes/LootDemo.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
