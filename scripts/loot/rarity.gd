## Rareza estilo Borderlands: el color define cantidad y calidad de afijos.
##
## Mapeo del brief (común->raro->épico->legendario). El brief mezclaba
## "verde/azul" en raro; aquí se separan en UNCOMMON (verde) y RARE (azul)
## para tener una curva de progresión más limpia (5 escalones).
class_name Rarity
extends RefCounted

enum Tier { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

const NAMES := {
	Tier.COMMON: "Común",
	Tier.UNCOMMON: "Poco común",
	Tier.RARE: "Raro",
	Tier.EPIC: "Épico",
	Tier.LEGENDARY: "Legendario",
}

## Colores de UI por rareza (blanco -> verde -> azul -> morado -> naranjo).
const COLORS := {
	Tier.COMMON: Color(0.90, 0.90, 0.90),
	Tier.UNCOMMON: Color(0.30, 0.78, 0.33),
	Tier.RARE: Color(0.18, 0.55, 1.00),
	Tier.EPIC: Color(0.69, 0.30, 1.00),
	Tier.LEGENDARY: Color(1.00, 0.54, 0.12),
}

## Rango [min, max] de afijos por rareza. Pocos y legibles: el poder del
## ítem viene de sus stats base × STAT_MULT, no de una sopa de sufijos.
const AFFIX_RANGE := {
	Tier.COMMON: Vector2i(0, 0),
	Tier.UNCOMMON: Vector2i(0, 1),
	Tier.RARE: Vector2i(1, 1),
	Tier.EPIC: Vector2i(1, 2),
	Tier.LEGENDARY: Vector2i(1, 2),
}

## Multiplicador de los stats BASE del ítem por rareza: un épico se lee al
## instante (×2 de lo que hace la base).
const STAT_MULT := {
	Tier.COMMON: 1.0,
	Tier.UNCOMMON: 1.3,
	Tier.RARE: 1.6,
	Tier.EPIC: 2.0,
	Tier.LEGENDARY: 2.5,
}

## Multiplicador de calidad: rarezas altas tiran valores más cerca del techo.
const QUALITY_MULT := {
	Tier.COMMON: 0.70,
	Tier.UNCOMMON: 0.90,
	Tier.RARE: 1.10,
	Tier.EPIC: 1.30,
	Tier.LEGENDARY: 1.60,
}

## Peso base de drop (cuanto más alto, más frecuente).
const DROP_WEIGHT := {
	Tier.COMMON: 1000,
	Tier.UNCOMMON: 420,
	Tier.RARE: 160,
	Tier.EPIC: 45,
	Tier.LEGENDARY: 7,
}

static func color(tier: int) -> Color:
	return COLORS.get(tier, Color.WHITE)

static func stat_mult(tier: int) -> float:
	return STAT_MULT.get(tier, 1.0)

static func display_name(tier: int) -> String:
	return NAMES.get(tier, "?")
