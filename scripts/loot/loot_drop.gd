extends Area3D

var item: LootItem = null

## Dueño del drop (E1.7: loot instanciado por jugador). 0 = para todos
## (pociones del mundo); != 0 = SOLO ese peer lo ve y lo puede recoger —
## el resto ni renderiza ni colisiona (el equipo se rollea una vez por
## jugador, así nadie compite por el botín).
var owner_peer: int = 0

@onready var light: OmniLight3D = $OmniLight3D
@onready var visual_mesh: MeshInstance3D = $Visual/Mesh
@onready var visual: Node3D = $Visual

var hover_time: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if owner_peer != 0 and owner_peer != multiplayer.get_unique_id():
		visible = false
		monitoring = false # sin colisión: body_entered nunca dispara acá
		set_process(false)

	if item:
		var color = item.ui_color()
		light.light_color = color
		
		# Cambiar color del material para coincidir con la rareza
		var mat = visual_mesh.get_surface_override_material(0)
		if mat == null:
			mat = StandardMaterial3D.new()
			mat.diffuse_mode = StandardMaterial3D.DIFFUSE_TOON
			visual_mesh.set_surface_override_material(0, mat)
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.5

func _process(delta: float) -> void:
	hover_time += delta * 2.0
	visual.position.y = sin(hover_time) * 0.2 + 0.5
	visual.rotate_y(delta * 1.5)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player") or item == null:
		return
	# En co-op el drop existe en todas las máquinas: recoge SOLO la máquina
	# dueña del player que lo tocó (su vida/inventario son locales).
	if not body.is_multiplayer_authority():
		return
	# Loot instanciado: si tiene dueño, solo su peer lo recoge (defensa
	# extra — para los demás ya está invisible y sin colisión).
	if owner_peer != 0 and owner_peer != multiplayer.get_unique_id():
		return

	# Consumibles: se aplican AL TOCAR (llenan vida/maná al instante).
	if item.is_consumable():
		if body.has_method("heal"):
			body.heal(item.effective(&"restore_health"))
		if body.has_method("restore_mana"):
			body.restore_mana(item.effective(&"restore_mana"))
		FX.burst(global_position + Vector3(0, 0.5, 0), item.ui_color(), 10, 0.06)
		_despawn()
		return

	# Equipo: al inventario (la decisión de equipar es del jugador).
	if not body.has_method("pick_up"):
		return
	if not body.pick_up(item):
		return # inventario lleno: el drop queda en el suelo
	print("[Loot] recogido: %s" % item.display_name)
	_despawn()

## Solo el host puede liberar un nodo replicado (el MultiplayerSpawner avisa
## el despawn al resto); un cliente que recogió le pide el despawn por RPC.
func _despawn() -> void:
	item = null # ya entregado: ignorar toques hasta que el host lo libere
	if multiplayer.is_server():
		queue_free()
	else:
		_request_despawn.rpc_id(1)

@rpc("any_peer", "reliable")
func _request_despawn() -> void:
	if multiplayer.is_server():
		queue_free()
