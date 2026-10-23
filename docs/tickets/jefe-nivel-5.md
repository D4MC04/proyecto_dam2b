# Jefe para el nivel 5: Acorazado real

Creador: Renzo
Estado: propuesta
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
El nivel 5 no tiene final especial.

## Qué hay que hacer
- Jefe con escudo frontal que gira lentamente y deja huecos para dañarlo.
- Sprite con script de `scripts/tools/`; aviso de jefe.

## Archivos que toca
- scripts/tools/make_acorazado_real.gd
- resources/enemy_data/acorazado_real.tres
- scripts/entities/Enemy.gd
- scripts/level/Spawner.gd
- scripts/tools/make_waves.gd

## Cómo se prueba a mano
1. Última oleada del nivel 5: el jefe solo recibe daño por donde no tiene el escudo.
