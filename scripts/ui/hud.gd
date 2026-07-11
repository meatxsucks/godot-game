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
@onready var pause_panel: CenterContainer = %Pause
@onready var btn_resume: Button = %BtnResume
@onready var btn_pause_options: Button = %BtnPauseOptions
@onready var btn_pause_menu: Button = %BtnPauseMenu
@onready var btn_pause_quit: Button = %BtnPauseQuit
@onready var options_panel: CenterContainer = %Options
@onready var language_option: OptionButton = %LanguageOption
@onready var volume_slider: HSlider = %VolumeSlider
@onready var volume_label: Label = %VolumeLabel
@onready var resolution_option: OptionButton = %ResolutionOption
@onready var fullscreen_check: CheckButton = %FullscreenCheck
@onready var btn_options_back: Button = %BtnOptionsBack
@onready var controls_panel: CenterContainer = %Controls
@onready var btn_pause_controls: Button = %BtnPauseControls
@onready var controls_list: VBoxContainer = %ControlsList
@onready var btn_controls_reset: Button = %BtnControlsReset
@onready var btn_controls_back: Button = %BtnControlsBack

var player: Node = null
var wave_manager: Node = null
var _slots: Array[AbilitySlot] = []
## Mientras corre, el label de oleada muestra "¡NIVEL X!" sin ser pisado.
var _level_flash: float = 0.0

## Nombres legibles de las acciones remapeables (ver SaveService.REMAPPABLE_ACTIONS).
const ACTION_LABELS := {
	&"move_up": "Mover arriba",
	&"move_down": "Mover abajo",
	&"move_left": "Mover izquierda",
	&"move_right": "Mover derecha",
	&"attack_primary": "Ataque primario",
	&"attack_secondary": "Ataque secundario",
	&"ability_dash": "Dash / blink",
	&"ability_nova": "Habilidad (Q)",
	&"ability_super": "Ultimate (R)",
	&"toggle_inventory": "Inventario",
	&"interact": "Interactuar",
}
## Nombre de cada locale en SU PROPIO idioma (no se traduce: un hablante de
## inglés tiene que poder reconocer "Español" aunque esté viendo el menú en inglés).
const LOCALE_NAMES := {
	"es": "Español",
	"en": "English",
}
var _kb_buttons := {} # StringName -> Button
var _joy_labels := {} # StringName -> Label
## Acción esperando la próxima tecla/click para remapearse (&"" = ninguna).
var _rebind_action: StringName = &""

func _ready() -> void:
	wave_manager = get_tree().get_first_node_in_group("wave_manager")
	if wave_manager:
		wave_manager.wave_started.connect(_on_wave_started)
		wave_manager.wave_cleared.connect(_on_wave_cleared)
		wave_manager.intermission_tick.connect(_on_intermission_tick)
		wave_manager.boss_defeated.connect(_on_boss_defeated)
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_victory_menu.pressed.connect(_on_menu_pressed)
	btn_resume.pressed.connect(_toggle_pause)
	btn_pause_menu.pressed.connect(_on_menu_pressed)
	btn_pause_quit.pressed.connect(_on_pause_quit_pressed)
	btn_pause_options.pressed.connect(_on_options_pressed)
	btn_options_back.pressed.connect(_on_options_back_pressed)
	language_option.item_selected.connect(_on_language_selected)
	volume_slider.value_changed.connect(_on_volume_changed)
	resolution_option.item_selected.connect(_on_resolution_selected)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	_setup_options_ui()
	btn_pause_controls.pressed.connect(_on_controls_pressed)
	btn_controls_back.pressed.connect(_on_controls_back_pressed)
	btn_controls_reset.pressed.connect(_on_controls_reset_pressed)
	_build_controls_rows()

	btn_retry.pressed.connect(_on_retry_pressed)
	btn_menu.pressed.connect(_on_menu_pressed)
	_try_bind_player()

## El HUD es del jugador LOCAL. En co-op el player se spawnea unos frames
## después del HUD, así que _process reintenta hasta encontrarlo (E1.5).
func _try_bind_player() -> void:
	player = Players.local(get_tree())
	if player == null:
		return
	player.health_changed.connect(_on_health_changed)
	player.mana_changed.connect(_on_mana_changed)
	player.super_charge_changed.connect(_on_super_changed)
	player.xp_changed.connect(_on_xp_changed)
	player.leveled_up.connect(_on_leveled_up)
	player.kit_changed.connect(_on_kit_changed)
	player.died.connect(_on_player_died)
	_build_slots()
	inventory_panel.setup(player)
	_on_health_changed(player.stats.health, player.stats.get_stat(&"max_health"))
	_on_mana_changed(player.stats.mana, player.stats.get_stat(&"max_mana"))
	_on_super_changed(player.super_charge, player.SUPER_MAX)
	_on_xp_changed(player.stats.xp, player.stats.xp_needed(), player.stats.level)

