extends Control

@onready var generate_btn: Button = $VBox/TopBar/GenerateBtn
@onready var level_spinbox: SpinBox = $VBox/TopBar/LevelSpinBox
@onready var output_text: RichTextLabel = $VBox/OutputText

## false hasta el primer ítem generado (evita comparar contra el texto
## placeholder para detectar "primera vez", que se rompe si se traduce).
var _has_item := false

func _ready() -> void:
	generate_btn.pressed.connect(_on_generate_pressed)
	# Generar un ítem al iniciar para no ver pantalla vacía
	_on_generate_pressed()

func _on_generate_pressed() -> void:
	var level = int(level_spinbox.value)
	var item = Loot.generate_random_item(level)

	# Agregamos los ítems nuevos arriba para mantener un historial visual
	var new_text = item.to_bbcode()
	if _has_item:
		output_text.text = new_text + "\n\n------------------------\n\n" + output_text.text
	else:
		output_text.text = new_text
		_has_item = true
