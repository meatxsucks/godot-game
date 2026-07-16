## Slot 2 — Ventisca (Cetro de escarcha RMB): nova de frío que DETONA Congelado
## en área. Autocombo del cetro: el LMB (Esquirla) congela, este RMB lo revienta
## (E7.2). Visual placeholder: reusa FrostNova hasta el arte de E8.
class_name BlizzardAbility
extends Ability

const SCENE := preload("res://scenes/magic/FrostNova.tscn")

func _init() -> void:
	id = &"blizzard"
	display_name = "Ventisca"
	key_label = "RMB"
	color = Color(0.6, 0.9, 1.0)
	cooldown = 3.5
	mana_cost = 16.0
	element = &"cold"
	detonates = [&"frozen"]

func _cast(player) -> Variant:
	return _spawn_nova(player, SCENE, &"cold_damage", 0.6)
