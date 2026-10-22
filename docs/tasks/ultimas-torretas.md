# Elegir las 3 últimas torretas principales

Estado: aceptada
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
El juego tiene 7 torretas y le faltan las 3 últimas principales. Había 12 tickets sueltos de "torre nueva" que competían por esas plazas. Se han juntado aquí para elegir entre todas a la vez.

## Qué hay que hacer
- **Hacerlo después de `cohetes-area` y `laser-mecanica`**, para elegir sabiendo ya qué hacen el Cañón pesado y el Láser y no repetir mecánicas.
- Presentar al usuario el catálogo de abajo y cualquier idea nueva que se proponga. Para cada una, decir si repite mecánica con alguna de las 7 actuales y cuánto costaría. Recomendar 3, pero que elija el usuario.
- Catálogo (las ideas de los tickets descartados):
  - **Lanzallamas:** cono de fuego corto que daña todo lo que toca y deja quemadura (daño por segundo unos segundos).
  - **Mortero:** proyectil en arco que cae donde estará la nave y daña en un radio; alcance mínimo, no dispara a naves muy cerca.
  - **Francotirador:** alcance muy largo, daño alto, cadencia lenta; prioriza la nave con más vida.
  - **Lanzamisiles teledirigidos:** misiles que giran hacia su objetivo y, si muere, buscan otro; estela de humo. Útil contra Espectros y naves rápidas.
  - **Láser de barrido:** haz que barre un arco de lado a lado dañando todo lo que cruza (si no se usó en `laser-mecanica`).
  - **Bahía de drones:** suelta 2 drones que vuelan hacia las naves en un radio grande, disparan y vuelven.
  - **Sembradora de minas:** lanza minas a puntos del camino en su alcance, que explotan al pasar una nave (máximo N minas).
  - **Pozo de gravedad:** tira de las naves cercanas hacia atrás en su camino unos px cada pocos segundos.
  - **Pulso inhibidor:** cada X s anula las habilidades en su radio (revela al Espectro, corta la curación y el EMP).
  - **Amplificador** (apoyo): no dispara; sube daño y cadencia un % a las torres de las 8 casillas vecinas, con aura visible.
  - **Proyector de escudo** (apoyo): solo junto a la estación; escudo que absorbe el daño de N naves y se recarga entre oleadas (`shield.png`, `shield_debil.png`).
  - **Extractor de dinero** (economía): no dispara; da dinero al acabar cada oleada; caro, rentable solo si se pone pronto.
- Con las 3 elegidas, escribir un ticket por torreta en esta misma carpeta, con el formato de `_plantilla.md` y `Estado: propuesta`. Cada uno incluye: mecánica, sprites de la torre y de su fusión con un script de `scripts/tools/` siguiendo art.md, su `TurretData`/`TowerData` y el de la fusión, añadirla a `GameData.tscn` y a los niveles desde el que se elija, y sus sonidos si hay assets.
- Preguntar si alguna de las no elegidas se guarda también como ticket propio. Las demás se descartan.
- No tocar código: este ticket solo decide y escribe tickets.

## Archivos que toca
- Carpeta de tickets: los 3 tickets nuevos (y los que se guarden)

## Cómo se prueba a mano
1. `/board`: aparecen los tickets de las 3 torretas elegidas, en `Estado: propuesta`, listos para aceptar.
