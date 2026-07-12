## Autoload "NetSpawn" (E1.3): punto único para instanciar lo que aparece
## durante la partida — enemigos, drops y proyectiles. Si el nivel tiene un
## SpawnRoot registrado, el spawn pasa por su MultiplayerSpawner: el host crea
## el nodo y los clientes lo reconstruyen desde el mismo diccionario de datos
## (todo serializable: las escenas viajan como path y los LootItem como
## to_save_dict()). Sin SpawnRoot (tests, escenas sueltas) cae al add_child
## clásico en el fallback_parent — idéntico al single-player de siempre.
##
## Convención de coordenadas: "position"/"transform" en props son LOCALES al
## contenedor. SpawnRoot vive en el origen del nivel, así que equivalen a
## globales; los fallback_parent de los tests también están en el origen.
extends Node

enum Kind { ENEMY, DROP, PROJECTILE, PLAYER }

## SpawnRoot del nivel activo (null = sin replicación, modo clásico).
var _root: Node = null

func register_root(root: Node) -> void:
	_root = root

func unregister_root(root: Node) -> void:
	if _root == root:
		_root = null

## Enemigo bajo el contenedor replicado. `props` se aplican con set() ANTES de
## entrar al árbol (el _ready del enemigo ya los ve). `scene_props` son
## propiedades PackedScene: viajan como path y se cargan al reconstruir.
func enemy(scene: PackedScene, props: Dictionary, fallback_parent: Node, scene_props: Dictionary = {}) -> Node:
	return _spawn(Kind.ENEMY,
		{"scene": scene.resource_path, "props": props, "scene_props": scene_props},
		fallback_parent)

## Drop de botín: el LootItem viaja serializado y se reconstruye contra
## LootDB. `owner_peer` != 0 = loot instanciado por jugador (E1.7): solo ese
## peer lo ve/recoge; 0 = para todos (pociones del mundo).
func drop(scene: PackedScene, item: LootItem, position: Vector3, fallback_parent: Node, owner_peer: int = 0) -> Node:
	return _spawn(Kind.DROP,
		{"scene": scene.resource_path,
			"props": {"position": position, "owner_peer": owner_peer},
			"item": item.to_save_dict()},
		fallback_parent)

## Player de un peer (E1.5): el nodo queda con autoridad de ese peer en host
## y clientes (viaja en el diccionario y build() la aplica en ambos lados).
func player(scene: PackedScene, peer_id: int, props: Dictionary, fallback_parent: Node) -> Node:
	return _spawn(Kind.PLAYER,
		{"scene": scene.resource_path, "props": props, "peer": peer_id},
		fallback_parent)

## Proyectil / efecto de combate transitorio (bolts, novas, slashes...).
## Con `source` != null el spawn aplica él mismo el setup(damage, source,
## crit) de combate — y si el que castea es un CLIENTE, el pedido viaja por
## RPC al host (única autoridad del MultiplayerSpawner: spawner.spawn() en
## un cliente falla con "!is_multiplayer_authority()"). En ese caso devuelve
## null: el visual llega replicado y el daño lo resuelve el host.
func projectile(scene: PackedScene, props: Dictionary, fallback_parent: Node,
		damage: float = 0.0, source: Node = null, crit: bool = false) -> Node:
	if _root and Net.is_online() and not multiplayer.is_server():
		_request_projectile.rpc_id(1, scene.resource_path, props, damage, crit)
		return null
	var node := _spawn(Kind.PROJECTILE, {"scene": scene.resource_path, "props": props}, fallback_parent)
	if source != null and node.has_method("setup"):
		node.setup(damage, source, crit)
	return node

## Un cliente pide castear: el host spawnea (el visual se replica a todos)
## y hace el setup() con el player del peer que lo pidió como fuente.
@rpc("any_peer", "reliable")
func _request_projectile(scene_path: String, props: Dictionary, damage: float, crit: bool) -> void:
	if not multiplayer.is_server() or _root == null:
		return
	var peer := multiplayer.get_remote_sender_id()
	var source: Node = null
	for player in get_tree().get_nodes_in_group("player"):
		if player.get_multiplayer_authority() == peer:
			source = player
			break
	var node := _spawn(Kind.PROJECTILE, {"scene": scene_path, "props": props}, _root)
	if node and source != null and node.has_method("setup"):
		node.setup(damage, source, crit)

func _spawn(kind: Kind, data: Dictionary, fallback_parent: Node) -> Node:
	if _root:
		var spawner: MultiplayerSpawner = _root.spawner_for(kind)
		if spawner:
			return spawner.spawn(data)
	var node := build(data)
	fallback_parent.add_child(node)
	return node

## Reconstruye un nodo desde el diccionario de spawn. Es la spawn_function de
## los MultiplayerSpawner del SpawnRoot: corre igual en host y clientes.
func build(data: Dictionary) -> Node:
	var scene := load(data["scene"]) as PackedScene
	var node := scene.instantiate()
	var props: Dictionary = data.get("props", {})
	for key: String in props:
		node.set(key, props[key])
	var scene_props: Dictionary = data.get("scene_props", {})
	for key: String in scene_props:
		node.set(key, load(scene_props[key]))
	if data.has("item"):
		node.set("item", LootItem.from_save_dict(data["item"]))
	if data.has("peer"):
		node.set_multiplayer_authority(int(data["peer"]))
	return node
