extends Control

@onready var generate_btn: Button = $VBox/TopBar/GenerateBtn
@onready var level_spinbox: SpinBox = $VBox/TopBar/LevelSpinBox
@onready var output_text: RichTextLabel = $VBox/OutputText

func _ready() -> void:
	generate_btn.pressed.connect(_on_generate_pressed)
	# Generar un ítem al iniciar para no ver pantalla vacía
	_on_generate_pressed()

func _on_generate_pressed() -> void:
	var level = int(level_spinbox.value)
	var item = Loot.generate_random_item(level)
	
	# Agregamos los ítems nuevos arriba para mantener un historial visual
	var current_text = output_text.text
	var new_text = item.to_bbcode()
	
	if current_text != "Loot will appear here." and not current_text.is_empty():
		output_text.text = new_text + "\n\n------------------------\n\n" + current_text
	else:
		output_text.text = new_text
