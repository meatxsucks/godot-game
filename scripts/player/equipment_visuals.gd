## Equipo visible en el personaje (paper-doll): los modelos KayKit traen los
## accesorios como meshes integrados al rig. Se ocultan TODOS al inicio
## (personaje sin equipo) y se muestran según lo equipado — cada clase luce
## su versión temática del ítem (el Bastón de guerra es espadón en el
## Guerrero y ballesta pesada en el Explorador).
class_name EquipmentVisuals
extends Node

## Meshes de accesorio que este sistema gestiona, por clase.
const ACCESSORY_MESHES := {
	&"mage": ["Spellbook", "Spellbook_open", "1H_Wand", "2H_Staff", "Mage_Hat"],
	&"warrior": ["1H_Sword_Offhand", "Badge_Shield", "Rectangle_Shield", "Round_Shield", "Spike_Shield", "1H_Sword", "2H_Sword", "Knight_Helmet"],
	&"ranger": ["Knife_Offhand", "1H_Crossbow", "2H_Crossbow", "Knife", "Throwable"],
}

## (clase → id de base del ítem → mesh a mostrar). Ítems sin entrada
## (anillo, túnica, botas...) simplemente no tienen visual.
const VISUALS := {
	&"mage": {
		&"wand_bone": "1H_Wand",
		&"staff_oak": "2H_Staff",
		&"staff_war": "2H_Staff",
		&"orb_quartz": "Spellbook_open",
		&"hat_cloth": "Mage_Hat",
	},
	&"warrior": {
		&"wand_bone": "1H_Sword",
		&"staff_oak": "1H_Sword",
		&"staff_war": "2H_Sword",
		&"shield_wood": "Round_Shield",
		&"orb_quartz": "Badge_Shield",
		&"hat_cloth": "Knight_Helmet",
	},
	&"ranger": {
		&"wand_bone": "Knife",
		&"staff_oak": "1H_Crossbow",
		&"staff_war": "2H_Crossbow",
		&"shield_wood": "Knife_Offhand",
	},
}

var _player: Node = null
var _meshes := {} # nombre -> MeshInstance3D

## Registra los meshes del modelo y se conecta a las señales de equipo.
func setup(player: Node, model: Node) -> void:
	_player = player
	var managed: Array = ACCESSORY_MESHES.get(Game.selected_class, [])
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		if managed.has(String(mesh.name)):
			_meshes[String(mesh.name)] = mesh
	player.item_equipped.connect(_on_item_equipped)
	player.stats_changed.connect(refresh)
	refresh()

func _on_item_equipped(_item, _previous) -> void:
	refresh()

## Oculta todos los accesorios y enciende los del equipo actual.
func refresh() -> void:
	for mesh in _meshes.values():
		mesh.visible = false
	var map: Dictionary = VISUALS.get(Game.selected_class, {})
	for slot in _player.stats.equipment:
		var item = _player.stats.equipment[slot]
		if item == null or item.base == null:
			continue
		var mesh_name: String = map.get(item.base.id, "")
		if mesh_name != "" and _meshes.has(mesh_name):
			_meshes[mesh_name].visible = true