func _input(event: InputEvent) -> void:
	# Con un rebind pendiente, la próxima tecla/click captura el bind (o lo
	# cancela si es Escape) en vez de accionar cualquier otra cosa.
	if _rebind_action != &"":
		_capture_rebind(event)
		return
	if event.is_action_pressed("ui_cancel"):
		# Con el inventario abierto, ESC lo cierra primero; con Opciones o
		# Controles abiertos, vuelve a Pausa; si ya terminó la partida (game
		# over/victoria), esos paneles tienen sus propios botones.
		if inventory_panel.visible:
			_toggle_inventory()
		elif options_panel.visible:
			_on_options_back_pressed()
		elif controls_panel.visible:
			_on_controls_back_pressed()
		elif not game_over.visible and not victory.visible:
			_toggle_pause()
		return
	if event.is_action_pressed("toggle_inventory") and not pause_panel.visible:
		_toggle_inventory()

## Pausa/reanuda el juego (ESC). El HUD corre en PROCESS_MODE_ALWAYS para
## seguir recibiendo input y poder des-pausar.
func _toggle_pause() -> void:
	pause_panel.visible = not pause_panel.visible
	if not pause_panel.visible:
		options_panel.visible = false
		controls_panel.visible = false
	get_tree().paused = pause_panel.visible

func _on_pause_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()

# --- Opciones (E0.3) --------------------------------------------------------
# Volumen/resolución/pantalla completa se aplican en vivo y persisten en
# cada cambio vía SaveService — sin botón "Guardar" separado.

func _setup_options_ui() -> void:
	for locale in SaveService.LOCALES:
		language_option.add_item(LOCALE_NAMES.get(locale, locale))
	for res in SaveService.RESOLUTIONS:
		resolution_option.add_item("%d×%d" % [res.x, res.y])
	var settings := SaveService.load_settings()
	var locale_idx := SaveService.LOCALES.find(settings["locale"])
	language_option.selected = maxi(locale_idx, 0)
	volume_slider.value = settings["master_volume"]
	_update_volume_label(settings["master_volume"])
	fullscreen_check.button_pressed = settings["fullscreen"]
	var res_idx := SaveService.RESOLUTIONS.find(settings["resolution"])
	resolution_option.selected = maxi(res_idx, 0)

func _on_options_pressed() -> void:
	pause_panel.visible = false
	options_panel.visible = true

func _on_options_back_pressed() -> void:
	options_panel.visible = false
	pause_panel.visible = true

func _on_volume_changed(value: float) -> void:
	_update_volume_label(value)
	_persist_settings()

func _update_volume_label(value: float) -> void:
	volume_label.text = "%d%%" % roundi(value * 100.0)

func _on_resolution_selected(_index: int) -> void:
	_persist_settings()

func _on_fullscreen_toggled(_pressed: bool) -> void:
	_persist_settings()

## Cambiar idioma re-traduce en vivo los Controls estáticos (Godot lo hace
## solo), pero los labels dinámicos ya compuestos (inventario, controles)
## hay que reconstruirlos a mano para que no se queden en el idioma viejo
## hasta el próximo refresh natural.
func _on_language_selected(_index: int) -> void:
	_persist_settings()
	_build_controls_rows()
	if player:
		inventory_panel.refresh()

func _persist_settings() -> void:
	var settings := {
		"locale": SaveService.LOCALES[language_option.selected],
		"master_volume": volume_slider.value,
		"resolution": SaveService.RESOLUTIONS[resolution_option.selected],
		"fullscreen": fullscreen_check.button_pressed,
	}
	SaveService.save_settings(settings)
	SaveService.apply_settings(settings)

# --- Controles (E0.4) --------------------------------------------------------
# Solo el bind de teclado/mouse es remapeable interactivamente; el de mando
# se muestra de referencia (rebindearlo requiere resolver ejes/gatillos
# analógicos aparte — queda para una iteración futura de E0.4).

func _build_controls_rows() -> void:
	for child in controls_list.get_children():
		child.queue_free()
	_kb_buttons.clear()
	_joy_labels.clear()
	for action in SaveService.REMAPPABLE_ACTIONS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 10)

		var name_label := Label.new()
		name_label.custom_minimum_size = Vector2(140, 0)
		name_label.add_theme_font_size_override(&"font_size", 10)
		name_label.text = tr(ACTION_LABELS.get(action, String(action)))
		row.add_child(name_label)

		var kb_button := Button.new()
		kb_button.custom_minimum_size = Vector2(90, 0)
		kb_button.pressed.connect(_on_rebind_pressed.bind(action))
		row.add_child(kb_button)
		_kb_buttons[action] = kb_button

		var joy_label := Label.new()
		joy_label.custom_minimum_size = Vector2(90, 0)
		joy_label.add_theme_font_size_override(&"font_size", 10)
		joy_label.add_theme_color_override(&"font_color", Color(0.7, 0.7, 0.75))
		row.add_child(joy_label)
		_joy_labels[action] = joy_label

		controls_list.add_child(row)
	_refresh_controls_rows()

