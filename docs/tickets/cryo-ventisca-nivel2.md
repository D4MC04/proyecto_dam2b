# Cryo ventisca nueva: vórtice que gira y acelera al recargar

Creador: Renzo
Responsable: Renzo
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
La Cryo ventisca (nivel 2 de la Cryo) casi no se distingue del nivel 1: es el mismo dibujo con 4 destellos en las esquinas, y su onda es el mismo anillo. Tiene que notarse a simple vista que es un nivel 2, con coherencia y sin cosas raras. Diseño elegido: **Vórtice**. Solo cambia el aspecto.

## Qué hay que hacer
- La Cryo (nivel 1, `assets/sprites/turrets/cryo/`) no cambia. Los números de la ventisca tampoco: daño 12, frena al 35 % durante 4,5 s, cooldown 2,0 s, `wave_scale` 1,5; no apunta ni gira hacia los enemigos.
- Generar los sprites de `assets/sprites/turrets/cryo_fusion/` con un script `scripts/tools/make_cryo_vortex.gd`, como `make_siege_cannon.gd` (32x32, art.md). Mismos nombres de archivo que ahora y sin tocar los `uid=`.
- **Colores:**
  - Metal oscuro: `#232838`, `#3c465c`, `#6c7a94`, `#b4c2da`.
  - Hielo, el de la Cryo: `#122248`, `#245296`, `#54a0e2`, `#a6defa`, `#ecfaff`, más blanco `#ffffff`.
  - Contorno `#0c0e16`.
- **Base:** la del nivel 1 (`cryo/cryo_base.png`) con sus luces azules en blanco y `#a6defa`.
- **Cañón:**
  - Desde el centro hacia fuera: núcleo de cristal redondo de 13 px (el del nivel 1, más grande), contorno, banda de hielo de 1 px, contorno, aro de metal de 3 px y contorno, unos 26 px en total.
  - El aro tiene 8 ranuras oscuras repartidas cada 45°.
  - Encima del aro, a radio 11, van **4 rodillos** redondos de 5 px con contorno y una luz de hielo en el centro: son los 4 tacos del nivel 1. Empiezan arriba, abajo, izquierda y derecha.
  - Ya no hay destellos en las esquinas.
- **El aro y los rodillos giran juntos** (solo aspecto). Velocidad:
  - Al acabar el pulso, 200°/s.
  - Durante la recarga sube de 40°/s a 460°/s, con la forma de p² (p = progreso de la recarga).
  - En la carga y el pulso, 560°/s.
  - En reposo con la torreta cargada (`default`), a tope.
  - La figura se repite cada 90°: basta con unos 12 frames de ángulo. El tiempo de cada frame da la velocidad: `fire_0` dura todo el ciclo y cada frame su tiempo, como en el Cañón de asedio.
- **Recarga visible:**
  - La velocidad del giro dice cuánto falta para el siguiente pulso.
  - La banda de hielo se aclara con la recarga: `#245296` hasta el 30 %, `#54a0e2` hasta el 60 %, `#a6defa` hasta el 90 % y `#ecfaff` después.
  - El núcleo se apaga (rampa oscura) en el enfriado del pulso y vuelve a su color al empezar la recarga. En la carga brilla y en el pulso se pone blanco.
- **Detalles vivos dentro del cañón:**
  - Un remolino blanco semitransparente dentro del cristal, que gira con el aro.
  - 14 copos de nieve de 1 px que entran en espiral desde el borde hacia el núcleo, más rápido cuanto más gira el aro.
- **Onda** (`cryo_fusion/cryo_wave_sheet.png`, 8 frames, mismos `start_radius`, `growth` y `wave_scale`):
  - Frente blanco de 1 px y eco `#a6defa` de 1 px por dentro.
  - Por detrás del frente, 6 brazos de ventisca en espiral (uno cada 60°), en blanco y `#a6defa`, que se desvanecen hasta 22 px por detrás y giran unos 25° por frame.
  - Se rompe y se apaga al final, como la onda actual.
- Icono `cryo_full_up.png`: la base con el cañón cargado.
- Mantener `amp_effect`, coste y alcance.
- Referencia visual (si sigue existiendo), en `C:\Users\renzo\AppData\Local\Temp\claude\f5abc0c09d7b3c11\b450c882-f198-4769-ba87-261f752fe623\scratchpad\`:
  - `cryo_ventisca2_A.gif`.
  - El script `bocetos2.py`: `cannon_vortex()`, `wave_vortex()` y `spin_speed()`, con las medidas y los colores exactos; la base es `_lb`.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/torretas.md › "Mejorar (fusión)" y "Tipos de ataque" › "Onda"
- docs/design/art.md › "Tamaños", "Paleta", "Contorno", "Luz y sombreado", "Animación" y la fila de la Cryo ventisca y la del Cañón de asedio
- scripts/tools/make_siege_cannon.gd (cómo genera las tiras y el `SpriteFrames` con un tiempo por frame)
- scripts/entities/Turret.gd › `_on_attack_timeout()` y `_ready()` (animaciones `default` y `fire_0` del cañón)
- scripts/entities/Pulse.gd › `spawn()`, `_hit_ring()`

## Archivos que toca
- scripts/tools/make_cryo_vortex.gd (nuevo)
- assets/sprites/turrets/cryo_fusion/
- resources/sprite_frames/cryo_fusion.tres, cryo_fusion_cannon.tres, cryo_fusion_wave.tres
- resources/pulse_data/cryo_fusion.tres (solo `fire_frame`, si cambia la animación)
- docs/design/art.md, docs/design/torretas.md

## Cómo se prueba a mano
1. Jugar un nivel con la Cryo desbloqueada, colocarla y pulsar Mejorar.
2. Sin enemigos cerca, el aro con sus 4 rodillos gira rápido, entra nieve en espiral y el cristal tiene un remolino.
3. Al entrar naves, pulsa: el núcleo se pone blanco y después se apaga, y el aro casi se para. Durante los 2 s de recarga el aro vuelve a acelerar y la banda de hielo se aclara hasta el siguiente pulso.
4. La onda es igual de grande que antes y lleva 6 brazos de ventisca en espiral. Las naves se frenan igual que antes.
5. La Cryo de nivel 1 se ve igual que siempre.
