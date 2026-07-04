## Panel de inventario + equipo estilo Tibia. Las casillas se crean por código.
## Click en un ítem del inventario = equipar; click en un slot de equipo = quitar.
extends PanelContainer

## Cruz de equipo (grilla 3x3, &"" = hueco vacío).
const EQUIP_LAYOUT: Array[StringName] = [
	&"", &"head", &"",
	&"weapon", &"armor", &"offhand",
	&"ring", &"boots", &"",
]

## Etiqueta de cada slot de equipo cuando está vacío.
const SLOT_LABELS := {
	&"head": "CAB",
	&"weapon": "ARM",
	&"armor": "TOR",
	&"offhand": "ESC",
	&"ring": "ANI",
	&"boots": "BOT",
}

## Stats mostrados en el bloque de Stats: [stat, etiqueta].
const STAT_ROWS := [
	[&"max_health", "Vida"],
	[&"max_mana", "Maná"],
	[&"spell_damage", "Daño mágico"],
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

var _equip_slots := {} # slot StringName -> ItemSlotUI
var _inv_slots: Array[ItemSlotUI] = []
var _stat_labels := {} # stat StringName -> Label
var _skill_labels := {} # skill StringName -> Label

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
		slot.pressed.connect(_on_equip_slot_pressed.bind(slot_name))
		equip_grid.add_child(slot)
		_equip_slots[slot_name] = slot

	for i in player.INVENTORY_SIZE:
		var slot := ItemSlotUI.new()
		slot.pressed.connect(_on_inventory_slot_pressed.bind(i))
		inv_grid.add_child(slot)
		_inv_slots.append(slot)

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

	# Stats efectivos (base de la clase + equipo) y skills estilo Tibia.
	for row in STAT_ROWS:
		_stat_labels[row[0]].text = "%s: %d" % [row[1], roundi(player.stats.get_stat(row[0]))]
	for skill in SkillSet.SKILLS:
		var lv: int = player.stats.skills.level(skill)
		var pct: int = roundi(player.stats.skills.progress(skill) * 100)
		_skill_labels[skill].text = "%s: nv %d (%d%%)" % [SkillSet.NAMES[skill], lv, pct]

func _on_inventory_slot_pressed(index: int) -> void:
	player.equip_from_inventory(index)

func _on_equip_slot_pressed(slot_name: StringName) -> void:
	player.unequip_slot(slot_name)
