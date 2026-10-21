# Arreglar y completar el audio: torretas, naves, interfaz y ambiente

Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: high

## Por qué
El audio de los niveles tiene varios problemas a la vez:
- **Torretas, sonido que no se corta:** en 1 o 2 torretas (no en todas) el sonido sigue sonando aunque la torreta ya haya dejado de disparar. Ejemplo: el audio dura 4 s, la torreta se activa al entrar un enemigo en su rango y lo mata en 1 s; el audio sigue los 3 s restantes con la torreta parada. El resto de torretas funcionan bien.
- **Torretas, sonidos que no suenan:** algunas torretas no reproducen alguno de sus sonidos.
- **Naves enemigas:** ahora mismo no suenan. Cuando sonaban, al haber muchas a la vez sus audios se mezclaban en un ruido molesto.
- **Interfaz y ambiente:** nada reproduce los sonidos de `SFXs/` ni los de `LevelAmbience/`. Los botones no suenan, la derrota y la victoria llegan en silencio (aparte de la música) y los niveles no tienen ambiente.

## Audios disponibles
Todos son `.wav`, salvo la música del juego, que son `.ogg`. Las rutas base son `assets/audio/effects/` (comprobar que `SpaceShips/` y `Turrets/` cuelgan de ahí).

**LevelAmbience/**: `DarkestVoid`, `EchoOfTheVoid`

**SFXs/**: `Click1`, `Click2`, `Click3`, `Click4`, `Click5`, `GameOver`, `Victory`

**SpaceShips/** (una carpeta por nave; entre paréntesis, el archivo que contiene):

| Carpeta | Audio |
|---|---|
| AggresiveShip | `AggresiveShip` |
| BatteringRam | `BatteringRamShip` |
| Battleship | `Battleship` |
| Dart | `DartShip` |
| Nodriza | `NodrizaShip` |
| NormalShip | `NormalShip` |
| SpikedUFO | `SpikedUFO` |
| UFO | `UfoShip` |
| Wasp | `WaspShip` |

**Turrets/** (una carpeta por torreta):

| Carpeta | Audios |
|---|---|
| Cryo | `IceCharging`, `IceShoot` |
| Desintegrator | `IncrementalRay` |
| Laser | `LaserShoot` |
| Rail | `RailgunCharging`, `RailgunShoot` |
| Rocket | `RocketExplosion`, `RocketShoot` |
| Tesla | `ChargingTower`, `ElectricZap` |
| Turret | `DobleLaserShoot` |

Atención: en varias carpetas el nombre del archivo no coincide con el de la carpeta (`UFO` → `UfoShip`, `Dart` → `DartShip`...). Si alguna ruta en el código tiene una mayúscula o un nombre distinto, el sonido no se carga; en Godot esto suele pasar sin error visible en Windows y falla al exportar a Linux o Web, donde se distingue entre mayúsculas y minúsculas.

## Qué hay que hacer
### 1. Torretas que no suenan
- Antes de nada, hacer un inventario con la tabla de arriba: por cada audio de torreta, comprobar si está asignado, si la ruta es correcta (incluidas mayúsculas) y si llega a reproducirse. Anotar en docs/design/torretas.md cuáles fallaban y por qué.
- Casos que merecen revisión específica:
  - Torretas con dos audios (`Cryo`, `Rail`, `Tesla`): comprobar que suenan los dos, el de carga y el de disparo, y en el orden correcto.
  - `Rocket`: `RocketExplosion` debería sonar al impactar, no al disparar, y no debe cortarse si el proyectil o la torreta se liberan.
  - `Desintegrator` (`IncrementalRay`): comprobar cómo se reproduce un sonido de rayo continuo, porque es el candidato más probable a seguir sonando cuando el rayo se apaga.
- Otras causas habituales: no hay stream asignado al `AudioStreamPlayer`, `play()` no se llama en ese tipo de torreta, el player se libera antes de sonar, o el bus no es `SFX`.
- Si varias torretas repiten el mismo código de sonido, valorar un helper común pequeño en vez de copiar y pegar.

### 2. Torretas cuyo sonido no se corta (1 o 2 tipos)
- Identificar cuáles son y compararlas con las que van bien: lo más probable es que las buenas ya paren el audio al perder el objetivo y estas no, o que el sonido sea mucho más largo que el disparo (hipótesis: las de sonido de carga o de rayo, como `Cryo`, `Rail`, `Tesla` y `Desintegrator`; hay que confirmarlo, no darlo por hecho).
- Llamar a `stop()` en todos los casos en que el disparo termina: muere el objetivo, sale del rango, no quedan objetivos, se vende o destruye la torreta, o acaba el nivel (derrota, victoria o cambio de escena).
- En las torretas con carga: si el objetivo desaparece durante la carga, el sonido de carga también se corta y no sigue sonando.
- Para evitar el "chasquido" al cortar, valorar un fundido muy corto (0,1-0,2 s) bajando `volume_db` con un `Tween` y llamando a `stop()` al final. Si complica el código, `stop()` directo es suficiente.
- Si la torreta pasa a otro objetivo sin dejar de disparar, el sonido no debe cortarse ni reiniciarse; y no debe reiniciarse en cada frame mientras apunta.

### 3. Naves enemigas
- Primero averiguar por qué ahora no suenan (stream sin asignar, ruta o mayúsculas incorrectas, `play()` que no se llama, bus incorrecto, player liberado demasiado pronto, volumen demasiado bajo...) y hacer que vuelvan a sonar. Hay que revisar las 9: AggresiveShip, BatteringRam, Battleship, Dart, Nodriza, NormalShip, SpikedUFO, UFO y Wasp.
- Una vez suenan, evitar la mezcla. Idea del equipo: bajar la ganancia según cuántas naves haya a la vez. Para hacerlo en un solo sitio y sin duplicar lógica en cada nave:
  - Llevar la cuenta de naves activas (con un grupo `enemigos` o con un contador en un nodo/autoload pequeño donde se registren al aparecer y se den de baja al morir o llegar a la base).
  - Calcular el volumen de cada nave a partir de esa cuenta con una bajada suave: por ejemplo -3 dB cada vez que se duplica el número de naves, con un mínimo para que nunca se apague del todo. Ajustar los números de oído.
  - Complemento recomendado: limitar cuántas naves pueden sonar a la vez (`max_polyphony` o un máximo de 4-6 players activos); las demás no reproducen el sonido hasta que haya hueco. Valorar contar por tipo de nave, para que una oleada de `NormalShip` no tape el sonido de una `Battleship` o de la `Nodriza`.

### 4. Sonidos de interfaz
- **Aviso:** en un intento anterior (2026-10-21) no gustó el clic de los botones con `Click1`/`Click2`. Antes de implementar, elegir con el usuario qué clic usar entre `Click3`, `Click4` y `Click5` (o ninguno).
- Clic en los botones: un solo sitio que lo haga para todos, sin tocar cada botón (por ejemplo, un autoload pequeño que escuche `get_tree().node_added` y conecte `pressed` de cada `BaseButton`). Elegir uno de los `Click*.wav` (o dos: uno para botones normales y otro para comprar/colocar torre). Bus `SFX`, y que suene también con el árbol en pausa (`process_mode = ALWAYS`).
- `GameOver.wav` cuando aparece `GameOverScreen` y `Victory.wav` cuando entra `VictoryScreen` (tras la cámara lenta / el respiro, no antes).

### 5. Ambiente de los niveles
- Reproducir `DarkestVoid` o `EchoOfTheVoid` en bucle y a volumen muy bajo durante el nivel, en el bus `SFX`. Decidir si se asigna uno por nivel o se alternan. Comprobar que los `.wav` tienen el bucle activado en la importación (o repetirlos por código) para que no queden mudos tras sonar una vez.
- Si choca con `MusicManager`, dejarlo fuera y avisar en vez de forzarlo.
- Debe pararse al salir del nivel y respetar la pausa.

### Común a todo
- Todo en el bus `SFX`, para que "Efectos" en Opciones lo controle. Los `.wav` originales no se tocan (los ajustes de volumen se hacen con `volume_db`).
- Opcional si es fácil: ligera variación aleatoria de `pitch_scale` en disparos de torretas y naves para que no suene repetitivo. Si complica el arreglo, dejarlo fuera y avisar.
- Actualizar docs/design/torretas.md, docs/design/enemigos.md, docs/design/ui.md y docs/design/flujo.md (este último si se añaden autoloads o nodos nuevos).

## Archivos que toca
- [COMPLETAR: script(s) y escenas de las 7 torretas: Cryo, Desintegrator, Laser, Rail, Rocket, Tesla y Turret]
- [COMPLETAR: script(s) y escenas de las 9 naves enemigas]
- scripts/autoloads/ (nuevo autoload de sonidos de UI y, si hace falta, gestor de naves/ambiente) + project.godot
- scripts/level_ui/GameOverScreen.gd, VictoryScreen.gd
- [COMPLETAR: script del nivel donde se arranca el ambiente]
- docs/design/torretas.md, docs/design/enemigos.md, docs/design/ui.md, docs/design/flujo.md

## Cómo se prueba a mano
1. F5, entrar a un nivel y probar cada tipo de torreta (Cryo, Desintegrator, Laser, Rail, Rocket, Tesla, Turret): todas suenan al disparar, y las que tienen dos audios reproducen carga y disparo; el cohete suena al impactar.
2. Con las torretas que fallaban por no cortar el sonido: dejar que una sola nave entre en rango y matarla rápido; el sonido se corta al morir, no sigue hasta el final del audio.
3. Con una torreta y varias naves seguidas, el sonido no se corta ni se reinicia mientras haya objetivos; solo se para cuando no queda ninguna en rango.
4. Vender una torreta mientras dispara o carga: el sonido se corta en ese momento.
5. Las 9 naves suenan. En una oleada grande el conjunto no es un ruido molesto ni sube de volumen cuantas más hay; con una sola nave se oye con normalidad.
6. En el menú principal, al pulsar Jugar, un nivel u Opciones suena el clic elegido.
7. En el nivel, comprar torre, lanzar oleada, AUTO y ×2 suenan; en pausa, los botones del menú de pausa también.
8. Perder un nivel: al salir la pantalla de derrota suena `GameOver`. Ganarlo: al entrar la victoria suena `Victory`. Al terminar, no queda ningún sonido de torretas o naves sonando.
9. Durante el nivel se oye el ambiente a volumen bajo y en bucle, sin tapar los efectos ni la música; se para al salir del nivel.
10. En pausa, nada se acumula ni se queda enganchado; al reanudar todo vuelve a la normalidad.
11. "Efectos" a 0 en Opciones silencia torretas, naves, interfaz y ambiente.