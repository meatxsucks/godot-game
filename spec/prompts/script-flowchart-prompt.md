# Prompt: documentar scripts + flujograma

Pega este prompt a una IA con acceso al repo (o pégale los scripts). Sirve con modelos económicos porque la tarea es mecánica (leer y describir, no diseñar).

---

## PROMPT

Eres un ingeniero de software documentando un proyecto de **Godot 4.4 (GDScript)**. Tu única tarea es **describir el código tal como está**, sin proponer cambios ni opinar sobre el diseño. Trabaja solo con los archivos de `scripts/**` y las escenas `scenes/**/*.tscn` del repo.

### Parte A — Ficha por script
Para **cada** archivo `.gd` en `scripts/`, genera una ficha con este formato exacto:

```
### <ruta/archivo.gd>
- **Tipo:** class_name (si tiene) · extends <Clase>
- **Rol en una frase:** <qué hace>
- **API pública:**
  - funcs: nombre(args) -> retorno — <qué hace en ≤1 línea>
  - señales: nombre(args) — <cuándo se emite>
  - @export / const relevantes: nombre = valor — <para qué>
- **Depende de:** <autoloads, otras clases, escenas que precarga, grupos que usa>
- **Lo usan:** <quién lo instancia o llama, si es evidente>
- **Notas/invariantes:** <constantes-contrato, rutas de nodo que busca, supuestos>
```

Reglas:
- No inventes. Si algo no está claro en el código, escribe `(no evidente en el código)`.
- Sé conciso: máximo ~10 líneas por ficha.
- Agrupa las fichas por carpeta (`core/`, `player/`, `abilities/`, `enemies/`, `levels/`, `loot/`, `ui/`, `world/`, `magic/`).

### Parte B — Flujograma de arquitectura (Mermaid)
Genera **un** diagrama Mermaid `flowchart TD` que muestre:
- Los **autoloads** (`Game`, `FX`, `LootDB`, `Loot`, `SceneManager`) como nodos.
- El **flujo de escenas**: `MainMenu → ClassSelect → Arena (con HUD dentro)`.
- Las relaciones clave: quién **instancia** a quién (player → habilidades → proyectiles/efectos; spawner → enemigos; enemigos → loot) y las **señales** principales (player → HUD).
- Usa flechas etiquetadas: `-->|instancia|`, `-->|señal: died|`, `-->|lee|`.
- Mantenlo legible (agrupa con `subgraph` por capa: Autoloads, UI, Gameplay, Loot).

### Parte C — Diagrama de secuencia de UN flujo (Mermaid)
Un `sequenceDiagram` del flujo **"el jugador castea una habilidad"**: input → `player._try_cast` → `Ability.execute/_cast` → spawn de proyectil/nova → impacto → `take_damage` en enemigo → `FX` (número de daño) → muerte y drop de loot.

### Formato de salida
Un único Markdown con tres secciones (A, B, C). Los diagramas Mermaid en bloques ```mermaid. Nada de texto de relleno ni conclusiones.
```
