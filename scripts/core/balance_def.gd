## Balance central del juego (E10.7): TODOS los knobs de curvas, drops y
## dificultad viven en `resources/balance.tres` — se tunean en el inspector
## sin tocar código (patrón data-driven E0.7). Los números por-habilidad
## (cooldown, coste, multiplicador propio) son identidad del poder y viven
## en su clase; lo GLOBAL vive acá.
class_name BalanceDef
extends Resource

# --- XP del personaje (curva creciente: cada nivel cuesta más) --------------
@export var xp_base: float = 60.0
@export var xp_power: float = 1.7
@export var xp_scale: float = 25.0

# --- Ganancias por level-up (rellena vida/maná al 100% aparte) --------------
@export var level_up_hp: float = 10.0
@export var level_up_mana: float = 5.0
@export var level_up_dmg: float = 1.0

# --- Escala global de daño del jugador por nivel ----------------------------
@export var level_dmg_base: float = 0.6
@export var level_dmg_per_level: float = 0.05
@export var level_dmg_cap: float = 1.5

# --- Skills por uso (curva LENTA: entrenar un elemento toma partidas) -------
@export var skill_xp_base: float = 35.0
@export var skill_xp_power: float = 1.7
@export var skill_xp_scale: float = 20.0

# --- Árbol de talentos (E10.3/E10.6) ----------------------------------------
## 1 punto cada N niveles (decisión 2026-07-17: 3).
@export var levels_per_talent_point: int = 3
## Costo del primer respec; se multiplica por growth en cada uso.
@export var respec_base_gold: int = 50
@export var respec_growth: float = 2.0

# --- Ítems: tier y requisito de nivel (E10.1) -------------------------------
## Cuánto escalan los base_stats por tier del ítem.
@export var tier_stat_mult: float = 0.35
## Penalización de stats por nivel faltante (requisito blando) y su piso.
@export var level_penalty_per_level: float = 0.15
@export var level_penalty_floor: float = 0.25

# --- Oleadas (crecimiento por oleada) ---------------------------------------
@export var wave_hp_growth: float = 0.15
@export var wave_dmg_growth: float = 0.10
@export var wave_atk_speed_growth: float = 0.06
@export var wave_xp_growth: float = 0.05

# --- Cofre (botín austero: la dificultad es OBTENER cosas) ------------------
@export var chest_weapon_count: int = 1
@export var chest_gear_count: int = 2

# --- Oro (E5.1: el recurso de la build — respec, tiendas E5) ----------------
## Cantidad base por drop (se le suma loot_level).
@export var gold_amount_min: int = 2
@export var gold_amount_max: int = 4

# --- Acceso global (carga única, sin autoload) ------------------------------
const PATH := "res://resources/balance.tres"
static var _instance: BalanceDef = null

static func bal() -> BalanceDef:
	if _instance == null:
		_instance = load(PATH) as BalanceDef
		if _instance == null:
			push_error("[Balance] no se pudo cargar %s — usando defaults" % PATH)
			_instance = BalanceDef.new()
	return _instance
