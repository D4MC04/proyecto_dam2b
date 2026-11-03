# La estación espacial gira despacio

Creador: Renzo
Responsable:
Estado: aceptada
Prioridad: media
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
La estación está quieta en el mapa. Si gira despacio y suave, parece una estación de verdad en el espacio y el mapa da más sensación de vida.

## Qué hay que hacer
- La estación (`SpaceStation` en `Base.tscn`) gira sobre sí misma, despacio y sin parar (una vuelta cada ~40 s, ajustable con un `@export`).
- El giro tiene que verse suave y en estilo pixel art: comprobar que con el filtro "nearest" no tiembla ni se deforma. Si se ve mal, generar fotogramas girados con un script en `scripts/tools/` en vez de girar el nodo.
- El escudo gira con ella. La explosión, el destello rojo y el cambio de fase siguen como hoy.
- El giro sigue a `time_scale` (se para en pausa y va más rápido con la velocidad x2). Al destruirse la estación deja de girar.
- No cambiar los mapas: solo la escena y el script de la estación.

## Qué leer
- docs/design/base.md
- scripts/entities/Base.gd

## Archivos que toca
- scripts/entities/Base.gd
- scenes/entities/Base.tscn
- scripts/tools/ (solo si hacen falta fotogramas girados)
- docs/design/base.md

## Cómo se prueba a mano
1. Jugar el nivel 1.
2. La estación gira despacio y sin tirones; al pausar se para.
3. Dejar que la golpeen naves: destella y cambia de fase mientras gira. Al destruirse, la explosión no gira.
