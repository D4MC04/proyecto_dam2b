extends VBoxContainer
class_name TurretActions
## Recuadro con "Mejorar" y "Vender" que sale encima de la torreta colocada seleccionada (debajo
## si arriba no cabe en el área de juego). Solo emite peticiones; LevelUI y LevelState deciden.

## El jugador pulsa "Vender" por segunda vez (la primera pide confirmar).
signal sell_requested
## El jugador pulsa "Mejorar"; la torreta y el dinero los gestiona BuildManager.
signal upgrade_requested

const BG_COLOR := Color("#0e1626")
const BORDER_COLOR := Color("#1c7496")
const HOVER_BG_COLOR := Color("#16243c")
const HOVER_BORDER_COLOR := Color("#40e0f0")
const PRESSED_BG_COLOR := Color("#14304a")
const DISABLED_BG_COLOR := Color("#0a0f1a")
const DISABLED_BORDER_COLOR := Color("#1c4a60")
const DISABLED_FONT_COLOR := Color(1, 1, 1, 0.3)
# Hueco en px entre el centro de la torreta y el borde del recuadro (media casilla, más lo que
# sobresalen los cañones y un respiro).
const TURRET_GAP := 22.0
# Margen del texto de los botones al borde, en px.
const BUTTON_H_MARGIN := 8.0
const BUTTON_V_MARGIN := 3.0
# Texto del botón mientras espera el segundo clic que confirma la venta.
const CONFIRM_SELL_TEXT := "¿Seguro?"

@onready var upgrade_button: Button = %UpgradeButton
@onready var sell_button: Button = %SellButton

var _turret: Turret
var _money := 0
var _confirming_sell := false

func _ready() -> void:
	for button in [upgrade_button, sell_button]:
		_style_button(button)
	upgrade_button.pressed.connect(upgrade_requested.emit)
	sell_button.pressed.connect(_on_sell_pressed)
	hide()

## Se abre sobre `turret` con el dinero actual; con null se cierra.
func show_for(turret: Turret, money: int) -> void:
	_turret = turret
	_money = money
	_confirming_sell = false
	if turret == null:
		hide()
		return
	upgrade_button.visible = turret.data.fusion != null
	_refresh()
	show()

## El dinero ha cambiado: "Mejorar" se apaga o se enciende.
func set_money(amount: int) -> void:
	_money = amount
	if visible:
		_refresh_upgrade()

func _refresh() -> void:
	sell_button.text = CONFIRM_SELL_TEXT if _confirming_sell else "Vender (+%s)" % UiFormat.money(_turret.get_sell_value())
	if _turret.data.fusion != null:
		upgrade_button.text = "Mejorar (-%s)" % UiFormat.money(_turret.data.fusion.cost)
	_refresh_upgrade()
	# El texto cambia el ancho: se encoge al mínimo y se recoloca.
	reset_size()
	_reposition()

func _refresh_upgrade() -> void:
	upgrade_button.disabled = _turret.data.fusion != null and _money < _turret.data.fusion.cost

# Vender siempre pide confirmar con un segundo clic.
func _on_sell_pressed() -> void:
	if _confirming_sell:
		sell_requested.emit()
		return
	_confirming_sell = true
	_refresh()

# Centrado encima de la torreta, sin salirse del área de juego (el padre); si arriba no cabe, debajo.
func _reposition() -> void:
	var area := get_parent_control()
	var turret_pos := area.get_global_transform_with_canvas().affine_inverse() * _turret.get_global_transform_with_canvas().origin
	var x := clampf(turret_pos.x - size.x / 2.0, 0.0, maxf(area.size.x - size.x, 0.0))
	var y := turret_pos.y - TURRET_GAP - size.y
	if y < 0.0:
		y = turret_pos.y + TURRET_GAP
	position = Vector2(roundf(x), roundf(y))

func _style_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _create_style(BG_COLOR, BORDER_COLOR))
	button.add_theme_stylebox_override("hover", _create_style(HOVER_BG_COLOR, HOVER_BORDER_COLOR))
	button.add_theme_stylebox_override("pressed", _create_style(PRESSED_BG_COLOR, HOVER_BORDER_COLOR))
	button.add_theme_stylebox_override("disabled", _create_style(DISABLED_BG_COLOR, DISABLED_BORDER_COLOR))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_disabled_color", DISABLED_FONT_COLOR)

func _create_style(bg: Color, border: Color) -> ClippedBoxStyle:
	var style := ClippedBoxStyle.create(bg, border)
	style.content_margin_left = BUTTON_H_MARGIN
	style.content_margin_right = BUTTON_H_MARGIN
	style.content_margin_top = BUTTON_V_MARGIN
	style.content_margin_bottom = BUTTON_V_MARGIN
	return style
