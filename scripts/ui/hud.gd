## HUD in-game: barras de vida/maná y la barra de 5 poderes con recarga radial.
## Vida/maná/super se actualizan por señales del player; los cooldowns se
## polean cada frame para que el relleno radial sea suave.
extends CanvasLayer

@onready var health_bar: ProgressBar = %HealthBar
@onready var health_label: Label = %HealthLabel
@onready var mana_bar: ProgressBar = %ManaBar
@onready var mana_label: Label = %ManaLabel
@onready var ability_bar: HBoxContainer = %AbilityBar
@onready var inventory_panel: PanelContainer = %InventoryPanel
@onready var game_over: CenterContainer = %GameOver
@onready var btn_retry: Button = %BtnRetry
@onready var btn_menu: Button = %BtnMenu

var player: Node = null
var _slots: Array[AbilitySlot] = []

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		push_warning("[HUD] no se encontró un nodo en el grupo 'player'")
		return
	player.health_changed.connect(_on_health_changed)
	player.mana_changed.connect(_on_mana_changed)
	player.super_charge_changed.connect(_on_super_changed)
	player.died.connect(_on_player_died)
	btn_retry.pressed.connect(_on_retry_pressed)
	btn_menu.pressed.connect(_on_menu_pressed)
	_build_slots()
	inventory_panel.setup(player)
	_on_health_changed(player.stats.health, player.stats.get_stat(&"max_health"))
	_on_mana_changed(player.stats.mana, player.stats.get_stat(&"max_mana"))
	_on_super_changed(player.super_charge, player.SUPER_MAX)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		_toggle_inventory()

## Abre/cierra el inventario. Mientras está abierto, el player no castea
## (así el click en las casillas no dispara la Bola de Fuego).
func _toggle_inventory() -> void:
	inventory_panel.visible = not inventory_panel.visible
	if player:
		player.combat_input_enabled = not inventory_panel.visible

func _build_slots() -> void:
	for i in player.abilities.size():
		var ability: Ability = player.get_ability(i)
		var slot := AbilitySlot.new()
		slot.ability_color = ability.color
		slot.key_label = ability.key_label
		slot.tooltip_text = ability.display_name
		if ability.id == &"meteor_storm":
			slot.charge_ratio = 0.0
			slot.custom_minimum_size = Vector2(54, 54)
		ability_bar.add_child(slot)
		_slots.append(slot)

func _process(_delta: float) -> void:
	if player == null:
		return
	for i in _slots.size():
		var slot := _slots[i]
		if slot.charge_ratio >= 0.0:
			continue # el super se actualiza por señal, no por cooldown
		var total: float = player.get_cooldown_total(i)
		slot.cooldown_ratio = player.get_cooldown_left(i) / total if total > 0.0 else 0.0

func _on_health_changed(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "%d/%d" % [roundi(current), roundi(maximum)]

func _on_mana_changed(current: float, maximum: float) -> void:
	mana_bar.max_value = maximum
	mana_bar.value = current
	mana_label.text = "%d/%d" % [roundi(current), roundi(maximum)]

func _on_super_changed(current: float, maximum: float) -> void:
	for slot in _slots:
		if slot.charge_ratio >= 0.0:
			slot.charge_ratio = current / maximum

# --- Game Over ---------------------------------------------------------------

func _on_player_died() -> void:
	if inventory_panel.visible:
		_toggle_inventory()
	game_over.visible = true

func _on_retry_pressed() -> void:
	# Misma clase, arena fresca.
	SceneManager.change_scene("res://scenes/levels/Arena.tscn")

func _on_menu_pressed() -> void:
	SceneManager.change_scene("res://scenes/ui/MainMenu.tscn")
