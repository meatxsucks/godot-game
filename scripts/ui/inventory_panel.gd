## Panel de inventario + equipo estilo Tibia. Las casillas se crean por código.
## Click en un ítem del inventario = equipar; click en un slot de equipo = quitar.
extends PanelContainer

## Cruz de equipo: sombrero arriba, arma|túnica|escudo al medio, guantes|capa abajo.
const EQUIP_LAYOUT: Array[StringName] = [
	&"", &"head", &"",
	&"weapon", &"armor", &"offhand",
	&"hands", &"cape", &"",
]

## Etiqueta de cada slot de equipo cuando está vacío.
const SLOT_LABELS := {
	&"head": "CAB",
	&"weapon": "ARM",
	&"armor": "TOR",
	&"offhand": "ESC",
	&"hands": "GUA",
	&"cape": "CAPA",
}

## Stats mostrados en el bloque de Stats, en orden (etiquetas: StatLabels).
const STAT_ROWS: Array[StringName] = [
	&"max_health", &"max_mana", &"mana_regen", &"spell_damage",
	&"melee_damage", &"ranged_damage", &"crit_chance", &"cast_speed", &"move_speed",
]

var player: Node = null

@onready var equip_grid: GridContainer = %EquipGrid
@onready var inv_grid: GridContainer = %InvGrid
@onready var inv_counter: Label = %InvCounter
@onready var gold_label: Label = %GoldLabel
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

## Árbol de talentos (E10.5): upgrade_id -> {"label": Label, "btn": Button}.
var _talent_rows := {}
var _talent_points_label: Label = null
var _respec_btn: Button = null

## Conecta el panel al player y construye las casillas. Lo llama el HUD.
func setup(p_player: Node) -> void:
	player = p_player
	player.inventory_changed.connect(refresh)
	player.stats_changed.connect(refresh)
	player.skills_changed.connect(refresh)
	if player.has_signal("gold_changed"):
		player.gold_changed.connect(func(_g): refresh())
	_style_coin()
	_build()
	refresh()

## Dibuja el recuadro de la moneda como un círculo dorado (el nodo Panel es
## un cuadro gris por defecto).
func _style_coin() -> void:
	var coin: Panel = get_node("%GoldLabel").get_parent().get_node("Coin")
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 0.82, 0.2)
	sb.border_color = Color(0.75, 0.55, 0.1)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8) # 16x16 → círculo
	coin.add_theme_stylebox_override(&"panel", sb)

func _build() -> void:
	for slot_name in EQUIP_LAYOUT:
		if slot_name == &"":
			var spacer := Control.new()
			spacer.custom_minimum_size = Vector2(40, 40)
			equip_grid.add_child(spacer)
			continue
		var slot := ItemSlotUI.new()
		slot.placeholder = tr(SLOT_LABELS[slot_name])
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
	for stat in STAT_ROWS:
		_stat_labels[stat] = _make_line(stats_box)
	for skill in SkillSet.SKILLS:
		_skill_labels[skill] = _make_line(skills_box)
	_build_talents()

## Columna del árbol de talentos (E10.5): nodos del kit de la clase, con
## compra por punto y respec pagado en oro (creciente). El árbol solo toca
## poderes de CLASE — las armas suben por su tier (decisión 2026-07-17).
func _build_talents() -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override(&"separation", 3)
	skills_box.get_parent().get_parent().add_child(col)

	var title := Label.new()
	title.text = tr("Talentos")
	title.add_theme_font_size_override(&"font_size", 12)
	col.add_child(title)
	_talent_points_label = _make_line(col)

	var kit: Array = Game.class_def(player.player_class).kit
	for ability_id in kit:
		for up: AbilityUpgrade in Game.upgrades_for_ability(ability_id):
			var row := HBoxContainer.new()
			col.add_child(row)
			var label := Label.new()
			label.add_theme_font_size_override(&"font_size", 9)
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(label)
			var btn := Button.new()
			btn.text = "+"
			btn.custom_minimum_size = Vector2(22, 16)
			btn.pressed.connect(_on_talent_pressed.bind(up.id))
			row.add_child(btn)
			_talent_rows[up.id] = {"label": label, "btn": btn}

	_respec_btn = Button.new()
	_respec_btn.add_theme_font_size_override(&"font_size", 9)
	_respec_btn.pressed.connect(_on_respec_pressed)
	col.add_child(_respec_btn)

func _on_talent_pressed(up_id: StringName) -> void:
	player.buy_talent(up_id)

func _on_respec_pressed() -> void:
	player.respec_talents()

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
	# El oro tiene su propio recuadro dorado (separado del conteo de objetos):
	# es un recurso escaso, no un ítem más del inventario.
	inv_counter.text = tr("Inventario %d/%d") % [player.inventory.size(), player.INVENTORY_SIZE]
	gold_label.text = tr("%d de oro") % player.stats.gold

	# Stats efectivos (base de la clase + equipo + niveles) y skills.
	_level_label.text = tr("Nivel: %d  (XP %d/%d)") % [player.stats.level, roundi(player.stats.xp), roundi(player.stats.xp_needed())]
	for stat in STAT_ROWS:
		_stat_labels[stat].text = "%s: %d" % [StatLabels.label(stat), roundi(player.stats.get_stat(stat))]
	for skill in SkillSet.SKILLS:
		var lv: int = player.stats.skills.level(skill)
		var pct: int = roundi(player.stats.skills.progress(skill) * 100)
		_skill_labels[skill].text = tr("%s: nv %d (%d%%)") % [tr(SkillSet.NAMES[skill]), lv, pct]

	# Árbol de talentos (E10.5).
	if _talent_points_label:
		_talent_points_label.text = tr("Puntos: %d (1 cada %d niveles)") % [
			player.stats.talent_points_available(), BalanceDef.bal().levels_per_talent_point]
		var spent: int = player.stats.talent_points_spent()
		var available: int = player.stats.talent_points_available()
		for up_id in _talent_rows:
			var up: AbilityUpgrade = Game.upgrade(up_id)
			var ranks: int = int(player.stats.talents.get(up_id, 0))
			var row: Dictionary = _talent_rows[up_id]
			row["label"].text = "%s %d/%d · %s" % [tr(up.name), ranks, up.max_ranks, up.describe()]
			var locked: bool = spent < up.requires_spent
			row["label"].modulate = Color(1, 1, 1, 0.45) if locked else Color.WHITE
			row["btn"].disabled = locked or ranks >= up.max_ranks or available < up.cost
		_respec_btn.text = tr("Reiniciar árbol (%d de oro)") % player.stats.respec_cost()
		_respec_btn.disabled = player.stats.talents.is_empty() or player.stats.gold < player.stats.respec_cost()

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
	compare_left.text = slot.item.to_bbcode(player.stats.level)

	var equipped: LootItem = null
	if slot.slot_kind == &"inventory" and not slot.item.is_consumable() and slot.item.base:
		equipped = player.stats.equipment.get(slot.item.base.slot, null)
	compare_right_box.visible = equipped != null
	if equipped:
		compare_right.text = equipped.to_bbcode(player.stats.level)

	compare_panel.visible = true
	compare_panel.reset_size()
	compare_panel.global_position = global_position - Vector2(compare_panel.size.x + 6.0, 0.0)

func _hide_compare() -> void:
	compare_panel.visible = false
