# Poderes del jugador: meteorito y congelar

Estado: aceptada
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
El jugador solo puede comprar torres y esperar. Dos poderes con recarga le dan algo que hacer en los momentos difíciles (un Acorazado que se escapa, una oleada que se amontona).

## Qué hay que hacer
- **Meteorito**: se pulsa el botón (o la tecla Q), el cursor pasa a modo apuntar con un círculo de área (radio 40 px) y al hacer clic en el mapa cae un meteorito: 150 de daño a todos los enemigos del área, con explosión y sonido (`RocketExplosion.wav` sirve). Clic derecho cancela. Recarga 45 s.
- **Congelar**: botón (o tecla E): todos los enemigos vivos van al 30 % de velocidad durante 4 s (`Enemy.slow`, con la escarcha). Recarga 60 s.
- Botones con icono de 16x16 nuevo (pixel art según `docs/design/art.md`) y la recarga dibujada encima (oscurecido que se va vaciando y segundos que faltan), en la barra izquierda bajo la ficha o donde quepan sin tapar nada.
- Solo se usan en `PLAYING`. La recarga sigue `Engine.time_scale` (×2 la acelera, la pausa la para). Empiezan listos en cada nivel y al reiniciar.
- Mientras se apunta el meteorito no se colocan torres (y al revés: elegir torre cancela el apuntado).
- Teclas nuevas en el Input Map de `project.godot`, junto a los atajos que ya hay.
- Actualizar docs/design/ui.md y docs/design/niveles.md (o un apartado de poderes donde encaje).

## Archivos que toca
- scripts/level/Powers.gd (nuevo: lógica de los poderes y apuntado)
- scripts/level_ui/LevelUI.gd + scenes/ de LevelUI (botones)
- scripts/level/BuildManager.gd (no colocar mientras se apunta)
- project.godot (Input Map)
- assets/sprites/ui/ (iconos nuevos)
- docs/design/ui.md, docs/design/niveles.md

## Cómo se prueba a mano
1. F5, nivel 3 o 4, lanzar oleada.
2. Pulsar Meteorito (o Q): sale el círculo; clic sobre un grupo de naves: explosión, las débiles mueren y el botón queda en recarga 45 s contando hacia atrás.
3. Pulsar Congelar (o E): todas las naves se ponen azules y van lentas 4 s; el botón queda en recarga.
4. Con ×2 la recarga va al doble; en pausa se para.
5. Reiniciar el nivel: los dos poderes vuelven a estar listos.
