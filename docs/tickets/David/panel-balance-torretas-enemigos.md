# Panel de balanceo: base, Torretas y Enemigos

Estado: aceptada
Prioridad: media
Modelo recomendado: opus
Esfuerzo recomendado: high

## Por qué
Balancear tocando los `.tres` a mano es lento y no deja comparar. Una página HTML local, fuera de Godot, que enseñe los stats de todas las torretas y naves en tablas editables y los guarde directamente en los `.tres`.

## Qué hay que hacer
- Crear `tools/balance/index.html` con scripts clásicos (`<script src>`, no módulos ES: desde `file://` Chrome bloquea los módulos). Se abre con doble clic en Chrome o Edge, sin servidor ni instalar nada.
- Botón "Abrir proyecto": con `showDirectoryPicker()` (File System Access API) el usuario elige la carpeta del juego (la principal o el worktree de un ticket). Si el navegador no lo soporta, mostrar un aviso.
- `tools/.gdignore` vacío para que Godot no escanee la carpeta.
- Lector y escritor de `.tres` (`tres.js`):
  - Leer las secciones `[resource]` y `[sub_resource id=...]` con sus líneas `clave = valor`, y los `ext_resource` (id → ruta) para seguir las referencias.
  - Guardar **solo la línea cambiada**, sin regenerar el archivo, para que `uid`, `ext_resource` y el resto queden igual.
  - Si el campo no está en el `.tres` porque vale lo de por defecto, insertar la línea en su sección (antes de `metadata/`).
  - Escribir los `float` como los guarda Godot (`500.0`).
- Valores por defecto: sacarlos de los `@export ... = valor` de los scripts de `scripts/resources/`, leyéndolos también de la carpeta elegida, para enseñar el valor real de los campos que no están en el `.tres`.
- Pestañas Torretas, Enemigos, Niveles y Diálogos. Niveles y Diálogos quedan vacías, con "Pendiente" (son otros tickets).
- **Torretas**: una fila por `resources/turret_data/*.tres`, agrupando base, fusión y nivel 3 de cada torreta. Columnas:
  - De `TurretData`: nombre (la clave traducida con `translations/textos.csv`, columna `es`), `cost`, `attack_cooldown`, `salvo_count`, `min_range`, `turn_speed`, sobrecalentamiento, `money_amount` y `amplifier_level`.
  - El alcance: el `radius` del Shape2D de `attack_range` en `resources/collision_shapes/`. Avisar si ese archivo lo comparten varias torretas.
  - El daño y lo propio de su tipo de ataque, según el recurso que tenga:
    - `bullet_data`: daño, velocidad, `pierce`, `splash_radius` y ralentización.
    - `chain`: daño, `max_targets` y `jump_range`.
    - `beam`: daño, `half_width` y `length`.
    - `pulse`: daño, ralentización y radio.
    - `focus_beam`: `damage_per_second` por nivel y `level_time`.
    - `orbit`: daño, `splash_radius` y `max_orbs`.
  - Columnas calculadas (solo lectura): DPS aproximado a un objetivo (daño por ataque × `salvo_count` ÷ `attack_cooldown`; en el haz continuo, el `damage_per_second`), coste acumulado contando las mejoras y DPS por €. La fórmula de cada tipo va en un tooltip.
- **Enemigos**: una fila por `resources/enemy_data/*.tres`. Columnas:
  - De `EnemyData`: nombre traducido, `hp`, `speed`, `reward`, `base_damage`, `heal_rate`, `reveal_time`, `emp_radius`, `death_damage` y `split_into` (solo se ve).
  - Calculadas: vida por € (`hp` ÷ `reward`) y velocidad en px/s (ver enemigos.md › "Datos").
- Las tablas se ordenan pulsando la cabecera. Las celdas editables son inputs numéricos.
- Al editar: marcar la celda cambiada, recalcular las columnas calculadas y activar "Guardar" (escribe todos los cambios) y "Descartar". Avisar si al salir queda algo sin guardar.
- Añadir a docs/CLAUDE-CODE.md una sección corta: cómo abrir el panel, que guarda en la carpeta elegida (usarlo en el worktree de un ticket, nunca en `main`) y que después hay que actualizar las tablas de stats de docs/design/ si cambian.

## Qué leer
Solo esto; `/work` no lee nada más de docs/design.
- docs/design/torretas.md › "Datos", "Tipos de ataque"
- docs/design/enemigos.md › "Datos"
- scripts/resources/TurretData.gd, EnemyData.gd, BulletData.gd, ChainData.gd, BeamData.gd, PulseData.gd, FocusBeamData.gd, OrbitData.gd (solo los `@export`)
- Un ejemplo de cada: resources/turret_data/minigun.tres, resources/bullet_data/minigun_bullet.tres, resources/collision_shapes/minigun.tres, resources/enemy_data/acorazado.tres

## Archivos que toca
- tools/balance/index.html, tools/balance/*.js, tools/balance/*.css (nuevos)
- tools/.gdignore (nuevo)
- docs/CLAUDE-CODE.md

## Cómo se prueba a mano
1. Abrir `tools/balance/index.html` en Chrome, pulsar "Abrir proyecto" y elegir la carpeta del juego.
2. En Torretas, ordenar por DPS por €: deberían salir todas las torretas con sus tres niveles y el alcance en píxeles.
3. En Enemigos, cambiar el `hp` de Dart a otro valor y pulsar Guardar. `git diff` debería cambiar solo la línea `hp = ...` de `resources/enemy_data/dart_rojo.tres`.
4. Jugar el nivel 1 en Godot: el Dart debería tener la vida nueva en su ficha.
5. Cambiar en una torreta un campo que no estaba en su `.tres` (por ejemplo `pierce`): debería añadirse la línea y Godot debería cargar el archivo sin errores.
