# GDD — ARPG de Insectos (título provisional)

> Documento de diseño. El **estado real de implementación** está en `IMPLEMENTED_FEATURES.md`; el **cómo técnico** en `docs/ARCHITECTURE.md`; las **tareas** en `docs/BACKLOG.md`. Este doc es la fuente de verdad de DISEÑO.

## 1. Visión y pilares
ARPG **cooperativo** con temática de **insectos** que **descienden** por una ciudad subterránea corrompida. Twin-stick (teclado+mouse o mando). Farmeo con peso (economía Tibia) y combos arma×clase.

**Pilares:**
1. **Descenso narrativo** — ciudades-insecto atravesadas por historia, no "pisos" que repites.
2. **Combos arma × clase** — el arma da los clicks (LMB/RMB), la clase da Q/R; combinarlos es la profundidad.
3. **Farmeo con peso (Tibia)** — oro escaso, muerte que castiga (XP + loot), 3 ejes de progresión.
4. **La Corrupción como reloj** — la infección presiona al mundo *y* al jugador. **Mecánica central.**

## 2. Decisiones cerradas
- **Cooperativo** (party; hasta 4). Roles: Tanque, Carry, Especialista, Heal (+2 clases especiales a futuro).
- **Mundo:** **ciudades fijas persistentes** (hubs) que conectan a **zonas construidas proceduralmente pero FIJAS** (se generan una vez y persisten; no se regeneran cada visita → mundo Tibia, no roguelike de corridas).
- **Corrupción: mecánica central** (ver §5).
- **Muerte (Tibia):** pierdes algo de **XP** y **loot aleatorio no equipado**; reapareces en la última ciudad. El mundo persiste (no reinicia).
- **Progresión:** **XP** (nivel → vida/maná) + **skills por uso** (magia, arma, por elemento; muy Tibia) + **gear**. Level-up rellena vida/maná al 100%.
- **Economía:** **oro escaso**, comprar es caro → farmear es necesario. Banco/depot expandible con oro.
- **Loot:** rareza **común → especial → raro → leyenda**; escala con nivel/dificultad de obtención (boss suelta arma fuerte con poder único).
- **Exploración con ramificaciones** (buscar loot, encontrarte enemigos, estilo Borderlands). **No oleadas.**

## 3. Clases y kit
5 slots por personaje, **idénticos en estructura** para todas las clases:
| Slot | Origen | Descripción |
|------|--------|-------------|
| **LMB** (click izq) | **Arma** | Ataque primario del arma |
| **RMB** (click der) | **Arma** | Ataque secundario del arma |
| **Espacio** | Clase/base | Movilidad: dash o blink (sin daño) |
| **Q** | **Clase** | Habilidad media / AOE (cuesta maná o stamina) |
| **R** | **Clase** | Ultimate (coste mayor, daño alto) |

- Cada **arma** tiene poderes **distintos a las demás** → armas × clases = espacio de combos.
- **Roles co-op:** Tanque (sustain/aggro), Carry (daño), Especialista (control/utilidad), Heal (soporte de party). Los **crímenes de cada condenado justifican el arquetipo** (contenido narrativo).

## 4. Sistema de combos (motor de la profundidad)
Las habilidades aplican y detonan **tags de estado** → los combos son **sistémicos**, no hardcodeados:
- **Aplican:** Quemado, Congelado, Corroído, Marcado, Sangrado, Aturdido.
- **Detonan:** ciertas habilidades consumen tags por bonus (ej. arma ígnea aplica *Quemado*; la R de la clase detona *Quemados* en explosión).
- Diseño: cada arma y cada Q/R declara qué tags **aplica** y cuáles **detona**. Nuevas armas/clases entran al sistema sin tocar las demás.

## 5. La Corrupción (mecánica central)
Un medidor de **Corrupción** por jugador:
- **Sube** con el tiempo en zona infectada, por golpes de infectados y por cercanía a nodos de infección.
- **Presiona el mundo (reloj activo):** a más corrupción de zona, los **enemigos mutan** (más rápidos/fuertes, nuevos ataques) y pueden **infectar a otros**. Tardar = pelea más dura.
- **Riesgo/beneficio al jugador** (estilo locura de Darkest Dungeon): baja = seguro; alta = +daño pero -defensa, *loot corrupto* (mejor pero riesgoso), efectos adversos.
- **Se limpia** en ciudades (zona segura) o con objetos.
- **Loop central:** *"quédate más para farmear más → la Corrupción sube → los bichos mutan → arriesgas morir (XP+loot)."* Empuja tu suerte, castiga la avaricia. Ata farmeo + tensión + muerte.

## 6. Control (PC ↔ mando, calzan 1:1)
| Acción | Teclado/Mouse | Mando |
|--------|---------------|-------|
| Mover | WASD | Stick izq |
| Apuntar | Mouse | Stick der |
| Arma primario | Click izq | **RT** |
| Arma secundario | Click der | **LT** |
| Q (clase) | Q | **RB** |
| R (ultimate) | R | **LB** (mantener) |
| Dash / blink | Espacio | **A** |
| Interactuar | E | **X** |
| Poción rápida | 1 / 2 | **B** / D-pad |
| Inventario | I / Tab | **Y** o Start |
| Pausa | ESC | Menú/Start |

## 7. Economía y recursos
- **Oro** escaso; sumideros: tienda, herrería (mejora de armas), banco (espacio), pociones grandes.
- **Pociones planas** (curan X fijo): al crecer tu pool curan proporcionalmente menos → obligan a comprar pociones mayores (sumidero + incentivo de farmeo).
- **Vida/maná NO se regeneran solos**: se recuperan con drops de enemigos, objetos pasivos (ej. botas que suben maná para magos), skills, y el level-up (rellena al 100%).

## 8. Estructura de mundo
- **Ciudades (hubs) fijas y persistentes:** base, NPCs, tienda, herrería, banco, limpieza de corrupción, beats de historia.
- **Zonas de exploración:** construidas proceduralmente **una vez** y luego **fijas/persistentes**; con ramificaciones, loot y encuentros. Cada zona tiene **espina narrativa** (ruta + boss + eventos únicos) que la hace memorable (evita el "todo se repite").
- **Descenso:** ganar al boss de una ciudad/área **abre el avance** por hechos narrativos particulares.

## 9. Narrativa → mecánica
- **Corrupción** afecta también al jugador (§5).
- **Crímenes = clases** (cada condenado, un arquetipo).
- **Facciones/colonias** con peso de gameplay (aliados, mercaderes, misiones) — historia compleja.
- **Infección como amenaza activa** (mutación por tiempo, contagio) — §5.

## 10. Estado del prototipo (reutilizable)
El repo ya tiene un prototipo **single-player** funcional que cubre gran parte de §3–§8 en versión mago (clases, kit arma×clase, loot con rareza, skills por uso, XP, dash, mundo procedural, minimapa, mando, pausa). **Se re-tematiza a insectos y se convierte a co-op.** El mayor trabajo NO hecho: **networking/co-op**, **guardado/persistencia**, **corrupción**, **facciones**, **ciudades-hub**. Ver `docs/BACKLOG.md`.

## 11. Decisiones aún abiertas (para próximas iteraciones)
- Tamaño de party (¿2 o 4?) y si se puede jugar solo con bots/escala.
- Cómo se comparte el loot en co-op (instanciado por jugador vs. compartido).
- Número final de armas y de tags de estado.
- ¿La corrupción es por-jugador o compartida por la party?
