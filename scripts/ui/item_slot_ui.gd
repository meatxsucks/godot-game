## Casilla de ítem (inventario o equipo) estilo Tibia: abreviatura y borde
## coloreados por rareza, tooltip con la ficha completa del ítem.
class_name ItemSlotUI
extends Button

## Texto mostrado cuando la casilla está vacía (etiqueta del slot de equipo).
var placeholder: String = ""
var item: LootItem = null

func _init() -> void:
	custom_minimum_size = Vector2(40, 40)
	focus_mode = Control.FOCUS_NONE
	add_theme_font_size_override(&"font_size", 9)

func set_item(new_item: LootItem) -> void:
	item = new_item

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.10, 0.14, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)

	var tint: Color
	if item == null:
		text = placeholder
		tooltip_text = ""
		tint = Color(0.42, 0.42, 0.5)
		style.border_color = Color(0.28, 0.28, 0.34)
	else:
		text = _abbrev_for(item)
		tooltip_text = item.to_text()
		tint = item.ui_color()
		style.border_color = tint

	add_theme_color_override(&"font_color", tint)
	add_theme_color_override(&"font_hover_color", tint.lightened(0.2))
	add_theme_color_override(&"font_pressed_color", tint)
	add_theme_stylebox_override(&"normal", style)

	var hover: StyleBoxFlat = style.duplicate()
	hover.bg_color = Color(0.17, 0.17, 0.24, 0.95)
	add_theme_stylebox_override(&"hover", hover)
	add_theme_stylebox_override(&"pressed", hover)

func _abbrev_for(it: LootItem) -> String:
	if it.base:
		if it.base.type == &"potion_health":
			return "VID"
		if it.base.type == &"potion_mana":
			return "MAN"
	return it.display_name.substr(0, 3).to_upper()
