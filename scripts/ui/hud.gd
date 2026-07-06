## HUD in-game: barras de vida/maná y la barra de 5 poderes con recarga radial.
## Vida/maná/super se actualizan por señales del player; los cooldowns se
## polean cada frame para que el relleno radial sea suave.
extends CanvasLayer

@onready var health_bar: ProgressBar = %HealthBar
@onready var health_label: Label = %HealthLabel
@onready var mana_bar: ProgressBar = %ManaBar
@onready var mana_label: Label = %ManaLabel
@onready var xp_bar: ProgressBar = %XPBar
@onready var level_label: Label = %LevelLabel
@onready var ability_bar: HBoxContainer = %AbilityBar
@onready var inventory_panel: PanelContainer = %InventoryPanel
@onready var game_over: CenterContainer = %GameOver
@onready var btn_retry: Button = %BtnRetry
@onready var btn_menu: Button = %BtnMenu
@onready var wave_label: Label = %WaveLabel
@onready var victory: CenterContainer = %Victory
@onready var btn_continue: Button = %BtnContinue
@onready var btn_victory_menu: Button = %BtnVictoryMenu

var player: Node = null
var wave_manager: Node = null
var _slots: Array[AbilitySlot] = []
## Mientras corre, el label de oleada muestra "¡NIVEL X!" sin ser pisado.
var _level_flash: float = 0.0

func _ready() -> void:
	wave_manager = get_tree().get_first_node_in_group("wave_manager")
	if wave_manager:
		wave_manager.wave_started.connect(_on_wave_started)
		wave_manager.wave_cleared.connect(_on_wave_cleared)
		wave_manager.intermission_tick.connect(_on_intermission_tick)
		wave_manager.boss_defeated.connect(_on_boss_defeated)
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_victory_menu.pressed.connect(_on_menu_pressed)

	player = get_tree().get_first_node_in_group("player")
	if player == null:
		push_warning("[HUD] no se encontró un nodo en el grupo 'player'")
		return
	player.health_changed.connect(_on_health_changed)
	player.mana_changed.connect(_on_mana_changed)
	player.super_charge_changed.connect(_on_super_changed)
	player.xp_changed.connect(_on_xp_changed)
	player.leveled_up.connect(_on_leveled_up)
	player.kit_changed.connect(_on_kit_changed)
	player.died.connect(_on_player_died)
	btn_retry.pressed.connect(_on_retry_pressed)
	btn_menu.pressed.connect(_on_menu_pressed)
	_build_slots()
	inventory_panel.setup(player)
	_on_health_changed(player.stats.health, player.stats.get_stat(&"max_health"))
	_on_mana_changed(player.stats.mana, player.stats.get_stat(&"max_mana"))
	_on_super_changed(player.super_charge, player.SUPER_MAX)
	_on_xp_changed(player.stats.xp, player.stats.xp_needed(), player.stats.level)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		_toggle_inventory()

## Abre/cierra el inventario. Mientras está abierto, el player no castea
## (así el click en las casillas no dispara la Bola de Fuego) y la cámara
## se acerca al personaje para ver el equipo puesto.
func _toggle_inventory() -> void:
	inventory_panel.visible = not inventory_panel.visible
	if player:
		player.combat_input_enabled = not inventory_panel.visible
	var rig = get_tree().get_first_node_in_group("camera_rig")
	if rig and rig.has_method("set_zoomed"):
		rig.set_zoomed(inventory_panel.visible)

func _build_slots() -> void:
	for i in player.abilities.size():
		var ability: Ability = player.get_ability(i)
		var slot := AbilitySlot.new()
		slot.ability_color = ability.color
		slot.key_label = ability.key_label
		slot.tooltip_text = ability.display_name
		if ability.is_super:
			slot.charge_ratio = 0.0
			slot.custom_minimum_size = Vector2(54, 54)
		ability_bar.add_child(slot)
		_slots.append(slot)

func _process(delta: float) -> void:
	if _level_flash > 0.0:
		_level_flash -= delta
	# Durante la oleada, mostrar cuántos enemigos quedan (vivos + por venir).
	elif wave_manager and wave_manager.current_wave() > 0:
		var left: int = wave_manager.enemies_left()
		if left > 0:
			wave_label.text = "Oleada %d — quedan %d" % [wave_manager.current_wave(), left]

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

## El arma equipada cambió el ataque básico: reconstruir la barra de poderes.
func _on_kit_changed() -> void:
	for child in ability_bar.get_children():
		child.queue_free()
	_slots.clear()
	_build_slots()
	_on_super_changed(player.super_charge, player.SUPER_MAX)

func _on_xp_changed(current: float, needed: float, level: int) -> void:
	xp_bar.max_value = needed
	xp_bar.value = current
	level_label.text = "Nv %d" % level

func _on_leveled_up(new_level: int) -> void:
	wave_label.text = "¡NIVEL %d!" % new_level
	_level_flash = 1.4

# --- Oleadas -------------------------------------------------------------------

func _on_wave_started(n: int) -> void:
	if wave_manager and n == wave_manager.boss_wave:
		wave_label.text = "¡OLEADA FINAL — EL REY SLIME!"
	else:
		wave_label.text = "Oleada %d" % n

func _on_boss_defeated() -> void:
	victory.visible = true

func _on_continue_pressed() -> void:
	victory.visible = false

func _on_wave_cleared(n: int) -> void:
	wave_label.text = "¡Oleada %d superada!" % n

func _on_intermission_tick(next_n: int, seconds_left: int) -> void:
	# Los primeros segundos se deja el "¡superada!" en pantalla.
	if seconds_left <= 7 or next_n == 1:
		wave_label.text = "Oleada %d en %d s..." % [next_n, seconds_left]

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
