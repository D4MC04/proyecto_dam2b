# Mejorar torres con un botón en vez de fusionar

Estado: aceptada
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
Hoy, para fusionar hay que elegir en la tienda la misma torre y hacer clic encima de la colocada. Es poco intuitivo. El usuario quiere que se mejore seleccionando la torre colocada y pulsando un botón.

## Qué hay que hacer
- Al seleccionar una torre colocada que tenga `fusion`, la ficha enseña un botón "Mejorar (-X€)" (X = `fusion.cost`) junto a Vender, con el mismo estilo. Si no hay dinero, el botón se ve pero no hace nada (o avisa como al no poder comprar).
- Pulsarlo hace lo mismo que la fusión actual (`BuildManager._fuse`): cambia la torre por su versión mejorada en la misma casilla, conserva lo invertido, las bajas y la selección.
- Quitar la fusión por clic con la misma torre de la tienda (`_can_fuse` en `_try_place`): un clic en una torre colocada solo la selecciona.
- En los textos de la interfaz, Navedex y tutorial, cambiar "fusionar/fusión" por "mejorar/mejora" donde lo vea el jugador. Los identificadores (`fusion`, `register_fusion`, logros `fuse_*`) se quedan.
- Comprobar que los logros "Primera fusión" y "Maestro de fusiones" siguen saltando al mejorar (renombrar su texto a "Primera mejora" y "Maestro de mejoras").

## Archivos que toca
- scripts/level/BuildManager.gd
- scripts/level_ui/InfoPanel.gd (y su .tscn si el botón va en la escena)
- scripts/level_ui/LevelUI.gd
- scripts/autoloads/GameState.gd (solo textos de logros)
- textos del tutorial y la Navedex que hablen de fusionar
- docs/design/torres.md, docs/design/ui.md

## Cómo se prueba a mano
1. Colocar un Cañón doble y hacer clic en él: la ficha enseña "Vender" y "Mejorar (-X€)".
2. Pulsar Mejorar: se convierte en su versión mejorada en la misma casilla y se cobra X.
3. Elegir Cañón doble en la tienda y hacer clic en el colocado: ya no se fusiona, solo se selecciona.
4. Una torre ya mejorada (sin `fusion`) no enseña el botón.
