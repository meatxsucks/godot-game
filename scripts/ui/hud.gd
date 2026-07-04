## HUD in-game: barras de vida/maná y la barra de 5 poderes con recarga radial.
## Vida/maná/super se actualizan por señales del player; los cooldowns se
## polean cada frame para que el relleno radial sea suave.
extends CanvasLayer

@onready var health_bar: ProgressBar = %HealthBar
@onready var health_label: Label = %HealthLabel
@onready var mana_bar: ProgressBar = %ManaBar
@onready var mana_label: Label = %ManaLabel
@onready var ability_bar: HBoxContainer = %AbilityBar

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
	_build_slots()
	_on_health_changed(player.stats.health, player.stats.get_stat(&"max_health"))
	_on_mana_changed(player.stats.mana, player.stats.get_stat(&"max_mana"))
	_on_super_changed(player.super_charge, player.SUPER_MAX)

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
