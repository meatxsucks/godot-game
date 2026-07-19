## Alquimista R — SUPER: Reacción en Cadena. Los enemigos cercanos EXPLOTAN
## uno tras otro (pop-pop-pop), cada explosión detona TODOS sus tags y salpica
## daño a los vecinos — reacción en cadena literal. Además toda la party
## recupera vida/maná y por unos segundos los golpes de todos detonan
## cualquier estado. Burst caótico en solo, habilitador de combos en party.
class_name SharedElixirAbility
extends Ability

const CHAIN := preload("res://scenes/magic/ChainReaction.tscn")

const HEAL_PCT := 0.35
const MANA_PCT := 0.5
const PRIME_SECONDS := 5.0

func _init() -> void:
	id = &"shared_elixir"
	display_name = "Reacción en Cadena"
	key_label = "R"
	color = Color(0.55, 0.9, 0.25)
	cooldown = 1.0
	mana_cost = 0.0
	power = 1.0
	element = &"magic"
	is_super = true

func _can_cast(player) -> bool:
	return player.super_charge >= player.SUPER_MAX

func _cast(player) -> Variant:
	if not player.consume_super_charge():
		return false
	FX.shake(0.4)
	# La cadena se centra en el alquimista y explota a los enemigos al alcance.
	# Base LEVE a propósito (E10.4, era 1.4): el árbol de talentos lo potencia.
	var result: Array = player.stats.roll_spell_damage(&"magic", power * damage_scale)
	NetSpawn.projectile(CHAIN, {"position": player.global_position},
		player.get_parent(), result[0], player, result[1])
	# Heal + prime de party (corre en todas las copias de cada aliado: la
	# cura la aplica el dueño; el prime lo lee el host al detonar).
	for ally in Players.alive(player.get_tree()):
		ally.receive_elixir.rpc(HEAL_PCT, MANA_PCT, PRIME_SECONDS)
	return true
