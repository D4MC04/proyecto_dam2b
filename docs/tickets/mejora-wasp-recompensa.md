# Mejora: la Wasp paga lo que vale

Creador: David
Responsable: David
Estado: propuesta
Prioridad: baja
Modelo recomendado: sonnet
Esfuerzo recomendado: low

## Por qué
La Wasp tiene el doble de vida que un Dart, va más rápida y quita el doble a la estación, pero da 10 € (el Dart 15). Con la fórmula de botín le tocarían unos 30 €: matarla no compensa y el generador mete demasiadas por oleada.

## Qué hay que hacer
- Subir `reward` de `wasp.tres` a 30 (0,4 × 50 × √(100 / 40) ≈ 32).
- Como el presupuesto de las oleadas cuenta en botín, regenerar con `make_waves.gd` y comprobar que el dinero total de los niveles 1-9 no cambia mucho (salen menos Wasp por oleada). Si un nivel queda más fácil, subir su `health` en la tabla.
- Actualizar la tabla de enemigos.md.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/enemigos.md › "Datos"
- docs/design/niveles.md › "Generador de oleadas", "Dificultad frente a dinero"

## Archivos que toca
- resources/enemy_data/wasp.tres
- scripts/tools/make_waves.gd y resources/wave_data/ (regenerados)
- docs/design/enemigos.md y docs/design/niveles.md

## Cómo se prueba a mano
1. Jugar el nivel 1.
2. Al matar una Wasp sale "+30€".
3. Salen menos Wasp por oleada y el nivel se sigue pasando.