func _refresh_controls_rows() -> void:
	for action in SaveService.REMAPPABLE_ACTIONS:
		var kb_text := "—"
		var joy_text := "—"
		for ev in InputMap.action_get_events(action):
			if ev is InputEventJoypadButton or ev is InputEventJoypadMotion:
				joy_text = InputGlyphs.text(ev)
			else:
				kb_text = InputGlyphs.text(ev)
		_kb_buttons[action].text = kb_text
		_joy_labels[action].text = joy_text

func _on_controls_pressed() -> void:
	pause_panel.visible = false
	controls_panel.visible = true
	_refresh_controls_rows()

func _on_controls_back_pressed() -> void:
	_cancel_rebind()
	controls_panel.visible = false
	pause_panel.visible = true

func _on_controls_reset_pressed() -> void:
	_cancel_rebind()
	SaveService.reset_keybinds()
	_refresh_controls_rows()

func _on_rebind_pressed(action: StringName) -> void:
	_cancel_rebind() # solo un rebind pendiente a la vez
	_rebind_action = action
	_kb_buttons[action].text = "..."

func _cancel_rebind() -> void:
	if _rebind_action == &"":
		return
	_rebind_action = &""
	_refresh_controls_rows()

## Captura el próximo evento válido (tecla o botón de mouse) mientras hay un
## rebind pendiente. Escape cancela en vez de asignarse.
func _capture_rebind(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			_cancel_rebind()
		else:
			SaveService.rebind_action(_rebind_action, event)
			_rebind_action = &""
			_refresh_controls_rows()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		SaveService.rebind_action(_rebind_action, event)
		_rebind_action = &""
		_refresh_controls_rows()
		get_viewport().set_input_as_handled()

## Abre/cierra el inventario. Mientras está abierto, el player no castea
## (así el click en las casillas no dispara la Bola de Fuego) y la cámara
## se acerca al personaje para ver el equipo puesto.
func _toggle_inventory() -> void:
	inventory_panel.visible = not inventory_panel.visible
	if player:
		player.combat_input_enabled = not inventory_panel.visible
		if player.has_method("set_inspect"):
			player.set_inspect(inventory_panel.visible)
	var rig = get_tree().get_first_node_in_group("camera_rig")
	if rig and rig.has_method("set_zoomed"):
		rig.set_zoomed(inventory_panel.visible)

func _build_slots() -> void:
	for i in player.abilities.size():
		var ability: Ability = player.get_ability(i)
		var slot := AbilitySlot.new()
		slot.ability_color = ability.color
		slot.key_label = ability.key_label
		slot.tooltip_text = tr(ability.display_name)
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
			wave_label.text = tr("Oleada %d — quedan %d") % [wave_manager.current_wave(), left]

	if player == null:
		_try_bind_player()
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
	level_label.text = tr("Nv %d") % level

func _on_leveled_up(new_level: int) -> void:
	wave_label.text = tr("¡NIVEL %d!") % new_level
	_level_flash = 1.4

# --- Oleadas -------------------------------------------------------------------

func _on_wave_started(n: int) -> void:
	if wave_manager and n == wave_manager.boss_wave:
		wave_label.text = tr("¡OLEADA FINAL — EL REY SLIME!")
	else:
		wave_label.text = tr("Oleada %d") % n

func _on_boss_defeated() -> void:
	victory.visible = true

func _on_continue_pressed() -> void:
	victory.visible = false

func _on_wave_cleared(n: int) -> void:
	wave_label.text = tr("¡Oleada %d superada!") % n

func _on_intermission_tick(next_n: int, seconds_left: int) -> void:
	# Los primeros segundos se deja el "¡superada!" en pantalla.
	if seconds_left <= 7 or next_n == 1:
		wave_label.text = tr("Oleada %d en %d s...") % [next_n, seconds_left]

# --- Game Over ---------------------------------------------------------------

func _on_player_died() -> void:
	if inventory_panel.visible:
		_toggle_inventory()
	game_over.visible = true

func _on_retry_pressed() -> void:
	get_tree().paused = false
	# Misma clase, arena fresca.
	SceneManager.change_scene("res://scenes/levels/Arena.tscn")

func _on_menu_pressed() -> void:
	get_tree().paused = false
	SceneManager.change_scene("res://scenes/ui/MainMenu.tscn")
