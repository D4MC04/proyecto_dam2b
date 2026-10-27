# Pausar al perder el foco de la ventana

Creador: Renzo
Estado: propuesta
Modelo recomendado: haiku
Esfuerzo recomendado: low

## Por qué
Al cambiar de ventana el nivel sigue y se pierde vida.

## Qué hay que hacer
- Con `NOTIFICATION_APPLICATION_FOCUS_OUT` abrir la pausa si hay un nivel en juego.
- Opción para desactivarlo.

## Archivos que toca
- scripts/screens/Game.gd
- scripts/autoloads/Settings.gd

## Cómo se prueba a mano
1. Jugar y hacer Alt+Tab: al volver, el juego está en pausa.
