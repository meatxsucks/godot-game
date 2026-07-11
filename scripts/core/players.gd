## Helpers estáticos para operar sobre TODOS los jugadores (grupo "player")
## en vez de get_first_node_in_group("player") — base del co-op (E1.2).
## Con 1 jugador el comportamiento es idéntico al anterior; con N, los
## enemigos targetean al más cercano y las recompensas llegan a todos.
class_name Players


## Jugadores vivos (excluye los que exponen is_alive() y devuelven false).
static func alive(tree: SceneTree) -> Array[Node3D]:
	var result: Array[Node3D] = []
	for node in tree.get_nodes_in_group("player"):
		if node is Node3D and (not node.has_method("is_alive") or node.is_alive()):
			result.append(node)
	return result


## Jugador vivo más cercano a from_position, o null si no hay ninguno.
static func nearest(tree: SceneTree, from_position: Vector3) -> Node3D:
	return nearest_of(alive(tree), from_position)


## Jugador controlado por ESTE peer (cámara/HUD se cuelgan de él). En
## single-player es el único; en co-op, el que tiene autoridad local.
static func local(tree: SceneTree) -> Node3D:
	for node in tree.get_nodes_in_group("player"):
		if node is Node3D and node.is_multiplayer_authority():
			return node
	return null


## Más cercano dentro de una lista ya filtrada (p. ej. sin los que están
## en zona segura), o null si la lista está vacía.
static func nearest_of(candidates: Array[Node3D], from_position: Vector3) -> Node3D:
	var best: Node3D = null
	var best_distance := INF
	for player in candidates:
		var distance := from_position.distance_squared_to(player.global_position)
		if distance < best_distance:
			best_distance = distance
			best = player
	return best
