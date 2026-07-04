## Selección de clase (rol) antes de entrar a la Arena. Las tarjetas se
## construyen por código desde Game.CLASSES.
extends Control

const ORDER: Array[StringName] = [&"mage", &"warrior", &"ranger"]

## Etiquetas cortas para las líneas de stats de cada tarjeta.
const STAT_LABELS := {
	&"max_health": "Vida",
	&"max_mana": "Maná",
	&"mana_regen": "Regen. maná",
	&"spell_damage": "Daño mágico",
	&"crit_chance": "Crítico %",
	&"crit_damage": "Daño crít. %",
	&"move_speed": "Vel. mov. %",
	&"res_fire": "Res. fuego %",
	&"res_cold": "Res. hielo %",
	&"res_lightning": "Res. rayo %",
}

@onready var cards: HBoxContainer = %Cards

func _ready() -> void:
	for id in ORDER:
		cards.add_child(_make_card(id))

func _make_card(id: StringName) -> Control:
	var def: Dictionary = Game.class_def(id)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.09, 0.14, 0.95)
	style.set_border_width_all(2)
	style.border_color = def["color"]
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override(&"panel", style)
	panel.custom_minimum_size = Vector2(190, 250)

	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 6)
	panel.add_child(box)

	var title := Label.new()
	title.text = def["name"]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override(&"font_color", def["color"])
	title.add_theme_font_size_override(&"font_size", 18)
	box.add_child(title)

	var desc := Label.new()
	desc.text = def["desc"]
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override(&"font_size", 10)
	desc.custom_minimum_size = Vector2(0, 56)
	box.add_child(desc)

	box.add_child(HSeparator.new())

	for stat in def["stats"]:
		var line := Label.new()
		line.text = "%s: %d" % [STAT_LABELS.get(stat, String(stat)), roundi(def["stats"][stat])]
		line.add_theme_font_size_override(&"font_size", 10)
		box.add_child(line)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)

	var button := Button.new()
	button.text = "Elegir"
	button.pressed.connect(_on_class_chosen.bind(id))
	box.add_child(button)

	return panel

func _on_class_chosen(id: StringName) -> void:
	Game.selected_class = id
	SceneManager.change_scene("res://scenes/levels/Arena.tscn")
