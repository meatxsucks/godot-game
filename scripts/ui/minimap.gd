## Minimapa con niebla de guerra (abajo a la derecha): el mundo se revela
## a medida que exploras. Dibujado 100% por código, sin assets ni viewports.
class_name Minimap
extends Control

## Límites del mundo en XZ (el piso de la Arena es 64×64).
const WORLD_MIN := Vector2(-32, -32)
const WORLD_MAX := Vector2(32, 32)
## Metros por celda de niebla y radio revelado alrededor del jugador.
const CELL := 2.0
const REVEAL_RADIUS := 9.0

var _revealed := {} # Vector2i (celda) -> true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		_reveal_around(player.global_position)
	queue_redraw()

func _reveal_around(pos: Vector3) -> void:
	var reach := int(ceil(REVEAL_RADIUS / CELL))
	var center := _cell_of(pos)
	for dx in range(-reach, reach + 1):
		for dz in range(-reach, reach + 1):
			if Vector2(dx, dz).length() * CELL <= REVEAL_RADIUS:
				_revealed[center + Vector2i(dx, dz)] = true

func _cell_of(pos: Vector3) -> Vector2i:
	return Vector2i(int(floor(pos.x / CELL)), int(floor(pos.z / CELL)))

func _is_revealed(pos: Vector3) -> bool:
	return _revealed.has(_cell_of(pos))

func _world_to_px(pos: Vector3) -> Vector2:
	var u := (pos.x - WORLD_MIN.x) / (WORLD_MAX.x - WORLD_MIN.x)
	var v := (pos.z - WORLD_MIN.y) / (WORLD_MAX.y - WORLD_MIN.y)
	return Vector2(u * size.x, v * size.y)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.04, 0.07, 0.85))

	# Terreno revelado.
	var cell_px := size.x * CELL / (WORLD_MAX.x - WORLD_MIN.x)
	for cell in _revealed:
		var world_pos := Vector3(cell.x * CELL, 0, cell.y * CELL)
		var px := _world_to_px(world_pos)
		if px.x < -cell_px or px.y < -cell_px or px.x > size.x or px.y > size.y:
			continue
		draw_rect(Rect2(px, Vector2(cell_px + 1.0, cell_px + 1.0)), Color(0.16, 0.18, 0.22, 0.9))

	# Zona segura (disco cian).
	var zone = get_tree().get_first_node_in_group("safe_zone")
	if zone and _is_revealed(zone.global_position):
		var radius_px: float = zone.radius * size.x / (WORLD_MAX.x - WORLD_MIN.x)
		draw_circle(_world_to_px(zone.global_position), radius_px, Color(0.2, 0.7, 0.8, 0.35))

	# Cofres (dorado, si su zona está revelada).
	for chest in get_tree().get_nodes_in_group("chest"):
		if chest is Node3D and _is_revealed(chest.global_position):
			draw_circle(_world_to_px(chest.global_position), 3.0, Color(1, 0.8, 0.2))

	# Portales de oleada (siempre visibles: son el telegrafiado).
	for portal in get_tree().get_nodes_in_group("spawn_portal"):
		if portal is Node3D:
			draw_circle(_world_to_px(portal.global_position), 3.0, Color(0.7, 0.35, 1))

	# Enemigos (rojos, solo en zonas reveladas).
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node3D and _is_revealed(enemy.global_position):
			draw_circle(_world_to_px(enemy.global_position), 2.0, Color(1, 0.25, 0.2))

	# Jugador.
	var player = get_tree().get_first_node_in_group("player")
	if player:
		draw_circle(_world_to_px(player.global_position), 3.0, Color.WHITE)

	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.9), false, 2.0)
