# Comprobar el proyecto en GitHub al subir

Creador: Renzo
Estado: propuesta
Modelo recomendado: sonnet
Esfuerzo recomendado: medium

## Por qué
`main` tiene que abrirse sin errores; hoy solo lo comprueba el `probador` en local.

## Qué hay que hacer
- GitHub Action que descarga Godot 4.7.2, importa en headless y falla si hay errores de script o recurso.
- Lanzar también las pruebas automáticas si existen.

## Archivos que toca
- .github/workflows/godot.yml

## Cómo se prueba a mano
1. Subir una rama: en GitHub aparece la comprobación en verde.
