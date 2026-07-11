## Contenedores replicados del nivel (E1.3): enemigos, drops y proyectiles se
## cuelgan de acá vía NetSpawn para que cada MultiplayerSpawner los replique
## host → clientes. DEBE quedar en el origen del nivel: las posiciones de
## spawn llegan como locales al contenedor (ver doc de NetSpawn).
extends Node3D

@onready var _spawners := {
	NetSpawn.Kind.ENEMY: $EnemiesSpawner as MultiplayerSpawner,
	NetSpawn.Kind.DROP: $DropsSpawner as MultiplayerSpawner,
	NetSpawn.Kind.PROJECTILE: $ProjectilesSpawner as MultiplayerSpawner,
	NetSpawn.Kind.PLAYER: $PlayersSpawner as MultiplayerSpawner,
}

func _ready() -> void:
	for spawner: MultiplayerSpawner in _spawners.values():
		spawner.spawn_function = NetSpawn.build
	NetSpawn.register_root(self)

func _exit_tree() -> void:
	NetSpawn.unregister_root(self)

func spawner_for(kind: NetSpawn.Kind) -> MultiplayerSpawner:
	return _spawners.get(kind)
