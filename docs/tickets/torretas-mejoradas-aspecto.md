# Que se note a simple vista que una torreta está mejorada

Creador: Renzo
Responsable:
Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
Algunas torretas mejoradas se parecen demasiado a su versión normal, y el jugador no nota que la torreta ha mejorado de verdad.

## Qué hay que hacer
- Al empezar, preguntar al usuario qué torretas mejoradas necesitan otro aspecto y qué cambio quiere en cada una. Las 10 son: Cañón cuádruple, Minigun pesada, Cryo ventisca, Cañón de asedio, Tormenta, Cinturón, Rail Gauss, Aniquilador, Amplificador mayor y Excavadora.
- Volver a dibujar solo las que elija. En `assets/sprites/turrets/<x>_fusion/` se cambian la base, la tira del cañón y el icono `*_full_up.png`, siguiendo art.md y el estilo de su versión normal, de modo que se vea claramente que es la mejorada.
- Mantener el tamaño, el número de frames y los nombres de archivo, para que los `sprite_frames` de `resources/sprite_frames/<x>_fusion*.tres` y los `.import` sigan sirviendo sin cambiar ningún `uid`.
- No tocar las torretas no elegidas ni las versiones normales.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/torretas.md › "Mejorar (fusión)"
- docs/design/art.md › "Tamaños", "Paleta", "Contorno", "Luz y sombreado", "Animación" y "Convención de nombres"
- Los PNG de `assets/sprites/turrets/<x>/` y `<x>_fusion/` de las torretas elegidas

## Archivos que toca
- assets/sprites/turrets/<x>_fusion/ (solo las torretas elegidas)
- docs/design/torretas.md

## Cómo se prueba a mano
1. Jugar un nivel con las torretas elegidas desbloqueadas.
2. Colocar una de cada y pulsar Mejorar en su ficha.
3. La mejorada se distingue a simple vista de la normal. Apunta, dispara y anima igual que antes.
