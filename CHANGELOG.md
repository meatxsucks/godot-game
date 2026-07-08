# CHANGELOG — registro de cambios de agentes

> **Regla:** todo agente que haga un cambio **DEBE** agregar una entrada aquí en el mismo commit. Entradas nuevas **arriba**. Sin entrada en el changelog, el trabajo se considera incompleto (ver `AGENTS.md §5`).

**Formato de entrada:**
```
## [fecha] — [agente] — [tarea TODO si aplica]
- Qué se hizo (1-3 bullets, en español).
- Archivos/zonas tocadas.
- Validación: smokes ✅/❌, notas.
```

---

## 2026-07-08 — Claude — reorganización de docs
- Nueva estructura de documentación: `spec/` (GDD, arquitectura, prompts — el contexto que todo agente lee), `TODO.md` (backlog + ideas + decisiones abiertas) y este `CHANGELOG.md` (registro obligatorio).
- `AGENTS.md` actualizado como punto de entrada con el flujo: **spec/ → TODO.md → trabajar → CHANGELOG.md**.
- Zonas: docs. Validación: no aplica (solo documentación).

---

# Historial previo (sembrado desde git, commits de 2026-07-04 a 2026-07-06)

## 2026-07-06 — Claude
- **Docs de planificación**: AGENTS (reglas multi-agente), GDD co-op/insectos, arquitectura Steam/consola, backlog por épicas, prompt de flujograma. (`fb17d5a`)
- **Menú de pausa (ESC)**: pausa real del árbol, Continuar/Menú/Salir, HUD en PROCESS_MODE_ALWAYS. (`140c1d7`)
- **Rebalance**: LMB/RMB de armas más livianos que Q/R (estaban muy OP; Muro de Llamas llegaba a 6x). (`1f21283`)
- **Ulti propio del Guerrero** (Golpe de Titán, ya no repetía el anillo de la espada) + fix crossbow faltante del arco. (`91f6321`)
- **Fix freeze al atacar** (attack_lock usaba tope fijo 0.45s; ahora duración real del clip) + las 5 armas en el cofre para testear. (`31e1475`)
- **Limpieza**: archivos de prueba sueltos fuera; quedan los 3 smokes. (`96b298b`)
- **Sistema de armas con poderes** (revisión y pulido): 5 armas × LMB/RMB únicos, kit Q/R por clase, parábola real del Salto Sísmico, afijos por familia de arma, Torbellino → anillo de choque. (`9283d73`)
- **Vista de inspección** al abrir inventario (cámara frontal cercana, personaje encara la cámara). (`c98340d`, `6348387`)
- **Fix crash** (typo en boss.gd) + heal del Guerrero (Grito de Guerra cura 25%) + poderes de enemigos escalan por oleada. (`15ede99`)

## 2026-07-04 — Claude
- **Playtest v3**: anims sin patinar (velocidad real medida), loot al final de oleada, orbes al tocar, el arma define el click, supers al frente, dash al mirar, **joystick completo**. (`3df7e5b`, `798ceb1`)
- **Esqueletos KayKit** (minion/rogue/warrior/mage) + arquero, FX (números de daño/partículas/shake), XP/niveles y paper-doll v2. (`eb1b55c`)
- **Personajes KayKit Adventurers** animados por clase + paper-doll (equipo visible). (`72741d2`, `c7d3db3`)
- **Legendarios activos** en combate + **Boss Rey Slime**. (`374f0a9`)
- **Mundo procedural** (64×64 por semilla) + portales de oleada + minimapa con niebla. (`744e7d6`)
- **Navmesh** + inventario v2 (comparación lado a lado + drag & drop). (`ff57af1`)
- **Kits por clase** (Guerrero melee, Explorador a distancia). (`15c6257`)
- **Clases + skills estilo Tibia + zona segura**; recursos limitados (sin regen pasiva). (`6821252`, `f854d33`)
- **Consumibles, cofre, variantes de enemigos, barras de vida**; inventario/equipamiento estilo Tibia; **sistema de 5 poderes + HUD radial**. (`bc89d50`, `31263e0`, `cb444ec`)
- Setup inicial del proyecto Godot 4.4 + README para artistas. (`069f863`, `49f8342`)
