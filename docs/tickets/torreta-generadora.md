# Torreta generadora de dinero

Creador: David
Responsable:
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Una torreta que no ataca pero da dinero abre una decisión nueva: invertir pronto para ganar más tarde o defender ya. El diseño visual tiene que estar muy cuidado y encajar con el resto de torretas.

## Qué hay que hacer
Por fases, parando a preguntar al usuario entre una y otra (AskUserQuestion). No implementar en el juego hasta que el usuario elija prototipo.
1. **Ideas**: pensar cómo debería verse (qué es temáticamente en el espacio: extractor, colector, minero de asteroides...) y cómo genera el dinero (cada X s, al limpiar oleada, etc.). Proponer 3-4 ideas al usuario con descripción breve de aspecto, animación y funcionamiento. Esperar a que elija.
2. **Prototipos**: con la idea elegida, dibujar 2-3 variantes de sprite (base + parte animada, 16x16 como las demás) respetando estrictamente el estilo de las torretas existentes: misma paleta, contorno, luz y proporciones (ver `assets/sprites/turrets/`, sobre todo `amplifier/` y `tesla/`, y docs/design/art.md). Cada variante con su animación de generación de dinero (p. ej. texto flotante `+X€` con `FloatingText` y un efecto en la torreta).
3. **Verlo en un nivel**: que el usuario pueda ver cada prototipo colocado dentro de un nivel real en Godot (p. ej. añadiéndolo provisionalmente a la barra de compra de un nivel, o una escena de prueba que monte un nivel con las variantes ya colocadas) y ver la animación funcionando. Abrir el editor y decirle cómo verlo. Esperar a que elija.
4. **Implementar** la elegida: `TurretData` nuevo (y su fusión si el usuario la quiere), sin ataque ni rango, tratada como torreta de apoyo como el Amplificador en `Turret._ready` (no apunta, sin `Timer` de ataque, el EMP la apaga y mientras está apagada no genera). Generar dinero con `LevelState.add_money`. Ficha con sus stats (`TurretData.get_stats`, `get_attack_label`). Añadirla a los niveles que diga el usuario. Quitar los prototipos descartados y lo provisional.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/art.md › "Tamaños", "Paleta", "Contorno", "Luz y sombreado", "Animación", "Convención de nombres"
- docs/design/torretas.md › "Escena y script", "Datos", "Amplificador"
- docs/design/niveles.md › "Datos de nivel"
- scripts/entities/Turret.gd › `_ready()` (rama `is_amplifier()`), `disable()`
- scripts/resources/TurretData.gd › `get_stats()`, `get_attack_label()`, `is_amplifier()`
- scripts/level/LevelState.gd › `add_money()`
- scripts/entities/FloatingText.gd

## Archivos que toca
- assets/sprites/turrets/<nueva>/
- resources/turret_data/<nueva>.tres (y fusión), resources/sprite_frames/
- scripts/entities/Turret.gd, scripts/resources/TurretData.gd
- resources/level_data/ (niveles donde se desbloquea)
- docs/design/torretas.md, docs/design/niveles.md

## Cómo se prueba a mano
1. Jugar un nivel donde esté desbloqueada y comprarla.
2. Debería generar dinero como se decidió, con su animación y el `+X€` flotante, y subir el contador de dinero.
3. Con un EMP de la Saboteadora encima, deja de generar mientras está apagada.
4. La ficha enseña sus stats y se vende como las demás.
