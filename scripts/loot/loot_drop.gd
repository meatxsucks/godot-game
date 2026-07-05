extends Area3D

var item: LootItem = null

@onready var light: OmniLight3D = $OmniLight3D
@onready var visual_mesh: MeshInstance3D = $Visual/Mesh
@onready var visual: Node3D = $Visual

var hover_time: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
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

	# Consumibles: se aplican AL TOCAR (llenan vida/maná al instante).
	if item.is_consumable():
		if body.has_method("heal"):
			body.heal(item.effective(&"restore_health"))
		if body.has_method("restore_mana"):
			body.restore_mana(item.effective(&"restore_mana"))
		FX.burst(global_position + Vector3(0, 0.5, 0), item.ui_color(), 10, 0.06)
		queue_free()
		return

	# Equipo: al inventario (la decisión de equipar es del jugador).
	if not body.has_method("pick_up"):
		return
	if not body.pick_up(item):
		return # inventario lleno: el drop queda en el suelo
	print("[Loot] recogido: %s" % item.display_name)
	queue_free()
