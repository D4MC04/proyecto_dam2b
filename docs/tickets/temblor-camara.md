# Temblor de pantalla en golpes fuertes

Creador: Renzo
Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Cuando una nave llega a la estación o explota la Nodriza no hay respuesta física en pantalla.

## Qué hay que hacer
- Temblor corto (offset aleatorio que se apaga) al recibir daño la estación y al morir un jefe.
- Fuerza según el daño; opción para apagarlo en Opciones.
- Documentar en docs/design/ui.md.

## Archivos que toca
- scripts/level/Level.gd
- scripts/autoloads/Settings.gd
- docs/design/ui.md

## Cómo se prueba a mano
1. Dejar pasar una nave en el nivel 1: la pantalla tiembla un instante.
2. Con la opción apagada no tiembla.
