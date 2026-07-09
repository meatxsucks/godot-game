# Docs en Obsidian (symlinks)

`spec/AGENTS.md`, `spec/GDD.md`, `spec/GDD_Claude_Context.md`, `spec/ARCHITECTURE.md`, `spec/TODO.md` y `spec/CHANGELOG.md` son **symlinks** al vault de Obsidian `D:\Obsidian\godot-game` — es el mismo archivo físico, no una copia. Editarlos desde el repo o desde Obsidian es equivalente; no hace falta sincronizar nada.

Leé `spec/AGENTS.md` primero (ver banner ahí) para el flujo de trabajo completo.

## Actualizar Obsidian como memoria del proyecto

⚠️ **Cada vez que trabajemos en este proyecto, actualizá el vault de Obsidian** (`D:\Obsidian\godot-game`, vía symlinks en `spec/` o el MCP `obsidian`) — no solo cuando se toque código:
- Tarea de [[TODO]] tomada/completada → actualizar su estado ahí (además del changelog).
- Cambio de diseño, decisión tomada, o contexto nuevo que surja hablando → anotarlo en [[GDD]], [[ARCHITECTURE]] o como nota nueva en el vault, lo que corresponda.
- Todo cambio de código → entrada en [[CHANGELOG]] (regla ya existente en `AGENTS.md`).
- Si surge una idea, decisión abierta o nota suelta que no encaja en ningún doc existente, creá una nota nueva en el vault en vez de perderla — la idea es que el vault crezca como memoria acumulada del proyecto, no solo como espejo de `spec/`.
