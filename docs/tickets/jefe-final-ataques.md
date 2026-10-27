# El jefe final ataca las torretas y después la base

Estado: propuesta
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Que el jefe pueda romper las torretas obliga al jugador a estar alerta para repararlas o volver a construirlas.

## Qué hay que hacer
- **Hacerlo después de `jefe-final-batalla`**, que crea `FinalBoss.gd`.
- Al empezar, preguntar al usuario:
  - Si los ataques **quitan vida** a la torreta (y se repara) o la **destruyen al instante** (y se vuelve a construir).
  - Si a la base la mata en 3 o en 4 golpes.
- Cada pocos segundos el jefe ataca una torreta, con un ataque que se vea.
- Si quita vida: barra de vida en las torretas (solo en esta batalla) y botón "Reparar" en la ficha, que cuesta dinero. Si destruye: la torreta desaparece y la casilla queda libre para construir otra.
- Mientras quede alguna torreta, el jefe no ataca la base. Cuando no queda ninguna, ataca la base: cada golpe quita la parte de vida que toque según los 3 o 4 golpes.

## Archivos que toca
- scripts/entities/FinalBoss.gd
- scripts/entities/Tower.gd
- scripts/level_ui/InfoPanel.gd
- docs/design/enemigos.md, docs/design/torres.md, docs/design/base.md

## Cómo se prueba a mano
1. Nivel 10: el jefe ataca torretas cada pocos segundos y se ve el ataque.
2. Una torreta atacada pierde vida y se repara desde la ficha, o desaparece y se puede volver a construir, según lo decidido.
3. Vender o perder todas las torretas: el jefe ataca la base y la destruye en 3 o 4 golpes.
