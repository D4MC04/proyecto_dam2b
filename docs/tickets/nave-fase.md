# Nave nueva: Fásica

Creador: Renzo
Estado: propuesta
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
El Espectro se camufla; una nave que se vuelva intocable da otro tipo de reto.

## Qué hay que hacer
- Alterna 2 s intocable (semitransparente, no recibe daño ni se puede apuntar) y 3 s normal.
- Sprite con script de `scripts/tools/`.

## Archivos que toca
- scripts/tools/make_fasica.gd
- resources/enemy_data/fasica.tres
- scripts/entities/Enemy.gd
- scripts/tools/make_waves.gd

## Cómo se prueba a mano
1. La Fásica parpadea y en su fase intocable las balas no le hacen daño.
