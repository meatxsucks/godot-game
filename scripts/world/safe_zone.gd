## Zona segura: los enemigos no entran y esperan afuera si el jugador está
## dentro. Ideal para equiparse tranquilo (el cofre vive adentro).
class_name SafeZone
extends Node3D

@export var radius: float = 5.0

@onready var _label: Label3D = $Label

func _ready() -> void:
	add_to_group("safe_zone")
	_label.text = tr(_label.text)

## ¿La posición (en el plano XZ) está dentro de la zona?
func contains(pos: Vector3) -> bool:
	var delta := pos - global_position
	delta.y = 0.0
	return delta.length_squared() <= radius * radius
