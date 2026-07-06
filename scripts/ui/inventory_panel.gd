## Panel de inventario + equipo estilo Tibia. Las casillas se crean por código.
## Click en un ítem del inventario = equipar; click en un slot de equipo = quitar.
extends PanelContainer

## Cruz de equipo: sombrero arriba, arma|túnica|escudo al medio, capa abajo.
const EQUIP_LAYOUT: Array[StringName] = [
	&"", &"head", &"",
	&"weapon", &"armor", &"offhand",
	&"", &"cape", &"",
]

## Etiqueta de cada slot de equipo cuando está vacío.
const SLOT_LABELS := {
	&"head": "CAB",
	&"weapon": "ARM",
	&"armor": "TOR",
	&"offhand": "ESC",
	&"cape": "CAPA",
}

## Stats mostrados en el bloque de Stats: [stat, etiqueta].
const STAT_ROWS := [
	[&"max_health", "Vida"],
	[&"max_mana", "Maná"],
	[&"mana_regen", "Maná por kill"],
	[&"spell_damage", "Daño mágico"],
	[&"melee_damage", "Daño melee"],
	[&"ranged_damage", "Daño distancia"],
	[&"crit_chance", "Crítico %"],
	[&"cast_speed", "Vel. lanz. %"],
	[&"move_speed", "Vel. mov. %"],
]

var player: Node = null

@onready var equip_grid: GridContainer = %EquipGrid
@onready var inv_grid: GridContainer = %InvGrid
@onready var inv_counter: Label = %InvCounter
@onready var stats_box: VBoxContainer = %StatsBox
@onready var skills_box: VBoxContainer = %SkillsBox
@onready var compare_panel: PanelContainer = %ComparePanel
@onready var compare_left: RichTextLabel = %CompareLeft
@onready var compare_right: RichTextLabel = %CompareRight
@onready var compare_right_box: VBoxContainer = %RightBox

var _equip_slots := {} # slot StringName -> ItemSlotUI
var _inv_slots: Array[ItemSlotUI] = []
var _stat_labels := {} # stat StringName -> Label
var _skill_labels := {} # skill StringName -> Label
var _level_label: Label = null

## Conecta el panel al player y construye las casillas. Lo llama el HUD.
func setup(p_player: Node) -> void:
	player = p_player
	player.inventory_changed.connect(refresh)
	player.stats_changed.connect(refresh)
	player.skills_changed.connect(refresh)
	_build()
	refresh()

func _build() -> void:
	for slot_name in EQUIP_LAYOUT:
		if slot_name == &"":
			var spacer := Control.new()
			spacer.custom_minimum_size = Vector2(40, 40)
			equip_grid.add_child(spacer)
			continue
		var slot := ItemSlotUI.new()
		slot.placeholder = SLOT_LABELS[slot_name]
		slot.slot_kind = &"equipment"
		slot.equip_slot = slot_name
		slot.pressed.connect(_on_equip_slot_pressed.bind(slot_name))
		slot.slot_dropped.connect(_on_slot_dropped.bind(&"equipment", -1))
		slot.mouse_entered.connect(_on_slot_hover.bind(slot))
		slot.mouse_exited.connect(_hide_compare)
		equip_grid.add_child(slot)
		_equip_slots[slot_name] = slot

	for i in player.INVENTORY_SIZE:
		var slot := ItemSlotUI.new()
		slot.slot_kind = &"inventory"
		slot.slot_index = i
		slot.pressed.connect(_on_inventory_slot_pressed.bind(i))
		slot.slot_dropped.connect(_on_slot_dropped.bind(&"inventory", i))
		slot.mouse_entered.connect(_on_slot_hover.bind(slot))
		slot.mouse_exited.connect(_hide_compare)
		inv_grid.add_child(slot)
		_inv_slots.append(slot)

	_level_label = _make_line(stats_box)
	for row in STAT_ROWS:
		_stat_labels[row[0]] = _make_line(stats_box)
	for skill in SkillSet.SKILLS:
		_skill_labels[skill] = _make_line(skills_box)

func _make_line(parent: Control) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override(&"font_size", 10)
	parent.add_child(label)
	return label

func refresh() -> void:
	if player == null:
		return
	for slot_name in _equip_slots:
		_equip_slots[slot_name].set_item(player.stats.equipment.get(slot_name, null))
	for i in _inv_slots.size():
		var item: LootItem = player.inventory[i] if i < player.inventory.size() else null
		_inv_slots[i].set_item(item)
	inv_counter.text = "Inventario %d/%d" % [player.inventory.size(), player.INVENTORY_SIZE]

	# Stats efectivos (base de la clase + equipo + niveles) y skills.
	_level_label.text = "Nivel: %d  (XP %d/%d)" % [player.stats.level, roundi(player.stats.xp), roundi(player.stats.xp_needed())]
	for row in STAT_ROWS:
		_stat_labels[row[0]].text = "%s: %d" % [row[1], roundi(player.stats.get_stat(row[0]))]
	for skill in SkillSet.SKILLS:
		var lv: int = player.stats.skills.level(skill)
		var pct: int = roundi(player.stats.skills.progress(skill) * 100)
		_skill_labels[skill].text = "%s: nv %d (%d%%)" % [SkillSet.NAMES[skill], lv, pct]

func _on_inventory_slot_pressed(index: int) -> void:
	_hide_compare()
	player.equip_from_inventory(index)

func _on_equip_slot_pressed(slot_name: StringName) -> void:
	_hide_compare()
	player.unequip_slot(slot_name)

# --- Drag & drop --------------------------------------------------------------

## Resuelve un drop según origen y destino (la validación fue en _can_drop_data).
func _on_slot_dropped(data: Dictionary, target_kind: StringName, target_index: int) -> void:
	_hide_compare()
	var source_kind: StringName = data.get("kind", &"")
	if source_kind == &"inventory" and target_kind == &"equipment":
		player.equip_from_inventory(int(data["index"]))
	elif source_kind == &"inventory" and target_kind == &"inventory":
		player.swap_inventory(int(data["index"]), target_index)
	elif source_kind == &"equipment" and target_kind == &"inventory":
		player.unequip_slot(data["equip_slot"])

# --- Comparación lado a lado ---------------------------------------------------

## Hover sobre una casilla con ítem: muestra su ficha y, si viene del
## inventario, la del equipado en ese slot al lado.
func _on_slot_hover(slot: ItemSlotUI) -> void:
	if slot.item == null:
		_hide_compare()
		return
	compare_left.text = slot.item.to_bbcode()

	var equipped: LootItem = null
	if slot.slot_kind == &"inventory" and not slot.item.is_consumable() and slot.item.base:
		equipped = player.stats.equipment.get(slot.item.base.slot, null)
	compare_right_box.visible = equipped != null
	if equipped:
		compare_right.text = equipped.to_bbcode()

	compare_panel.visible = true
	compare_panel.reset_size()
	compare_panel.global_position = global_position - Vector2(compare_panel.size.x + 6.0, 0.0)

func _hide_compare() -> void:
	compare_panel.visible = false
