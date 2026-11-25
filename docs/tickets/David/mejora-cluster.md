# Mejora: la Cluster lanza sus trozos hacia delante

Estado: aceptada
Espera a: mejora-payload
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: medium

## Por qué
La Divisora suelta sus trozos donde muere, así que solo es una nave con algo más de vida repartida. Si los trozos salen disparados hacia delante y son rápidos, importa dónde la matas: lejos no pasa nada, cerca de la estación le regalas 3 naves rápidas casi en la meta.

## Qué hay que hacer
- **Rediseño visual del sprite:** que se vea a simple vista su mecánica (se parte y lanza sus trozos hacia delante) y que encaje con las naves ya bien establecidas: las naves base de `make_base_ships.gd` (Streak, Vanguard, Cruiser...), con su mismo estilo y nivel de pulido. Los diseños antiguos de la Reparadora, la Divisora y la Saboteadora no sirven de referencia. Nada descabellado: igual que la Streak parece rápida sin nada especial, esta tiene que dar el aire de su mecánica. Generarlo con un script en `scripts/tools/` (no a mano) y enseñar el boceto ampliado al usuario antes de integrarlo.
- Al morir, los 3 trozos salen en arco unas 3 casillas (48 px) hacia delante por el camino, desde la posición de la Cluster, sin pasar del final. Se reutiliza el partirse de ahora (animación `crack`, `flash()`, cuentan como vivos); cambia hacia dónde van.
- Trozos: 25 de vida, 90 px/s, 5 de daño, 5 de botín. Cluster: 125 de vida, 30 px/s, 15 de daño, botín 20 (docs/design/naves-plan.md).
- Nombre Cluster (y "Cluster fragment" para los trozos) y `description`.
- Al terminar: pasarla a docs/design/enemigos.md y quitarla de naves-plan.md.

## Qué leer
- docs/design/art.md › la línea de las **Naves base** (estilo de referencia) y la de esta nave
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/naves-plan.md › Cluster
- docs/design/enemigos.md › "Partirse al morir"
- docs/design/niveles.md › "Spawner"
- scripts/level/Spawner.gd › donde parte a la Divisora

## Archivos que toca
- assets/sprites/enemies/divisora/ y su script de `scripts/tools/`
- scripts/level/Spawner.gd
- resources/enemy_data/divisora.tres y fragmento_divisora_*.tres
- translations/textos.csv
- docs/design/enemigos.md, docs/design/niveles.md y docs/design/naves-plan.md

## Cómo se prueba a mano
1. Jugar el nivel 5.
2. Al matar una Cluster, sus 3 trozos saltan hacia delante por el camino y corren rápido.
3. Matarla cerca de la estación deja pasar trozos; matarla al principio, no.
