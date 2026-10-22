# Estelas en misiles y balas pesadas

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Los proyectiles del Cañón pesado se ven como puntos sueltos.

## Qué hay que hacer
- Estela corta (Line2D o partículas) detrás de las balas de `rocket_launcher` y su fusión.
- Que no quede la estela flotando al impactar.

## Archivos que toca
- scripts/entities/Bullet.gd
- scenes/entities/Bullet.tscn
- resources/bullet_data/*

## Cómo se prueba a mano
1. Colocar un Cañón pesado: sus disparos dejan una estela que desaparece al impactar.
