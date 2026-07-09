## Casilla de ítem (inventario o equipo) estilo Tibia: abreviatura y borde
## coloreados por rareza. Soporta click (equipar/usar/quitar) y drag & drop
## nativo de Godot; la comparación en hover la maneja InventoryPanel.
class_name ItemSlotUI
extends Button

## Rol de la casilla para drag & drop (lo setea InventoryPanel al construir).
var slot_kind: StringName = &"inventory" # &"inventory" | &"equipment"
var slot_index: int = -1                 # índice en la grilla del inventario
var equip_slot: StringName = &""         # slot de equipo (si kind == equipment)

## Texto mostrado cuando la casilla está vacía (etiqueta del slot de equipo).
var placeholder: String = ""
var item: LootItem = null

## Algo fue soltado sobre esta casilla (data del _get_drag_data del origen).
signal slot_dropped(data: Dictionary)

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
		tint = Color(0.42, 0.42, 0.5)
		style.border_color = Color(0.28, 0.28, 0.34)
	else:
		text = _abbrev_for(item)
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

# --- Drag & drop --------------------------------------------------------------

func _get_drag_data(_at_position: Vector2) -> Variant:
	if item == null:
		return null
	var preview := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.18, 0.9)
	style.set_border_width_all(2)
	style.border_color = item.ui_color()
	style.set_corner_radius_all(4)
	preview.add_theme_stylebox_override(&"panel", style)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", 9)
	label.add_theme_color_override(&"font_color", item.ui_color())
	preview.add_child(label)
	set_drag_preview(preview)
	return {"kind": slot_kind, "index": slot_index, "equip_slot": equip_slot, "item": item}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary) or not data.has("item"):
		return false
	var source_kind: StringName = data.get("kind", &"")
	if source_kind == &"inventory" and slot_kind == &"equipment":
		var dragged: LootItem = data["item"]
		return dragged.base != null and not dragged.is_consumable() \
				and dragged.base.slot == equip_slot
	if source_kind == &"inventory" and slot_kind == &"inventory":
		return int(data["index"]) != slot_index
	if source_kind == &"equipment" and slot_kind == &"inventory":
		return true
	return false

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	slot_dropped.emit(data)

func _abbrev_for(it: LootItem) -> String:
	if it.base:
		if it.base.type == &"potion_health":
			return tr("VID")
		if it.base.type == &"potion_mana":
			return tr("MAN")
	# Se abrevia el display_name ya generado (queda en el idioma en que se
	# generó el ítem — cambiar de idioma no re-traduce ítems ya en el mundo).
	return it.display_name.substr(0, 3).to_upper()
