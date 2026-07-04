# Documento de Diseño del Juego (Contexto para Claude Code)

Este documento sirve como base de conocimiento y contexto para el desarrollo del juego en Godot. 

## 1. Concepto Principal y Género
- **Género**: ARPG isométrico enfocado en la magia, fuertemente inspirado en mecánicas de la saga *Diablo* y sistemas de botín (loot) de *Borderlands*.
- **Fantasía del Jugador**: Fantasía de mago. El combate se basa enteramente en el uso y combinación de hechizos, sin uso de armas de fuego tradicionales (no es un shooter).
- **Cámara**: Vista isométrica / top-down (estilo Diablo). El ángulo es fijo y sigue al jugador.
- **Controles**: Adaptación de *twin-stick* para magos: movimiento con teclado (WASD) y apuntado libre con el mouse.

## 2. Core Gameplay Loop (Bucle de Juego)
El juego se estructura a través de un sistema basado en oleadas (wave-based):
1. **Sobrevivir**: Enfrentar oleadas progresivas de enemigos.
2. **Lootear**: Los enemigos derrotados sueltan botín (loot) que varía en rareza.
3. **Mejorar (Build)**: Equipar ítems, potenciar estadísticas y modificar hechizos.
4. **Progresar**: Avanzar a la siguiente oleada, la cual presenta un escalado mayor de dificultad y recompensas más valiosas.

## 3. Sistema de Botín (Loot)
Combina la generación procedural de Diablo con la filosofía de rareza y colores de Borderlands.

### Tipos de Ítems
- Bastones, Orbes, Varitas, Anillos, Armaduras.
- **Stats Procedurales (Afijos)**: Cada ítem se genera con modificadores al estilo Diablo (ej: +Daño, +Maná, +Probabilidad de Crítico, Resistencias elementales, etc.).

### Sistema de Rareza (Por Color)
La rareza define tanto la cantidad como la calidad/potencia de los afijos generados:
1. **Común (Blanco)**: Stats base.
2. **Raro (Verde / Azul)**: Múltiples afijos con valores mejorados.
3. **Épico (Morado)**: Stats superiores y gran cantidad de afijos.
4. **Legendario (Naranja)**: Ítems que otorgan **PODERES ÚNICOS**. Estos modifican fundamentalmente el funcionamiento de un hechizo o la sinergia de una build completa (similar a los efectos legendarios de Borderlands o los ítems únicos de Diablo), en lugar de solo ofrecer incrementos numéricos.

## 4. Sistema RPG y Combate
- **Hechizos (Habilidades)**: Cada habilidad cuenta con tres atributos principales:
  - Costo de Maná.
  - Tiempo de recarga (Cooldown).
  - Tiempo de casteo (Cast time).
- **Estados Alterados (Buffs / Debuffs)**: Efectos de estado aplicables tanto al jugador como a los enemigos (ej: Quemadura, Congelación, Escudos protectores).
- **Modificadores de Stats**: Los afijos y habilidades escalan de forma multiplicativa y aditiva para potenciar la *build*.
- **Atributos Base del Personaje**: 
  - Vida
  - Maná
  - Daño Mágico
  - Probabilidad/Daño Crítico
  - Velocidad de casteo (Cast speed)

## 5. Dirección de Arte y Estética (Low-Poly / PS2 Refinado)
El objetivo es un estilo "PS2 remasterizado", no un demake glitcheado. Es decir, un estilo retro 3D pero con altos estándares de calidad moderna.
- **Geometría y Topología**: Modelos low-poly pero con una topología muy limpia.
- **Texturizado**: Texturas creadas con mimo y detalle, sin verse rotas a propósito.
- **Filtros Retro (Deliberados y Sutiles)**: 
  - Baja resolución de render escalada.
  - Dithering.
  - Leve "affine warp" y vertex snapping opcional (muy controlado).
- **Iluminación y Render (Forward+)**: 
  - Iluminación y sombras modernas y precisas para un contraste atractivo.
  - Cel-shading suave aplicado a los personajes (magos y enemigos) para resaltarlos sobre el entorno.
  - El "look PS2" se logra usando *viewport scaling* (aprox. 0.55-0.65, un poco más alto que los shooters retro para mayor claridad) sumado a shaders de URSC (Ultimate Retro Shader Collection).

---
*Nota para el Asistente AI (Claude)*: Utiliza este documento como la "biblia" base para decisiones de arquitectura de software en Godot, diseño de componentes, shaders, sistema de inventario y generación procedural.
