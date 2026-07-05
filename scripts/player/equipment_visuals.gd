## Equipo visible en el personaje (paper-doll v2). Dos técnicas:
## - MANOS: props externos del pack anclados a los huesos handslot.r/.l
##   con BoneAttachment3D (arma derecha, escudo/libro izquierda) — se ven
##   en la mano y siguen las animaciones en las 3 clases.
## - OUTFIT: meshes integrados del modelo (sombrero/casco = cabeza,
##   CAPA = torso/túnica) que se muestran/ocultan según lo equipado.
## Arranca todo oculto: personaje sin equipo. Anillo/botas: sin visual.
class_name EquipmentVisuals
extends Node

## Props de mano por id de base (iguales para las 3 clases: el ítem se
## reconoce). "hand": r = arma, l = offhand.
const PROPS := {
	&"wand_bone": {"scene": "res://assets/kaykit/props/wand.gltf", "hand": "r"},
	&"staff_oak": {"scene": "res://assets/kaykit/props/staff.gltf", "hand": "r"},
	&"sword_war": {"scene": "res://assets/kaykit/props/sword_2handed.gltf", "hand": "r"},
	&"shield_wood": {"scene": "res://assets/kaykit/props/shield_round.gltf", "hand": "l"},
	&"orb_quartz": {"scene": "res://assets/kaykit/props/spellbook_open.gltf", "hand": "l"},
}

## Meshes integrados por clase → id de base que los enciende (túnica = capa).
const BUILTIN_VISUALS := {
	&"mage": {&"robe_linen": "Mage_Cape"},
	&"warrior": {&"robe_linen": "Knight_Cape"},
	&"ranger": {&"robe_linen": "Rogue_Cape"},
}

## TODOS los meshes de accesorio integrados: se ocultan al inicio y solo
## se encienden los mapeados arriba.
const ACCESSORY_MESHES := {
	&"mage": ["Spellbook", "Spellbook_open", "1H_Wand", "2H_Staff", "Mage_Hat", "Mage_Cape"],
	&"warrior": ["1H_Sword_Offhand", "Badge_Shield", "Rectangle_Shield", "Round_Shield", "Spike_Shield", "1H_Sword", "2H_Sword", "Knight_Helmet", "Knight_Cape"],
	&"ranger": ["Knife_Offhand", "1H_Crossbow", "2H_Crossbow", "Knife", "Throwable", "Rogue_Cape"],
}

var _player: Node = null
var _meshes := {} # nombre -> MeshInstance3D (integrados)
var _attach_r: BoneAttachment3D = null
var _attach_l: BoneAttachment3D = null

## Registra meshes, crea los anclajes de mano y se conecta al equipo.
func setup(player: Node, model: Node) -> void:
	_player = player
	var managed: Array = ACCESSORY_MESHES.get(Game.selected_class, [])
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		if managed.has(String(mesh.name)):
			_meshes[String(mesh.name)] = mesh

	# Anclajes en los huesos de las manos del rig KayKit.
	var skeletons := model.find_children("*", "Skeleton3D", true, false)
	if not skeletons.is_empty():
		var skeleton: Skeleton3D = skeletons[0]
		_attach_r = _make_attachment(skeleton, "handslot.r")
		_attach_l = _make_attachment(skeleton, "handslot.l")

	player.item_equipped.connect(_on_item_equipped)
	player.stats_changed.connect(refresh)
	refresh()

func _make_attachment(skeleton: Skeleton3D, bone: String) -> BoneAttachment3D:
	if skeleton.find_bone(bone) < 0:
		return null
	var attachment := BoneAttachment3D.new()
	skeleton.add_child(attachment)
	attachment.bone_name = bone
	return attachment

func _on_item_equipped(_item, _previous) -> void:
	refresh()

## Sincroniza el visual completo con el equipo actual.
func refresh() -> void:
	# Apagar todo (integrados) y vaciar las manos.
	for mesh in _meshes.values():
		mesh.visible = false
	_clear_hand(_attach_r)
	_clear_hand(_attach_l)

	var builtin: Dictionary = BUILTIN_VISUALS.get(Game.selected_class, {})
	for slot in _player.stats.equipment:
		var item = _player.stats.equipment[slot]
		if item == null or item.base == null:
			continue
		var id: StringName = item.base.id

		# Outfit integrado (sombrero/casco, capa).
		var mesh_name: String = builtin.get(id, "")
		if mesh_name != "" and _meshes.has(mesh_name):
			_meshes[mesh_name].visible = true

		# Prop en la mano.
		if PROPS.has(id):
			var prop: Dictionary = PROPS[id]
			var attachment := _attach_r if prop["hand"] == "r" else _attach_l
			if attachment:
				var scene = load(prop["scene"])
				if scene:
					attachment.add_child(scene.instantiate())

func _clear_hand(attachment: BoneAttachment3D) -> void:
	if attachment == null:
		return
	for child in attachment.get_children():
		child.queue_free()
