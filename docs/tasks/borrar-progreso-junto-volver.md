# Borrar progreso junto al botón Volver en Opciones

Estado: aceptada
Modelo recomendado: haiku
Esfuerzo recomendado: low

## Por qué
"Borrar progreso" está a medio camino entre las opciones y "Volver" y es más bajo (204x30 frente a 204x36). Debería formar parte del bloque de botones grandes, con "Volver".

## Qué hay que hacer
- En `OptionsMenu.tscn`, meter `ResetProgressButton` y `BackButton` en un mismo bloque (p. ej. un `VBoxContainer` con los 9 px de separación que usan los botones del menú), con más separación entre ese bloque y las secciones de opciones.
- `ResetProgressButton` a 204x36, igual que `BackButton`.
- Actualizar las rutas de las conexiones de señal y de `%ResetProgressButton` si cambian.
- Actualizar el apartado de Opciones de `docs/design/menu.md`.

## Archivos que toca
- scenes/OptionsMenu.tscn
- docs/design/menu.md

## Cómo se prueba a mano
1. Lanzar el juego y abrir Opciones.
2. "Borrar progreso" debería tener el mismo tamaño que "Volver", estar pegado a él y quedar claramente separado de las opciones de arriba.
3. Pulsar "Borrar progreso" y "Volver": deberían funcionar igual que antes, también la confirmación.
