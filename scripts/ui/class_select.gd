## Selección de clase (rol) antes de entrar a la Arena. Las tarjetas se
## construyen por código desde los ClassDef que carga Game — una clase nueva
## (.tres en resources/classes/) aparece acá sola, ordenada por menu_order.
extends Control

@onready var cards: HBoxContainer = %Cards

func _ready() -> void:
	for id in Game.class_ids():
		cards.add_child(_make_card(id))
	_add_back_button()
	# Si el host corta mientras elegimos clase, volver al menú (sin esto el
	# cliente quedaba en una pantalla muerta).
	if Net.is_online() and not multiplayer.is_server():
		Net.server_disconnected.connect(_on_back_pressed)

## Volver al menú principal. En co-op también corta la sesión: elegir clase
## es el último paso antes de entrar a la Arena, salir de acá = salir de la
## partida (el host spawnea a todos recién cuando nadie falta por cargar).
func _add_back_button() -> void:
	var btn_back := Button.new()
	btn_back.text = tr("Volver")
	btn_back.pressed.connect(_on_back_pressed)
	cards.get_parent().add_child(btn_back)

func _on_back_pressed() -> void:
	Net.close_connection()
	SceneManager.change_scene("res://scenes/ui/MainMenu.tscn")

func _make_card(id: StringName) -> Control:
	var def: ClassDef = Game.class_def(id)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.09, 0.14, 0.95)
	style.set_border_width_all(2)
	style.border_color = def.color
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override(&"panel", style)
	panel.custom_minimum_size = Vector2(190, 250)

	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 6)
	panel.add_child(box)

	var title := Label.new()
	title.text = tr(def.display_name)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override(&"font_color", def.color)
	title.add_theme_font_size_override(&"font_size", 18)
	box.add_child(title)

	var desc := Label.new()
	desc.text = tr(def.description)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override(&"font_size", 10)
	desc.custom_minimum_size = Vector2(0, 56)
	box.add_child(desc)

	box.add_child(HSeparator.new())

	for stat in def.stats:
		var line := Label.new()
		line.text = "%s: %d" % [StatLabels.label(stat), roundi(def.stats[stat])]
		line.add_theme_font_size_override(&"font_size", 10)
		box.add_child(line)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)

	var button := Button.new()
	button.text = tr("Elegir")
	button.pressed.connect(_on_class_chosen.bind(id))
	box.add_child(button)

	return panel

func _on_class_chosen(id: StringName) -> void:
	Game.selected_class = id
	SceneManager.change_scene("res://scenes/levels/Arena.tscn")
