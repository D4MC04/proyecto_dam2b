---
name: mejora
description: Rediseña el nivel 2 (versión mejorada o fusionada) de una torreta para que se note a simple vista y al atacar, con animación de transformación al mejorar. Usar cuando el usuario quiera rediseñar, mejorar o cambiar una torreta mejorada (Cañón cuádruple, Minigun pesada, Cryo ventisca, Tormenta, Cinturón, Rail Gauss, Aniquilador, Amplificador mayor, Excavadora).
argument-hint: "nombre de la torreta"
---

Rediseña el nivel 2 de una torreta: $ARGUMENTS. Hecho por primera vez con el Cañón de asedio (tickets `asedio-martillo` y `asedio-transformacion`): es el ejemplo a seguir.

## Reglas del diseño
- **El nivel 1 no cambia.** Es la referencia de todo.
- **El nivel 2 tiene que ser claramente un nivel 2:** silueta nueva, no la misma recoloreada. Más agresiva y más brusca que el nivel 1.
- **El ataque también cambia, pero parte del nivel 1:** se mantiene el tipo de ataque (bala, onda, cadena, haz...) y se le añade una mecánica que se vea y se sienta. En el Cañón de asedio: salva de 2 balas en la que la primera frena 0,3 s y la segunda cae encima.
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

## Cómo se trabaja
Fase de diseño, sin tocar archivos del proyecto:
1. Leer cómo es ahora la torreta en sus dos niveles: su `TurretData` en `resources/turret_data/<x>.tres` y `<x>_fusion.tres`, su ataque (`*Data`), sus sprites en `assets/sprites/turrets/`, `docs/design/torretas.md` (su fila de "Mejorar (fusión)" y su tipo de ataque) y `docs/design/art.md`. Mirar también la sección "Decidido" de `docs/DESIGN.md` y si el ticket `torretas-mejoradas-aspecto` sigue abierto.
2. Proponer **3 prototipos en texto**. Para cada uno: aspecto, cómo cambia el ataque respecto al nivel 1 (con números) y por qué se siente más brusco.
3. El usuario elige uno o varios, o mezcla. Proponer **3 más** a partir de esos.
4. Cuando lo pida, hacer **bocetos en GIF**, uno por prototipo, con Python y Pillow en la carpeta temporal de la sesión (nunca en el repo). Partir de los sprites reales del nivel 1, enseñar la torreta disparando a una fila de naves y, al lado, la torreta ampliada x4 con sus datos. Mirar los fotogramas antes de enviarlos.
5. Repetir con lo que pida el usuario (recarga, bala, transformación...) hasta que diga que le vale.

Paso a tickets con `/add`, dos por torreta:
- `<torreta>-nivel2`: aspecto nuevo, ataque, recarga o mecánica visible, y bala o efecto. Opus, esfuerzo high.
- `<torreta>-transformacion`: animación de mejora. Va después del primero. Opus, esfuerzo medium.

En los dos, poner los números exactos, los pasos de la animación y la ruta de los GIF de referencia. Si `torretas-mejoradas-aspecto` sigue sin hacer, avisar de que esa torreta queda fuera de él.
