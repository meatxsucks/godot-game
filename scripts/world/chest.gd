## Cofre accionable: acércate y presiona E para abrirlo. Su contenido
## (bastón, sombrero, zapatos, túnica + pociones de vida) cae al suelo
## alrededor. Un solo uso.
extends StaticBody3D

const DROP_SCENE := preload("res://scenes/loot/LootDrop.tscn")
## Tipos de arma: se derraman TODOS para poder probar cada poder de LMB/RMB.
const WEAPON_TYPES: Array[StringName] = [&"staff", &"wand", &"sword", &"mace", &"bow"]

## Nivel del loot que genera.
@export var loot_level: int = 1
## Pociones de vida que trae (la vida SOLO sale de cofres, no de enemigos).
@export var health_potions: int = 2

var _player_in_range := false
var _opened := false

@onready var lid_pivot: Node3D = $LidPivot
@onready var prompt: Label3D = $Prompt

func _ready() -> void:
	add_to_group("chest")
	prompt.text = tr(prompt.text)
	$InteractArea.body_entered.connect(_on_body_entered)
	$InteractArea.body_exited.connect(_on_body_exited)

## Reabastecimiento entre oleadas: el cofre se cierra y puede volver a
## abrirse, con botín del nivel de la oleada actual. RPC: lo emite el host
## (dueño de las oleadas) y la tapa se cierra en todas las máquinas.
@rpc("authority", "call_local", "reliable")
func restock(new_loot_level: int) -> void:
	loot_level = new_loot_level
	_opened = false
	var tween := create_tween()
	tween.tween_property(lid_pivot, "rotation:x", 0.0, 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	prompt.visible = _player_in_range

func _physics_process(_delta: float) -> void:
	if _player_in_range and not _opened and Input.is_action_just_pressed("interact"):
		# Solo el host spawnea drops replicados: un cliente PIDE abrir (el
		# cofre existe con el mismo path en todas las máquinas).
		_request_open.rpc_id(1)

@rpc("any_peer", "call_local", "reliable")
func _request_open() -> void:
	if not multiplayer.is_server() or _opened:
		return
	_open.rpc() # abre la tapa en TODAS las máquinas; los drops los replica el spawner

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		prompt.visible = not _opened

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		prompt.visible = false

@rpc("authority", "call_local", "reliable")
func _open() -> void:
	_opened = true
	prompt.visible = false
	var tween := create_tween()
	tween.tween_property(lid_pivot, "rotation:x", -1.9, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# El contenido lo genera SOLO el host (los drops llegan replicados).
	if multiplayer.is_server():
		_spill_content()

## Genera el contenido y lo "derrama" al suelo en anillo alrededor del
## cofre. Instanciado POR JUGADOR (E1.7): cada jugador vivo recibe SU
## tirada completa y solo ve la propia (comparten anillo sin molestarse).
func _spill_content() -> void:
	for player in Players.alive(get_tree()):
		_spill_for(player.get_multiplayer_authority())

func _spill_for(owner_peer: int) -> void:
	var offhand_type: StringName = [&"shield", &"orb"].pick_random()
	var items: Array[LootItem] = [
		Loot.generate_random_item(loot_level, &"armor"),
		Loot.generate_random_item(loot_level, &"helmet"),
		Loot.generate_random_item(loot_level, &"cape"),
		Loot.generate_random_item(loot_level, &"gloves"),
		Loot.generate_random_item(loot_level, offhand_type),
	]
	for weapon_type in WEAPON_TYPES:
		items.append(Loot.generate_random_item(loot_level, weapon_type))
	for i in health_potions:
		items.append(Loot.make_potion(&"potion_health"))

	for i in items.size():
		var item := items[i]
		if item == null:
			continue
		var drop := NetSpawn.drop(DROP_SCENE, item,
			global_position + Vector3.UP * 0.9, get_parent(), owner_peer)

		var angle := TAU * float(i) / items.size() + randf_range(-0.3, 0.3)
		var dist := randf_range(1.3, 2.2)
		var target := global_position + Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		var tween := drop.create_tween()
		tween.tween_property(drop, "global_position", target, 0.35) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
