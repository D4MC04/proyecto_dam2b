---
name: mejora
description: Rediseña el nivel 2 (versión mejorada o fusionada) de una torreta, o diseña su nivel 3 partiendo del nivel 2, para que se note a simple vista (y, si se pide o es nivel 3, también al atacar), con animación de transformación al mejorar. Usar cuando el usuario quiera rediseñar, mejorar o cambiar una torreta mejorada (Cañón doble/cuádruple, Minigun/Minigun pesada, Cryo/Cryo ventisca, Cañón pesado/de asedio, Tesla/Tormenta, Orbitador/Cinturón, Rail/Rail Gauss, Disintegrator/Aniquilador, Amplificador/Amplificador mayor, Minero/Excavadora) o diseñar el nivel 3 de una torreta.
argument-hint: "nombre de la torreta [nivel 3] (Cañón doble, Minigun, Cryo, Cañón pesado, Tesla, Orbitador, Rail, Disintegrator, Amplificador, Minero)"
---

Diseña una mejora de torreta: $ARGUMENTS.

**Qué nivel:** si los argumentos dicen "nivel 3" (o "nv3", "level 3"), se diseña el **nivel 3** partiendo del nivel 2; si no, el **nivel 2** partiendo del nivel 1. La torreta se puede nombrar por cualquiera de sus niveles (por ejemplo, "cañón doble nivel 3" y "cañón cuádruple nivel 3" son lo mismo).

El nivel 2 se hizo por primera vez con el Cañón de asedio (tickets `asedio-martillo` y `asedio-transformacion`): es el ejemplo a seguir en los dos niveles.

## Reglas del diseño
- **El nivel 1 no cambia.** Es la referencia de todo.
- **El nivel 2 tiene que ser claramente un nivel 2:** silueta nueva, no la misma recoloreada. Más agresiva y más brusca que el nivel 1.
- **Diseño estético:** solo cambia el aspecto (silueta, bala o efecto, recarga visible). El ataque y los números se quedan igual.
- **Diseño con mecánicas:** el ataque también cambia, pero parte del nivel 1: se mantiene el tipo de ataque (bala, onda, cadena, haz...) y se le añade una mecánica que se vea y se sienta. En el Cañón de asedio: salva de 2 balas, la segunda cae encima de la primera.
- **La mecánica se tiene que ver, no solo una luz.** En el Cañón de asedio, la recarga se ve con la bala entrando en la recámara y el cerrojo cerrándose.
- **Coherencia de tamaños:** lo que dispara es lo que se ve cargar. La bala en vuelo del Cañón de asedio es la misma de la recámara, tumbada (8x3).
- **El ataque se tiene que leer en pantalla:** halo de 1 px del color del acento sobre el fondo oscuro, estela, llama o partículas pequeñas, y una velocidad que deje seguirlo con la vista.
- **En las torretas que no atacan** (Amplificador mayor, Excavadora), lo que cambia de forma visible es su efecto (aura, generación de dinero).
- **Animación de transformación al mejorar** (sustituye al holograma de `play_build()` solo en esa torreta, unos 2-2,5 s, sin disparar mientras dura). Tiene que ser **coherente**:
  - Cada pieza del nivel 1 se mueve y se convierte en una del nivel 2. Por ejemplo: el cañón se parte en dos, el tubo viejo entra y salen los nuevos, los postes bajan y se ensanchan en pistones.
  - No se desmonta todo para rehacerlo, ni hay piezas que aparezcan de la nada o se disuelvan píxel a píxel.
  - La base se queda en su sitio: cambian sus luces una a una y sus placas se deslizan.
  - Pequeños golpes ("clac", 1 px), chispas y vapor en los encajes. Nada de explosiones.
- Sprites a 32x32 y según `docs/design/art.md`. Sin tocar los `uid=`.

