## Portal de spawn de oleada: telegrafia dónde aparecerá la próxima oleada
## con un disco emisivo pulsante. Solo visual — el spawner pone los enemigos.
extends Node3D

var _time := 0.0

@onready var disc: MeshInstance3D = $Disc
@onready var light: OmniLight3D = $Light

func _ready() -> void:
	add_to_group("spawn_portal") # el minimapa los dibuja siempre

func _process(delta: float) -> void:
	_time += delta
	var pulse := 0.6 + 0.4 * sin(_time * 5.0)
	light.light_energy = 1.8 * pulse
	disc.scale = Vector3.ONE * (0.9 + 0.15 * sin(_time * 5.0))
	disc.rotate_y(delta * 2.0)
