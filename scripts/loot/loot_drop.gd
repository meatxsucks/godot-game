extends Area3D

var item: LootItem = null

@onready var light: OmniLight3D = $OmniLight3D
@onready var visual_mesh: MeshInstance3D = $Visual/Mesh
@onready var visual: Node3D = $Visual

var hover_time: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	if item:
		var color = item.rarity_color()
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
	print("--- LOOT RECOGIDO ---")
	print(item.to_text())
	# Equipar de verdad: aplica los stats del ítem al mago.
	if body.has_method("equip"):
		var previous: LootItem = body.equip(item)
		if previous:
			print("(reemplaza: %s)" % previous.display_name)
	queue_free()
