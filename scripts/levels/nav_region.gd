## Región de navegación de la Arena: bakea el navmesh en runtime a partir de
## los colliders estáticos hijos (piso y muros). Los muros quedan recortados
## del navmesh, así los enemigos rodean hacia la puerta en vez de empujar.
extends NavigationRegion3D

func _ready() -> void:
	bake_navigation_mesh()
