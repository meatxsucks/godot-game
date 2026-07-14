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
		# Forma propia por tipo: MONEDA (disco dorado que gira de canto),
		# POCIÓN (frasco/orbe), OBJETO (gema de rareza) — de un vistazo sabés
		# qué es sin recogerlo. El material lo comparten (toon + emissive).
		var color = item.ui_color()
		_kind = _drop_kind()
		visual_mesh.mesh = _mesh_for_kind(_kind)
		light.light_color = color
		light.light_energy = 2.6 if _kind == &"gold" else 2.0

		var mat := StandardMaterial3D.new()
		mat.diffuse_mode = StandardMaterial3D.DIFFUSE_TOON
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.9 if _kind == &"gold" else 0.5
		if _kind == &"gold":
			mat.metallic = 0.8
			mat.roughness = 0.25
		visual_mesh.set_surface_override_material(0, mat)

## Categoría visual del drop.
func _drop_kind() -> StringName:
	if item.base == null:
		return &"item"
	if item.base.type == &"gold":
		return &"gold"
	if item.is_consumable():
		return &"potion"
	return &"item"

func _mesh_for_kind(kind: StringName) -> Mesh:
	match kind:
		&"gold":
			var coin := CylinderMesh.new()
			coin.top_radius = 0.26
			coin.bottom_radius = 0.26
			coin.height = 0.08
			return coin
		&"potion":
			var orb := SphereMesh.new()
			orb.radius = 0.22
			orb.height = 0.44
			return orb
		_:
			var gem := PrismMesh.new()
			gem.size = Vector3(0.5, 0.5, 0.5)
			return gem

## Categoría del drop (gold/potion/item), para el spin distinto.
var _kind: StringName = &"item"

func _process(delta: float) -> void:
	hover_time += delta * 2.0
	visual.position.y = sin(hover_time) * 0.2 + 0.5
	# La moneda "gira de canto" (vuelta de moneda); lo demás gira plano.
	if _kind == &"gold":
		visual.rotate_z(delta * 4.0)
	else:
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

	# Oro (E5.1): directo al bolsillo, nunca al inventario.
	if item.base and item.base.type == &"gold":
		if body.has_method("add_gold"):
			body.add_gold(item.item_level)
		FX.burst(global_position + Vector3(0, 0.5, 0), Color(1.0, 0.85, 0.2), 12, 0.06)
		_despawn()
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
