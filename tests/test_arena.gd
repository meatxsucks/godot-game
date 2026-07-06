extends Node

func _ready():
	print("TESTING IN ARENA...")
	# Esperar un poco para que la escena cargue y genere al player
	await get_tree().create_timer(1.0).timeout
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("NO PLAYER IN ARENA")
		get_tree().quit(1)
		return
		
	print("EQUIPPING ORB...")
	var orb = LootItem.new()
	orb.base = LootDB.item_bases.filter(func(b): return b.id == &"orb_quartz")[0]
	player.stats.equip(orb)
	
	print("CASTING LMB...")
	player._try_cast(0)
	
	await get_tree().create_timer(0.5).timeout
	print("ARENA TEST OK")
	get_tree().quit(0)
