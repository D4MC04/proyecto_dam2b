# Plan de naves (provisional)

Lista de las 20 naves a las que queremos llegar: 10 base (sin mecánica, se distinguen por sus números; ya hechas, ver [enemigos.md](enemigos.md)) y 10 con mecánica. Es provisional: cada ticket la implementa y, al terminar, pasa su nave a [enemigos.md](enemigos.md). Cuando estén todas, este archivo se borra.

## Reglas

- **Nombres en inglés** en los dos idiomas (`translations/textos.csv`, columnas `es` y `en`).
- **Stats en escalones**: vida en saltos de 25. Velocidad como multiplicador en saltos de 0,25 sobre 1,0 = **60 px/s** (`EnemyData.speed` sigue en px/s).
- **Botín** ≈ vida / 5 × √(velocidad) × factor por habilidad (1,2-1,5), redondeado a 5. Es más o menos el 40 % del de antes. Como `make_waves.gd` reparte un presupuesto en botín, al bajar el botín se bajan los presupuestos en la misma proporción para que salgan las mismas naves.
- **Nichos con escalones**: dentro de un nicho puede haber versiones mejores que otras (la Frigate es un Corsair mejor). Las frágiles no lo compensan todo con velocidad: parte va en que salen muchas.
- No hay naves pensadas para contrarrestar una torreta concreta, ni torretas para una nave concreta: las respuestas tienen que salir solas de cómo funciona cada cosa.

## Naves con mecánica

| Nave | Antes | Vida | Velocidad | Daño a la estación | Botín |
|---|---|---|---|---|---|
| Payload | Saboteadora | 100 | 0,75 (45) | 25 | 25 |
| Mender | Reparadora | 100 | 0,75 (45) | 5 | 25 |
| Cluster | Divisora | 125 | 0,5 (30) | 15 | 20 (+3 × 5 de los trozos) |
| Magpie | nueva | 75 | 1,0 → 0,5 (60 → 30) | 10 | 20 (+ lo robado) |
| Lure | nueva (sustituye al Señuelo) | 125 | 0,75 (45) | 10 | 25 |
| Tug | nueva | 75 | 1,25 (75) | 10 | 20 |
| Wildfire | nueva | 150 | 0,5 → 1,5 (30 → 90) | 15 | 30 |
| Damper | nueva | 300 | 0,75 (45) | 25 | 70 |
| Shell | nueva | 150 | 0,5 (30) | 15 | 30 |

- **Payload**: una bomba. Late cada vez más rápido según avanza por el camino. Al morir explota: el pulso EMP de ahora (96 px, apaga las torretas 3 s) y 50 de daño a las naves que tenga cerca. Matarla dentro de un grupo de naves los castiga a ellos, pero si están junto a tus torretas te las apaga.
- **Mender**: se vacía para curar. Engancha un rayo a la nave más dañada a 64 px o menos y le pasa su propia vida (10 por segundo). Su barra baja mientras la otra sube. Si la ignoras, ella sola se gasta y muere, pero habrá salvado a otra.
- **Cluster**: al morir suelta 3 trozos (25 de vida, velocidad 1,5, 5 de daño, 5 de botín) que salen disparados unas casillas hacia delante por el camino. Matarla cerca de la estación es regalarle 3 naves rápidas casi en la meta.
- **Magpie**: mientras vive te roba **todo** el dinero que ganes (bajas, Mineros, bonus). En cada robo sale el importe en negativo y en morado (`-15€`) donde se iba a ganar, y el cristal que lleva en el vientre crece y brilla más (4 tamaños). Cuanto más roba, más grande y más lenta. Al matarla el cristal estalla y recuperas todo lo robado. Si llega a la estación, se pierde.
- **Lure**: cada 5 s suelta un pulso que dura 2,5 s. Durante el pulso, las torretas que la tienen a tiro la apuntan a ella, con una línea roja para que se vea por qué. Camuflada no atrae. Como mucho una por grupo.
- **Tug**: remolcador con rayo tractor. Engancha a la nave pesada más cercana (Ram, Juggernaut, Mothership…) y la arrastra a su propia velocidad. Si muere la Tug, la pesada vuelve a su lentitud; si muere la pesada, la Tug sale disparada sola.
- **Wildfire**: acelera según pierde vida, hasta el triple casi muerta. Se va poniendo roja y deja estela. Castiga quitarle vida poco a poco.
- **Damper**: ningún golpe le quita más de 25. El haz continuo del Disintegrator le hace el daño entero (son golpes de menos de 1). Va perdiendo placas a la vista.
- **Shell**: resta 5 a cada golpe, mínimo 1. Al haz continuo se le resta por segundo, no por frame. Los golpes que pierden más de la mitad sacan una chispa gris.

## Tickets

- `mejora-specter`, `mejora-payload`, `mejora-mender`, `mejora-cluster`: cambiar las que ya existen.
- `nave-magpie`, `nave-lure`, `nave-tug`, `nave-wildfire`, `nave-damper`, `nave-shell`: las nuevas con mecánica.
