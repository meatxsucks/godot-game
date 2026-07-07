# AGENTS.md — Reglas para agentes de IA

Este repo lo editan **varios agentes** (Claude, Antigravity, agentes de arte/visual, humanos). Estas reglas evitan que se pisen entre sí. **Léelas ANTES de tocar nada.** Aplican a todos por igual.

## 1. Antes de empezar (obligatorio)
1. Lee `docs/GDD.md` (qué es el juego), `docs/ARCHITECTURE.md` (cómo está hecho) y `docs/BACKLOG.md` (tareas).
2. Toma **UNA** tarea del backlog y márcala `[~] en progreso` con tu nombre de agente. No abras 5 frentes a la vez.
3. Trabaja SOLO dentro de tu **zona de propiedad** (sección 2).

## 2. Zonas de propiedad (no salgas de la tuya sin coordinar)
| Zona | Carpetas / nodos | Qué agente |
|------|------------------|------------|
| **Lógica / gameplay** | `scripts/**`, `tests/**`, lógica de `.tscn` (scripts adjuntos, señales) | Claude, Antigravity |
| **Arte / visual** | `assets/**`, mallas·materiales·luces·partículas dentro del subárbol `Visual` de cada escena, animaciones (`AnimationPlayer`), íconos | Agentes visuales |
| **Niveles / datos** | `scenes/levels/**`, layouts, datos de contenido en `resources/**` (`.tres`) | Diseño de niveles |
| **Docs** | Cada agente actualiza la doc de SU zona | Todos |

> **Regla de oro visual ↔ lógica:** el agente visual **cambia meshes/materiales/animaciones, nunca la lógica de scripts**. El agente de lógica **no toca `assets/` ni reemplaza modelos**. El puente son los **contratos** de la sección 3.

## 3. Contratos intocables (no cambies sin anotarlo como tarea de coordinación)
Cambiar esto rompe el trabajo de otros agentes silenciosamente:
- **Rutas de nodo** que los scripts buscan por ruta: `Visual`, `Visual/Wand`, `Visual/Body`, `LidPivot`, `Prompt`, huesos `handslot.l/.r`, y toda la tabla "Guía para artistas" del `README.md`.
- **Nombres de acciones de input** en `project.godot` (`attack_primary`, `ability_dash`, etc.).
- **Firmas de autoloads** (`Game`, `FX`, `LootDB`, `Loot`, `SceneManager`) y las **señales del player** (`health_changed`, `item_equipped`, `kit_changed`, `died`, …).
- **Formato de guardado** (cuando exista) y los **ids** de habilidades/ítems.
- Constantes-contrato: `Ability.PROJECTILE_HEIGHT`, la propiedad `Ability.is_super`.

## 4. Invariantes / lecciones aprendidas (no las reintroduzcas como bug)
- **Altura de proyectiles = `Ability.PROJECTILE_HEIGHT` (0.55m).** A la altura de la mano pasan por encima de enemigos chicos.
- **Anti-tunneling:** proyectiles rápidos usan el rayo de barrido de `fireball.gd`; no confíes solo en `body_entered`.
- **Tween callbacks** de entidades que pueden morir (boss) van en el **nodo del efecto**, no en el emisor.
- El **flash de daño** debe volver al color BASE, no al color leído.
- Identifica slots especiales por **propiedad** (`is_super`), nunca por id hardcodeado.
- **Co-op:** NUNCA asumas "un solo jugador". Usa grupos/listas; el prototipo usa `get_first_node_in_group("player")` en muchos lados — eso hay que migrar (ver backlog E1).
- `Container` ignora hijos `top_level` (útil para popups dentro de `PanelContainer`).

## 5. Flujo de trabajo (obligatorio para cada tarea)
1. **Branch** por tarea: `feat/loot-tiendas`, `fix/dash-direccion`.
2. Cambios **pequeños y atómicos** (una tarea = un PR/commit lógico).
3. **Validar headless ANTES de commitear** (comando abajo). Cero errores de parseo; los 3 smokes deben imprimir `SMOKE OK`, `KIT SMOKE OK`, `HIT SMOKE OK`.
4. **Actualiza la doc** de tu zona (`GDD.md`, `ARCHITECTURE.md`, `README.md` o `BACKLOG.md`).
5. **Commit claro en español.** ⚠️ **PROHIBIDO** poner `Co-Authored-By: Claude`, `🤖 Generated with…` ni cualquier atribución de IA. El autor es el dueño del repo.
6. Marca la tarea `[x] hecha` en `BACKLOG.md`.

### Comando de validación (copia y pega)
```bash
GODOT="C:/Users/matia/Downloads/Godot_v4.4.1-stable_win64.exe/Godot_v4.4.1-stable_win64_console.exe"
PROJ="c:/Users/matia/OneDrive/Documentos/GithubProyects/godot-game"
"$GODOT" --headless --path "$PROJ" --editor --quit-after 250        # importa + parseo
"$GODOT" --headless --path "$PROJ" --quit-after 900 res://scenes/levels/Arena.tscn  # runtime
"$GODOT" --headless --path "$PROJ" res://tests/HitSmoke.tscn        # HIT SMOKE OK
"$GODOT" --headless --path "$PROJ" res://tests/LootSmoke.tscn       # SMOKE OK
"$GODOT" --headless --path "$PROJ" res://tests/KitSmoke.tscn        # KIT SMOKE OK
```

## 6. Definition of Done
- [ ] Dentro de mi zona (o coordinado si tuve que salir).
- [ ] Sin errores de parseo; los 3 smokes pasan.
- [ ] Doc actualizada.
- [ ] Commit sin atribución de IA; tarea marcada `[x]`.

## 7. Si tienes que salir de tu zona
No lo hagas silencioso. Anota en `BACKLOG.md` una nota `⚠️ requiere tocar <archivo> (zona X)` y coordina, o divídelo en dos tareas (una por zona). Un contrato roto sin avisar es el peor error posible aquí.
