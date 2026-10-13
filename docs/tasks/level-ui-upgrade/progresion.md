# Tarea: progresión de oleadas

Tarea 5b del rediseño de la UI de nivel (plan en `ui_task_plan.md`). Necesita hecha `oleadas`, que crea la pestaña Oleadas y la señal `wave_started`. Hace que los niveles puedan tener varias oleadas que se juegan una tras otra, con un botón para lanzar la siguiente y un modo AUTO.

## Situación actual

- `Spawner.setup()` arranca la primera oleada al momento y `start_next_wave()` no se vuelve a llamar nunca.
- `wave_finished` se emite cuando sale el **último enemigo** de la oleada (no cuando mueren todos) y nadie la escucha.
- Nadie lleva la cuenta de los enemigos vivos.
- Un enemigo que llega al final hace perder la partida en el momento (`Level._lose`). Eso no cambia en esta tarea.

## Qué hay que hacer

### Lógica (`Spawner` / `Level`)

1. **La primera oleada ya no arranca sola.** El nivel empieza en espera para dejar construir y la primera oleada se lanza con el botón (o sola si AUTO está activo; ver más abajo).
2. **Cuenta de enemigos vivos.** El `Spawner` lleva la cuenta: suma uno al crear un enemigo y resta uno cuando ese enemigo muere o llega al final. Cada enemigo se descuenta exactamente una vez, aunque muera y llegue al final en el mismo frame. La cuenta no depende de `tree_exiting`, porque al reiniciar se liberan todos y no debe disparar nada.
3. **Estados claros**, expuestos con funciones o propiedades legibles:
   - **Sacando enemigos:** la oleada actual aún tiene entradas pendientes.
   - **Ha terminado de sacar:** no quedan entradas, pero puede haber enemigos vivos.
   - **Limpia:** no quedan entradas de ninguna oleada lanzada y no hay enemigos vivos.
4. **Señales.** Además de `wave_started(index, total)`, que ya existe:
   - **`wave_cleared(index)`:** cuando la situación pasa a "limpia" tras la oleada `index`.
   - **`all_waves_cleared`:** cuando se limpia la **última** oleada. La victoria (otra tarea) se conectará aquí; en esta tarea solo se emite.
   - `wave_finished` se puede mantener o renombrar, pero tiene que quedar claro que significa "ha terminado de sacar".
5. **Lanzar la siguiente oleada antes de tiempo.** Se puede lanzar en cuanto la actual **ha terminado de sacar**, aunque queden enemigos vivos. Se permite que convivan enemigos de dos oleadas. No se puede lanzar mientras la actual sigue sacando, ni si no quedan oleadas.
6. **Modo AUTO.** Es un bool (por ejemplo `auto_waves`) que vive en la lógica del nivel, no en la UI.
   - Con AUTO activo, cuando el nivel queda **limpio** y quedan oleadas, la siguiente empieza sola tras una pausa corta (una constante, alrededor de 1,5 s).
   - Si se activa AUTO estando ya limpio, o antes de la primera oleada, arranca tras esa misma pausa.
   - Si se desactiva durante la pausa, la cuenta atrás se cancela.
   - La pausa del juego detiene la cuenta atrás (`process_mode` normal).
   - Empieza desactivado en cada nivel y al reiniciar.

### UI (pestaña Oleadas)

7. **Dos controles junto a la cabecera "OLEADA X/Y"**, en una fila que quepa en 80 px:
   - **Botón "Siguiente oleada":** icono de avanzar (▶ o ▶▶ en pixel art) con tooltip. Activo solo cuando se puede lanzar según el punto 5, y atenuado cuando no.
   - **Toggle AUTO:** icono de rayo, o el texto "AUTO" si cabe, con tooltip. Se ve claramente encendido o apagado.
   - Si no caben junto a la cabecera, van en una fila propia justo debajo, fija, sin scroll.
8. **Cabecera antes de empezar:** "OLEADA 0/Y" (o la forma corta elegida en `oleadas`) y el primer bloque marcado como "próxima". El botón de avanzar, encendido o con un pequeño parpadeo, invita a pulsarlo.
9. Los bloques de la pestaña siguen la oleada en curso, como ya se definió en `oleadas`. Si conviven dos oleadas, la resaltada es la última lanzada.
10. **Estética:** queremos que quede más bonito y cuidado que la UI actual, siempre en pixel art y con la paleta de `docs/design/art.md`. Los iconos nuevos van a `assets/ui/` con nombres en minúscula y guion bajo.

## Criterios de hecho

**Código**
- [ ] `Spawner.setup()` ya no lanza la primera oleada.
- [ ] El `Spawner` cuenta los enemigos vivos y cada enemigo se descuenta una sola vez, al morir o al llegar al final; la cuenta no usa `tree_exiting`.
- [ ] Existen `wave_cleared(index)` y `all_waves_cleared`, y se emiten en los momentos descritos (no al salir el último enemigo).
- [ ] Hay una función pública para lanzar la siguiente oleada que se niega si la actual sigue sacando o si no quedan oleadas.
- [ ] `auto_waves` vive en la lógica del nivel, empieza en `false` y la UI solo lo lee y lo cambia.
- [ ] La cuenta atrás de AUTO se detiene con la pausa y se cancela al desactivar AUTO.
- [ ] Las señales nuevas se desconectan bien al reiniciar; no hay errores de conexión duplicada.
- [ ] Código tipado y con los nombres en inglés.
- [ ] El proyecto carga sin errores en headless.

**Juego** (para probarlo, añadir temporalmente 2 o 3 `WaveData` cortas a un nivel, sin commitearlas, o los datos que tú prefieras dejar)
- [ ] Al entrar en el nivel no sale ningún enemigo; la cabecera pone "0/Y" y el botón de avanzar está activo.
- [ ] Al pulsar el botón empieza la oleada 1 y la cabecera pasa a "1/Y". Mientras salen enemigos, el botón está atenuado.
- [ ] Cuando sale el último enemigo de la oleada 1, el botón se activa aunque queden enemigos vivos. Al pulsarlo empieza la 2 y conviven enemigos de ambas.
- [ ] Con AUTO desactivado, al matar todos los enemigos no empieza nada solo.
- [ ] Con AUTO activado, al matar todos los enemigos de la oleada actual, la siguiente empieza sola tras una pausa corta.
- [ ] Activar AUTO al principio del nivel lanza la primera oleada tras la pausa corta.
- [ ] Desactivar AUTO durante la pausa corta cancela el arranque.
- [ ] Pausar el juego durante la pausa corta la congela; al continuar, termina y arranca la oleada.
- [ ] En la última oleada, el botón queda atenuado. Al matar el último enemigo se emite `all_waves_cleared`; comprobarlo con un `print` temporal o en el depurador, porque la pantalla de victoria aún no existe.
- [ ] Reiniciar a mitad de una oleada vuelve a "0/Y" con AUTO apagado, sin enemigos y sin errores.
- [ ] Un enemigo que llega al final sigue provocando la derrota como antes.
- [ ] Los niveles actuales, de una oleada, se juegan bien: botón, oleada y `all_waves_cleared` al limpiarla.

**Documentación**
- [ ] `docs/design/niveles.md` explica el ciclo de oleadas: espera inicial, cuenta de vivos, estados, señales y AUTO. Las dudas sobre `start_next_wave` y la ausencia de final de nivel se actualizan.
- [ ] `docs/design/ui.md` describe el botón y el toggle de la pestaña Oleadas.
- [ ] `docs/design/art.md` lista los iconos nuevos de `assets/ui/`.
- [ ] Este archivo de tarea está borrado.