### Además, en el nivel 3
- **El nivel 1 y el nivel 2 no cambian.** La referencia es el nivel 2.
- **Siempre con mecánicas** (no hay diseños estéticos): se mantiene el tipo de ataque y se añade **otra** mecánica que se vea y se sienta, distinta de la que ganó en el nivel 2 (que se conserva).
- **Silueta nueva, todavía más brusca que la del nivel 2.** No es el nivel 2 recoloreado ni con piezas pegadas.
- **Números a la altura del coste:** el coste del nivel 3 es 2 × el del nivel 2 (ver `docs/design/torretas.md` › "Mejorar (fusión)"), y daño, alcance, cadencia y la mecánica nueva tienen que justificarlo.
- **Animación de transformación del nivel 2 al 3** (`upgrade_frames` en `<x>_level3.tres`), con las mismas reglas de coherencia: cada pieza del nivel 2 se convierte en una del nivel 3.
- Datos en `resources/turret_data/<x>_level3.tres` y sprites en `assets/sprites/turrets/<x>_level3/`.

## Cómo se trabaja
**Antes de nada, preguntar** (un solo AskUserQuestion, con opciones para elegir con un clic; el usuario puede usar "Otro" para escribir lo suyo; no leer ni proponer nada hasta tener las respuestas):
- Cuántos diseños quiere. Por defecto 3 (opción recomendada); puede pedir otro número.
- Solo en el nivel 2: qué tipo de diseños: todos estéticos, todos con mecánicas (ataques nuevos y cosas así) o una mezcla. Si es mezcla, preguntar después cuántos de cada tipo. En el nivel 3 no se pregunta: siempre son con mecánicas.

Fase de diseño, sin tocar archivos del proyecto:
1. Leer cómo es ahora la torreta: su `TurretData` en `resources/turret_data/<x>.tres` y `<x>_fusion.tres` (en el nivel 3, también `<x>_level3.tres`, que es provisional), su ataque (`*Data`), sus sprites en `assets/sprites/turrets/`, `docs/design/torretas.md` (su fila de "Mejorar (fusión)", y en el nivel 3 lo que diga del nivel 3, y su tipo de ataque) y `docs/design/art.md`. Mirar también la sección "Decidido" de `docs/DESIGN.md`. Si en el nivel 3 no existe `<x>_level3.tres`, avisar de que falta el ticket `nivel3-sistema` y parar.
2. Proponer **exactamente los diseños pedidos**, en texto, cada uno marcado como estético o con mecánicas. Para cada uno: aspecto y por qué se ve más brusco; en los de mecánicas, además, cómo cambia el ataque respecto al nivel anterior (con números). En el nivel 3, poner el coste (2 × el del nivel 2) y qué mecánica nueva añade frente a la del nivel 2.
3. El usuario elige uno. No proponer rondas nuevas ni mezclas por tu cuenta: solo cambiar lo que él pida.
4. Cuando lo pida, hacer **bocetos en GIF**, uno por diseño, con Python y Pillow en la carpeta temporal de la sesión (nunca en el repo). Partir de los sprites reales del nivel anterior (nivel 1 para el nivel 2, nivel 2 para el nivel 3), enseñar la torreta disparando a una fila de naves y, al lado, la torreta ampliada x4 con sus datos. Mirar los fotogramas antes de enviarlos.

Paso a tickets con `/add`, dos por torreta:
- Nivel 2:
  - `<torreta>-nivel2`: aspecto nuevo, recarga o mecánica visible, y bala o efecto; si el diseño es con mecánicas, también el ataque nuevo. Opus, esfuerzo high (medium si es estético).
  - `<torreta>-transformacion`: animación de mejora. Va después del primero. Opus, esfuerzo medium.
- Nivel 3:
  - `<torreta>-nivel3`: aspecto nuevo, la mecánica nueva visible, bala o efecto y el ataque nuevo con sus números en `<x>_level3.tres`. Opus, esfuerzo high.
  - `<torreta>-transformacion3`: animación de mejora del nivel 2 al 3 (`upgrade_frames` de `<x>_level3.tres`). Va después del primero. Opus, esfuerzo medium.

En los dos, poner los números exactos, los pasos de la animación y la ruta de los GIF de referencia.
